# Funciones de utilidad general
function Get-CleanUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    $cleanUrl = $Url -replace '^https?://', ''
    $cleanUrl = $cleanUrl -replace '^www\.', ''
    $cleanUrl = $cleanUrl -replace '/+$', ''  # Quitar trailing slashes
    return $cleanUrl.Trim()
}

function Get-YouTubeVideoId {
    param([Parameter(Mandatory=$true)][string]$Url)
    $m = [regex]::Match($Url, 'youtu\.be/([A-Za-z0-9_-]{11})', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($Url, '[?&]v=([A-Za-z0-9_-]{11})', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($Url, '/shorts/([A-Za-z0-9_-]{11})', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($Url, '/embed/([A-Za-z0-9_-]{11})', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}

function Get-CurrentUrl {
    if (-not $txtUrl) { return "" }
    $t = ($txtUrl.Text).Trim()
    if ($t -eq $global:UrlPlaceholder) { return "" }
    return $t
}

function Human-Size {
    param([Nullable[long]]$bytes)
    if (-not $bytes -or $bytes -le 0) { return "" }
    $units = "B","KiB","MiB","GiB","TiB"
    $p = 0; $n = [double]$bytes
    while ($n -ge 1024 -and $p -lt $units.Count-1) { $n/=1024; $p++ }
    return ("{0:N1}{1}" -f $n, $units[$p])
}

function Get-SafeFileName {
    param([Parameter(Mandatory=$true)][string]$Name)
    $invalid = ([IO.Path]::GetInvalidFileNameChars() -join '')
    $regex = "[{0}]" -f [regex]::Escape($invalid)
    $n = [regex]::Replace($Name, $regex, " ")
    $n = ($n -replace '\s+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($n)) { $n = "video" }
    return $n
}

function Get-DisplayUrl {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $Url }
    $u = $Url.Trim()
    $u = $u -replace '^https?://', ''
    $u = $u -replace '^www\.', ''
    return $u
}

function Invoke-CaptureResponsive {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [string[]]$Args = @(),
        [string]$WorkingText = "Procesando...",
        [int]$TimeoutSec = 120
    )
    # Implementación de Invoke-CaptureResponsive...
}

function Invoke-Capture {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [string[]]$Args=@(),
        [int]$TimeoutSeconds = 30
    )
    # Implementación de Invoke-Capture...
}

function Invoke-YtDlpConsoleProgress {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [Parameter(Mandatory=$true)][string[]]$Args,
        [switch]$UpdateUi
    )
    # Implementación de Invoke-YtDlpConsoleProgress...
}

Export-ModuleMember -Function Get-CleanUrl, Get-YouTubeVideoId, Get-CurrentUrl, `
    Human-Size, Get-SafeFileName, Get-DisplayUrl, Invoke-CaptureResponsive, `
    Invoke-Capture, Invoke-YtDlpConsoleProgress