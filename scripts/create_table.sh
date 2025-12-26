#!/bin/bash
if [ -n "$1" ]; then
    DB_DIR="$1"
fi
# -------------------------
# ask for table name
# -------------------------
while true
do
    read -p "enter the name of the table: " table

    # empty?
    if [ -z "$table" ]; then
        echo "invalid table name"
        continue
    fi

    # contains colon?
    case "$table" in
        *:*)
            echo "invalid table name"
            continue
            ;;
    esac

    META_FILE="$DB_DIR/$table.meta"
    DATA_FILE="$DB_DIR/$table.data"

    # file exists?
    if [ -e "$META_FILE" ] || [ -e "$DATA_FILE" ]; then
        echo "Table already exists"
        continue
    fi

    break
done


# -------------------------
# get column count
# -------------------------
while true
do
    read -p "enter number of columns: " col_count

    # regex using case
    case "$col_count" in
        ''|*[!0-9]*)
            echo "Invalid number"
            continue
            ;;
    esac

    if [ "$col_count" -lt 1 ]; then
        echo "Invalid number"
        continue
    fi

    break
done


# arrays
declare -a col_names
declare -a col_types
declare -a col_pk

# -------------------------
# loop for each column
# -------------------------
for (( i=0; i<col_count; i++ ))
do
    # column name
    while true
    do
        read -p "enter the name of column $((i+1)): " name

        # empty?
        if [ -z "$name" ]; then
            echo "invalid column name"
            continue
        fi

        # contains :
        case "$name" in
            *:*)
                echo "invalid column name"
                continue
                ;;
        esac

        # check duplicates
        duplicate=0
        for exists in "${col_names[@]}"
        do
            if [ "$exists" = "$name" ]; then
                duplicate=1
                break
            fi
        done

        if [ "$duplicate" -eq 1 ]; then
            echo "Duplicate column name"
            continue
        fi

        col_names[i]="$name"
        break
    done

    # column type
    while true
    do
        echo "Choose type for $name:"
        echo "1) string"
        echo "2) int"
        read -p "enter choice: " choice

        if [ "$choice" = "1" ]; then
            col_types[i]="string"
            break
        elif [ "$choice" = "2" ]; then
            col_types[i]="int"
            break
        else
            echo "invalid choice"
        fi
    done

    col_pk[i]=0
done


# -------------------------
# choose primary key
# -------------------------
while true
do
    echo "choose a primary key column:"
    for (( i=0; i<col_count; i++ ))
    do
        echo "$((i+1))) ${col_names[i]}"
    done

    read -p "enter choice: " pk_choice

    # numeric check
    case "$pk_choice" in
        ''|*[!0-9]*)
            echo "invalid choice"
            continue
            ;;
    esac

    if [ "$pk_choice" -lt 1 ] || [ "$pk_choice" -gt "$col_count" ]; then
        echo "invalid choice"
        continue
    fi

    pk_index=$((pk_choice-1))
    col_pk[$pk_index]=1
    break
done
# -------------------------
# write files
# -------------------------
touch "$META_FILE"
touch "$DATA_FILE"

for (( i=0; i<col_count; i++ ))
do
    echo "${col_names[i]}:${col_types[i]}:${col_pk[i]}" >> "$META_FILE"
done

echo "Table '$table' created successfully."

#resetting everything
unset col_names
unset col_types
unset col_pk