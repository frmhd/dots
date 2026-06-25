#!/bin/sh

set -eu

lock_cmd='sh "$HOME/.config/niri/lock.sh"'

mode="${1:-full}"

if pgrep -x swayidle >/dev/null; then
    exit 0
fi

case "$mode" in
    minimal)
        exec swayidle -w \
            before-sleep "$lock_cmd" \
            after-resume 'niri msg action power-on-monitors' \
            lock "$lock_cmd"
        ;;
    full|*)
        exec swayidle -w \
            timeout 300 "$lock_cmd" \
            timeout 600 'niri msg action power-off-monitors' \
                resume 'niri msg action power-on-monitors' \
            before-sleep "$lock_cmd" \
            after-resume 'niri msg action power-on-monitors' \
            lock "$lock_cmd"
        ;;
esac
