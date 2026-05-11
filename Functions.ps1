function Get-IniValue {
    param(
        [string]$Section,
        [string]$Key,
        [string]$DefaultValue = $null
    )
    if (-not (Test-Path $script:ConfigFile)) { return $DefaultValue }
    try {
        $content   = Get-Content $script:ConfigFile -ErrorAction Stop
        $inSection = $false
        foreach ($line in $content) {
            $line = $line.Trim()
            if ($line -eq "[$Section]")       { $inSection = $true;  continue }
            elseif ($line -match '^\[')       { $inSection = $false; continue }
            if ($inSection -and $line -match "^$Key=(.*)$") { return $matches[1].Trim() }
        }
    } catch {
        Write-Host "[CONFIG] Error leyendo configuración: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    return $DefaultValue
}

function Set-IniValue {
    param([string]$Section, [string]$Key, [string]$Value)
    if (-not (Test-Path $script:ConfigDir)) {
        New-Item -ItemType Directory -Path $script:ConfigDir -Force | Out-Null
    }
    $lines       = @()
    $sectionFound = $false
    $keyFound     = $false
    if (Test-Path $script:ConfigFile) { $lines = Get-Content $script:ConfigFile }
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "[$Section]") {
            $sectionFound = $true
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^\[') { break }
                if ($lines[$j] -match "^$Key=") {
                    $lines[$j] = "$Key=$Value"
                    $keyFound  = $true
                    break
                }
            }
            if (-not $keyFound) {
                $lines = @($lines[0..$i]) + @("$Key=$Value") + @($lines[($i+1)..($lines.Count-1)])
            }
            break
        }
    }
    if (-not $sectionFound) {
        $lines += "[$Section]"
        $lines += "$Key=$Value"
    }
    try { Set-Content -Path $script:ConfigFile -Value $lines -Encoding UTF8 }
    catch { Write-Host "[CONFIG] Error guardando configuración: $($_.Exception.Message)" -ForegroundColor Red }
}

function Write-DebugLog {
    param([string]$Message, [string]$ForegroundColor = "Yellow")
    if ($global:DebugEnabled) { Write-Host $Message -ForegroundColor $ForegroundColor }
}

function Get-ActiveCookiesArgs {
    if ([string]::IsNullOrWhiteSpace($script:cookiesPath)) { return @() }
    if (-not (Test-Path -LiteralPath $script:cookiesPath)) {
        Write-Host "[COOKIES] ADVERTENCIA: Archivo de cookies no encontrado: $($script:cookiesPath)" -ForegroundColor Yellow
        return @()
    }
    return @("--cookies", $script:cookiesPath)
}


function Get-JsRuntimeArgs {
    try { $node = Get-Command node -ErrorAction Stop } catch { return @() }
    if ($node -and -not [string]::IsNullOrWhiteSpace($node.Source)) {
        return @("--js-runtimes", ("node:{0}" -f $node.Source))
    }
    return @("--js-runtimes", "node")
}
function Get-YouTubeExtractorArgs {
    param(
        [string]$Url,
        [switch]$IncludeMissingPot
    )
    if ([string]::IsNullOrWhiteSpace($Url)) { return @() }
    if ($Url -match '(?i)(youtube\.com|youtu\.be)') {
        if ($IncludeMissingPot) {
            return @("--extractor-args", "youtube:formats=missing_pot")
        }
        return @("--extractor-args", "youtube:player_client=default,-web_safari,-web_embedded,-tv")
    }
    return @()
}

function Test-YouTubeMissingPotRetry {
    param(
        [string]$Url,
        [string]$StdOut,
        [string]$StdErr
    )
    if ([string]::IsNullOrWhiteSpace($Url) -or $Url -notmatch '(?i)(youtube\.com|youtu\.be)') { return $false }
    if (-not [string]::IsNullOrWhiteSpace($StdErr)) {
        if ($StdErr -match 'Requested format is not available' -or $StdErr -match 'PO Token' -or $StdErr -match 'SABR') {
            return $true
        }
    }
    return (-not [string]::IsNullOrWhiteSpace($StdOut)) -and ($StdOut.Trim() -eq "null")
}

function Invoke-YtDlpJsonQuery {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$WorkingText = "Procesando JSON...",
        [int]$TimeoutSec = 60
    )
    $args = @("-J","--no-playlist","--no-warnings","--ignore-config")
    $args += Get-JsRuntimeArgs
    $args += Get-ActiveCookiesArgs
    $args += Get-YouTubeExtractorArgs -Url $Url
    $args += $Url
    $res = Invoke-CaptureResponsive -ExePath $ExePath -Args $args -WorkingText $WorkingText -TimeoutSec $TimeoutSec
    if (Test-YouTubeMissingPotRetry -Url $Url -StdOut $res.StdOut -StdErr $res.StdErr) {
        Write-DebugLog "[DEBUG] Reintentando consulta JSON con youtube:formats=missing_pot" -ForegroundColor Yellow
        $retryArgs = @("-J","--no-playlist","--no-warnings","--ignore-config")
        $retryArgs += Get-JsRuntimeArgs
        $retryArgs += Get-ActiveCookiesArgs
        $retryArgs += Get-YouTubeExtractorArgs -Url $Url -IncludeMissingPot
        $retryArgs += $Url
        return Invoke-CaptureResponsive -ExePath $ExePath -Args $retryArgs -WorkingText ($WorkingText + " (missing_pot)") -TimeoutSec $TimeoutSec
    }
    return $res
}

function Get-CleanUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    $u = $Url -replace '^https?://', ''
    $u = $u -replace '^www\.', ''
    $u = $u -replace '/+$', ''
    return $u.Trim()
}

function Normalize-InputUrl {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $Url }
    $u = $Url.Trim()
    if ($u -eq $global:UrlPlaceholder) { return "" }
    if ($u -match '^(?i)[a-z][a-z0-9+\.-]*://') { return $u }
    if ($u -match '^(?i)//') { return "https:$u" }
    if ($u -match '^(?i)[\w.-]+\.[A-Za-z]{2,}([/:?#]|$)') { return "https://$u" }
    return $u
}

function Get-DisplayUrl {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $Url }
    $u = $Url.Trim() -replace '^https?://', '' -replace '^www\.', ''
    return $u
}

function Get-SafeFileName {
    param([Parameter(Mandatory=$true)][string]$Name)
    $invalid = ([IO.Path]::GetInvalidFileNameChars() -join '')
    $regex   = "[{0}]" -f [regex]::Escape($invalid)
    $n = [regex]::Replace($Name, $regex, " ")
    $n = ($n -replace '\s+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($n)) { $n = "video" }
    return $n
}

function Format-Count {
    param(
        [Parameter(Mandatory=$true)][int]$Count,
        [Parameter(Mandatory=$true)][string]$Singular,
        [Parameter(Mandatory=$true)][string]$Plural
    )
    if ($Count -eq 1) { return "1 $Singular" }
    return ("{0} {1}" -f $Count, $Plural)
}

function Save-Bytes {
    param([byte[]]$Bytes, [string]$Path)
    [System.IO.File]::WriteAllBytes($Path, $Bytes)
    return $Path
}

function Clear-History {
    try { Set-Content -LiteralPath $script:LogFile -Value @() -Encoding UTF8 } catch {}
}

function Add-HistoryUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    Write-DebugLog "[DEBUG] Add-HistoryUrl iniciada con URL: '$Url'" -ForegroundColor Cyan
    $u = $Url.Trim()
    if ([string]::IsNullOrWhiteSpace($u))          { return }
    if ($u -eq $global:UrlPlaceholder)             { return }
    if ($u -notmatch '^(\w+://|www\.|\w+\.\w+)')  { return }

    $cleanUrl = Get-CleanUrl -Url $u
    $title = if ($script:ultimoTitulo) {
        $s = Get-SafeFileName -Name $script:ultimoTitulo
        if ($s.Length -gt 20) { $s.Substring(0,20) + "..." } else { $s }
    } else { "Video" }

    $historyEntry = "{0} | {1}" -f $title, $cleanUrl
    Start-Sleep -Milliseconds 50
    try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}

    $currentEntries = @()
    try {
        if (Test-Path -LiteralPath $script:LogFile) {
            $content = [System.IO.File]::ReadAllText($script:LogFile, [System.Text.Encoding]::UTF8)
            $currentEntries = $content -split "`r?`n" |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -and ($_ -notmatch '^\s*$') }
        }
    } catch { $currentEntries = @() }

    $exists = $false
    foreach ($entry in $currentEntries) {
        if ($entry -match '\|\s*(.+)$') {
            if ($matches[1].Trim() -eq $cleanUrl) { $exists = $true; break }
        } elseif ($entry -eq $cleanUrl) { $exists = $true; break }
    }

    if (-not $exists) {
        $newList = @($historyEntry) + $currentEntries
        if ($newList.Count -gt 200) { $newList = $newList[0..199] }
        try {
            $stream = [System.IO.StreamWriter]::new($script:LogFile, $false, [System.Text.Encoding]::UTF8)
            $stream.Write(($newList -join "`r`n") + "`r`n")
            $stream.Close()
            Write-DebugLog "[HISTORIAL] Guardado: $historyEntry" -ForegroundColor Green
        } catch {
            Write-DebugLog "[ERROR] No se pudo guardar en el historial: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
}

function Get-HistoryUrls {
    try {
        if (Test-Path -LiteralPath $script:LogFile) {
            $content = [System.IO.File]::ReadAllText($script:LogFile, [System.Text.Encoding]::UTF8)
            $lines = $content -split "`r?`n" |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -and ($_ -notmatch '^\s*$') } |
                Select-Object -Unique
        } else { $lines = @() }
        $urls = @()
        foreach ($line in $lines) {
            if ($line -match '\|\s*(.+)$') { $urls += $matches[1].Trim() } else { $urls += $line }
        }
        return $urls
    } catch { return @() }
}

function New-FormatDisplay {
    param([string]$Id, [string]$Label)
    return ("{0} — {1}" -f $Id, $Label)
}

function Classify-Format {
    param($fmt)
    $v = $fmt.vcodec; $a = $fmt.acodec
    [pscustomobject]@{
        VideoOnly   = [bool]($v -and $v -ne "none" -and ($a -eq $null -or $a -eq "" -or $a -eq "none"))
        AudioOnly   = [bool]($a -and $a -ne "none" -and ($v -eq $null -or $v -eq "" -or $v -eq "none"))
        Progressive = [bool]($v -and $v -ne "none" -and $a -and $a -ne "none")
        Ext         = $fmt.ext
        VRes        = if ($fmt.height)   { [int]$fmt.height }    else { 0 }
        VCodec      = $fmt.vcodec
        ACodec      = $fmt.acodec
        ABr         = if ($fmt.abr)      { [double]$fmt.abr }    else { 0 }
        Tbr         = if ($fmt.tbr)      { [double]$fmt.tbr }    else { 0 }
        Filesize    = $fmt.filesize
        FormatNote  = $fmt.format_note
        Id          = $fmt.format_id
    }
}

function Human-Size {
    param([Nullable[long]]$bytes)
    if (-not $bytes -or $bytes -le 0) { return "" }
    $units = "B","KiB","MiB","GiB","TiB"
    $p = 0; $n = [double]$bytes
    while ($n -ge 1024 -and $p -lt $units.Count-1) { $n /= 1024; $p++ }
    return ("{0:N1}{1}" -f $n, $units[$p])
}

function Format-ExtractorsInline {
    param([Parameter(Mandatory=$true)][string]$RawText, [int]$WrapAt = 120)
    $lines = $RawText -split "`r?`n" | ForEach-Object { $_.Trim() } |
        Where-Object { $_ -and ($_ -notmatch '^\s*WARNING') -and ($_ -notmatch '^\s*ERROR') -and ($_ -notmatch '^\s*Deprecation') }
    $tokens = foreach ($ln in $lines) {
        $clean = $ln -replace '\s+\(.*?\)\s*$',''
        $parts = $clean -split '[\s,]+' | Where-Object { $_ }
        foreach ($p in $parts) { if ($p -match '^[A-Za-z0-9][\w:-]+$') { $p } }
    }
    $uniq = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($t in $tokens) { if ($seen.Add($t)) { $null = $uniq.Add($t) } }
    $sb = [System.Text.StringBuilder]::new()
    $lineLen = 0
    for ($i = 0; $i -lt $uniq.Count; $i++) {
        $tok    = $uniq[$i]
        $sep    = if ($i -eq 0 -or $lineLen -eq 0) { '' } else { ' | ' }
        $addLen = $sep.Length + $tok.Length
        if ($WrapAt -gt 0 -and ($lineLen + $addLen) -gt $WrapAt) {
            [void]$sb.AppendLine(); $lineLen = 0; $sep = ''; $addLen = $tok.Length
        }
        [void]$sb.Append($sep); [void]$sb.Append($tok); $lineLen += $addLen
    }
    [pscustomobject]@{ Text = $sb.ToString(); Count = $uniq.Count; List = $uniq }
}

