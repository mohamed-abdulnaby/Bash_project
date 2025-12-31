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
col_types=()
while IFS= read -r line; do
    col_name=$(echo "$line" | cut -d: -f1)
    col_type=$(echo "$line" | cut -d: -f2)
    col_names+=("$col_name")
    col_types+=("$col_type")
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
where_condition=""
col_combo_values=$(printf "%s|" "${col_names[@]}")
col_combo_values=${col_combo_values%|}
if zenity --question --text="Do you want a WHERE condition?"; then

    where_values=$(zenity --forms --title="where condition" --text="fill the fields" --separator="|" --add-combo="choose colomn" --combo-values="$col_combo_values" --add-combo="choose operation" --combo-values="=|>=|<=|!=|>|<" --add-entry="enter your value" )
    [ $? -ne 0 ] && zenity --error --text="invalid entry! " && return
    IFS="|" read -r where_col where_condition where_val <<< "$where_values"

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

        datatype="${col_types[$where_col_index]}"

        is_int() { [[ "$1" =~ ^-?[0-9]+$ ]]; }

        case "$datatype" in
            Int)
                if ! is_int "$where_val"; then
                    zenity --error --text="Value '$where_val' is not an integer. Column '$where_col' requires INT."
                    return
                fi
                ;;
            String)
                # always valid
                ;;
            *)
                zenity --error --text="Unknown datatype: $datatype"
                return
                ;;
        esac
    fi

    if [[ "$datatype" == "Int" ]]; then
        case "$where_condition" in
            "=")
                (( row[where_col_index] == where_val )) || continue 
            ;;
            "!=")
                (( row[where_col_index] != where_val )) || continue 
            ;;
            ">")
                (( row[where_col_index] >  where_val )) || continue 
            ;;
            "<")
                (( row[where_col_index] <  where_val )) || continue 
            ;;
            ">=")
                (( row[where_col_index] >= where_val )) || continue 
            ;;
            "<=")
                (( row[where_col_index] <= where_val )) || continue 
            ;;
        esac
    else
        case "$where_condition" in
            "=")
                [[ "${row[where_col_index]}" != "$where_val" ]] && continue
            ;;
            "!=")
                [[ "${row[where_col_index]}" == "$where_val" ]] && continue
            ;;
            ">=")
                [[ "${row[where_col_index]}" < "$where_val" ]] && continue
            ;;
            "<=")
                [[ "${row[where_col_index]}" > "$where_val" ]] && continue
            ;;
            ">")
                [[ "${row[where_col_index]}" > "$where_val" ]] || continue
            ;;
            "<")
                [[ "${row[where_col_index]}" < "$where_val" ]] || continue
            ;;
            *)
                zenity --error --text="please choose a valid condition"
                return
            ;;
        esac

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