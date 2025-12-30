#!/bin/bash

table="$1"
META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

# Validate table exists
if [ ! -f "$META_FILE" ] || [ ! -f "$DATA_FILE" ]; then
    zenity --error --text="table doesn't exist"
    return
fi

# Check if table has data
if [ ! -s "$DATA_FILE" ]; then
    zenity --error --text="Table is empty, nothing to update."
    return
fi

# Read column names and types from metadata
#unset arrays
unset col_names col_types col_pk
declare -a col_names col_types col_pk

while read -r line; do
    IFS=: read -r name type pk <<< "$line"
    col_names+=("$name")
    col_types+=("$type")
    col_pk+=("$pk")
done < "$META_FILE"

# --- Step 1: Choose column to SET (update) ---
merge_set=()
for ((i=0; i<${#col_names[@]}; i++)); do
    merge_set+=("${col_names[i]}" "${col_types[i]}")
done

set_col_name=$(zenity --list \
    --title="Choose column to UPDATE" \
    --column="Name" \
    --column="Type" \
    "${merge_set[@]}")

[[ -z "$set_col_name" ]] && return

# find index
set_col_index=-1
for ((i=0; i<${#col_names[@]}; i++)); do
    if [[ "${col_names[i]}" = "$set_col_name" ]]; then
        set_col_index=$i
        break
    fi
done

set_col_type="${col_types[set_col_index]}"



# Ask for NEW VALUE
new_value=$(zenity --entry \
    --title="New Value" \
    --text="Enter NEW value for column '$set_col_name':")

[[ -z "$new_value" ]] && {
    zenity --error --text="Value cannot be empty."
    return
}

# Type validation
if [[ "$set_col_type" = "int" && "$new_value" =~ [^0-9] ]]; then
    zenity --error --text="Invalid integer value."
    return
fi

if [[ "$new_value" == *:* ]]; then
    zenity --error --text="Value cannot contain ':'."
    return
fi

# Primary key duplication check
if [[ "${col_pk[set_col_index]}" = "1" ]]; then
    while IFS= read -r line; do
        IFS=: read -ra values <<< "$line"
        if [[ "${values[$set_col_index]}" = "$new_value" ]]; then
            zenity --error --text="Primary key value '$new_value' already exists."
            return
        fi
    done < "$DATA_FILE"
fi

# --- Step 2: Choose WHERE condition ---
merge_where=()
for ((i=0; i<${#col_names[@]}; i++)); do
    merge_where+=("${col_names[i]}" "${col_types[i]}")
done


where_col_name=$(zenity --list \
    --title="WHERE condition" \
    --column="Name" \
    --column="Type" \
    "${merge_where[@]}")

[[ -z "$where_col_name" ]] && return


# find index
where_col_index=-1
for ((i=0; i<${#col_names[@]}; i++)); do
    if [[ "${col_names[i]}" = "$where_col_name" ]]; then
        where_col_index=$i
        break
    fi
done

# Ask WHERE value
where_value=$(zenity --entry \
    --title="WHERE condition" \
    --text="Rows where '$where_col_name' =")

[[ -z "$where_value" ]] && return

# --- Step 3: Show rows that will be updated ---
preview=""
count=0
while IFS= read -r line; do
    IFS=: read -ra values <<< "$line"
    
    if [ "${values[$where_col_index]}" = "$where_value" ]; then
        preview+="$line"$'\n'
        ((count++))
    fi
done < "$DATA_FILE"

if [[ $count -eq 0 ]]; then
    zenity --error --text="No rows match this condition"
    return
fi

zenity --text-info \
    --title="Rows to be updated ($count)" \
    --filename=<(printf "%s" "$preview")

# Confirm

zenity --question --text="Update $count row(s)?"
[[ $? -ne 0 ]] && return

# --- Step 4: UPDATE using temp file ---

: > "$DATA_FILE.tmp"


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

echo -e "Successfully updated $count row(s).\n@ "$(date)"" | tee -a "$HOME/DBs/DB.log"
zenity --info --text="Successfully updated $count row(s)."