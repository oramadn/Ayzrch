#!/bin/bash
set -e

echo ":: Installing Hyprland and essential Wayland packages..."

# Core Hyprland + Wayland dependencies
sudo pacman -S --needed --noconfirm \
    hyprland \
    wayland-protocols \
    wlroots \
    mako \
    wofi \
    swaybg \
    grim \
    slurp \
    foot \
    ghostty

# Optional: configure NVIDIA environment variables only if GPU is present
if lspci | grep -i 'nvidia' >/dev/null; then
    HYPRLAND_CONF="$HOME/.config/hypr/hyprland.conf"
    if [ -f "$HYPRLAND_CONF" ]; then
        echo ":: Adding NVIDIA environment variables to hyprland.conf"
        cat >>"$HYPRLAND_CONF" <<'EOF'

# NVIDIA environment variables
env = NVD_BACKEND,direct
env = LIBVA_DRIVER_NAME,nvidia
env = __GLX_VENDOR_LIBRARY_NAME,nvidia
EOF
    fi
fi

echo ":: Hyprland installation complete!"
