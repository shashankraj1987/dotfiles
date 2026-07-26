#!/usr/bin/env bash
# Ensures zsh + Oh My Zsh are installed, then wires the repo's config into
# ~/.zshrc. Mirrors installers/powershell.ps1.

OH_MY_ZSH_DIR="${ZSH:-$HOME/.oh-my-zsh}"

install_oh_my_zsh() {
    local force="$1"

    if [ "$force" != "true" ] && [ -d "$OH_MY_ZSH_DIR" ]; then
        write_skip "Oh My Zsh is already installed."
        return
    fi

    write_step "Installing Oh My Zsh..."
    # --unattended skips the shell-change prompt (handled separately below).
    # --keep-zshrc leaves any existing ~/.zshrc alone instead of overwriting it.
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" \
        "" --unattended --keep-zshrc
}

ensure_default_shell_zsh() {
    local zsh_path
    zsh_path="$(command -v zsh)"
    [ -z "$zsh_path" ] && return

    if [ "${SHELL:-}" = "$zsh_path" ]; then
        write_skip "zsh is already the default shell."
        return
    fi

    write_step "Setting zsh as the default shell..."
    chsh -s "$zsh_path" "$USER"
}

step_zsh() {
    local force="$1"

    install_apt_package "zsh" "zsh" "$force"
    install_oh_my_zsh "$force"
    ensure_default_shell_zsh

    set_zsh_loader "$REPO_ROOT" "$force"

    for file in "$REPO_ROOT/.my_config.zsh" "$REPO_ROOT/profile.zsh"; do
        if [ ! -f "$file" ]; then
            write_warn "Missing zsh config file: $file"
        fi
    done

    write_success "zsh configuration is ready."
}

register_step "zsh"
