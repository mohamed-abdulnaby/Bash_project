#!/bin/bash
source $HOME/BashProject/scripts/list_database.sh
read -p "Enter the database to be dropped: " drop
if rm -r $HOME/DBs/"$drop" 2>> "$HOME/BashProject/DB.log"
then
	echo -e ""$drop" Database Dropped Successfully!\n@ "$(date)"" | tee -a "$HOME/BashProject/DB.log"
else
	echo ""$drop" Database Not Found!"
fi
