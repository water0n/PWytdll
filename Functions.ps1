<#
.SYNOPSIS
    YTDLL — Módulo de Funciones
    Lógica de negocio: configuración, historial, formatos de video/audio,
    miniaturas, invocación de procesos externos (yt-dlp, ffmpeg).

    Compatible con PowerShell 5.x
    Cargado mediante dot-sourcing desde Main.ps1

    NOTA DE ACOPLAMIENTO:
    Algunas funciones (Invoke-CaptureResponsive, Invoke-YtDlpConsoleProgress,
    Fetch-Formats, Populate-FormatCombos, Invoke-ConsultaFromUI, etc.) acceden
    a controles de la GUI ($lblEstadoConsulta, $cmbVideoFmt, etc.) a través del
    scope compartido que genera el dot-sourcing.  Estas variables deben existir
    antes de que esas funciones sean *llamadas* (no cuando son definidas).
#>

# ═══════════════════════════════════════════════════════════════════════════════
#  CONFIGURACIÓN  (config.ini)
# ═══════════════════════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════════════════════
#  LOGGING / DEBUG
# ═══════════════════════════════════════════════════════════════════════════════

function Write-DebugLog {
    param([string]$Message, [string]$ForegroundColor = "Yellow")
    if ($script:DebugEnabled) { Write-Host $Message -ForegroundColor $ForegroundColor }
}

# ═══════════════════════════════════════════════════════════════════════════════
#  UTILIDADES DE CADENAS Y ARCHIVOS
# ═══════════════════════════════════════════════════════════════════════════════

function Get-CleanUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    $u = $Url -replace '^https?://', ''
    $u = $u -replace '^www\.', ''
    $u = $u -replace '/+$', ''
    return $u.Trim()
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

# ═══════════════════════════════════════════════════════════════════════════════
#  HISTORIAL DE URLs
# ═══════════════════════════════════════════════════════════════════════════════

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
    [System.Windows.Forms.Application]::DoEvents()

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

# ═══════════════════════════════════════════════════════════════════════════════
#  FORMATOS DE VIDEO/AUDIO
# ═══════════════════════════════════════════════════════════════════════════════

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

# ═══════════════════════════════════════════════════════════════════════════════
#  DETECCIÓN DE URL / VIDEO ID
# ═══════════════════════════════════════════════════════════════════════════════

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
    # Nota: referencia $txtUrl (control GUI, accesible por scope compartido)
    if (-not $txtUrl) { return "" }
    $t = ($txtUrl.Text).Trim()
    if ($t -eq $global:UrlPlaceholder) { return "" }
    return $t
}

# ═══════════════════════════════════════════════════════════════════════════════
#  INVOCACIÓN DE PROCESOS EXTERNOS
# ═══════════════════════════════════════════════════════════════════════════════

