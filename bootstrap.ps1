#Requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$Force,
    [switch]$SkipPackages,
    [switch]$SkipPowerShell
)

$ErrorActionPreference = "Stop"

$RepoRoot = $PSScriptRoot
$InstallerRoot = Join-Path $RepoRoot "installers"

. (Join-Path $InstallerRoot "common.ps1")

Write-Banner "Windows Developer Environment Setup"

. (Join-Path $InstallerRoot "winget.ps1")
. (Join-Path $InstallerRoot "powershell.ps1")
. (Join-Path $InstallerRoot "git.ps1")
. (Join-Path $InstallerRoot "terminal.ps1")
. (Join-Path $InstallerRoot "fonts.ps1")

if ($SkipPackages) {
    Disable-BootstrapStep -Name "winget"
}

if ($SkipPowerShell) {
    Disable-BootstrapStep -Name "powershell"
}

Invoke-BootstrapSteps -Context @{
    RepoRoot = $RepoRoot
    Force = [bool]$Force
}

Write-Host ""
Write-Success "Bootstrap complete."
Write-Step "Restart PowerShell to load the updated profile."
