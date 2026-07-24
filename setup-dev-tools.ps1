#Requires -Version 7.0

[CmdletBinding()]
param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

Write-Warning "setup-dev-tools.ps1 is kept for compatibility. Use .\bootstrap.ps1 for new installs."

& (Join-Path $PSScriptRoot "bootstrap.ps1") -Force:$Force
