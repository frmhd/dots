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
DOTS_DIR="${DOTS_DIR:-$HOME/dev/system/dots}"
DESKTOP_DIR="$HOME/.local/share/applications"
BINDS_FILE="$DOTS_DIR/niri/.config/niri/binds.kdl"
TRANSLATOR_SCRIPT="$DOTS_DIR/niri/.config/niri/google-translate.sh"

KNOWN_BROWSERS='brave|firefox|helium-browser|chromium|/usr/bin/firefox|/usr/bin/chromium'
HIDDEN_MARKER='X-Dots-Set-Browser-Hidden=true'

if ! command -v "$BROWSER" >/dev/null 2>&1; then
  echo "Error: browser command not found: $BROWSER"
  exit 1
fi

if [[ ! -f "$BINDS_FILE" ]]; then
  echo "Error: niri binds file not found: $BINDS_FILE"
  exit 1
fi

# Only undo NoDisplay when this script was responsible for setting it.
set_desktop_hidden() {
  local file=$1
  local hidden=$2

  if [[ "$hidden" == true ]]; then
    if grep -qxF "$HIDDEN_MARKER" "$file"; then
      return
    fi

    # Preserve launchers that were already hidden for another reason.
    if grep -q '^NoDisplay=true$' "$file"; then
      return
    elif grep -q '^NoDisplay=' "$file"; then
      sed -i 's/^NoDisplay=.*/NoDisplay=true/' "$file"
    else
      printf '\nNoDisplay=true\n' >>"$file"
    fi
    printf '%s\n' "$HIDDEN_MARKER" >>"$file"
  elif grep -qxF "$HIDDEN_MARKER" "$file"; then
    sed -i -e '/^NoDisplay=true$/d' -e "/^${HIDDEN_MARKER}$/d" "$file"
  fi
}

set_app_bind() {
  local key_regex=$1
  local key=$2
  local command=$3
  sed -i -E "s#^([[:space:]]*)${key_regex} \\{.*#\\1${key} { ${command} }#" "$BINDS_FILE"
}

# Reuse the Chromium-style launchers for every browser. Firefox's undocumented
# taskbar mode gives these windows web-app behavior without a registered tab ID.
updated_desktops=0
while IFS= read -r -d '' file; do
  [[ $(basename "$file") == firefox.webapp-*.desktop ]] && continue

  if ! grep -qE '^Exec=[^ ]+ (--app=|-P kiosk-apps --kiosk --new-window |--new-window |-taskbar-tab [^ ]+ -new-window )' "$file"; then
    continue
  fi

  set_desktop_hidden "$file" false
  if [[ "$BROWSER_BASE" == firefox ]]; then
    sed -i -E "s#^Exec=[^ ]+ (--app=|-P kiosk-apps --kiosk --new-window |--new-window |-taskbar-tab [^ ]+ -new-window )#Exec=${BROWSER} -taskbar-tab 0 -new-window #" "$file"
  else
    sed -i -E "s#^Exec=[^ ]+ (--app=|-P kiosk-apps --kiosk --new-window |--new-window |-taskbar-tab [^ ]+ -new-window )#Exec=${BROWSER} --app=#" "$file"
  fi

  updated_desktops=$((updated_desktops + 1))
done < <(find "$DESKTOP_DIR" -maxdepth 1 -type f -name '*.desktop' -print0)

# Add-to-Taskbar launchers are redundant and would duplicate the reused apps.
while IFS= read -r -d '' file; do
  set_desktop_hidden "$file" true
done < <(find "$DESKTOP_DIR" -maxdepth 1 -type f -name 'firefox.webapp-*.desktop' -print0)

if [[ "$BROWSER_BASE" == firefox ]]; then
  set_app_bind 'Mod\+Shift\+A' 'Mod+Shift+A' "spawn \"${BROWSER}\" \"-taskbar-tab\" \"0\" \"-new-window\" \"https://google.com/ai\";"
  set_app_bind 'Mod\+Shift\+G' 'Mod+Shift+G' "spawn \"${BROWSER}\" \"-taskbar-tab\" \"0\" \"-new-window\" \"https://gemini.google.com\";"
  set_app_bind 'Mod\+Shift\+X' 'Mod+Shift+X' "spawn \"${BROWSER}\" \"-taskbar-tab\" \"0\" \"-new-window\" \"https://x.com\";"
else
  set_app_bind 'Mod\+Shift\+A' 'Mod+Shift+A' "spawn \"${BROWSER}\" \"--app=https://google.com/ai\" \"--profile-directory=Default\";"
  set_app_bind 'Mod\+Shift\+G' 'Mod+Shift+G' "spawn \"${BROWSER}\" \"--app=https://gemini.google.com\" \"--profile-directory=Default\";"
  set_app_bind 'Mod\+Shift\+X' 'Mod+Shift+X' "spawn \"${BROWSER}\" \"--app=https://x.com\" \"--profile-directory=Default\";"
fi

sed -i -E "s#spawn \"(${KNOWN_BROWSERS})\"#spawn \"${BROWSER}\"#g" "$BINDS_FILE"
updated_binds=$(grep -cE "spawn \"${BROWSER}\"" "$BINDS_FILE" || true)

if [[ -f "$TRANSLATOR_SCRIPT" ]]; then
  sed -i "s|^browser=.*|browser=${BROWSER}|" "$TRANSLATOR_SCRIPT"
fi

if command -v update-desktop-database >/dev/null 2>&1; then
  update-desktop-database "$DESKTOP_DIR" >/dev/null
fi

# Map browser binary to its .desktop file for xdg-settings.
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
echo "Updated $updated_desktops web app launcher(s), $updated_binds niri bind(s)."
echo "Reload niri config if binds changed: niri msg action load-config-file"
