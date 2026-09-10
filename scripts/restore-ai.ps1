#Requires -Version 7.0

[CmdletBinding()]
param(
    [string[]]$Tools = @("codex", "claude", "copilot", "gemini", "opencode"),
    [switch]$Force
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AiRoot = Join-Path $RepoRoot "config/ai"
$Stamp = Get-Date -Format "yyyyMMdd-HHmmss"
$HomePortable = $HOME.Replace("\", "/")

function Test-Selected {
    param([string]$Name)
    return $Tools -contains $Name
}

function Install-SettingsFile {
    param(
        [string]$Source,
        [string]$Target,
        [switch]$Template
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { return }
    $parent = Split-Path -Parent $Target
    New-Item -ItemType Directory -Path $parent -Force | Out-Null

    if (Test-Path -LiteralPath $Target) {
        if (-not $Force) {
            Write-Host "SKIP  $Target (exists; use -Force to replace)"
            return
        }
        $backup = "$Target.dotfiles-backup-$Stamp"
        Copy-Item -LiteralPath $Target -Destination $backup
        Write-Host "SAVE  $backup"
    }

    if ($Template) {
        (Get-Content -LiteralPath $Source -Raw).Replace("@HOME@", $HomePortable) |
            Set-Content -LiteralPath $Target -NoNewline
    }
    else {
        Copy-Item -LiteralPath $Source -Destination $Target
    }
    Write-Host "WRITE $Target"
}

function Install-SettingsTree {
    param([string]$Source, [string]$Target)
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { return }
    Get-ChildItem -LiteralPath $Source -File -Recurse | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($Source, $_.FullName)
        Install-SettingsFile -Source $_.FullName -Target (Join-Path $Target $relative)
    }
}

if (Test-Selected "codex") {
    Install-SettingsFile -Source (Join-Path $AiRoot "codex/config.toml.tmpl") `
        -Target (Join-Path $HOME ".codex/config.toml") -Template
    Install-SettingsFile -Source (Join-Path $AiRoot "codex/common/AGENTS.md") `
        -Target (Join-Path $HOME ".codex/AGENTS.md")
    Install-SettingsTree -Source (Join-Path $AiRoot "codex/common/rules") `
        -Target (Join-Path $HOME ".codex/rules")
    Install-SettingsTree -Source (Join-Path $AiRoot "codex/common/skills") `
        -Target (Join-Path $HOME ".codex/skills")
    Install-SettingsTree -Source (Join-Path $AiRoot "codex/common/memories") `
        -Target (Join-Path $HOME ".codex/memories")
    Install-SettingsTree -Source (Join-Path $AiRoot "codex/windows/rules") `
        -Target (Join-Path $HOME ".codex/rules")
}

if (Test-Selected "claude") {
    Install-SettingsFile -Source (Join-Path $AiRoot "claude/settings.json.tmpl") `
        -Target (Join-Path $HOME ".claude/settings.json") -Template
    Install-SettingsFile -Source (Join-Path $AiRoot "claude/CLAUDE.md") `
        -Target (Join-Path $HOME ".claude/CLAUDE.md")
    foreach ($part in @("agents", "commands", "hooks", "skills")) {
        Install-SettingsTree -Source (Join-Path $AiRoot "claude/$part") `
            -Target (Join-Path $HOME ".claude/$part")
    }
}

if (Test-Selected "copilot") {
    Install-SettingsFile -Source (Join-Path $AiRoot "copilot/settings.json.tmpl") `
        -Target (Join-Path $HOME ".copilot/settings.json") -Template
}

if (Test-Selected "gemini") {
    Install-SettingsFile -Source (Join-Path $AiRoot "gemini/settings.json.tmpl") `
        -Target (Join-Path $HOME ".gemini/settings.json") -Template
    Install-SettingsFile -Source (Join-Path $AiRoot "gemini/GEMINI.md") `
        -Target (Join-Path $HOME ".gemini/GEMINI.md")
    Install-SettingsTree -Source (Join-Path $AiRoot "gemini/commands") `
        -Target (Join-Path $HOME ".gemini/commands")
}

if (Test-Selected "opencode") {
    Install-SettingsFile -Source (Join-Path $AiRoot "opencode/opencode.jsonc.tmpl") `
        -Target (Join-Path $HOME ".config/opencode/opencode.jsonc") -Template
}

Write-Host "AI settings restore complete. Sign in to each tool separately; credentials are not restored."
