<#
.SYNOPSIS
    YTDLL — Módulo de Dependencias
    Funciones para verificar, instalar, actualizar y desinstalar herramientas externas
    mediante Chocolatey (yt-dlp, ffmpeg, Node.js, mpv.net, .NET 6 Desktop Runtime).

    Compatible con PowerShell 5.x
    Cargado mediante dot-sourcing desde Main.ps1
#>

# ─── Detección básica ──────────────────────────────────────────────────────────

function Test-CommandExists {
    <#
    .SYNOPSIS Retorna $true si el comando existe en el PATH. #>
    param([Parameter(Mandatory=$true)][string]$Name)
    try { Get-Command $Name -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}

function Get-ToolVersion {
    <#
    .SYNOPSIS Ejecuta <comando> <args> y retorna la versión como string, o $null si no existe. #>
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [string]$ArgsForVersion = "--version",
        [ValidateSet("FirstLine","Raw")][string]$Parse = "FirstLine"
    )
    try { $cmd = Get-Command $Command -ErrorAction Stop } catch { return $null }
    try {
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $p.StartInfo.FileName               = $cmd.Source
        $p.StartInfo.Arguments              = $ArgsForVersion
        $p.StartInfo.RedirectStandardOutput = $true
        $p.StartInfo.RedirectStandardError  = $true
        $p.StartInfo.UseShellExecute        = $false
        $p.StartInfo.CreateNoWindow         = $true
        [void]$p.Start()
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()
        $combined = ($stdout + "`n" + $stderr).Trim()
        if ($Parse -eq "FirstLine") {
            return ($combined -split "`r?`n" | Where-Object { $_.Trim() -ne "" } | Select-Object -First 1)
        }
        return $combined
    } catch {
        return "Detectado pero no se obtuvo versión"
    }
}

# ─── Chocolatey ────────────────────────────────────────────────────────────────

function Check-Chocolatey {
    <#
    .SYNOPSIS
        Verifica si Chocolatey está instalado.
        Si no está, ofrece instalarlo.  Retorna $true si está disponible.
    #>
    Write-Host "[CHECK] Verificando Chocolatey..." -ForegroundColor Cyan
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "[WARN] Chocolatey no encontrado." -ForegroundColor Yellow
        $response = [System.Windows.Forms.MessageBox]::Show(
            "Chocolatey no está instalado. ¿Desea instalarlo ahora?",
            "Chocolatey no encontrado",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($response -eq [System.Windows.Forms.DialogResult]::No) {
            Write-Host "[CANCEL] Usuario rechazó instalar Chocolatey." -ForegroundColor Red
            return $false
        }
        Write-Host "[INSTALL] Instalando Chocolatey..." -ForegroundColor Cyan
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = `
                [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "`t[OK] Chocolatey instalado. Configurando cache..." -ForegroundColor Green
            choco config set cacheLocation C:\Choco\cache | Out-Null
            [System.Windows.Forms.MessageBox]::Show(
                "Chocolatey se instaló correctamente.`nPor favor, reinicia PowerShell antes de continuar.",
                "Reinicio requerido",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            Stop-Process -Id $PID -Force
            return $false
        } catch {
            Write-Host "`t[ERROR] Falló instalación de Chocolatey: $_" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                "Error al instalar Chocolatey. Por favor, inténtelo manualmente.",
                "Error de instalación",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            return $false
        }
    }
    Write-Host "`t[OK] Chocolatey ya está instalado." -ForegroundColor Green
    return $true
}

# ─── .NET 6 Desktop Runtime ────────────────────────────────────────────────────

function Test-DotNet6DesktopRuntime {
    <#
    .SYNOPSIS Retorna $true si .NET 6 Desktop Runtime está instalado. #>
    try { $cmd = Get-Command dotnet -ErrorAction Stop } catch { return $false }
    try {
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $p.StartInfo.FileName               = $cmd.Source
        $p.StartInfo.Arguments              = "--list-runtimes"
        $p.StartInfo.RedirectStandardOutput = $true
        $p.StartInfo.RedirectStandardError  = $true
        $p.StartInfo.UseShellExecute        = $false
        $p.StartInfo.CreateNoWindow         = $true
        [void]$p.Start()
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()
        $out = ($stdout + "`n" + $stderr)
        return ($out -match 'Microsoft\.NETCore\.App\s+6\.' -or
                $out -match 'Microsoft\.WindowsDesktop\.App\s+6\.')
    } catch {
        return $false
    }
}

