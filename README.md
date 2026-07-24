# Dotfiles

Personal Windows-focused dotfiles and bootstrap scripts.

## Quick Start

Run the bootstrap entry point from PowerShell 7:

```powershell
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

After it finishes, restart PowerShell and verify the environment:

```powershell
.\scripts\verify.ps1
```

## Layout

```text
dotfiles/
├── bootstrap.ps1
├── profile.ps1
├── installers/
│   ├── common.ps1
│   ├── winget.ps1
│   ├── powershell.ps1
│   ├── git.ps1
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

`bootstrap.ps1` is the only script intended to be run manually on a fresh machine. It loads installer modules, then runs the steps they register.

## Common Commands

```powershell
.\bootstrap.ps1        # Install packages and configure PowerShell
.\bootstrap.ps1 -Force # Reinstall packages and refresh generated files
.\scripts\update.ps1  # Upgrade installed Winget packages
.\scripts\verify.ps1  # Check expected tools are available
```

## PowerShell Profile

The bootstrap replaces the user PowerShell profile with a small loader that points at `profile.ps1` in this repository. This keeps the real configuration version-controlled and avoids duplicate profile blocks.
