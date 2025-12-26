#!/bin/bash
read -p "Enter the database to be created: " create
if [[ $create =~ [^a-zA-Z0-9_] ]];
then
	echo "Invalid Name!!"
	echo "Names should only contain letters, numbers or _"
else
	if mkdir $HOME/DBs/"$create" &>> "$HOME/BashProject/DB.log"
	then
		echo -e ""$create" Database Created Successfully!\n@ "$(date)"" | tee -a "$HOME/BashProject/DB.log"
	else
		echo ""$create" Database already Exists"
	fi
fi
