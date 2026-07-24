function mkcd {
    param([Parameter(Mandatory)][string]$Path)

    New-Item -ItemType Directory -Path $Path -Force | Out-Null
    Set-Location -Path $Path
}

function which {
    param([Parameter(Mandatory)][string]$Name)

    Get-Command $Name | Select-Object -ExpandProperty Source
}

function xclip {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline)]
        [object]$InputObject
    )

    begin {
        $items = [System.Collections.Generic.List[string]]::new()
    }

    process {
        if ($null -ne $InputObject) {
            $items.Add([string]$InputObject)
        }
    }

    end {
        if ($items.Count -gt 0) {
            $items -join [Environment]::NewLine | Set-Clipboard
            return
        }

        Get-Clipboard
    }
}

function base_py {
    $activationScript = Join-Path $HOME "venv\base\Scripts\Activate.ps1"

    if (-not (Test-Path -LiteralPath $activationScript)) {
        throw "Base Python environment was not found at $activationScript."
    }

    . $activationScript
}
