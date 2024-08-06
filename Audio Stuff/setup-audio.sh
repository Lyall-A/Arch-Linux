#!/bin/bash
# Script to setup EVERYTHING

# CD into this directory
cd "$(dirname "$0")"

# Log everything here
exec &> setup-audio.log

# Check modprobe and modules-load for virtual MIDI setup
if [ -f "/etc/modprobe.d/modprobe-virtual-midi.conf" ]; then echo "Virtual MIDI modprobe file exists"; else echo "Virtual MIDI modprobe file not found!"; fi
if [ -f "/etc/modules-load.d/modules-load-virtual-midi.conf" ]; then echo "Virtual MIDI modules-load file exists"; else echo "Virtual MIDI modules-load not found!"; fi

# Create virtual sinks and set default
echo "Creating virtual sinks..."
echo "Main sink: $(pactl load-module module-null-sink sink_name=Main)"
echo "Music sink: $(pactl load-module module-null-sink sink_name=Music)"
echo "Video sink: $(pactl load-module module-null-sink sink_name=Video)"
echo "Output sink: $(pactl load-module module-null-sink sink_name=Output)"
pactl set-default-sink Main

echo "Creating virtual inputs..."
echo "Mic 1: $(pactl load-module module-virtual-source source_name=Mic1 channel_map=mono)"
echo "Mic 2: $(pactl load-module module-virtual-source source_name=Mic2 channel_map=mono)"
pactl set-default-source output.Mic1

# Start Carla (plugin host)
echo "Starting Carla..."
carla --no-gui ./.carxp &> ./Carla.log &
sleep 2

# Start qpwgraph (for routing and graph)
echo "Starting qpwgraph..."
qpwgraph --minimized --deactivated --nonexclusive ./.qpwgraph &> ./qpwgraph.log &
sleep 2

# Start audio monitoring script (monitors for new nodes)
echo "Starting audio monitoring script..."
./monitor-audio.sh &> ./monitor-audio.log &

# Start update routes script (for routing)
echo "Starting routes update script..."
./update-routes.sh &> ./update-routes.log &

# Start MIDI update script (makes sure MIDI doesn't get changed)
echo "Starting MIDI update script..."
./update-midi.sh &> ./update-midi.log &

# Start xbindkeys (keyboard bindings for MIDI)
echo "Starting xbindkeys..."
xbindkeys --file ./.xbindkeysrc &> ./xbindkeys.log &