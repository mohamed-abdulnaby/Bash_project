#!/bin/bash
drop=$(basename -a "$HOME/DBs"/*/ | zenity --list --title="Databases" --column="choose which one to drop")

if rm -r $HOME/DBs/"$drop" 2>> "$HOME/DBs/DB.log"
then
	zenity --info --text="database $drop dropped successfully"
	echo -e ""$drop" Database Dropped Successfully!\n@ "$(date)"" | tee -a "$HOME/DBs/DB.log"
else
	zenity --error --text="database $drop does not exist"
fi
