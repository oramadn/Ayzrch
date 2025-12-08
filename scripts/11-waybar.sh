#!/bin/bash
set -e

echo ":: Installing Waybar..."

# ------------------------------------------------------------------------------
# 1. Install Waybar and dependencies
# ------------------------------------------------------------------------------
sudo pacman -S --needed --noconfirm \
    waybar \
    wl-clipboard \
    imagemagick \
    polkit \
    pamixer \
    networkmanager \
    jq

# ------------------------------------------------------------------------------
# 2. Create user config directory
# ------------------------------------------------------------------------------
WAYBAR_CONFIG_DIR="$HOME/.config/waybar"
mkdir -p "$WAYBAR_CONFIG_DIR"

# ------------------------------------------------------------------------------
# 3. Create a minimal default config if missing
# ------------------------------------------------------------------------------
WAYBAR_CONFIG="$WAYBAR_CONFIG_DIR/config"
WAYBAR_STYLE="$WAYBAR_CONFIG_DIR/style.css"

if [ ! -f "$WAYBAR_CONFIG" ]; then
    cat > "$WAYBAR_CONFIG" <<'EOF'
{
    "layer": "top",
    "position": "top",
    "modules-left": ["sway/workspaces"],
    "modules-center": ["clock"],
    "modules-right": ["network", "pulseaudio", "battery"]
}
EOF
fi

if [ ! -f "$WAYBAR_STYLE" ]; then
    cat > "$WAYBAR_STYLE" <<'EOF'
* {
    font-family: "DejaVu Sans Mono";
    font-size: 10px;
    background-color: #222222;
    color: #ffffff;
}
EOF
fi

echo ":: Waybar installation complete!"
echo ":: Configure modules and styling further by editing $WAYBAR_CONFIG_DIR/config and style.css"

