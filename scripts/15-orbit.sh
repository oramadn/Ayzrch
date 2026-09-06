#!/bin/bash
set -e

# Orbit desktop: Hyprland + Noctalia + QuickShell global menu + plugins.
# Vendored from CleanShirtUK/dotfiles; see orbit/ATTRIBUTION.md.
#
#   15-orbit.sh                 full install
#   15-orbit.sh --plugins-only  rebuild the four Hyprland plugins (after a
#                               Hyprland upgrade) and nothing else

ORBIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../orbit" && pwd)"
PLUGINS_ONLY=false
[[ "${1:-}" == "--plugins-only" ]] && PLUGINS_ONLY=true

# ------------------------------------------------------------------------------
# Plugin builds. Each installer is idempotent, pins an upstream commit, and only
# writes ~/.local/share/hyprland/plugins/ — the running compositor is untouched.
# ------------------------------------------------------------------------------
build_plugins() {
    echo ":: Building Hyprland plugins (pinned commits)..."
    "$ORBIT_DIR/bin/install-hyprglass"
    "$ORBIT_DIR/bin/install-scrolloverview"
    "$ORBIT_DIR/arch/install-hyprwindowshade"
    "$ORBIT_DIR/arch/install-dynamic-cursors"
}

if $PLUGINS_ONLY; then
    build_plugins
    echo ":: Plugins rebuilt. Restart Hyprland to load them."
    exit 0
fi

echo ":: Installing Orbit desktop..."

# ------------------------------------------------------------------------------
# 1. Repository packages
# ------------------------------------------------------------------------------
sudo pacman -S --needed --noconfirm \
    hyprland \
    hypridle \
    hyprlock \
    hyprpolkitagent \
    xdg-desktop-portal \
    xdg-desktop-portal-hyprland \
    nwg-displays \
    qt6ct \
    jq \
    socat \
    zenity \
    alsa-utils \
    python-pyudev \
    python-evdev \
    fastfetch \
    grim \
    slurp \
    wl-clipboard \
    libcanberra \
    satty \
    hyprpicker \
    playerctl \
    brightnessctl \
    dolphin \
    wayland \
    libpng \
    mesa \
    libglvnd \
    base-devel \
    git \
    patch \
    lua54

# ------------------------------------------------------------------------------
# 2. AUR packages (no non-git builds exist for noctalia/quickshell)
# ------------------------------------------------------------------------------
AUR_PACKAGES=(
    noctalia-git
    quickshell-git
    hyprqt6engine
    kora-icon-theme
)

if command -v paru >/dev/null 2>&1; then
    AUR_HELPER="paru"
    AUR_FLAGS=(--needed --noconfirm --noclean --nopgpfetch --skipreview)
elif command -v yay >/dev/null 2>&1; then
    AUR_HELPER="yay"
    AUR_FLAGS=(--needed --noconfirm --cleanafter)
else
    echo "!! No AUR helper found. Run scripts/01-aur-helper.sh first."
    exit 1
fi

echo ":: Installing AUR packages with $AUR_HELPER..."
$AUR_HELPER -S "${AUR_FLAGS[@]}" "${AUR_PACKAGES[@]}"

# ------------------------------------------------------------------------------
# 3. Input group. orbit-input-state reads /dev/input/event* to track the Alt key
#    for Alt+Tab. Upstream wraps it in `sg input`, which does not exist on Arch
#    (shadow ships newgrp only), so membership is granted directly. Takes effect
#    at the next login.
# ------------------------------------------------------------------------------
if ! id -nG | tr ' ' '\n' | grep -qx input; then
    echo ":: Adding $USER to the 'input' group (needed for Alt+Tab)..."
    sudo usermod -aG input "$USER"
    echo ":: Group membership applies at your next login."
fi

# ------------------------------------------------------------------------------
# 4. Cursor theme (no Arch package; GitHub release)
# ------------------------------------------------------------------------------
"$ORBIT_DIR/arch/install-oblique-cursor"

