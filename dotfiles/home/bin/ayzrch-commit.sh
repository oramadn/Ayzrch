#!/usr/bin/env bash
# Commit everything in the Ayzrch repo: rice and dotfiles together.
#
# The successor to chezmoi-commit.sh. Since $HOME is symlinked into the repo,
# editing any config anywhere shows up here, and this is the one command that
# records it. The repo location is resolved from this script's own path rather
# than hardcoded, so moving the clone does not break it.

set -euo pipefail

repo_dir=$(cd -- "$(dirname -- "$(readlink -f "$0")")/../../.." && pwd)
cd "$repo_dir" || { printf 'Failed to cd into %s\n' "$repo_dir" >&2; exit 1; }

git add -A
if git diff --cached --quiet; then
    printf 'No changes to commit in %s.\n' "$repo_dir"
    exit 0
fi

printf 'Changes staged in %s:\n\n' "$repo_dir"
git diff --cached --stat
printf '\n'

read -r -p "Commit message: " message
[[ -n "$message" ]] || { printf 'Commit message cannot be empty.\n' >&2; exit 1; }

git commit -m "$message"
git push
