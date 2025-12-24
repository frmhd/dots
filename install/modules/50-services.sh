#!/bin/bash
# Module 50: System services
# Enables required systemd services

log_header "50" "System services..."

# Enable ly display manager
if systemctl list-unit-files | grep -q "ly.service"; then
    sudo systemctl enable ly.service
    log_ok "ly.service enabled"
else
    log_warn "ly.service not found (install ly package)"
fi

# Disable conflicting display managers
for dm in gdm sddm lightdm; do
    if systemctl is-enabled "$dm.service" &>/dev/null; then
        sudo systemctl disable "$dm.service"
        log_info "Disabled $dm.service"
    fi
done
