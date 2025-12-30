#!/bin/bash
connect=$(basename -a $(ls -d "$HOME/DBs"/*/ )| zenity --list --title="Databases" --column="choose a database")

DB_DIR="$HOME/DBs/$connect"
operations() {
	while true
 	do
	 	choice=$(zenity --list \
		--title="select operation" \
		--column="ID" --column="Operation"\
		1 "drop table"\
		2 "insert into table"\
		3 "select from table"\
		4 "delete from table"\
		5 "update table"\
		6 "go back")
		case "$choice" in
			1) 
				echo "dropping table" 
				source $HOME/BashProject/scripts/drop_table.sh "$selected_table" 
				;;
			2)
				echo "inserting into table"
				source $HOME/BashProject/scripts/insert_into_table.sh "$selected_table"
				;;
			3)
				echo "selecting from table"
				source $HOME/BashProject/scripts/select_from_table.sh "$selected_table" 
				;;
			4)
				echo "deleting from table" 
				source $HOME/BashProject/scripts/delete_from_table.sh "$selected_table" 
				;;
			5) 
				echo "updating table"
				source $HOME/BashProject/scripts/update_table.sh "$selected_table" 
				;;
			6|*)
				echo "going back"
				break
				;;

		esac
	done
	selected_table=""
}


if [ -d "$DB_DIR" ]; then
    
    
    
    option=$(zenity --list --title="DBMS menu options" --column="Action"\
			"create table"\
			"list tables"\
			"select a table for an operation"\
			"back")
	case "$option" in
		"create table")
			echo "Creating a table..."
			source "$HOME/BashProject/scripts/create_table.sh" "$DB_DIR"
			;;
		"list tables")
			echo "Listing tables:"
			# error handling
			# lists full path not table names
			if [[ $(basename -s .meta -a "$DB_DIR"/*.meta) == "*" ]]
			then
				echo "No tables to list"
			else
				basename -s .meta -a "$DB_DIR"/*.meta
			fi
			;;
		"select a table for an operation")
			mapfile -t files < <(basename -s .meta -a "$DB_DIR"/*.meta)
			if [[ ${files[0]} == "*" ]]; then
				zenity --error --text="no tables to operate on"
				continue
			fi
			value=$(zenity --list --title="choose a table" --column="tables" "${files[@]}")
			operations
			;;
		"back"|*)
			echo "Exiting..."
			return
			;;
	esac
    
else
    echo "$connect Database Not Found!"
fi

