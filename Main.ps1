<#
.SYNOPSIS
    YTDLL — Punto de entrada principal
    Inicializa rutas, encoding, variables de estado y carga los módulos en orden:
        1. Dependencies.ps1  — instalar/verificar herramientas externas
        2. Functions.ps1     — lógica de negocio y utilidades
        3. GUI.ps1           — construcción de la interfaz gráfica

    Compatible con PowerShell 5.x

.EXAMPLE
    powershell.exe -ExecutionPolicy Bypass -File ".\Main.ps1"
#>

# ═══════════════════════════════════════════════════════════════════════════════
#  RUTAS Y DIRECTORIOS
# ═══════════════════════════════════════════════════════════════════════════════
if (!(Test-Path -Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
    Write-Host "Carpeta 'C:\Temp' creada correctamente."
}
$iconDir = "C:\Temp\icos"
if (-not (Test-Path $iconDir)) {
    New-Item -ItemType Directory -Path $iconDir -Force | Out-Null
}

$script:LogFile       = "C:\Temp\ytdll\ytdll_history.txt"
$script:ThumbnailsDir = "C:\Temp\ytdll\miniaturas"
$script:ConfigDir     = "C:\Temp\ytdll"
$script:ConfigFile    = "C:\Temp\ytdll\config.ini"

if (-not (Test-Path -LiteralPath $script:LogFile)) {
    New-Item -ItemType File -Path $script:LogFile -Force | Out-Null
}

# ═══════════════════════════════════════════════════════════════════════════════
#  VERSIÓN
# ═══════════════════════════════════════════════════════════════════════════════
$version = "beta 251215.1225"

# ═══════════════════════════════════════════════════════════════════════════════
#  ENCODING UTF-8
# ═══════════════════════════════════════════════════════════════════════════════
try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
} catch {}
$OutputEncoding       = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = 'utf-8'
chcp 65001 | Out-Null
$env:PYTHONUTF8       = '1'
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSStyle.OutputRendering = 'Ansi'
}

# ═══════════════════════════════════════════════════════════════════════════════
#  TEXTO DE CHANGELOG (usado en Show-AppInfo)
# ═══════════════════════════════════════════════════════════════════════════════
$global:defaultInstructions = @"
----- CAMBIOS -----
- Se agrega ini para guardar configuraciones, nuevas rutas para URLS y miniaturas.
- Rediseño y agregar opción de previsualizar.
- Ahora ya guarda un log con URLS consultadas.
- Se agrea funcionalidad para ver y buscar sitios compatibles.
- Soporte para VODS de twitch / vista previa.
- Se agregó botón ? para información de sistema.
- Ahora ya solo existe 1 botón para consultar y descargar.
- Ahora se debe tener una carpeta preconfigurada de destino, por omisión se usa el Escritorio.
- Ahora permite que selecciones los formatos para video y audio.
- Se agrega la opción para actualizar y desinstalar dependencias.
- Se agregó vista previa del video.
- Se agregó detalles de progreso de descarga en consola.
- Se agregó dependencia Node.
- Se agregó validar consulta de video para descargar.
"@

# ═══════════════════════════════════════════════════════════════════════════════
#  CARGAR MÓDULOS (dot-source — comparten el scope del llamador)
# ═══════════════════════════════════════════════════════════════════════════════
. "$PSScriptRoot\Dependencies.ps1"
. "$PSScriptRoot\Functions.ps1"

# ═══════════════════════════════════════════════════════════════════════════════
#  CONFIGURACIÓN DE LA APLICACIÓN
#  (debe ir ANTES de GUI.ps1 porque algunos controles leen estas variables)
# ═══════════════════════════════════════════════════════════════════════════════

# ── Debug desde config.ini ─────────────────────────────────────────────────────
$script:DebugEnabled = [bool]::Parse((Get-IniValue -Section "DEBUG" -Key "ConsoleDebug" -DefaultValue "false"))

# ── Feature flags ─────────────────────────────────────────────────────────────
$script:RequireNode = $true   # Cambiar a $false para no exigir Node.js