function Invoke-Capture {
    <#
    .SYNOPSIS Ejecuta un proceso y captura stdout/stderr. Retorna @{ExitCode; StdOut; StdErr}. #>
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
    <#
    .SYNOPSIS
        Igual que Invoke-Capture pero mantiene la GUI responsiva (DoEvents) durante la espera.
        Actualiza $lblEstadoConsulta con puntos de progreso (scope compartido con GUI).
    #>
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [string[]]$Args       = @(),
        [string]$WorkingText  = "Procesando...",
        [int]$TimeoutSec      = 120
    )
    $prevBtnState = $null
    if ($btnConsultar)       { $prevBtnState = $btnConsultar.Enabled; $btnConsultar.Enabled = $false }
    if ($lblEstadoConsulta)  { $lblEstadoConsulta.Text = $WorkingText }

    $tmpDir  = [System.IO.Path]::GetTempPath()
    $outFile = Join-Path $tmpDir ("proc_stdout_{0}.log" -f ([guid]::NewGuid()))
    $errFile = Join-Path $tmpDir ("proc_stderr_{0}.log" -f ([guid]::NewGuid()))
    $argLine = ($Args | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } }) -join ' '
    $proc    = Start-Process -FilePath $ExePath -ArgumentList $argLine `
                 -NoNewWindow -PassThru `
                 -RedirectStandardOutput $outFile `
                 -RedirectStandardError  $errFile
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $dot = 0
    try {
        while (-not $proc.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            $dot = ($dot + 1) % 4
            if ($lblEstadoConsulta) { $lblEstadoConsulta.Text = $WorkingText + ("." * $dot) }
            if ($sw.Elapsed.TotalSeconds -ge $TimeoutSec) {
                try { $proc.Kill() } catch {}
                throw "Tiempo de espera agotado ($TimeoutSec s) en '$WorkingText'."
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
    <#
    .SYNOPSIS Invoca yt-dlp de forma asíncrona y retorna stdout/stderr completos al terminar. #>
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
    <#
    .SYNOPSIS
        Ejecuta yt-dlp mostrando el progreso en consola y actualizando la GUI en tiempo real.
        Referencia $lblEstadoConsulta por scope compartido.
    #>
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
            [System.Windows.Forms.Application]::DoEvents()
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

# ═══════════════════════════════════════════════════════════════════════════════
#  METADATOS Y FORMATOS
# ═══════════════════════════════════════════════════════════════════════════════

function Get-Metadata {
    param([Parameter(Mandatory=$true)][string]$Url)
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch { return $null }
    $obj = Invoke-CaptureResponsive -ExePath $yt.Source -Args @("-J","--no-playlist",$Url) -WorkingText "Leyendo metadatos…"
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
    param([System.Windows.Forms.ComboBox]$Combo)
    if (-not $Combo -or -not $Combo.SelectedItem) { return $null }
    $t = [string]$Combo.SelectedItem
    if ([string]::IsNullOrWhiteSpace($t)) { return $null }
    return ($t -split '\s')[0]
}

function Extract-VideoFromPlaylist {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $yt  = Get-Command yt-dlp -ErrorAction Stop
        $res = Invoke-Capture -ExePath $yt.Source -Args @("--flat-playlist","--print","url","--no-warnings","--playlist-items","1",$Url)
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
    if ($script:cookiesPath) { $args += @("--cookies",$script:cookiesPath) }
    $res = Invoke-Capture -ExePath $yt.Source -Args $args
    if ($res.ExitCode -ne 0) { return $null }
    return (($res.StdOut -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)).Trim()
}

# ═══════════════════════════════════════════════════════════════════════════════
#  MINIATURAS
# ═══════════════════════════════════════════════════════════════════════════════

function Get-TempThumbPattern {
    return (Join-Path ([System.IO.Path]::GetTempPath()) "ytdll_thumb_*")
}

function Get-ThumbnailListFromYtDlp {
    param([Parameter(Mandatory=$true)][string]$Url)
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch { return @() }
    $res = Invoke-Capture -ExePath $yt.Source -Args @("--list-thumbnails",$Url)
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
    if ($Url -match 'youtube\.com.*list=') { $args += "--playlist-items","1" }
    if ($script:cookiesPath)              { $args += @("--cookies",$script:cookiesPath) }
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

# ═══════════════════════════════════════════════════════════════════════════════
#  OPERACIONES MIXTAS GUI + LÓGICA
#  Estas funciones actualizan controles GUI (lblEstadoConsulta, cmbVideoFmt, etc.)
#  a través del scope compartido. Deben llamarse después de que GUI.ps1 haya
#  construido los controles.
# ═══════════════════════════════════════════════════════════════════════════════

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
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
        return $false
    }
    $lblEstadoConsulta.Text     = "Obteniendo lista de formatos..."
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
    $args1 = @("-J","--no-playlist","--ignore-config","--no-warnings",$Url)
    $obj   = Invoke-CaptureResponsive -ExePath $yt.Source -Args $args1 -WorkingText "Obteniendo formatos" -TimeoutSec 30
    if (($obj.ExitCode -ne 0 -and $obj.ExitCode -ne $null) -or [string]::IsNullOrWhiteSpace($obj.StdOut)) {
        $lblEstadoConsulta.Text = "Reintentando obtención de formatos..."
        $obj = Invoke-CaptureResponsive -ExePath $yt.Source -Args $args1 -WorkingText "Reintentando formatos" -TimeoutSec 30
        if (($obj.ExitCode -ne 0 -and $obj.ExitCode -ne $null) -or [string]::IsNullOrWhiteSpace($obj.StdOut)) {
            $lblEstadoConsulta.Text     = "ERROR: No se pudieron obtener formatos"
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
            return $false
        }
    }
    try { $json = $obj.StdOut | ConvertFrom-Json } catch {
        $lblEstadoConsulta.Text     = "ERROR: Formato JSON inválido"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
        return $false
    }
    $script:lastThumbUrl = Get-BestThumbnailUrl -Json $json
    if (-not $json.formats -or $json.formats.Count -eq 0) {
        $lblEstadoConsulta.Text     = "ADVERTENCIA: No se encontraron formatos"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
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
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
        Populate-FormatCombos
    } else {
        $lblEstadoConsulta.Text     = "ADVERTENCIA: No se pudieron enumerar formatos"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
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
    $script:originalUrl  = $Url
    $script:isPlaylist   = Test-YouTubePlaylist -Url $Url
    if ($script:isPlaylist) {
        $lblEstadoConsulta.Text     = "Playlist detectada, extrayendo primer video..."
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
        [System.Windows.Forms.Application]::DoEvents()
        $singleVideoUrl = Extract-VideoFromPlaylist -Url $Url
        if ($singleVideoUrl) { $Url = $singleVideoUrl; $txtUrl.Text = $singleVideoUrl; $txtUrl.ForeColor = [System.Drawing.Color]::Black }
    }
    Write-Host ("`n`n[CONSULTA] Consultando URL: {0}" -f $Url) -ForegroundColor Cyan
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch {
        $lblEstadoConsulta.Text     = "ERROR: yt-dlp no disponible"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show("yt-dlp no está disponible en el PATH.","yt-dlp no encontrado",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return $false
    }
    $btnDescargar.Enabled = $false; $txtUrl.Enabled = $false
    if ($script:ultimaURL -ne $Url) { $script:videoConsultado = $false; $script:formatsEnumerated = $false }
    $args = @("--no-playlist","--no-warnings","--ignore-config","--print","title","--print","thumbnail","--print","id",$Url)
    $lblEstadoConsulta.Text     = "Consultando video..."
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
    [System.Windows.Forms.Application]::DoEvents()
    $res   = Invoke-CaptureResponsive -ExePath $yt.Source -Args $args -WorkingText "Consultando video" -TimeoutSec 30
    $lines = @()
    if (-not [string]::IsNullOrWhiteSpace($res.StdOut)) {
        $lines = $res.StdOut -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
    }
    $hasValidData = ($lines.Count -ge 3) -and (-not [string]::IsNullOrWhiteSpace($lines[0]))
    if ($res.ExitCode -eq 0 -or $hasValidData) {
        $title    = if ($lines.Count -gt 0) { $lines[0] } else { "Título no disponible" }
        $thumbUrl = if ($lines.Count -gt 1) { $lines[1] } else { $null }
        $script:videoConsultado   = $true
        $script:ultimaURL         = $Url
        $script:ultimoTitulo      = $title
        $script:lastThumbUrl      = $thumbUrl
        $script:formatsEnumerated = $false
        $lblEstadoConsulta.Text     = "Consulta OK: `"$title`""
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
        $lblEstadoConsulta.Text     = "Cargando vista previa..."
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
        [System.Windows.Forms.Application]::DoEvents()
        Show-PreviewUniversal -Url $Url -Titulo $title -DirectThumbUrl $thumbUrl
        $lblEstadoConsulta.Text     = "Obteniendo formatos..."
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
        [System.Windows.Forms.Application]::DoEvents()
        $fmtOk = Fetch-Formats -Url $Url
        if ($fmtOk -and $script:lastFormats) { Print-FormatsTable -formats $script:lastFormats }
        $btnDescargar.Enabled = $true; $txtUrl.Enabled = $true
        Set-DownloadButtonVisual
        $lblEstadoConsulta.Text     = if ($fmtOk) { "Consulta completada - Listo para descargar" } else { "Consulta completada (sin formatos)" }
        $lblEstadoConsulta.ForeColor = if ($fmtOk) { [System.Drawing.Color]::DarkGreen } else { [System.Drawing.Color]::DarkOrange }
        return $true
    } else {
        $script:videoConsultado = $false; $script:ultimaURL = $null; $script:ultimoTitulo = $null
        $script:formatsEnumerated = $false
        $lblEstadoConsulta.Text     = "Error al consultar la URL"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
        $picPreview.Image = $null
        $btnDescargar.Enabled = $true; $txtUrl.Enabled = $true
        $errorMsg = "yt-dlp devolvió error al consultar la URL."
        if (-not [string]::IsNullOrWhiteSpace($res.StdErr)) { $errorMsg += "`n`nError: $($res.StdErr)" }
        [System.Windows.Forms.MessageBox]::Show($errorMsg,"Error en consulta",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        Set-DownloadButtonVisual
        return $false
    }
}
