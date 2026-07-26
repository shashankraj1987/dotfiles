#!/usr/bin/env bash
# Linux counterpart to scripts/update.ps1.
set -euo pipefail

echo "Updating apt packages..."
sudo apt-get update
sudo apt-get upgrade -y

if command -v oh-my-posh > /dev/null 2>&1; then
    echo "Updating Oh My Posh..."
    oh-my-posh upgrade || true
fi

if command -v asusctl > /dev/null 2>&1; then
    echo "Checking asusctl version..."
    installed_version=$(asusctl info 2>/dev/null | awk -F'v' '/^asusctl/{print $2}')
    latest_version=$(curl -fsS https://api.github.com/repos/OpenGamingCollective/asusctl/releases/latest 2>/dev/null | awk -F'"' '/"tag_name"/{print $4; exit}')
    if [ -n "$installed_version" ] && [ -n "$latest_version" ] && [ "$installed_version" != "$latest_version" ]; then
        echo "  asusctl $installed_version installed, $latest_version available: https://github.com/OpenGamingCollective/asusctl/releases/latest"
    fi
fi

echo "Done."