# ── Estado compartido de formatos ─────────────────────────────────────────────
$script:formatsIndex      = @{}
$script:formatsVideo      = @()
$script:formatsAudio      = @()
$script:ExcludedFormatIds = @('18','22','95','96')
$script:bestProgId        = $null
$script:bestProgRank      = -1

# ── Estado de sesión ──────────────────────────────────────────────────────────
$script:videoConsultado   = $false
$script:ultimaURL         = $null
$script:ultimoTitulo      = $null
$script:lastThumbUrl      = $null
$script:formatsEnumerated = $false
$script:cookiesPath       = $null
$script:cookiesBrowser    = $null
$script:ultimaRutaDescarga = Get-IniValue -Section "ruta" -Key "Destino" -DefaultValue ([Environment]::GetFolderPath('Desktop'))
$global:UrlPlaceholder    = "BUSCAR VIDEO"

# ── Variables de proceso de yt-dlp ────────────────────────────────────────────
$script:lastYtDlpExitCode = $null
$script:lastPct           = -1
$script:lastLineSig       = $null
$script:hlsDurationSec    = $null
$script:lastFormats       = $null
$script:lastExtractor     = $null
$script:isPlaylist        = $false
$script:originalUrl       = $null

# ═══════════════════════════════════════════════════════════════════════════════
#  VERIFICAR E INSTALAR DEPENDENCIAS (antes de mostrar la GUI)
# ═══════════════════════════════════════════════════════════════════════════════
if (-not (Initialize-AppHeadless)) {
    Write-Host "[EXIT] No se pudo inicializar el entorno. Saliendo." -ForegroundColor Red
    return
}

# ── Detección rápida de mpvnet (para uso posterior en GUI) ────────────────────
$mpvnetInstalled = Test-CommandExists -Name "mpvnet"
if ($mpvnetInstalled) {
    $mpvnetVersion = Get-ToolVersion -Command "mpvnet" -ArgsForVersion "--version" -Parse "FirstLine"
}

# ═══════════════════════════════════════════════════════════════════════════════
#  CARGAR GUI
#  GUI.ps1 ejecuta código de nivel superior: crea $formPrincipal y todos los
#  controles como variables accesibles en este scope.
# ═══════════════════════════════════════════════════════════════════════════════
. "$PSScriptRoot\GUI.ps1"

# ═══════════════════════════════════════════════════════════════════════════════
#  BANNER EN CONSOLA
# ═══════════════════════════════════════════════════════════════════════════════
Write-Host "`n=============================================" -ForegroundColor DarkCyan
Write-Host "                   YTDLL                     " -ForegroundColor Green
Write-Host ("              Versión: v{0}" -f $version)    -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor DarkCyan

# ═══════════════════════════════════════════════════════════════════════════════
#  EVENTOS DE BOTONES
# ═══════════════════════════════════════════════════════════════════════════════

# ── Cookies ───────────────────────────────────────────────────────────────────
$btnPickCookies.Add_Click({
    $ctxCookies = $formPrincipal.FindName("ctxCookies")
    $ctxCookies.IsOpen = $true
})

