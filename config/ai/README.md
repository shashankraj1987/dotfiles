# AI tool settings

This directory contains portable, non-secret settings for AI coding tools. It
intentionally excludes login sessions, API keys, chat history, caches, logs,
databases, downloaded plugins, and machine-generated application profiles.

## Included snapshot

- Codex: model, reasoning level, theme, enabled plugins, feature flags, the
  OpenAI documentation MCP endpoint, desktop preferences, and restored Linux
  command rules.
- Claude Code: user settings restored from the previous backup.
- GitHub Copilot CLI: supported by the scripts when `~/.copilot/settings.json`
  exists. The current `config.json` only contains generated first-launch state,
  so it is not committed.
- Gemini CLI: supported by the scripts when `~/.gemini/settings.json` or
  `~/.gemini/GEMINI.md` exists.
- OpenCode: restored `opencode.jsonc`; generated `node_modules` and package
  manager state are excluded.

`@HOME@` in a `*.tmpl` file is replaced with the current user's home directory
during restore. Use forward slashes in templates; TOML and JSON accept them on
Windows too.

## Commands

Linux:

```bash
./scripts/backup-ai.sh
./scripts/restore-ai.sh
./scripts/restore-ai.sh --tools codex,claude --force
```

Windows (PowerShell 7):

```powershell
.\scripts\backup-ai.ps1
.\scripts\restore-ai.ps1
.\scripts\restore-ai.ps1 -Tools codex,claude -Force
```

Without `--force` / `-Force`, restore skips files that already exist. With it,
each replaced file is copied to a timestamped `*.dotfiles-backup-*` file first.

The backup scripts only copy known declarative files and user-created content.
They refuse files that look as though they contain credentials. Review
`git diff -- config/ai` before committing every refresh.

Environment variables and login credentials are not an input to these restore
scripts. On a new computer, obtain secret values from the password manager,
approved secret manager, provider account, or encrypted offline backup. Use a
project's `.env.example` to discover required variable names and keep the real
`.env` untracked. The main [README](../../README.md#where-settings-environment-variables-and-credentials-come-from)
contains the full source and restore checklist.

## Push the backup

After reviewing the changes:

```bash
git add config/ai .gitignore scripts/backup-ai.* scripts/restore-ai.* bootstrap.* README.md
git commit -m "Back up portable AI tool settings"
git push
```

On a new PC, clone this dotfiles repo and run the restore command for that OS.
