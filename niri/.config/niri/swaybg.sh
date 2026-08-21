#!/bin/sh

set -eu

background="$HOME/.config/omarchy/current/background"

if [ -f "$background" ]; then
    exec swaybg -i "$background" -m fill
else
    exec swaybg --color '#000000'
fi
