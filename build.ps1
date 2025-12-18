# build.ps1 - Script de construcción para YTDLL
param(
    [string]$Version = "1.0.0",
    [switch]$Clean
)

# Configuración
$ProjectRoot = $PSScriptRoot
$SrcPath = Join-Path $ProjectRoot "src"
$ReleasePath = Join-Path $ProjectRoot "release"

# Colores para mensajes
$ErrorColor = "Red"
$SuccessColor = "Green"
$InfoColor = "Cyan"
$WarningColor = "Yellow"

function Write-Step {
    param([string]$Message, [string]$Color = $InfoColor)
    Write-Host "[$(Get-Date -Format 'HH:mm:ss')] " -NoNewline -ForegroundColor Gray
    Write-Host $Message -ForegroundColor $Color
}

function Test-PowerShellVersion {
    $requiredVersion = [version]"5.0"
    $currentVersion = $PSVersionTable.PSVersion
    
    if ($currentVersion -lt $requiredVersion) {
        Write-Step "PowerShell $requiredVersion o superior es requerido. Actual: $currentVersion" $ErrorColor
        return $false
    }
    
    Write-Step "PowerShell $currentVersion - Compatible ?" $SuccessColor
    return $true
}

# Verificar versión de PowerShell
if (-not (Test-PowerShellVersion)) {
    exit 1
}

# Limpiar release si se solicita
if ($Clean -or (Test-Path $ReleasePath)) {
    Write-Step "Limpiando directorio release..." $WarningColor
    try {
        Remove-Item $ReleasePath -Recurse -Force -ErrorAction Stop
        Write-Step "Directorio release limpiado ?" $SuccessColor
    } catch {
        Write-Step "Error al limpiar release: $_" $ErrorColor
        exit 1
    }
}

# Crear estructura de release
Write-Step "Creando estructura de release..." $InfoColor
$folders = @(
    $ReleasePath,
    (Join-Path $ReleasePath "forms"),
    (Join-Path $ReleasePath "modules")
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
    }
}

# Copiar módulos
Write-Step "Copiando módulos..." $InfoColor
$modules = @("Database", "GUI", "Installers", "Queries", "Utilities")
foreach ($module in $modules) {
    $srcModule = Join-Path $SrcPath "modules\$module.psm1"
    $dstModule = Join-Path $ReleasePath "modules\$module.psm1"
    
    if (Test-Path $srcModule) {
        Copy-Item -Path $srcModule -Destination $dstModule -Force
        Write-Step "  Copiado: $module.psm1" $SuccessColor
    } else {
        Write-Step "  Advertencia: $module.psm1 no encontrado en src" $WarningColor
        # Crear archivo vacío para mantener la estructura
        "" | Set-Content -Path $dstModule
    }
}

# Copiar forms (si existen)
Write-Step "Copiando forms..." $InfoColor
$formsPath = Join-Path $SrcPath "forms"
if (Test-Path $formsPath) {
    $formFiles = Get-ChildItem -Path $formsPath -Filter "*.ps1" -File
    foreach ($file in $formFiles) {
        Copy-Item -Path $file.FullName -Destination (Join-Path $ReleasePath "forms\$($file.Name)") -Force
        Write-Step "  Copiado: $($file.Name)" $SuccessColor
    }
}

# Copiar archivos principales
Write-Step "Copiando archivos principales..." $InfoColor
$mainFiles = @("main.ps1", "run.bat")
foreach ($file in $mainFiles) {
    $srcFile = Join-Path $SrcPath $file
    $dstFile = Join-Path $ReleasePath $file
    
    if (Test-Path $srcFile) {
        Copy-Item -Path $srcFile -Destination $dstFile -Force
        Write-Step "  Copiado: $file" $SuccessColor
    } else {
        Write-Step "  Error: $file no encontrado en src" $ErrorColor
    }
}

# Crear version.json
Write-Step "Creando version.json..." $InfoColor
$versionInfo = @{
    version = $Version
    buildDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    powershellVersion = $PSVersionTable.PSVersion.ToString()
    compatibleWith = "PowerShell 5.0+"
} | ConvertTo-Json

$versionInfo | Set-Content -Path (Join-Path $ReleasePath "version.json") -Encoding UTF8
Write-Step "  version.json creado ?" $SuccessColor

# Crear archivo de información del build
$buildInfo = @"
# YTDLL Build Information
Version: $Version
Build Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
Source Directory: $SrcPath
Release Directory: $ReleasePath
PowerShell Version: $($PSVersionTable.PSVersion)

## Files Included:
$(Get-ChildItem -Path $ReleasePath -Recurse -File | ForEach-Object { "  - $($_.FullName.Replace($ReleasePath, ''))" })

## Build Steps:
1. Verified PowerShell compatibility
2. Cleaned release directory
3. Copied modules from src/modules/
4. Copied forms from src/forms/
5. Copied main application files
6. Created version metadata
"@

$buildInfo | Set-Content -Path (Join-Path $ReleasePath "BUILD_INFO.md") -Encoding UTF8

# Crear ZIP de release
Write-Step "Creando archivo ZIP de release..." $InfoColor
$zipPath = Join-Path $ProjectRoot "ytdll-release.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
}

try {
    # Usar Compress-Archive para compatibilidad con PS 5.0
    Compress-Archive -Path "$ReleasePath\*" -DestinationPath $zipPath -CompressionLevel Optimal
    Write-Step "  ytdll-release.zip creado ? ($([math]::Round((Get-Item $zipPath).Length/1MB,2)) MB)" $SuccessColor
} catch {
    Write-Step "  Error al crear ZIP: $_" $ErrorColor
}

# Resumen final
Write-Step "`n=== CONSTRUCCIÓN COMPLETADA ===" $SuccessColor
Write-Step "Versión: $Version" $InfoColor
Write-Step "Directorio release: $ReleasePath" $InfoColor
Write-Step "Archivos en release: $(Get-ChildItem -Path $ReleasePath -Recurse -File).Count" $InfoColor
if (Test-Path $zipPath) {
    Write-Step "ZIP creado: $zipPath" $SuccessColor
}

Write-Step "`nPara probar la aplicación:" $InfoColor
Write-Step "1. Navega a: $ReleasePath" $WarningColor
Write-Step "2. Ejecuta: .\main.ps1" $WarningColor
Write-Step "`nPara distribución:" $InfoColor
Write-Step "Sube ytdll-release.zip a GitHub Releases" $WarningColor
