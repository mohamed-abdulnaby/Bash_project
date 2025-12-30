#!/bin/bash

table="$1"
META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

# Validate table exists
if [ ! -f "$META_FILE" ] || [ ! -f "$DATA_FILE" ]; then
    zenity --error --text="Table '$table' does not exist."
    return
fi

# Check if table has data
if [ ! -s "$DATA_FILE" ]; then
    zenity --error --text="Table is empty, nothing to delete."
    return
fi


# unset arrays if any
unset col_names
unset col_types
declare -a col_names
declare -a col_types
while read -r line; do
    name=$(echo "$line" | cut -d: -f1)
    type=$(echo "$line" | cut -d: -f2)
    col_names+=("$name")
    col_types+=("$type")
done < "$META_FILE"

# Show available columns
for ((i=0; i<${#col_names[@]}; i++)); do
    merged+=("${col_names[i]}" "${col_types[i]}")
done

selected_col=$(zenity --list --title="pick a column for the WHERE condition" --column="name" --column="type" "${merged[@]}")

[[ -z "$selected_col" ]] && zenity --error --text="invalid selected column"

col_index=1
for ((i=0; i<${#col_names[@]}; i++)); do
    if [[ "${col_names[i]}" == "$selected_col" ]]; then
        col_index=i
        break
    fi
done

if (( col_index == -1 )); then
    zenity --error --text="Column not found."
    return
fi

# Ask for value to delete
delete_value=$(zenity --entry \
    --text="Delete rows where [$selected_col] = ?" \
)

[[ -z "$delete_value" ]] && zenity --error --text="Invalid deleted value"

# Show matching rows and count them
matches=""
count=0

while IFS= read -r line; do
    # Split the line by : into an array
    IFS=: read -ra values <<< "$line"
    
    # Check if the specific column matches
    if [ "${values[$col_index]}" = "$delete_value" ]; then
        matches+="$line"$'\n'
        ((count++))
    fi
done < "$DATA_FILE"

zenity --text-info --title="Matching Rows" --filename=<(printf "%s" "$matches")

zenity --question --text="Found $count rows.\nDelete them?"

if [[ $? -ne 0 ]]; then
    return
fi

# Create empty temp file first
> "$DATA_FILE.tmp"

while IFS= read -r line; do
    IFS=: read -ra values <<< "$line"
    
    # Keep the row only if it does NOT match
    if [ "${values[$col_index]}" != "$delete_value" ]; then
        echo "$line" >> "$DATA_FILE.tmp"
    fi
done < "$DATA_FILE"

# Replace original with temp file
mv "$DATA_FILE.tmp" "$DATA_FILE"

unset col_names
unset col_types

echo -e "Successfully deleted $count row(s).\n@ "$(date)"" | tee -a "$HOME/DBs/DB.log"

zenity --info --text="successfully deleted"