#!/bin/bash

table="$1"

META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

if [ ! -f "$META_FILE" ] && [ ! -f "$DATA_FILE" ]; then
    echo "Table '$table' does not exist."
    return
fi

read -p "Are you sure you want to delete table '$table'? (Y/n): " confirm
case "$confirm" in
    Y) ;;
    *) echo "Aborted."; return ;;
esac
rm -f "$META_FILE" "$DATA_FILE"
echo -e "Table '$table' has been deleted.\n@ "$(date)" | tee -a "$HOME/DBs/DB.log""
exit 0
