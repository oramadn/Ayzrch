#!/bin/bash
set -e

echo "=== Arch Rice Setup Starting ==="

RUN_ALL=false
if [[ "$1" == "-a" || "$1" == "--all" ]]; then
    RUN_ALL=true
fi

for script in scripts/*.sh; do
    name=$(basename "$script")

    # Optional scripts are prefixed with "opt-"
    if [[ "$name" == opt-* ]]; then
        if $RUN_ALL; then
            echo "Running (optional): $script"
            bash "$script"
        elif [[ -t 0 ]]; then
            read -rp "Run optional module ${name#opt-}? [y/N] " reply
            [[ "$reply" =~ ^[Yy]$ ]] && bash "$script" || echo ":: Skipped $name"
        else
            echo ":: Skipping optional: $name (pass --all to include)"
        fi
    else
        echo "Running: $script"
        bash "$script"
    fi
done

echo "=== Setup Complete ==="
