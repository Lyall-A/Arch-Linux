#!/bin/bash

CC=$1
VALUE=$2

MIDI_DEVICE="hw:0,0"
CHANNEL="15"

CHANNEL_HEX="$(printf "b%x" $CHANNEL)"
CC_HEX="$(printf "%02x" $CC)"
VALUE_HEX="$(printf "%02x" $VALUE)"

DATA="$CHANNEL_HEX $CC_HEX $VALUE_HEX"

echo "Writing '$DATA' to $MIDI_DEVICE"
amidi -p $MIDI_DEVICE -S "$DATA"