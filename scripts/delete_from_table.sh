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
    echo "Table is empty, nothing to delete."
    return
fi

# Read column names from metadata
declare -a col_names
declare -a col_types
while read -r line; do
    name=$(echo "$line" | cut -d: -f1)
    type=$(echo "$line" | cut -d: -f2)
    col_names+=("$name")
    col_types+=("$type")
done < "$META_FILE"

# Show available columns
echo "Available columns:"
for ((i=0; i<${#col_names[@]}; i++)); do
    echo "$((i+1))) ${col_names[i]} (${col_types[i]})"
done

# Get column for WHERE condition
read -p "Select column number for WHERE condition: " col_choice

# Validate column choice
case "$col_choice" in
    ''|*[!0-9]*)
        echo "Invalid choice"
        return
        ;;
esac

if [ "$col_choice" -lt 1 ] || [ "$col_choice" -gt "${#col_names[@]}" ]; then
    echo "Invalid choice"
    return
fi

col_index=$((col_choice-1))
selected_col="${col_names[col_index]}"

# Get value to match
read -p "Enter value to delete (rows where $selected_col = value): " delete_value

echo ""
echo "Rows that will be deleted:"
echo "----------------------------------------"

# Show matching rows and count them
count=0
while IFS= read -r line; do
    # Split the line by : into an array
    IFS=: read -ra values <<< "$line"
    
    # Check if the specific column matches
    if [ "${values[$col_index]}" = "$delete_value" ]; then
        echo "$line"
        ((count++))
    fi
done < "$DATA_FILE"

echo "----------------------------------------"
echo "Total rows to delete: $count"

if [ "$count" -eq 0 ]; then
    echo "No matching rows found."
    return
fi

# Confirm before deleting
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Delete cancelled."
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

echo -e "Successfully deleted $count row(s).\n@ "$(date)"" | tee -a "$HOME/BashProject/DB.log"

