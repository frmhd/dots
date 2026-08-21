#!/bin/sh

wall=$(find "$HOME/Pictures/walls" -type f -print | while IFS= read -r path; do
    base=$(basename "$path")
    name=${base%.*}
    printf '%s\t%s\n' "$name" "$path"
done | fuzzel --dmenu --with-nth=1 --accept-nth=2)
[ -n "$wall" ] || exit 0

ln -nsf "$wall" "$HOME/.config/omarchy/current/background"
systemctl --user restart swaybg.service
