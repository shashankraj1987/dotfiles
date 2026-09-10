#!/usr/bin/env bash
# Linux counterpart to bootstrap.ps1: installs packages and wires up the zsh profile.
set -euo pipefail

FORCE=false
SKIP_PACKAGES=false
SKIP_ZSH=false
RESTORE_AI=true
RESTORE_PROJECTS=true
IGNORE_LID_SWITCH=false

for arg in "$@"; do
    case "$arg" in
        --force) FORCE=true ;;
        --skip-packages) SKIP_PACKAGES=true ;;
        --skip-zsh) SKIP_ZSH=true ;;
        --restore-ai) RESTORE_AI=true ;; # retained for compatibility; now the default
        --skip-ai) RESTORE_AI=false ;;
        --skip-projects) RESTORE_PROJECTS=false ;;
        --ignore-lid-switch) IGNORE_LID_SWITCH=true ;;
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

detect_package_manager
if [ "$PKG_MANAGER" = "unknown" ]; then
    echo "No supported package manager found (need apt, dnf, or pacman)." >&2
    exit 1
fi
write_step "Detected package manager: $PKG_MANAGER"

source "$INSTALLER_ROOT/packages.sh"
source "$INSTALLER_ROOT/zsh.sh"
source "$INSTALLER_ROOT/git.sh"
source "$INSTALLER_ROOT/systemd-logind.sh"

$SKIP_PACKAGES && disable_step "packages"
$SKIP_ZSH && disable_step "zsh"
$IGNORE_LID_SWITCH || disable_step "systemd_logind"

invoke_steps "$FORCE"

if $RESTORE_AI; then
    ai_args=()
    $FORCE && ai_args+=(--force)
    "$REPO_ROOT/scripts/restore-ai.sh" "${ai_args[@]}"
fi

if $RESTORE_PROJECTS; then
    "$REPO_ROOT/scripts/restore-projects.sh"
fi

echo ""
write_success "Bootstrap complete."
write_step "Restart your terminal (or run 'exec zsh') to load the updated profile."
