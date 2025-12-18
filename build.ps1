# build.ps1 - Script de construcción para YTDLL
param(
    [string]$Version = "",
    [switch]$Clean
)

# Configuración básica
$ProjectRoot = $PSScriptRoot
$ReleasePath = Join-Path $ProjectRoot "release"
$VersionJsonPath = Join-Path $ProjectRoot "version.json"

# Funciones de utilidad
function Write-Step {
    param([string]$Message, [string]$Color = "Cyan")
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor Gray
    Write-Host $Message -ForegroundColor $Color
}

# Leer versión actual
function Get-CurrentVersion {
    if (Test-Path $VersionJsonPath) {
        try {
            $json = Get-Content $VersionJsonPath -Raw | ConvertFrom-Json
            return $json.Version
        } catch {
            Write-Step "Error leyendo version.json: $($_.Exception.Message)" "Yellow"
        }
    }
    return "unknown"
}

# Verificar PowerShell
function Test-PowerShellVersion {
    $requiredVersion = [version]"5.0"
    $currentVersion = $PSVersionTable.PSVersion

    if ($currentVersion -lt $requiredVersion) {
        Write-Step "PowerShell $requiredVersion+ requerido. Actual: $currentVersion" "Red"
        return $false
    }
    Write-Step "PowerShell $currentVersion - Compatible" "Green"
    return $true
}

# Programa principal
try {
    # Verificar PowerShell
    if (-not (Test-PowerShellVersion)) { exit 1 }

    # Obtener versión
    $currentVersion = Get-CurrentVersion
    if ([string]::IsNullOrWhiteSpace($Version)) {
        $Version = $currentVersion
    }
    Write-Step "Version: $Version" "Cyan"

    # Limpiar si se solicita
    if ($Clean -and (Test-Path $ReleasePath)) {
        Write-Step "Limpiando release..." "Yellow"
        Remove-Item $ReleasePath -Recurse -Force -ErrorAction Stop
        Write-Step "Release limpiado" "Green"
    }

    # Crear directorios
    Write-Step "Creando estructura..." "Cyan"
    if (-not (Test-Path $ReleasePath)) {
        New-Item -ItemType Directory -Path $ReleasePath -Force | Out-Null
    }
    if (-not (Test-Path (Join-Path $ReleasePath "modules"))) {
        New-Item -ItemType Directory -Path (Join-Path $ReleasePath "modules") -Force | Out-Null
    }

    # Copiar archivos
    Write-Step "Copiando archivos..." "Cyan"

    # Copiar main.ps1
    if (Test-Path (Join-Path $ProjectRoot "main.ps1")) {
        $mainContent = Get-Content (Join-Path $ProjectRoot "main.ps1") -Raw
        # Actualizar versión si está hardcodeada
        $mainContent = $mainContent -replace 'global:version\s*=\s*"[^"]+"', "global:version = `"$Version`""
        $mainContent | Set-Content (Join-Path $ReleasePath "main.ps1") -Encoding UTF8
        Write-Step "  main.ps1 copiado" "Green"
    }

    # Copiar modules
    $modulesDir = Join-Path $ProjectRoot "modules"
    if (Test-Path $modulesDir) {
        $modules = Get-ChildItem $modulesDir -Filter "*.psm1"
        foreach ($module in $modules) {
            Copy-Item $module.FullName (Join-Path $ReleasePath "modules\$($module.Name)") -Force
            Write-Step "  $($module.Name) copiado" "Green"
        }
    }

    # Copiar version.json
    if (Test-Path $VersionJsonPath) {
        Copy-Item $VersionJsonPath (Join-Path $ReleasePath "version.json") -Force
        Write-Step "  version.json copiado" "Green"
    }

    # Crear run.bat
    $runBat = @'
@echo off
chcp 65001 > nul
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0main.ps1"
pause
'@
    $runBat | Set-Content (Join-Path $ReleasePath "run.bat") -Encoding ASCII
    Write-Step "  run.bat creado" "Green"

    # Crear ZIP
    Write-Step "Creando ZIP..." "Cyan"
    $zipName = "ytdll-$Version.zip"
    $zipPath = Join-Path $ProjectRoot $zipName

    if (Test-Path $zipPath) {
        Remove-Item $zipPath -Force
    }

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    [System.IO.Compression.ZipFile]::CreateFromDirectory($ReleasePath, $zipPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

    $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Write-Step "  $zipName creado ($zipSize MB)" "Green"

    # Resumen
    Write-Step "`n=== CONSTRUCCION COMPLETADA ===" "Green"
    Write-Step "Release en: $ReleasePath" "Cyan"
    Write-Step "ZIP: $zipPath ($zipSize MB)" "Cyan"

} catch {
    Write-Step "ERROR: $($_.Exception.Message)" "Red"
    exit 1
}