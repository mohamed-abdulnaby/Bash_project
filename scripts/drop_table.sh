#!/bin/bash

table="$1"

META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

if [ ! -f "$META_FILE" ] && [ ! -f "$DATA_FILE" ]; then
    zenity --error --text="Table '$table' does not exist."
    return
fi

if zenity --question --text="do you want to drop table $table ?"; then

rm -f "$META_FILE" "$DATA_FILE"
echo -e "Table '$table' has been deleted.\n@ "$(date)" | tee -a "$HOME/DBs/DB.log""
zenity --info --text="Table '$table' has been deleted."

else
zenity --info --text="aborted dropping"
fi
return