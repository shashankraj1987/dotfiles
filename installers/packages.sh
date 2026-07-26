#!/usr/bin/env bash
# Installs the CLI tools the zsh profile expects. Mirrors installers/winget.ps1.

# name:apt-package
APT_PACKAGES=(
    "zoxide:zoxide"
    "fzf:fzf"
    "eza:eza"
    "bat:bat"
    "fd:fd-find"
    "ripgrep:ripgrep"
)

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
}

step_packages() {
    local force="$1"

    if has_command apt-get; then
        write_step "Updating apt package index..."
        sudo apt-get update
    fi

    for entry in "${APT_PACKAGES[@]}"; do
        IFS=':' read -r name pkg <<< "$entry"
        install_apt_package "$pkg" "$name" "$force"
    done

    install_oh_my_posh "$force"
    install_bottom "$force"
}

register_step "packages"
