#!/bin/bash
set -e

echo ":: Arabic language setup"
echo ""

# ── Arabic fonts ──────────────────────────────────────────────────────────────
echo ":: Arabic fonts are bundled in noto-fonts (already installed)."

# ── Toggle shortcut ───────────────────────────────────────────────────────────
echo ""
echo "   Choose a keyboard layout toggle shortcut:"
echo "   1) Alt+Shift  (default)"
echo "   2) Super+Space"
echo "   3) CapsLock"
read -rp "   Choice [1]: " TOGGLE_CHOICE
TOGGLE_CHOICE="${TOGGLE_CHOICE:-1}"

case "$TOGGLE_CHOICE" in
    2) KB_OPTIONS="grp:win_space_toggle" ;;
    3) KB_OPTIONS="grp:caps_toggle" ;;
    *) KB_OPTIONS="grp:alt_shift_toggle" ;;
esac

echo "   Using: $KB_OPTIONS"

# ── Patch hyprland.conf ───────────────────────────────────────────────────────
HYPR_CONF="$HOME/.config/hypr/hyprland.conf"
mkdir -p "$HOME/.config/hypr"

if [ -f "$HYPR_CONF" ]; then
    # Update existing kb_layout line to include Arabic
    if grep -q "kb_layout" "$HYPR_CONF"; then
        # Add ,ara if not already there
        if ! grep -q "kb_layout.*ara" "$HYPR_CONF"; then
            sed -i 's/kb_layout\s*=\s*/kb_layout = /' "$HYPR_CONF"
            sed -i '/kb_layout/s/$/,ara/' "$HYPR_CONF"
        fi
        # Update or insert kb_options
        if grep -q "kb_options" "$HYPR_CONF"; then
            sed -i "s/kb_options\s*=.*/kb_options = $KB_OPTIONS/" "$HYPR_CONF"
        else
            sed -i "/kb_layout/a\\    kb_options = $KB_OPTIONS" "$HYPR_CONF"
        fi
    else
        # No input block kb_layout found — append a new input block
        cat >> "$HYPR_CONF" <<EOF

input {
    kb_layout = us,ara
    kb_options = $KB_OPTIONS
}
EOF
    fi
else
    # No config yet — create a stub with the input block
    cat > "$HYPR_CONF" <<EOF
input {
    kb_layout = us,ara
    kb_options = $KB_OPTIONS
}
EOF
fi

echo ""
echo ":: Arabic layout added. Toggle with your chosen shortcut after restarting Hyprland."
