#!/bin/bash
echo "Hello to OUR DBMS!"
mkdir -p $HOME/DBs
while true; do
	first_choice=$(zenity --list --title="choose database operation"\
					--column="DB operation"\
					"create database"\
					"list databases"\
					"connect database"\
					"drop database"\
					"exit")
	case $first_choice in
		"create database") echo "Creating Database..."
		source $HOME/BashProject/scripts/create_database.sh 
		;;
		"list databases") echo "Listing Databases..."
		source $HOME/BashProject/scripts/list_database.sh
		;;
		"connect database") echo "Connecting to Database..."
		source $HOME/BashProject/scripts/connect_database.sh
		;;
		"drop database") echo "Droping Database..."
		source $HOME/BashProject/scripts/drop_database.sh
		;;
		"exit"|*) echo "Exiting..."
			break
		;;
	esac

done