#!/bin/bash

# Define variables
CC=1 ## MIDI CC number to use
CHANGE_AMOUNT=-5 # How much value should be incremented/decremented
TOGGLE=false # Toggle to 0 or 127
SAVE_FILE="master-volume" # Save filename


VALUE=$(head -n 1 "$(dirname "$0")/../Saves/$SAVE_FILE")
NEW_VALUE=$([ $TOGGLE = true ] && echo $(( VALUE == 127 ? 0 : 127 )) || echo $(( $VALUE + $CHANGE_AMOUNT > 127 ? 127 : $VALUE + $CHANGE_AMOUNT < 0 ? 0 : $VALUE + $CHANGE_AMOUNT )))

"$(dirname "$0")/../send-midi.sh" $CC $NEW_VALUE
echo $NEW_VALUE > "$(dirname "$0")/../Saves/$SAVE_FILE"
echo "Set value to $NEW_VALUE"