#!/bin/bash
set -e

echo ":: Installing niri scrollable-tiling Wayland compositor..."

sudo pacman -S --needed --noconfirm niri

# Append NVIDIA environment variables to config if GPU is present and config exists
if lspci | grep -i 'nvidia' >/dev/null; then
    NIRI_CONF="$HOME/.config/niri/config.kdl"
    if [ -f "$NIRI_CONF" ] && ! grep -q 'NVD_BACKEND' "$NIRI_CONF"; then
        echo ":: Adding NVIDIA environment variables to niri config..."
        cat >>"$NIRI_CONF" <<'EOF'

// NVIDIA environment variables (added by setup)
environment {
    NVD_BACKEND "direct"
    LIBVA_DRIVER_NAME "nvidia"
    __GLX_VENDOR_LIBRARY_NAME "nvidia"
}
EOF
    fi
fi

# Set system-wide dark theme via gsettings (dconf)
echo ":: Applying dark theme..."
gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita-dark'

echo ":: niri installation complete!"
