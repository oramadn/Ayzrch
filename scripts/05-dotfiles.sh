#!/bin/bash
set -e

echo ":: Dotfiles setup (chezmoi)"
echo ""

CHEZMOI_DIR="$HOME/.local/share/chezmoi"

# ── Already initialised ───────────────────────────────────────────────────────
if [ -d "$CHEZMOI_DIR/.git" ]; then
    echo "   chezmoi already initialised at $CHEZMOI_DIR"
    read -rp "   Re-apply existing dotfiles? [Y/n] " APPLY
    APPLY="${APPLY:-Y}"
    if [[ "$APPLY" =~ ^[Yy]$ ]]; then
        chezmoi apply
        echo ":: Dotfiles applied."
    else
        echo ":: Skipped."
    fi
    exit 0
fi

# ── Fresh init ────────────────────────────────────────────────────────────────
read -rp "   Dotfiles repo URL (leave blank to skip): " REPO_URL

if [ -z "$REPO_URL" ]; then
    echo ":: Skipping dotfiles setup."
    exit 0
fi

echo ":: Running: chezmoi init --apply $REPO_URL"
chezmoi init --apply "$REPO_URL"

echo ""
echo ":: Dotfiles applied successfully!"
