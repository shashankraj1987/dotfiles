# Dotfiles

Personal dotfiles and bootstrap scripts for Windows (PowerShell) and Linux (zsh).

## Quick Start

### Windows

Run the bootstrap entry point from PowerShell 7:

```powershell
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Portable AI settings and projects from the tracked manifest are restored by
default. Authentication is intentionally excluded. Use `-SkipAISettings` or
`-SkipProjects` to opt out.

After it finishes, restart PowerShell and verify the environment:

```powershell
.\scripts\verify.ps1
```

### Linux

Run the bootstrap entry point from bash:

```bash
./bootstrap.sh
```

Portable AI settings and projects from the tracked manifest are restored by
default. Authentication is intentionally excluded. Use `--skip-ai` or
`--skip-projects` to opt out.

After it finishes, restart your terminal (or run `exec zsh`) and verify the environment:

```bash
./scripts/verify.sh
```

## Fedora-to-Windows migration

This repository recreates the portable developer environment rather than
copying Fedora itself. It can transfer:

- shell, Git, terminal, and supported command-line tool configuration;
- Codex, Claude Code, GitHub Copilot CLI, Gemini CLI, and OpenCode settings;
- Codex global guidance, user-created skills, rules, and optional file-based
  memories;
- the list of Git projects to clone; and
- project-specific AI guidance committed inside each project's repository,
  including `AGENTS.md`, `CLAUDE.md`, `.codex/config.toml`, and
  `.github/copilot-instructions.md`.

### 1. Prepare and push from Fedora

Refresh the portable AI snapshot and project manifest:

```bash
./scripts/backup-ai.sh
./scripts/backup-projects.sh
```

The current Fedora `~/git_apps` directory contains active projects as well as a
recovered `windows_git_apps` tree. Review `config/projects/projects.tsv` and
remove duplicate, archived, or unwanted repositories before committing it.
Also inspect every reported dirty repository: uncommitted and untracked files
cannot be recreated from a Git remote.

Review the complete dotfiles change before pushing:

```bash
git status --short
git diff
git add README.md config/ai config/projects scripts bootstrap.sh bootstrap.ps1 .gitignore
git commit -m "Prepare portable developer environment"
git push
```

Do not commit credentials, private `.env` files, SSH private keys, login state,
or generated chat/session databases. Move those through a password manager,
secret manager, or encrypted backup.

### 2. Restore on Windows

Install Git and PowerShell 7, clone this repository, and optionally choose where
project repositories should be created:

```powershell
$env:DOTFILES_PROJECTS_ROOT = "D:/git_apps"
pwsh -ExecutionPolicy Bypass -File .\bootstrap.ps1
```

Without `DOTFILES_PROJECTS_ROOT`, projects are cloned under `~/git_apps`.
Bootstrap restores portable AI settings and clones missing manifest projects by
default. Existing AI files and project directories are preserved unless
`-Force` is supplied for supported settings.

Restart PowerShell, run the verification script, and sign in to each AI tool:

```powershell
.\scripts\verify.ps1
```

If a project remote uses an SSH alias such as
`git@work-alias:owner/repository.git`, recreate the corresponding
`~/.ssh/config` entry and install its private key securely before bootstrap, or
replace the alias with a canonical hostname in the manifest.

### 3. Transfer non-dotfile data separately

This repository is not a whole-machine backup. Use an encrypted, versioned
backup for documents, media, browser profiles, application data, containers,
VMs, Fedora system state, uncommitted project files, and other personal data.
AI authentication and generated Codex memory/session SQLite databases are also
excluded. Required long-term AI knowledge should live in tracked `AGENTS.md`
files or project documentation.

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
│   ├── ai/
│   ├── projects/
│   ├── powershell/
│   ├── oh-my-posh/
│   ├── windows-terminal/
│   └── git/
├── scripts/
└── docs/
```

`bootstrap.ps1` / `bootstrap.sh` is the only script intended to be run manually on a fresh machine. It loads installer modules, then runs the steps they register.

## Command Reference

Options can be combined. Running a command without options uses the defaults
shown below.

### Windows bootstrap

```powershell
.\bootstrap.ps1 [-Force] [-SkipPackages] [-SkipPowerShell] [-SkipAISettings] [-SkipProjects]
```

| Option | Effect |
| --- | --- |
| none | Install packages/configuration, restore portable AI settings, and clone missing manifest projects. |
| `-Force` | Reinstall/refresh packages and replace generated configuration where supported. Git configuration is only applied in this mode. |
| `-SkipPackages` | Skip the Winget package-installation step. |
| `-SkipPowerShell` | Skip PowerShell profile and module configuration. |
| `-SkipAISettings` | Do not restore tracked AI-tool settings. |
| `-SkipProjects` | Do not clone projects from `config/projects/projects.tsv`. |

Examples:

```powershell
.\bootstrap.ps1
.\bootstrap.ps1 -SkipPackages
.\bootstrap.ps1 -Force
```

