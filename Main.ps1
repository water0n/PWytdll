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
$global:DebugEnabled = [bool]::Parse((Get-IniValue -Section "DEBUG" -Key "ConsoleDebug" -DefaultValue "false"))

# ── Feature flags ─────────────────────────────────────────────────────────────
$script:RequireNode = $true   # Cambiar a $false para no exigir Node.js
$script:AiEnabled   = [bool]::Parse((Get-IniValue -Section "ai" -Key "Enabled" -DefaultValue "false"))
$script:aiPanelExpanded = $false
$script:aiPanelInitialized = $false

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

# ── Cookies ────────────────────────────────────────────────────────────────────────────
$btnPickCookies.Add_Click({ Show-CookieDialog })

# ── IA / Gemini ───────────────────────────────────────────────────────────────
Update-AiButtonVisual
$btnAi.Add_Click({
    if ($script:aiPanelExpanded) { Set-AiPanelExpanded -Expanded $false }
    else { Show-AiPanel }
})
if ($btnAiPanelToggle) {
    $btnAiPanelToggle.Add_Click({
        if ($script:aiPanelExpanded) { Set-AiPanelExpanded -Expanded $false }
        else { Show-AiPanel }
    })
}


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

# ── Cola de descargas ─────────────────────────────────────────────────────────
Initialize-DownloadQueueUi

# ── Salir ─────────────────────────────────────────────────────────────────────
$btnExit.Add_Click({
    Write-Host "[EXIT] Cerrando aplicación por solicitud del usuario." -ForegroundColor Yellow
    $formPrincipal.Close()
})

# ── Consultar / Agregar a cola ────────────────────────────────────────────────
$btnDescargar.Add_Click({
    Refresh-GateByDeps
    $currentUrl  = Get-CurrentUrl
    $ready = $script:videoConsultado -and
             -not [string]::IsNullOrWhiteSpace($script:ultimaURL) -and
             ($script:ultimaURL -eq $currentUrl) -and
             $script:formatsEnumerated

    if (-not $ready) {
        if ([string]::IsNullOrWhiteSpace($currentUrl)) {
            $lblEstadoConsulta.Text     = "ERROR: Escribe una URL"
            $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Red
            [System.Windows.MessageBox]::Show("Escribe una URL de YouTube.", "Falta URL", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
        $lblEstadoConsulta.Text     = "Iniciando consulta..."
        $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkBlue
        $ok = Invoke-ConsultaFromUI -Url $currentUrl
        if ($ok) {
            Set-DownloadButtonVisual
            [System.Windows.MessageBox]::Show("Consulta lista. Revisa formatos y vuelve a presionar Agregar a cola.", "Consulta completada", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        } else { Set-DownloadButtonVisual }
        return
    }

    if (Add-CurrentDownloadToQueue) {
        Set-DownloadButtonVisual
    } else {
        [System.Windows.MessageBox]::Show("No se pudo agregar la descarga a la cola.", "Cola de descargas", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
    }
})

# ═══════════════════════════════════════════════════════════════════════════════
#  ESTADO INICIAL DE LA GUI
# ═══════════════════════════════════════════════════════════════════════════════
Refresh-GateByDeps
Set-DownloadButtonVisual

# ── Restaurar cookies guardadas de la sesión anterior ─────────────────────────
$savedCookiePath = Get-IniValue -Section "cookies" -Key "Path" -DefaultValue $null
if (-not [string]::IsNullOrWhiteSpace($savedCookiePath) -and (Test-Path $savedCookiePath -ErrorAction SilentlyContinue)) {
    $script:cookiesPath = $savedCookiePath
    Write-Host "[INIT] Cookies restauradas: $savedCookiePath" -ForegroundColor Green
} else {
    # Buscar cualquier archivo de cookies guardado en sesiones anteriores
    $found = @("edge","chrome","brave","firefox","opera","vivaldi") |
             ForEach-Object { Join-Path $env:TEMP "ytdll_cookies_$_.txt" } |
             Where-Object { Test-Path $_ } | Select-Object -First 1
    if ($found) {
        Write-Host "[INIT] Archivo de cookies encontrado (no activado): $found" -ForegroundColor Yellow
    }
}
Update-CookieButtonVisual
try { $txtDestino.Text = $script:ultimaRutaDescarga } catch {}

# ═══════════════════════════════════════════════════════════════════════════════
#  MOSTRAR LA APLICACIÓN
# ═══════════════════════════════════════════════════════════════════════════════
$formPrincipal.ShowDialog() | Out-Null
