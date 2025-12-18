#requires -Version 5.0

# Configuración de codificación
chcp 65001 > $null
[Console]::OutputEncoding = [System.Text.UTF8Encoding]::new()
[Console]::InputEncoding = [System.Text.UTF8Encoding]::new()
$OutputEncoding = [Console]::OutputEncoding

$global:version = "beta.25.12.03.1046"

# Cargar ensamblados de Windows Forms y Drawing
try {
    Write-Host "Cargando ensamblados de Windows Forms..." -ForegroundColor Yellow
    Add-Type -AssemblyName System.Windows.Forms
    Write-Host "✓ System.Windows.Forms cargado" -ForegroundColor Green
} catch {
    Write-Host "✗ Error cargando System.Windows.Forms: $_" -ForegroundColor Red
    pause
    exit 1
}

try {
    Add-Type -AssemblyName System.Drawing
    Write-Host "✓ System.Drawing cargado" -ForegroundColor Green
} catch {
    Write-Host "✗ Error cargando System.Drawing: $_" -ForegroundColor Red
    pause
    exit 1
}

try {
    [System.Windows.Forms.Application]::EnableVisualStyles()
    Write-Host "✓ VisualStyles habilitado" -ForegroundColor Green
} catch {
    Write-Host "✗ Error habilitando VisualStyles: $_" -ForegroundColor Red
}

# Configurar política de ejecución
if (Get-Command Set-ExecutionPolicy -ErrorAction SilentlyContinue) {
    Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process -Force
}

# Importar módulos
Write-Host "`nImportando módulos..." -ForegroundColor Yellow
$modulesPath = Join-Path $PSScriptRoot "modules"
$modules = @(
    "GUI.psm1",
    "Download.psm1",
    "Preview.psm1",
    "Utilities.psm1",
    "History.psm1",
    "Dependencies.psm1",
    "Config.psm1"
)

foreach ($module in $modules) {
    $modulePath = Join-Path $modulesPath $module
    if (Test-Path $modulePath) {
        try {
            Import-Module $modulePath -Force -ErrorAction Stop -DisableNameChecking
            Write-Host "  ✓ $module" -ForegroundColor Green
        } catch {
            Write-Host "  ✗ Error importando módulo: $module" -ForegroundColor Red
            Write-Host "    Ruta    : $modulePath" -ForegroundColor DarkYellow
            Write-Host "    Mensaje : $($_.Exception.Message)" -ForegroundColor Yellow
            Write-Host "    Detalle : $($_.InvocationInfo.PositionMessage)" -ForegroundColor DarkYellow
            Write-Host "    Stack   : $($_.ScriptStackTrace)" -ForegroundColor DarkGray
            throw
        }
    } else {
        Write-Host "  ✗ $module no encontrado" -ForegroundColor Red
    }
}

# Inicializar entorno
if (!(Test-Path -Path "C:\Temp")) {
    try {
        New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
        Write-Host "Carpeta 'C:\Temp' creada." -ForegroundColor Green
    } catch {
        Write-Host "Error creando C:\Temp: $_" -ForegroundColor Yellow
    }
}

# Inicializar configuración
try {
    $debugEnabled = Initialize-DzToolsConfig
    Write-DzDebug "`t[DEBUG]Configuración de debug cargada (debug=$debugEnabled)" -Color DarkGray
} catch {
    Write-Host "Advertencia: No se pudo inicializar la configuración de debug. $_" -ForegroundColor Yellow
}

# Iniciar aplicación
try {
    Start-Application
} catch {
    Write-Host "Error fatal: $_" -ForegroundColor Red
    Write-Host "Stack Trace: $($_.Exception.StackTrace)" -ForegroundColor Red
    pause
    exit 1
}