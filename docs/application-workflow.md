# Application Workflow and Feature Inventory

This document describes what the current dotfiles application does, in the
order it does it. It is intended as a behavior reference for a future rewrite
in Python, Go, or another language.

## What this application is

This is a personal developer-environment bootstrap and configuration
repository. It installs selected command-line tools, connects the current
repository to the user's shell profile, restores portable AI-tool settings,
and clones Git repositories listed in a manifest. It also provides separate
backup, update, and verification commands.

It is not a general machine backup, package manager, GitHub repository
discovery service, or background application. It currently has separate
Windows PowerShell and Linux Bash implementations; macOS is not a supported
bootstrap target.

## Fresh-machine bootstrap sequence

### Windows

Entry point: `bootstrap.ps1` (PowerShell 7).

1. Parse options: `-Force`, `-SkipPackages`, `-SkipPowerShell`,
   `-SkipAISettings`, and `-SkipProjects`.
2. Load shared PowerShell helpers and display the setup banner.
3. Load installer modules. Each module registers a named bootstrap step:
   Winget packages, PowerShell configuration, Git configuration, Windows
   Terminal settings, and fonts.
4. Disable the package or PowerShell step if its corresponding skip option was
   provided.
5. Run the remaining steps in registration order.
6. Unless `-SkipAISettings` was supplied, restore tracked AI settings. `-Force`
   is passed through so existing destinations can be backed up and replaced.
7. Unless `-SkipProjects` was supplied, clone missing projects from
   `config/projects/projects.tsv`.
8. Report completion and recommend restarting PowerShell.

`-RestoreAISettings` is also declared as a parameter but currently has no
effect; AI settings are restored by default unless `-SkipAISettings` is used.

`setup-dev-tools.ps1` is a compatibility wrapper that forwards `-Force` to
`bootstrap.ps1`.

### Linux

Entry point: `bootstrap.sh` (Bash).

1. Parse options: `--force`, `--skip-packages`, `--skip-zsh`, `--skip-ai`,
   `--skip-projects`, and `--ignore-lid-switch`. `--restore-ai` is accepted for
   compatibility; AI restore is already enabled by default.
2. Load shared Bash helpers, display the setup banner, and detect `apt`, `dnf`,
   or `pacman`. Stop if none is available.
3. Load installer modules. They register package, zsh, Git, and systemd-logind
   steps.
4. Disable package/zsh steps when requested. The systemd-logind step is
   disabled unless `--ignore-lid-switch` was requested.
5. Run enabled steps in registration order.
6. Unless `--skip-ai` was supplied, restore tracked AI settings. `--force` is
   passed through to the restore script.
7. Unless `--skip-projects` was supplied, clone missing projects from the
   manifest.
8. Report completion and recommend restarting the terminal or running
   `exec zsh`.

The bootstrap is mostly idempotent: installed packages, current profile
loaders, existing project directories, and existing AI settings are generally
skipped unless force behavior is supported and requested. Some operations
(such as Linux package-index refresh) still run when the package step runs.

## Feature inventory

### 1. Package installation

**Windows:** Winget installs `zoxide`, `fzf`, `eza`, `bat`, `fd`, `ripgrep`,
`bottom` (`btm`), and Oh My Posh. Existing packages are skipped normally;
`-Force` requests reinstall where supported. Winget agreements are accepted
non-interactively. The current process PATH is refreshed after installation.

**Linux:** the package installer selects distro package names for `apt`, `dnf`,
or `pacman`/`yay` and installs `zoxide`, `fzf`, `eza`, `bat`, `fd`, and
`ripgrep`. It also installs Oh My Posh using its upstream install script and
`bottom` using the distro package or the latest upstream release, depending on
the package manager and architecture. On Arch, `yay` is bootstrapped from the
AUR if needed. System package operations use `sudo`.

Package-manager indexes are refreshed before Linux package installation. With
`--force`/`-Force`, applicable installed packages are reinstalled.

### 2. Shell configuration

**Windows PowerShell:**

- Creates the PowerShell profile if needed and configures it to dot-source
  this repository's `profile.ps1`.
- Backs up a non-empty existing profile before replacing its contents with the
  loader when not forced.
- Installs the `Terminal-Icons` PowerShell module for the current user.
- Verifies that the repository's aliases, functions, environment, and
  completion configuration files exist.
- The loaded profile imports those config files, initializes zoxide and Oh My
  Posh when installed, and uses the tracked Oh My Posh theme.

**Linux:**

- Installs zsh and Oh My Zsh if needed. The upstream installer is run
  unattended with `--keep-zshrc`, so it does not replace the user's existing
  `.zshrc`.
- Sets zsh as the default shell if it is not already the default.
- Adds a marker-delimited loader block to `~/.zshrc` to source this repository's
  `profile.zsh`. On reruns, only the managed block is replaced; other content
  is preserved. When replacing an existing managed block, the file is backed
  up first; an initial append to an unmarked `.zshrc` does not create a backup.
