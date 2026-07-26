# Setup Notes

## Fresh Machine (Windows)

1. Install PowerShell 7 if it is not already available.
2. Clone this repository.
3. Run `pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1`.
4. Restart PowerShell.
5. Run `.\scripts\verify.ps1`.

### How It Works

`bootstrap.ps1` loads installer files from `installers/`. Each installer registers a step with `Register-BootstrapStep`.

The PowerShell installer replaces the user profile with a loader:

```powershell
. "D:\git_apps\Personal_Projects\dotfiles\profile.ps1"
```

That means the live shell configuration stays in this repository, and future changes apply after pulling the repo and restarting PowerShell.

## Fresh Machine (Linux)

1. Clone this repository.
2. Run `./bootstrap.sh` (installs apt packages with `sudo`, so it will prompt for a password).
3. Restart your terminal, or run `exec zsh`.
4. Run `./scripts/verify.sh`.

### How It Works

`bootstrap.sh` loads installer files from `installers/` (`common.sh`, `packages.sh`, `zsh.sh`, `git.sh`). Each installer registers a step with `register_step`, and `invoke_steps` runs them in order.

The `zsh` step installs `zsh` and [Oh My Zsh](https://ohmyz.sh) first if either is missing (using Oh My Zsh's official unattended installer with `--keep-zshrc`, so it never overwrites an existing `~/.zshrc`), sets `zsh` as your default shell if it isn't already, and then appends a marker-delimited block to `~/.zshrc`:

```bash
# >>> dotfiles bootstrap >>>
[ -f "/path/to/dotfiles/profile.zsh" ] && source "/path/to/dotfiles/profile.zsh"
# <<< dotfiles bootstrap <<<
```

Re-running the bootstrap replaces only the content between those markers, so Oh My Zsh and any other existing `~/.zshrc` content is left alone (a timestamped backup is taken before the first edit and before any content change).

`profile.zsh` sources `.my_config.zsh` (the base zsh options, aliases, completion, and keybindings) and then adds the same modern-CLI integrations as `profile.ps1`: eza-based `ls`/`ll`/`la`/`lt`, zoxide, Oh My Posh (using the same `config/oh-my-posh/theme.json`), and fzf's default-command env vars — each gated on the tool actually being installed.

### Linux Config Parity

`.my_config.zsh` is the single source of truth for base zsh behavior on Linux (history, completion, keybindings, core aliases), and Oh My Zsh remains the shell framework — the bootstrap never replaces its `~/.zshrc`, only appends to it. `installers/packages.sh` installs the CLI tools `.my_config.zsh` and `profile.zsh` expect via `apt`:

- `eza`, `bat`, `fd-find` (binary `fdfind` on Debian/Ubuntu), `ripgrep`, `zoxide`, `fzf` via `apt`.
- `oh-my-posh` via its official install script (not packaged for apt).
- `bottom` (`btm`) via the latest GitHub release `.deb` (not packaged for apt).

Git config (`config/git/gitconfig.linux`) is available but, like the Windows side, only applied with `--force` since it overwrites `~/.gitconfig`.
