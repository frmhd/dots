#!/bin/bash
# Monitor brightness control with swayosd progress bar
# Usage: brightness-control.sh [up|down]

if [ "$1" == "up" ]; then
    ddcutil setvcp 10 + 10
elif [ "$1" == "down" ]; then
    ddcutil setvcp 10 - 10
else
    echo "Usage: $0 [up|down]"
    exit 1
fi

# Get current brightness value
brightness=$(ddcutil getvcp 10 | grep -oP 'current value =\s+\K\d+')

# Display progress bar with swayosd
swayosd-client \
    --custom-icon=display-brightness-symbolic \
    --custom-progress=$(echo "scale=2; $brightness / 100" | bc) \
    --custom-progress-text="$brightness%"
