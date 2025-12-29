#!/bin/bash

col_names
input_values+="$val" if pk = 1

primary_key input_values DATA_FILE META_FILE (which columns are pk)
declare -a comparing_indx
comparing_idx+=i if  


compare_value= ""
for each line in DATA_FILE
    for idx in comparing_idx; do
        compare_value+="${line[idx]}"
    done

    if compare_value = input_values
        echo "pk exists! "
    fi

done
