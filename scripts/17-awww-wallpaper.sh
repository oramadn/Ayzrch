#!/bin/bash
set -e

# Wallpapers: awww renders, Noctalia picks. See docs/awww-live-wallpaper.md.
AWWW_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../awww" && pwd)"

echo ":: Installing awww..."
sudo pacman -S --needed --noconfirm awww

echo ":: Linking awww integration..."
mkdir -p "$HOME/.local/bin" "$HOME/.config/systemd/user" "$HOME/.config/noctalia" \
         "${XDG_PICTURES_DIR:-$HOME/Pictures}"
ln -sfn "$AWWW_DIR/bin/awww-noctalia-hook"            "$HOME/.local/bin/awww-noctalia-hook"
ln -sfn "$AWWW_DIR/systemd/user/awww-daemon.service"  "$HOME/.config/systemd/user/awww-daemon.service"
ln -sfn "$AWWW_DIR/config/noctalia/20-awww-wallpaper.toml" \
        "$HOME/.config/noctalia/20-awww-wallpaper.toml"

systemctl --user daemon-reload
systemctl --user enable awww-daemon.service

# Only meaningful inside a running Hyprland session.
if systemctl --user is-active --quiet hyprland-session.target; then
    systemctl --user start awww-daemon.service
    noctalia msg config-reload >/dev/null 2>&1 || true
    if command -v noctalia >/dev/null && current="$(noctalia msg wallpaper-get 2>/dev/null)"; then
        [[ -n "$current" ]] && NOCTALIA_WALLPAPER_PATH="$current" "$HOME/.local/bin/awww-noctalia-hook" || true
    fi
fi

echo ":: awww ready. Pick a wallpaper from Noctalia's picker to test."
