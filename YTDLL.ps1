# YTDLL.ps1 - Script de instalación y ejecución
# Ejecutar con: irm bit.ly/ytdll | iex

param(
    [string]$Branch = "release"   # solo informativo ahora
)

# ===================== ADVERTENCIA DE VERSIÓN BETA =====================
Write-Host "`n==============================================" -ForegroundColor Red
Write-Host "           YTDLL - Descargador de Videos" -ForegroundColor Cyan
Write-Host "==============================================" -ForegroundColor Red
Write-Host "Esta aplicación se encuentra en fase de desarrollo BETA.`n" -ForegroundColor Yellow
Write-Host "Características principales:" -ForegroundColor White
Write-Host " - Descarga videos de múltiples plataformas" -ForegroundColor Gray
Write-Host " - Interfaz gráfica amigable" -ForegroundColor Gray
Write-Host " - Soporte para formatos video+audio" -ForegroundColor Gray
Write-Host " - Vista previa de videos" -ForegroundColor Gray
Write-Host "`n¿Desea continuar con la instalación/ejecución? (Y/N)" -ForegroundColor Yellow

# Leer una tecla (Y/N)
$Host.UI.RawUI.FlushInputBuffer()
do {
    $key = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    $answer = $key.Character.ToString().ToUpper()
} until ($answer -in @('Y','N'))

if ($answer -ne 'Y') {
    Write-Host "`nInstalación cancelada por el usuario.`n" -ForegroundColor Red
    return
}

# ======================================================================
Clear-Host

$baseRuntimePath = "C:\temp\ytdll"
$releasePath = Join-Path $baseRuntimePath "release"
$Owner = "water0ff"
$Repo = "PWytdll"

function Show-ProgressBar {
    param(
        [int]$Percent,
        [string]$Message = ""
    )
    $width = 20
    if ($Percent -lt 0) { $Percent = 0 }
    if ($Percent -gt 100) { $Percent = 100 }
    $filled = [math]::Round(($Percent / 100) * $width)
    $bar = "[" + ("=" * $filled).PadRight($width) + "]"
    $line = "{0} {1,3}%  {2}" -f $bar, $Percent, $Message
    $consoleWidth = $Host.UI.RawUI.WindowSize.Width
    $line = $line.PadRight($consoleWidth - 1)
    Write-Host "`r$line" -NoNewline
    if ($Percent -ge 100) {
        Write-Host ""
    }
}

if (-not (Test-Path $baseRuntimePath)) {
    New-Item -ItemType Directory -Path $baseRuntimePath -Force | Out-Null
}

Show-ProgressBar -Percent 5 -Message "Preparando entorno YTDLL..."

$zipPath = Join-Path $baseRuntimePath "ytdll-release.zip"

Show-ProgressBar -Percent 10 -Message "Limpiando versión anterior..."
try {
    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force -ErrorAction SilentlyContinue
    }

    if (Test-Path $releasePath) {
        Remove-Item $releasePath -Recurse -Force -ErrorAction SilentlyContinue
    }
} catch {
    # Si algo falla limpiando, continuamos
}

$zipUrl = "https://github.com/$Owner/$Repo/releases/latest/download/ytdll-release.zip"

Show-ProgressBar -Percent 20 -Message "Descargando última versión..."
try {
    $progressPreference = 'SilentlyContinue'
    Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath -UseBasicParsing
    $progressPreference = 'Continue'
} catch {
    Show-ProgressBar -Percent 100 -Message "Error al descargar"
    Write-Host ""
    Write-Host "? No se pudo descargar la versión más reciente." -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    Write-Host ""
    Write-Host "Solución alternativa:" -ForegroundColor Yellow
    Write-Host "1. Visita: https://github.com/water0ff/PWytdll" -ForegroundColor Cyan
    Write-Host "2. Descarga manualmente el archivo ytdll-release.zip" -ForegroundColor Cyan
    Write-Host "3. Extrae en: C:\temp\ytdll\release" -ForegroundColor Cyan
    return
}

Show-ProgressBar -Percent 50 -Message "Extrayendo archivos..."
try {
    if (-not (Test-Path $releasePath)) {
        New-Item -ItemType Directory -Path $releasePath -Force | Out-Null
    }

    # Usar Expand-Archive para compatibilidad con PowerShell 5.0
    Expand-Archive -Path $zipPath -DestinationPath $releasePath -Force
} catch {
    Show-ProgressBar -Percent 100 -Message "Error al extraer"
    Write-Host ""
    Write-Host "? No se pudo extraer el archivo ZIP." -ForegroundColor Red
    Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor DarkRed
    return
}

Show-ProgressBar -Percent 70 -Message "Preparando aplicación..."
$projectRoot = $releasePath
$mainPath = Join-Path $projectRoot "main.ps1"

if (-not (Test-Path $mainPath)) {
    Show-ProgressBar -Percent 100 -Message "Error"
    Write-Host ""
    Write-Host "? No se encontró main.ps1 en la carpeta release." -ForegroundColor Red
    Write-Host "Ruta esperada: $mainPath" -ForegroundColor DarkYellow
    return
}

Show-ProgressBar -Percent 100 -Message "Listo"
Write-Host ""
Write-Host "=============================================" -ForegroundColor Gray
Write-Host "   Iniciando YTDLL desde GitHub" -ForegroundColor Green
Write-Host "   Canal: $Branch" -ForegroundColor DarkGray
Write-Host "   Carpeta: $projectRoot" -ForegroundColor DarkGray
Write-Host "=============================================" -ForegroundColor Gray
Write-Host ""

# Ejecutar la aplicación
try {
    powershell -ExecutionPolicy Bypass -NoProfile -File $mainPath
} catch {
    Write-Host "? Error al ejecutar la aplicación: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
    Write-Host "Puedes intentar ejecutar manualmente:" -ForegroundColor Yellow
    Write-Host "powershell -ExecutionPolicy Bypass -File `"$mainPath`"" -ForegroundColor Cyan
}
