#!/bin/bash
echo "Hello to OUR DBMS!"
mkdir -p $HOME/DBs
databaseps="choose a database operation(create/list/connect/drop/exit): "
PS3=$databaseps
select mode in "Create Database" "List Database" "Connect to Database" "Drop Database" "Exit"
do
	case $REPLY in
		1) echo "Creating Database..."
		source $HOME/BashProject/scripts/create_database.sh 
		;;
		2) echo "Listing Databases..."
		source $HOME/BashProject/scripts/list_database.sh
		;;
		3) echo "Connecting to Database..."
		source $HOME/BashProject/scripts/connect_database.sh
		;;
		4) echo "Droping Database..."
		source $HOME/BashProject/scripts/drop_database.sh
		;;
		5) echo "Exiting..."
			break
		;;
		*) echo "Invalid Option..."
		;;
	esac
done
