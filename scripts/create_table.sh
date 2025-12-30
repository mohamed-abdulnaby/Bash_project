#!/bin/bash
if [ -n "$1" ]; then
    DB_DIR="$1"
fi
# -------------------------
# ask for table name
# -------------------------
while true
do
	table=$(zenity --entry --title="Table Name" --text="Enter table name: ")

	# empty?
	if [ -z "$table" ]; then
	zenity --error --text="Table names can't be empty!!"
	continue
	fi

	# contains colon?
	case "$table" in
	*:*)
	    zenity --error --text="Table names can't contain ':'!!"
	    continue
	    ;;
	esac

	META_FILE="$DB_DIR/$table.meta"
	DATA_FILE="$DB_DIR/$table.data"

	# file exists?
	if [ -e "$META_FILE" ] || [ -e "$DATA_FILE" ]; then
	zenity --error --text="Table $table already exists!!"
	continue
	fi

	break
done


# -------------------------
# get column count
# -------------------------
while true
do
    #read -p "enter number of columns: " col_count
    col_count=$(zenity --entry --title="Column Number" /
    --text="Enter number of columns: ")

    # regex using case
    case "$col_count" in
        ''|*[!0-9]*)
            echo "Invalid number"
            zenity --error --text="Invalid Number!!"
            continue
            ;;
    esac

    if [ "$col_count" -lt 1 ]; then
        echo "Invalid number"
        zenity --error --text="Invalid Number!!"
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
        #read -p "enter the name of column $((i+1)): " name
	name=$(zenity --entry --title="Column Name" /
	--text="Enter the name of column $((i+1)): ")
        # empty?
        if [ -z "$name" ]; then
            echo "invalid column name"
            zenity --error --text="Column Names can't be empty !!"
            continue
        fi

        # contains :
        case "$name" in
            (*[!a-zA-Z0-9_]*)
                echo "invalid column name"
                zenity --error --text="Column Names can only contain (a~z),(A~Z),(0~9) or '_' !!"
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
            zenity --error --text="Column Names can't be empty !!"
            continue
        fi

        col_names[i]="$name"
        break
    done

    # column type
	col_types[i]=$(zenity --list --title="Attribute Datatype" /
	--column="Data Types" /
	"String" "Int")
	if [ $? -eq 0 ]; then
		echo "User selected: ${col_types[i]}"
		zenity --info --text="Selected: ${col_types[i]}"
	else
		return
	fi
	col_pk[i]=0
done


# -------------------------
# choose primary key
# -------------------------
pk_choice=$(zenity --list --title="Choose Primary Key" --column="Attributes" /
"${col_names[@]}")
if [ $? -eq 0 ]; then
	echo "User selected: $pk_choice"
	zenity --info --text="Selected: $pk_choice"
else
	return
fi
# -------------------------
# write files
# -------------------------
touch "$META_FILE"
touch "$DATA_FILE"

for (( i=0; i<col_count; i++ ))
do
    echo "${col_names[i]}:${col_types[i]}:${col_pk[i]}" >> "$META_FILE"
done

echo -e "Table '$table' created successfully.\n@ "$(date)"" | tee -a "$HOME/DBs/DB.log"
zenity --info --text="Table '$table' created successfully."

#resetting everything
unset col_names
unset col_types
unset col_pk
