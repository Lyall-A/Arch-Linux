#!/bin/bash

macro_name=$1
dont_update=$2

midi_device="hw:0,0" # Get with 'amidi -l'
default_value="127" # Default value if no save was found
macros_location="$(dirname "$0")/macros" # Macros location
macro_saves_location="$(dirname "$0")/macro-saves" # Macro saves location

found_macro=$(grep "^$macro_name\s" "$macros_location")
if [ "$found_macro" != "" ]; then
    save_name=$(echo "$found_macro" | cut -d " " -f 2)
    cc=$(echo "$found_macro" | cut -d " " -f 3)
    channel=$(echo "$found_macro" | cut -d " " -f 4)
    change_amount=$(echo "$found_macro" | cut -d " " -f 5)
    is_toggle=$(echo "$found_macro" | cut -d " " -f 6)

    found_save=$(grep "^$save_name\s" "$macro_saves_location")

    if [ "$found_save" != "" ]; then current_value=$(echo "$found_save" | cut -d " " -f 2); else current_value=$default_value; fi
    if [ "$dont_update" = "" ]; then
        if [ "$is_toggle" = "true" ]; then
            new_value=$(( current_value > 0 ? 0 : 127 ))
        else
            change_amount_abs=$(( change_amount < 0 ? -change_amount : change_amount ))
            new_value=$(( current_value + change_amount ))
            new_value=$(( ((new_value + (change_amount_abs / 2)) / change_amount_abs) * change_amount_abs ))
            new_value=$(( new_value > 127 ? 127 : new_value < 0 ? 0 : new_value ))
        fi
    else
        new_value=$current_value
    fi

    updated_save="$save_name $new_value"

    channel_hex="$(printf "b%x" $channel)"
    cc_hex="$(printf "%02x" $cc)"
    value_hex="$(printf "%02x" $new_value)"

    data="$channel_hex $cc_hex $value_hex"

    echo "Changing '$macro_name' value from $current_value to $new_value"
    amidi -p $midi_device -S "$data"
    
    if [ "$found_save" = "" ]; then
        echo "$updated_save" >> "$macro_saves_location"
    else
        sed -i "s/$found_save/$updated_save/" "$macro_saves_location"
    fi
else
    echo "Couldn't find macro '$macro_name'!"
fi