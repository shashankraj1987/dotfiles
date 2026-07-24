$DotfilesRoot = $PSScriptRoot
$PowerShellConfigRoot = Join-Path $DotfilesRoot "config\powershell"

Import-Module Terminal-Icons -ErrorAction SilentlyContinue

. (Join-Path $PowerShellConfigRoot "env.ps1")
. (Join-Path $PowerShellConfigRoot "aliases.ps1")
. (Join-Path $PowerShellConfigRoot "functions.ps1")
. (Join-Path $PowerShellConfigRoot "completions.ps1")

if (Get-Command zoxide -ErrorAction SilentlyContinue) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
}

$OhMyPoshTheme = Join-Path $DotfilesRoot "config\oh-my-posh\theme.json"
if ((Get-Command oh-my-posh -ErrorAction SilentlyContinue) -and (Test-Path -LiteralPath $OhMyPoshTheme)) {
    oh-my-posh init pwsh --config $OhMyPoshTheme | Invoke-Expression
}
