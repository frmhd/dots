#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") <browser-bin>"
  echo "Example: $(basename "$0") helium-browser"
  exit 1
}

[[ $# -eq 1 ]] || usage

BROWSER="$1"
script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
DOTS_DIR="${DOTS_DIR:-$HOME/dev/system/dots}"
DESKTOP_DIR="$HOME/.local/share/applications"
BINDS_FILE="$DOTS_DIR/niri/.config/niri/binds.kdl"

KNOWN_BROWSERS='brave|helium-browser|chromium|/usr/bin/chromium'

if ! command -v "$BROWSER" >/dev/null 2>&1; then
  echo "Error: browser command not found: $BROWSER"
  exit 1
fi

if [[ ! -f "$BINDS_FILE" ]]; then
  echo "Error: niri binds file not found: $BINDS_FILE"
  exit 1
fi

updated_desktops=0
while IFS= read -r -d '' file; do
  if grep -qE '^Exec=[^ ]+ --app=' "$file"; then
    sed -i "s|^Exec=[^ ]* --app=|Exec=${BROWSER} --app=|" "$file"
    updated_desktops=$((updated_desktops + 1))
    echo "Desktop: $(basename "$file")"
  fi
done < <(find "$DESKTOP_DIR" -maxdepth 1 -name '*.desktop' -print0)

sed -i -E "s#spawn \"(${KNOWN_BROWSERS})\"#spawn \"${BROWSER}\"#g" "$BINDS_FILE"
updated_binds=$(grep -cE "spawn \"${BROWSER}\"" "$BINDS_FILE" || true)

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" >/dev/null
fi

# Map browser binary to its .desktop file for xdg-settings
declare -A DESKTOP_MAP
DESKTOP_MAP=( [brave]=brave-browser.desktop [chromium]=chromium.desktop [helium-browser]=helium-browser.desktop )

# Extract base name from BROWSER (strip path)
BROWSER_BASE=$(basename "$BROWSER")
DESKTOP_FILE="${DESKTOP_MAP[$BROWSER_BASE]:-}"

if [[ -n "$DESKTOP_FILE" ]] && command -v xdg-settings >/dev/null 2>&1; then
  xdg-settings set default-web-browser "$DESKTOP_FILE"
  echo "Default browser set via xdg-settings: $DESKTOP_FILE"
elif [[ -z "$DESKTOP_FILE" ]]; then
  echo "Warning: no mapping for $BROWSER_BASE to a .desktop file; xdg-settings not updated"
fi

echo ""
echo "Browser set to: $BROWSER"
echo "Updated $updated_desktops web app(s), $updated_binds niri bind(s)."
echo "Reload niri config if binds changed: niri msg action load-config-file"
