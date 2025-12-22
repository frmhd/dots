#!/bin/bash

# Check if unzip is installed
if ! pacman -Q unzip &>/dev/null; then
    echo "unzip is required but not installed. Installing..."
    sudo pacman -S --noconfirm --needed unzip
fi

curl -fsSL https://bun.sh/install | bash