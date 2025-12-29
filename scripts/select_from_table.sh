#!/bin/bash

table="$1"
META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

# Validate table exists
if [ ! -f "$META_FILE" ] || [ ! -f "$DATA_FILE" ]; then
    echo "Table '$table' does not exist."
    return
fi

# Show example and get query
echo "Example: SELECT col1,col2 (use all instead of *) WHERE col=value"
read -p "Enter your query: " query

# --- Step 1: Extract the part after SELECT and before FROM ---
# This gets "col1,col2" or "*"
cols_part=""
in_select=0
for word in $query; do
    
    if [ "$word" = "SELECT" ] || [ "$word" = "select" ]; then
        in_select=1
        continue
    fi
    if [ "$word" = "FROM" ] || [ "$word" = "from" ]; then
        break
    fi
    if [ $in_select -eq 1 ]; then
        cols_part="$cols_part$word"
    fi
done

# Remove commas from cols_part (turn "col1,col2" into "col1 col2")
cols_part=$(echo "$cols_part" | tr ',' ' ')

# --- Step 2: Extract WHERE clause if it exists ---
where_col=""
where_val=""
where_op=""
if echo "$query" | grep -qi "WHERE"; then
    # Get everything after WHERE
    where_part=$(echo "$query" | grep -oEi 'WHERE .*' | cut -d' ' -f2-)
    
    # Detect the operator and split accordingly
    if echo "$where_part" | grep -q ">="; then
        where_op=">="
        where_col=$(echo "$where_part" | cut -d'>' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'=' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q "<="; then
        where_op="<="
        where_col=$(echo "$where_part" | cut -d'<' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'=' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q "!="; then
        where_op="!="
        where_col=$(echo "$where_part" | cut -d'!' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'=' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q ">"; then
        where_op=">"
        where_col=$(echo "$where_part" | cut -d'>' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'>' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q "<"; then
        where_op="<"
        where_col=$(echo "$where_part" | cut -d'<' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'<' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q "="; then
        where_op="="
        where_col=$(echo "$where_part" | cut -d= -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d= -f2 | tr -d ' ')
    fi
fi

# --- Step 3: Read column names from metadata file ---
declare -a col_names
while read -r line; do
    # Extract just the column name (first part before :)
    name=$(echo "$line" | cut -d: -f1)
    col_names+=("$name")
done < "$META_FILE"

# --- Step 4: Figure out which columns to print ---
declare -a print_indices
if [ "$cols_part" = "*" ]; then
    # Print all columns
    for ((i=0; i<${#col_names[@]}; i++)); do
        print_indices+=($i)
    done
else
    # Print only specified columns
    for col in $cols_part; do
        found=0
        for ((i=0; i<${#col_names[@]}; i++)); do
            if [ "${col_names[i]}" = "$col" ]; then
                print_indices+=($i)
                found=1
                break
            fi
        done
        if [ $found -eq 0 ]; then
            echo "Column '$col' does not exist."
            return
        fi
    done
fi

# --- Step 5: Find WHERE column index if WHERE exists ---
where_idx=-1
if [ -n "$where_col" ]; then
    for ((i=0; i<${#col_names[@]}; i++)); do
        if [ "${col_names[i]}" = "$where_col" ]; then
            where_idx=$i
            break
        fi
    done
    if [ $where_idx -eq -1 ]; then
        echo "WHERE column '$where_col' does not exist."
        return
    fi
fi

# --- Step 6: Print header row ---
for idx in "${print_indices[@]}"; do
    echo -n "${col_names[idx]}"
    echo -n $'\t'  # Tab character
done
echo ""
echo "----------------------------------------"

# --- Step 7: Read and print data rows ---
while read -r line; do
    # Split line by colons into an array
    declare -a row_values
    temp="$line"
    while [ -n "$temp" ]; do
        # Extract value before first colon
        if [[ "$temp" == *:* ]]; then
            value="${temp%%:*}"  # Everything before first :
            temp="${temp#*:}"    # Everything after first :
        else
            value="$temp"
            temp=""
        fi
        row_values+=("$value")
    done
    
    # Check WHERE condition if it exists
    if [ $where_idx -ne -1 ]; then
        col_val="${row_values[where_idx]}"
        match=0
        
        case "$where_op" in
            "=")
                [ "$col_val" = "$where_val" ] && match=1
                ;;
            "!=")
                [ "$col_val" != "$where_val" ] && match=1
                ;;
            ">")
                [ "$col_val" -gt "$where_val" ] 2>$HOME/BashProject/DB.log && match=1
                ;;
            "<")
                [ "$col_val" -lt "$where_val" ] 2>$HOME/BashProject/DB.log && match=1
                ;;
            ">=")
                [ "$col_val" -ge "$where_val" ] 2>$HOME/BashProject/DB.log && match=1
                ;;
            "<=")
                [ "$col_val" -le "$where_val" ] 2>$HOME/BashProject/DB.log && match=1
                ;;
        esac
        
        if [ $match -eq 0 ]; then
            unset row_values
            continue  # Skip this row
        fi
    fi
    
    # Print only the selected columns
    for idx in "${print_indices[@]}"; do
        echo -n "${row_values[idx]}"
        echo -n $'\t'
    done
    echo ""
    
    unset row_values
done < "$DATA_FILE"
unset col_names
unset print_indices
echo ""