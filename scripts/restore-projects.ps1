#Requires -Version 7.0

[CmdletBinding()]
param([string]$Root = $env:DOTFILES_PROJECTS_ROOT)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Manifest = Join-Path $RepoRoot "config/projects/projects.tsv"
if (-not $Root) { $Root = Join-Path $HOME "git_apps" }
if (-not (Test-Path -LiteralPath $Manifest -PathType Leaf)) { return }
New-Item -ItemType Directory -Path $Root -Force | Out-Null

foreach ($line in Get-Content -LiteralPath $Manifest) {
    if (-not $line -or $line.StartsWith("#")) { continue }
    $fields = $line -split "`t", 3
    if ($fields.Count -lt 2) { throw "Invalid project manifest line: $line" }
    $relative, $remote = $fields[0], $fields[1]
    $branch = if ($fields.Count -eq 3) { $fields[2] } else { "" }
    if ([IO.Path]::IsPathRooted($relative) -or $relative -split '[/\\]' -contains '..') {
        throw "REFUSE unsafe project path in manifest: $relative"
    }
    $target = Join-Path $Root $relative
    if (Test-Path -LiteralPath $target) { Write-Host "SKIP  $target (exists)"; continue }
    New-Item -ItemType Directory -Path (Split-Path -Parent $target) -Force | Out-Null
    Write-Host "CLONE $remote -> $target"
    & git clone $remote $target
    if ($LASTEXITCODE -ne 0) { throw "git clone failed for $remote" }
    if ($branch) {
        & git -C $target show-ref --verify --quiet "refs/remotes/origin/$branch"
        if ($LASTEXITCODE -eq 0) { & git -C $target checkout $branch }
    }
}
