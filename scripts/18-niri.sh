#!/bin/bash
set -e

# Orbit on niri: the same desktop, driven by a scrollable-tiling compositor.
#
# It is numbered 18 so setup.sh reaches it after 15-orbit.sh: the scripts run in
# numeric order, this one needs Orbit already deployed, and it exits non-zero if
# it is not -- which under setup.sh's `set -e` would abort the whole install.
#
# Orbit installs the shell, the palette, the theme adapters and the QuickShell
# global menu; all of that is compositor-independent and is reused unchanged.
# This script adds what niri needs on top -- the compositor, its Xwayland and
# portal backends, the session entry Ly offers at login -- and deploys Orbit's
# niri configuration.
#
# Nothing here touches the Hyprland session. Both remain installed and the
# compositor is chosen at the login screen.

ORBIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../orbit" && pwd)"

echo ":: Installing niri and its session dependencies..."

# xwayland-satellite gives niri the Xwayland that Hyprland has built in; Steam,
# Affinity and the other X11 clients Orbit carries rules for need it.
# xdg-desktop-portal-gnome is what niri's shipped portals.conf prefers, and it
# is the only backend implementing ScreenCast for niri — without it screen
# sharing and the recorder have nothing to talk to.
# nwg-displays supports niri natively, so monitor arrangement is the same GUI
# step as under Hyprland; scripts/15-orbit.sh has already installed it.
sudo pacman -S --needed --noconfirm \
    niri \
    xwayland-satellite \
    xdg-desktop-portal-gnome \
    xdg-desktop-portal-gtk \
    nwg-displays

# ------------------------------------------------------------------------------
# Orbit must already be installed: the niri session starts Noctalia, the global
# menu and orbit-session-bootstrap, and reads Noctalia's palette.
# ------------------------------------------------------------------------------
if [ ! -x "$HOME/.local/bin/orbit-session-bootstrap" ]; then
    echo "!! Orbit is not deployed yet. Run scripts/15-orbit.sh first."
    exit 1
fi

# ------------------------------------------------------------------------------
# Back up a pre-Orbit niri config. Orbit's deploy refuses to overwrite files it
# does not own, and a hand-written config.kdl is exactly such a file.
# ------------------------------------------------------------------------------
STAMP="$(date +%Y-%m-%d)"
target="$HOME/.config/niri"
if [ -d "$target" ] && [ ! -L "$target/orbit.kdl" ]; then
    backup="$HOME/.config/niri.pre-orbit-$STAMP"
    [ -e "$backup" ] && backup="$backup-$(date +%H%M%S)"
    mv "$target" "$backup"
    echo ":: Backed up $target -> $backup"
    echo "   Your old config is there. Re-run nwg-displays for the monitors;"
    echo "   move anything else you want into ~/.config/niri/local.kdl, which"
    echo "   Orbit never replaces."
fi

# ------------------------------------------------------------------------------
# Deploy. This links Orbit's niri configuration and seeds the files that are
# yours — config.kdl, which Noctalia appends its palette include to, monitor.kdl,
# which nwg-displays rewrites, and local.kdl for everything else machine-local.
# ------------------------------------------------------------------------------
echo ":: Deploying Orbit's niri configuration..."
if ! "$ORBIT_DIR/bootstrap/deploy"; then
    echo ":: Colour adapters deferred to the first login (Noctalia is not running)."
fi

# ------------------------------------------------------------------------------
# Noctalia's niri palette template. Orbit's template config enables it, but a
# Noctalia that is already running has to be told to re-read it.
# ------------------------------------------------------------------------------
install -m 0644 "$ORBIT_DIR/arch/noctalia-templates.toml" \
    "$HOME/.config/noctalia/10-orbit-templates.toml"
if command -v noctalia >/dev/null 2>&1; then
    noctalia msg templates-apply >/dev/null 2>&1 || true
fi

# ------------------------------------------------------------------------------
# Session entry. Ly reads wayland-sessions; the launcher sets PATH and the GPU
# environment that niri's KDL cannot express before exec'ing the compositor.
# ------------------------------------------------------------------------------
echo ":: Installing the Orbit (niri) session entry..."
sudo install -D -m 0755 "$ORBIT_DIR/bin/orbit-niri-session" \
    /usr/local/bin/orbit-niri-session
sudo install -D -m 0644 "$ORBIT_DIR/desktop/orbit-niri.desktop" \
    /usr/share/wayland-sessions/orbit-niri.desktop

"$ORBIT_DIR/bootstrap/verify"

cat <<'EOF'

:: Orbit on niri installed.

   1. Log out and pick "Orbit (niri)" in Ly. "Hyprland" is still there and
      unchanged; the two sessions share Noctalia, the palette and every theme
      adapter, so switching between them changes navigation, not appearance.
   2. Run `nwg-displays` to arrange monitors, exactly as under Hyprland. It
      writes ~/.config/niri/monitor.kdl and asks niri to reload, so the layout
      applies live with the usual revert-on-timeout prompt. Adaptive sync and
      10-bit are there too; only workspace assignment is greyed out, because
      niri's workspaces are dynamic.

   3. Super+/ opens the same Orbit cheatsheet as under Hyprland. It is generated
      from the niri config, so it always matches what the keys actually do.

:: What differs from the Hyprland session

   - Windows tile in scrollable columns instead of floating by default, and
     Super+comma / Super+period move a window in and out of a column.
   - Alt+Tab opens niri's real workspace overview rather than ScrollOverview.
   - Hyprglass refraction, HyprWindowShade ripples and cursor tilt are Hyprland
     plugins with no niri equivalent. Blur, shadows and rounding are native and
     configured to match; the rest are absent.
EOF
