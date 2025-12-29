#!/bin/bash

table="$1"

META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"

if [ ! -f "$META_FILE" ] && [ ! -f "$DATA_FILE" ]; then
    echo "Table '$table' does not exist."
    exit 1
fi

read -p "Are you sure you want to delete table '$table'? (y/N): " confirm
case "$confirm" in
    y|Y) ;;
    *) echo "Aborted."; exit 0 ;;
esac
rm -f "$META_FILE" "$DATA_FILE"
echo "Table '$table' has been deleted."
