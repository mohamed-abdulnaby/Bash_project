#!/bin/bash
source "$HOME/BashProject/scripts/list_database.sh"

read -p "Enter database to connect: " connect

DB_DIR="$HOME/DBs/$connect"
tableps="Choose a table operation (create/list/select/exit): "

operations() {
	while true
 	do
	 	echo "Select operation:"
	    	echo "1) drop table"
	    	echo "2) insert into table"
	    	echo "3) select from table"
	    	echo "4) delete from table"
	    	echo "5) update table"
    		echo "6) back"
    		read -p "Enter your choice (1-6): " choice
		case "$choice" in
			1) 
				echo "dropping table" 
				#drop_table.sh "$selected_table" 
				;;
			2)
				echo "inserting into table"
				insert_into_table.sh "$selected_table"
				;;
			3)
				echo "selecting from table"
				#select_from_table.sh "$selected_table" 
				;;
			4)
				echo "deleting from table" 
				#delete_from_table.sh "$selected_table" 
				;;
			5) 
				echo "updating table"
				#update_table.sh "$selected_table" 
				;;
			6)
				echo "going back"
				break
				;;
			*)
				echo "invalid choice"
				;;
		esac
	done
	selected_table=""
}


if [ -d "$DB_DIR" ]; then
    echo "Connecting to $connect..."
    
    PS3=$tableps
    select option in "create table" "list tables" "select a table for an operation" "exit"
    do
        case "$REPLY" in
            1)
                echo "Creating a table..."
                source "$HOME/BashProject/scripts/create_table.sh" "$DB_DIR"
                ;;
            2)
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
            3)
            	files=$(basename -s .meta -a "$DB_DIR"/*.meta)
                if [[ $files == "*" ]]; then
                    echo "No tables to operate on."
                    continue
                fi
                echo "$files"
                read -p "Enter the table to operate on(or back): " value
                if [[ "$value" == "back" ]]
                then
                	continue
                fi
                for table in "${files[@]}"
                do
                	#echo "$table"
                	if [[ "$value" == "$table" ]]
                	then
                		selected_table=$value
                	fi
                done
                if [[ "$selected_table" == "" ]]
                then
                	echo "$value Table not found"
                else
                	operations
                fi
                ;;
            4)
                echo "Exiting..."
                PS3=$databaseps
                break
                ;;
            *)
                echo "Invalid entry, please try again"
                ;;
        esac
    done
else
    echo "$connect Database Not Found!"
fi