function Print-FormatsTable {
    param([array]$formats)
    Write-Host "`n[FORMATOS] Disponibles (similar a yt-dlp -F):" -ForegroundColor Cyan
    Write-Host ("{0,-8} {1,-12} {2,-6} {3,-15} {4,-15} {5,-8} {6}" `
        -f "res","tamaño","ext","vcodec","acodec","tbr","format_id") -ForegroundColor DarkGray
    $vFmts = @(); $aFmts = @()
    foreach ($f in $formats) {
        $k = Classify-Format $f
        if ($k.Progressive -or $k.VideoOnly) { $vFmts += [pscustomobject]@{Format=$f;Height=$k.VRes;Tbr=$k.Tbr} }
        elseif ($k.AudioOnly)                { $aFmts += [pscustomobject]@{Format=$f;ABr=$k.ABr} }
    }
    $vFmts | Sort-Object @{Expression={($_.Height*100000)+$_.Tbr};Descending=$true} | ForEach-Object {
        $f=$_.Format; $res=if($f.height){"{0}p"-f$f.height}else{""}
        $sz=Human-Size $f.filesize; $tbr=if($f.tbr){"{0}k"-f[math]::Round($f.tbr)}else{""}
        Write-Host ("{0,-8} {1,-12} {2,-6} {3,-15} {4,-15} {5,-8} {6}" `
            -f $res,$sz,$f.ext,$f.vcodec,$f.acodec,$tbr,$f.format_id)
    }
    $aFmts | Sort-Object @{Expression={$_.ABr};Descending=$true} | ForEach-Object {
        $f=$_.Format; $sz=Human-Size $f.filesize; $tbr=if($f.tbr){"{0}k"-f[math]::Round($f.tbr)}else{""}
        Write-Host ("{0,-8} {1,-12} {2,-6} {3,-15} {4,-15} {5,-8} {6}" `
            -f "",$sz,$f.ext,$f.vcodec,$f.acodec,$tbr,$f.format_id)
    }
}

function Get-YouTubeVideoId {
    param([Parameter(Mandatory=$true)][string]$Url)
    foreach ($pattern in @(
        'youtu\.be/([A-Za-z0-9_-]{11})',
        '[?&]v=([A-Za-z0-9_-]{11})',
        '/shorts/([A-Za-z0-9_-]{11})',
        '/embed/([A-Za-z0-9_-]{11})'
    )) {
        $m = [regex]::Match($Url, $pattern, 'IgnoreCase')
        if ($m.Success) { return $m.Groups[1].Value }
    }
    return $null
}

function Test-YouTubePlaylist {
    param([Parameter(Mandatory=$true)][string]$Url)
    return ($Url -match 'list=' -and $Url -match 'youtube\.com') -or
           ($Url -match '^https?://(www\.)?youtube\.com/playlist') -or
           ($Url -match '^https?://(www\.)?youtube\.com/watch.*list=') -or
           ($Url -match 'start_radio=1')
}

function Get-CurrentUrl {

    if (-not $txtUrl) { return "" }
    $t = ($txtUrl.Text).Trim()
    if ($t -eq $global:UrlPlaceholder) { return "" }
    return (Normalize-InputUrl -Url $t)
}

function Invoke-Capture {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [string[]]$Args = @(),
        [int]$TimeoutSeconds = 30
    )
    $psi          = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName  = $ExePath
    $psi.Arguments = (($Args | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } }) -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute        = $false
    $psi.CreateNoWindow         = $true
    Write-DebugLog "[DEBUG] Invoke-Capture: $ExePath $($psi.Arguments)" -ForegroundColor DarkGray
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
        try { $p.Kill() } catch {}
        return [pscustomobject]@{ ExitCode = -1; StdOut = ""; StdErr = "Timeout después de $TimeoutSeconds segundos" }
    }
    return [pscustomobject]@{ ExitCode = $p.ExitCode; StdOut = $p.StandardOutput.ReadToEnd(); StdErr = $p.StandardError.ReadToEnd() }
}

function Invoke-CaptureResponsive {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [string[]]$Args       = @(),
        [string]$WorkingText  = "Procesando...",
        [int]$TimeoutSec      = 120
    )
    $prevBtnState = $null
    if ($btnConsultar)       { $prevBtnState = $btnConsultar.Enabled; $btnConsultar.IsEnabled = $false }
    if ($lblEstadoConsulta)  { $lblEstadoConsulta.Text = $WorkingText }

    $tmpDir  = [System.IO.Path]::GetTempPath()
    $outFile = Join-Path $tmpDir ("proc_stdout_{0}.log" -f ([guid]::NewGuid()))
    $errFile = Join-Path $tmpDir ("proc_stderr_{0}.log" -f ([guid]::NewGuid()))
    $argLine = ($Args | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } }) -join ' '
    Write-DebugLog "[DEBUG] Invoke-CaptureResponsive: $ExePath $argLine" -ForegroundColor DarkGray
    $proc = Start-Process -FilePath $ExePath -ArgumentList $argLine `
                 -NoNewWindow -PassThru `
                 -RedirectStandardOutput $outFile `
                 -RedirectStandardError  $errFile
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $dot = 0
    try {
        while (-not $proc.HasExited) {
            try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}
            $dot = ($dot + 1) % 4
            if ($lblEstadoConsulta) { $lblEstadoConsulta.Text = $WorkingText + ("." * $dot) }
            if ($sw.Elapsed.TotalSeconds -ge $TimeoutSec) {
                try { $proc.Kill() } catch {}
                return [pscustomobject]@{ ExitCode = -1; StdOut = ""; StdErr = "Tiempo de espera agotado ($TimeoutSec s) en '$WorkingText'." }
            }
            Start-Sleep -Milliseconds 120
        }
    } finally {
        $sw.Stop()
        if ($btnConsultar -and $prevBtnState -ne $null) { $btnConsultar.Enabled = $prevBtnState }
    }
    $stdout = ""; $stderr = ""
    try { if (Test-Path $outFile) { $stdout = [IO.File]::ReadAllText($outFile) } } catch {}
    try { if (Test-Path $errFile) { $stderr = [IO.File]::ReadAllText($errFile) } } catch {}
    try { Remove-Item -Path $outFile,$errFile -ErrorAction SilentlyContinue } catch {}
    return [pscustomobject]@{ ExitCode = $proc.ExitCode; StdOut = $stdout; StdErr = $stderr }
}

function Invoke-YtDlpQuery {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [Parameter(Mandatory=$true)][string[]]$Args,
        [switch]$UpdateUi
    )
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
    $global:ProgressPreference = 'SilentlyContinue'
    $tmpDir  = [System.IO.Path]::GetTempPath()
    $errFile = Join-Path $tmpDir ("yt-dlp-stderr_{0}.log" -f ([guid]::NewGuid()))
    $outFile = Join-Path $tmpDir ("yt-dlp-stdout_{0}.log" -f ([guid]::NewGuid()))
    $argLine = ($Args | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } }) -join ' '
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName                  = $ExePath
    $psi.Arguments                 = $argLine
    $psi.RedirectStandardOutput    = $true
    $psi.RedirectStandardError     = $true
    $psi.UseShellExecute           = $false
    $psi.CreateNoWindow            = $true
    $psi.StandardOutputEncoding    = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding     = [System.Text.Encoding]::UTF8
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $started = $proc.Start()
    if (-not $started) {
        return [pscustomobject]@{ ExitCode = -1; StdOut = ""; StdErr = "No se pudo iniciar el proceso" }
    }
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()
    $proc.WaitForExit()
    $proc.Dispose()
    return [pscustomobject]@{ ExitCode = $proc.ExitCode; StdOut = $stdoutTask.GetAwaiter().GetResult(); StdErr = $stderrTask.GetAwaiter().GetResult() }
}

function Invoke-YtDlpConsoleProgress {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [Parameter(Mandatory=$true)][string[]]$Args,
        [switch]$UpdateUi
    )
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
    $global:ProgressPreference = 'SilentlyContinue'
    $tmpDir  = [System.IO.Path]::GetTempPath()
    $errFile = Join-Path $tmpDir ("yt-dlp-stderr_{0}.log" -f ([guid]::NewGuid()))
    $outFile = Join-Path $tmpDir ("yt-dlp-stdout_{0}.log" -f ([guid]::NewGuid()))
    $argLine = ($Args | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } }) -join ' '
    $proc = Start-Process -FilePath $ExePath -ArgumentList $argLine `
        -NoNewWindow -PassThru `
        -RedirectStandardError  $errFile `
        -RedirectStandardOutput $outFile
    $fsErr = [System.IO.File]::Open($errFile,[System.IO.FileMode]::OpenOrCreate,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
    $srErr = New-Object System.IO.StreamReader($fsErr)
    $fsOut = [System.IO.File]::Open($outFile,[System.IO.FileMode]::OpenOrCreate,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
    $srOut = New-Object System.IO.StreamReader($fsOut)
    $script:lastPct        = -1
    $script:lastLineSig    = $null
    $script:hlsDurationSec = $null
    $phase = "Preparando…"
    function Set-Ui([string]$txt) {
        if ($UpdateUi -and $lblEstadoConsulta) { $lblEstadoConsulta.Text = $txt }
    }
    function _PrintLine([string]$text) {
        if ([string]::IsNullOrWhiteSpace($text)) { return }
        $mDur = [regex]::Match($text, 'Duration:\s*(?<h>\d{2}):(?<m>\d{2}):(?<s>\d{2}(?:\.\d+)?)')
        if ($mDur.Success) {
            $h=[int]$mDur.Groups['h'].Value; $m=[int]$mDur.Groups['m'].Value; $s=[double]$mDur.Groups['s'].Value
            $script:hlsDurationSec = ($h*3600 + $m*60 + $s); return
        }
        if ($text -match "^\[(?:hls|https)\s@.*\]\s+Opening\s+'.+\.ts'")         { return }
        if ($text -match '^\s*(Input\s+#0,|Output\s+#0|Press \[q\] to stop)')    { return }
        if ($text -match 'Sleeping\s+(\d+(?:\.\d+)?)\s+seconds')                  { Set-Ui "Esperando $($Matches[1])s…"; Write-Host "`n$text"; return }
        if ($text -match '^\[download\]\s+Destination:')                           { $phase = "Descargando…"; Set-Ui $phase; Write-Host "`n$text"; return }
        if ($text -match '^\[Merger\]\s+Merging formats')                          { $phase = "Fusionando…"; Set-Ui $phase; Write-Host "`n$text"; return }
        if ($text -match '^Deleting original file')                                { $phase = "Borrando temporales…"; Set-Ui $phase; Write-Host "`n$text"; return }
        if ($text -match '^\[(ExtractAudio|Fixup|EmbedSubtitle|ModifyChapters)\]'){ $phase = "Post-procesando…"; Set-Ui $phase; Write-Host "`n$text"; return }
        $m = [regex]::Match($text, 'download:\s*(?<pct>\d+(?:\.\d+)?)%\s*(?:ETA:(?<eta>\S+))?\s*(?:SPEED:(?<spd>.+))?', 'IgnoreCase')
        if (-not $m.Success) { $m = [regex]::Match($text, '(?<pct>\d+(?:\.\d+)?)%\s+of.*?at\s+(?<spd>\S+)\s+ETA\s+(?<eta>\S+)', 'IgnoreCase') }
        if (-not $m.Success) { $m = [regex]::Match($text, '(?<pct>\d+(?:\.\d+)?)%') }
        if ($m.Success) {
            $pct = [int][math]::Min(100,[math]::Round([double]$m.Groups['pct'].Value))
            $eta = $m.Groups['eta'].Value; $spd = $m.Groups['spd'].Value
            if ($pct -ne $script:lastPct) {
                $script:lastPct = $pct
                $etaText = if ($eta) { $eta } else { "--:--" }
                $spdText = if ($spd) { $spd } else { "" }
                Set-Ui ("{0} {1}%  ETA {2}  {3}" -f ($phase -replace '\.\.\.$','…'), $pct, $etaText, $spdText)
                Write-Host ("`r[PROGRESO] {0,3}%  ETA {1,-8}  {2,-16}" -f $pct, $eta, $spd) -NoNewline
            }
            return
        }
        $mFfm = [regex]::Match($text, '^frame=\s*\d+.*time=\d{2}:\d{2}:\d{2}(?:\.\d+)?\s+.*speed=\S+')
        if ($mFfm.Success) {
            $line = ($text -replace '\s+',' ').Trim()
            $sig  = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($line)))
            if ($sig -ne $script:lastLineSig) { $script:lastLineSig = $sig; Set-Ui $line; Write-Host ("`r[PROGRESO] {0}" -f $line) -NoNewline }
            return
        }
        Write-Host "`n$text"
    }
    try {
        Set-Ui "Preparando descarga…"
        $bufErr = ""; $bufOut = ""
        while (-not $proc.HasExited) {
            $bufOut += $srOut.ReadToEnd(); $bufErr += $srErr.ReadToEnd()
            foreach ($chunk in @($bufOut, $bufErr)) {
                if ([string]::IsNullOrEmpty($chunk)) { continue }
                $parts = [regex]::Split($chunk, "\r\n|\n|\r")
                for ($i=0; $i -lt $parts.Length-1; $i++) { _PrintLine $parts[$i] }
            }
            if ($bufOut) { $bufOut = ([regex]::Split($bufOut, "\r\n|\n|\r") | Select-Object -Last 1) }
            if ($bufErr) { $bufErr = ([regex]::Split($bufErr, "\r\n|\n|\r") | Select-Object -Last 1) }
            try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}
            Start-Sleep -Milliseconds 80
        }
        $bufOut += $srOut.ReadToEnd(); $bufErr += $srErr.ReadToEnd()
        foreach ($line in ([regex]::Split(($bufOut + "`n" + $bufErr), "\r\n|\n|\r"))) { _PrintLine $line }
    } finally {
        try { $srErr.Close(); $fsErr.Close() } catch {}
        try { $srOut.Close(); $fsOut.Close() } catch {}
        Write-Host ""
    }
    $code = $proc.ExitCode
    $script:lastYtDlpExitCode = $code
    return $code
}

