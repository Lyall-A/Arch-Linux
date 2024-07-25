#!/bin/bash

sleep 5

# Apply NVIDIA settings
if [ -f /usr/bin/nvidia-settings ]; then /usr/bin/nvidia-settings -l; fi

# Setup audio
./Arch-Linux/Audio\ Stuff/setup-audio.sh
