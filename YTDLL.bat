@echo off
setlocal
title Instalador de YTDLL

net session >nul 2>&1
if not "%errorlevel%"=="0" (
    echo Solicitando permisos de administrador...
    powershell.exe -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    exit /b
)

set "bootstrap=%TEMP%\Install-YTDLL.ps1"
set "bootstrapUrl=https://raw.githubusercontent.com/water0n/PWytdll/refs/heads/main/Install-YTDLL.ps1"

echo Descargando el instalador de YTDLL...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command ^
  "$ProgressPreference='SilentlyContinue';" ^
  "[Net.ServicePointManager]::SecurityProtocol=[Net.SecurityProtocolType]::Tls12;" ^
  "Invoke-WebRequest -UseBasicParsing -Uri '%bootstrapUrl%' -OutFile '%bootstrap%'"

if not "%errorlevel%"=="0" (
    echo.
    echo No se pudo descargar el instalador.
    pause
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%bootstrap%"
set "exitCode=%errorlevel%"

del "%bootstrap%" >nul 2>&1

if not "%exitCode%"=="0" (
    echo.
    echo La instalacion de YTDLL fallo con el codigo %exitCode%.
    pause
)

exit /b %exitCode%
