#!/bin/sh

set -eu

if systemctl --user --quiet is-active wlsunset.service; then
    systemctl --user stop wlsunset.service
    notify-send 'Night Light' 'Disabled'
else
    systemctl --user start wlsunset.service
    notify-send 'Night Light' 'Enabled'
fi
