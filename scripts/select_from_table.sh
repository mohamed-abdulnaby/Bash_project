#!/bin/bash

table="$1"
META_FILE="$DB_DIR/$table.meta"
DATA_FILE="$DB_DIR/$table.data"
#pwd
echo "$META_FILE"
## extra valid
# Validate table exists
if [ ! -f "$META_FILE" ] && [ ! -f "$DATA_FILE" ]; then
    echo "Table '$table' does not exist."
    return
fi

<<<<<<< HEAD
# arrays
declare -a tags

# --- Step 1: Set the columns to be shown ---
awk -F: '{ printf "%-10s", $1 } END { print "" }' $META_FILE
read -p "Select columns in the format(y:y:N...:y): " selection
if [[ "$selection" =~ ^(y|N)(:(y|N))+$ ]]
then
	echo "$selection"
	IFS=: read -ra tags <<< $selection
	read -p "Is there a condition?(Y/N): " is_condition
	case "$is_condition" in
		"Y")
			read -p "Enter Condition: " condition ;;
		"N")
			echo "Okii" ;;
		*) 
			echo "Invalid confirmation!!" 
			return
			;;
	esac
=======
# Show example and get query
echo "Example: SELECT col1,col2 (use * to select all) WHERE col=value"
read -p "Enter your query: " query

# --- Step 1: Extract the part after SELECT and before FROM ---
# This gets "col1,col2" or "*"
cols_part=""
in_select=0
set -f
for word in $query; do
    
    if [ "$word" = "SELECT" ] || [ "$word" = "select" ]; then
        in_select=1
        continue
    fi
    if [ "$word" = "WHERE" ] || [ "$word" = "where" ]; then
        break
    fi
    if [ $in_select -eq 1 ]; then
        cols_part="$cols_part$word"
    fi
done
set +f
# Remove commas from cols_part (turn "col1,col2" into "col1 col2")
cols_part=$(echo "$cols_part" | tr ',' ' ')

# --- Step 2: Extract WHERE clause if it exists ---
where_col=""
where_val=""
where_op=""
if echo "$query" | grep -qi "WHERE"; then
    # Get everything after WHERE
    where_part=$(echo "$query" | grep -oEi 'WHERE .*' | cut -d' ' -f2-)
    
    # Detect the operator and split accordingly
    if echo "$where_part" | grep -q ">="; then
        where_op=">="
        where_col=$(echo "$where_part" | cut -d'>' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'=' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q "<="; then
        where_op="<="
        where_col=$(echo "$where_part" | cut -d'<' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'=' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q "!="; then
        where_op="!="
        where_col=$(echo "$where_part" | cut -d'!' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'=' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q ">"; then
        where_op=">"
        where_col=$(echo "$where_part" | cut -d'>' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'>' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q "<"; then
        where_op="<"
        where_col=$(echo "$where_part" | cut -d'<' -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d'<' -f2 | tr -d ' ')
    elif echo "$where_part" | grep -q "="; then
        where_op="="
        where_col=$(echo "$where_part" | cut -d= -f1 | tr -d ' ')
        where_val=$(echo "$where_part" | cut -d= -f2 | tr -d ' ')
    fi
fi

# --- Step 3: Read column names from metadata file ---
unset col_names
declare -a col_names
while read -r line; do
    # Extract just the column name (first part before :)
    name=$(echo "$line" | cut -d: -f1)
    col_names+=("$name")
done < "$META_FILE"

# --- Step 4: Figure out which columns to print ---
unset print_indices
declare -a print_indices
if [ "$cols_part" = "*" ]; then
    # Print all columns
    for ((i=0; i<${#col_names[@]}; i++)); do
        print_indices+=($i)
    done
>>>>>>> dcad9ad (docs: final edit in update and delete)
else
	echo "Invalid column selection!!"
	return	
fi

if [[ "$is_condition" == "Y" ]]
then
	# --- Step 2: Extract WHERE clause if it exists ---
	echo "$condition"
	where_col=""
	where_val=""
	where_op=""
	where_part="$condition"
	if [[ "$where_part" == *">="* ]]; then
	    where_op=">="
	    where_col="${where_part%%>=*}"
	    where_val="${where_part##*>=}"
	elif [[ "$where_part" == *"<="* ]]; then
	    where_op="<="
	    where_col="${where_part%%<=*}"
	    where_val="${where_part##*<=}"
	elif [[ "$where_part" == *"!="* ]]; then
	    where_op="!="
	    where_col="${where_part%%!=*}"
	    where_val="${where_part##*!=}"
	elif [[ "$where_part" == *">"* ]]; then
	    where_op=">"
	    where_col="${where_part%%>*}"
	    where_val="${where_part##*>}"
	elif [[ "$where_part" == *"<"* ]]; then
	    where_op="<"
	    where_col="${where_part%%<*}"
	    where_val="${where_part##*<}"
	elif [[ "$where_part" == *"="* ]]; then
	    where_op="="
	    where_col="${where_part%%=*}"
	    where_val="${where_part##*=}"
	fi
	echo "$where_op"
	echo "$where_col"
	echo "$where_val"
fi
# --- Step 3: print ---
# --- Step 3.1: print table header ---
tags_str="${tags[*]}"
awk -F: -v list="$tags_str" '
BEGIN { n = split(list,tags, " ")}
{
	if (tags[NR] == "y"){
		printf "%-15s|", $1
	} 
}
END { printf "\n"}' $META_FILE
# --- Step 3.2: print table contents ---
where_col=$(awk -F: -v column="$where_col" '{
	if($1 == column) print NR
}' $META_FILE)
#echo "$where_col"
awk -F: -v tag_list="$tags_str" -v operation="$where_op" -v column="$where_col" -v value="$where_val" -v condition="$is_condition" '
BEGIN { n = split(tag_list,tags, " ")}
{
	# skip if no condition
	is_match = 0
	if (condition == "Y") {
	if (operation == ">=" && $column >= value) 
	{
	is_match = 1
	#print $column 
	}
	else if (operation == "<=" && $column <= value) is_match = 1
	else if (operation == ">"  && $column >  value) is_match = 1
	else if (operation == "<"  && $column <  value) is_match = 1
	else if (operation == "!=" && $column != value) is_match = 1
	else if (operation == "="  && $column == value) {is_match = 1
	#print $column
	}
	}
	else
	{ is_match = 1 }
	if (is_match) {
	# print only tagged columns
	for (i = 1; i <= NF; i++) {
	    if (tags[i] == "y") {
		printf "%-15s|", $i
	    }
	}
	printf "\n"
	}
}
END { printf "\n"} ' $DATA_FILE
## unset arrays
unset tags
