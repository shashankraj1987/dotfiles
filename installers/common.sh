#!/usr/bin/env bash
# Shared helpers for the Linux bootstrap installers.

BOOTSTRAP_STEP_NAMES=()
declare -A BOOTSTRAP_STEP_ENABLED

write_banner() {
    printf '\n=======================================\n %s\n=======================================\n\n' "$1"
}

write_step() {
    printf '\033[36m[..] %s\033[0m\n' "$1"
}

write_success() {
    printf '\033[32m[OK] %s\033[0m\n' "$1"
}

write_skip() {
    printf '\033[90m[SKIP] %s\033[0m\n' "$1"
}

write_warn() {
    printf '\033[33m[WARN] %s\033[0m\n' "$1"
}

has_command() {
    command -v "$1" >/dev/null 2>&1
}

apt_package_installed() {
    dpkg -s "$1" >/dev/null 2>&1
}

install_apt_package() {
    local pkg="$1" name="$2" force="${3:-false}"

    if ! has_command apt-get; then
        write_warn "apt-get not found; skipping $name."
        return
    fi

    if [ "$force" != "true" ] && apt_package_installed "$pkg"; then
        write_skip "$name is already installed."
        return
    fi

    if [ "$force" = "true" ] && apt_package_installed "$pkg"; then
        write_step "Reinstalling $name..."
        sudo apt-get install --reinstall -y "$pkg"
        return
    fi

    write_step "Installing $name..."
    sudo apt-get install -y "$pkg"
}

backup_file() {
    local path="$1"
    [ -e "$path" ] || return 0

    local backup="${path}.$(date +%Y%m%d-%H%M%S).bak"
    cp -p "$path" "$backup"
    echo "$backup"
}

copy_if_changed() {
    local source="$1" destination="$2"
    mkdir -p "$(dirname "$destination")"

    if [ -f "$destination" ] && cmp -s "$source" "$destination"; then
        write_skip "$destination is already current."
        return
    fi

    cp "$source" "$destination"
    write_success "Updated $destination."
}

# Injects a marker-delimited block into ~/.zshrc that sources profile.zsh
# from the repo, without disturbing Oh My Zsh or other existing config.
set_zsh_loader() {
    local repo_root="$1" force="${2:-false}"
    local zshrc="$HOME/.zshrc"
    local repo_profile="$repo_root/profile.zsh"
    local begin_marker="# >>> dotfiles bootstrap >>>"
    local end_marker="# <<< dotfiles bootstrap <<<"

    touch "$zshrc"

    local block
    block="$(printf '%s\n[ -f "%s" ] && source "%s"\n%s' \
        "$begin_marker" "$repo_profile" "$repo_profile" "$end_marker")"

    if grep -qF "$begin_marker" "$zshrc"; then
        local current
        current="$(awk -v b="$begin_marker" -v e="$end_marker" '
            $0==b {flag=1}
            flag {print}
            $0==e {flag=0}
        ' "$zshrc")"

        if [ "$current" = "$block" ] && [ "$force" != "true" ]; then
            write_skip "zsh profile loader is already configured."
            return
        fi

        backup_file "$zshrc" >/dev/null
        awk -v b="$begin_marker" -v e="$end_marker" '
            $0==b {flag=1; next}
            $0==e {flag=0; next}
            !flag {print}
        ' "$zshrc" > "$zshrc.tmp"
        mv "$zshrc.tmp" "$zshrc"
    fi

    {
        echo ""
        echo "$block"
    } >> "$zshrc"

    write_success "~/.zshrc now loads $repo_profile."
}

register_step() {
    BOOTSTRAP_STEP_NAMES+=("$1")
    BOOTSTRAP_STEP_ENABLED["$1"]="true"
}

disable_step() {
    BOOTSTRAP_STEP_ENABLED["$1"]="false"
}

invoke_steps() {
    local force="$1"

    for name in "${BOOTSTRAP_STEP_NAMES[@]}"; do
        if [ "${BOOTSTRAP_STEP_ENABLED[$name]}" != "true" ]; then
            write_skip "Step '$name' disabled."
            continue
        fi

        write_step "Running step '$name'."
        "step_${name}" "$force"
    done
}
