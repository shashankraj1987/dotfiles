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

# Detects apt (Debian/Ubuntu), dnf (Fedora), or pacman (Arch) and records it in
# PKG_MANAGER. All package steps go through this instead of assuming apt.
PKG_MANAGER=""

detect_package_manager() {
    [ -n "$PKG_MANAGER" ] && return

    if has_command apt-get; then
        PKG_MANAGER="apt"
    elif has_command dnf; then
        PKG_MANAGER="dnf"
    elif has_command pacman; then
        PKG_MANAGER="pacman"
    else
        PKG_MANAGER="unknown"
    fi
}

# On Arch-based systems, yay wraps pacman for both official-repo and AUR
# packages. It isn't preinstalled anywhere, so bootstrap it from the AUR the
# first time a pacman-based install is needed.
ensure_yay() {
    [ "$PKG_MANAGER" = "pacman" ] || return 0
    has_command yay && return 0

    write_step "Installing yay (AUR helper)..."
    sudo pacman -S --needed --noconfirm base-devel git

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    git clone --quiet https://aur.archlinux.org/yay-bin.git "$tmp_dir/yay-bin"
    (cd "$tmp_dir/yay-bin" && makepkg -si --noconfirm)
    rm -rf "$tmp_dir"
}

update_package_index() {
    case "$PKG_MANAGER" in
        apt)
            write_step "Updating apt package index..."
            sudo apt-get update
            ;;
        dnf)
            write_step "Updating dnf package index..."
            sudo dnf makecache
            ;;
        pacman)
            ensure_yay
            write_step "Syncing pacman package databases..."
            yay -Sy --noconfirm
            ;;
        *)
            write_warn "No supported package manager found (need apt, dnf, or pacman)."
            ;;
    esac
}

package_installed() {
    local pkg="$1"

    case "$PKG_MANAGER" in
        apt) dpkg -s "$pkg" >/dev/null 2>&1 ;;
        dnf) rpm -q "$pkg" >/dev/null 2>&1 ;;
        pacman) pacman -Qi "$pkg" >/dev/null 2>&1 ;;
        *) return 1 ;;
    esac
}

install_package() {
    local pkg="$1" name="$2" force="${3:-false}"

    if [ "$PKG_MANAGER" = "unknown" ] || [ -z "$PKG_MANAGER" ]; then
        write_warn "No supported package manager found; skipping $name."
        return
    fi

    if [ -z "$pkg" ]; then
        write_warn "No package mapping for $name on this distro; skipping."
        return
    fi

    if [ "$force" != "true" ] && package_installed "$pkg"; then
        write_skip "$name is already installed."
        return
    fi

    case "$PKG_MANAGER" in
        apt)
            if [ "$force" = "true" ] && package_installed "$pkg"; then
                write_step "Reinstalling $name..."
                sudo apt-get install --reinstall -y "$pkg"
            else
                write_step "Installing $name..."
                sudo apt-get install -y "$pkg"
            fi
            ;;
        dnf)
            if [ "$force" = "true" ] && package_installed "$pkg"; then
                write_step "Reinstalling $name..."
                sudo dnf reinstall -y "$pkg"
            else
                write_step "Installing $name..."
                sudo dnf install -y "$pkg"
            fi
            ;;
        pacman)
            ensure_yay
            write_step "Installing $name..."
            yay -S --needed --noconfirm "$pkg"
            ;;
    esac
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
