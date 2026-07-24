#Requires -Version 7.0

$ErrorActionPreference = "Continue"

$machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
$env:Path = ($machinePath, $userPath | Where-Object { $_ }) -join ";"

$checks = @(
    "git",
    "pwsh",
    "eza",
    "bat",
    "fd",
    "rg",
    "zoxide",
    "fzf",
    "btm",
    "oh-my-posh"
)

foreach ($cmd in $checks) {
    if (-not (Get-Command $cmd -ErrorAction SilentlyContinue)) {
        "{0,-12} MISSING" -f $cmd
        continue
    }

    try {
        $version = (& $cmd --version 2>$null | Select-Object -First 1)
        if (-not $version) {
            $version = "Installed"
        }
    }
    catch {
        $version = "Installed"
    }

    "{0,-12} {1}" -f $cmd, $version
}
