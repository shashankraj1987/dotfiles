#Requires -Version 7.0

[CmdletBinding()]
param(
    [string[]]$Tools = @("codex", "claude", "copilot", "gemini", "opencode"),
    [switch]$IncludeMemories
)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$AiRoot = Join-Path $RepoRoot "config/ai"
$HomePortable = $HOME.Replace("\", "/")
$SecretPattern = '(?i)(api[_-]?key|access[_-]?token|refresh[_-]?token|client[_-]?secret|password|authorization)["\s]*[:=]\s*["'']?[^"''\s}]{8,}'

function Test-Selected {
    param([string]$Name)
    return $Tools -contains $Name
}

function Assert-NoSecrets {
    param([string]$Source)
    $content = Get-Content -LiteralPath $Source -Raw
    if ($content -match $SecretPattern) {
        throw "REFUSE $Source appears to contain a credential; sanitize it manually."
    }
}

function Copy-SettingsFile {
    param(
        [string]$Source,
        [string]$Target,
        [switch]$Template
    )
    if (-not (Test-Path -LiteralPath $Source -PathType Leaf)) { return }
    Assert-NoSecrets $Source
    New-Item -ItemType Directory -Path (Split-Path -Parent $Target) -Force | Out-Null
    if ($Template) {
        (Get-Content -LiteralPath $Source -Raw).Replace($HomePortable, "@HOME@").Replace($HOME, "@HOME@") |
            Set-Content -LiteralPath $Target -NoNewline
    }
    else {
        Copy-Item -LiteralPath $Source -Destination $Target -Force
    }
    $relative = [IO.Path]::GetRelativePath($RepoRoot, $Target)
    Write-Host "COPY  $Source -> $relative"
}

function Copy-SettingsTree {
    param([string]$Source, [string]$Target)
    if (-not (Test-Path -LiteralPath $Source -PathType Container)) { return }
    Get-ChildItem -LiteralPath $Source -File -Recurse | Where-Object {
        $_.FullName -notmatch '[\\/](\.system|cache|logs|sessions|projects)[\\/]' -and
        $_.Name -notmatch '\.sqlite(-shm|-wal)?$'
    } | ForEach-Object {
        $relative = [IO.Path]::GetRelativePath($Source, $_.FullName)
        Copy-SettingsFile -Source $_.FullName -Target (Join-Path $Target $relative)
    }
}

function Backup-CodexConfig {
    $source = Join-Path $HOME ".codex/config.toml"
    if (-not (Test-Path -LiteralPath $source -PathType Leaf)) { return }
    Assert-NoSecrets $source

    $result = [Collections.Generic.List[string]]::new()
    $skip = $false
    foreach ($line in Get-Content -LiteralPath $source) {
        if ($line -match '^\[') {
            $skip = $line -match '^\[marketplaces\.' -or
                $line -match '^\[mcp_servers\.node_repl(\.|\])' -or
                $line -match '^\[shell_environment_policy\.set\]' -or
                $line -match '^\[projects\.'
        }
        if (-not $skip) { [void]$result.Add($line) }
    }

    $target = Join-Path $AiRoot "codex/config.toml.tmpl"
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    (($result -join [Environment]::NewLine).Replace($HomePortable, "@HOME@").Replace($HOME, "@HOME@") + [Environment]::NewLine) |
        Set-Content -LiteralPath $target -NoNewline
    Write-Host "COPY  $source -> config/ai/codex/config.toml.tmpl (machine-generated sections removed)"
}

if (Test-Selected "codex") {
    Backup-CodexConfig
    Copy-SettingsFile -Source (Join-Path $HOME ".codex/AGENTS.md") `
        -Target (Join-Path $AiRoot "codex/common/AGENTS.md")
    Copy-SettingsTree -Source (Join-Path $HOME ".codex/rules") -Target (Join-Path $AiRoot "codex/windows/rules")
    Copy-SettingsTree -Source (Join-Path $HOME ".codex/skills") -Target (Join-Path $AiRoot "codex/common/skills")
    if ($IncludeMemories) {
        Copy-SettingsTree -Source (Join-Path $HOME ".codex/memories") `
            -Target (Join-Path $AiRoot "codex/common/memories")
    }
}

if (Test-Selected "claude") {
    Copy-SettingsFile -Source (Join-Path $HOME ".claude/settings.json") `
        -Target (Join-Path $AiRoot "claude/settings.json.tmpl") -Template
    Copy-SettingsFile -Source (Join-Path $HOME ".claude/CLAUDE.md") `
        -Target (Join-Path $AiRoot "claude/CLAUDE.md")
    foreach ($part in @("agents", "commands", "hooks", "skills")) {
        Copy-SettingsTree -Source (Join-Path $HOME ".claude/$part") -Target (Join-Path $AiRoot "claude/$part")
    }
}

if (Test-Selected "copilot") {
    Copy-SettingsFile -Source (Join-Path $HOME ".copilot/settings.json") `
        -Target (Join-Path $AiRoot "copilot/settings.json.tmpl") -Template
}

if (Test-Selected "gemini") {
    Copy-SettingsFile -Source (Join-Path $HOME ".gemini/settings.json") `
        -Target (Join-Path $AiRoot "gemini/settings.json.tmpl") -Template
    Copy-SettingsFile -Source (Join-Path $HOME ".gemini/GEMINI.md") `
        -Target (Join-Path $AiRoot "gemini/GEMINI.md")
    Copy-SettingsTree -Source (Join-Path $HOME ".gemini/commands") -Target (Join-Path $AiRoot "gemini/commands")
}

if (Test-Selected "opencode") {
    Copy-SettingsFile -Source (Join-Path $HOME ".config/opencode/opencode.jsonc") `
        -Target (Join-Path $AiRoot "opencode/opencode.jsonc.tmpl") -Template
}

Write-Host "AI settings backup complete. Review 'git diff -- config/ai' before committing."