`setup-dev-tools.ps1 [-Force]` is retained as a compatibility wrapper around
`bootstrap.ps1`; use `bootstrap.ps1` for new installations.

### Linux bootstrap

```bash
./bootstrap.sh [--force] [--skip-packages] [--skip-zsh] [--skip-ai] [--skip-projects]
```

| Option | Effect |
| --- | --- |
| none | Install packages/configuration, restore portable AI settings, and clone missing manifest projects. |
| `--force` | Reinstall/refresh packages and replace generated configuration where supported. Git configuration is only applied in this mode. |
| `--skip-packages` | Skip the package-installation step. |
| `--skip-zsh` | Skip zsh, Oh My Zsh, and `.zshrc` integration. |
| `--skip-ai` | Do not restore tracked AI-tool settings. |
| `--skip-projects` | Do not clone projects from `config/projects/projects.tsv`. |

Examples:

```bash
./bootstrap.sh
./bootstrap.sh --skip-packages
./bootstrap.sh --force
```

### AI settings backup

Backup refreshes the Git-trackable snapshot under `config/ai/` from the current
computer. The default tool set is `codex,claude,copilot,gemini,opencode`.

```bash
./scripts/backup-ai.sh [--tools TOOL1,TOOL2] [--include-memories]
```

```powershell
.\scripts\backup-ai.ps1 [-Tools TOOL1,TOOL2] [-IncludeMemories]
```

| Option | Effect |
| --- | --- |
| none | Back up portable settings for every supported tool found on the computer. Missing tools are skipped. |
| `--tools LIST` | Linux: back up only the comma-separated tool names in `LIST`. |
| `-Tools LIST` | PowerShell: back up only the supplied tool-name array. |
| `--include-memories` / `-IncludeMemories` | Also copy file-based Codex memories after secret checks; generated SQLite stores remain excluded. |

Examples:

```bash
./scripts/backup-ai.sh --tools codex,claude
```

```powershell
.\scripts\backup-ai.ps1 -Tools codex,claude
```

The backup is allowlisted: it excludes authentication, API keys, histories,
sessions, logs, caches, databases, downloaded system skills, and generated app
profiles. It stops if a selected declarative file looks as though it contains a
credential. Always inspect `git diff -- config/ai` before committing.

### Projects and project memory

Project source code should remain in each project's own Git repository. This
dotfiles repository stores only a clone manifest, so a new Windows or Linux
machine can recreate the same workspace without duplicating source trees here.

Generate or refresh the manifest from the default `~/git_apps` directory:

```bash
./scripts/backup-projects.sh
```

```powershell
.\scripts\backup-projects.ps1
```

Use `--root PATH` or `-Root PATH` for a different source directory. On restore,
set `DOTFILES_PROJECTS_ROOT` when projects should live somewhere other than
`~/git_apps` (for example `D:/git_apps` on Windows). Bootstrap automatically
clones missing entries from `config/projects/projects.tsv`; existing directories
are never overwritten.

The manifest transfers committed Git content only. Before moving machines,
commit and push each project's durable AI context—especially `AGENTS.md`,
`CLAUDE.md`, `.codex/config.toml`, `.github/copilot-instructions.md`, and project
documentation—to that project's repository. The backup command warns about
dirty repositories because uncommitted and untracked files cannot be recreated
from a remote.

Review the manifest before committing it: remote URLs and private repository
names may be sensitive even when they contain no password or token. Remotes
that use SSH host aliases (for example `git@work-alias:owner/repo.git`) also
require a matching `~/.ssh/config` entry and private key on the new machine;
prefer canonical hostnames in the manifest or restore those separately.

### AI settings restore

Restore reads only from the cloned repository. The default tool set is
`codex,claude,copilot,gemini,opencode`.

```bash
./scripts/restore-ai.sh [--tools TOOL1,TOOL2] [--force]
```

```powershell
.\scripts\restore-ai.ps1 [-Tools TOOL1,TOOL2] [-Force]
```

| Option | Effect |
| --- | --- |
| none | Restore every tracked tool, skipping destination files that already exist. |
| `--tools LIST` | Linux: restore only the comma-separated tool names in `LIST`. |
| `-Tools LIST` | PowerShell: restore only the supplied tool-name array. |
| `--force` / `-Force` | Replace existing destination files after creating timestamped `*.dotfiles-backup-*` safety copies. |

Examples:

```bash
./scripts/restore-ai.sh
./scripts/restore-ai.sh --tools codex,opencode
./scripts/restore-ai.sh --tools codex,claude --force
```

```powershell
.\scripts\restore-ai.ps1
.\scripts\restore-ai.ps1 -Tools codex,opencode
.\scripts\restore-ai.ps1 -Tools codex,claude -Force
```

Linux restores Linux-specific Codex rules; Windows restores Windows-specific
rules. Sign in to each tool after restoring because credentials never come from
Git. See [the AI settings guide](config/ai/README.md) for the tracked files and
the commit/push workflow.

### Where settings, environment variables, and credentials come from

Use the following source order on a new computer:

