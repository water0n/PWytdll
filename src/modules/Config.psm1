# Variables de configuración globales
$script:ConfigDir = Join-Path $env:LOCALAPPDATA "YTDLL"
$script:ConfigFile = Join-Path $script:ConfigDir "config.ini"
$script:LogFile = Join-Path $script:ConfigDir "history.log"
$script:ThumbnailsDir = Join-Path $script:ConfigDir "thumbnails"

# Inicializar directorios de configuración
if (-not (Test-Path $script:ConfigDir)) {
    New-Item -ItemType Directory -Path $script:ConfigDir -Force | Out-Null
}
if (-not (Test-Path $script:ThumbnailsDir)) {
    New-Item -ItemType Directory -Path $script:ThumbnailsDir -Force | Out-Null
}

# Funciones de configuración
function Get-IniValue {
    param([string]$Section, [string]$Key, [string]$DefaultValue = $null)

    if (-not (Test-Path $script:ConfigFile)) {
        return $DefaultValue
    }

    try {
        $content = Get-Content $script:ConfigFile -ErrorAction Stop
        $inSection = $false

        foreach ($line in $content) {
            $line = $line.Trim()
            if ($line -eq "[$Section]") {
                $inSection = $true
                continue
            } elseif ($line -match '^\[') {
                $inSection = $false
                continue
            }

            if ($inSection -and $line -match "^$Key=(.*)$") {
                return $matches[1].Trim()
            }
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

    $lines = @()
    $sectionFound = $false
    $keyFound = $false

    if (Test-Path $script:ConfigFile) {
        $lines = Get-Content $script:ConfigFile
    }

    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i].Trim() -eq "[$Section]") {
            $sectionFound = $true
            for ($j = $i + 1; $j -lt $lines.Count; $j++) {
                if ($lines[$j] -match '^\[') {
                    break  # Nueva sección encontrada
                }
                if ($lines[$j] -match "^$Key=") {
                    $lines[$j] = "$Key=$Value"
                    $keyFound = $true
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

    try {
        Set-Content -Path $script:ConfigFile -Value $lines -Encoding UTF8
    } catch {
        Write-Host "[CONFIG] Error guardando configuración: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Initialize-DzToolsConfig {
    # Inicializar configuración de debug
    $debugValue = Get-IniValue -Section "DEBUG" -Key "ConsoleDebug" -DefaultValue "false"
    $script:DebugEnabled = [bool]::Parse($debugValue)
    return $script:DebugEnabled
}

function Write-DebugLog {
    param([string]$Message, [string]$ForegroundColor = "Yellow")

    if ($script:DebugEnabled) {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
}

# Variables de estado de la aplicación
$script:videoConsultado = $false
$script:ultimaURL = $null
$script:ultimoTitulo = $null
$script:lastThumbUrl = $null
$script:formatsEnumerated = $false
$script:cookiesPath = $null
$script:ultimaRutaDescarga = Get-IniValue -Section "ruta" -Key "Destino" -DefaultValue ([Environment]::GetFolderPath('Desktop'))
$script:RequireNode = $true
$script:lastFormats = $null
$script:lastExtractor = $null
$script:isPlaylist = $false
$script:originalUrl = $null

# Exportar funciones y variables
Export-ModuleMember -Function Get-IniValue, Set-IniValue, Initialize-DzToolsConfig, Write-DebugLog `
                    -Variable ConfigDir, ConfigFile, LogFile, ThumbnailsDir, DebugEnabled, `
                    videoConsultado, ultimaURL, ultimoTitulo, lastThumbUrl, formatsEnumerated, `
                    cookiesPath, ultimaRutaDescarga, RequireNode, lastFormats, lastExtractor, `
                    isPlaylist, originalUrl