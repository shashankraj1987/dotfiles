#Requires -Version 7.0

$ErrorActionPreference = "Stop"

Write-Host ""
Write-Host "======================================="
Write-Host " Windows Developer Environment Setup"
Write-Host "======================================="
Write-Host ""

function Install-Package {
    param(
        [string]$Id,
        [string]$Name
    )

    Write-Host "Installing $Name..."

    winget install `
        --id $Id `
        --exact `
        --silent `
        --accept-package-agreements `
        --accept-source-agreements `
        --disable-interactivity
}

function Add-ProfileBlock {

    $marker = "# >>> DEV TOOLS >>>"

    if (!(Test-Path $PROFILE)) {
        New-Item -ItemType File -Force $PROFILE | Out-Null
    }

    $content = Get-Content $PROFILE -Raw

    if ($content.Contains($marker)) {
        Write-Host "Profile already configured."
        return
    }

    @"

$marker

# Zoxide
Invoke-Expression (& { (zoxide init powershell | Out-String) })

# eza aliases
function ls { eza }
function ll { eza -la --git --icons }
function la { eza -a }
function lt { eza --tree --level=2 --icons }

# Better defaults
Set-Alias cat bat
Set-Alias grep rg

# fzf
`$env:FZF_DEFAULT_COMMAND = "fd --type f --hidden --exclude .git"
`$env:FZF_CTRL_T_COMMAND = `$env:FZF_DEFAULT_COMMAND
`$env:_ZO_FZF_OPTS = "--height=40% --border --reverse"

# <<< DEV TOOLS <<<

"@ | Add-Content $PROFILE

    Write-Host "PowerShell profile updated."
}

if (!(Get-Command winget -ErrorAction SilentlyContinue)) {
    throw "Winget not found."
}

$packages = @(
    @{
        Name="zoxide"
        Id="ajeetdsouza.zoxide"
    },
    @{
        Name="fzf"
        Id="junegunn.fzf"
    },
    @{
        Name="eza"
        Id="eza-community.eza"
    },
    @{
        Name="bat"
        Id="sharkdp.bat"
    },
    @{
        Name="fd"
        Id="sharkdp.fd"
    },
    @{
        Name="ripgrep"
        Id="BurntSushi.ripgrep.MSVC"
    }
)

foreach ($pkg in $packages) {
    Install-Package $pkg.Id $pkg.Name
}

Add-ProfileBlock

Write-Host ""
Write-Host "Installed Versions"
Write-Host "------------------"

$commands = @(
    "zoxide",
    "fzf",
    "eza",
    "bat",
    "fd",
    "rg"
)

foreach ($cmd in $commands) {

    if (Get-Command $cmd -ErrorAction SilentlyContinue) {

        try {
            $version = (& $cmd --version | Select-Object -First 1)
        }
        catch {
            $version = "Installed"
        }

        "{0,-10} {1}" -f $cmd, $version
    }
}

Write-Host ""
Write-Host "Done."
Write-Host ""
Write-Host "Restart PowerShell."
