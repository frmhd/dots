#!/bin/bash
THEME_DIR="$HOME/dev/system/dots/themes"

# List directories in themes folder, excluding scripts/files
THEMES=$(find "$THEME_DIR" -maxdepth 1 -mindepth 1 -type d -not -path '*/.*' -exec basename {} \; | sort)

SELECTED=$(echo "$THEMES" | fuzzel -d -p "󰔉 Theme > " --width 30)

if [[ -n "$SELECTED" ]]; then
    "$THEME_DIR/set-theme" "$SELECTED"
    notify-send "Theme Changed" "Active theme: $SELECTED"
fi
