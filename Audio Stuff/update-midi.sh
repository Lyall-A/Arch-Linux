#!/bin/bash

midi_device="hw:0,0" # Get with 'amidi -l'
default_value="127" # Default value if no save was found
macros_location="$(dirname "$0")/macros" # Macros location
macro_saves_location="$(dirname "$0")/macro-saves" # Macro saves location
interval=5

while true
do
    sleep $interval
    grep -v "^\s*$" "$macros_location" | while read line; do
        macro_name=$(echo "$line" | cut -d " " -f 1)
        save_name=$(echo "$line" | cut -d " " -f 2)
        cc=$(echo "$line" | cut -d " " -f 3)
        channel=$(echo "$line" | cut -d " " -f 4)

        found_save=$(grep "^$save_name\s" "$macro_saves_location")

        if [ "$found_save" != "" ]; then value=$(echo "$found_save" | cut -d " " -f 2); else value=$default_value; fi

        updated_save="$save_name $value"

        channel_hex="$(printf "b%x" $channel)"
        cc_hex="$(printf "%02x" $cc)"
        value_hex="$(printf "%02x" $value)"

        data="$channel_hex $cc_hex $value_hex"

        amidi -p $midi_device -S "$data"
    
        if [ "$found_save" = "" ]; then
            echo "$updated_save"
            echo "$updated_save" >> "$macro_saves_location"
        fi
    done
done