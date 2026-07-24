#Requires -Version 7.0

$ErrorActionPreference = "Stop"

Write-Host "Updating Winget packages..."
winget upgrade --all --accept-package-agreements --accept-source-agreements --disable-interactivity

Write-Host "Updating PowerShell help..."
Update-Help -ErrorAction SilentlyContinue

Write-Host "Done."
