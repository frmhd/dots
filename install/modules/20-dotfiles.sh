#!/bin/bash
# Module 20: Dotfiles deployment
# Uses GNU Stow to symlink configurations

log_header "20" "Deploying dotfiles..."

# Stow packages to deploy
STOW_PACKAGES=(
    alacritty
    btop
    claude
    electron-and-browsers-flags
    elephant
    fontconfig
    hypr
    mako
    niri
    nvim
    swayosd
    walker
    waybar
)

# Check stow is installed
if ! has_cmd stow; then
    log_err "stow is not installed"
    exit 1
fi

# Stow each package
cd "$DOTS_DIR"
for pkg in "${STOW_PACKAGES[@]}"; do
    if [[ -d "$DOTS_DIR/$pkg" ]]; then
        stow --restow --target="$HOME" "$pkg" 2>/dev/null || true
        log_ok "Stowed $pkg"
    else
        log_warn "Package not found: $pkg"
    fi
done

# Setup theme system
log_info "Setting up theme system..."
mkdir -p "$HOME/.local/share/omarchy"
mkdir -p "$HOME/.config/omarchy/current"

# Link themes directory
if [[ ! -L "$HOME/.local/share/omarchy/themes" ]]; then
    ln -snf "$DOTS_DIR/themes" "$HOME/.local/share/omarchy/themes"
fi

# Set default theme if not set
if [[ ! -L "$HOME/.config/omarchy/current/theme" ]]; then
    if [[ -d "$DOTS_DIR/themes/flexoki-light" ]]; then
        ln -snf "$DOTS_DIR/themes/flexoki-light" "$HOME/.config/omarchy/current/theme"
        log_ok "Default theme: flexoki-light"
    elif [[ -d "$DOTS_DIR/themes/tokyo-night" ]]; then
        ln -snf "$DOTS_DIR/themes/tokyo-night" "$HOME/.config/omarchy/current/theme"
        log_ok "Default theme: tokyo-night"
    fi
else
    current_theme=$(basename "$(readlink -f "$HOME/.config/omarchy/current/theme")")
    log_ok "Theme already set: $current_theme"
fi

log_ok "Dotfiles deployed"
