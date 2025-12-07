#!/bin/bash
set -e

sudo pacman -S --needed --noconfirm pciutils

echo ":: Detecting NVIDIA GPU..."

if lspci | grep -i 'nvidia' >/dev/null; then
    echo ":: NVIDIA GPU detected"

    # Determine driver
    if lspci | grep -i 'nvidia' | grep -q -E "RTX [2-9][0-9]|GTX 16"; then
        NVIDIA_DRIVER_PACKAGE="nvidia-open-dkms"
    else
        NVIDIA_DRIVER_PACKAGE="nvidia-dkms"
    fi

    # Determine kernel headers
    KERNEL_HEADERS="linux-headers"
    if pacman -Q linux-zen &>/dev/null; then
        KERNEL_HEADERS="linux-zen-headers"
    elif pacman -Q linux-lts &>/dev/null; then
        KERNEL_HEADERS="linux-lts-headers"
    elif pacman -Q linux-hardened &>/dev/null; then
        KERNEL_HEADERS="linux-hardened-headers"
    fi

    echo ":: Installing NVIDIA packages..."
    PACKAGES=(
        "$KERNEL_HEADERS"
        "$NVIDIA_DRIVER_PACKAGE"
        "nvidia-utils"
        "lib32-nvidia-utils"
        "egl-wayland"
        "libva-nvidia-driver"
        "qt5-wayland"
        "qt6-wayland"
    )
    sudo pacman -Syu --needed --noconfirm "${PACKAGES[@]}"

    # Enable early KMS
    echo "options nvidia_drm modeset=1" | sudo tee /etc/modprobe.d/nvidia.conf >/dev/null

    # Update mkinitcpio
    MKINITCPIO_CONF="/etc/mkinitcpio.conf"
    sudo cp "$MKINITCPIO_CONF" "${MKINITCPIO_CONF}.backup"

    NVIDIA_MODULES="nvidia nvidia_modeset nvidia_uvm nvidia_drm"
    sudo sed -i -E 's/ nvidia_drm//g; s/ nvidia_uvm//g; s/ nvidia_modeset//g; s/ nvidia//g;' "$MKINITCPIO_CONF"
    sudo sed -i -E "s/^(MODULES=\()/\1${NVIDIA_MODULES} /" "$MKINITCPIO_CONF"
    sudo sed -i -E 's/  +/ /g' "$MKINITCPIO_CONF"

    sudo mkinitcpio -P

    echo ":: NVIDIA driver installation complete!"
else
    echo ":: No NVIDIA GPU detected. Skipping NVIDIA driver installation."
fi

