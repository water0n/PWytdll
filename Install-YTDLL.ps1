#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Owner = "water0n",
    [string]$Repository = "PWytdll",
    [string]$InstallRoot = "C:\Temp\YTDLL",
    [switch]$ForceUpdate,
    [switch]$NoLaunch,
    [string]$PackagePath,
    [string]$PackageVersion
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$assetName = "ytdll-release.zip"
$appPath = Join-Path $InstallRoot "app"
$localVersionFile = Join-Path $appPath "version.json"
$localRunBat = Join-Path $appPath "run.bat"

function Get-InstalledVersion {
    if (-not (Test-Path -LiteralPath $localVersionFile)) {
        return $null
    }

    try {
        $data = Get-Content -LiteralPath $localVersionFile -Raw | ConvertFrom-Json
        return [string]$data.Version
    } catch {
        return $null
    }
}

function Start-Ytdll {
    if (-not (Test-Path -LiteralPath $localRunBat)) {
        throw "No se encontro el ejecutable local: $localRunBat"
    }

    if (-not $NoLaunch) {
        Write-Host "Iniciando YTDLL..." -ForegroundColor Green
        Start-Process -FilePath $localRunBat -WorkingDirectory $appPath
    }
}

function Use-InstalledCopy {
    param([string]$Reason)

    if (Test-Path -LiteralPath $localRunBat) {
        Write-Warning $Reason
        Write-Host "Se usara la instalacion local." -ForegroundColor Yellow
        Start-Ytdll
        return $true
    }

    return $false
}

New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null

$downloadPath = Join-Path $InstallRoot $assetName
$remoteVersion = $PackageVersion

if ([string]::IsNullOrWhiteSpace($PackagePath)) {
    $apiUrl = "https://api.github.com/repos/$Owner/$Repository/releases/latest"
    Write-Host "Consultando la ultima version de YTDLL..." -ForegroundColor Cyan

    try {
        $release = Invoke-RestMethod -Uri $apiUrl -UseBasicParsing `
            -Headers @{ "User-Agent" = "YTDLL-Installer" }
    } catch {
        if (Use-InstalledCopy -Reason "No se pudo consultar GitHub Releases: $($_.Exception.Message)") {
            return
        }
        throw
    }

    $remoteVersion = [string]$release.tag_name
    $asset = @($release.assets | Where-Object name -eq $assetName | Select-Object -First 1)
    if ($asset.Count -eq 0) {
        if (Use-InstalledCopy -Reason "El release $remoteVersion no contiene $assetName.") {
            return
        }
        throw "El release $remoteVersion no contiene el archivo $assetName."
    }

    $installedVersion = Get-InstalledVersion
    if (-not $ForceUpdate -and
        -not [string]::IsNullOrWhiteSpace($installedVersion) -and
        $installedVersion -eq $remoteVersion) {
        Write-Host "YTDLL $installedVersion ya esta actualizado." -ForegroundColor Green
        Start-Ytdll
        return
    }

    Write-Host "Descargando YTDLL $remoteVersion..." -ForegroundColor Cyan
    try {
        Invoke-WebRequest -Uri $asset[0].browser_download_url `
            -OutFile $downloadPath -UseBasicParsing
    } catch {
        if (Use-InstalledCopy -Reason "No se pudo descargar $remoteVersion`: $($_.Exception.Message)") {
            return
        }
        throw
    }
} else {
    $resolvedPackage = (Resolve-Path -LiteralPath $PackagePath).Path
    Copy-Item -LiteralPath $resolvedPackage -Destination $downloadPath -Force
    if ([string]::IsNullOrWhiteSpace($remoteVersion)) {
        $remoteVersion = "paquete local"
    }
}

$stagingPath = Join-Path $InstallRoot ("app.new." + [guid]::NewGuid().ToString("N"))
$backupPath = Join-Path $InstallRoot ("app.old." + [guid]::NewGuid().ToString("N"))

try {
    New-Item -ItemType Directory -Path $stagingPath -Force | Out-Null
    Expand-Archive -LiteralPath $downloadPath -DestinationPath $stagingPath -Force

    foreach ($requiredFile in @(
        "Main.ps1",
        "Dependencies.ps1",
        "Functions.ps1",
        "GUI.ps1",
        "run.bat",
        "version.json"
    )) {
        $candidate = Join-Path $stagingPath $requiredFile
        if (-not (Test-Path -LiteralPath $candidate)) {
            throw "El paquete esta incompleto. Falta: $requiredFile"
        }
    }

    if (Test-Path -LiteralPath $appPath) {
        Move-Item -LiteralPath $appPath -Destination $backupPath
    }

    try {
        Move-Item -LiteralPath $stagingPath -Destination $appPath
    } catch {
        if (Test-Path -LiteralPath $backupPath) {
            Move-Item -LiteralPath $backupPath -Destination $appPath
        }
        throw
    }

    if (Test-Path -LiteralPath $backupPath) {
        Remove-Item -LiteralPath $backupPath -Recurse -Force
    }
} finally {
    if (Test-Path -LiteralPath $stagingPath) {
        Remove-Item -LiteralPath $stagingPath -Recurse -Force -ErrorAction SilentlyContinue
    }
    if (Test-Path -LiteralPath $downloadPath) {
        Remove-Item -LiteralPath $downloadPath -Force -ErrorAction SilentlyContinue
    }
}

$installedVersion = Get-InstalledVersion
Write-Host "YTDLL instalado correctamente." -ForegroundColor Green
Write-Host "Version: $installedVersion" -ForegroundColor Cyan
Write-Host "Ruta: $appPath" -ForegroundColor DarkGray

Start-Ytdll
