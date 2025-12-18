# build.ps1 - Script de construcción para YTDLL
param(
    [string]$Version = "",
    [switch]$Clean
)

# Configuración
$ProjectRoot = $PSScriptRoot
$SrcPath = $ProjectRoot  # Ahora todo está en la raíz del proyecto
$ReleasePath = Join-Path $ProjectRoot "release"
$ModulesPath = Join-Path $SrcPath "modules"

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

    Write-Step "PowerShell $currentVersion - Compatible ✓" $SuccessColor
    return $true
}

function Get-VersionFromJson {
    param([string]$JsonPath = "version.json")

    if (Test-Path $JsonPath) {
        try {
            $jsonContent = Get-Content -Path $JsonPath -Raw -ErrorAction Stop
            $versionData = $jsonContent | ConvertFrom-Json

            # Primero intenta con "Version" (mayúscula V)
            $version = $versionData.Version
            # Si está vacío, intenta con "version" (minúscula v)
            if ([string]::IsNullOrWhiteSpace($version)) {
                $version = $versionData.version
            }

            if (-not [string]::IsNullOrWhiteSpace($version)) {
                return $version
            }
        } catch {
            Write-Step "Error leyendo $JsonPath: $_" $WarningColor
        }
    }

    # Si falla, usar versión por defecto
    return "beta.unknown"
}

function Update-VersionJson {
    param(
        [string]$Version,
        [string]$OutputPath
    )

    try {
        $versionInfo = @{
            Version = $Version
            LastUpdated = (Get-Date -Format "yyyy-MM-ddTHH:mm:ss")
            BuildDate = (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
            PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        } | ConvertTo-Json

        $versionInfo | Set-Content -Path $OutputPath -Encoding UTF8
        Write-Step "  version.json actualizado en release" $SuccessColor
        return $true
    } catch {
        Write-Step "  Error al actualizar version.json: $_" $ErrorColor
        return $false
    }
}

# Verificar versión de PowerShell
if (-not (Test-PowerShellVersion)) {
    exit 1
}

# Obtener versión actual del proyecto
$currentVersion = Get-VersionFromJson -JsonPath (Join-Path $ProjectRoot "version.json")

# Si no se proporciona versión por parámetro, usar la actual o incrementar
if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = $currentVersion
    Write-Step "Usando versión actual del proyecto: $Version" $InfoColor
} else {
    Write-Step "Usando versión especificada: $Version" $InfoColor
}

# Limpiar release si se solicita
if ($Clean -or (Test-Path $ReleasePath)) {
    Write-Step "Limpiando directorio release..." $WarningColor
    try {
        if (Test-Path $ReleasePath) {
            Remove-Item $ReleasePath -Recurse -Force -ErrorAction Stop
        }
        Write-Step "Directorio release limpiado ✓" $SuccessColor
    } catch {
        Write-Step "Error al limpiar release: $_" $ErrorColor
        exit 1
    }
}

# Crear estructura de release
Write-Step "Creando estructura de release..." $InfoColor
$folders = @(
    $ReleasePath,
    (Join-Path $ReleasePath "modules")
)

foreach ($folder in $folders) {
    if (-not (Test-Path $folder)) {
        New-Item -ItemType Directory -Path $folder -Force | Out-Null
        Write-Step "  Creado: $($folder.Replace($ReleasePath, 'release'))" $SuccessColor
    }
}

# Verificar que existe la carpeta de módulos
if (-not (Test-Path $ModulesPath)) {
    Write-Step "ERROR: No se encontró la carpeta 'modules' en el proyecto" $ErrorColor
    Write-Step "Creando estructura de módulos básica..." $WarningColor

    # Crear estructura mínima de módulos
    $moduleNames = @("Config", "GUI", "Download", "Preview", "Utilities", "History", "Dependencies")
    foreach ($module in $moduleNames) {
        $moduleFile = Join-Path $ModulesPath "$module.psm1"
        if (-not (Test-Path (Split-Path $moduleFile))) {
            New-Item -ItemType Directory -Path (Split-Path $moduleFile) -Force | Out-Null
        }
        # Crear archivo de módulo vacío
        "# Módulo $module" | Set-Content -Path $moduleFile -Encoding UTF8
        Write-Step "  Creado módulo vacío: $module.psm1" $WarningColor
    }
}

