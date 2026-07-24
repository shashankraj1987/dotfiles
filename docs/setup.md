# Setup Notes

## Fresh Machine

1. Install PowerShell 7 if it is not already available.
2. Clone this repository.
3. Run `pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1`.
4. Restart PowerShell.
5. Run `.\scripts\verify.ps1`.

## How It Works

`bootstrap.ps1` loads installer files from `installers/`. Each installer registers a step with `Register-BootstrapStep`.

The PowerShell installer replaces the user profile with a loader:

```powershell
. "D:\git_apps\Personal_Projects\dotfiles\profile.ps1"
```

That means the live shell configuration stays in this repository, and future changes apply after pulling the repo and restarting PowerShell.

## Linux Config Parity

The PowerShell profile carries over the Windows-friendly parts of `.my_config.zsh`:

- `cp`, `mv`, and `rm` wrappers with verbose output and confirmation where useful.
- `ls`, `ll`, `la`, and `lt` through `eza`.
- `cat` through `bat`, `grep` through `rg`, and `less` through `bat`.
- `top` through `btm` when it is installed, with a `Get-Process` fallback.
- `vi` mapped to `vim` or `nvim` when either editor is installed.
- `xclip` mapped to PowerShell clipboard commands.
- `base_py` mapped to `$HOME\venv\base\Scripts\Activate.ps1`.

zsh-specific history, completion, keybinding, and Linux-only terminal settings stay in the Linux config.
