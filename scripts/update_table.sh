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

# FIX: Check if updating a primary key column - allow it but prevent duplicates
if [ "${col_pk[set_col_index]}" = "1" ]; then
    echo "Warning: You are updating a PRIMARY KEY column!"
    
    # Check if new PK value already exists by parsing each row
    pk_exists=0
    while IFS= read -r line; do
        IFS=: read -ra values <<< "$line"
        if [ "${values[$set_col_index]}" = "$new_value" ]; then
            pk_exists=1
            break
        fi
    done < "$DATA_FILE"
    
    if [ "$pk_exists" -eq 1 ]; then
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

# FIX: Parse each row and check exact column match
count=0
while IFS= read -r line; do
    IFS=: read -ra values <<< "$line"
    
    if [ "${values[$where_col_index]}" = "$where_value" ]; then
        echo "$line"
        ((count++))
    fi
done < "$DATA_FILE"

echo "----------------------------------------"
echo "Total rows to update: $count"

if [ "$count" -eq 0 ]; then
    echo "No matching rows found."
    return
fi

# Confirm
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Update cancelled."
    return
fi

# --- Step 4: UPDATE using temp file ---
# FIX: Use temp file approach - simpler and more reliable
while IFS= read -r line; do
    IFS=: read -ra values <<< "$line"
    
    # Check if this row matches WHERE condition
    if [ "${values[$where_col_index]}" = "$where_value" ]; then
        # Update the SET column
        values[$set_col_index]="$new_value"
    fi
    
    # Rebuild the line
    new_line=""
    for ((i=0; i<${#values[@]}; i++)); do
        if [ $i -eq 0 ]; then
            new_line="${values[i]}"
        else
            new_line="$new_line:${values[i]}"
        fi
    done
    
    echo "$new_line" >> "$DATA_FILE.tmp"
done < "$DATA_FILE"

# Replace original with temp file
mv "$DATA_FILE.tmp" "$DATA_FILE"

unset col_names
unset col_types
unset col_pk

echo "Successfully updated $count row(s)."