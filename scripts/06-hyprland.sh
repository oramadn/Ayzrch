#!/bin/bash
set -e

echo ":: Installing Hyprland and essential Wayland packages..."

# Core Hyprland + Wayland dependencies
sudo pacman -S --needed --noconfirm \
    hyprland \
    wayland-protocols \
    wlroots0.19 \
    wofi \
    grim \
    slurp \
    foot \
    ghostty \
    hyprlock \
    hypridle

# NVIDIA environment variables now live in orbit/config/hypr/hyprland.lua,
# guarded on /proc/driver/nvidia/version. Hyprland 0.55+ uses the Lua config,
# so there is no hyprland.conf to append to. See scripts/15-orbit.sh.

echo ":: Hyprland installation complete!"
