foreach ($name in @("cp", "mv", "rm", "ls", "ll", "la", "lt", "cat", "grep", "less", "top", "vi")) {
    if (Test-Path -LiteralPath "Alias:\$name") {
        Remove-Item -LiteralPath "Alias:\$name" -Force
    }
}

function cp {
    Copy-Item @args -Verbose
}

function mv {
    Move-Item @args -Verbose -Confirm
}

function rm {
    Remove-Item @args -Confirm
}

function ls {
    eza @args
}

function ll {
    eza -la --icons --git @args
}

function la {
    eza -a --icons @args
}

function lt {
    eza --tree --level=2 --icons @args
}

function less {
    if (Get-Command bat -ErrorAction SilentlyContinue) {
        bat --paging=always @args
        return
    }

    Get-Content @args
}

function top {
    if (Get-Command btm -ErrorAction SilentlyContinue) {
        btm @args
        return
    }

    Get-Process | Sort-Object CPU -Descending | Select-Object -First 20
}

Set-Alias cat bat -Force
Set-Alias grep rg -Force

if (Get-Command vim -ErrorAction SilentlyContinue) {
    Set-Alias vi vim -Force
}
elseif (Get-Command nvim -ErrorAction SilentlyContinue) {
    Set-Alias vi nvim -Force
}
