#!/bin/bash
set -e

echo ":: Installing base applications and fonts..."

FONTS=(
    noto-fonts
    noto-fonts-emoji
    ttf-dejavu
    ttf-liberation
    ttf-jetbrains-mono
    ttf-nerd-fonts-symbols
)

echo ":: Installing fonts..."
sudo pacman -S --needed --noconfirm "${FONTS[@]}"
