#!/bin/bash
set -e

echo "=== Arch Rice Setup Starting ==="

for script in scripts/*.sh; do
    echo "Running: $script"
    bash "$script"
done

echo "=== Setup Complete ==="

