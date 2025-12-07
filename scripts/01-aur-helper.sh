#!/bin/bash
set -e

echo ":: Installing yay (AUR helper)..."

if ! command -v yay >/dev/null 2>&1; then
   sudo pacman -S --needed git base-devel
   git clone https://aur.archlinux.org/yay.git
   cd yay
   makepkg -si
fi

