#!/bin/bash
create=$(zenity --entry --text="Enter the database name: ")
if [[ $create =~ [^a-zA-Z0-9_] ]];
then
	zenity --error --text="invalid database name!!\
	Names should only contain letters, numbers or _"
else
	if mkdir $HOME/DBs/"$create" &>> "$HOME/DBs/DB.log"
	then
		echo -e ""$create" Database Created Successfully!\n@ "$(date)"" | tee -a "$HOME/DBs/DB.log"
		zenity --info --text="database $create created successfuly"
	else
		zenity --error --text="database $create already exists"
	fi
fi
