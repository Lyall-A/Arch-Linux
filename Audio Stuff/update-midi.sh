#!/bin/bash
# Looks through each macro every interval and updates MIDI to make sure it is synced up

default_value="127" # Default value if no save was found
macros_location="$(dirname "$0")/macros" # Macros location
macro_saves_location="$(dirname "$0")/macro-saves" # Macro saves location
interval=5 # How often to update

while true
do
    sleep $interval
    # Loop through each macro
    grep -vE "^(\s*|#.*)$" "$macros_location" | while read line; do
        # Get macro details
        macro_name=$(echo "$line" | cut -d " " -f 1)
        save_name=$(echo "$line" | cut -d " " -f 2)
        midi_device=$(echo "$line" | cut -d " " -f 3)
        cc=$(echo "$line" | cut -d " " -f 4)
        channel=$(echo "$line" | cut -d " " -f 5)

        # Find save
        found_save=$(grep "^$save_name\s" "$macro_saves_location")

        # Get value from save, or use default value
        if [ "$found_save" != "" ]; then value=$(echo "$found_save" | cut -d " " -f 2); else value=$default_value; fi

        # Update save
        updated_save="$save_name $value"

        # Change to hex for MIDI
        channel_hex="$(printf "b%x" $channel)"
        cc_hex="$(printf "%02x" $cc)"
        value_hex="$(printf "%02x" $value)"

        data="$channel_hex $cc_hex $value_hex"

        # Send to MIDI
        amidi -p $midi_device -S "$data"
    
        # Write save
        if [ "$found_save" = "" ]; then
            echo "$updated_save"
            echo "$updated_save" >> "$macro_saves_location"
        fi
    done
done