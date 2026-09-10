#Requires -Version 7.0

[CmdletBinding()]
param([string]$Root = $env:DOTFILES_PROJECTS_ROOT)

$ErrorActionPreference = "Stop"
$RepoRoot = Split-Path -Parent $PSScriptRoot
$Manifest = Join-Path $RepoRoot "config/projects/projects.tsv"
if (-not $Root) { $Root = Join-Path $HOME "git_apps" }
if (-not (Test-Path -LiteralPath $Root -PathType Container)) { throw "Projects root does not exist: $Root" }

$lines = [Collections.Generic.List[string]]::new()
[void]$lines.Add("# Portable Git workspace manifest.")
[void]$lines.Add("# path`tremote URL`tbranch")

Get-ChildItem -LiteralPath $Root -Directory -Recurse -Force -Filter ".git" | Sort-Object FullName | ForEach-Object {
    $project = $_.Parent.FullName
    $relative = [IO.Path]::GetRelativePath($Root, $project).Replace("\", "/")
    $remote = (& git -C $project remote get-url origin 2>$null)
    $branch = (& git -C $project branch --show-current 2>$null)
    if (-not $remote) { Write-Host "SKIP  $project (no origin remote)"; return }
    if ("$relative$remote$branch" -match "[`t`r`n]") { Write-Warning "Skipping $project (tab/newline in manifest value)"; return }
    if ($remote -match '^https?://[^/@:]+:[^/@]+@') { throw "REFUSE $project has credentials embedded in its remote URL." }
    [void]$lines.Add("$relative`t$remote`t$branch")
    if (& git -C $project status --porcelain) { Write-Warning "$relative has uncommitted files; the manifest cannot transfer them." }
    else { Write-Host "ADD   $relative" }
}

New-Item -ItemType Directory -Path (Split-Path -Parent $Manifest) -Force | Out-Null
($lines -join "`n") + "`n" | Set-Content -LiteralPath $Manifest -NoNewline
Write-Host "Project manifest written to config/projects/projects.tsv. Review it before committing."
