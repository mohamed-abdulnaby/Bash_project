#!/bin/bash

if [ -z "$DB_DIR" ]; then
    zenity --error --text="invalid database"
    return
fi

table="$selected_table"
if [ -z "$table" ]; then
    zenity --error --text="invalid database"
    return
fi
# paths
META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

# validation

if [ ! -e "$META_FILE" ] || [ ! -e "$DATA_FILE" ]; then
    zenity --error --text="invalid table"
    return
fi
#loads the meta file into an array
mapfile -t meta < "$META_FILE"
#counts the number of arguments in the array using #
col_count=${#meta[@]}
#arrays to fill with data
declare -a col_names col_types col_pk

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
    type="${col_types[i]}"
    
    
    while true
    do
        val=$(zenity --entry --text="ener value for column ($col) no $i: ")
        
        if [ "$type" = "int" ];
        then
            case "$val" in
                ''|*[!0-9]*)
                        zenity --error --text="invalid integer"
                    continue
                ;;
            esac
        fi
        
        case "$val" in
            *:*)
                zenity --error --text="value contains ':' "
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
    awk_idx=$((pk_index + 1))  # awk fields are 1-based

    if awk -F: -v idx="$awk_idx" -v val="$pk_value" '
        BEGIN { found=0 }
        $idx == val { found=1 }
        END { exit found ? 0 : 1 }' "$DATA_FILE"; then
        zenity --error --text="Primary key already exists"
        return
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
echo -e "row '$new_row'\ninserted.\n @ "$(date)"" | tee -a "$HOME/DBs/DB.log"

unset col_names col_types col_pk values
