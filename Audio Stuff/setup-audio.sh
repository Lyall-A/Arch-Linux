#!/bin/bash

cd "$(dirname "$0")"

exec &> setup-audio.log

if [ -f "/etc/modprobe.d/modprobe-virtual-midi.conf" ]; then echo "Virtual MIDI modprobe file exists"; else echo "Virtual MIDI modprobe file not found!"; fi
if [ -f "/etc/modules-load.d/modules-load-virtual-midi.conf" ]; then echo "Virtual MIDI modules-load file exists"; else echo "Virtual MIDI modules-load not found!"; fi

echo "Creating virtual sinks..."
echo "Main sink: $(pactl load-module module-null-sink sink_name=Main)"
echo "Music sink: $(pactl load-module module-null-sink sink_name=Music)"
pactl set-default-sink Main
sleep 2

echo "Starting Carla..."
carla ./.carxp &> ./Carla.log &
sleep 2

echo "Starting qpwgraph..."
qpwgraph --activated --minimized ./.qpwgraph &> ./qpwgraph.log &
sleep 2

echo "Starting audio monitoring script..."
./monitor-audio.sh &> ./monitor-audio.log &
sleep 2

echo "Starting xbindkeys..."
xbindkeys --verbose --file ./.xbindkeysrc &> ./xbindkeys.log &
sleep 2
