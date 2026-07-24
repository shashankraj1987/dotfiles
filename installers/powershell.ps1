#Requires -Version 7.0

function Configure-PowerShell {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [switch]$Force
    )

    Set-ProfileLoader -RepoRoot $RepoRoot -Force:$Force
    Install-PowerShellModule -Name "Terminal-Icons" -Force:$Force

    $configPath = Join-Path $RepoRoot "config\powershell"
    foreach ($file in @("aliases.ps1", "functions.ps1", "env.ps1", "completions.ps1")) {
        $path = Join-Path $configPath $file
        if (-not (Test-Path -LiteralPath $path)) {
            throw "Missing PowerShell config file: $path"
        }
    }

    Write-Success "PowerShell configuration is ready."
}

function Install-PowerShellModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Name,
        [switch]$Force
    )

    if (-not $Force -and (Get-Module -ListAvailable -Name $Name)) {
        Write-Skip "$Name module is already installed."
        return
    }

    Write-Step "Installing PowerShell module $Name..."
    Install-Module -Name $Name -Scope CurrentUser -Force -AllowClobber
}

Register-BootstrapStep -Name "powershell" -Enabled -Action {
    param([hashtable]$Context)

    Configure-PowerShell -RepoRoot $Context.RepoRoot -Force:([bool]$Context.Force)
}