function Get-Metadata {
    param([Parameter(Mandatory=$true)][string]$Url)
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch { return $null }
    $obj = Invoke-YtDlpJsonQuery -ExePath $yt.Source -Url $Url -WorkingText "Leyendo metadatos…" -TimeoutSec 60
    if ($obj.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($obj.StdOut)) { return $null }
    try { $json = $obj.StdOut | ConvertFrom-Json } catch { return $null }
    [pscustomobject]@{
        Title     = $json.title
        Extractor = $json.extractor
        Domain    = $json.webpage_url_domain
        Thumbnail = (Get-BestThumbnailUrl -Json $json)
        Duration  = $json.duration
        Uploader  = $json.uploader
        Json      = $json
    }
}

function Get-SelectedFormatId {
    param([System.Windows.Controls.ComboBox]$Combo)
    if (-not $Combo -or -not $Combo.SelectedItem) { return $null }
    $t = [string]$Combo.SelectedItem
    if ([string]::IsNullOrWhiteSpace($t)) { return $null }
    return ($t -split '\s')[0]
}

function Extract-VideoFromPlaylist {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $yt  = Get-Command yt-dlp -ErrorAction Stop
        $tmpArgs = @("--flat-playlist","--print","url","--no-warnings","--playlist-items","1")
        $tmpArgs += Get-JsRuntimeArgs
        $tmpArgs += Get-ActiveCookiesArgs

        $tmpArgs += $Url
        $res = Invoke-Capture -ExePath $yt.Source -Args $tmpArgs
        if ($res.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($res.StdOut)) {
            $first = ($res.StdOut -split "`r?`n" | Where-Object { $_ -match 'watch\?v=' } | Select-Object -First 1)
            if ($first) { return if ($first -match '^https?://') { $first.Trim() } else { "https://www.youtube.com/watch?v=$first" } }
        }
    } catch { Write-Host "[PLAYLIST] Error extrayendo video: $($_.Exception.Message)" -ForegroundColor Yellow }
    return $null
}

function Get-BestThumbnailUrl {
    param([Parameter(Mandatory=$true)]$Json)
    $candidate = $null
    if ($Json.thumbnail -and -not [string]::IsNullOrWhiteSpace($Json.thumbnail)) {
        $candidate = [string]$Json.thumbnail
    }
    if (-not $candidate -and $Json.thumbnails -and $Json.thumbnails.Count -gt 0) {
        $ordered = $Json.thumbnails | Sort-Object @{Expression='preference';Descending=$true}, @{Expression='width';Descending=$true}
        $noWebp  = $ordered | Where-Object { $_.url -and ($_.url -notmatch '\.webp($|\?)') } | Select-Object -First 1
        if ($noWebp -and $noWebp.url) { $candidate = [string]$noWebp.url }
        if (-not $candidate) {
            $first = $ordered | Select-Object -First 1
            if ($first -and $first.url) { $candidate = [string]$first.url }
        }
    }
    if ($candidate) { $candidate = Normalize-ThumbUrl -Url $candidate -Extractor $Json.extractor }
    return $candidate
}

function Normalize-ThumbUrl {
    param([Parameter(Mandatory=$true)][string]$Url, [string]$Extractor = $null)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $Url }
    return $Url.Trim()
}

function Get-BestStreamUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch { return $null }
    $args = @("-g","-f","best",$Url)
    $args += Get-JsRuntimeArgs

    $res = Invoke-Capture -ExePath $yt.Source -Args $args
    if ($res.ExitCode -ne 0) { return $null }
    return (($res.StdOut -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)).Trim()
}

function Get-TempThumbPattern {
    return (Join-Path ([System.IO.Path]::GetTempPath()) "ytdll_thumb_*")
}

function Get-ThumbnailListFromYtDlp {
    param([Parameter(Mandatory=$true)][string]$Url)
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch { return @() }
    $tmpArgs = @("--list-thumbnails")
    $tmpArgs += Get-JsRuntimeArgs

    $tmpArgs += $Url
    $res = Invoke-Capture -ExePath $yt.Source -Args $tmpArgs
    if ($res.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($res.StdOut)) { return @() }
    $lines = $res.StdOut -split "`r?`n"
    $startIndex = -1
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match '^\s*ID\s+Width\s+Height\s+URL') { $startIndex = $i + 1; break }
    }
    if ($startIndex -lt 0) { return @() }
    $thumbs = @()
    for ($i = $startIndex; $i -lt $lines.Length; $i++) {
        $line = $lines[$i].Trim(); if (-not $line) { continue }
        $m = [regex]::Match($line, '^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$')
        if (-not $m.Success) { continue }
        $url = $m.Groups[4].Value
        if ($url -match '\.webp($|\?)|vi_webp') { continue }
        if ($url -notmatch '\.jpg($|\?)')        { continue }
        $wInt = 0; $hInt = 0
        [void][int]::TryParse($m.Groups[2].Value,[ref]$wInt)
        [void][int]::TryParse($m.Groups[3].Value,[ref]$hInt)
        $thumbs += [pscustomobject]@{ Id=$m.Groups[1].Value; Width=$wInt; Height=$hInt; Url=$url }
    }
    return $thumbs
}

function Select-BestThumbnail {
    param([Parameter(Mandatory=$true)][array]$Thumbs)
    if (-not $Thumbs -or $Thumbs.Count -eq 0) { return $null }
    $ranked = $Thumbs | ForEach-Object {
        $w=$_.Width; $h=$_.Height; $area=[math]::Max($w*$h,1); $idNum=0
        [void][int]::TryParse($_.Id,[ref]$idNum)
        [pscustomobject]@{ Thumb=$_; Area=$area; IdNum=$idNum }
    }
    $best = $ranked | Sort-Object @{Expression="Area";Descending=$true}, @{Expression="IdNum";Descending=$true} | Select-Object -First 1
    return $best.Thumb
}

function Fetch-ThumbnailFile {
    param([Parameter(Mandatory=$true)][string]$Url)
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch { return $null }
    if (-not (Test-Path $script:ThumbnailsDir)) {
        New-Item -ItemType Directory -Path $script:ThumbnailsDir -Force | Out-Null
    }
    Get-ChildItem -Path (Get-TempThumbPattern) -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
    $outTmpl = Join-Path $script:ThumbnailsDir "ytdll_thumb_%(id)s.%(ext)s"
    $args = @("--skip-download","--quiet","--no-warnings","--write-thumbnail","--convert-thumbnails","jpg","-o",$outTmpl,"--no-playlist")
    $args += Get-JsRuntimeArgs
    $args += Get-ActiveCookiesArgs
    if ($Url -match 'youtube\.com.*list=') { $args += "--playlist-items","1" }

    $args += $Url
    $res = Invoke-Capture -ExePath $yt.Source -Args $args
    $thumb = Get-ChildItem -Path (Join-Path $script:ThumbnailsDir "ytdll_thumb_*") -ErrorAction SilentlyContinue |
             Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($thumb) { return $thumb.FullName }
    return $null
}

function Get-ImageFromUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    $cleanUrl = $Url -replace '\?.*$', ''
    try {
        Add-Type -AssemblyName System.Net.Http
        $handler    = New-Object System.Net.Http.HttpClientHandler
        $httpClient = New-Object System.Net.Http.HttpClient($handler)
        $httpClient.DefaultRequestHeaders.Add("User-Agent","Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36")
        $httpClient.DefaultRequestHeaders.Add("Accept","image/webp,image/apng,image/*,*/*;q=0.8")
        $httpClient.Timeout = [System.TimeSpan]::FromSeconds(10)
        $response = $httpClient.GetAsync($cleanUrl).Result
        if ($response.IsSuccessStatusCode) {
            $stream = $response.Content.ReadAsStreamAsync().Result
            $image  = [System.Drawing.Image]::FromStream($stream)
            $httpClient.Dispose()
            return $image
        }
        $httpClient.Dispose()
        return $null
    } catch {
        try { $httpClient.Dispose() } catch {}
        return $null
    }
}

function Get-ImageFromUrlFallback {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        $bytes    = $response.Content
        if ($bytes -and $bytes.Length -gt 0) {
            $ms = New-Object System.IO.MemoryStream(,$bytes)
            return [System.Drawing.Image]::FromStream($ms)
        }
        return $null
    } catch { return $null }
}

function Convert-WebpUrlToPng {
    param([Parameter(Mandatory=$true)][string]$Url)
    try { $ff = Get-Command ffmpeg -ErrorAction Stop | Select-Object -ExpandProperty Source } catch { return $null }
    $webClient = $null
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add('User-Agent','Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell-YTDLL')
        $bytes  = $webClient.DownloadData($Url)
        $tmpIn  = Join-Path ([IO.Path]::GetTempPath()) ("ytdll_webp_{0}.webp" -f ([guid]::NewGuid()))
        $tmpOut = [IO.Path]::ChangeExtension($tmpIn, ".png")
        [IO.File]::WriteAllBytes($tmpIn,$bytes)
        $p = Start-Process -FilePath $ff -ArgumentList @("-y","-hide_banner","-loglevel","error","-i",$tmpIn,$tmpOut) -NoNewWindow -PassThru
        $p.WaitForExit()
        if ($p.ExitCode -eq 0 -and (Test-Path $tmpOut)) { return $tmpOut }
        return $null
    } catch { return $null }
    finally {
        if ($webClient) { $webClient.Dispose() }
        try { if (Test-Path $tmpIn) { Remove-Item $tmpIn -Force } } catch {}
    }
}

function Build-PreviewFromStream {
    param([Parameter(Mandatory=$true)][string]$StreamUrl, [int]$SeekSec = 2)
    try { $ff = (Get-Command ffmpeg -ErrorAction Stop).Source } catch { return $null }
    $tmp  = Join-Path ([IO.Path]::GetTempPath()) ("ytdll_snap_{0}.jpg" -f ([guid]::NewGuid()))
    $args = @("-y","-hide_banner","-loglevel","error","-ss",$SeekSec.ToString(),"-i",$StreamUrl,"-frames:v","1","-vf","scale=1280:-2",$tmp)
    $env:FFREPORT = ""
    $p = Start-Process -FilePath $ff -ArgumentList $args -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -eq 0 -and (Test-Path $tmp)) { return $tmp }
    return $null
}