1. Clone this repository for portable shell and AI-tool settings.
2. Run the bootstrap; portable AI settings and manifest projects restore by
   default on both operating systems.
3. Sign in to each AI provider again; do not copy authentication files through
   Git.
4. Retrieve private environment-variable values from your password manager,
   secret manager, or encrypted backup.
5. For a project, use that project's `.env.example`, documentation, or secret
   manager entry to determine which variables are required, then create its
   untracked `.env` file locally.

| Configuration | Source on a new computer | Destination |
| --- | --- | --- |
| Non-secret PowerShell variables | This repo: `config/powershell/env.ps1` | Loaded automatically by `profile.ps1`. |
| Non-secret Linux shell variables | This repo: `profile.zsh` and `.my_config.zsh` | Loaded automatically through the managed `.zshrc` block. |
| Portable AI settings | This repo: `config/ai/` | Installed by `restore-ai.ps1` or `restore-ai.sh`. |
| AI login sessions | The corresponding OpenAI, Anthropic, GitHub, Google, or model-provider account | Created locally when you sign in again. |
| API keys and secret environment variables | Password manager, approved secret manager, or encrypted offline backup | User environment, a private shell file, or a project-local `.env`; never `config/ai/`. |
| Project-specific variables | The project's `.env.example`/README plus its secret-manager entry | The project's untracked `.env` or platform deployment settings. |

### What this does not transfer

A Git dotfiles repository is not a whole-machine backup. It deliberately does
not transfer documents, media, browser profiles, installed application data,
Windows registry state, Fedora system state, containers/VMs, credentials,
uncommitted project files, or AI chat/session databases. Use an encrypted,
versioned backup tool for those files and a password manager for secrets. This
separation keeps a leaked dotfiles repository from becoming a leaked machine.

The initial AI snapshot in this repository was selected from these locations on
the restored Linux machine:

| Tool | Initial source | What was retained |
| --- | --- | --- |
| Codex | `~/.codex/config.toml` and the recovered Codex rules under `~/recovery-hold-20260814/pending-settings/harnesses/.codex/` | Portable preferences, enabled plugins, MCP endpoint, and Linux rules. |
| Claude Code | `~/recovery-hold-20260814/pending-settings/harnesses/.claude/settings.json` | User-facing settings only. |
| GitHub Copilot | `~/.copilot/` | No current user settings file was present; generated first-launch state was excluded. The scripts will pick up `settings.json` when present. |
| Gemini CLI | `~/.gemini/` | No current settings were present; backup and restore support is ready for future settings. |
| OpenCode | `~/recovery-hold-20260814/pending-settings/harnesses/.config/opencode/opencode.jsonc` | Declarative configuration only; `node_modules` and package-manager state were excluded. |

Authentication and runtime files such as `~/.codex/auth.json`, Claude's
`.credentials.json`, browser cookies, OAuth caches, histories, sessions, and
SQLite databases are deliberately excluded. Keep the recovery directory as an
offline source only; do not add it wholesale to Git.

To identify environment-variable names on the old machine without printing
their values:

```bash
printenv | cut -d= -f1 | sort
```

```powershell
Get-ChildItem Env: | Select-Object -ExpandProperty Name | Sort-Object
```

These commands only reveal what was present in that shell. The actual values
must still come from the password manager, provider account, deployment
platform, or encrypted backup that owns the secret.

Typical post-restore authentication is:

| Tool | What to do after restore |
| --- | --- |
| Codex | Start Codex and sign in with the intended ChatGPT account or API-key workflow. Codex stores local login state separately from `config.toml`. |
| Claude Code | Start Claude Code and complete its provider sign-in flow. |
| GitHub Copilot | Authenticate the GitHub CLI/account used by Copilot, then start Copilot. |
| Gemini CLI | Start Gemini and sign in with Google, or provide the approved provider key through your private environment. |
| OpenCode | Authenticate each configured model provider; retrieve provider API keys from the password/secret manager when required. |

### Maintenance scripts

These commands have no options:

| Windows | Linux | Purpose |
| --- | --- | --- |
| `.\scripts\update.ps1` | `./scripts/update.sh` | Upgrade installed packages. Linux also upgrades Oh My Posh and reports an outdated `asusctl` when present. |
| `.\scripts\verify.ps1` | `./scripts/verify.sh` | Report whether expected command-line tools are installed. |
| `.\scripts\cleanup.ps1` | `./scripts/cleanup.sh` | Placeholder; no cleanup tasks are configured yet. |

## PowerShell Profile

The Windows bootstrap replaces the user PowerShell profile with a small loader that points at `profile.ps1` in this repository. This keeps the real configuration version-controlled and avoids duplicate profile blocks.

## zsh Profile

The Linux bootstrap appends a marker-delimited block to `~/.zshrc` (leaving Oh My Zsh and everything else untouched) that sources `profile.zsh`. `profile.zsh` sources `.my_config.zsh` — the base zsh options, aliases, completion, and keybindings — then layers on the same modern-CLI integrations as `profile.ps1` (eza, zoxide, Oh My Posh, fzf) when those tools are installed.
