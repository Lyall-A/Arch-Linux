#!/bin/bash

CC=$1
VALUE=$2

MIDI_DEVICE="hw:4,0"
CHANNEL="15"

amidi -p $MIDI_DEVICE -S "$(printf "b%x" $CHANNEL) $(printf "%02x" $CC) $(printf "%02x" $VALUE)"