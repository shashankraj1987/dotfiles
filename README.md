# Dotfiles

Personal dotfiles and bootstrap scripts for Windows (PowerShell) and Linux (zsh).

## Quick Start

### Windows

Run the bootstrap entry point from PowerShell 7:

```powershell
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

After it finishes, restart PowerShell and verify the environment:

```powershell
.\scripts\verify.ps1
```

### Linux

Run the bootstrap entry point from bash:

```bash
./bootstrap.sh
```

After it finishes, restart your terminal (or run `exec zsh`) and verify the environment:

```bash
./scripts/verify.sh
```

## Layout

```text
dotfiles/
├── bootstrap.ps1
├── bootstrap.sh
├── profile.ps1
├── profile.zsh
├── .my_config.zsh
├── installers/
│   ├── common.ps1 / common.sh
│   ├── winget.ps1 / packages.sh
│   ├── powershell.ps1 / zsh.sh
│   ├── git.ps1 / git.sh
│   ├── terminal.ps1
│   └── fonts.ps1
├── config/
│   ├── powershell/
│   ├── oh-my-posh/
│   ├── windows-terminal/
│   └── git/
├── scripts/
└── docs/
```

`bootstrap.ps1` / `bootstrap.sh` is the only script intended to be run manually on a fresh machine. It loads installer modules, then runs the steps they register.

## Common Commands

```powershell
.\bootstrap.ps1        # Install packages and configure PowerShell
.\bootstrap.ps1 -Force # Reinstall packages and refresh generated files
.\scripts\update.ps1  # Upgrade installed Winget packages
.\scripts\verify.ps1  # Check expected tools are available
```

```bash
./bootstrap.sh          # Install packages and configure zsh (apt, dnf, or pacman/yay, auto-detected)
./bootstrap.sh --force  # Reinstall packages and refresh generated files
./scripts/update.sh     # Upgrade system packages and Oh My Posh, flag outdated asusctl if installed
./scripts/verify.sh     # Check expected tools are available
```

## PowerShell Profile

The Windows bootstrap replaces the user PowerShell profile with a small loader that points at `profile.ps1` in this repository. This keeps the real configuration version-controlled and avoids duplicate profile blocks.

## zsh Profile

The Linux bootstrap appends a marker-delimited block to `~/.zshrc` (leaving Oh My Zsh and everything else untouched) that sources `profile.zsh`. `profile.zsh` sources `.my_config.zsh` — the base zsh options, aliases, completion, and keybindings — then layers on the same modern-CLI integrations as `profile.ps1` (eza, zoxide, Oh My Posh, fzf) when those tools are installed.