$formPrincipal.FindName("miCookieEdge").add_Click({
    $res = Export-BrowserCookies -Browser "edge"
    if ($res) {
        $script:cookiesPath = $res
        $script:cookiesBrowser = $null
        Set-IniValue -Section "cookies" -Key "Browser" -Value "edge"
        Set-IniValue -Section "cookies" -Key "Path" -Value $res
        [System.Windows.MessageBox]::Show("Cookies extraÃ­das de Edge exitosamente.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})
$formPrincipal.FindName("miCookieChrome").add_Click({
    $res = Export-BrowserCookies -Browser "chrome"
    if ($res) {
        $script:cookiesPath = $res
        $script:cookiesBrowser = $null
        Set-IniValue -Section "cookies" -Key "Browser" -Value "chrome"
        Set-IniValue -Section "cookies" -Key "Path" -Value $res
        [System.Windows.MessageBox]::Show("Cookies extraÃ­das de Chrome exitosamente.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})
$formPrincipal.FindName("miCookieFirefox").add_Click({
    $res = Export-BrowserCookies -Browser "firefox"
    if ($res) {
        $script:cookiesPath = $res
        $script:cookiesBrowser = $null
        Set-IniValue -Section "cookies" -Key "Browser" -Value "firefox"
        Set-IniValue -Section "cookies" -Key "Path" -Value $res
        [System.Windows.MessageBox]::Show("Cookies extraÃ­das de Firefox exitosamente.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})
$formPrincipal.FindName("miCookieBrave").add_Click({
    $res = Export-BrowserCookies -Browser "brave"
    if ($res) {
        $script:cookiesPath = $res
        $script:cookiesBrowser = $null
        Set-IniValue -Section "cookies" -Key "Browser" -Value "brave"
        Set-IniValue -Section "cookies" -Key "Path" -Value $res
        [System.Windows.MessageBox]::Show("Cookies extraÃ­das de Brave exitosamente.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})
$formPrincipal.FindName("miCookieOpera").add_Click({
    $res = Export-BrowserCookies -Browser "opera"
    if ($res) {
        $script:cookiesPath = $res
        $script:cookiesBrowser = $null
        Set-IniValue -Section "cookies" -Key "Browser" -Value "opera"
        Set-IniValue -Section "cookies" -Key "Path" -Value $res
        [System.Windows.MessageBox]::Show("Cookies extraÃ­das de Opera exitosamente.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})
$formPrincipal.FindName("miCookieVivaldi").add_Click({
    $res = Export-BrowserCookies -Browser "vivaldi"
    if ($res) {
        $script:cookiesPath = $res
        $script:cookiesBrowser = $null
        Set-IniValue -Section "cookies" -Key "Browser" -Value "vivaldi"
        Set-IniValue -Section "cookies" -Key "Path" -Value $res
        [System.Windows.MessageBox]::Show("Cookies extraÃ­das de Vivaldi exitosamente.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})

$formPrincipal.FindName("miCookieFile").add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Title  = "Selecciona cookies.txt"
    $ofd.Filter = "Cookies (*.txt)|*.txt|Todos (*.*)|*.*"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:cookiesPath = $ofd.FileName
        $script:cookiesBrowser = $null
        [System.Windows.MessageBox]::Show("Cookies configuradas archivo: $($script:cookiesPath)", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
    }
})

# ── Carpeta de destino ────────────────────────────────────────────────────────
$btnPickDestino.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description  = "Selecciona la carpeta de descarga"
    $fbd.SelectedPath = if ([string]::IsNullOrWhiteSpace($script:ultimaRutaDescarga)) {
        [Environment]::GetFolderPath('Desktop')
    } else { $script:ultimaRutaDescarga }
    if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:ultimaRutaDescarga = $fbd.SelectedPath
        $txtDestino.Text = $script:ultimaRutaDescarga
        Set-IniValue -Section "ruta" -Key "Destino" -Value $script:ultimaRutaDescarga
        Write-Host ("[DESTINO] Carpeta configurada: {0}" -f $script:ultimaRutaDescarga) -ForegroundColor Cyan
    }
})

# ── Sitios compatibles ────────────────────────────────────────────────────────
$btnSites.Add_Click({ Show-SitesDialog })

# ── Info / Dependencias ───────────────────────────────────────────────────────
$btnInfo.Add_Click({ Show-AppInfo })

# ── Salir ─────────────────────────────────────────────────────────────────────
$btnExit.Add_Click({
    Write-Host "[EXIT] Cerrando aplicación por solicitud del usuario." -ForegroundColor Yellow
    $formPrincipal.Close()
})

# ── Consultar / Descargar ─────────────────────────────────────────────────────
$btnDescargar.Add_Click({
    Refresh-GateByDeps
    $currentUrl  = Get-CurrentUrl
    $noPlaylistArg = @()
    if ($script:isPlaylist -or (Test-YouTubePlaylist -Url $currentUrl)) {
        $noPlaylistArg = @("--no-playlist")
        Write-Host "[DESCARGA] Forzando --no-playlist" -ForegroundColor Yellow
    }
    $ready = $script:videoConsultado -and
             -not [string]::IsNullOrWhiteSpace($script:ultimaURL) -and
             ($script:ultimaURL -eq $currentUrl)

    if (-not $ready) {
        if ([string]::IsNullOrWhiteSpace($currentUrl)) {
            $lblEstadoConsulta.Text     = "ERROR: Escribe una URL"
            $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Red
            [System.Windows.MessageBox]::Show("Escribe una URL de YouTube.", "Falta URL", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
            Invoke-ConsultaFromUI -Url $currentUrl
            return
        }
        $lblEstadoConsulta.Text     = "Iniciando consulta..."
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkBlue
        $ok = Invoke-ConsultaFromUI -Url $currentUrl
        if ($ok) {
            Set-DownloadButtonVisual
            [System.Windows.MessageBox]::Show("Consulta lista. Revisa formatos y vuelve a presionar Descargar para iniciar la descarga.", "Consulta completada", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        } else { Set-DownloadButtonVisual }
        return
    }

    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch {
        [System.Windows.MessageBox]::Show("yt-dlp no está disponible. Valídalo en Dependencias.", "yt-dlp no encontrado", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        return
    }

    $dest = $script:ultimaRutaDescarga
    if ([string]::IsNullOrWhiteSpace($dest)) {
        $dest = [Environment]::GetFolderPath('Desktop')
        $script:ultimaRutaDescarga = $dest
        try { $txtDestino.Text = $dest } catch {}
    }
    if (-not (Test-Path -LiteralPath $dest)) {
        try { New-Item -ItemType Directory -Path $dest -Force | Out-Null } catch {
            [System.Windows.MessageBox]::Show("No se pudo preparar la carpeta de destino.", "Error de destino", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            return
        }
    }

    # ── Selección de formato ───────────────────────────────────────────────────
    $videoSel        = Get-SelectedFormatId -Combo $cmbVideoFmt
    $audioSel        = Get-SelectedFormatId -Combo $cmbAudioFmt
    $hayFormatosAudio = ($script:formatsAudio -and $script:formatsAudio.Count -gt 0)

    if ($videoSel -and $audioSel) {
        $fSelector = "{0}+{1}" -f $videoSel, $audioSel; $mergeExt = "mp4"
    } elseif ($videoSel -and $hayFormatosAudio) {
        $fSelector = "{0}+bestaudio" -f $videoSel;       $mergeExt = "mp4"
    } elseif ($videoSel) {
        $fSelector = $videoSel;                           $mergeExt = $null
    } elseif ($audioSel) {
        $fSelector = $audioSel;                           $mergeExt = $null
    } else {
        if ($hayFormatosAudio) { $fSelector = "bestvideo+bestaudio/best"; $mergeExt = "mp4" }
        else                   { $fSelector = "best";                      $mergeExt = $null }
    }
    Write-DebugLog "[DEBUG] Selector: $fSelector | MergeExt: $mergeExt" -ForegroundColor Yellow

    # ── Nombre del archivo ─────────────────────────────────────────────────────
    $prevPickDest = $btnPickDestino.IsEnabled; $prevCmbVid = $cmbVideoFmt.IsEnabled; $prevCmbAud = $cmbAudioFmt.IsEnabled
    $btnPickDestino.IsEnabled = $false; $cmbVideoFmt.IsEnabled = $false; $cmbAudioFmt.IsEnabled = $false
    $lblEstadoConsulta.Text = "Preparando descarga…"

    $baseTitle = if ($script:ultimoTitulo) { $script:ultimoTitulo } else {
        $vid = Get-YouTubeVideoId -Url $script:ultimaURL
        if ($vid) { "video_$vid" } else { "video" }
    }
    $baseTitle = Get-SafeFileName -Name $baseTitle
    $finalExt  = if ([string]::IsNullOrWhiteSpace($mergeExt)) { "mp4" } else { $mergeExt }
    $targetPath = Join-Path $dest ("{0}.{1}" -f $baseTitle, $finalExt)
    $idx = 2
    while (Test-Path -LiteralPath $targetPath) {
        $targetPath = Join-Path $dest ("{0}_{1}.{2}" -f $baseTitle, $idx, $finalExt); $idx++
    }
    Write-Host ("[OUTPUT] Archivo destino: {0}" -f $targetPath) -ForegroundColor Cyan

    # ── Argumentos de yt-dlp ───────────────────────────────────────────────────
    $dlpArgs = @("--encoding","utf-8","--progress","--no-color","--newline","-f",$fSelector)
    $dlpArgs += $noPlaylistArg
    if ($mergeExt) {
        $dlpArgs += @("--merge-output-format",$mergeExt)
    }
    $dlpArgs += @(
        "-o", $targetPath,
        "--progress-template","download:%(progress._percent_str)s ETA:%(progress._eta_str)s SPEED:%(progress._speed_str)s",
        "--extractor-args","youtube:player_client=default,-web_safari,-web_embedded,-tv",
        "--no-part","--ignore-config"
    )
    $dlpArgs += $noPlaylistArg   # doble por seguridad

    $dlpArgs += $script:ultimaURL
    $dlpArgs += @("--retries","5","--retry-sleep","2","-N","4")

    # ── Ejecutar descarga ──────────────────────────────────────────────────────
    [System.Windows.Input.Mouse]::OverrideCursor = [System.Windows.Input.Cursors]::Wait
    try {
        $exit = Invoke-YtDlpConsoleProgress -ExePath $yt.Source -Args $dlpArgs -UpdateUi
        if ($exit -ne 0 -and $videoSel -match '^best(video)?$' -and $script:bestProgId) {
            Write-Host "[RETRY] Reintento con ID concreto: $($script:bestProgId)" -ForegroundColor Yellow
            $retryArgs = @(
                "--encoding","utf-8","--progress","--no-color","--newline",
                "-f",$script:bestProgId,"-o",$targetPath,
                "--progress-template","download:%(progress._percent_str)s ETA:%(progress._eta_str)s SPEED:%(progress._speed_str)s",
                "--extractor-args","youtube:player_client=default,-web_safari,-web_embedded,-tv"
            )
            $exit = Invoke-YtDlpConsoleProgress -ExePath $yt.Source -Args $retryArgs -UpdateUi
        }
        if ($null -eq $exit -and $script:lastYtDlpExitCode -ne $null) { $exit = $script:lastYtDlpExitCode }

        Write-Host "------------------------" -ForegroundColor DarkGray
        $archivoExiste = Test-Path -LiteralPath $targetPath

        if ($exit -eq 0 -or $archivoExiste) {
            if ($exit -ne 0 -and $archivoExiste) {
                Write-Host "[WARN] ExitCode=$exit pero archivo existe. Se considera éxito." -ForegroundColor Yellow
            }
            Add-HistoryUrl -Url $script:ultimaURL
            $lblEstadoConsulta.Text = ("Completado: {0}" -f $script:ultimoTitulo)
            [System.Windows.MessageBox]::Show(("Descarga finalizada:`n{0}" -f $script:ultimoTitulo), "Completado", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        } else {
            $lblEstadoConsulta.Text = "Error durante la descarga"
            [System.Windows.MessageBox]::Show("Falló la descarga. Revisa conexión/URL/DRM.", "Error de descarga", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
            Write-Host "[ERROR] Descarga fallida. ExitCode=$exit" -ForegroundColor Red
        }
    } finally {
        [System.Windows.Input.Mouse]::OverrideCursor = $null
        $btnPickDestino.IsEnabled = $prevPickDest
        $cmbVideoFmt.IsEnabled    = $prevCmbVid
        $cmbAudioFmt.IsEnabled    = $prevCmbAud
        Set-DownloadButtonVisual
    }
})

# ═══════════════════════════════════════════════════════════════════════════════
#  ESTADO INICIAL DE LA GUI
# ═══════════════════════════════════════════════════════════════════════════════
Refresh-GateByDeps
Set-DownloadButtonVisual
try { $txtDestino.Text = $script:ultimaRutaDescarga } catch {}

# ═══════════════════════════════════════════════════════════════════════════════
#  MOSTRAR LA APLICACIÓN
# ═══════════════════════════════════════════════════════════════════════════════
$formPrincipal.ShowDialog() | Out-Null



