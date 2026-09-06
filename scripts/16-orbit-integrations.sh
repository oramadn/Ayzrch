#!/bin/bash
set -e

# Optional Orbit integrations. Run after 15-orbit.sh.
# Upstream ships these as Flatpak integrations; the native Arch packages are
# wired up instead (see orbit/ATTRIBUTION.md).

ORBIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../orbit" && pwd)"

echo ":: Installing Orbit integrations..."

# ------------------------------------------------------------------------------
# 1. GPU Screen Recorder (Super+Shift+R records, Super+Shift+Z saves a replay)
# ------------------------------------------------------------------------------
sudo pacman -S --needed --noconfirm gpu-screen-recorder gpu-screen-recorder-ui ffmpeg
mkdir -p "$HOME/Videos/ScreenCap/replays" "$HOME/Videos/ScreenCap/recordings"

# ------------------------------------------------------------------------------
# 2. Zen Browser chrome overrides
# ------------------------------------------------------------------------------
# The Arch package keeps profiles under the XDG config dir; upstream tarballs
# use ~/.zen. configure-zen resolves either.
if [ -f "$HOME/.zen/profiles.ini" ] || [ -f "${XDG_CONFIG_HOME:-$HOME/.config}/zen/profiles.ini" ]; then
    "$ORBIT_DIR/bin/configure-zen"
else
    echo ":: Zen profile not found — launch Zen once, then rerun this script."
fi

# ------------------------------------------------------------------------------
# 3. LocalSend background service
# ------------------------------------------------------------------------------
sudo pacman -S --needed --noconfirm ufw
systemctl --user enable localsend.service

echo ":: Opening LocalSend's port (53317) in ufw..."
sudo ufw allow 53317/tcp
sudo ufw allow 53317/udp

# The device name can only be set once LocalSend has written its preferences.
if ! "$ORBIT_DIR/bin/configure-localsend" 2>/dev/null; then
    echo ":: LocalSend has no settings yet — launch it once, then run:"
    echo "   ~/.local/bin/configure-localsend"
fi

echo ":: Integrations complete."
