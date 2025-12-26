#!/bin/bash
columnps="Choose column datatype: "
read -p "Enter the name of the table: " table

#if condition checks for valid table name
if [[ $table =~ [^a-zA-Z0-9_] ]] 
then
	echo "Invalid table name"
	return
fi
#need to be set once the project is up and running
#DB_DIR="$1" 

#unneccessary check
#it exits if the database doesn't't exist
#if [ ! -d "$DB_DIR" ]; then
#    echo "Database directory $DB_DIR does not exist!"
#    exit 1
#fi

META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"
#if they already exist then it exits 
if [[ -e "$META_FILE" || -e "$DATA_FILE" ]]
then
    echo "Table already exists"
    return
fi
read -p "Enter number of columns: " col_count
#checks for valid number of columns as it can't start with a zero
if [[ ! "$col_count" =~ ^[1-9][0-9]*$ ]] 
then
    echo "Invalid number"
    exit 1
fi
#declares some arrays that we will fill later on in the script
declare -a col_names
declare -a col_types
declare -a col_pk

#loops to fill the columns with valid data and exits if any invalid input is written
for (( i=0 ; i<col_count ; i++  ))
do
	read -p "Enter the name of column $((i+1)): " name
	#name of the table can't contain the delimiter we use 
	if [[ $name =~ [^a-zA-Z0-9_] ]] 
	then
		echo "Invalid column name"
		return
	fi
	#checks if a column with the same name already exists
	for exists in "${col_names[@]}"; do
		if [ "$exists" = "$name" ] 
		then
			echo "Duplicate column name"
			return
		fi
	done
	#if no duplicates are available then it appends the column name to the array 
	col_names[i]="$name"
	while true
	do
		read -p "Is it a primary key?(Y/n): " pk
		case "$pk" in
			Y)
				col_pk[i]=1
				break
				;;
			n)
				col_pk[i]=0
				break
				;;
			*)
				echo "Invalid option!"
				;;
		esac
	done
	
	#loops till the user chooses a valid data type (integer or string) only
	#select only one primary key
	PS3=$columns
	select dtype in string int 
	do
		case "$REPLY" in
			1|2)
				col_types[i]="$dtype"
				break
				;;
			*)
				echo "invalid choice"
				;;
		esac
	done
#	assumes all the columns are not primary keys at first to later assign it
#	col_pk[i]=0
done

#echo "choose a primary key column: "
#displays the available columns and gives the user a choice to pick a table to be the pk then it's value is stored in pk_col
##CONSIDERS ONLY ONE COLUMN TO BE THE PRIAMARY KEY
#select pk_col in "${col_names[@]}"
#do
#	if [[ -n "$pk_col" ]] 
#	then 
#		break
#	fi
#	echo "invalid choice"
#done
 
#loops on the entire table to reach the desired table and assign 1 for the pk field 
#for (( i=0; i<col_count; i++ ))
#do
#	if [[ "${col_names[i]}" = "$pk_col" ]]; then
#		col_pk[i]=1
#	fi
#done
#finally creates the file.meta
touch "$META_FILE"
#stores the array values we filled earlier inside the file.meta
for (( i=0; i<col_count; i++ ))
do
	echo "${col_names[i]}:${col_types[i]}:${col_pk[i]}" >> "$META_FILE"
done
#creates an empty file.data to later on store the column values
touch "$DATA_FILE"
echo -e ""$table" Table Created Successfully!\n@ "$(date)"" | tee -a "$HOME/BashProject/DB.log"
#resetting everything
unset col_names
unset col_types
unset col_pk
PS3=$tableps
