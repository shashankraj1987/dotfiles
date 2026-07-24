#Requires -Version 7.0

$script:WingetPackages = @(
    @{
        Name = "zoxide"
        Id = "ajeetdsouza.zoxide"
    },
    @{
        Name = "fzf"
        Id = "junegunn.fzf"
    },
    @{
        Name = "eza"
        Id = "eza-community.eza"
    },
    @{
        Name = "bat"
        Id = "sharkdp.bat"
    },
    @{
        Name = "fd"
        Id = "sharkdp.fd"
    },
    @{
        Name = "ripgrep"
        Id = "BurntSushi.ripgrep.MSVC"
    },
    @{
        Name = "bottom"
        Id = "Clement.bottom"
    },
    @{
        Name = "Oh My Posh"
        Id = "JanDeDobbeleer.OhMyPosh"
    }
)

function Install-WingetPackages {
    [CmdletBinding()]
    param([switch]$Force)

    foreach ($pkg in $script:WingetPackages) {
        Install-Package -Id $pkg.Id -Name $pkg.Name -Force:$Force
    }

    Update-SessionPath
}

Register-BootstrapStep -Name "winget" -Enabled -Action {
    param([hashtable]$Context)

    Install-WingetPackages -Force:([bool]$Context.Force)
}