# Copiar todos los módulos de la carpeta modules
Write-Step "Copiando módulos..." $InfoColor
if (Test-Path $ModulesPath) {
    $moduleFiles = Get-ChildItem -Path $ModulesPath -Filter "*.psm1" -File
    if ($moduleFiles.Count -gt 0) {
        foreach ($file in $moduleFiles) {
            $dstModule = Join-Path $ReleasePath "modules\$($file.Name)"
            Copy-Item -Path $file.FullName -Destination $dstModule -Force
            Write-Step "  Copiado: $($file.Name)" $SuccessColor
        }
    } else {
        Write-Step "  Advertencia: No se encontraron archivos .psm1 en la carpeta modules" $WarningColor
    }
} else {
    Write-Step "  ERROR: Carpeta modules no encontrada" $ErrorColor
}

# Copiar archivos principales
Write-Step "Copiando archivos principales..." $InfoColor
$mainFiles = @("main.ps1")
foreach ($file in $mainFiles) {
    $srcFile = Join-Path $SrcPath $file
    $dstFile = Join-Path $ReleasePath $file

    if (Test-Path $srcFile) {
        # Leer el contenido y actualizar la versión si es necesario
        $content = Get-Content -Path $srcFile -Raw

        # Si el archivo main.ps1 contiene una versión hardcodeada, la actualizamos
        if ($content -match 'global:version\s*=\s*"[^"]+"') {
            $content = $content -replace 'global:version\s*=\s*"[^"]+"', "global:version = `"$Version`""
        }

        $content | Set-Content -Path $dstFile -Encoding UTF8
        Write-Step "  Copiado y actualizado: $file" $SuccessColor
    } else {
        Write-Step "  Error: $file no encontrado" $ErrorColor
    }
}

# Crear o actualizar version.json en release
Write-Step "Creando/actualizando version.json en release..." $InfoColor
Update-VersionJson -Version $Version -OutputPath (Join-Path $ReleasePath "version.json")

# Crear run.bat para facilitar la ejecución
Write-Step "Creando run.bat..." $InfoColor
$runBatContent = @'
@echo off
chcp 65001 > nul
powershell.exe -ExecutionPolicy Bypass -NoProfile -File "%~dp0main.ps1"
pause
'@
$runBatContent | Set-Content -Path (Join-Path $ReleasePath "run.bat") -Encoding ASCII
Write-Step "  run.bat creado ✓" $SuccessColor

# Crear README para la release
Write-Step "Creando README.md para la release..." $InfoColor
$readmeContent = @"
# YTDLL - Descargador de Videos

Versión: $Version
Fecha de compilación: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")

## Instrucciones de uso

1. **Ejecutar con PowerShell:**
   - Haga clic derecho en `main.ps1`
   - Seleccione "Ejecutar con PowerShell"

2. **Ejecutar con doble clic:**
   - Ejecute `run.bat`

3. **Desde línea de comandos:**
   \```powershell
   powershell -ExecutionPolicy Bypass -File "main.ps1"
   \```

## Requisitos del sistema

- Windows 7 o superior
- PowerShell 5.0 o superior
- Conexión a Internet

## Módulos incluidos

- **Config.psm1**: Configuración y variables globales
- **GUI.psm1**: Interfaz gráfica de usuario
- **Download.psm1**: Funciones de descarga
- **Preview.psm1**: Vista previa de videos
- **Utilities.psm1**: Utilidades generales
- **History.psm1**: Historial de URLs
- **Dependencies.psm1**: Manejo de dependencias

## Notas importantes

- La primera ejecución puede tardar más debido a la carga de ensamblados
- Se requiere conexión a Internet para descargar videos
- Los videos se guardan en la carpeta de destino configurada

## Solución de problemas

Si la aplicación no se inicia:
1. Verifique que PowerShell 5.0+ esté instalado
2. Ejecute PowerShell como administrador y ejecute:
   \`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser\`
3. Reinstale las dependencias desde el botón "?" en la aplicación

---

**Compilado el:** $(Get-Date -Format "dd/MM/yyyy HH:mm")
"@

$readmeContent | Set-Content -Path (Join-Path $ReleasePath "README.md") -Encoding UTF8
Write-Step "  README.md creado ✓" $SuccessColor

# Crear archivo de información del build
Write-Step "Creando información de compilación..." $InfoColor
$buildInfo = @"
# YTDLL Build Information

## Datos de la compilación
- Versión: $Version
- Fecha de compilación: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
- Directorio origen: $SrcPath
- Directorio release: $ReleasePath
- Versión de PowerShell: $($PSVersionTable.PSVersion)

## Archivos incluidos:
$(Get-ChildItem -Path $ReleasePath -Recurse -File | ForEach-Object {
    $relativePath = $_.FullName.Replace($ReleasePath, '').TrimStart('\')
    $sizeKB = [math]::Round($_.Length / 1KB, 2)
    "  - $relativePath ($sizeKB KB)"
})

## Módulos:
$(Get-ChildItem -Path (Join-Path $ReleasePath "modules") -Filter "*.psm1" -File | ForEach-Object {
    $sizeKB = [math]::Round($_.Length / 1KB, 2)
    "  - $($_.Name) ($sizeKB KB)"
})

## Pasos de compilación:
1. Verificada compatibilidad de PowerShell
2. Limpiado directorio release (si se solicitó)
3. Copiados módulos desde modules/
4. Copiado main.ps1 (versión actualizada)
5. Creado version.json en release
6. Creado run.bat para facilitar ejecución
7. Creado README.md con instrucciones

## Configuración:
- Encoding: UTF-8
- Requisito mínimo: PowerShell 5.0
- Plataforma: Windows

"@

$buildInfo | Set-Content -Path (Join-Path $ReleasePath "BUILD_INFO.md") -Encoding UTF8
Write-Step "  BUILD_INFO.md creado ✓" $SuccessColor

# Crear ZIP de release
Write-Step "Creando archivo ZIP de release..." $InfoColor
$zipPath = Join-Path $ProjectRoot "ytdll-v$Version.zip"
if (Test-Path $zipPath) {
    Remove-Item $zipPath -Force
    Write-Step "  ZIP anterior eliminado" $WarningColor
}

try {
    # Usar Compress-Archive para compatibilidad con PS 5.0
    $compressParams = @{
        Path = "$ReleasePath\*"
        DestinationPath = $zipPath
        CompressionLevel = "Optimal"
    }

    Compress-Archive @compressParams
    $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Write-Step "  ytdll-v$Version.zip creado ✓ ($zipSize MB)" $SuccessColor
} catch {
    Write-Step "  Error al crear ZIP: $_" $ErrorColor
    Write-Step "  Intentando método alternativo..." $WarningColor

    # Método alternativo usando .NET
    try {
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        [System.IO.Compression.ZipFile]::CreateFromDirectory($ReleasePath, $zipPath)
        $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
        Write-Step "  ytdll-v$Version.zip creado (método alternativo) ✓ ($zipSize MB)" $SuccessColor
    } catch {
        Write-Step "  Error crítico al crear ZIP" $ErrorColor
    }
}

# Resumen final
Write-Step "`n=== CONSTRUCCIÓN COMPLETADA ===" $SuccessColor
Write-Step "Versión: $Version" $InfoColor
Write-Step "Directorio release: $ReleasePath" $InfoColor
$fileCount = (Get-ChildItem -Path $ReleasePath -Recurse -File).Count
Write-Step "Archivos en release: $fileCount" $InfoColor

if (Test-Path $zipPath) {
    $zipSize = [math]::Round((Get-Item $zipPath).Length / 1MB, 2)
    Write-Step "ZIP creado: $(Split-Path $zipPath -Leaf) ($zipSize MB)" $SuccessColor
}

Write-Step "`nPara probar la aplicación:" $InfoColor
Write-Step "1. Navega a: $ReleasePath" $WarningColor
Write-Step "2. Ejecuta: .\run.bat" $WarningColor
Write-Step "   o" $WarningColor
Write-Step "   .\main.ps1" $WarningColor

Write-Step "`nPara distribución:" $InfoColor
Write-Step "Sube $(Split-Path $zipPath -Leaf) a GitHub Releases" $WarningColor

Write-Step "`nEstructura de release:" $InfoColor
tree $ReleasePath /F | Select-Object -Skip 1 | ForEach-Object {
    Write-Host "  $_" -ForegroundColor Gray
}