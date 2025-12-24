#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTS_DIR="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Stow-compatible directories (contain .config, .local, etc.)
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

# Directories that need special handling (not stow-compatible)
SPECIAL_DIRS=(
    themes
    install
)

check_stow() {
    if ! command -v stow &> /dev/null; then
        log_error "stow is not installed. Please run: sudo pacman -S stow"
        exit 1
    fi
}

stow_package() {
    local pkg="$1"
    local pkg_dir="$DOTS_DIR/$pkg"

    if [[ ! -d "$pkg_dir" ]]; then
        log_warn "Package directory not found: $pkg"
        return 1
    fi

    log_info "Stowing $pkg..."
    cd "$DOTS_DIR"
    stow -v --restow --target="$HOME" "$pkg" 2>&1 | grep -v "^$" || true
    log_success "Stowed $pkg"
}

unstow_package() {
    local pkg="$1"
    local pkg_dir="$DOTS_DIR/$pkg"

    if [[ ! -d "$pkg_dir" ]]; then
        log_warn "Package directory not found: $pkg"
        return 1
    fi

    log_info "Unstowing $pkg..."
    cd "$DOTS_DIR"
    stow -v --delete --target="$HOME" "$pkg" 2>&1 | grep -v "^$" || true
    log_success "Unstowed $pkg"
}

setup_themes() {
    log_info "Setting up themes..."

    # Create omarchy directory if it doesn't exist
    mkdir -p "$HOME/.local/share/omarchy"

    # Link themes directory
    if [[ ! -L "$HOME/.local/share/omarchy/themes" ]]; then
        ln -snf "$DOTS_DIR/themes" "$HOME/.local/share/omarchy/themes"
        log_success "Linked themes directory"
    else
        log_info "Themes directory already linked"
    fi

    # Set default theme if not set
    if [[ ! -L "$HOME/.local/share/omarchy/theme" ]]; then
        if [[ -d "$DOTS_DIR/themes/tokyo-night" ]]; then
            ln -snf "$DOTS_DIR/themes/tokyo-night" "$HOME/.local/share/omarchy/theme"
            log_success "Set default theme: tokyo-night"
        fi
    else
        log_info "Theme already set"
    fi
}

stow_all() {
    check_stow

    for pkg in "${STOW_PACKAGES[@]}"; do
        stow_package "$pkg"
    done

    setup_themes
    log_success "All dotfiles deployed!"
}

unstow_all() {
    check_stow

    for pkg in "${STOW_PACKAGES[@]}"; do
        unstow_package "$pkg"
    done

    log_success "All dotfiles removed!"
}

list_packages() {
    echo "=== Stow packages ==="
    for pkg in "${STOW_PACKAGES[@]}"; do
        if [[ -d "$DOTS_DIR/$pkg" ]]; then
            echo "  $pkg"
        else
            echo "  $pkg (missing)"
        fi
    done
    echo ""
    echo "=== Special directories ==="
    for dir in "${SPECIAL_DIRS[@]}"; do
        echo "  $dir"
    done
}

show_help() {
    echo "Usage: $0 [OPTIONS] [PACKAGE...]"
    echo ""
    echo "Deploy dotfiles using GNU Stow"
    echo ""
    echo "Options:"
    echo "  --all         Deploy all packages (default)"
    echo "  --unstow      Remove symlinks instead of creating them"
    echo "  --list        List available packages"
    echo "  -h, --help    Show this help"
    echo ""
    echo "Examples:"
    echo "  $0                    Deploy all packages"
    echo "  $0 nvim alacritty     Deploy specific packages"
    echo "  $0 --unstow nvim      Remove nvim symlinks"
}

main() {
    local action="stow"
    local packages=()

    while [[ $# -gt 0 ]]; do
        case $1 in
            --all)
                packages=("${STOW_PACKAGES[@]}")
                shift
                ;;
            --unstow)
                action="unstow"
                shift
                ;;
            --list)
                list_packages
                exit 0
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            *)
                packages+=("$1")
                shift
                ;;
        esac
    done

    check_stow

    # Default to all packages if none specified
    if [[ ${#packages[@]} -eq 0 ]]; then
        if [[ "$action" == "stow" ]]; then
            stow_all
        else
            unstow_all
        fi
        exit 0
    fi

    # Process specific packages
    for pkg in "${packages[@]}"; do
        if [[ "$action" == "stow" ]]; then
            stow_package "$pkg"
        else
            unstow_package "$pkg"
        fi
    done

    if [[ "$action" == "stow" ]]; then
        setup_themes
    fi
}

main "$@"
