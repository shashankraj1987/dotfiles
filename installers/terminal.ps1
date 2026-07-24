#Requires -Version 7.0

function Configure-Terminal {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)][string]$RepoRoot,
        [switch]$Force
    )

    $settingsPath = Join-Path $RepoRoot "config\windows-terminal\settings.json"
    if (Test-Path -LiteralPath $settingsPath) {
        Write-Skip "Windows Terminal settings template is ready at $settingsPath."
    }
}

Register-BootstrapStep -Name "terminal" -Action {
    param([hashtable]$Context)

    Configure-Terminal -RepoRoot $Context.RepoRoot -Force:([bool]$Context.Force)
}
