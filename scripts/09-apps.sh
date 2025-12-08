#!/bin/bash
set -e

# ------------------------------------------------------------------------------
# 1. Define AUR packages to install
# ------------------------------------------------------------------------------
AUR_PACKAGES=(
    zen-browser-bin
    matugen
    swww
)

# ------------------------------------------------------------------------------
# 2. Detect AUR helper and set flags
# ------------------------------------------------------------------------------
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
    AUR_FLAGS=(--needed --noconfirm --noclean --nodiffmenu --nopgpfetch --skipreview)
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
    AUR_FLAGS=(--needed --noconfirm --cleanafter --nocleanmenu --nodiffmenu --noeditmenu)
else
    AUR_HELPER=""
fi

# ------------------------------------------------------------------------------
# 3. Install AUR packages
# ------------------------------------------------------------------------------
if [ -n "$AUR_HELPER" ]; then
    echo ":: Installing AUR packages with $AUR_HELPER..."
    $AUR_HELPER -S "${AUR_FLAGS[@]}" "${AUR_PACKAGES[@]}"
else
    echo "!! No AUR helper found, skipping AUR installs."
fi

