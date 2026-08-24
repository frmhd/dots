#!/bin/bash

set -euo pipefail

usage() {
  echo "Usage: $(basename "$0") <browser-bin>"
  echo "Example: $(basename "$0") helium-browser"
  exit 1
}

[[ $# -eq 1 ]] || usage

BROWSER="$1"
BROWSER_BASE=$(basename "$BROWSER")
script_dir=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
DOTS_DIR="${DOTS_DIR:-$HOME/dev/system/dots}"
DESKTOP_DIR="$HOME/.local/share/applications"
BINDS_FILE="$DOTS_DIR/niri/.config/niri/binds.kdl"
TRANSLATOR_SCRIPT="$DOTS_DIR/niri/.config/niri/google-translate.sh"

KNOWN_BROWSERS='brave|firefox|helium-browser|chromium|/usr/bin/firefox|/usr/bin/chromium'

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
    if [[ "$BROWSER_BASE" == firefox ]]; then
      sed -i "s|^Exec=[^ ]* --app=|Exec=${BROWSER} --new-window |" "$file"
    else
      sed -i "s|^Exec=[^ ]* --app=|Exec=${BROWSER} --app=|" "$file"
    fi
  elif grep -qE '^Exec=[^ ]+ -P kiosk-apps --kiosk --new-window ' "$file"; then
    if [[ "$BROWSER_BASE" == firefox ]]; then
      sed -i "s|^Exec=[^ ]* -P kiosk-apps --kiosk --new-window |Exec=${BROWSER} --new-window |" "$file"
    else
      sed -i "s|^Exec=[^ ]* -P kiosk-apps --kiosk --new-window |Exec=${BROWSER} --app=|" "$file"
    fi
  elif grep -qE '^Exec=[^ ]+ --new-window ' "$file"; then
    if [[ "$BROWSER_BASE" == firefox ]]; then
      sed -i "s|^Exec=[^ ]* --new-window |Exec=${BROWSER} --new-window |" "$file"
    else
      sed -i "s|^Exec=[^ ]* --new-window |Exec=${BROWSER} --app=|" "$file"
    fi
  else
    continue
  fi

  updated_desktops=$((updated_desktops + 1))
  echo "Desktop: $(basename "$file")"
done < <(find "$DESKTOP_DIR" -maxdepth 1 -name '*.desktop' -print0)

if [[ "$BROWSER_BASE" == firefox ]]; then
  sed -i -E "s#spawn \"(${KNOWN_BROWSERS})\" \"--app=([^\"]+)\"( \"--profile-directory=[^\"]+\")?#spawn \"${BROWSER}\" \"--new-window\" \"\2\"#g" "$BINDS_FILE"
  sed -i -E "s#spawn \"(${KNOWN_BROWSERS})\" \"-P\" \"kiosk-apps\" \"--kiosk\" \"--new-window\" \"([^\"]+)\"#spawn \"${BROWSER}\" \"--new-window\" \"\2\"#g" "$BINDS_FILE"
else
  sed -i -E "s#spawn \"(${KNOWN_BROWSERS})\" \"-P\" \"kiosk-apps\" \"--kiosk\" \"--new-window\" \"([^\"]+)\"#spawn \"${BROWSER}\" \"--app=\2\" \"--profile-directory=Default\"#g" "$BINDS_FILE"
  sed -i -E "s#spawn \"(${KNOWN_BROWSERS})\" \"--new-window\" \"([^\"]+)\"#spawn \"${BROWSER}\" \"--app=\2\" \"--profile-directory=Default\"#g" "$BINDS_FILE"
fi
sed -i -E "s#spawn \"(${KNOWN_BROWSERS})\"#spawn \"${BROWSER}\"#g" "$BINDS_FILE"
updated_binds=$(grep -cE "spawn \"${BROWSER}\"" "$BINDS_FILE" || true)

if [[ -f "$TRANSLATOR_SCRIPT" ]]; then
  sed -i "s|^browser=.*|browser=${BROWSER}|" "$TRANSLATOR_SCRIPT"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" >/dev/null
fi

# Map browser binary to its .desktop file for xdg-settings
declare -A DESKTOP_MAP
DESKTOP_MAP=( [brave]=brave-browser.desktop [chromium]=chromium.desktop [firefox]=firefox.desktop [helium-browser]=helium-browser.desktop )

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
