#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[OK]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step() { echo -e "\n${CYAN}${BOLD}=== $1 ===${NC}\n"; }

show_banner() {
    echo -e "${CYAN}"
    echo "╔═══════════════════════════════════════╗"
    echo "║         System Setup Script           ║"
    echo "║         Arch Linux + Wayland          ║"
    echo "╚═══════════════════════════════════════╝"
    echo -e "${NC}"
}

confirm() {
    local prompt="$1"
    local default="${2:-y}"

    if [[ "$default" == "y" ]]; then
        prompt="$prompt [Y/n]: "
    else
        prompt="$prompt [y/N]: "
    fi

    read -p "$prompt" response
    response=${response:-$default}

    [[ "$response" =~ ^[Yy] ]]
}

run_step() {
    local name="$1"
    local script="$2"

    if confirm "Run $name?"; then
        log_step "$name"
        bash "$SCRIPT_DIR/$script"
        log_success "$name completed"
    else
        log_warn "Skipping $name"
    fi
}

install_packages() {
    run_step "Package Installation" "install-packages.sh"
}

deploy_dotfiles() {
    run_step "Dotfiles Deployment" "deploy-dotfiles.sh"
}

install_dev_tools() {
    log_step "Development Tools"

    if confirm "Install nvm (Node Version Manager)?"; then
        bash "$SCRIPT_DIR/nvm.sh"
    fi

    if confirm "Install bun?"; then
        bash "$SCRIPT_DIR/bun.sh"
    fi
}

setup_shell() {
    log_step "Shell Setup"

    if [[ "$SHELL" != *"zsh"* ]]; then
        if confirm "Change default shell to zsh?"; then
            chsh -s $(which zsh)
            log_success "Default shell changed to zsh"
            log_warn "Please log out and back in for changes to take effect"
        fi
    else
        log_info "zsh is already the default shell"
    fi
}

enable_services() {
    log_step "System Services"

    local services=(
        "ly.service"
    )

    for service in "${services[@]}"; do
        if confirm "Enable $service?"; then
            sudo systemctl enable "$service" || log_warn "Failed to enable $service"
        fi
    done
}

set_theme() {
    log_step "Theme Selection"

    local themes_dir="$SCRIPT_DIR/../themes"
    if [[ -d "$themes_dir" ]]; then
        echo "Available themes:"
        ls -1 "$themes_dir" | grep -v "\.sh$" | grep -v "^set-" | while read theme; do
            if [[ -d "$themes_dir/$theme" ]]; then
                echo "  - $theme"
            fi
        done
        echo ""

        read -p "Enter theme name (or press Enter to skip): " theme_name
        if [[ -n "$theme_name" && -d "$themes_dir/$theme_name" ]]; then
            "$themes_dir/set-theme" "$theme_name"
            log_success "Theme set to $theme_name"
        fi
    fi
}

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Full system setup script for Arch Linux + Wayland"
    echo ""
    echo "Options:"
    echo "  --packages     Only install packages"
    echo "  --dotfiles     Only deploy dotfiles"
    echo "  --dev          Only install dev tools (nvm, bun)"
    echo "  --shell        Only setup shell"
    echo "  --services     Only enable services"
    echo "  --theme        Only set theme"
    echo "  --all          Run all steps (interactive)"
    echo "  --auto         Run all steps (non-interactive, accept defaults)"
    echo "  -h, --help     Show this help"
}

main() {
    cd "$SCRIPT_DIR"

    if [[ $# -eq 0 ]]; then
        show_banner
        install_packages
        deploy_dotfiles
        install_dev_tools
        setup_shell
        enable_services
        set_theme

        echo ""
        log_success "System setup complete!"
        echo ""
        echo "Next steps:"
        echo "  1. Log out and back in to apply shell changes"
        echo "  2. Start niri or hyprland: niri-session"
        echo "  3. Use set-theme to change themes"
        exit 0
    fi

    while [[ $# -gt 0 ]]; do
        case $1 in
            --packages)
                install_packages
                shift
                ;;
            --dotfiles)
                deploy_dotfiles
                shift
                ;;
            --dev)
                install_dev_tools
                shift
                ;;
            --shell)
                setup_shell
                shift
                ;;
            --services)
                enable_services
                shift
                ;;
            --theme)
                set_theme
                shift
                ;;
            --all)
                show_banner
                install_packages
                deploy_dotfiles
                install_dev_tools
                setup_shell
                enable_services
                set_theme
                shift
                ;;
            --auto)
                show_banner
                log_info "Running in non-interactive mode..."
                bash "$SCRIPT_DIR/install-packages.sh"
                bash "$SCRIPT_DIR/deploy-dotfiles.sh"
                bash "$SCRIPT_DIR/nvm.sh"
                bash "$SCRIPT_DIR/bun.sh"
                shift
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
}

main "$@"
