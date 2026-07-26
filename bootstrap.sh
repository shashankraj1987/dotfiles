#!/usr/bin/env bash
# Linux counterpart to bootstrap.ps1: installs packages and wires up the zsh profile.
set -euo pipefail

FORCE=false
SKIP_PACKAGES=false
SKIP_ZSH=false

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --skip-packages) SKIP_PACKAGES=true ;;
        --skip-zsh) SKIP_ZSH=true ;;
        *)
            echo "Unknown option: $arg" >&2
            exit 1
            ;;
    esac
done

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALLER_ROOT="$REPO_ROOT/installers"

source "$INSTALLER_ROOT/common.sh"

write_banner "Linux Developer Environment Setup"

source "$INSTALLER_ROOT/packages.sh"
source "$INSTALLER_ROOT/zsh.sh"
source "$INSTALLER_ROOT/git.sh"

$SKIP_PACKAGES && disable_step "packages"
$SKIP_ZSH && disable_step "zsh"

invoke_steps "$FORCE"

echo ""
write_success "Bootstrap complete."
write_step "Restart your terminal (or run 'exec zsh') to load the updated profile."
