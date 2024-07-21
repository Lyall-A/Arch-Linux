#!/bin/bash

cd $(dirname "%0")

echo "Creating virtual sink..."
pactl load-module module-null-sink sink_name=Main
pactl set-default-sink Main
sleep 2

echo "Starting Carla..."
carla --no-gui ./.carxp &
sleep 2

echo "Starting qpwgraph..."
qpwgraph --activated --minimized ./.qpwgraph &
sleep 2

echo "Starting xbindkeys..."
xbindkeys --file ./.xbindkeysrc &
sleep 2