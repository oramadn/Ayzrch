#!/bin/bash
set -e

echo ":: Setting up dual boot menu (systemd-boot)..."

ESP="/boot"
WIN_DISK="/dev/nvme0n1p1"
TMP_MNT="/mnt/efi_other"

# --- Detect other OS EFI partition ---
if [[ ! -b "$WIN_DISK" ]]; then
    echo ":: $WIN_DISK not found — skipping dual boot setup"
    exit 0
fi

# Mount the other ESP
sudo mkdir -p "$TMP_MNT"
sudo mount "$WIN_DISK" "$TMP_MNT"

FOUND_WINDOWS=false
FOUND_UBUNTU=false

[[ -f "$TMP_MNT/EFI/Microsoft/Boot/bootmgfw.efi" ]] && FOUND_WINDOWS=true
[[ -f "$TMP_MNT/EFI/ubuntu/shimx64.efi" ]] && FOUND_UBUNTU=true

if ! $FOUND_WINDOWS && ! $FOUND_UBUNTU; then
    echo ":: No Windows or Ubuntu EFI found on $WIN_DISK — skipping"
    sudo umount "$TMP_MNT"
    sudo rmdir "$TMP_MNT"
    exit 0
fi

# --- Windows ---
if $FOUND_WINDOWS; then
    if [[ ! -f "$ESP/EFI/Microsoft/Boot/bootmgfw.efi" ]]; then
        echo ":: Copying Windows EFI files to current ESP..."
        sudo mkdir -p "$ESP/EFI/Microsoft/Boot"
        sudo cp -r "$TMP_MNT/EFI/Microsoft/." "$ESP/EFI/Microsoft/"
    else
        echo ":: Windows EFI already present on current ESP"
    fi

    if [[ ! -f "$ESP/loader/entries/windows.conf" ]]; then
        echo ":: Creating systemd-boot entry for Windows..."
        sudo tee "$ESP/loader/entries/windows.conf" > /dev/null <<'EOF'
title   Windows
efi     /EFI/Microsoft/Boot/bootmgfw.efi
EOF
        echo ":: Windows entry created"
    else
        echo ":: Windows boot entry already exists"
    fi
fi

# --- Ubuntu ---
if $FOUND_UBUNTU; then
    if [[ ! -f "$ESP/EFI/ubuntu/shimx64.efi" ]]; then
        echo ":: Copying Ubuntu EFI files to current ESP..."
        sudo mkdir -p "$ESP/EFI/ubuntu"
        sudo cp -r "$TMP_MNT/EFI/ubuntu/." "$ESP/EFI/ubuntu/"
    else
        echo ":: Ubuntu EFI already present on current ESP"
    fi

    if [[ ! -f "$ESP/loader/entries/ubuntu.conf" ]]; then
        echo ":: Creating systemd-boot entry for Ubuntu..."
        sudo tee "$ESP/loader/entries/ubuntu.conf" > /dev/null <<'EOF'
title   Ubuntu
efi     /EFI/ubuntu/shimx64.efi
EOF
        echo ":: Ubuntu entry created"
    else
        echo ":: Ubuntu boot entry already exists"
    fi
fi

# --- Cleanup ---
sudo umount "$TMP_MNT"
sudo rmdir "$TMP_MNT"

# --- Set boot menu timeout if not already configured ---
LOADER_CONF="$ESP/loader/loader.conf"
if ! grep -q '^timeout' "$LOADER_CONF" 2>/dev/null || grep -q '^timeout 0$' "$LOADER_CONF" 2>/dev/null; then
    echo ":: Setting boot menu timeout to 5 seconds..."
    sudo sed -i 's/^timeout.*/timeout 5/' "$LOADER_CONF"
    if ! grep -q '^timeout' "$LOADER_CONF"; then
        echo "timeout 5" | sudo tee -a "$LOADER_CONF" > /dev/null
    fi
fi

echo ":: Dual boot setup complete"
echo "   Entries in $ESP/loader/entries/:"
ls "$ESP/loader/entries/"
