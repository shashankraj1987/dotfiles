#Requires -Version 7.0

if (-not $script:BootstrapSteps) {
    $script:BootstrapSteps = [System.Collections.Generic.List[object]]::new()
}

function Write-Banner {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host ""
    Write-Host "======================================="
    Write-Host " $Message"
    Write-Host "======================================="
    Write-Host ""
}

function Write-Step {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "[..] $Message" -ForegroundColor Cyan
}

function Write-Success {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "[OK] $Message" -ForegroundColor Green
}

function Write-Skip {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "[SKIP] $Message" -ForegroundColor DarkGray
}

function Write-Warn {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Test-Command {
    param([Parameter(Mandatory)][string]$Name)

    $null -ne (Get-Command $Name -ErrorAction SilentlyContinue)
}

function Update-SessionPath {
    $machinePath = [Environment]::GetEnvironmentVariable("Path", "Machine")
    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    $env:Path = ($machinePath, $userPath | Where-Object { $_ }) -join ";"
}

function Test-WingetPackageInstalled {
    param([Parameter(Mandatory)][string]$Id)

    if (-not (Test-Command "winget")) {
        return $false
    }

    $output = winget list --id $Id --exact --accept-source-agreements 2>$null
    return ($LASTEXITCODE -eq 0 -and ($output -match [regex]::Escape($Id)))
}

function Install-Package {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$Id,
        [Parameter(Mandatory)][string]$Name,
        [switch]$Force
    )

    if (-not (Test-Command "winget")) {
        throw "Winget was not found. Install App Installer from the Microsoft Store, then rerun bootstrap."
    }

    if (-not $Force -and (Test-WingetPackageInstalled -Id $Id)) {
        Write-Skip "$Name is already installed."
        return
    }

    if ($Force -and (Test-WingetPackageInstalled -Id $Id)) {
        Write-Step "Reinstalling $Name..."
        winget install --id $Id --exact --silent --force --accept-package-agreements --accept-source-agreements --disable-interactivity
        return
    }

    Write-Step "Installing $Name..."
    winget install --id $Id --exact --silent --accept-package-agreements --accept-source-agreements --disable-interactivity
    Update-SessionPath
}

function Backup-File {
    param([Parameter(Mandatory)][string]$Path)

    if (-not (Test-Path -LiteralPath $Path)) {
        return $null
    }

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $backupPath = "$Path.$timestamp.bak"
    Copy-Item -LiteralPath $Path -Destination $backupPath -Force
    return $backupPath
}

function Copy-IfChanged {
    param(
        [Parameter(Mandatory)][string]$Source,
        [Parameter(Mandatory)][string]$Destination
    )

    $destinationDir = Split-Path -Parent $Destination
    if ($destinationDir -and -not (Test-Path -LiteralPath $destinationDir)) {
        New-Item -ItemType Directory -Path $destinationDir -Force | Out-Null
    }

    if ((Test-Path -LiteralPath $Destination) -and
        ((Get-FileHash -LiteralPath $Source).Hash -eq (Get-FileHash -LiteralPath $Destination).Hash)) {
        Write-Skip "$Destination is already current."
        return
    }

    Copy-Item -LiteralPath $Source -Destination $Destination -Force
    Write-Success "Updated $Destination."
}

function Ensure-Profile {
    $profileDir = Split-Path -Parent $PROFILE
    if (-not (Test-Path -LiteralPath $profileDir)) {
        New-Item -ItemType Directory -Path $profileDir -Force | Out-Null
    }

    if (-not (Test-Path -LiteralPath $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    return $PROFILE
}

function Set-ProfileLoader {
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [switch]$Force
    )

    $profilePath = Ensure-Profile
    $repoProfile = Join-Path $RepoRoot "profile.ps1"
    $loader = @"
# Managed by dotfiles bootstrap.
. "$repoProfile"
"@

    $current = ""
    if (Test-Path -LiteralPath $profilePath) {
        $current = Get-Content -LiteralPath $profilePath -Raw
    }

    if ($current.Trim() -eq $loader.Trim()) {
        Write-Skip "PowerShell profile loader is already configured."
        return
    }

    if ($current.Trim().Length -gt 0 -and -not $Force) {
        $backup = Backup-File -Path $profilePath
        Write-Warn "Existing PowerShell profile backed up to $backup."
    }

    Set-Content -LiteralPath $profilePath -Value $loader -Encoding UTF8
    Write-Success "PowerShell profile now loads $repoProfile."
}

function Register-BootstrapStep {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Action,
        [switch]$Enabled
    )

    $script:BootstrapSteps.Add([pscustomobject]@{
        Name = $Name
        Action = $Action
        Enabled = [bool]$Enabled
    }) | Out-Null
}

function Disable-BootstrapStep {
    param([Parameter(Mandatory)][string]$Name)

    foreach ($step in $script:BootstrapSteps) {
        if ($step.Name -eq $Name) {
            $step.Enabled = $false
        }
    }
}

function Import-BootstrapInstaller {
    param([Parameter(Mandatory)][string]$Path)

    if (Test-Path -LiteralPath $Path) {
        . $Path
    }
}

function Invoke-BootstrapSteps {
    param([Parameter(Mandatory)][hashtable]$Context)

    foreach ($step in $script:BootstrapSteps) {
        if (-not $step.Enabled) {
            Write-Skip "Step '$($step.Name)' disabled."
            continue
        }

        Write-Step "Running step '$($step.Name)'."
        & $step.Action $Context
    }
}
