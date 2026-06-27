#!/bin/bash
set -e

# ------------------------------------------------------------------------------
# 1. Define AUR packages to install
# ------------------------------------------------------------------------------
AUR_PACKAGES=(
    zen-browser-bin
    awww
    tmuxinator
    wayle-bin
    localsend-bin
    todoist-appimage
    pomatez
)

# ------------------------------------------------------------------------------
# 2. Detect AUR helper and set flags
# ------------------------------------------------------------------------------
if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
    AUR_FLAGS=(--needed --noconfirm --noclean --nopgpfetch --skipreview)
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
    AUR_FLAGS=(--needed --noconfirm --cleanafter )
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

# ------------------------------------------------------------------------------
# 4. Install nvm and latest Node.js / npm
# ------------------------------------------------------------------------------
NVM_DIR="$HOME/.nvm"

if [ ! -d "$NVM_DIR" ]; then
    echo ":: Installing nvm..."
    NVM_LATEST=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest \
        | grep '"tag_name"' | cut -d'"' -f4)
    curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${NVM_LATEST}/install.sh" | bash
fi

export NVM_DIR
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && source "$NVM_DIR/nvm.sh"

echo ":: Installing latest Node.js via nvm..."
nvm install node      # installs latest Node (bundles npm)
nvm use node
nvm alias default node

echo ":: Upgrading npm to latest..."
npm install -g npm@latest

echo ":: Node $(node -v) / npm $(npm -v) ready."

# ------------------------------------------------------------------------------
# 5. Install screenshot / clipping tools
# ------------------------------------------------------------------------------
echo ":: Installing screenshot and clipping tools..."
sudo pacman -S --noconfirm grim slurp satty wl-clipboard

# ------------------------------------------------------------------------------
# 6. Wayland desktop entry overrides for Electron apps
#    These apps default to X11; force Wayland so they work without XWayland.
# ------------------------------------------------------------------------------
APPS_DIR="$HOME/.local/share/applications"
LOCAL_BIN="$HOME/.local/bin"
mkdir -p "$APPS_DIR" "$LOCAL_BIN"

echo ":: Writing Wayland desktop entry override for Todoist..."
cat >"$APPS_DIR/todoist.desktop" <<'EOF'
[Desktop Entry]
Name=Todoist
Exec=env DESKTOPINTEGRATION=false /usr/bin/todoist %u --ozone-platform=wayland %U
Terminal=false
Type=Application
Icon=todoist
StartupWMClass=Todoist
Comment=The Best To-Do List App and Task Manager
MimeType=x-scheme-handler/todoist;x-scheme-handler/com.todoist;image/png;image/jpeg;image/webp;application/pdf;
Categories=Office;

[Desktop Action new-window]
Name=New Home Window
Exec=todoist --new-window
EOF

echo ":: Writing Wayland wrapper and desktop entry override for Pomatez..."
cat >"$LOCAL_BIN/pomatez" <<'EOF'
#!/bin/sh
exec /opt/Pomatez/pomatez --ozone-platform=wayland "$@"
EOF
chmod +x "$LOCAL_BIN/pomatez"

cat >"$APPS_DIR/pomatez.desktop" <<'EOF'
[Desktop Entry]
Name=Pomatez
Exec=/opt/Pomatez/pomatez --ozone-platform=wayland %U
Terminal=false
Type=Application
Icon=pomatez
StartupWMClass=Pomatez
Comment=Attractive pomodoro timer for Windows, Mac, and Linux.
Categories=Utility;
EOF

update-desktop-database "$APPS_DIR" 2>/dev/null || true