function Fetch-Formats {
    param([Parameter(Mandatory=$true)][string]$Url)
    $script:formatsIndex.Clear()
    $script:formatsVideo     = @()
    $script:formatsAudio     = @()
    $script:formatsEnumerated = $false
    $script:lastFormats       = $null
    $script:bestProgId        = $null
    $script:bestProgRank      = -1
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch {
        $lblEstadoConsulta.Text     = "ERROR: yt-dlp no disponible para listar formatos"
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Red
        return $false
    }
    $lblEstadoConsulta.Text     = "Obteniendo lista de formatos..."
    $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkBlue
    $obj = Invoke-YtDlpJsonQuery -ExePath $yt.Source -Url $Url -WorkingText "Obteniendo formatos" -TimeoutSec 60
    if (($obj.ExitCode -ne 0 -and $obj.ExitCode -ne $null) -or [string]::IsNullOrWhiteSpace($obj.StdOut)) {
        $lblEstadoConsulta.Text = "Reintentando obtención de formatos..."
        $obj = Invoke-YtDlpJsonQuery -ExePath $yt.Source -Url $Url -WorkingText "Reintentando formatos" -TimeoutSec 60
        if (($obj.ExitCode -ne 0 -and $obj.ExitCode -ne $null) -or [string]::IsNullOrWhiteSpace($obj.StdOut)) {
            $lblEstadoConsulta.Text     = "ERROR: No se pudieron obtener formatos"
            $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Red
            return $false
        }
    }
    try { $json = $obj.StdOut | ConvertFrom-Json } catch {
        $lblEstadoConsulta.Text     = "ERROR: Formato JSON inválido"
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Red
        return $false
    }
    $script:lastThumbUrl = Get-BestThumbnailUrl -Json $json
    if (-not $json.formats -or $json.formats.Count -eq 0) {
        $lblEstadoConsulta.Text     = "ADVERTENCIA: No se encontraron formatos"
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkOrange
        return $false
    }
    $script:lastFormats = $json.formats
    $lblEstadoConsulta.Text = "Clasificando y ordenando formatos..."
    $videoFormats = @(); $audioFormats = @()
    foreach ($f in $json.formats) {
        $klass = Classify-Format $f
        $script:formatsIndex[$klass.Id] = $klass
        $res   = if ($klass.VRes)  { "{0}p" -f $klass.VRes }                   else { "" }
        $sz    = Human-Size $klass.Filesize
        $tbrStr = if ($klass.Tbr) { "{0}k" -f [math]::Round($klass.Tbr) }     else { "" }
        if ($klass.Progressive -or $klass.VideoOnly) {
            $label = if ($klass.Progressive) {
                "{0} {1} {2} {3}/{4} {5} (progresivo)" -f $res,$sz,$klass.Ext,$klass.VCodec,$klass.ACodec,$tbrStr
            } else {
                "{0} {1} {2} {3} {4} (video-only)" -f $res,$sz,$klass.Ext,$klass.VCodec,$tbrStr
            }
            $videoFormats += [pscustomobject]@{ Display=(New-FormatDisplay -Id $klass.Id -Label $label); Height=$klass.VRes; Tbr=$klass.Tbr; IsProgressive=$klass.Progressive; Filesize=$klass.Filesize; Id=$klass.Id }
        } elseif ($klass.AudioOnly) {
            $label = "{0} {1} {2} ~{3}k (audio-only)" -f $sz,$klass.Ext,$klass.ACodec,[math]::Round($klass.ABr)
            $audioFormats += [pscustomobject]@{ Display=(New-FormatDisplay -Id $klass.Id -Label $label); ABr=$klass.ABr; Filesize=$klass.Filesize; Id=$klass.Id }
        }
    }
    $script:formatsVideo     = ($videoFormats | Sort-Object @{Expression={($_.Height*100000)+$_.Tbr};Descending=$true}).Display
    $script:formatsAudio     = ($audioFormats | Sort-Object @{Expression={$_.ABr};Descending=$true}).Display
    $script:formatsEnumerated = ($script:formatsVideo.Count -gt 0 -or $script:formatsAudio.Count -gt 0)
    if ($json.extractor) { $script:lastExtractor = $json.extractor }
    if ($script:formatsEnumerated) {
        $lblEstadoConsulta.Text     = "Formatos obtenidos y ordenados correctamente"
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkGreen
        Populate-FormatCombos
    } else {
        $lblEstadoConsulta.Text     = "ADVERTENCIA: No se pudieron enumerar formatos"
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkOrange
    }
    return $script:formatsEnumerated
}

function Populate-FormatCombos {
    if (-not $script:lastFormats) { return }
    if ($cmbVideoFmt) { $cmbVideoFmt.Items.Clear() }
    if ($cmbAudioFmt) { $cmbAudioFmt.Items.Clear() }
    $videoItems = @(); $audioItems = @()
    foreach ($fmt in $script:lastFormats) {
        $klass = Classify-Format $fmt
        if ($script:ExcludedFormatIds -contains $klass.Id) { continue }
        $res   = if ($klass.VRes) { "{0}p" -f $klass.VRes } else { "" }
        $sz    = Human-Size $klass.Filesize
        $tbrStr = if ($klass.Tbr) { "{0}k" -f [math]::Round($klass.Tbr) } else { "" }
        if ($klass.Progressive -or $klass.VideoOnly) {
            $label = if ($klass.Progressive) {
                "{0} {1} {2} {3}/{4} {5} (progresivo)" -f $res,$sz,$klass.Ext,$klass.VCodec,$klass.ACodec,$tbrStr
            } else {
                "{0} {1} {2} {3} {4} (video-only)" -f $res,$sz,$klass.Ext,$klass.VCodec,$tbrStr
            }
            $videoItems += [pscustomobject]@{ Display=(New-FormatDisplay -Id $klass.Id -Label $label); Height=$klass.VRes; Tbr=$klass.Tbr; IsProgressive=$klass.Progressive; Filesize=$klass.Filesize; Id=$klass.Id }
        } elseif ($klass.AudioOnly) {
            $label = "{0} {1} {2} ~{3}k (audio-only)" -f $sz,$klass.Ext,$klass.ACodec,[math]::Round($klass.ABr)
            $audioItems += [pscustomobject]@{ Display=(New-FormatDisplay -Id $klass.Id -Label $label); ABr=$klass.ABr; Filesize=$klass.Filesize; Id=$klass.Id }
        }
    }
    ($videoItems | Sort-Object @{Expression={($_.Height*100000)+$_.Tbr};Descending=$true}) | ForEach-Object { $cmbVideoFmt.Items.Add($_.Display) | Out-Null }
    ($audioItems | Sort-Object @{Expression={$_.ABr};Descending=$true})                    | ForEach-Object { $cmbAudioFmt.Items.Add($_.Display) | Out-Null }
    if ($cmbVideoFmt.Items.Count -gt 0) { $cmbVideoFmt.SelectedIndex = 0 }
    if ($cmbAudioFmt.Items.Count -gt 0) { $cmbAudioFmt.SelectedIndex = 0 }
}