function Ensure-DotNet6DesktopRuntime {
    <#
    .SYNOPSIS Instala .NET 6 Desktop Runtime si no está presente. Retorna $true si está disponible. #>
    Write-Host "[CHECK] Verificando .NET 6 Desktop Runtime..." -ForegroundColor Cyan
    if (Test-DotNet6DesktopRuntime) {
        Write-Host "`t[OK] .NET 6 Desktop Runtime ya está disponible." -ForegroundColor Green
        return $true
    }
    Write-Host "[WARN] .NET 6 Desktop Runtime no detectado." -ForegroundColor Yellow
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        [System.Windows.Forms.MessageBox]::Show(
            ".NET 6 Desktop Runtime es obligatorio para mpv.net, pero Chocolatey no está disponible." +
            "`nInstálalo manualmente desde el sitio de Microsoft o instala Chocolatey.",
            ".NET 6 requerido",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return $false
    }
    $resp = [System.Windows.Forms.MessageBox]::Show(
        "Es necesario instalar Microsoft .NET 6 Desktop Runtime para reproducir videos con mpv.net." +
        "`n¿Deseas instalarlo ahora con Chocolatey (dotnet-6.0-desktopruntime)?",
        ".NET 6 Desktop Runtime requerido",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($resp -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Host "[CANCEL] Usuario canceló instalación de .NET 6 Desktop Runtime." -ForegroundColor Yellow
        return $false
    }
    Write-Host "[INSTALL] Instalando .NET 6 Desktop Runtime..." -ForegroundColor Cyan
    try {
        Start-Process -FilePath "choco" `
            -ArgumentList @("install","dotnet-6.0-desktopruntime","-y") `
            -NoNewWindow -Wait
    } catch {
        Write-Host "`t[ERROR] Falló instalación de .NET 6 Desktop Runtime: $_" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show(
            "No se pudo instalar .NET 6 Desktop Runtime automáticamente. Intenta instalarlo manualmente.",
            "Error de instalación",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return $false
    }
    if (Test-DotNet6DesktopRuntime) {
        Write-Host "`t[OK] .NET 6 Desktop Runtime instalado correctamente." -ForegroundColor Green
        return $true
    }
    [System.Windows.Forms.MessageBox]::Show(
        ".NET 6 Desktop Runtime se instaló, pero no pudo ser detectado de inmediato." +
        "`nReinicia PowerShell y vuelve a ejecutar la aplicación.",
        "Reinicio requerido",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
    Stop-Process -Id $PID -Force
    return $false
}

# ─── Instalación headless (sin GUI de dependencias) ────────────────────────────

function Ensure-ToolHeadless {
    <#
    .SYNOPSIS
        Verifica si una herramienta está instalada.
        Si no está, la instala silenciosamente con Chocolatey.
        Retorna $true si está disponible tras el intento.
    #>
    param(
        [Parameter(Mandatory=$true)][string]$CommandName,
        [Parameter(Mandatory=$true)][string]$FriendlyName,
        [Parameter(Mandatory=$true)][string]$ChocoPkg,
        [string]$VersionArgs = "--version",
        [ValidateSet("FirstLine","Raw")][string]$Parse = "FirstLine"
    )
    Write-Host ("[CHECK] Verificando {0}..." -f $FriendlyName) -ForegroundColor Cyan
    if (Test-CommandExists -Name $CommandName) {
        Write-Host ("`t[OK] {0} detectado." -f $FriendlyName) -ForegroundColor Green
        return $true
    }
    Write-Host ("[WARN] {0} no encontrado. Instalando con choco..." -f $FriendlyName) -ForegroundColor Yellow
    try {
        Start-Process -FilePath "choco" -ArgumentList @("install",$ChocoPkg,"-y") -NoNewWindow -Wait
    } catch {
        Write-Host ("[ERROR] Falló instalación headless de {0}: {1}" -f $FriendlyName, $_) -ForegroundColor Red
        return $false
    }
    if (-not (Test-CommandExists -Name $CommandName)) {
        Write-Host ("[WARN] {0} instalado pero no detectado aún. Requiere reinicio de PS." -f $FriendlyName) -ForegroundColor Yellow
        return $false
    }
    Write-Host ("`t[OK] {0} detectado." -f $FriendlyName) -ForegroundColor Green
    return $true
}

function Ensure-MpvNetOptional {
    <#
    .SYNOPSIS Verifica/instala mpv.net (opcional). Primero comprueba .NET 6 Desktop Runtime. #>
    if (-not (Ensure-DotNet6DesktopRuntime)) { return $false }
    return (Ensure-ToolHeadless `
        -CommandName "mpvnet" `
        -FriendlyName "mpv.net" `
        -ChocoPkg "mpv.net" `
        -VersionArgs "--version")
}

function Initialize-AppHeadless {
    <#
    .SYNOPSIS
        Ejecuta la verificación e instalación automática de todas las dependencias requeridas
        antes de mostrar la GUI. Retorna $true si el entorno está listo.
    #>
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()

    if (-not (Check-Chocolatey)) {
        Write-Host "[EXIT] Falta Chocolatey o se requiere reinicio." -ForegroundColor Yellow
        return $false
    }
    if (-not (Ensure-ToolHeadless -CommandName "yt-dlp"  -FriendlyName "yt-dlp"  -ChocoPkg "yt-dlp"       -VersionArgs "--version")) { return $false }
    if (-not (Ensure-ToolHeadless -CommandName "ffmpeg"  -FriendlyName "ffmpeg"  -ChocoPkg "ffmpeg"       -VersionArgs "-version"))  { return $false }
    if ($script:RequireNode) {
        if (-not (Ensure-ToolHeadless -CommandName "node" -FriendlyName "Node.js" -ChocoPkg "nodejs-lts" -VersionArgs "--version")) { return $false }
    }
    Write-Host "[CHECK] (headless) Verificando mpvnet: " -NoNewline
    if (Test-CommandExists -Name "mpvnet") {
        Write-Host "`n`t[OK] INSTALADO (opcional)" -ForegroundColor Green
    } else {
        Write-Host "`n`t[NO] NO INSTALADO (opcional)" -ForegroundColor Yellow
    }
    return $true
}

# ─── Acciones desde el panel de dependencias de la GUI ────────────────────────

function Refresh-DependencyLabel {
    <#
    .SYNOPSIS Actualiza el texto y color de un label de versión en el panel de dependencias. #>
    param(
        [string]$CommandName,
        [string]$FriendlyName,
        [ref]$LabelRef,
        [string]$VersionArgs = "--version",
        [ValidateSet("FirstLine","Raw")][string]$Parse = "FirstLine"
    )
    $ver = Get-ToolVersion -Command $CommandName -ArgsForVersion $VersionArgs -Parse $Parse
    if ($ver) {
        $LabelRef.Value.Text     = ("{0}: {1}" -f $FriendlyName, $ver)
        $LabelRef.Value.ForeColor = [System.Drawing.Color]::ForestGreen
    } else {
        $LabelRef.Value.Text     = ("{0}: no instalado" -f $FriendlyName)
        $LabelRef.Value.ForeColor = [System.Drawing.Color]::Red
    }
    Refresh-GateByDeps
}

function Update-Dependency {
    <#
    .SYNOPSIS Actualiza una dependencia usando Chocolatey y refresca su label de versión. #>
    param(
        [string]$ChocoPkg,
        [string]$FriendlyName,
        [string]$CommandName,
        [ref]$LabelRef,
        [string]$VersionArgs = "--version",
        [ValidateSet("FirstLine","Raw")][string]$Parse = "FirstLine"
    )
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Chocolatey no está disponible. Instálalo para poder actualizar dependencias.",
            "Chocolatey requerido",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }
    Write-Host ("[UPDATE] Actualizando {0} con choco upgrade {1} -y" -f $FriendlyName, $ChocoPkg) -ForegroundColor Cyan
    try {
        Start-Process -FilePath "choco" -ArgumentList @("upgrade",$ChocoPkg,"-y") -Wait -NoNewWindow
        Refresh-DependencyLabel -CommandName $CommandName -FriendlyName $FriendlyName `
            -LabelRef $LabelRef -VersionArgs $VersionArgs -Parse $Parse
        [System.Windows.Forms.MessageBox]::Show(
            ("{0} ha sido verificado/actualizado." -f $FriendlyName),
            "Actualización completada",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    } catch {
        Write-Host ("[ERROR] Falló actualización de {0}: {1}" -f $FriendlyName, $_) -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show(
            ("No se pudo actualizar {0}. Revisa la consola." -f $FriendlyName),
            "Error de actualización",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } finally {
        Refresh-GateByDeps
    }
}

function Uninstall-Dependency {
    <#
    .SYNOPSIS Desinstala una dependencia usando Chocolatey y actualiza su label. #>
    param(
        [string]$ChocoPkg,
        [string]$FriendlyName,
        [ref]$LabelRef
    )
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        [System.Windows.Forms.MessageBox]::Show(
            "Chocolatey no está disponible. Instálalo para poder desinstalar dependencias.",
            "Chocolatey requerido",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        ) | Out-Null
        return
    }
    $r = [System.Windows.Forms.MessageBox]::Show(
        ("¿Seguro que deseas desinstalar {0}?{1}{1}Esto podría requerir reiniciar PowerShell para refrescar el PATH." `
            -f $FriendlyName, [Environment]::NewLine),
        "Confirmar desinstalación",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    Write-Host ("[UNINSTALL] Desinstalando {0} con choco uninstall {1} -y" -f $FriendlyName,$ChocoPkg) -ForegroundColor Cyan
    try {
        Start-Process -FilePath "choco" -ArgumentList @("uninstall",$ChocoPkg,"-y") -Wait -NoNewWindow
        $LabelRef.Value.Text     = ("{0}: no instalado" -f $FriendlyName)
        $LabelRef.Value.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show(
            ("{0} ha sido desinstalado.{1}{1}Te recomiendo cerrar y abrir PowerShell para refrescar el PATH." `
                -f $FriendlyName,[Environment]::NewLine),
            "Desinstalación completada",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Information
        ) | Out-Null
    } catch {
        Write-Host ("[ERROR] Falló desinstalación de {0}: {1}" -f $FriendlyName, $_) -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show(
            ("No se pudo desinstalar {0}. Revisa la consola." -f $FriendlyName),
            "Error de desinstalación",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
    } finally {
        Refresh-GateByDeps
    }
}