- The profile loads `.my_config.zsh`, sets up FZF defaults, configures eza
  aliases, and initializes zoxide and Oh My Posh when those commands exist.

The tracked shell configuration also supplies command aliases/functions,
history and completion behavior, key bindings, and a shared prompt theme.

### 3. Git and Windows Terminal configuration

- A Windows Git config template and a Linux Git config template are present.
- Git configuration is deliberately not applied by default because it writes
  `~/.gitconfig`; bootstrap only applies it with `-Force`/`--force`.
- Windows Terminal settings are tracked and the Windows installer reports
  their location; it does not currently install or copy them into Terminal's
  active settings path.

### 4. Optional Linux keep-awake behavior

`--ignore-lid-switch` enables a Linux-only systemd-logind step:

- Installs the tracked logind drop-in under
  `/etc/systemd/logind.conf.d/lid.conf`, backing up a differing existing file.
- Restarts `systemd-logind` only when the installed file changes. This can
  interrupt the current graphical session and requires administrative access.
- When GNOME power settings are available and writable, disables automatic
  idle suspend on AC and battery. Locked settings are left unchanged; absent
  GNOME settings are skipped.
- Manual suspend remains available.

The feature is opt-in and is not enabled by `--force` alone.

### 5. AI-tool settings backup and restore

Supported tools: Codex, Claude Code, GitHub Copilot CLI, Gemini CLI, and
OpenCode. Backup and restore operate on known declarative files under each
tool's user configuration directory.

**Backup** (`scripts/backup-ai.ps1` / `scripts/backup-ai.sh`):

- Copies known settings, guidance, user-created rules/skills/commands/hooks,
  as applicable, into `config/ai/`.
- Uses templates for settings that need a home-directory placeholder; restore
  substitutes the current home path for `@HOME@`.
- Removes machine-generated Codex configuration sections.
- Excludes login/authentication data, tokens, histories, sessions, logs,
  caches, SQLite databases, downloaded runtime/plugin state, and generated
  profiles.
- Refuses selected files that match credential-like patterns.
- Codex file-based memories can be included explicitly with
  `-IncludeMemories` / `--include-memories`; SQLite stores remain excluded.
- Accepts a selected tool list. Missing settings files are simply not copied.
- Tells the user to inspect `git diff -- config/ai` before committing.

**Restore** (`scripts/restore-ai.ps1` / `scripts/restore-ai.sh`):

- Restores the tracked settings for all supported tools by default; a tool
  selection can limit the operation.
- Skips destination files that already exist by default.
- With `-Force` / `--force`, saves a timestamped
  `*.dotfiles-backup-*` copy before replacing an existing destination.
- Restores OS-specific Codex rules for Windows or Linux.
- Does not restore credentials; users sign in to providers separately.

### 6. Project manifest backup and restore

The tracked file `config/projects/projects.tsv` stores tab-separated relative
path, remote URL, and branch values.

**Manifest generation** (`scripts/backup-projects.ps1` /
`scripts/backup-projects.sh`):

1. Scans the project root recursively for directories named `.git`.
2. Uses each repository's `origin` remote and current branch.
3. Skips repositories without an origin, rejects credential-bearing HTTP(S)
   remotes, and skips values that cannot be represented safely in the TSV.
4. Warns if a repository has uncommitted changes; it only records clone
   metadata and cannot transfer local changes.
5. Rewrites the manifest and asks the user to review it before committing.

The default source root is `~/git_apps`; it can be changed using
`DOTFILES_PROJECTS_ROOT` or the backup command's `--root` / `-Root` argument.

**Restore** (`scripts/restore-projects.ps1` /
`scripts/restore-projects.sh`):

1. Reads the manifest, skipping blank lines and comments.
2. Uses the configured project root (`DOTFILES_PROJECTS_ROOT`) or defaults to
   `~/git_apps`.
3. Rejects unsafe relative paths that could escape that root.
4. Skips any target path that already exists; it does not overwrite a project.
5. Clones the remote into the target path and checks out the recorded branch
   when that branch exists on the remote.

The restore command does not discover GitHub repositories. Repository
discovery, edits to the manifest, and committing/pushing the manifest remain a
manual workflow.

### 7. Update utilities

- `scripts/update.ps1` runs `winget upgrade --all` and updates PowerShell help.
- `scripts/update.sh` upgrades packages using the detected Linux package
  manager. It also attempts to upgrade Oh My Posh and reports when a newer
  `asusctl` release is available.
- These are separate commands and are not run as part of bootstrap.

### 8. Verification utilities

- `scripts/verify.ps1` reports installed/missing expected Windows CLI tools
  and displays a version when available.
- `scripts/verify.sh` checks Linux CLI commands (including package-name
  variants such as `batcat` and `fdfind`) and Oh My Zsh.
