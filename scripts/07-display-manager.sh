#!/bin/bash
set -e

# Install Ly Display Manager
echo ":: Installing Ly display manager..."
sudo pacman -S --needed --noconfirm ly

# Ensure your user exists
USER_NAME="${USER:-$(whoami)}"
echo ":: Setting up autologin for user: $USER_NAME"

# Configure Ly for autologin
LY_CONF="/etc/ly/config.ini"

# Backup original config
if [ ! -f "${LY_CONF}.backup" ]; then
    sudo cp "$LY_CONF" "${LY_CONF}.backup"
fi

# Enable autologin
sudo sed -i "s/^autologin = .*/autologin = $USER_NAME/" "$LY_CONF"

# Set Hyprland as default session
sudo sed -i "s|^default = .*|default = Hyprland|" "$LY_CONF"

# Enable Ly service
echo ":: Enabling Ly service..."
sudo systemctl enable ly.service

echo ":: Ly display manager installed and configured!"
echo ":: Upon reboot, your system will auto-login and start Hyprland."

