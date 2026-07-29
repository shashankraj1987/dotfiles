#!/usr/bin/env bash
# Installs the CLI tools the zsh profile expects, across apt, dnf, and
# pacman/yay based distros. Mirrors installers/winget.ps1.

# name:apt-package:dnf-package:pacman-package
PACKAGES=(
    "zoxide:zoxide:zoxide:zoxide"
    "fzf:fzf:fzf:fzf"
    "eza:eza:eza:eza"
    "bat:bat:bat:bat"
    "fd:fd-find:fd-find:fd"
    "ripgrep:ripgrep:ripgrep:ripgrep"
)

package_name_for_manager() {
    local name="$1" apt_pkg="$2" dnf_pkg="$3" pacman_pkg="$4"

    case "$PKG_MANAGER" in
        apt) echo "$apt_pkg" ;;
        dnf) echo "$dnf_pkg" ;;
        pacman) echo "$pacman_pkg" ;;
    esac
}

install_oh_my_posh() {
    local force="$1"

    if [ "$force" != "true" ] && has_command oh-my-posh; then
        write_skip "Oh My Posh is already installed."
        return
    fi

    write_step "Installing Oh My Posh..."
    curl -s https://ohmyposh.dev/install.sh | bash -s
}

install_bottom() {
    local force="$1"

    if [ "$force" != "true" ] && has_command btm; then
        write_skip "bottom (btm) is already installed."
        return
    fi

    # Arch's official repos package it; everywhere else it's pulled from the
    # latest GitHub release since neither Debian/Ubuntu nor Fedora carry it.
    if [ "$PKG_MANAGER" = "pacman" ]; then
        install_package "bottom" "bottom (btm)" "$force"
        return
    fi

    if [ "$PKG_MANAGER" = "apt" ]; then
        local arch
        case "$(uname -m)" in
            x86_64) arch="amd64" ;;
            aarch64) arch="arm64" ;;
            *)
                write_warn "Unsupported architecture for bottom: $(uname -m)"
                return
                ;;
        esac

        write_step "Installing bottom (btm)..."
        local deb_url
        deb_url="$(curl -sL https://api.github.com/repos/ClementTsang/bottom/releases/latest \
            | grep -o "\"browser_download_url\": *\"[^\"]*_${arch}\.deb\"" \
            | head -n1 | cut -d'"' -f4)"

        if [ -z "$deb_url" ]; then
            write_warn "Could not resolve a bottom release asset; skipping."
            return
        fi

        local tmp_deb
        tmp_deb="$(mktemp --suffix=.deb)"
        curl -sL "$deb_url" -o "$tmp_deb"
        sudo dpkg -i "$tmp_deb"
        rm -f "$tmp_deb"
        return
    fi

    # dnf (and anything else without a native package): drop the static
    # binary from the release tarball into ~/.local/bin.
    local target_arch
    case "$(uname -m)" in
        x86_64) target_arch="x86_64" ;;
        aarch64) target_arch="aarch64" ;;
        *)
            write_warn "Unsupported architecture for bottom: $(uname -m)"
            return
            ;;
    esac

    write_step "Installing bottom (btm)..."
    local tar_url
    tar_url="$(curl -sL https://api.github.com/repos/ClementTsang/bottom/releases/latest \
        | grep -o "\"browser_download_url\": *\"[^\"]*${target_arch}-unknown-linux-gnu\.tar\.gz\"" \
        | head -n1 | cut -d'"' -f4)"

    if [ -z "$tar_url" ]; then
        write_warn "Could not resolve a bottom release asset; skipping."
        return
    fi

    local tmp_dir
    tmp_dir="$(mktemp -d)"
    curl -sL "$tar_url" -o "$tmp_dir/bottom.tar.gz"
    tar -xzf "$tmp_dir/bottom.tar.gz" -C "$tmp_dir"
    mkdir -p "$HOME/.local/bin"
    install -m 755 "$tmp_dir/btm" "$HOME/.local/bin/btm"
    rm -rf "$tmp_dir"
    write_success "Installed btm to $HOME/.local/bin/btm (ensure it's on PATH)."
}

step_packages() {
    local force="$1"

    detect_package_manager
    update_package_index

    for entry in "${PACKAGES[@]}"; do
        IFS=':' read -r name apt_pkg dnf_pkg pacman_pkg <<< "$entry"
        local pkg
        pkg="$(package_name_for_manager "$name" "$apt_pkg" "$dnf_pkg" "$pacman_pkg")"
        install_package "$pkg" "$name" "$force"
    done

    install_oh_my_posh "$force"
    install_bottom "$force"
}

register_step "packages"
