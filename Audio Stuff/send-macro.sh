#!/bin/bash
# Sends MIDI commands using the names of macros

macro_name=$1
dont_update=$2

default_value="127" # Default value if no save was found
macros_location="$(dirname "$0")/macros" # Macros location
macro_saves_location="$(dirname "$0")/macro-saves" # Macro saves location

# Find macro
found_macro=$(grep "^$macro_name : " "$macros_location") # if macro_name contains regex characters, stuff happens, so dont
if [ -n "$found_macro" ]; then
    # Get macro details
    save_name=$(echo "$found_macro" | awk -F" : " '{print $2}')
    midi_device=$(echo "$found_macro" | awk -F" : " '{print $3}')
    cc=$(echo "$found_macro" | awk -F" : " '{print $4}')
    channel=$(echo "$found_macro" | awk -F" : " '{print $5}')
    change_amount=$(echo "$found_macro" | awk -F" : " '{print $6}')
    is_toggle=$(echo "$found_macro" | awk -F" : " '{print $7}')
    toggle_low=$(echo "$found_macro" | awk -F" : " '{print $8}') && toggle_low=${toggle_low:-0} && toggle_low=$(( toggle_low > 127 ? 127 : toggle_low < 0 ? 0 : toggle_low ))
    toggle_high=$(echo "$found_macro" | awk -F" : " '{print $9}') && toggle_high=${toggle_high:-127} && toggle_high=$(( toggle_high > 127 ? 127 : toggle_high < 0 ? 0 : toggle_high ))

    # Find save
    found_save=$(grep "^$save_name : " "$macro_saves_location") # if save_name contains regex characters, stuff happens, so dont

    # Get value from save, or use default value
    if [ -n "$found_save" ]; then current_value=$(echo "$found_save" | awk -F" : " '{print $2}'); else current_value=$default_value; fi
    if [ -z "$dont_update" ]; then
        if [ "$is_toggle" = true ]; then
            # Set's value to 0 OR 127
            new_value=$(( current_value > toggle_low ? toggle_low : toggle_high ))
        else
            # Updates value, rounds to nearest change_amount
            change_amount_abs=$(( change_amount < 0 ? -change_amount : change_amount ))
            new_value=$(( current_value + change_amount )) && new_value=$(( ((new_value + (change_amount_abs / 2)) / change_amount_abs) * change_amount_abs )) && new_value=$(( new_value > 127 ? 127 : new_value < 0 ? 0 : new_value ))
        fi
    else
        # Don't update value
        new_value=$current_value
    fi

    # Update save
    updated_save="$save_name : $new_value"

    # Change to hex for MIDI
    channel_hex="$(printf "b%x" $channel)"
    cc_hex="$(printf "%02x" $cc)"
    value_hex="$(printf "%02x" $new_value)"

    data="$channel_hex $cc_hex $value_hex"

    echo "Changing '$macro_name' (CC$cc, Ch$((channel + 1))) value from $current_value to $new_value"
    # Send to MIDI
    amidi -p "$midi_device" -S "$data"
    
    # Write save
    if [ -z "$found_save" ]; then
        echo "$updated_save" >> "$macro_saves_location"
    else
        sed -i "s/$found_save/$updated_save/" "$macro_saves_location"
    fi
else
    # Macro not found
    echo "Couldn't find macro '$macro_name'!"
fi