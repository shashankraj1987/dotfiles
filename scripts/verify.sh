#!/usr/bin/env bash
# Linux counterpart to scripts/verify.ps1.
set -uo pipefail

# display-name:candidate binaries (space separated)
checks=(
    "git:git"
    "zsh:zsh"
    "eza:eza"
    "bat:bat batcat"
    "fd:fd fdfind"
    "ripgrep:rg"
    "zoxide:zoxide"
    "fzf:fzf"
    "bottom:btm"
    "oh-my-posh:oh-my-posh"
)

for entry in "${checks[@]}"; do
    IFS=':' read -r name candidates <<< "$entry"
    found=""

    for candidate in $candidates; do
        if command -v "$candidate" > /dev/null 2>&1; then
            found="$candidate"
            break
        fi
    done

    if [ -z "$found" ]; then
        printf '%-12s MISSING\n' "$name"
        continue
    fi

    version="$("$found" --version 2>/dev/null | head -n1)"
    [ -z "$version" ] && version="Installed"
    printf '%-12s %s\n' "$name" "$version"
done

if [ -d "${ZSH:-$HOME/.oh-my-zsh}" ]; then
    printf '%-12s Installed\n' "oh-my-zsh"
else
    printf '%-12s MISSING\n' "oh-my-zsh"
fi
