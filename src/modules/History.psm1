# Funciones de historial
function Show-UrlHistoryMenu {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Control]$AnchorControl
    )
    # Implementación de Show-UrlHistoryMenu...
}

function Add-HistoryUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    # Implementación de Add-HistoryUrl...
}

function Get-HistoryUrls {
    # Implementación de Get-HistoryUrls...
}

Export-ModuleMember -Function Show-UrlHistoryMenu, Add-HistoryUrl, Get-HistoryUrls