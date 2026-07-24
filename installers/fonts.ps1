#Requires -Version 7.0

function Install-Fonts {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [switch]$Force
    )

    Write-Skip "Font installation is not configured yet."
}

Register-BootstrapStep -Name "fonts" -Action {
    param([hashtable]$Context)

    Install-Fonts -RepoRoot $Context.RepoRoot -Force:([bool]$Context.Force)
}
