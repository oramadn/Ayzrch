#!/bin/bash
set -e

echo ":: Installing Zsh..."

# ------------------------------------------------------------------------------
# 1. Install Zsh only
# ------------------------------------------------------------------------------
sudo pacman -S --needed --noconfirm zsh

# ------------------------------------------------------------------------------
# 2. Set up Zsh config folder in .config
# ------------------------------------------------------------------------------
ZSH_CONFIG_DIR="$HOME/.config/zsh"
ZSHRC="$ZSH_CONFIG_DIR/zshrc"

mkdir -p "$ZSH_CONFIG_DIR"

# Create a starter zshrc if it doesn't exist
if [ ! -f "$ZSHRC" ]; then
    cat > "$ZSHRC" <<'EOF'
# Minimal starter zshrc

# --- Plugins ---
source ~/.zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source ~/.zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
EOF
fi

# Symlink ~/.zshrc → .config/zsh/zshrc
if [ ! -L "$HOME/.zshrc" ]; then
    ln -s "$ZSHRC" "$HOME/.zshrc"
fi

# Starship
sudo pacman -S --needed --noconfirm starship

# Ensure Starship is initialized in zshrc
if ! grep -q 'starship init zsh' "$ZSHRC"; then
    echo 'eval "$(starship init zsh)"' >> "$ZSHRC"
fi

# Create default starship config if missing
STARSHIP_CFG="$HOME/.config/starship.toml"
if [ ! -f "$STARSHIP_CFG" ]; then
    cat > "$STARSHIP_CFG" <<'EOF'
add_newline = false

[character]
success_symbol = "❯"
error_symbol = "❯"
EOF
fi

# ------------------------------------------------------------------------------
# 3. Install Zsh plugin managers
# ------------------------------------------------------------------------------
ZSH_CUSTOM="$HOME/.zsh"
mkdir -p "$ZSH_CUSTOM/plugins"

# zsh-autosuggestions
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions \
        "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi

# zsh-syntax-highlighting
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting \
        "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ------------------------------------------------------------------------------
# 4. Set Zsh as default shell
# ------------------------------------------------------------------------------
if [ "$SHELL" != "/usr/bin/zsh" ]; then
    echo ":: Setting Zsh as default shell..."
    chsh -s /usr/bin/zsh
fi

echo ":: Zsh installation complete!"

