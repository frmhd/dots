#!/bin/bash

set -euo pipefail

script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
current_theme_path="$HOME/.config/omarchy/current/theme"
zed_themes_dir="$HOME/.config/zed/themes"
generator_script="$script_dir/generate-zed-theme.sh"
template_file="$script_dir/zed-theme.tpl"

palette_source=""
appearance="dark"

if [[ -f "$current_theme_path/colors.toml" ]]; then
    palette_source="$current_theme_path/colors.toml"
elif [[ -f "$current_theme_path/alacritty.toml" ]]; then
    palette_source="$current_theme_path/alacritty.toml"
else
    echo "[set-theme] zed theme not changed: no colors.toml or alacritty.toml found"
    exit 0
fi

if [[ -f "$current_theme_path/light.mode" ]]; then
    appearance="light"
fi

mkdir -p "$zed_themes_dir"

if "$generator_script" "$palette_source" "$zed_themes_dir" "$template_file" "$appearance"; then
    pkill -HUP -x zed 2>/dev/null || true
else
    echo "[set-theme] zed theme generation failed"
fi
