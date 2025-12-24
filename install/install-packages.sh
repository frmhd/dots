#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES_DIR="$SCRIPT_DIR/packages"

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

# Parse package file (skip comments and empty lines)
parse_packages() {
    grep -v '^#' "$1" | grep -v '^$' | tr '\n' ' '
}

install_yay() {
    if command -v yay &> /dev/null; then
        log_success "yay is already installed"
        return 0
    fi

    log_info "Installing yay AUR helper..."
    local tmp_dir=$(mktemp -d)
    cd "$tmp_dir"
    git clone https://aur.archlinux.org/yay-bin.git
    cd yay-bin
    makepkg -si --noconfirm
    cd /
    rm -rf "$tmp_dir"
    log_success "yay installed successfully"
}

install_official() {
    if [[ ! -f "$PACKAGES_DIR/official.txt" ]]; then
        log_warn "No official.txt found, skipping official packages"
        return 0
    fi

    local packages=$(parse_packages "$PACKAGES_DIR/official.txt")
    if [[ -z "$packages" ]]; then
        log_warn "No official packages to install"
        return 0
    fi

    log_info "Installing official packages..."
    sudo pacman -Syu --needed --noconfirm $packages
    log_success "Official packages installed"
}

install_aur() {
    if [[ ! -f "$PACKAGES_DIR/aur.txt" ]]; then
        log_warn "No aur.txt found, skipping AUR packages"
        return 0
    fi

    local packages=$(parse_packages "$PACKAGES_DIR/aur.txt")
    if [[ -z "$packages" ]]; then
        log_warn "No AUR packages to install"
        return 0
    fi

    log_info "Installing AUR packages..."
    yay -S --needed --noconfirm $packages
    log_success "AUR packages installed"
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --official    Install only official packages"
    echo "  --aur         Install only AUR packages"
    echo "  --yay         Install only yay AUR helper"
    echo "  --all         Install everything (default)"
    echo "  --list        List packages without installing"
    echo "  -h, --help    Show this help"
}

list_packages() {
    echo "=== Official packages ==="
    if [[ -f "$PACKAGES_DIR/official.txt" ]]; then
        parse_packages "$PACKAGES_DIR/official.txt" | tr ' ' '\n' | grep -v '^$'
    fi
    echo ""
    echo "=== AUR packages ==="
    if [[ -f "$PACKAGES_DIR/aur.txt" ]]; then
        parse_packages "$PACKAGES_DIR/aur.txt" | tr ' ' '\n' | grep -v '^$'
    fi
}

main() {
    local install_official=false
    local install_aur=false
    local install_yay_only=false

    if [[ $# -eq 0 ]]; then
        install_official=true
        install_aur=true
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --official)
                install_official=true
                shift
                ;;
            --aur)
                install_aur=true
                shift
                ;;
            --yay)
                install_yay_only=true
                shift
                ;;
            --all)
                install_official=true
                install_aur=true
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
            *)
                log_error "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done

    if $install_yay_only; then
        install_yay
        exit 0
    fi

    if $install_official; then
        install_official
    fi

    if $install_aur; then
        install_yay
        install_aur
    fi

    log_success "Package installation complete!"
}

main "$@"
