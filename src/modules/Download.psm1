# Variables para manejo de formatos
$script:formatsIndex = @{}   # format_id -> objeto con metadatos
$script:formatsVideo = @()   # lista de objetos mostrables en Combo Video
$script:formatsAudio = @()   # lista de objetos mostrables en Combo Audio
$script:ExcludedFormatIds = @('18','22','95','96')
$script:bestProgId = $null
$script:bestProgRank = -1

# Funciones de clasificación de formatos
function Classify-Format {
    param($fmt)
    $v = $fmt.vcodec; $a = $fmt.acodec
    $isVideoOnly = $v -and $v -ne "none" -and ($a -eq $null -or $a -eq "" -or $a -eq "none")
    $isAudioOnly = $a -and $a -ne "none" -and ($v -eq $null -or $v -eq "" -or $v -eq "none")
    $isProgressive = $v -and $v -ne "none" -and $a -and $a -ne "none"

    [pscustomobject]@{
        VideoOnly     = [bool]$isVideoOnly
        AudioOnly     = [bool]$isAudioOnly
        Progressive   = [bool]$isProgressive
        Ext           = $fmt.ext
        VRes          = if ($fmt.height) { [int]$fmt.height } else { 0 }
        VCodec        = $fmt.vcodec
        ACodec        = $fmt.acodec
        ABr           = if ($fmt.abr) { [double]$fmt.abr } else { 0 }
        Tbr           = if ($fmt.tbr) { [double]$fmt.tbr } else { 0 }
        Filesize      = $fmt.filesize
        FormatNote    = $fmt.format_note
        Id            = $fmt.format_id
    }
}

function New-FormatDisplay {
    param([string]$Id, [string]$Label)
    return ("{0} — {1}" -f $Id, $Label)
}

function Fetch-Formats {
    param([Parameter(Mandatory=$true)][string]$Url)
    # Implementación de Fetch-Formats...
}

function Populate-FormatCombos {
    # Implementación de Populate-FormatCombos...
}

function Get-SelectedFormatId {
    param([System.Windows.Forms.ComboBox]$Combo)
    if (-not $Combo) { return $null }
    if (-not $Combo.SelectedItem) { return $null }
    $t = [string]$Combo.SelectedItem
    if ([string]::IsNullOrWhiteSpace($t)) { return $null }
    return ($t -split '\s')[0]
}

function Test-YouTubePlaylist {
    param([Parameter(Mandatory=$true)][string]$Url)
    return ($Url -match 'list=' -and $Url -match 'youtube\.com') -or
           ($Url -match '^https?://(www\.)?youtube\.com/playlist') -or
           ($Url -match '^https?://(www\.)?youtube\.com/watch.*list=') -or
           ($Url -match 'start_radio=1')
}

function Extract-VideoFromPlaylist {
    param([Parameter(Mandatory=$true)][string]$Url)
    # Implementación de Extract-VideoFromPlaylist...
}

function Invoke-ConsultaFromUI {
    param([Parameter(Mandatory = $true)][string]$Url)
    # Implementación de Invoke-ConsultaFromUI...
}

Export-ModuleMember -Function Classify-Format, New-FormatDisplay, Fetch-Formats, `
    Populate-FormatCombos, Get-SelectedFormatId, Test-YouTubePlaylist, `
    Extract-VideoFromPlaylist, Invoke-ConsultaFromUI `
    -Variable formatsIndex, formatsVideo, formatsAudio, ExcludedFormatIds, `
    bestProgId, bestProgRank