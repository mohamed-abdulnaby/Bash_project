#!/bin/bash
connect=$(basename -a $(ls -d "$HOME/DBs"/*/ )| zenity --list --title="Databases" --column="choose a database")

DB_DIR="$HOME/DBs/$connect"
operations() {
    while true
    do
        choice=$(zenity --list \
            --title="select operation" \
            --column="Operation"\
            "drop table"\
            "insert into table"\
            "select from table"\
            "delete from table"\
            "update table"\
            "go back")
        case "$choice" in
            "drop table")
                echo "dropping table"
                source $HOME/BashProject/scripts/drop_table.sh "$selected_table"
            ;;
            "insert into table")
                echo "inserting into table"
                source $HOME/BashProject/scripts/insert_into_table.sh "$selected_table"
            ;;
            "select from table")
                echo "selecting from table"
                source $HOME/BashProject/scripts/select_from_table.sh "$selected_table"
            ;;
            "delete from table")
                echo "deleting from table"
                source $HOME/BashProject/scripts/delete_from_table.sh "$selected_table"
            ;;
            "update table")
                echo "updating table"
                source $HOME/BashProject/scripts/update_table.sh "$selected_table"
            ;;
            "go back"|*)
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
            # Get all .meta files
            tables=( "$DB_DIR"/*.meta )
            
            # Check if no tables exist
            if [[ ! -e "${tables[0]}" ]]; then
                zenity --error --text="No tables found."
            fi
            # Build the text content
            output=""
            for file in "$DB_DIR"/*.meta; do
                output+="$(basename "$file" .meta)"$'\n'
            done
            
            # Display the list
            zenity --info \
            --title="Available Tables" \
            --text="$(printf "%s" "$output")"
            
        ;;
        "select a table for an operation")
            mapfile -t files < <(basename -s .meta -a "$DB_DIR"/*.meta)
            if [[ ${files[0]} == "*" ]]; then
                zenity --error --text="no tables to operate on"
                continue
            fi
            selected_table=$(zenity --list --title="choose a table" --column="tables" "${files[@]}")
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

