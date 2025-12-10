#!/bin/bash
set -e

echo ":: Installing base packages..."

sudo pacman -Syu --noconfirm

sudo pacman -S --needed --noconfirm \
    base-devel \
    git \
    less \
    curl \
    wget \
    nano \
    neovim \
    unzip \
    zip \
    openssh \
    chezmoi \
    rofi \
    waybar-hyprland \
    wtype \
    wl-clipboard \
    rofi-emoji \
    feh \
    ufw

