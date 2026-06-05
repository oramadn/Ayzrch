#!/bin/bash
set -e

echo ":: Setting up wayle bar and dependencies..."

# ------------------------------------------------------------------------------
# 1. Install dependencies
# ------------------------------------------------------------------------------
sudo pacman -S --needed --noconfirm \
    networkmanager \
    pamixer \
    upower \
    polkit \
    wl-clipboard

# ------------------------------------------------------------------------------
# 2. Enable and start NetworkManager with iwd as WiFi backend
# ------------------------------------------------------------------------------
sudo mkdir -p /etc/NetworkManager/conf.d
sudo tee /etc/NetworkManager/conf.d/wifi-backend.conf > /dev/null <<'EOF'
[device]
wifi.backend=iwd
EOF

sudo systemctl enable --now NetworkManager

# ------------------------------------------------------------------------------
# 3. Install wayle (AUR)
# ------------------------------------------------------------------------------
if ! command -v wayle &>/dev/null; then
    paru -S --noconfirm wayle-bin
fi

echo ":: Wayle setup complete!"
echo ":: Run 'matugen image <wallpaper>' to generate the wayle config."
echo ":: Wayle starts automatically via Hyprland startup.conf."
