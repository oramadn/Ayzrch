#!/bin/bash
set -e

echo ":: Installing yay (AUR helper)..."

if ! command -v yay >/dev/null 2>&1; then
   sudo pacman -S --needed --noconfirm git base-devel
   rm -rf /tmp/yay-build
   git clone https://aur.archlinux.org/yay.git /tmp/yay-build
   cd /tmp/yay-build
   makepkg -si --noconfirm
   cd -
fi