# ------------------------------------------------------------------------------
# 5. Back up any pre-Orbit config. Orbit's deploy refuses to overwrite existing
#    files, so these directories must be out of the way first.
# ------------------------------------------------------------------------------
STAMP="$(date +%Y-%m-%d)"
for dir in hypr kitty wezterm; do
    target="$HOME/.config/$dir"
    # Only a real directory of someone else's files is in the way; an existing
    # Orbit deployment is a directory of symlinks into this repo and is fine.
    if [ -d "$target" ] && ! find "$target" -maxdepth 1 -lname "$ORBIT_DIR/*" -print -quit | grep -q .; then
        backup="$HOME/.config/$dir.pre-orbit-$STAMP"
        [ -e "$backup" ] && backup="$backup-$(date +%H%M%S)"
        mv "$target" "$backup"
        echo ":: Backed up $target -> $backup"
    fi
done

# ------------------------------------------------------------------------------
# 6. Noctalia templates. Orbit's adapters read the rendered output of these
#    built-in templates, so install the config before Noctalia first runs.
# ------------------------------------------------------------------------------
mkdir -p "$HOME/.config/noctalia"
install -m 0644 "$ORBIT_DIR/arch/noctalia-templates.toml" \
    "$HOME/.config/noctalia/10-orbit-templates.toml"

# Seed a fallback monitor layout. hyprland.lua requires this module, and
# nwg-displays cannot generate the real one until a Hyprland session is running,
# so the first login needs something valid to load. It is a plain file, never a
# symlink: nwg-displays rewrites it in place.
if [ ! -e "$HOME/.config/hypr/monitors.lua" ]; then
    install -D -m 0644 "$ORBIT_DIR/arch/monitors.lua.default" "$HOME/.config/hypr/monitors.lua"
    echo ":: Seeded a fallback ~/.config/hypr/monitors.lua (replace it with nwg-displays)."
fi

# ------------------------------------------------------------------------------
# 7. Deploy. migrate --dry-run must report READY FOR ADOPTION first; anything
#    else means an unexpected file is in the way and deploy would refuse.
# ------------------------------------------------------------------------------
echo ":: Checking for conflicting files..."
MIGRATE_REPORT="$(mktemp)"
if ! "$ORBIT_DIR/bootstrap/migrate" --dry-run >"$MIGRATE_REPORT" 2>&1; then
    grep -E "BLOCK|BLOCKED" "$MIGRATE_REPORT" || tail -20 "$MIGRATE_REPORT"
    echo "!! Orbit found unexpected files at its destinations (listed above)."
    echo "   Full report: $MIGRATE_REPORT"
    echo "   Move or remove those files, then rerun this script."
    exit 1
fi
tail -1 "$MIGRATE_REPORT"
rm -f "$MIGRATE_REPORT"

echo ":: Deploying Orbit..."
# The final step of deploy asks a running Noctalia to apply templates. Noctalia
# is not up during install; orbit-session-bootstrap redoes it at first login.
if ! "$ORBIT_DIR/bootstrap/deploy"; then
    echo ":: Colour adapters deferred to the first Hyprland login (Noctalia is not running)."
fi

# ------------------------------------------------------------------------------
# 8. Plugins
# ------------------------------------------------------------------------------
build_plugins

# ------------------------------------------------------------------------------
# 9. Wallpaper Engine (separate GPL-3.0 project, built from its pinned tag)
# ------------------------------------------------------------------------------
echo ":: Installing Orbit Wallpaper Engine..."
ORBIT_WALLPAPER_REPO_URL=https://github.com/CleanShirtUK/orbit-wallpaper-engine.git \
    "$ORBIT_DIR/bin/dotfiles-install-wallpaper"


# ------------------------------------------------------------------------------
# 10. Verify
# ------------------------------------------------------------------------------
"$ORBIT_DIR/bootstrap/verify"

cat <<'EOF'

:: Orbit installed. Remaining steps are interactive:

   1. Log out and pick "Hyprland" in Ly (not hyprland-uwsm).
   2. Noctalia's setup wizard runs on first login — choose a wallpaper.
      Every colour in the desktop is derived from it.
   3. Run `nwg-displays` to arrange your monitors. It writes
      ~/.config/hypr/monitors.lua, which is per-machine and never synced.
      Workspaces are then assigned to connected monitors automatically at login.
   4. Run scripts/16-orbit-integrations.sh for Zen theming, LocalSend and
      GPU Screen Recorder.

   After a Hyprland upgrade, rebuild the plugins: scripts/15-orbit.sh --plugins-only
EOF
