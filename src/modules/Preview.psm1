# Funciones de vista previa
function Get-ImageFromUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    # Implementación de Get-ImageFromUrl...
}

function Get-TempThumbPattern {
    $tmp = [System.IO.Path]::GetTempPath()
    return (Join-Path $tmp "ytdll_thumb_*")
}

function Get-ThumbnailListFromYtDlp {
    param([Parameter(Mandatory = $true)][string]$Url)
    # Implementación de Get-ThumbnailListFromYtDlp...
}

function Select-BestThumbnail {
    param([Parameter(Mandatory = $true)][array]$Thumbs)
    # Implementación de Select-BestThumbnail...
}

function Fetch-ThumbnailFile {
    param([Parameter(Mandatory=$true)][string]$Url)
    # Implementación de Fetch-ThumbnailFile...
}

function Show-PreviewUniversal {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$Titulo = $null,
        [string]$DirectThumbUrl = $null
    )
    # Implementación de Show-PreviewUniversal...
}

function Show-PreviewImage {
    param(
        [Parameter(Mandatory=$true)][string]$ImageUrl,
        [string]$Titulo = $null
    )
    # Implementación de Show-PreviewImage...
}

function Get-BestThumbnailUrl {
    param([Parameter(Mandatory=$true)]$Json)
    # Implementación de Get-BestThumbnailUrl...
}

function Get-BestStreamUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    # Implementación de Get-BestStreamUrl...
}

function Convert-WebpUrlToPng {
    param([Parameter(Mandatory=$true)][string]$Url)
    # Implementación de Convert-WebpUrlToPng...
}

Export-ModuleMember -Function Get-ImageFromUrl, Get-TempThumbPattern, `
    Get-ThumbnailListFromYtDlp, Select-BestThumbnail, Fetch-ThumbnailFile, `
    Show-PreviewUniversal, Show-PreviewImage, Get-BestThumbnailUrl, `
    Get-BestStreamUrl, Convert-WebpUrlToPng