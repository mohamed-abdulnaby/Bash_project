#!/bin/bash

table="$1"
META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

# Validate table exists
if [ ! -f "$META_FILE" ] || [ ! -f "$DATA_FILE" ]; then
    echo "Table '$table' does not exist."
    return
fi

# Check if table has data
if [ ! -s "$DATA_FILE" ]; then
    echo "Table is empty, nothing to update."
    return
fi

# Read column names and types from metadata
#unset arrays
unset col_names
unset col_types
unset col_pk
declare -a col_names
declare -a col_types
declare -a col_pk
while read -r line; do
    name=$(echo "$line" | cut -d: -f1)
    type=$(echo "$line" | cut -d: -f2)
    pk=$(echo "$line" | cut -d: -f3)
    col_names+=("$name")
    col_types+=("$type")
    col_pk+=("$pk")
done < "$META_FILE"

echo "=== UPDATE TABLE: $table ==="
echo ""

# --- Step 1: Choose column to SET (update) ---
echo "Available columns to UPDATE:"
for ((i=0; i<${#col_names[@]}; i++)); do
    echo "$((i+1))) ${col_names[i]} (${col_types[i]})"
done

read -p "Select column number to UPDATE: " set_col_choice

# Validate
case "$set_col_choice" in
    ''|*[!0-9]*)
        echo "Invalid choice"
        return
        ;;
esac

if [ "$set_col_choice" -lt 1 ] || [ "$set_col_choice" -gt "${#col_names[@]}" ]; then
    echo "Invalid choice"
    return
fi

##
set_col_index=$((set_col_choice-1))
set_col_name="${col_names[set_col_index]}"
set_col_type="${col_types[set_col_index]}"

# Get new value
read -p "Enter NEW value for $set_col_name: " new_value

# Validate data type
if [ "$set_col_type" = "int" ]; then
    case "$new_value" in
        ''|*[!0-9]*)
            echo "Invalid integer value"
            return
            ;;
    esac
fi

# Check for colon in value
case "$new_value" in
    *:*)
        echo "Value cannot contain ':'"
        return
        ;;
esac

# Check if updating a primary key column
if [ "${col_pk[set_col_index]}" = "1" ]; then
    echo "Warning: You are updating a PRIMARY KEY column!"
    
    # Check if new PK value already exists
    escaped_check=$(echo "$new_value" | sed 's/[.*[\^$]/\\&/g')
    
    # Build pattern based on column position
    if [ $set_col_index -eq 0 ]; then
        check_pattern="^${escaped_check}:"
    elif [ $set_col_index -eq $((${#col_names[@]}-1)) ]; then
        check_pattern=":${escaped_check}$"
    else
        check_pattern=":${escaped_check}:"
    fi
    
    # Check if this PK value already exists
    if grep -q "$check_pattern" "$DATA_FILE"; then
        echo "Error: Primary key value '$new_value' already exists!"
        echo "Cannot update - would create duplicate primary key."
        return
    fi
fi

# --- Step 2: Choose WHERE condition ---
echo ""
echo "Available columns for WHERE condition:"
for ((i=0; i<${#col_names[@]}; i++)); do
    echo "$((i+1))) ${col_names[i]} (${col_types[i]})"
done

read -p "Select column number for WHERE condition: " where_col_choice

# Validate
case "$where_col_choice" in
    ''|*[!0-9]*)
        echo "Invalid choice"
        return
        ;;
esac

if [ "$where_col_choice" -lt 1 ] || [ "$where_col_choice" -gt "${#col_names[@]}" ]; then
    echo "Invalid choice"
    return
fi

where_col_index=$((where_col_choice-1))
where_col_name="${col_names[where_col_index]}"

read -p "Enter value for WHERE $where_col_name = : " where_value

# --- Step 3: Show rows that will be updated ---
echo ""
echo "Rows that will be updated:"
echo "----------------------------------------"

# Escape special characters for grep/sed
escaped_where=$(echo "$where_value" | sed 's/[.*[\^$]/\\&/g')

# Build grep pattern for WHERE column
if [ $where_col_index -eq 0 ]; then
    where_pattern="^${escaped_where}:"
elif [ $where_col_index -eq $((${#col_names[@]}-1)) ]; then
    where_pattern=":${escaped_where}$"
else
    where_pattern=":${escaped_where}:"
fi

# Show matching rows
grep "$where_pattern" "$DATA_FILE"

count=$(grep -c "$where_pattern" "$DATA_FILE")

if [ "$count" -eq 0 ]; then
    echo "No matching rows found."
    return
fi

echo "----------------------------------------"
echo "Total rows to update: $count"

# Confirm
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Update cancelled."
    return
fi

# --- Step 4: UPDATE using sed ---
# We need to replace the value in the SET column
# while keeping other columns intact

# Escape new value for sed replacement
escaped_new=$(echo "$new_value" | sed 's/[&/\]/\\&/g')

# Build sed substitution based on column positions
if [ $set_col_index -eq 0 ]; then
    # Update first column: ^old: -> ^new:
    if [ $where_col_index -eq 0 ]; then
        # SET and WHERE are same column
        sed -i "s/^${escaped_where}:/${escaped_new}:/" "$DATA_FILE"
    else
        # Different columns
        sed -i "/${where_pattern}/s/^[^:]*:/${escaped_new}:/" "$DATA_FILE"
    fi
elif [ $set_col_index -eq $((${#col_names[@]}-1)) ]; then
    # Update last column: :old$ -> :new$
    if [ $where_col_index -eq $set_col_index ]; then
        # SET and WHERE are same column
        sed -i "s/:${escaped_where}$/:${escaped_new}/" "$DATA_FILE"
    else
        # Different columns
        sed -i "/${where_pattern}/s/:[^:]*$/:${escaped_new}/" "$DATA_FILE"
    fi
else
    # Update middle column: :old: -> :new:
    # This is tricky - need to update the Nth occurrence
    
    # Count colons before target column
    colons_before=$set_col_index
    
    # Build pattern to match the specific field
    # Pattern: ^(fields before):(old_value):(fields after)$
    
    if [ $where_col_index -eq $set_col_index ]; then
        # SET and WHERE are same column
        sed -i "s/:${escaped_where}:/:${escaped_new}:/" "$DATA_FILE"
    else
        # Different columns - need to be more careful
        # Use a loop to update each matching line
        while IFS= read -r line; do
            if echo "$line" | grep -q "$where_pattern"; then
                # Split line into array
                declare -a values
                temp="$line"
                while [ -n "$temp" ]; do
                    if [[ "$temp" == *:* ]]; then
                        value="${temp%%:*}"
                        temp="${temp#*:}"
                    else
                        value="$temp"
                        temp=""
                    fi
                    values+=("$value")
                done
                
                # Update the target column
                values[$set_col_index]="$new_value"
                
                # Rebuild line
                new_line=""
                for ((i=0; i<${#values[@]}; i++)); do
                    if [ $i -eq 0 ]; then
                        new_line="${values[i]}"
                    else
                        new_line="$new_line:${values[i]}"
                    fi
                done
                
                # Escape for sed
                escaped_old_line=$(echo "$line" | sed 's/[.*[\^$]/\\&/g')
                escaped_new_line=$(echo "$new_line" | sed 's/[&/\]/\\&/g')
                
                # Replace the line
                sed -i "s/^${escaped_old_line}$/${escaped_new_line}/" "$DATA_FILE"
                
                unset values
            fi
        done < <(cat "$DATA_FILE")
    fi
fi

echo -e "Successfully updated $count row(s).\n@ "$(date)"" | tee -a "$HOME/DBs/DB.log"
