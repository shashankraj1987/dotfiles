#!/usr/bin/env bash
# Mirrors installers/git.ps1: available, but only applied with --force.

step_git() {
    local force="$1"
    local source="$REPO_ROOT/config/git/gitconfig.linux"
    local destination="$HOME/.gitconfig"

    if [ ! -f "$source" ]; then
        write_skip "No Linux gitconfig template found."
        return
    fi

    if [ "$force" = "true" ]; then
        copy_if_changed "$source" "$destination"
    else
        write_skip "Git configuration is available but not applied by default."
    fi
}

register_step "git"
