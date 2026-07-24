#Requires -Version 7.0

function Configure-Git {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [switch]$Force
    )

    $source = Join-Path $RepoRoot "config\git\gitconfig"
    $destination = Join-Path $HOME ".gitconfig"

    if (-not (Test-Path -LiteralPath $source)) {
        Write-Skip "No gitconfig template found."
        return
    }

    if ($Force) {
        Copy-IfChanged -Source $source -Destination $destination
    }
    else {
        Write-Skip "Git configuration is available but not applied by default."
    }
}

Register-BootstrapStep -Name "git" -Action {
    param([hashtable]$Context)

    Configure-Git -RepoRoot $Context.RepoRoot -Force:([bool]$Context.Force)
}