- Verification is informational; it does not install or repair missing tools.

### 9. Cleanup utility

`scripts/cleanup.ps1` and `scripts/cleanup.sh` currently only report that no
cleanup tasks are configured.

## Requested features for the rewrite

These are desired additions; they are not implemented in the current scripts.

### 10. Repository overview

Provide a single command or dashboard that makes it easy to see:

- The most recently updated repository, with its latest update time.
- Repository name and remote, default/current branch, and branch count.
- The most recently updated branch and its latest commit time.
- For a local checkout: current branch, clean/dirty state, changed and
  untracked file counts, and commits ahead of/behind its upstream.

Use `gh` when available and authenticated to enumerate GitHub repositories,
read branch metadata, and determine the newest branch tip. Allow the user to
select the account/organization scope. Repositories represented only by the
local project manifest (including non-GitHub remotes) should still be
reportable from local Git data. Clearly distinguish remote metadata from the
state of a local checkout; do not imply that a local checkout is current with
the remote unless it has been fetched. If GitHub access is unavailable, show
the local information that can be determined and explicitly report which
remote fields could not be fetched.

### 11. Two-way folder sync

Allow the user to select folders to synchronize between computers using an
external drive or NAS as the shared sync location. The selection and shared
location should be configurable, not hard-coded. The sync should:

- Transfer changes in either direction, so updates made on either computer
  propagate on the next sync.
- Track enough per-file state to distinguish a deliberate deletion from a file
  that is merely absent because a drive was disconnected or a sync was
  interrupted. Propagate deletions only when the recorded sync state confirms
  them.
- When both computers changed the same file since the last successful sync,
  use the newest modification timestamp as the winner, and report that a
  conflict occurred. Preserve a backup of the losing version before replacing
  it.
- Provide a preview/dry-run and a clear summary of files to copy, replace,
  delete, or skip before making changes.
- Detect an unavailable destination and fail without treating the shared
  contents as deleted or overwriting local files.
- Offer explicit exclusions for secrets, caches, generated state, and other
  folders that should not be synchronized.

Timestamp-based conflict resolution is the selected policy, but depends on
reliable clocks and preserved modification times. The implementation should
surface timestamp ties or unreadable metadata rather than silently choosing a
version. The sync destination is a transport/storage location, not the only
backup: retain versioned backups of overwritten files and document that
disconnected/offline computers see changes only after they sync.

## Configuration, inputs, and sensitive data

- `config/` contains tracked shell, prompt, terminal, Git, Linux system, AI,
  and projects configuration.
- There is no automatic `.env` loader. Per-project environment values must be
  supplied separately, and private `.env` files are not part of this
  application's restore workflow.
- Authentication, API keys, SSH private keys, application databases, and
  uncommitted project contents are not transferred.
- Remote URLs and private repository names can still be sensitive. Review
  manifests and diffs before committing them.
- Project clone access depends on the configured Git transport and credentials
  already available on the new machine (for example, SSH keys or Git credential
  manager).

## Current platform boundaries and incomplete areas

- Windows bootstrap is PowerShell 7 and Windows-specific; Linux bootstrap is
  Bash and supports Debian/Ubuntu, Fedora, and Arch package-manager families.
- macOS is not currently handled by the bootstrap.
- Some behavior is intentionally opt-in: AI restore and project cloning can be
  skipped; Git config requires force; lid-switch behavior requires an explicit
  flag.
- The repository overview and two-way folder sync described above are requested
  additions and remain future implementation work.
- Windows Terminal settings are currently detected/referenced, not deployed.
- Font installation is a placeholder.
- Cleanup scripts are placeholders.
- The scripts do not automatically enumerate GitHub repositories or synchronize
  manifest changes with GitHub.

## Suggested rewrite boundary

For a language rewrite, keep the externally observable behavior separate from
the implementation:

1. Model the manifest, AI restore mapping, package catalog, and platform
   differences as data rather than duplicated command logic.
2. Preserve the two user-facing bootstrap flows and their option meanings.
3. Keep subprocess execution explicit (package managers, `git`, `gh` if
   discovery is later added) and surface non-zero exit codes.
4. Preserve safety rules: no credential transfer, backup before replacement,
   safe relative paths, skip existing projects, and review-before-commit.
5. Make platform-only operations explicit capabilities, so unsupported
   operations can be skipped or reported instead of silently approximated.
6. Implement the repository overview with clear local-vs-remote freshness
   semantics and graceful `gh`-unavailable behavior.
7. Implement sync state and deletion tracking before enabling bidirectional
   propagation; test interrupted runs, missing destinations, timestamp ties,
   and simultaneous edits on both computers.
8. Treat other unimplemented behavior (font installation, Windows Terminal
   deployment, cleanup) as future scope rather than assuming it already works.
