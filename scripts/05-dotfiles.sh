#!/bin/bash
set -e

# Personal dotfiles: editor, shell, terminal, multiplexer.
#
# This used to hand off to chezmoi and a second repository. It no longer does.
# Everything lives in dotfiles/ here, and is symlinked into $HOME, so editing
# the live file edits the repo -- `git status` is the list of changes you have
# not committed. One repo, one clone, one source of truth.
#
# chezmoi was carrying no templates, no encrypted files and no per-machine
# data, so nothing was lost in the move. If per-machine variance is wanted
# later, dotfiles/deploy is where to add it.
#
# Safe to run before or after the Orbit scripts: nothing here depends on Orbit,
# and the three files Orbit also writes into are seeded rather than linked, so
# neither side clobbers the other.

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../dotfiles" && pwd)"

echo ":: Deploying dotfiles from $DOTFILES_DIR"
"$DOTFILES_DIR/deploy"

cat <<'EOF'

:: Dotfiles deployed.

   They are symlinks into this repository. Edit them anywhere -- ~/.zshrc,
   :e in nvim, your tmux config -- and commit from the repo when you are happy.

   Anything moved aside is kept next to the original as *.pre-orbit-<date>.
EOF
