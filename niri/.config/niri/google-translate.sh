#!/bin/sh

set -eu

url='https://translate.google.com/'
browser=firefox

launch_browser() {
    if [ "${browser##*/}" = firefox ]; then
        "$browser" --new-window "$url"
    else
        "$browser" --app="$url" --profile-directory=Default
    fi
}

if [ "${1:-}" != '--paste' ]; then
    launch_browser
    exit
fi

launch_browser &
sleep 2

if primary=$(wl-paste --primary --no-newline 2>/dev/null) && [ -n "$primary" ]; then
    printf '%s' "$primary" | wl-copy
    wtype -M ctrl -k v -m ctrl
    wl-copy --clear --primary
elif clipboard=$(wl-paste --no-newline 2>/dev/null) && [ -n "$clipboard" ]; then
    wtype -M ctrl -k v -m ctrl
fi
