#!/bin/bash
table="$1"
META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"
# Validate table exists
if [ ! -f "$META_FILE" ] || [ ! -f "$DATA_FILE" ]; then
    zenity --error --text="Table '$table' does not exist."
    return
fi
# Format: "ID" "Label" "State"
col_names=()
while IFS= read -r line; do
    col_name=$(echo "$line" | cut -d: -f1)
    col_names+=("$col_name")
done < "$META_FILE"
zenity_args=()
for ((i=0; i<${#col_names[@]}; i++)); do
    zenity_args+=("FALSE" "$i" "${col_names[i]}")
done
choices=$(zenity --list \
    --title="Select columns" \
    --text="Pick columns: " \
    --checklist \
    --column="Select" --column="ID" --column="Column" \
    "${zenity_args[@]}" \
    --separator="|" \
    --print-column=2)
[[ -z "$choices" ]] && zenity --error --text="cancelled" && return
IFS="|" read -ra selected_indices <<< "$choices"
where_col=""
where_val=""
if zenity --question --text="Do you want a WHERE condition?"; then
    where_col=$(zenity --list \
        --title="WHERE Column" \
        --text="Pick column for condition:" \
        --column="Column" "${col_names[@]}")
    [[ -z "$where_col" ]] && zenity --info --text="Cancelled" && return
    where_val=$(zenity --entry \
        --title="WHERE Value" \
        --text="Rows where '$where_col' =")
fi
output=""
for idx in "${selected_indices[@]}"; do
    output+="${col_names[$idx]}"$'\t'$'\t'$'\t'
done
output="${output%$'\t'$'\t'$'\t'}"$'\n'
output+="-------------------------------------------------------"$'\n'
# Data rows
while IFS=: read -r -a row; do
    # Apply WHERE if exists
    if [[ -n "$where_col" ]]; then
        where_col_index=-1
        for i in "${!col_names[@]}"; do
            [[ "${col_names[i]}" == "$where_col" ]] && where_col_index=$i && break
        done
        [[ "${row[where_col_index]}" != "$where_val" ]] && continue
    fi
    line=""
    for idx in "${selected_indices[@]}"; do
        line+="${row[$idx]}"$'\t'$'\t'$'\t'
    done
    output+="${line%$'\t'$'\t'$'\t'}"$'\n'
done < "$DATA_FILE"
zenity --text-info \
    --title="Table: $table" \
    --width=600 --height=400 \
    --filename=<(echo "$output")