#!/bin/bash
set -e

echo ":: Git global configuration"
echo ""

# ── Name ──────────────────────────────────────────────────────────────────────
CURRENT_NAME=$(git config --global user.name 2>/dev/null || true)
if [ -n "$CURRENT_NAME" ]; then
    read -rp "   Name [$CURRENT_NAME]: " INPUT_NAME
    GIT_NAME="${INPUT_NAME:-$CURRENT_NAME}"
else
    read -rp "   Name: " GIT_NAME
fi

# ── Email ─────────────────────────────────────────────────────────────────────
CURRENT_EMAIL=$(git config --global user.email 2>/dev/null || true)
if [ -n "$CURRENT_EMAIL" ]; then
    read -rp "   Email [$CURRENT_EMAIL]: " INPUT_EMAIL
    GIT_EMAIL="${INPUT_EMAIL:-$CURRENT_EMAIL}"
else
    read -rp "   Email: " GIT_EMAIL
fi

# ── Editor ────────────────────────────────────────────────────────────────────
CURRENT_EDITOR=$(git config --global core.editor 2>/dev/null || true)
EDITOR_DEFAULT="${CURRENT_EDITOR:-nvim}"
read -rp "   Default editor [$EDITOR_DEFAULT]: " INPUT_EDITOR
GIT_EDITOR="${INPUT_EDITOR:-$EDITOR_DEFAULT}"

echo ""

# Apply core settings
[ -n "$GIT_NAME" ]   && git config --global user.name  "$GIT_NAME"
[ -n "$GIT_EMAIL" ]  && git config --global user.email "$GIT_EMAIL"
git config --global core.editor      "$GIT_EDITOR"
git config --global init.defaultBranch main
git config --global pull.rebase      false

echo "   Applied: name='$GIT_NAME'  email='$GIT_EMAIL'  editor='$GIT_EDITOR'"
echo ""

# ── SSH key ───────────────────────────────────────────────────────────────────
SSH_KEY="$HOME/.ssh/id_ed25519"

if [ -f "$SSH_KEY" ]; then
    echo ":: SSH key already exists at $SSH_KEY — skipping generation."
else
    read -rp ":: Generate a new ed25519 SSH key? [Y/n] " GEN_SSH
    GEN_SSH="${GEN_SSH:-Y}"
    if [[ "$GEN_SSH" =~ ^[Yy]$ ]]; then
        SSH_EMAIL="${GIT_EMAIL:-$(git config --global user.email 2>/dev/null || echo '')}"
        read -rp "   Key comment/email [$SSH_EMAIL]: " INPUT_SSH_EMAIL
        SSH_EMAIL="${INPUT_SSH_EMAIL:-$SSH_EMAIL}"

        mkdir -p "$HOME/.ssh"
        chmod 700 "$HOME/.ssh"
        ssh-keygen -t ed25519 -C "$SSH_EMAIL" -f "$SSH_KEY"
        eval "$(ssh-agent -s)"
        ssh-add "$SSH_KEY"

        echo ""
        echo ":: Add this public key to GitHub / GitLab / etc.:"
        echo "──────────────────────────────────────────────────"
        cat "${SSH_KEY}.pub"
        echo "──────────────────────────────────────────────────"
    fi
fi

echo ""
echo ":: Git configuration complete!"
