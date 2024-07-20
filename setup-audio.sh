#!/bin/bash

echo "Creating virtual sink..."
pactl load-module module-null-sink sink_name=Main
pactl set-default-sink Main

echo "Starting Carla..."
carla --no-gui ~/carla.carxp &
sleep 5

echo "Starting qpwgraph..."
qpwgraph --activated --exclusive --minimized ~/qpwgraph.qpwgraph &
sleep 5
