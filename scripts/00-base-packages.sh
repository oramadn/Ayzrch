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
    wtype \
    wl-clipboard \
    ufw \
    eza \
    libnotify \
    tmux \
    yazi \
    ripgrep \
    wl-clip-persist \
    plasma-integration
