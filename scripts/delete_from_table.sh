#!/bin/bash

table="$1"
META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

# Validate table exists
if [ ! -f "$META_FILE" ] || [ ! -f "$DATA_FILE" ]; then
    echo "Table '$table' does not exist."
    exit 1
fi

# Check if table has data
if [ ! -s "$DATA_FILE" ]; then
    echo "Table is empty, nothing to delete."
    exit 0
fi

# Read column names from metadata
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
        exit 1
        ;;
esac

if [ "$col_choice" -lt 1 ] || [ "$col_choice" -gt "${#col_names[@]}" ]; then
    echo "Invalid choice"
    exit 1
fi

col_index=$((col_choice-1))
selected_col="${col_names[col_index]}"

# Get value to match
read -p "Enter value to delete (rows where $selected_col = value): " delete_value

# Escape special characters for sed (. * [ ] ^ $ \)
escaped_value=$(echo "$delete_value" | sed 's/[.*[\^$]/\\&/g')

# Build sed pattern based on column position
if [ $col_index -eq 0 ]; then
    # First column: ^value:
    pattern="^${escaped_value}:"
elif [ $col_index -eq $((${#col_names[@]}-1)) ]; then
    # Last column: :value$
    pattern=":${escaped_value}$"
else
    # Middle column: :value:
    pattern=":${escaped_value}:"
fi

# Show matching rows before deletion
echo ""
echo "Rows that will be deleted:"
echo "----------------------------------------"
grep "$pattern" "$DATA_FILE"

# Count matching rows
count=$(grep -c "$pattern" "$DATA_FILE")

if [ "$count" -eq 0 ]; then
    echo "No matching rows found."
    exit 0
fi

echo "----------------------------------------"
echo "Total rows to delete: $count"

# Confirm before deleting
read -p "Are you sure? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo "Delete cancelled."
    exit 0
fi

# --- DELETE USING SED (in-place, no temp file) ---
# sed -i deletes matching lines directly in the file
sed -i "/${pattern}/d" "$DATA_FILE"

echo "Successfully deleted $count row(s)."