function Invoke-ConsultaFromUI {
    param([Parameter(Mandatory=$true)][string]$Url)
    $Url = Normalize-InputUrl -Url $Url
    $script:originalUrl  = $Url
    $script:isPlaylist   = Test-YouTubePlaylist -Url $Url
    if ($txtUrl -and -not [string]::IsNullOrWhiteSpace($Url) -and $txtUrl.Text -ne $Url) {
        $txtUrl.Text = $Url
        $txtUrl.Foreground = [System.Windows.Media.Brushes]::Black
    }
    if ($script:isPlaylist) {
        $lblEstadoConsulta.Text     = "Playlist detectada, extrayendo primer video..."
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkOrange
        try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}
        $singleVideoUrl = Extract-VideoFromPlaylist -Url $Url
        if ($singleVideoUrl) { $Url = $singleVideoUrl; $txtUrl.Text = $singleVideoUrl; $txtUrl.Foreground = [System.Windows.Media.Brushes]::Black }
    }
    Write-Host ("`n`n[CONSULTA] Consultando URL: {0}" -f $Url) -ForegroundColor Cyan
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch {
        $lblEstadoConsulta.Text     = "ERROR: yt-dlp no disponible"
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Red
        [System.Windows.MessageBox]::Show("yt-dlp no está disponible en el PATH.","yt-dlp no encontrado",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
        return $false
    }
    $btnDescargar.IsEnabled = $false; $txtUrl.IsEnabled = $false
    if ($script:ultimaURL -ne $Url) { $script:videoConsultado = $false; $script:formatsEnumerated = $false }
    $lblEstadoConsulta.Text     = "Consultando video..."
    $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkBlue
    try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}
    $res = Invoke-YtDlpJsonQuery -ExePath $yt.Source -Url $Url -WorkingText "Consultando video" -TimeoutSec 60
    Write-DebugLog "[DEBUG] yt-dlp ExitCode: $($res.ExitCode)" -ForegroundColor Yellow
    if (-not [string]::IsNullOrWhiteSpace($res.StdErr)) {
        Write-DebugLog "[DEBUG] StdErr: $($res.StdErr)" -ForegroundColor Red
    }
    if ([string]::IsNullOrWhiteSpace($res.StdOut)) {
        Write-DebugLog "[DEBUG] StdOut está vacío o nulo" -ForegroundColor Red
    } elseif (($res.StdOut.Trim()) -eq "null") {
        Write-DebugLog "[DEBUG] StdOut contiene JSON literal null" -ForegroundColor Red
    }
    $metaJson = $null
    if (-not [string]::IsNullOrWhiteSpace($res.StdOut)) {
        try { $metaJson = $res.StdOut | ConvertFrom-Json } catch {
            Write-DebugLog "[DEBUG] JSON inválido en consulta: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    $hasValidData = ($null -ne $metaJson) -and (-not [string]::IsNullOrWhiteSpace($metaJson.title))
    if ($hasValidData) {
        $title    = $metaJson.title
        $thumbUrl = Get-BestThumbnailUrl -Json $metaJson
        $script:ultimaURL         = $Url
        $script:videoConsultado   = $true
        $script:ultimoTitulo      = $title
        $script:lastThumbUrl      = $thumbUrl
        $script:formatsEnumerated = $false
        $lblEstadoConsulta.Text     = "Consulta OK: `"$title`""
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkGreen
        $lblEstadoConsulta.Text     = "Cargando vista previa..."
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkBlue
        try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}
        Show-PreviewUniversal -Url $Url -Titulo $title -DirectThumbUrl $thumbUrl
        $lblEstadoConsulta.Text     = "Obteniendo formatos..."
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkBlue
        try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}
        $fmtOk = Fetch-Formats -Url $Url
        if ($fmtOk -and $script:lastFormats) { Print-FormatsTable -formats $script:lastFormats }
        $btnDescargar.IsEnabled = $true; $txtUrl.IsEnabled = $true
        Set-DownloadButtonVisual
        $lblEstadoConsulta.Text     = if ($fmtOk) { "Consulta completada - Listo para descargar" } else { "Consulta completada (sin formatos)" }
        $lblEstadoConsulta.Foreground = if ($fmtOk) { [System.Windows.Media.Brushes]::DarkGreen } else { [System.Windows.Media.Brushes]::DarkOrange }
        return $true
    } else {
        $script:videoConsultado = $false; $script:ultimaURL = $null; $script:ultimoTitulo = $null
        $script:formatsEnumerated = $false
        $picPreview.Source = $null
        $btnDescargar.IsEnabled = $true; $txtUrl.IsEnabled = $true

        $isYouTubeBot = $res.StdErr -match "Sign in to confirm" -or
                        $res.StdErr -match "not a bot" -or
                        $res.StdErr -match "Use --cookies"
        if ($isYouTubeBot) {
            $lblEstadoConsulta.Text     = "⚠ YouTube requiere autenticación — usa el botón 🍪"
            $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkOrange
            [System.Windows.MessageBox]::Show(
                "YouTube detectó actividad sospechosa y pide iniciar sesión.`n`n" +
                "Solución: haz clic en el botón 🍪 (arriba a la derecha) y elige tu navegador para extraer las cookies automáticamente.`n`n" +
                "Si ya tienes un archivo cookies.txt, selecciona '📁 Seleccionar archivo...'",
                "YouTube requiere cookies",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Warning
            ) | Out-Null
            Set-DownloadButtonVisual
            return $false
        }

        $lblEstadoConsulta.Text     = "Error al consultar la URL"
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Red
        $errorMsg = "yt-dlp devolvió error al consultar la URL."
        if (-not [string]::IsNullOrWhiteSpace($res.StdErr)) { $errorMsg += "`n`nError: $($res.StdErr)" }
        [System.Windows.MessageBox]::Show($errorMsg, "Error en consulta", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        Set-DownloadButtonVisual
        return $false
    }
}

function Get-QueueBool {
    param([string]$Value, [bool]$Default = $false)
    if ([string]::IsNullOrWhiteSpace($Value)) { return $Default }
    return ($Value -match '^(1|true|yes|si|sí)$')
}

function Ensure-QueueProperty {
    param($Item, [string]$Name, $DefaultValue)
    if (-not $Item.PSObject.Properties[$Name]) {
        $Item | Add-Member -MemberType NoteProperty -Name $Name -Value $DefaultValue
    }
}

function Initialize-QueueItemShape {
    param($Item)
    Ensure-QueueProperty -Item $Item -Name "Id" -DefaultValue ([guid]::NewGuid().ToString())
    Ensure-QueueProperty -Item $Item -Name "Url" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "Title" -DefaultValue "Video"
    Ensure-QueueProperty -Item $Item -Name "ThumbUrl" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "Destination" -DefaultValue $script:ultimaRutaDescarga
    Ensure-QueueProperty -Item $Item -Name "FormatSelector" -DefaultValue "bestvideo+bestaudio/best"
    Ensure-QueueProperty -Item $Item -Name "MergeExt" -DefaultValue "mp4"
    Ensure-QueueProperty -Item $Item -Name "VideoFormatId" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "AudioFormatId" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "VideoFormatLabel" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "AudioFormatLabel" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "SizeText" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "NoPlaylist" -DefaultValue $true
    Ensure-QueueProperty -Item $Item -Name "BestProgId" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "Status" -DefaultValue "Waiting"
    Ensure-QueueProperty -Item $Item -Name "Phase" -DefaultValue "En espera"
    Ensure-QueueProperty -Item $Item -Name "Percent" -DefaultValue 0
    Ensure-QueueProperty -Item $Item -Name "Speed" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "Eta" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "TargetPath" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "ExitCode" -DefaultValue $null
    Ensure-QueueProperty -Item $Item -Name "LastError" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "DebugLogPath" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "ArgsText" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "OutputTail" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "ErrorTail" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "CreatedAt" -DefaultValue ([DateTime]::Now.ToString("o"))
    Ensure-QueueProperty -Item $Item -Name "StartedAt" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "CompletedAt" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "StartRequested" -DefaultValue $false
    Ensure-QueueProperty -Item $Item -Name "CancelRequested" -DefaultValue $false
    Ensure-QueueProperty -Item $Item -Name "Process" -DefaultValue $null
    Ensure-QueueProperty -Item $Item -Name "StdoutPath" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "StderrPath" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "StdoutReader" -DefaultValue $null
    Ensure-QueueProperty -Item $Item -Name "StderrReader" -DefaultValue $null
    Ensure-QueueProperty -Item $Item -Name "StdoutStream" -DefaultValue $null
    Ensure-QueueProperty -Item $Item -Name "StderrStream" -DefaultValue $null
    Ensure-QueueProperty -Item $Item -Name "LastOutFragment" -DefaultValue ""
    Ensure-QueueProperty -Item $Item -Name "LastErrFragment" -DefaultValue ""
    if ($Item.Status -in @("Running","Canceling")) {
        $Item.Status = "Waiting"
        $Item.Phase = "En espera"
        $Item.Percent = 0
        $Item.StartRequested = $false
    }
    $Item.Process = $null
    $Item.StdoutReader = $null
    $Item.StderrReader = $null
    $Item.StdoutStream = $null
    $Item.StderrStream = $null
    $Item.CancelRequested = $false
    return $Item
}

function Load-DownloadQueue {
    if (-not $script:downloadQueue) {
        $script:downloadQueue = New-Object System.Collections.ArrayList
    }
    $script:downloadQueue.Clear()
    $raw = Get-IniValue -Section "queue" -Key "ItemsBase64" -DefaultValue ""
    if ([string]::IsNullOrWhiteSpace($raw)) { return }
    try {
        $json = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($raw))
        $items = @($json | ConvertFrom-Json)
        foreach ($item in $items) {
            if ($null -eq $item) { continue }
            [void]$script:downloadQueue.Add((Initialize-QueueItemShape -Item $item))
        }
    } catch {
        Write-Host "[QUEUE] No se pudo restaurar la cola guardada: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Save-DownloadQueue {
    if (-not $script:downloadQueue) { return }
    try {
        $items = @()
        foreach ($item in $script:downloadQueue) {
            $status = if ($item.Status -eq "Running") { "Waiting" } else { $item.Status }
            $percent = if ($status -eq "Completed") { 100 } else { [int]($item.Percent) }
            if ($status -eq "Waiting") { $percent = 0 }
            $items += [pscustomobject]@{
                Id               = $item.Id
                Url              = $item.Url
                Title            = $item.Title
                ThumbUrl         = $item.ThumbUrl
                Destination      = $item.Destination
                FormatSelector   = $item.FormatSelector
                MergeExt         = $item.MergeExt
                VideoFormatId    = $item.VideoFormatId
                AudioFormatId    = $item.AudioFormatId
                VideoFormatLabel = $item.VideoFormatLabel
                AudioFormatLabel = $item.AudioFormatLabel
                SizeText         = $item.SizeText
                NoPlaylist       = [bool]$item.NoPlaylist
                BestProgId       = $item.BestProgId
                Status           = $status
                Phase            = if ($status -eq "Completed") { "Completado" } else { "En espera" }
                Percent          = $percent
                Speed            = ""
                Eta              = ""
                TargetPath       = if ($status -eq "Completed") { $item.TargetPath } else { "" }
                ExitCode         = $item.ExitCode
                LastError        = $item.LastError
                DebugLogPath     = $item.DebugLogPath
                CreatedAt        = $item.CreatedAt
                StartedAt        = $item.StartedAt
                CompletedAt      = $item.CompletedAt
                StartRequested   = $false
            }
        }
        $json = if ($items.Count -gt 0) { $items | ConvertTo-Json -Compress -Depth 6 } else { "[]" }
        $b64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($json))
        Set-IniValue -Section "queue" -Key "ItemsBase64" -Value $b64
    } catch {
        Write-Host "[QUEUE] Error guardando cola: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Save-DownloadQueueSettings {
    Set-IniValue -Section "queue" -Key "AutoDownload" -Value ([string]$script:queueAutoDownload).ToLower()
    Set-IniValue -Section "queue" -Key "MaxConcurrent" -Value ([string]$script:queueMaxConcurrent)
    Set-IniValue -Section "queue" -Key "PanelExpanded" -Value ([string]$script:queuePanelExpanded).ToLower()
}

function Get-QueueMaxConcurrent {
    if (-not $cmbMaxConcurrent -or -not $cmbMaxConcurrent.SelectedItem) { return [int]$script:queueMaxConcurrent }
    $raw = $cmbMaxConcurrent.SelectedItem
    if ($raw -is [System.Windows.Controls.ComboBoxItem]) { $raw = $raw.Content }
    $value = 2
    if ([int]::TryParse([string]$raw, [ref]$value)) {
        return [Math]::Max(1, [Math]::Min(5, $value))
    }
    return 2
}

function Set-QueuePanelExpanded {
    param([bool]$Expanded, [switch]$SkipSave)
    $script:queuePanelExpanded = $Expanded
    if ($QueuePanel -and $queueColumn -and $btnQueueToggle -and $formPrincipal) {
        if ($Expanded) {
            $QueuePanel.Visibility = [System.Windows.Visibility]::Visible
            $queueColumn.Width = New-Object System.Windows.GridLength(420)
            $btnQueueToggle.Content = "«"
            $formPrincipal.Width = 920
        } else {
            $QueuePanel.Visibility = [System.Windows.Visibility]::Collapsed
            $queueColumn.Width = New-Object System.Windows.GridLength(0)
            $btnQueueToggle.Content = "»"
            $formPrincipal.Width = 500
        }
    }
    if (-not $SkipSave) { Save-DownloadQueueSettings }
}

function Get-QueueItemById {
    param([Parameter(Mandatory=$true)][string]$Id)
    if (-not $script:downloadQueue) { return $null }
    return ($script:downloadQueue | Where-Object { $_.Id -eq $Id } | Select-Object -First 1)
}

function Get-QueueFormatSelection {
    $videoSel = Get-SelectedFormatId -Combo $cmbVideoFmt
    $audioSel = Get-SelectedFormatId -Combo $cmbAudioFmt
    $hayFormatosAudio = ($script:formatsAudio -and $script:formatsAudio.Count -gt 0)
    $mergeExt = $null

    if ($videoSel -and $audioSel) {
        $selector = "{0}+{1}" -f $videoSel, $audioSel
        $mergeExt = "mp4"
    } elseif ($videoSel -and $hayFormatosAudio) {
        $selector = "{0}+bestaudio" -f $videoSel
        $mergeExt = "mp4"
    } elseif ($videoSel) {
        $selector = $videoSel
    } elseif ($audioSel) {
        $selector = $audioSel
    } else {
        if ($hayFormatosAudio) {
            $selector = "bestvideo+bestaudio/best"
            $mergeExt = "mp4"
        } else {
            $selector = "best"
        }
    }

    $size = 0
    foreach ($id in @($videoSel, $audioSel)) {
        if ($id -and $script:formatsIndex.ContainsKey($id) -and $script:formatsIndex[$id].Filesize) {
            $size += [double]$script:formatsIndex[$id].Filesize
        }
    }

    return [pscustomobject]@{
        Selector   = $selector
        MergeExt   = $mergeExt
        VideoId    = if ($videoSel) { $videoSel } else { "" }
        AudioId    = if ($audioSel) { $audioSel } else { "" }
        VideoLabel = if ($cmbVideoFmt -and $cmbVideoFmt.SelectedItem) { [string]$cmbVideoFmt.SelectedItem } else { "" }
        AudioLabel = if ($cmbAudioFmt -and $cmbAudioFmt.SelectedItem) { [string]$cmbAudioFmt.SelectedItem } else { "" }
        SizeText   = if ($size -gt 0) { Human-Size $size } else { "" }
    }
}

function Add-CurrentDownloadToQueue {
    Refresh-GateByDeps
    $currentUrl = Get-CurrentUrl
    $ready = $script:videoConsultado -and
             -not [string]::IsNullOrWhiteSpace($script:ultimaURL) -and
             ($script:ultimaURL -eq $currentUrl) -and
             $script:formatsEnumerated
    if (-not $ready) { return $false }

    $dest = $script:ultimaRutaDescarga
    if ([string]::IsNullOrWhiteSpace($dest)) {
        $dest = [Environment]::GetFolderPath('Desktop')
        $script:ultimaRutaDescarga = $dest
        try { $txtDestino.Text = $dest } catch {}
    }
    if (-not (Test-Path -LiteralPath $dest)) {
        try { New-Item -ItemType Directory -Path $dest -Force | Out-Null } catch {
            [System.Windows.MessageBox]::Show("No se pudo preparar la carpeta de destino.", "Error de destino", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            return $false
        }
    }

    $fmt = Get-QueueFormatSelection
    $noPlaylist = $false
    foreach ($u in @($script:originalUrl, $script:ultimaURL)) {
        if (-not [string]::IsNullOrWhiteSpace($u) -and (Test-YouTubePlaylist -Url $u)) {
            $noPlaylist = $true
            break
        }
    }

    $item = [pscustomobject]@{
        Id               = [guid]::NewGuid().ToString()
        Url              = $script:ultimaURL
        Title            = if ($script:ultimoTitulo) { $script:ultimoTitulo } else { "Video" }
        ThumbUrl         = if ($script:lastThumbUrl) { $script:lastThumbUrl } else { "" }
        Destination      = $dest
        FormatSelector   = $fmt.Selector
        MergeExt         = $fmt.MergeExt
        VideoFormatId    = $fmt.VideoId
        AudioFormatId    = $fmt.AudioId
        VideoFormatLabel = $fmt.VideoLabel
        AudioFormatLabel = $fmt.AudioLabel
        SizeText         = $fmt.SizeText
        NoPlaylist       = ($script:isPlaylist -or $noPlaylist)
        BestProgId       = if ($script:bestProgId) { $script:bestProgId } else { "" }
        Status           = "Waiting"
        Phase            = "En espera"
        Percent          = 0
        Speed            = ""
        Eta              = ""
        TargetPath       = ""
        ExitCode         = $null
        LastError        = ""
        DebugLogPath     = ""
        ArgsText         = ""
        OutputTail       = ""
        ErrorTail        = ""
        CreatedAt        = [DateTime]::Now.ToString("o")
        StartedAt        = ""
        CompletedAt      = ""
        StartRequested   = [bool]$script:queueAutoDownload
        CancelRequested  = $false
        Process          = $null
        StdoutPath       = ""
        StderrPath       = ""
        StdoutReader     = $null
        StderrReader     = $null
        StdoutStream     = $null
        StderrStream     = $null
        LastOutFragment  = ""
        LastErrFragment  = ""
    }
    if (-not $script:downloadQueue) { $script:downloadQueue = New-Object System.Collections.ArrayList }
    [void]$script:downloadQueue.Add($item)
    Add-HistoryUrl -Url $script:ultimaURL
    Save-DownloadQueue
    Set-QueuePanelExpanded -Expanded $true
    Refresh-QueuePanel
    Start-NextQueuedDownloads
    $lblEstadoConsulta.Text = if ($script:queueAutoDownload) { "Agregado a cola e iniciando..." } else { "Agregado a cola" }
    $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkGreen
    return $true
}

function New-QueueTargetPath {
    param($Item)
    $dest = if ([string]::IsNullOrWhiteSpace($Item.Destination)) { $script:ultimaRutaDescarga } else { $Item.Destination }
    if ([string]::IsNullOrWhiteSpace($dest)) { $dest = [Environment]::GetFolderPath('Desktop') }
    if (-not (Test-Path -LiteralPath $dest)) { New-Item -ItemType Directory -Path $dest -Force | Out-Null }

    $baseTitle = Get-SafeFileName -Name $Item.Title
    $finalExt = if ([string]::IsNullOrWhiteSpace($Item.MergeExt)) { "mp4" } else { $Item.MergeExt }
    $idx = 1
    do {
        $suffix = if ($idx -eq 1) { "" } else { "_$idx" }
        $candidate = Join-Path $dest ("{0}{1}.{2}" -f $baseTitle, $suffix, $finalExt)
        $reserved = @($script:downloadQueue | Where-Object {
            $_.Id -ne $Item.Id -and $_.TargetPath -and $_.TargetPath -eq $candidate -and $_.Status -in @("Running","Waiting")
        }).Count -gt 0
        $exists = Test-Path -LiteralPath $candidate
        $idx++
    } while ($exists -or $reserved)
    return $candidate
}

function Join-YtdllArgumentList {
    param([string[]]$ArgumentArray)
    return (($ArgumentArray | ForEach-Object {
        $s = [string]$_
        if ($s -match '[\s"]') { '"' + ($s -replace '"','\"') + '"' } else { $s }
    }) -join ' ')
}

function Get-QueueLogDirectory {
    $base = if ([string]::IsNullOrWhiteSpace($script:ConfigDir)) { "C:\Temp\ytdll" } else { $script:ConfigDir }
    $dir = Join-Path $base "queue_logs"
    if (-not (Test-Path -LiteralPath $dir)) {
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
    }
    return $dir
}

function New-QueueDebugLogPath {
    param($Item)
    $safe = Get-SafeFileName -Name $Item.Title
    if ($safe.Length -gt 36) { $safe = $safe.Substring(0,36).Trim() }
    $stamp = Get-Date -Format "yyyyMMdd_HHmmss"
    return (Join-Path (Get-QueueLogDirectory) ("{0}_{1}_{2}.log" -f $stamp, $safe, $Item.Id.Substring(0,8)))
}

function Write-QueueDebugLog {
    param(
        $Item,
        [string]$Text,
        [switch]$NoNewLine
    )
    if (-not $Item -or [string]::IsNullOrWhiteSpace($Item.DebugLogPath)) { return }
    try {
        if ($NoNewLine) {
            [System.IO.File]::AppendAllText($Item.DebugLogPath, $Text, [System.Text.Encoding]::UTF8)
        } else {
            [System.IO.File]::AppendAllText($Item.DebugLogPath, ($Text + [Environment]::NewLine), [System.Text.Encoding]::UTF8)
        }
    } catch {}
}

function Add-QueueTextTail {
    param(
        $Item,
        [string]$PropertyName,
        [string]$Text,
        [int]$MaxChars = 4000
    )
    if (-not $Item -or [string]::IsNullOrEmpty($Text)) { return }
    $value = [string]$Item.$PropertyName + $Text
    if ($value.Length -gt $MaxChars) {
        $value = $value.Substring($value.Length - $MaxChars)
    }
    $Item.$PropertyName = $value
}

function Get-QueueReadableError {
    param($Item)
    $raw = ""
    if ($Item -and -not [string]::IsNullOrWhiteSpace($Item.ErrorTail)) { $raw = $Item.ErrorTail }
    elseif ($Item -and -not [string]::IsNullOrWhiteSpace($Item.OutputTail)) { $raw = $Item.OutputTail }
    $lines = @($raw -split "\r\n|\n|\r" | ForEach-Object { $_.Trim() } | Where-Object { $_ })
    if ($lines.Count -eq 0) { return "" }
    $useful = @($lines | Where-Object {
        $_ -notmatch '^\[download\]' -and
        $_ -notmatch '^frame=' -and
        $_ -notmatch '^size='
    })
    if ($useful.Count -eq 0) { $useful = $lines }
    $tail = @($useful | Select-Object -Last 4)
    return ($tail -join " | ")
}

function Start-QueuedDownload {
    param($Item)
    if (-not $Item -or $Item.Status -eq "Running") { return $false }
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch {
        $Item.Status = "Failed"
        $Item.Phase = "yt-dlp no disponible"
        $Item.StartRequested = $false
        return $false
    }

    try {
        $targetPath = New-QueueTargetPath -Item $Item
        $Item.TargetPath = $targetPath
        $dlpArgs = @("--encoding","utf-8","--progress","--no-color","--newline","-f",$Item.FormatSelector)
        if ($global:DebugEnabled) { $dlpArgs += "--verbose" }
        if ($Item.NoPlaylist) { $dlpArgs += "--no-playlist" }
        if (-not [string]::IsNullOrWhiteSpace($Item.MergeExt)) {
            $dlpArgs += @("--merge-output-format", $Item.MergeExt)
        }
        $dlpArgs += @(
            "-o", $targetPath,
            "--progress-template", "download:%(progress._percent_str)s ETA:%(progress._eta_str)s SPEED:%(progress._speed_str)s"
        )
        $dlpArgs += Get-JsRuntimeArgs
        $dlpArgs += Get-ActiveCookiesArgs
        $dlpArgs += Get-YouTubeExtractorArgs -Url $Item.Url
        $dlpArgs += @("--no-part","--ignore-config", $Item.Url, "--retries","5","--retry-sleep","2","-N","4")

        $tmpDir = [System.IO.Path]::GetTempPath()
        $Item.StdoutPath = Join-Path $tmpDir ("ytdll-queue-out_{0}.log" -f $Item.Id)
        $Item.StderrPath = Join-Path $tmpDir ("ytdll-queue-err_{0}.log" -f $Item.Id)
        Remove-Item -LiteralPath $Item.StdoutPath, $Item.StderrPath -Force -ErrorAction SilentlyContinue

        $argLine = Join-YtdllArgumentList -ArgumentArray $dlpArgs
        $Item.DebugLogPath = New-QueueDebugLogPath -Item $Item
        $Item.ArgsText = "{0} {1}" -f $yt.Source, $argLine
        $Item.OutputTail = ""
        $Item.ErrorTail = ""
        $Item.LastError = ""
        Write-QueueDebugLog -Item $Item -Text ("YTDLL QUEUE DEBUG {0}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"))
        Write-QueueDebugLog -Item $Item -Text ("Title: {0}" -f $Item.Title)
        Write-QueueDebugLog -Item $Item -Text ("URL: {0}" -f $Item.Url)
        Write-QueueDebugLog -Item $Item -Text ("Target: {0}" -f $Item.TargetPath)
        Write-QueueDebugLog -Item $Item -Text ("Selector: {0} | MergeExt: {1}" -f $Item.FormatSelector, $Item.MergeExt)
        Write-QueueDebugLog -Item $Item -Text ("Command: {0}" -f $Item.ArgsText)
        Write-QueueDebugLog -Item $Item -Text ""
        Write-DebugLog ("[QUEUE][DEBUG] Comando: {0}" -f $Item.ArgsText) -ForegroundColor DarkGray
        Write-DebugLog ("[QUEUE][DEBUG] Log: {0}" -f $Item.DebugLogPath) -ForegroundColor DarkGray
        $proc = Start-Process -FilePath $yt.Source -ArgumentList $argLine -NoNewWindow -PassThru `
            -RedirectStandardOutput $Item.StdoutPath -RedirectStandardError $Item.StderrPath

        $Item.StdoutStream = [System.IO.File]::Open($Item.StdoutPath,[System.IO.FileMode]::OpenOrCreate,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
        $Item.StderrStream = [System.IO.File]::Open($Item.StderrPath,[System.IO.FileMode]::OpenOrCreate,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
        $Item.StdoutReader = New-Object System.IO.StreamReader($Item.StdoutStream)
        $Item.StderrReader = New-Object System.IO.StreamReader($Item.StderrStream)
        $Item.Process = $proc
        $Item.Status = "Running"
        $Item.Phase = "Preparando..."
        $Item.Percent = 0
        $Item.Speed = ""
        $Item.Eta = ""
        $Item.StartedAt = [DateTime]::Now.ToString("o")
        $Item.CompletedAt = ""
        $Item.ExitCode = $null
        $Item.StartRequested = $false
        $Item.CancelRequested = $false
        Write-Host ("[QUEUE] Iniciada descarga: {0}" -f $Item.Title) -ForegroundColor Cyan
        Save-DownloadQueue
        return $true
    } catch {
        Close-QueueProcessResources -Item $Item
        foreach ($logPath in @($Item.StdoutPath, $Item.StderrPath)) {
            if (-not [string]::IsNullOrWhiteSpace($logPath)) {
                Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
            }
        }
        $Item.Status = "Failed"
        $Item.Phase = "No se pudo iniciar"
        $Item.LastError = $_.Exception.Message
        $Item.StartRequested = $false
        Write-Host "[QUEUE] Error iniciando descarga: $($_.Exception.Message)" -ForegroundColor Red
        if ($Item.DebugLogPath) {
            Write-QueueDebugLog -Item $Item -Text ("START ERROR: {0}" -f $_.Exception.Message)
            Write-Host ("[QUEUE] Log de diagnostico: {0}" -f $Item.DebugLogPath) -ForegroundColor Yellow
        }
        Save-DownloadQueue
        return $false
    }
}

function Update-QueueProgressFromLine {
    param($Item, [string]$Text)
    if ([string]::IsNullOrWhiteSpace($Text)) { return }
    if ($Text -match 'Sleeping\s+(\d+(?:\.\d+)?)\s+seconds') { $Item.Phase = "Esperando $($Matches[1])s"; return }
    if ($Text -match '^\[download\]\s+Destination:') { $Item.Phase = "Descargando"; return }
    if ($Text -match '^\[Merger\]\s+Merging formats') { $Item.Phase = "Fusionando"; return }
    if ($Text -match '^Deleting original file') { $Item.Phase = "Borrando temporales"; return }
    if ($Text -match '^\[(ExtractAudio|Fixup|EmbedSubtitle|ModifyChapters)\]') { $Item.Phase = "Post-procesando"; return }

    $m = [regex]::Match($Text, 'download:\s*(?<pct>\d+(?:\.\d+)?)%\s*(?:ETA:(?<eta>\S+))?\s*(?:SPEED:(?<spd>.+))?', 'IgnoreCase')
    if (-not $m.Success) { $m = [regex]::Match($Text, '(?<pct>\d+(?:\.\d+)?)%\s+of.*?at\s+(?<spd>\S+)\s+ETA\s+(?<eta>\S+)', 'IgnoreCase') }
    if (-not $m.Success) { $m = [regex]::Match($Text, '(?<pct>\d+(?:\.\d+)?)%') }
    if ($m.Success) {
        $Item.Percent = [int][math]::Min(100,[math]::Round([double]$m.Groups['pct'].Value))
        $Item.Eta = $m.Groups['eta'].Value
        $Item.Speed = ($m.Groups['spd'].Value).Trim()
        if ([string]::IsNullOrWhiteSpace($Item.Phase) -or $Item.Phase -eq "Preparando...") { $Item.Phase = "Descargando" }
    }
}

function Read-QueueProcessOutput {
    param($Item)
    foreach ($kind in @("Out","Err")) {
        $readerProp = if ($kind -eq "Out") { "StdoutReader" } else { "StderrReader" }
        $fragProp = if ($kind -eq "Out") { "LastOutFragment" } else { "LastErrFragment" }
        $reader = $Item.$readerProp
        if (-not $reader) { continue }
        $chunk = $reader.ReadToEnd()
        if ([string]::IsNullOrEmpty($chunk)) { continue }
        if ($kind -eq "Out") {
            Add-QueueTextTail -Item $Item -PropertyName "OutputTail" -Text $chunk
            Write-QueueDebugLog -Item $Item -Text $chunk -NoNewLine
        } else {
            Add-QueueTextTail -Item $Item -PropertyName "ErrorTail" -Text $chunk
            Write-QueueDebugLog -Item $Item -Text $chunk -NoNewLine
        }
        $text = [string]$Item.$fragProp + $chunk
        $parts = [regex]::Split($text, "\r\n|\n|\r")
        for ($i = 0; $i -lt $parts.Length - 1; $i++) {
            Update-QueueProgressFromLine -Item $Item -Text $parts[$i]
        }
        $Item.$fragProp = $parts[$parts.Length - 1]
    }
}

function Close-QueueProcessResources {
    param($Item)
    try { if ($Item.StdoutReader) { $Item.StdoutReader.Close() } } catch {}
    try { if ($Item.StderrReader) { $Item.StderrReader.Close() } } catch {}
    try { if ($Item.StdoutStream) { $Item.StdoutStream.Close() } } catch {}
    try { if ($Item.StderrStream) { $Item.StderrStream.Close() } } catch {}
    try { if ($Item.Process) { $Item.Process.Dispose() } } catch {}
    $Item.StdoutReader = $null
    $Item.StderrReader = $null
    $Item.StdoutStream = $null
    $Item.StderrStream = $null
    $Item.Process = $null
}

function Complete-QueuedDownload {
    param($Item)
    Read-QueueProcessOutput -Item $Item
    foreach ($fragment in @($Item.LastOutFragment, $Item.LastErrFragment)) {
        if (-not [string]::IsNullOrWhiteSpace($fragment)) {
            Update-QueueProgressFromLine -Item $Item -Text $fragment
        }
    }
    $Item.LastOutFragment = ""
    $Item.LastErrFragment = ""
    $exit = $null
    try {
        $procObj = $Item.Process
        if ($procObj -is [System.Management.Automation.PSObject]) { $procObj = $procObj.BaseObject }
        if ($procObj) {
            $procObj.Refresh()
            if (-not $procObj.HasExited) { [void]$procObj.WaitForExit(1000) }
            $exit = $procObj.ExitCode
        }
    } catch {}
    $Item.ExitCode = $exit
    Close-QueueProcessResources -Item $Item

    if ($Item.CancelRequested) {
        $Item.Status = "Cancelled"
        $Item.Phase = "Cancelada"
        $Item.Percent = 0
        $Item.StartRequested = $false
        if ($Item.TargetPath) { Remove-Item -LiteralPath $Item.TargetPath -Force -ErrorAction SilentlyContinue }
        Write-Host ("[QUEUE] Cancelada: {0}" -f $Item.Title) -ForegroundColor Yellow
    } elseif ($exit -eq 0 -or ($Item.TargetPath -and (Test-Path -LiteralPath $Item.TargetPath))) {
        $Item.Status = "Completed"
        $Item.Phase = "Completado"
        $Item.Percent = 100
        $Item.Speed = ""
        $Item.Eta = ""
        $Item.CompletedAt = [DateTime]::Now.ToString("o")
        $oldTitle = $script:ultimoTitulo
        try {
            $script:ultimoTitulo = $Item.Title
            Add-HistoryUrl -Url $Item.Url
        } finally {
            $script:ultimoTitulo = $oldTitle
        }
        Write-Host ("[QUEUE] Completada: {0}" -f $Item.Title) -ForegroundColor Green
    } else {
        $Item.Status = "Failed"
        $Item.LastError = Get-QueueReadableError -Item $Item
        if ([string]::IsNullOrWhiteSpace($Item.LastError)) { $Item.LastError = "yt-dlp termino con ExitCode=$exit" }
        $Item.Phase = "Error: $($Item.LastError)"
        $Item.StartRequested = $false
        if ($Item.TargetPath) { Remove-Item -LiteralPath $Item.TargetPath -Force -ErrorAction SilentlyContinue }
        Write-Host ("[QUEUE] Error: {0} ExitCode={1}" -f $Item.Title, $exit) -ForegroundColor Red
        Write-Host ("[QUEUE] Detalle: {0}" -f $Item.LastError) -ForegroundColor Red
        if ($Item.DebugLogPath) {
            Write-Host ("[QUEUE] Log de diagnostico: {0}" -f $Item.DebugLogPath) -ForegroundColor Yellow
            Write-QueueDebugLog -Item $Item -Text ""
            Write-QueueDebugLog -Item $Item -Text ("ExitCode: {0}" -f $exit)
            Write-QueueDebugLog -Item $Item -Text ("ReadableError: {0}" -f $Item.LastError)
        }
    }
    foreach ($logPath in @($Item.StdoutPath, $Item.StderrPath)) {
        if (-not [string]::IsNullOrWhiteSpace($logPath)) {
            Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
        }
    }
    Save-DownloadQueue
}

function Monitor-ActiveDownloads {
    if (-not $script:downloadQueue) { return }
    foreach ($item in @($script:downloadQueue | Where-Object { $_.Status -eq "Running" })) {
        Read-QueueProcessOutput -Item $item
        if ($item.Process -and $item.Process.HasExited) {
            Complete-QueuedDownload -Item $item
        }
    }
}

function Start-NextQueuedDownloads {
    if (-not $script:downloadQueue) { return }
    $max = [int]$script:queueMaxConcurrent
    if ($max -lt 1) { $max = 1 }
    while (@($script:downloadQueue | Where-Object { $_.Status -eq "Running" }).Count -lt $max) {
        $next = ($script:downloadQueue | Where-Object {
            $_.Status -eq "Waiting" -and $_.StartRequested
        } | Select-Object -First 1)
        if (-not $next) { break }
        [void](Start-QueuedDownload -Item $next)
        if ($next.Status -ne "Running") { break }
    }
    Refresh-QueuePanel
}

function Request-QueueItemStart {
    param([Parameter(Mandatory=$true)][string]$Id)
    $item = Get-QueueItemById -Id $Id
    if (-not $item) { return }
    if ($item.Status -eq "Running") { return }
    if ($item.Status -in @("Failed","Cancelled")) {
        $item.Status = "Waiting"
        $item.Phase = "En espera"
        $item.Percent = 0
        $item.Speed = ""
        $item.Eta = ""
        $item.TargetPath = ""
    }
    $item.StartRequested = $true
    Save-DownloadQueue
    Start-NextQueuedDownloads
    Refresh-QueuePanel
}

function Cancel-QueueItem {
    param([Parameter(Mandatory=$true)][string]$Id)
    $item = Get-QueueItemById -Id $Id
    if (-not $item) { return }
    if ($item.Status -eq "Running") {
        $item.CancelRequested = $true
        $item.StartRequested = $false
        $item.Phase = "Cancelando"
        try {
            if ($item.Process -and -not $item.Process.HasExited) { $item.Process.Kill() }
        } catch {}
    } else {
        [void]$script:downloadQueue.Remove($item)
    }
    Save-DownloadQueue
    Refresh-QueuePanel
}

function Remove-QueueItem {
    param([Parameter(Mandatory=$true)][string]$Id)
    $item = Get-QueueItemById -Id $Id
    if (-not $item) { return }
    if ($item.Status -eq "Running") { Cancel-QueueItem -Id $Id; return }
    [void]$script:downloadQueue.Remove($item)
    Save-DownloadQueue
    Refresh-QueuePanel
}

function Clear-CompletedQueueItems {
    if (-not $script:downloadQueue) { return }
    foreach ($item in @($script:downloadQueue | Where-Object { $_.Status -eq "Completed" })) {
        [void]$script:downloadQueue.Remove($item)
    }
    Save-DownloadQueue
    Refresh-QueuePanel
}

function Add-QueuePlaceholder {
    param($Panel, [string]$Text)
    if (-not $Panel) { return }
    $tb = New-Object System.Windows.Controls.TextBlock
    $tb.Text = $Text
    $tb.FontSize = 12
    $tb.Foreground = [System.Windows.Media.Brushes]::Gray
    $tb.Margin = New-Object System.Windows.Thickness(0,0,0,8)
    [void]$Panel.Children.Add($tb)
}

function Get-QueueStatusLabel {
    param($Item)
    switch ($Item.Status) {
        "Running" { return $Item.Phase }
        "Completed" { return "Completado" }
        "Failed" { return "Error" }
        "Cancelled" { return "Cancelada" }
        default { if ($Item.StartRequested) { return "En cola" } else { return "En espera" } }
    }
}

function New-QueueItemCard {
    param($Item)
    $title = [System.Security.SecurityElement]::Escape([string]$Item.Title)
    $status = [System.Security.SecurityElement]::Escape((Get-QueueStatusLabel -Item $Item))
    if ($Item.Status -eq "Failed" -and -not [string]::IsNullOrWhiteSpace($Item.LastError)) {
        $shortError = [string]$Item.LastError
        if ($shortError.Length -gt 120) { $shortError = $shortError.Substring(0,120).Trim() + "..." }
        $status = [System.Security.SecurityElement]::Escape("Error: $shortError")
    }
    $format = if ($Item.SizeText) { $Item.SizeText } else { $Item.FormatSelector }
    if ($Item.VideoFormatId) { $format = ("{0}  Video {1}" -f $format, $Item.VideoFormatId).Trim() }
    if ($Item.AudioFormatId) { $format = ("{0}  Audio {1}" -f $format, $Item.AudioFormatId).Trim() }
    $format = [System.Security.SecurityElement]::Escape($format)
    $pct = [int][math]::Max(0,[math]::Min(100,[int]$Item.Percent))
    $speed = if ($Item.Speed) { [System.Security.SecurityElement]::Escape([string]$Item.Speed) } else { "" }
    $progressVis = if ($Item.Status -in @("Running","Completed")) { "Visible" } else { "Collapsed" }
    $playVis = if ($Item.Status -in @("Waiting","Failed","Cancelled")) { "Visible" } else { "Collapsed" }
    $cancelVis = if ($Item.Status -in @("Running","Waiting","Failed","Cancelled")) { "Visible" } else { "Collapsed" }
    $deleteVis = if ($Item.Status -eq "Completed") { "Visible" } else { "Collapsed" }
    $statusColor = switch ($Item.Status) {
        "Completed" { "#34C759" }
        "Failed" { "#FF3B30" }
        "Cancelled" { "#FF9500" }
        default { "#34C759" }
    }

    [xml]$xamlCard = @"
<Border xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Background="White" BorderBrush="#D1D1D6" BorderThickness="1" CornerRadius="8"
        Padding="10" Margin="0,0,0,8">
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="*"/>
            <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Grid.Row="0" Grid.Column="0" Margin="0,0,10,0">
            <TextBlock Text="$title" FontWeight="SemiBold" FontSize="12.5" TextWrapping="Wrap"/>
            <TextBlock Text="$format" FontSize="11" Foreground="#86868B" TextWrapping="Wrap"/>
        </StackPanel>
        <StackPanel Grid.Row="0" Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
            <Button Name="btnPlay" Content="▶" Width="28" Height="28" Margin="0,0,4,0"
                    Visibility="$playVis" ToolTip="Iniciar"/>
            <Button Name="btnCancel" Content="×" Width="28" Height="28" Margin="0,0,4,0"
                    Visibility="$cancelVis" ToolTip="Cancelar o quitar"/>
            <Button Name="btnDelete" Content="🗑" Width="28" Height="28"
                    Visibility="$deleteVis" ToolTip="Quitar de completadas"/>
        </StackPanel>
        <Grid Grid.Row="1" Grid.ColumnSpan="2" Margin="0,8,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Text="$status" FontSize="11" Foreground="$statusColor" TextWrapping="Wrap"/>
            <TextBlock Grid.Column="1" Text="$speed" FontSize="11" Foreground="#1D1D1F"/>
        </Grid>
        <ProgressBar Grid.Row="2" Grid.ColumnSpan="2" Height="6" Margin="0,6,0,0"
                     Minimum="0" Maximum="100" Value="$pct" Visibility="$progressVis"/>
    </Grid>
</Border>
"@
    $reader = New-Object System.Xml.XmlNodeReader $xamlCard
    $card = [System.Windows.Markup.XamlReader]::Load($reader)
    foreach ($name in @("btnPlay","btnCancel","btnDelete")) {
        $button = $card.FindName($name)
        if ($button) { $button.Tag = $Item.Id }
    }
    $play = $card.FindName("btnPlay")
    if ($play) { $play.Add_Click({ param($s,$e) Request-QueueItemStart -Id ([string]$s.Tag) }) }
    $cancel = $card.FindName("btnCancel")
    if ($cancel) { $cancel.Add_Click({ param($s,$e) Cancel-QueueItem -Id ([string]$s.Tag) }) }
    $delete = $card.FindName("btnDelete")
    if ($delete) { $delete.Add_Click({ param($s,$e) Remove-QueueItem -Id ([string]$s.Tag) }) }
    return $card
}

function Refresh-QueuePanel {
    if (-not $spActiveDownloads -or -not $spWaitingDownloads -or -not $spCompletedDownloads) { return }
    $spActiveDownloads.Children.Clear()
    $spWaitingDownloads.Children.Clear()
    $spCompletedDownloads.Children.Clear()
    if (-not $script:downloadQueue) { $script:downloadQueue = New-Object System.Collections.ArrayList }

    $active = @($script:downloadQueue | Where-Object { $_.Status -eq "Running" })
    $waiting = @($script:downloadQueue | Where-Object { $_.Status -in @("Waiting","Failed","Cancelled") })
    $completed = @($script:downloadQueue | Where-Object { $_.Status -eq "Completed" })

    if ($lblActiveHeader) { $lblActiveHeader.Text = "En progreso ($($active.Count))" }
    if ($lblWaitingHeader) { $lblWaitingHeader.Text = "En espera ($($waiting.Count))" }
    if ($lblCompletedHeader) { $lblCompletedHeader.Text = "Completadas ($($completed.Count))" }
    if ($txtQueueSummary) {
        $txtQueueSummary.Text = ("{0} activas / {1} espera" -f $active.Count, $waiting.Count)
    }

    if ($active.Count -eq 0) { Add-QueuePlaceholder -Panel $spActiveDownloads -Text "Sin descargas activas" }
    else { foreach ($item in $active) { [void]$spActiveDownloads.Children.Add((New-QueueItemCard -Item $item)) } }

    if ($waiting.Count -eq 0) { Add-QueuePlaceholder -Panel $spWaitingDownloads -Text "Sin elementos en espera" }
    else { foreach ($item in $waiting) { [void]$spWaitingDownloads.Children.Add((New-QueueItemCard -Item $item)) } }

    if ($completed.Count -eq 0) { Add-QueuePlaceholder -Panel $spCompletedDownloads -Text "Sin descargas completadas" }
    else { foreach ($item in $completed) { [void]$spCompletedDownloads.Children.Add((New-QueueItemCard -Item $item)) } }
}

function Invoke-QueueTick {
    Monitor-ActiveDownloads
    Start-NextQueuedDownloads
    Refresh-QueuePanel
}

function Stop-AllActiveQueueDownloads {
    if (-not $script:downloadQueue) { return }
    foreach ($item in @($script:downloadQueue | Where-Object { $_.Status -eq "Running" })) {
        $item.CancelRequested = $true
        try {
            if ($item.Process -and -not $item.Process.HasExited) { $item.Process.Kill() }
        } catch {}
        Close-QueueProcessResources -Item $item
        if ($item.TargetPath) { Remove-Item -LiteralPath $item.TargetPath -Force -ErrorAction SilentlyContinue }
        foreach ($logPath in @($item.StdoutPath, $item.StderrPath)) {
            if (-not [string]::IsNullOrWhiteSpace($logPath)) {
                Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue
            }
        }
        $item.Status = "Waiting"
        $item.Phase = "En espera"
        $item.Percent = 0
        $item.Speed = ""
        $item.Eta = ""
        $item.TargetPath = ""
        $item.StartRequested = $false
        $item.CancelRequested = $false
    }
    Save-DownloadQueue
}

function Initialize-DownloadQueueUi {
    if (-not $script:downloadQueue) { $script:downloadQueue = New-Object System.Collections.ArrayList }
    $script:queueAutoDownload = Get-QueueBool -Value (Get-IniValue -Section "queue" -Key "AutoDownload" -DefaultValue "true") -Default $true
    $script:queueMaxConcurrent = 2
    [void][int]::TryParse((Get-IniValue -Section "queue" -Key "MaxConcurrent" -DefaultValue "2"), [ref]$script:queueMaxConcurrent)
    $script:queueMaxConcurrent = [Math]::Max(1, [Math]::Min(5, [int]$script:queueMaxConcurrent))
    $script:queuePanelExpanded = Get-QueueBool -Value (Get-IniValue -Section "queue" -Key "PanelExpanded" -DefaultValue "false") -Default $false

    Load-DownloadQueue

    if ($chkAutoDownload) { $chkAutoDownload.IsChecked = [bool]$script:queueAutoDownload }
    if ($cmbMaxConcurrent) { $cmbMaxConcurrent.SelectedIndex = $script:queueMaxConcurrent - 1 }
    Set-QueuePanelExpanded -Expanded ([bool]$script:queuePanelExpanded) -SkipSave
    Refresh-QueuePanel

    if ($btnQueueToggle) {
        $btnQueueToggle.Add_Click({ Set-QueuePanelExpanded -Expanded (-not [bool]$script:queuePanelExpanded) })
    }
    if ($chkAutoDownload) {
        $chkAutoDownload.Add_Checked({
            $script:queueAutoDownload = $true
            Save-DownloadQueueSettings
        })
        $chkAutoDownload.Add_Unchecked({
            $script:queueAutoDownload = $false
            Save-DownloadQueueSettings
        })
    }
    if ($cmbMaxConcurrent) {
        $cmbMaxConcurrent.Add_SelectionChanged({
            $script:queueMaxConcurrent = Get-QueueMaxConcurrent
            Save-DownloadQueueSettings
            Start-NextQueuedDownloads
        })
    }
    if ($btnStartQueue) {
        $btnStartQueue.Add_Click({
            foreach ($item in @($script:downloadQueue | Where-Object { $_.Status -eq "Waiting" })) {
                $item.StartRequested = $true
            }
            Save-DownloadQueue
            Start-NextQueuedDownloads
            Refresh-QueuePanel
        })
    }
    if ($btnClearCompleted) {
        $btnClearCompleted.Add_Click({ Clear-CompletedQueueItems })
    }
    if ($formPrincipal) {
        $formPrincipal.Add_Closing({
            try { if ($script:queueTimer) { $script:queueTimer.Stop() } } catch {}
            Stop-AllActiveQueueDownloads
        })
    }

    $script:queueTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:queueTimer.Interval = [TimeSpan]::FromMilliseconds(500)
    $script:queueTimer.Add_Tick({ Invoke-QueueTick })
    $script:queueTimer.Start()
}

function Export-BrowserCookies {
    param([string]$Browser)
    Write-Host "[COOKIES] === Iniciando extraccion de cookies: $Browser ===" -ForegroundColor Cyan
    Write-DebugLog "[DEBUG] Export-BrowserCookies: Browser='$Browser'" -ForegroundColor Cyan

    try { $yt = Get-Command yt-dlp -ErrorAction Stop }
    catch {
        Write-Host "[COOKIES] ERROR: yt-dlp no disponible" -ForegroundColor Red
        [System.Windows.MessageBox]::Show("yt-dlp no esta disponible.","Error",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error) | Out-Null
        return $null
    }
    Write-DebugLog "[DEBUG] yt-dlp: $($yt.Source)" -ForegroundColor DarkGray

    $tmpCookie = Join-Path $env:TEMP "ytdll_cookies_$Browser.txt"
    Write-DebugLog "[DEBUG] Ruta cookies: $tmpCookie" -ForegroundColor DarkGray
    if (Test-Path $tmpCookie) {
        Write-DebugLog "[DEBUG] Eliminando cookies previas..." -ForegroundColor DarkGray
        Remove-Item $tmpCookie -Force -ErrorAction SilentlyContinue
    }

    $perfiles = @{
        "chrome"  = "$env:LOCALAPPDATA\Google\Chrome\User Data"
        "brave"   = "$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data"
        "firefox" = "$env:APPDATA\Mozilla\Firefox\Profiles"
        "edge"    = "$env:LOCALAPPDATA\Microsoft\Edge\User Data"
        "opera"   = "$env:APPDATA\Opera Software\Opera Stable"
        "vivaldi" = "$env:LOCALAPPDATA\Vivaldi\User Data"
    }
    if ($perfiles.ContainsKey($Browser)) {
        $perfil = $perfiles[$Browser]
        Write-DebugLog "[DEBUG] Perfil esperado en: $perfil" -ForegroundColor DarkGray
        if (Test-Path $perfil) {
            Write-DebugLog "[DEBUG] Perfil de $Browser ENCONTRADO" -ForegroundColor Green
        } else {
            Write-Host "[COOKIES] ADVERTENCIA: Perfil de $Browser no encontrado en $perfil" -ForegroundColor Yellow
        }
    }

    $procName = @{ "chrome"="chrome"; "brave"="brave"; "firefox"="firefox"; "edge"="msedge"; "opera"="opera"; "vivaldi"="vivaldi" }
    if ($procName.ContainsKey($Browser)) {
        $running = Get-Process -Name $procName[$Browser] -ErrorAction SilentlyContinue
        if ($running) {
            Write-Host "[COOKIES] ADVERTENCIA: $Browser tiene $($running.Count) proceso(s) corriendo. Puede fallar la extraccion." -ForegroundColor Yellow
            Write-DebugLog "[DEBUG] PIDs de $Browser`: $($running.Id -join ', ')" -ForegroundColor Yellow
        } else {
            Write-DebugLog "[DEBUG] $Browser no tiene procesos activos. OK para extraer cookies." -ForegroundColor Green
        }
    }

    $lblEstadoConsulta.Text     = "Extrayendo cookies de $Browser..."
    $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkBlue
    try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}

    $cookieArgs = @(
        "--cookies-from-browser", $Browser,
        "--cookies", $tmpCookie,
        "--extractor-args", "youtubetab:skip=authcheck",
        "--ignore-config", "--no-warnings",
        "https://www.youtube.com/robots.txt"
    )
    Write-Host "[COOKIES] Comando: yt-dlp $($cookieArgs -join ' ')" -ForegroundColor DarkCyan

    $res = Invoke-CaptureResponsive -ExePath $yt.Source -Args $cookieArgs `
               -WorkingText "Extrayendo cookies de $Browser" -TimeoutSec 180

    Write-Host "[COOKIES] ExitCode: $($res.ExitCode)" -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($res.StdOut)) {
        Write-DebugLog "[DEBUG] StdOut: $($res.StdOut)" -ForegroundColor DarkGray
    }
    if (-not [string]::IsNullOrWhiteSpace($res.StdErr)) {
        Write-Host "[COOKIES] StdErr: $($res.StdErr)" -ForegroundColor Yellow
    }

    $existe = Test-Path $tmpCookie
    $tamano = if ($existe) { (Get-Item $tmpCookie).Length } else { 0 }
    $cookieFileReady = $existe -and $tamano -ge 50
    $reportedExtraction = (-not [string]::IsNullOrWhiteSpace($res.StdOut)) -and ($res.StdOut -match "Extracted \d+ cookies from")
    Write-DebugLog "[DEBUG] Archivo existe: $existe | Tamano: $tamano bytes" -ForegroundColor DarkGray

    if ((-not $cookieFileReady) -or (($res.ExitCode -ne 0) -and (-not $reportedExtraction))) {
        $lblEstadoConsulta.Text     = "ERROR: No se pudieron extraer cookies de $Browser"
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Red
        $isDpapiFailure = (-not [string]::IsNullOrWhiteSpace($res.StdErr)) -and (
            $res.StdErr -match "Failed to decrypt with DPAPI" -or
            $res.StdErr -match "'NoneType' object has no attribute 'decode'"
        )

        $detail = if ($res.ExitCode -eq -1) {
            "Tiempo de espera agotado (180s). Cierra $Browser completamente y reintenta."
        } elseif ($isDpapiFailure) {
            "yt-dlp no pudo descifrar las cookies con DPAPI. Esto coincide con un problema conocido de Chrome/Chromium en Windows."
        } elseif (-not $existe) {
            "yt-dlp termino sin crear el archivo. Error: $($res.StdErr)"
        } elseif ($tamano -lt 50) {
            "Archivo de cookies creado pero vacio ($tamano bytes). Error: $($res.StdErr)"
        } else {
            $res.StdErr
        }

        Write-Host "[COOKIES] FALLO: $detail" -ForegroundColor Red
        if ($isDpapiFailure) {
            [System.Windows.MessageBox]::Show(
                "No se pudieron extraer las cookies de $Browser.`n`n" +
                "Diagnostico:`n$detail`n`n" +
                "Opciones recomendadas:`n" +
                "  1. Usa Firefox o un navegador que si permita exportar cookies en este equipo`n" +
                "  2. Exporta un archivo cookies.txt con una extension del navegador y luego cargalo desde el boton de cookies`n" +
                "  3. Desactiva Application Bound Encryption y reinstala Chrome solo si entiendes el impacto de seguridad`n`n" +
                "Nota: ese tercer workaround reduce la proteccion contra robo de cookies y borra la sesion actual del navegador.",
                "Error DPAPI al extraer cookies de $Browser",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
        } else {
            [System.Windows.MessageBox]::Show(
                "No se pudieron extraer las cookies de $Browser.`n`n" +
                "Pasos para solucionar:`n" +
                "  1. Cierra $Browser completamente`n" +
                "     (incluyendo procesos en segundo plano / bandeja del sistema)`n" +
                "  2. Asegurate de haber iniciado sesion en YouTube en $Browser`n" +
                "  3. Vuelve a intentarlo`n`n" +
                "Diagnostico:`n$detail",
                "Error al extraer cookies de $Browser",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Error
            ) | Out-Null
        }
        return $null
    }
    if ($res.ExitCode -ne 0) {
        Write-Host "[COOKIES] AVISO: yt-dlp devolvio ExitCode $($res.ExitCode), pero el archivo de cookies quedo listo. Se continuara con ese archivo." -ForegroundColor Yellow
    }

    Write-Host "[COOKIES] Exito: $tmpCookie ($tamano bytes)" -ForegroundColor Green
    $lblEstadoConsulta.Text     = "Cookies de $Browser listas ($tamano bytes)"
    $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkGreen
    return $tmpCookie
}

