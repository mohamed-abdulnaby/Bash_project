#!/bin/bash

if [ -z "$DB_DIR" ]; then
    echo "Error: DB_DIR not set"
    exit 1
fi

table="$selected_table"
if [ -z "$table" ]; then
    read -p "enter table name: " table
fi
# paths
META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

# validation

if [ ! -e "$META_FILE" ] || [ ! -e "$DATA_FILE" ]; then
    echo "Table doesn't exist"
    exit 1
fi
#loads the meta file into an array
mapfile -t meta < "$META_FILE"
#counts the number of arguments in the array using #
col_count=${#meta[@]}
#arrays to fill with data
declare -a col_names
declare -a col_types
declare -a col_pk

for ((i=0; i<col_count; i++)); do
    line="${meta[i]}"
    col_names[i]=$(echo "$line" | cut -d: -f1)
    col_types[i]=$(echo "$line" | cut -d: -f2)
    col_pk[i]=$(echo "$line" | cut -d: -f3)
done

declare -a values

for ((i=0; i<col_count; i++))
do
    col="${col_names[i]}"
    type="{$col_types[i]}"
    
    
    while true
    do
        read -p "etner value for $col: " val
        
        if [ "$type" = "int" ];
        then
            case "$val" in
                ''|*[!0-9]*)
                    echo "invalid int"
                    continue
                ;;
            esac
        fi
        
        case "$val" in
            *:*)
                echo "value cannot contain ':'"
            ;;
        esac
        
        values[i]="$val"
        break
    done
done

pk_index=-1
for ((i=0; i<col_count; i++))
do
    if [ "${col_pk[i]}" = "1" ]; then
        pk_index=$i
        break
    fi
done

if [ "$pk_index" -ne -1 ]; then
    pk_value="${values[pk_index]}"

    if awk -F: -v idx="$pk_index" -v val="$pk_value" '$idx == val {found=1} END {exit found ? 0 : 1}' "$DATA_FILE"; then
        echo "Primary key already exists"
        exit 1
    fi
fi

new_row=""
for ((i=0; i<col_count; i++))
do
    if [ $i -eq 0 ]; then
        new_row="${values[i]}"
    else
        new_row="$new_row:${values[i]}"
    fi
done

echo "$new_row" >> "$DATA_FILE"
echo "row inserted"

