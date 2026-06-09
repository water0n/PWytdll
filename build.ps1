#requires -Version 5.1
[CmdletBinding()]
param(
    [string]$Version = ("v{0}" -f (Get-Date -Format "yyMMdd.HHmm")),
    [string]$OutputDirectory
)

$ErrorActionPreference = "Stop"

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $OutputDirectory = Join-Path $PSScriptRoot "release"
}

$projectRoot = [System.IO.Path]::GetFullPath($PSScriptRoot)
$outputRoot = [System.IO.Path]::GetFullPath($OutputDirectory)
$projectPrefix = $projectRoot.TrimEnd(
    [System.IO.Path]::DirectorySeparatorChar,
    [System.IO.Path]::AltDirectorySeparatorChar
) + [System.IO.Path]::DirectorySeparatorChar

if (-not $outputRoot.StartsWith(
        $projectPrefix,
        [System.StringComparison]::OrdinalIgnoreCase
    )) {
    throw "OutputDirectory debe estar dentro del proyecto: $projectRoot"
}

$requiredFiles = @(
    "Main.ps1",
    "Dependencies.ps1",
    "Functions.ps1",
    "GUI.ps1"
)

foreach ($file in $requiredFiles) {
    $sourcePath = Join-Path $PSScriptRoot $file
    if (-not (Test-Path -LiteralPath $sourcePath)) {
        throw "Falta el archivo requerido: $sourcePath"
    }
}

$scriptsToValidate = @(
    $requiredFiles
    "Install-YTDLL.ps1"
    "build.ps1"
)
foreach ($scriptName in $scriptsToValidate) {
    $sourceFile = Get-Item -LiteralPath (Join-Path $PSScriptRoot $scriptName)
    $tokens = $null
    $parseErrors = $null
    [void][System.Management.Automation.Language.Parser]::ParseFile(
        $sourceFile.FullName,
        [ref]$tokens,
        [ref]$parseErrors
    )
    if ($parseErrors.Count -gt 0) {
        $messages = @($parseErrors | ForEach-Object {
            "{0}:{1} {2}" -f $_.Extent.File, $_.Extent.StartLineNumber, $_.Message
        })
        throw ($messages -join [Environment]::NewLine)
    }
}

if (Test-Path -LiteralPath $outputRoot) {
    Remove-Item -LiteralPath $outputRoot -Recurse -Force
}
New-Item -ItemType Directory -Path $outputRoot -Force | Out-Null

foreach ($file in $requiredFiles) {
    Copy-Item -LiteralPath (Join-Path $PSScriptRoot $file) `
        -Destination (Join-Path $outputRoot $file) -Force
}

$versionInfo = [ordered]@{
    Version     = $Version
    LastUpdated = (Get-Date).ToString("yyyy-MM-ddTHH:mm:ssK")
}
$versionInfo |
    ConvertTo-Json |
    Set-Content -LiteralPath (Join-Path $outputRoot "version.json") -Encoding UTF8

$runBat = @'
@echo off
setlocal
title YTDLL

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0Main.ps1"
set "exitCode=%errorlevel%"

if not "%exitCode%"=="0" (
    echo.
    echo YTDLL finalizo con el codigo %exitCode%.
    pause
)

exit /b %exitCode%
'@
[System.IO.File]::WriteAllText(
    (Join-Path $outputRoot "run.bat"),
    $runBat,
    [System.Text.Encoding]::ASCII
)

$zipPath = Join-Path $PSScriptRoot "ytdll-release.zip"
if (Test-Path -LiteralPath $zipPath) {
    Remove-Item -LiteralPath $zipPath -Force
}

Compress-Archive -Path (Join-Path $outputRoot "*") `
    -DestinationPath $zipPath -CompressionLevel Optimal -Force

Write-Host "Release creado: $zipPath" -ForegroundColor Green
Write-Host "Version: $Version" -ForegroundColor Cyan
