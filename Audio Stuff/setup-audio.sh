#!/bin/bash

cd "$(dirname "$0")"

echo "Creating virtual sinks..."
pactl load-module module-null-sink sink_name=Main
pactl load-module module-null-sink sink_name=Music
pactl set-default-sink Main
sleep 2

echo "Starting Carla..."
carla ./.carxp &
sleep 2

echo "Starting qpwgraph..."
qpwgraph --activated --minimized ./.qpwgraph &
sleep 2

echo "Starting audio monitoring script..."
./monitor-audio.sh &
sleep 2

echo "Starting xbindkeys..."
xbindkeys --file ./.xbindkeysrc &
sleep 2
