if (!(Test-Path -Path "C:\Temp")) {
    New-Item -ItemType Directory -Path "C:\Temp" | Out-Null
    Write-Host "Carpeta 'C:\Temp' creada correctamente."
}
$iconDir = "C:\Temp\icos"
if (-not (Test-Path $iconDir)) {
    New-Item -ItemType Directory -Path $iconDir -Force | Out-Null
    Write-Host "Carpeta de íconos creada: $iconDir"
}
$script:LogFile = "C:\Temp\ytdll\ytdll_history.txt"
$script:ThumbnailsDir = "C:\Temp\ytdll\miniaturas"
$script:ConfigDir = "C:\Temp\ytdll"
$script:ConfigFile = "C:\Temp\ytdll\config.ini"
if (-not (Test-Path -LiteralPath $script:LogFile)) {
    New-Item -ItemType File -Path $script:LogFile -Force | Out-Null
}
                                                                                                $version = "beta 251215.1225"
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
function Write-DebugLog {
    param([string]$Message, [string]$ForegroundColor = "Yellow")

    if ($script:DebugEnabled) {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
}
$script:DebugEnabled = [bool]::Parse((Get-IniValue -Section "DEBUG" -Key "ConsoleDebug" -DefaultValue "false"))
function Get-CleanUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    $cleanUrl = $Url -replace '^https?://', ''
    $cleanUrl = $cleanUrl -replace '^www\.', ''
    $cleanUrl = $cleanUrl -replace '/+$', ''  # Quitar trailing slashes
    return $cleanUrl.Trim()
}
function Clear-History {
    try {
        Set-Content -LiteralPath $script:LogFile -Value @() -Encoding UTF8
    } catch {}
}
try {
  [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
  [Console]::InputEncoding  = [System.Text.Encoding]::UTF8
} catch {}
$OutputEncoding = [System.Text.Encoding]::UTF8
$env:PYTHONIOENCODING = 'utf-8'
chcp 65001 | Out-Null               # Forzar code page de consola a UTF-8
$env:PYTHONUTF8 = '1'               # Python/yt-dlp en modo UTF-8
if ($PSVersionTable.PSVersion.Major -ge 7) {
    $PSStyle.OutputRendering = 'Ansi'
}
$global:defaultInstructions = @"
----- CAMBIOS -----
- Se agrega ini para guardar configuraciones, nuevas rutas para URLS y miniaturas.
- Rediseño y agregar opción de previsualizar.
- Ahora ya guarda un log con URLS consultadas.
- Se agrea funcionalidad para ver y buscar sitios compatibles.
- Soporte para VODS de twitch / vista previa.
- Se agregó botón ? para información de sistema.
- Ahora ya solo existe 1 botón para consultar y descargar.
- Ahora se debe tener una carpeta preconfigurada de destino, por omisión se usa el Escritorio.
- Ahora permite que selecciones los formatos para video y audio.
- Se agrega la opción para actualizar y desinstalar dependencias.
- Se agregó vista previa del video.
- Se agregó detalles de progreso de descarga en consola.
- Se agregó dependencia Node.
- Se agregó validar consulta de video para descargar.
"@
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    # Soporte para arrastrar ventana sin borde (user32.dll)
Add-Type @"
using System;
using System.Runtime.InteropServices;
public static class NativeDrag {
    public const int WM_NCLBUTTONDOWN = 0xA1;
    public const int HTCAPTION = 0x2;

    [DllImport("user32.dll")]
    public static extern bool ReleaseCapture();

    [DllImport("user32.dll")]
    public static extern IntPtr SendMessage(IntPtr hWnd, int Msg, int wParam, int lParam);
}
"@
$formPrincipal = New-Object System.Windows.Forms.Form
$formPrincipal.Size = New-Object System.Drawing.Size(400, 650)
$formPrincipal.StartPosition = "CenterScreen"
$formPrincipal.BackColor = [System.Drawing.Color]::White
$formPrincipal.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$formPrincipal.ControlBox      = $false
$formPrincipal.MaximizeBox     = $false
$formPrincipal.MinimizeBox     = $false
$formPrincipal.Opacity = 0.97
$formPrincipal.Add_Shown({
    param($sender, $e)
    Set-RoundedRegion -Control $sender -Radius 20
})
$formPrincipal.Add_Resize({
    param($sender, $e)
    Set-RoundedRegion -Control $sender -Radius 20
})
$formPrincipal.Add_MouseDown({
    param($sender, $e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        [NativeDrag]::ReleaseCapture() | Out-Null
        [NativeDrag]::SendMessage($sender.Handle,
            [NativeDrag]::WM_NCLBUTTONDOWN,
            [NativeDrag]::HTCAPTION,
            0
        ) | Out-Null
    }
})
$defaultFont         = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$boldFont            = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$ColorBgForm         = [System.Drawing.Color]::FromArgb(209, 209, 214)
$ColorPrimary        = [System.Drawing.Color]::FromArgb(94, 92, 230) # INDIGO?
$ColorPrimaryDark    = [System.Drawing.Color]::FromArgb(0, 92, 197)
$ColorPrimaryLight   = [System.Drawing.Color]::FromArgb(142, 209, 255)
$ColorSurface        = [System.Drawing.Color]::FromArgb(255, 255, 255)
$ColorPanel          = [System.Drawing.Color]::FromArgb(242, 242, 247)
$ColorText           = [System.Drawing.Color]::FromArgb(28, 28, 30)
$ColorSubText        = [System.Drawing.Color]::FromArgb(142, 142, 147)
$ColorAccent         = [System.Drawing.Color]::FromArgb(72, 169, 197) # TEAL tipo iOS
$formPrincipal.BackColor = $ColorBgForm
Write-Host "`n=============================================" -ForegroundColor DarkCyan
Write-Host "                   YTDLL                       " -ForegroundColor Green
Write-Host ("              Versión: v{0}" -f $version) -ForegroundColor Green
Write-Host "=============================================" -ForegroundColor DarkCyan
$toolTip = New-Object System.Windows.Forms.ToolTip
function Set-RoundedRegion {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Control]$Control,

        [int]$Radius = 10
    )
    if ($Radius -lt 1 -or -not $Control.Width -or -not $Control.Height) { return }
    $rect = New-Object System.Drawing.Rectangle(0, 0, $Control.Width, $Control.Height)
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diam = $Radius * 2
    $path.AddArc($rect.X, $rect.Y, $diam, $diam, 180, 90)
    $path.AddArc($rect.Right - $diam, $rect.Y, $diam, $diam, 270, 90)
    $path.AddArc($rect.Right - $diam, $rect.Bottom - $diam, $diam, $diam, 0, 90)
    $path.AddArc($rect.X, $rect.Bottom - $diam, $diam, $diam, 90, 90)
    $path.CloseFigure()
    $Control.Region = New-Object System.Drawing.Region($path)
}
function Create-Button {
    param (
        [string]$Text,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$BackColor = $ColorPrimary,
        [System.Drawing.Color]$ForeColor = [System.Drawing.Color]::White,
        [string]$ToolTipText = $null,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(220, 35)),
        [System.Drawing.Font]$Font = $defaultFont,
        [bool]$Enabled = $true
    )
    $button = New-Object System.Windows.Forms.Button
    $button.Text      = $Text
    $button.Size      = $Size
    $button.Location  = $Location
    $button.BackColor = $BackColor
    $button.ForeColor = $ForeColor
    $button.Font      = $Font
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.FlatAppearance.MouseDownBackColor = $ColorPrimaryDark
    $button.FlatAppearance.MouseOverBackColor = $ColorPrimary
    $button.Tag = $BackColor
    $button_MouseEnter = {
        $this.BackColor = $ColorPrimaryDark
        $this.Font = $boldFont
        $this.Cursor = [System.Windows.Forms.Cursors]::Hand
    }
    $button_MouseLeave = {
        $this.BackColor = $this.Tag
        $this.Font = $defaultFont
        $this.Cursor = [System.Windows.Forms.Cursors]::Default
    }
    $button.Add_MouseEnter($button_MouseEnter)
    $button.Add_MouseLeave($button_MouseLeave)
    $button.Add_Resize({
        param($sender, $e)
        $radius = [int]([math]::Round($sender.Height / 2))
        if ($radius -lt 10) { $radius = 10 }
        Set-RoundedRegion -Control $sender -Radius $radius
    })
    $button.Enabled = $Enabled
    if ($ToolTipText) { $toolTip.SetToolTip($button, $ToolTipText) }
    return $button
}
function Create-Label {
    param(
        [string]$Text,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$BackColor = [System.Drawing.Color]::Transparent,
        [System.Drawing.Color]$ForeColor = $ColorText,
        [string]$ToolTipText = $null,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(200, 30)),
        [System.Drawing.Font]$Font = $defaultFont,
        [System.Windows.Forms.BorderStyle]$BorderStyle = [System.Windows.Forms.BorderStyle]::None,
        [System.Drawing.ContentAlignment]$TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft,
        [switch]$IsTitle,
        [switch]$IsTag
    )
    $label = New-Object System.Windows.Forms.Label
    $label.Text       = $Text
    $label.Size       = $Size
    $label.Location   = $Location
    $label.BackColor  = $BackColor
    $label.ForeColor  = $ForeColor
    $label.Font       = $Font
    $label.BorderStyle= $BorderStyle
    $label.TextAlign  = $TextAlign
    if ($IsTitle) {
        $label.Font      = $boldFont
        $label.ForeColor = $ColorPrimaryDark
    }
    if ($IsTag) {
        $label.BackColor = [System.Drawing.Color]::FromArgb(230,235,245)
        $label.ForeColor = $ColorSubText
    }
    if ($ToolTipText) { $toolTip.SetToolTip($label, $ToolTipText) }
    return $label
}
function Create-Form {
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter()][System.Drawing.Size]$Size = (New-Object System.Drawing.Size(350,200)),
        [Parameter()][System.Windows.Forms.FormStartPosition]$StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen,
        [Parameter()][System.Windows.Forms.FormBorderStyle]$FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog,
        [Parameter()][bool]$MaximizeBox = $false,[Parameter()][bool]$MinimizeBox = $false,
        [Parameter()][bool]$TopMost = $false,[Parameter()][bool]$ControlBox = $true,
        [Parameter()][System.Drawing.Icon]$Icon = $null,
        [Parameter()][System.Drawing.Color]$BackColor = [System.Drawing.SystemColors]::Control
    )
    $form = New-Object System.Windows.Forms.Form
    $form.Text=$Title; $form.Size=$Size; $form.StartPosition=$StartPosition
    $form.FormBorderStyle=$FormBorderStyle; $form.MaximizeBox=$MaximizeBox; $form.MinimizeBox=$MinimizeBox
    $form.TopMost=$TopMost; $form.ControlBox=$ControlBox
    if ($Icon) { $form.Icon = $Icon }
    $form.BackColor = $BackColor
    return $form
}
function Create-ComboBox {
    param(
        [System.Drawing.Point]$Location,[System.Drawing.Size]$Size = (New-Object System.Drawing.Size(200,30)),
        [System.Windows.Forms.ComboBoxStyle]$DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList,
        [System.Drawing.Font]$Font = $defaultFont,[string[]]$Items = @(),[int]$SelectedIndex = -1,[string]$DefaultText = $null
    )
    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = $Location; $comboBox.Size = $Size
    $comboBox.DropDownStyle = $DropDownStyle; $comboBox.Font = $Font
    if ($Items.Count -gt 0) { $comboBox.Items.AddRange($Items); $comboBox.SelectedIndex = $SelectedIndex }
    if ($DefaultText) { $comboBox.Text = $DefaultText }
    return $comboBox
}
function Create-TextBox {
    param(
        [System.Drawing.Point]$Location,[System.Drawing.Size]$Size = (New-Object System.Drawing.Size(200,30)),
        [System.Drawing.Color]$BackColor=[System.Drawing.Color]::White,[System.Drawing.Color]$ForeColor=[System.Drawing.Color]::Black,
        [System.Drawing.Font]$Font=$defaultFont,[string]$Text="",[bool]$Multiline=$false,
        [System.Windows.Forms.ScrollBars]$ScrollBars=[System.Windows.Forms.ScrollBars]::None,
        [bool]$ReadOnly=$false,[bool]$UseSystemPasswordChar=$false
    )
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location=$Location; $textBox.Size=$Size; $textBox.BackColor=$BackColor; $textBox.ForeColor=$ForeColor
    $textBox.Font=$Font; $textBox.Text=$Text; $textBox.Multiline=$Multiline; $textBox.ScrollBars=$ScrollBars; $textBox.ReadOnly=$ReadOnly
    $textBox.WordWrap=$false; if ($UseSystemPasswordChar) { $textBox.UseSystemPasswordChar = $true }
    return $textBox
}
function Set-DownloadButtonVisual {
    param()
    $haveYt   = Test-CommandExists -Name "yt-dlp"
    $haveFfm  = Test-CommandExists -Name "ffmpeg"
    $haveNode = if ($script:RequireNode) { Test-CommandExists -Name "node" } else { $true }
    $haveMpv  = Test-CommandExists -Name "mpvnet"
    $depsOk = $haveYt -and $haveFfm -and $haveNode
    if (-not $depsOk) {
        $btnDescargar.Enabled   = $false
        $btnDescargar.BackColor = [System.Drawing.Color]::Black
        $btnDescargar.ForeColor = [System.Drawing.Color]::White
        $btnDescargar.Text      = "Descargar"
        $toolTip.SetToolTip($btnDescargar, "Deshabilitado: instala/activa dependencias")
        $btnDescargar.Tag = $btnDescargar.BackColor
        return
    }
    $currentUrl = Get-CurrentUrl
    $isConsulted = $script:videoConsultado -and
                   -not [string]::IsNullOrWhiteSpace($script:ultimaURL) -and
                   ($script:ultimaURL -eq $currentUrl)
    $btnDescargar.Enabled = $true
if (-not $isConsulted) {
        $btnDescargar.Text = "Buscar Video"
        $btnDescargar.BackColor = [System.Drawing.Color]::DodgerBlue
        $btnDescargar.ForeColor = [System.Drawing.Color]::White
        $toolTip.SetToolTip($btnDescargar, "Aún no consultado: al hacer clic validará la URL (no descargará)")
    }
    elseif (-not $script:formatsEnumerated) {
        $btnDescargar.Text = "Buscar Video"  # CAMBIO: Si no hay formatos, volver a buscar
        $btnDescargar.Enabled   = $true
        $btnDescargar.BackColor = [System.Drawing.Color]::DarkOrange
        $btnDescargar.ForeColor = [System.Drawing.Color]::White
        $toolTip.SetToolTip($btnDescargar, "No se pudieron extraer formatos. Presiona 'Buscar Video' para volver a consultar.")
        if ($lblEstadoConsulta) {
            $lblEstadoConsulta.Text = "No fue posible extraer formatos. Presiona 'Buscar Video' para volver a consultar."
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
        }
    }
    else {
        $btnDescargar.Text = "Descargar Video"  # CAMBIO: Texto específico para descargar
        $btnDescargar.BackColor = [System.Drawing.Color]::ForestGreen
        $btnDescargar.ForeColor = [System.Drawing.Color]::White
        $toolTip.SetToolTip($btnDescargar, "Consulta válida: listo para descargar")
    }
    $btnDescargar.Tag = $btnDescargar.BackColor
}
$script:RequireNode = $true #Aqui vemos si se les va a pedir Node o No, falta probar que show
function Test-CommandExists {
    param([Parameter(Mandatory=$true)][string]$Name)
    try { Get-Command $Name -ErrorAction Stop | Out-Null; return $true } catch { return $false }
}
function Refresh-GateByDeps {
    $haveYt   = Test-CommandExists -Name "yt-dlp"
    $haveFfm  = Test-CommandExists -Name "ffmpeg"
    $haveNode = if ($script:RequireNode) { Test-CommandExists -Name "node" } else { $true }
    $haveMpv  = Test-CommandExists -Name "mpvnet"
    $allOk = $haveYt -and $haveFfm -and $haveNode
    Set-DownloadButtonVisual
}
$script:formatsIndex = @{}   # format_id -> objeto con metadatos (tipo, codecs, label)
$script:formatsVideo = @()   # lista de objetos mostrables en Combo Video
$script:formatsAudio = @()   # lista de objetos mostrables en Combo Audio
$script:ExcludedFormatIds = @('18','22','95','96')
function New-FormatDisplay {
    param(
        [string]$Id,[string]$Label
    )
    return ("{0} — {1}" -f $Id, $Label)
}
function Classify-Format {
    param($fmt)
    $v = $fmt.vcodec; $a = $fmt.acodec
    $isVideoOnly = $v -and $v -ne "none" -and ($a -eq $null -or $a -eq "" -or $a -eq "none")
    $isAudioOnly = $a -and $a -ne "none" -and ($v -eq $null -or $v -eq "" -or $v -eq "none")
    $isProgressive = $v -and $v -ne "none" -and $a -and $a -ne "none"
    [pscustomobject]@{
        VideoOnly     = [bool]$isVideoOnly
        AudioOnly     = [bool]$isAudioOnly
        Progressive   = [bool]$isProgressive
        Ext           = $fmt.ext
        VRes          = if ($fmt.height) { [int]$fmt.height } else { 0 }
        VCodec        = $fmt.vcodec
        ACodec        = $fmt.acodec
        ABr           = if ($fmt.abr) { [double]$fmt.abr } else { 0 }
        Tbr           = if ($fmt.tbr) { [double]$fmt.tbr } else { 0 }
        Filesize      = $fmt.filesize
        FormatNote    = $fmt.format_note
        Id            = $fmt.format_id
    }
}
function Human-Size {
    param([Nullable[long]]$bytes)
    if (-not $bytes -or $bytes -le 0) { return "" }
    $units = "B","KiB","MiB","GiB","TiB"
    $p = 0; $n = [double]$bytes
    while ($n -ge 1024 -and $p -lt $units.Count-1) { $n/=1024; $p++ }
    return ("{0:N1}{1}" -f $n, $units[$p])
}
function Format-Count {
    param(
        [Parameter(Mandatory=$true)][int]$Count,
        [Parameter(Mandatory=$true)][string]$Singular,
        [Parameter(Mandatory=$true)][string]$Plural
    )
    if ($Count -eq 1) { return "1 $Singular" }
    return ("{0} {1}" -f $Count, $Plural)
}
function Get-SafeFileName {
    param([Parameter(Mandatory=$true)][string]$Name)
    $invalid = ([IO.Path]::GetInvalidFileNameChars() -join '')
    $regex   = "[{0}]" -f [regex]::Escape($invalid)
    $n = [regex]::Replace($Name, $regex, " ")
    $n = ($n -replace '\s+', ' ').Trim()
    if ([string]::IsNullOrWhiteSpace($n)) { $n = "video" }
    return $n
}
function Format-ExtractorsInline {
    param(
        [Parameter(Mandatory=$true)][string]$RawText,
        [int]$WrapAt = 120
    )
    $lines = $RawText -split "`r?`n" |
        ForEach-Object { $_.Trim() } |
        Where-Object {
            $_ -and
            ($_ -notmatch '^\s*WARNING') -and
            ($_ -notmatch '^\s*ERROR')   -and
            ($_ -notmatch '^\s*Deprecation')
        }

    $tokens = foreach ($ln in $lines) {
        $clean = $ln -replace '\s+\(.*?\)\s*$',''
        $parts = $clean -split '[\s,]+' | Where-Object { $_ }
        foreach ($p in $parts) {
            if ($p -match '^[A-Za-z0-9][\w:-]+$') { $p }
        }
    }

    $uniq = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new([StringComparer]::OrdinalIgnoreCase)
    foreach ($t in $tokens) { if ($seen.Add($t)) { $null = $uniq.Add($t) } }

    $sb = [System.Text.StringBuilder]::new()
    $lineLen = 0
    for ($i=0; $i -lt $uniq.Count; $i++) {
        $tok = $uniq[$i]
        $sep = if ($i -eq 0 -or $lineLen -eq 0) { '' } else { ' | ' }
        $addLen = $sep.Length + $tok.Length
        if ($WrapAt -gt 0 -and ($lineLen + $addLen) -gt $WrapAt) {
            [void]$sb.AppendLine()
            $lineLen = 0
            $sep = ''
            $addLen = $tok.Length
        }
        [void]$sb.Append($sep)
        [void]$sb.Append($tok)
        $lineLen += $addLen
    }

    [pscustomobject]@{
        Text  = $sb.ToString()
        Count = $uniq.Count
        List  = $uniq           # <--- NUEVO: lista utilizable para filtrar
    }
}
function Print-FormatsTable {
    param([array]$formats)
    Write-Host "`n[FORMATOS] Disponibles (similar a yt-dlp -F):" -ForegroundColor Cyan
    Write-Host ("{0,-8} {1,-12} {2,-6} {3,-15} {4,-15} {5,-8} {6}" -f "res", "tamaño", "ext", "vcodec", "acodec", "tbr", "format_id") -ForegroundColor DarkGray
    $videoFormats = @()
    $audioFormats = @()
    foreach ($f in $formats) {
        $klass = Classify-Format $f
        if ($klass.Progressive -or $klass.VideoOnly) {
            $videoFormats += [pscustomobject]@{
                Format = $f
                Height = $klass.VRes
                Tbr = $klass.Tbr
            }
        }
        elseif ($klass.AudioOnly) {
            $audioFormats += [pscustomobject]@{
                Format = $f
                ABr = $klass.ABr
            }
        }
    }
    $sortedVideo = $videoFormats | Sort-Object @{
        Expression = {
            $heightScore = if ($_.Height) { $_.Height } else { 0 }
            $tbrScore = if ($_.Tbr) { $_.Tbr } else { 0 }
            ($heightScore * 100000) + $tbrScore
        }
        Descending = $true
    }
    $sortedAudio = $audioFormats | Sort-Object @{
        Expression = { if ($_.ABr) { $_.ABr } else { 0 } }
        Descending = $true
    }
    foreach ($item in $sortedVideo) {
        $f = $item.Format
        $res = if ($f.height) { "{0}p" -f $f.height } else { "" }
        $sz = Human-Size $f.filesize
        $tbrStr = if ($f.tbr) { "{0}k" -f [math]::Round($f.tbr) } else { "" }
        Write-Host ("{0,-8} {1,-12} {2,-6} {3,-15} {4,-15} {5,-8} {6}" -f $res, $sz, $f.ext, $f.vcodec, $f.acodec, $tbrStr, $f.format_id)
    }
    foreach ($item in $sortedAudio) {
        $f = $item.Format
        $res = ""
        $sz = Human-Size $f.filesize
        $tbrStr = if ($f.tbr) { "{0}k" -f [math]::Round($f.tbr) } else { "" }
        Write-Host ("{0,-8} {1,-12} {2,-6} {3,-15} {4,-15} {5,-8} {6}" -f $res, $sz, $f.ext, $f.vcodec, $f.acodec, $tbrStr, $f.format_id)
    }
}
$script:bestProgId   = $null
$script:bestProgRank = -1
function Fetch-Formats {
    param([Parameter(Mandatory=$true)][string]$Url)
    $script:formatsIndex.Clear()
    $script:formatsVideo = @()
    $script:formatsAudio = @()
    $script:formatsEnumerated = $false
    $script:lastFormats = $null
    $script:bestProgId   = $null
    $script:bestProgRank = -1
    try {
        $yt = Get-Command yt-dlp -ErrorAction Stop
    } catch {
        $lblEstadoConsulta.Text = "ERROR: yt-dlp no disponible para listar formatos"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
        Write-Host "`t[ERROR] yt-dlp no disponible para listar formatos." -ForegroundColor Red
        return $false
    }

    $lblEstadoConsulta.Text = "Obteniendo lista de formatos..."
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
    $args1 = @(
        "-J", "--no-playlist",
        "--ignore-config",
        "--no-warnings",
        $Url
    )
    Write-DebugLog "[FORMATOS] Intento 1: yt-dlp -J (ignore-config + extractor-args)" -ForegroundColor Cyan
    $obj = Invoke-CaptureResponsive -ExePath $yt.Source -Args $args1 -WorkingText "Obteniendo formatos" -TimeoutSec 30
    $exit1 = $obj.ExitCode
    $len1  = if ($obj.StdOut) { $obj.StdOut.Length } else { 0 }
    if ( ( $exit1 -ne $null -and $exit1 -ne 0 ) -or [string]::IsNullOrWhiteSpace($obj.StdOut)) {
        $lblEstadoConsulta.Text = "Reintentando obtención de formatos..."
        Write-Host ("[FORMATOS] Intento 1 sin JSON (ExitCode={0}, StdOutLen={1})" -f $exit1, $len1) -ForegroundColor Yellow
        if ($obj.StdErr) { Write-Host $obj.StdErr }
        $args2 = @(
            "-J","--no-playlist",
            "--ignore-config",
            "--no-warnings",
            $Url
        )
        Write-DebugLog "[FORMATOS] Intento 2: yt-dlp -J (ignore-config, sin extractor-args)" -ForegroundColor Cyan
        $obj = Invoke-CaptureResponsive -ExePath $yt.Source -Args $args2 -WorkingText "Reintentando formatos" -TimeoutSec 30
        $exit2 = $obj.ExitCode
        $len2  = if ($obj.StdOut) { $obj.StdOut.Length } else { 0 }
        if ( ( $exit2 -ne $null -and $exit2 -ne 0 ) -or [string]::IsNullOrWhiteSpace($obj.StdOut)) {
            $lblEstadoConsulta.Text = "ERROR: No se pudieron obtener formatos"
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
            Write-Host ("[ERROR] No se pudo obtener JSON de formatos ni en reintento. ExitCode={0}, StdOutLen={1}" -f $exit2, $len2) -ForegroundColor Red
            if ($obj.StdErr) { Write-Host $obj.StdErr }
            return $false
        } else {
            Write-Host ("[FORMATOS] Intento 2 OK: ExitCode={0}, StdOutLen={1}" -f $exit2, $len2) -ForegroundColor Green
        }
    }
    try {
        $lblEstadoConsulta.Text = "Procesando formatos..."
        $json = $obj.StdOut | ConvertFrom-Json
    } catch {
        $lblEstadoConsulta.Text = "ERROR: Formato JSON inválido"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
        Write-Host "`t[ERROR] JSON inválido al listar formatos." -ForegroundColor Red
        return $false
    }
    $script:lastThumbUrl = Get-BestThumbnailUrl -Json $json
    if (-not $json.formats -or $json.formats.Count -eq 0) {
        $lblEstadoConsulta.Text = "ADVERTENCIA: No se encontraron formatos"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
        Write-Host "[WARN] El extractor no devolvió lista de formatos." -ForegroundColor Yellow
        return $false
    }
    $script:lastFormats = $json.formats
    $lblEstadoConsulta.Text = "Clasificando y ordenando formatos..."
    $lblEstadoConsulta.Text = "Clasificando y ordenando formatos..."
    $videoFormats = @()
    $audioFormats = @()
    foreach ($f in $json.formats) {
        $klass = Classify-Format $f
        $script:formatsIndex[$klass.Id] = $klass
        $res   = if ($klass.VRes) { "{0}p" -f $klass.VRes } else { "" }
        $sz    = Human-Size $klass.Filesize
        $tbrStr = if ($klass.Tbr) { "{0}k" -f [math]::Round($klass.Tbr) } else { "" }
        if ($klass.Progressive -or $klass.VideoOnly) {
            $label = if ($klass.Progressive) {
                "{0} {1} {2} {3}/{4} {5} (progresivo)" -f $res, $sz, $klass.Ext, $klass.VCodec, $klass.ACodec, $tbrStr
            } else {
                "{0} {1} {2} {3} {4} (video-only)" -f $res, $sz, $klass.Ext, $klass.VCodec, $tbrStr
            }
            $videoFormats += [pscustomobject]@{
                Display = (New-FormatDisplay -Id $klass.Id -Label $label)
                Height = $klass.VRes
                Tbr = $klass.Tbr
                IsProgressive = $klass.Progressive
                Filesize = $klass.Filesize
                Id = $klass.Id
            }
        }
    elseif ($klass.AudioOnly) {
        $label = "{0} {1} {2} ~{3}k (audio-only)" -f $sz, $klass.Ext, $klass.ACodec, [math]::Round($klass.ABr)
        $audioFormats += [pscustomobject]@{
            Display = (New-FormatDisplay -Id $klass.Id -Label $label)
            ABr = $klass.ABr
            Filesize = $klass.Filesize
            Id = $klass.Id
            }
        }
    }
    $sortedVideo = $videoFormats | Sort-Object @{
        Expression = {
            $heightScore = if ($_.Height) { $_.Height } else { 0 }
            $tbrScore = if ($_.Tbr) { $_.Tbr } else { 0 }
            ($heightScore * 100000) + $tbrScore
        }
        Descending = $true
    }
    $sortedAudio = $audioFormats | Sort-Object @{
        Expression = { if ($_.ABr) { $_.ABr } else { 0 } }
        Descending = $true
    }
    $script:formatsVideo = $sortedVideo.Display
    $script:formatsAudio = $sortedAudio.Display
    $script:formatsEnumerated = ($script:formatsVideo.Count -gt 0 -or $script:formatsAudio.Count -gt 0)
    if ($json.extractor) { $script:lastExtractor = $json.extractor }
    if ($script:formatsEnumerated) {
        $lblEstadoConsulta.Text = "Formatos obtenidos y ordenados correctamente"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
        Populate-FormatCombos
    } else {
        $lblEstadoConsulta.Text = "ADVERTENCIA: No se pudieron enumerar formatos"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
    }
    return $script:formatsEnumerated
}
function Populate-FormatCombos {
    if (-not $script:lastFormats) { return }
    if ($cmbVideoFmt) { $cmbVideoFmt.Items.Clear() }
    if ($cmbAudioFmt) { $cmbAudioFmt.Items.Clear() }
    $videoItems = @()
    $audioItems = @()
    foreach ($fmt in $script:lastFormats) {
        $klass = Classify-Format $fmt
        if ($script:ExcludedFormatIds -contains $klass.Id) { continue }
        $res = if ($klass.VRes) { "{0}p" -f $klass.VRes } else { "" }
        $sz = Human-Size $klass.Filesize
        $tbrStr = if ($klass.Tbr) { "{0}k" -f [math]::Round($klass.Tbr) } else { "" }
        if ($klass.Progressive -or $klass.VideoOnly) {
            $label = if ($klass.Progressive) {
                "{0} {1} {2} {3}/{4} {5} (progresivo)" -f $res, $sz, $klass.Ext, $klass.VCodec, $klass.ACodec, $tbrStr
            } else {
                "{0} {1} {2} {3} {4} (video-only)" -f $res, $sz, $klass.Ext, $klass.VCodec, $tbrStr
            }
            $videoItems += [pscustomobject]@{
                Display = (New-FormatDisplay -Id $klass.Id -Label $label)
                Height = $klass.VRes
                Tbr = $klass.Tbr
                IsProgressive = $klass.Progressive
                Filesize = $klass.Filesize
                Id = $klass.Id
                OriginalIndex = $videoItems.Count  # Mantener orden original
            }
        }
        elseif ($klass.AudioOnly) {
            $label = "{0} {1} {2} ~{3}k (audio-only)" -f $sz, $klass.Ext, $klass.ACodec, [math]::Round($klass.ABr)
            $audioItems += [pscustomobject]@{
                Display = (New-FormatDisplay -Id $klass.Id -Label $label)
                ABr = $klass.ABr
                Filesize = $klass.Filesize
                Id = $klass.Id
                OriginalIndex = $audioItems.Count  # Mantener orden original
            }
        }
    }
    $sortedVideo = $videoItems | Sort-Object @{
        Expression = {
            $heightScore = if ($_.Height) { $_.Height } else { 0 }
            $tbrScore = if ($_.Tbr) { $_.Tbr } else { 0 }
            ($heightScore * 100000) + $tbrScore
        }
        Descending = $true
    }
    $sortedAudio = $audioItems | Sort-Object @{
        Expression = { if ($_.ABr) { $_.ABr } else { 0 } }
        Descending = $true
    }
    foreach ($item in $sortedVideo) {
        $cmbVideoFmt.Items.Add($item.Display) | Out-Null
    }
    foreach ($item in $sortedAudio) {
        $cmbAudioFmt.Items.Add($item.Display) | Out-Null
    }
    if ($cmbVideoFmt.Items.Count -gt 0) {
        $cmbVideoFmt.SelectedIndex = 0
        Write-DebugLog "[DEBUG] Video combo items: $($cmbVideoFmt.Items.Count)" -ForegroundColor Yellow
    }
    if ($cmbAudioFmt.Items.Count -gt 0) {
        $cmbAudioFmt.SelectedIndex = 0
        Write-DebugLog "[DEBUG] Audio combo items: $($cmbAudioFmt.Items.Count)" -ForegroundColor Yellow
    }
}
function Normalize-ThumbUrl {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$Extractor = $null
    )
    if ([string]::IsNullOrWhiteSpace($Url)) { return $Url }
    $u = $Url.Trim()
    return $u
}
function Get-Metadata {
    param([Parameter(Mandatory=$true)][string]$Url)

    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch { return $null }

    $obj = Invoke-CaptureResponsive -ExePath $yt.Source -Args @(
        "-J", "--no-playlist",
        $Url
    ) -WorkingText "Leyendo metadatos…"

    if ($obj.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($obj.StdOut)) { return $null }

    try { $json = $obj.StdOut | ConvertFrom-Json } catch { return $null }

    $thumb = Get-BestThumbnailUrl -Json $json
    [pscustomobject]@{
        Title      = $json.title
        Extractor  = $json.extractor         # p.ej. 'twitch', 'youtube', 'twitter', etc.
        Domain     = $json.webpage_url_domain
        Thumbnail  = $thumb
        Duration   = $json.duration
        Uploader   = $json.uploader
        Json       = $json                   # por si lo quieres reutilizar
    }
}
function Get-SelectedFormatId {
    param([System.Windows.Forms.ComboBox]$Combo)
    if (-not $Combo) { return $null }
    if (-not $Combo.SelectedItem) { return $null }
    $t = [string]$Combo.SelectedItem
    if ([string]::IsNullOrWhiteSpace($t)) { return $null }
    return ($t -split '\s')[0]
}
function Test-YouTubePlaylist {
    param([Parameter(Mandatory=$true)][string]$Url)
    return ($Url -match 'list=' -and $Url -match 'youtube\.com') -or
           ($Url -match '^https?://(www\.)?youtube\.com/playlist') -or
           ($Url -match '^https?://(www\.)?youtube\.com/watch.*list=') -or
           ($Url -match 'start_radio=1')
}
function Extract-VideoFromPlaylist {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $yt = Get-Command yt-dlp -ErrorAction Stop
        $args = @(
            "--flat-playlist",
            "--print", "url",
            "--no-warnings",
            "--playlist-items", "1",  # Solo el primer item
            $Url
        )
        $res = Invoke-Capture -ExePath $yt.Source -Args $args
        if ($res.ExitCode -eq 0 -and -not [string]::IsNullOrWhiteSpace($res.StdOut)) {
            $firstVideo = ($res.StdOut -split "`r?`n" | Where-Object { $_ -match 'watch\?v=' } | Select-Object -First 1)
            if ($firstVideo) {
                if ($firstVideo -match '^https?://') {
                    return $firstVideo.Trim()
                } else {
                    return "https://www.youtube.com/watch?v=$firstVideo"
                }
            }
        }
    } catch {
        Write-Host "[PLAYLIST] Error extrayendo video de playlist: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    return $null
}
function Create-IconButton {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Text,
        [Parameter(Mandatory = $true)]
        [System.Drawing.Point]$Location,
        [System.Drawing.Size]$Size = $(New-Object System.Drawing.Size(26, 26)),
        [string]$ToolTipText
    )
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text      = $Text
    $btn.Location  = $Location
    $btn.Size      = $Size
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 0
    $btn.FlatAppearance.MouseOverBackColor = $ColorPrimaryLight
    $btn.FlatAppearance.MouseDownBackColor = $ColorPrimaryDark
    $btn.BackColor = $ColorSurface
    $btn.ForeColor = $ColorText
    try {
        $btn.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 10, [System.Drawing.FontStyle]::Regular)
    } catch {
        $btn.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    }
    try {
        Set-RoundedRegion -Control $btn -Radius 8
    } catch {}
    if ($ToolTipText -and $script:toolTip) {
        $script:toolTip.SetToolTip($btn, $ToolTipText)
    } elseif ($ToolTipText -and $toolTip) {
        $toolTip.SetToolTip($btn, $ToolTipText)
    }
    return $btn
}
function New-LinkLabel {
    param(
        [string]$Text,
        [string]$Url,
        [System.Drawing.Point]$Location,
        [System.Drawing.Size]$Size
    )
    $ll = New-Object System.Windows.Forms.LinkLabel
    $ll.Text = $Text
    $ll.AutoSize = $false
    $ll.Location = $Location
    $ll.Size = $Size
    $ll.LinkBehavior = [System.Windows.Forms.LinkBehavior]::HoverUnderline
    [void]$ll.Links.Add(0, $Text.Length, $Url)
    $ll.add_LinkClicked({
        param($s,$e)
        try { Start-Process $e.Link.LinkData } catch {}
    })
    return $ll
}
function Refresh-DependencyLabel {
    param(
        [string]$CommandName,
        [string]$FriendlyName,
        [ref]$LabelRef,
        [string]$VersionArgs = "--version",
        [ValidateSet("FirstLine","Raw")][string]$Parse = "FirstLine"
    )
    $ver = Get-ToolVersion -Command $CommandName -ArgsForVersion $VersionArgs -Parse $Parse
    if ($ver) {
        $LabelRef.Value.Text = ("{0}: {1}" -f $FriendlyName, $ver)
        $LabelRef.Value.ForeColor = [System.Drawing.Color]::ForestGreen
    } else {
        $LabelRef.Value.Text = ("{0}: no instalado" -f $FriendlyName)
        $LabelRef.Value.ForeColor = [System.Drawing.Color]::Red
    }
    Refresh-GateByDeps   # <-- NUEVO
}
function Update-Dependency {
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
        Refresh-DependencyLabel -CommandName $CommandName -FriendlyName $FriendlyName -LabelRef $LabelRef -VersionArgs $VersionArgs -Parse $Parse
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
        Refresh-GateByDeps   # <-- re-evalúa y bloquea/habilita Consultar/Descargar
    }
}
function Uninstall-Dependency {
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
        ("¿Seguro que deseas desinstalar {0}?{1}{1}Esto podría requerir reiniciar PowerShell para refrescar el PATH." -f $FriendlyName, [Environment]::NewLine),
        "Confirmar desinstalación",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Warning
    )
    if ($r -ne [System.Windows.Forms.DialogResult]::Yes) { return }
    Write-Host ("[UNINSTALL] Desinstalando {0} con choco uninstall {1} -y" -f $FriendlyName,$ChocoPkg) -ForegroundColor Cyan
    try {
        Start-Process -FilePath "choco" -ArgumentList @("uninstall",$ChocoPkg,"-y") -Wait -NoNewWindow
        $LabelRef.Value.Text = ("{0}: no instalado" -f $FriendlyName)
        $LabelRef.Value.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show(
            ("{0} ha sido desinstalado.{1}{1}Te recomiendo cerrar y abrir PowerShell para refrescar el PATH." -f $FriendlyName,[Environment]::NewLine),
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
        Refresh-GateByDeps   # <-- re-evalúa y bloquea/habilita Consultar/Descargar
    }
}
Write-Host "[INIT] Cargando UI..." -ForegroundColor Cyan
function Check-Chocolatey {
    Write-Host "[CHECK] Verificando Chocolatey..." -ForegroundColor Cyan
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        Write-Host "[WARN] Chocolatey no encontrado." -ForegroundColor Yellow
        $response = [System.Windows.Forms.MessageBox]::Show(
            "Chocolatey no está instalado. ¿Desea instalarlo ahora?",
            "Chocolatey no encontrado",[System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($response -eq [System.Windows.Forms.DialogResult]::No) {
            Write-Host "[CANCEL] Usuario rechazó instalar Chocolatey." -ForegroundColor Red
            return $false
        }
        Write-Host "[INSTALL] Instalando Chocolatey..." -ForegroundColor Cyan
        try {
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
            iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
            Write-Host "`t[OK] Chocolatey instalado. Configurando cache..." -ForegroundColor Green
            choco config set cacheLocation C:\Choco\cache | Out-Null
            [System.Windows.Forms.MessageBox]::Show(
                "Chocolatey se instaló correctamente y ha sido configurado. Por favor, reinicie PowerShell antes de continuar.",
                "Reinicio requerido",[System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            Stop-Process -Id $PID -Force
            return $false
        } catch {
            Write-Host "`t[ERROR] Falló instalación de Chocolatey: $_" -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                "Error al instalar Chocolatey. Por favor, inténtelo manualmente.",
                "Error de instalación",[System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            return $false
        }
    } else {
        Write-Host "`t[OK] Chocolatey ya está instalado." -ForegroundColor Green
        return $true
    }
}
function Get-YouTubeVideoId {
    param([Parameter(Mandatory=$true)][string]$Url)
    $m = [regex]::Match($Url, 'youtu\.be/([A-Za-z0-9_-]{11})', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($Url, '[?&]v=([A-Za-z0-9_-]{11})', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($Url, '/shorts/([A-Za-z0-9_-]{11})', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    $m = [regex]::Match($Url, '/embed/([A-Za-z0-9_-]{11})', 'IgnoreCase')
    if ($m.Success) { return $m.Groups[1].Value }
    return $null
}
function Get-CurrentUrl {
    if (-not $txtUrl) { return "" }
    $t = ($txtUrl.Text).Trim()
    if ($t -eq $global:UrlPlaceholder) { return "" }
    return $t
}
function New-HttpClient {
    return $null
}
function Get-ImageFromUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    $cleanUrl = $Url -replace '\?.*$', ''
    if ($cleanUrl -ne $Url) {
        Write-Host "`t[IMAGEN] URL limpiada: $cleanUrl" -ForegroundColor Yellow
    }
    try {
        Write-Host "`t[IMAGEN] Descargando: $cleanUrl" -ForegroundColor Cyan
        Add-Type -AssemblyName System.Net.Http
        $handler = New-Object System.Net.Http.HttpClientHandler
        $httpClient = New-Object System.Net.Http.HttpClient($handler)
        $httpClient.DefaultRequestHeaders.Add("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.124 Safari/537.36")
        $httpClient.DefaultRequestHeaders.Add("Accept", "image/webp,image/apng,image/*,*/*;q=0.8")
        $httpClient.DefaultRequestHeaders.Add("Referer", "https://www.tiktok.com/")
        $httpClient.DefaultRequestHeaders.Add("Sec-Fetch-Dest", "image")
        $httpClient.DefaultRequestHeaders.Add("Sec-Fetch-Mode", "no-cors")
        $httpClient.DefaultRequestHeaders.Add("Sec-Fetch-Site", "cross-site")
        $httpClient.Timeout = [System.TimeSpan]::FromSeconds(10)
        $response = $httpClient.GetAsync($cleanUrl).Result
        if ($response.IsSuccessStatusCode) {
            $stream = $response.Content.ReadAsStreamAsync().Result
            $image = [System.Drawing.Image]::FromStream($stream)
            $httpClient.Dispose()
            Write-Host "`t[IMAGEN] Descarga exitosa: $($image.Width)x$($image.Height)" -ForegroundColor Green
            return $image
        } else {
            Write-Host "`t[IMAGEN] Error HTTP: $($response.StatusCode) - $($response.ReasonPhrase)" -ForegroundColor Red
            $httpClient.Dispose()
            return $null
        }
    } catch {
        Write-Host "`t[IMAGEN] Error con HttpClient: $($_.Exception.Message)" -ForegroundColor Red
        try { $httpClient.Dispose() } catch {}
        return $null
    }
}
function Get-TempThumbPattern {
    $tmp = [System.IO.Path]::GetTempPath()
    return (Join-Path $tmp "ytdll_thumb_*")
}
function Get-ThumbnailListFromYtDlp {
    param([Parameter(Mandatory = $true)][string]$Url)
    try {
        $yt = Get-Command yt-dlp -ErrorAction Stop
    } catch {
        Write-Host "`t[THUMB] yt-dlp no disponible para listar thumbnails." -ForegroundColor Red
        return @()
    }
    $res = Invoke-Capture -ExePath $yt.Source -Args @("--list-thumbnails", $Url)
    if ($res.ExitCode -ne 0 -or [string]::IsNullOrWhiteSpace($res.StdOut)) {
        Write-Host "`t[THUMB] --list-thumbnails devolvió error o salida vacía." -ForegroundColor Yellow
        return @()
    }
    $lines = $res.StdOut -split "`r?`n"
    $startIndex = -1
    for ($i = 0; $i -lt $lines.Length; $i++) {
        if ($lines[$i] -match '^\s*ID\s+Width\s+Height\s+URL') {
            $startIndex = $i + 1
            break
        }
    }
    if ($startIndex -lt 0) {
        Write-Host "`t[THUMB] No se encontró encabezado de tabla de thumbnails." -ForegroundColor Yellow
        return @()
    }
    $thumbs = @()
    for ($i = $startIndex; $i -lt $lines.Length; $i++) {
        $line = $lines[$i].Trim()
        if (-not $line) { continue }
        $m = [regex]::Match($line, '^\s*(\S+)\s+(\S+)\s+(\S+)\s+(\S+)\s*$')
        if (-not $m.Success) { continue }
        $id     = $m.Groups[1].Value
        $width  = $m.Groups[2].Value
        $height = $m.Groups[3].Value
        $url    = $m.Groups[4].Value
        if ($url -match '\.webp($|\?)|vi_webp') {
            continue
        }
        if ($url -notmatch '\.jpg($|\?)') {
            continue
        }
        $wInt = 0; $hInt = 0
        [void][int]::TryParse($width,  [ref]$wInt)
        [void][int]::TryParse($height, [ref]$hInt)
        $thumbs += [pscustomobject]@{
            Id     = $id
            Width  = $wInt
            Height = $hInt
            Url    = $url
        }
    }
    Write-Host "`t[THUMB] Encontradas $($thumbs.Count) miniaturas JPG" -ForegroundColor Cyan

    if (-not $thumbs -or $thumbs.Count -eq 0) {
        Write-Host "`t[THUMB] No se encontraron miniaturas JPG." -ForegroundColor Yellow
        return @()
    }
    return $thumbs
}
function Select-BestThumbnail {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Thumbs
    )
    if (-not $Thumbs -or $Thumbs.Count -eq 0) { return $null }
    $ranked = $Thumbs | ForEach-Object {
        $w = if ($_.Width  -gt 0) { $_.Width }  else { 0 }
        $h = if ($_.Height -gt 0) { $_.Height } else { 0 }
        $area = [math]::Max($w * $h, 1)
        $idNum = 0
        [void][int]::TryParse($_.Id, [ref]$idNum)
        [pscustomobject]@{
            Thumb   = $_
            Area    = $area
            IdNum   = $idNum
        }
    }
    $best = $ranked |
        Sort-Object @{Expression = "Area"; Descending = $true}, @{Expression = "IdNum"; Descending = $true} |
        Select-Object -First 1
    Write-Host "`t[THUMB] Mejor miniatura seleccionada: $($best.Thumb.Url)" -ForegroundColor Green
    return $best.Thumb
}
function Fetch-ThumbnailFile {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $yt = Get-Command yt-dlp -ErrorAction Stop
    } catch {
        Write-Host "`t[ERROR] yt-dlp no disponible para descargar miniatura" -ForegroundColor Red
        return $null
    }
        if (-not (Test-Path $script:ThumbnailsDir)) {
            New-Item -ItemType Directory -Path $script:ThumbnailsDir -Force | Out-Null
        }
        Get-ChildItem -Path (Get-TempThumbPattern) -ErrorAction SilentlyContinue | Remove-Item -Force -ErrorAction SilentlyContinue
        $outTmpl = Join-Path $script:ThumbnailsDir "ytdll_thumb_%(id)s.%(ext)s"
    $args = @(
        "--skip-download",
        "--quiet",
        "--no-warnings",
        "--write-thumbnail",
        "--convert-thumbnails", "jpg",
        "-o", $outTmpl,
        "--no-playlist"  # Importante para playlists
    )
    if ($Url -match 'youtube\.com.*list=') {
        $args += "--playlist-items", "1"
    }
    if ($script:cookiesPath) {
        $args += @("--cookies", $script:cookiesPath)
    }
    $args += $Url
    Write-Host "`t[THUMB] Ejecutando yt-dlp para obtener miniatura..." -ForegroundColor Cyan
    $res = Invoke-Capture -ExePath $yt.Source -Args $args
    if ($res.ExitCode -ne 0) {
        Write-DebugLog "`t[THUMB] Error al obtener miniatura (ExitCode: $($res.ExitCode))" -ForegroundColor Red
        if (-not [string]::IsNullOrWhiteSpace($res.StdErr)) {
            Write-DebugLog "`t[THUMB] Error details: $($res.StdErr)" -ForegroundColor Red
        }
        if ($Url -match 'youtube\.com.*list=') {
            Write-Host "`t[THUMB] Intentando método alternativo para playlist..." -ForegroundColor Yellow
            return $null  # Dejar que Show-PreviewUniversal use otros métodos
        }
    }
    $thumb = Get-ChildItem -Path (Join-Path $script:ThumbnailsDir "ytdll_thumb_*") -ErrorAction SilentlyContinue |
                 Sort-Object LastWriteTime -Descending |
                 Select-Object -First 1
    if ($thumb) {
        Write-Host "`t[THUMB] Miniatura descargada: $($thumb.FullName)" -ForegroundColor Green
        return $thumb.FullName
    } else {
        Write-Host "`t[THUMB] No se pudo descargar miniatura con yt-dlp" -ForegroundColor Red
        return $null
    }
}
function Get-TempThumbPattern {
    $tmp = [System.IO.Path]::GetTempPath()
    return (Join-Path $tmp "ytdll_thumb_*")
}
function Show-PreviewUniversal {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$Titulo = $null,
        [string]$DirectThumbUrl = $null
    )
    Write-DebugLog "[VISTA PREVIA] Intentando vista previa para: $Url" -ForegroundColor Cyan
    $lblEstadoConsulta.Text = "Obteniendo miniaturas..."
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
    Write-DebugLog "`t[VISTA PREVIA] Intentando descargar miniatura con yt-dlp..." -ForegroundColor Yellow
    $thumbFile = Fetch-ThumbnailFile -Url $Url
    if ($thumbFile -and (Test-Path $thumbFile)) {
        try {
            if ($picPreview.Image) { $picPreview.Image.Dispose() }
            $imgW = [System.Drawing.Image]::FromFile($thumbFile)
            $picPreview.Image = $imgW
            if ($Titulo) { $toolTip.SetToolTip($picPreview, $Titulo) }
            $lblEstadoConsulta.Text = "Vista previa cargada"
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
            Write-DebugLog "`t[VISTA PREVIA] Vista previa cargada desde yt-dlp" -ForegroundColor Green
            Start-Job -ScriptBlock {
                param($file)
                Start-Sleep -Seconds 5
                try { Remove-Item $file -Force -ErrorAction SilentlyContinue } catch {}
            } -ArgumentList $thumbFile | Out-Null

            return $true
        } catch {
            Write-Host "`t[VISTA PREVIA] Error al cargar miniatura descargada: $($_.Exception.Message)" -ForegroundColor Red
        }
    }
    Write-DebugLog "`t[VISTA PREVIA] Intentando obtener thumbnails con --list-thumbnails..." -ForegroundColor Yellow
    $thumbList = Get-ThumbnailListFromYtDlp -Url $Url
    if ($thumbList -and $thumbList.Count -gt 0) {
        $lblEstadoConsulta.Text = "Probando miniaturas..."
        $sortedThumbs = $thumbList | Sort-Object @{Expression = { $_.Width * $_.Height }; Descending = $true } | Select-Object -First 3
        $thumbIndex = 1
        foreach ($thumb in $sortedThumbs) {
            $lblEstadoConsulta.Text = "Probando miniatura $thumbIndex de 3..."
            Write-DebugLog "`t[VISTA PREVIA] Probando miniatura: $($thumb.Url)" -ForegroundColor Cyan
            if (Show-PreviewImage -ImageUrl $thumb.Url -Titulo $Titulo) {
                $lblEstadoConsulta.Text = "Vista previa cargada"
                $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
                Write-DebugLog "`t[VISTA PREVIA] Vista previa cargada desde --list-thumbnails" -ForegroundColor Green
                return $true
            } else {
                Write-Host "`t[VISTA PREVIA] Falló miniatura, probando siguiente..." -ForegroundColor Yellow
            }
            $thumbIndex++
        }
        Write-Host "`t[VISTA PREVIA] Todas las miniaturas JPG fallaron" -ForegroundColor Red
    }
    $lblEstadoConsulta.Text = "Usando método alternativo..."
    Write-DebugLog "`t[VISTA PREVIA] Usando fallback con miniatura directa..." -ForegroundColor Yellow
    if ($DirectThumbUrl -and (Show-PreviewImage -ImageUrl $DirectThumbUrl -Titulo $Titulo)) {
        $lblEstadoConsulta.Text = "Vista previa cargada"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
        Write-DebugLog "`t[VISTA PREVIA] Vista previa cargada (directa)" -ForegroundColor Green
        return $true
    }
    $lblEstadoConsulta.Text = "No se pudo cargar vista previa"
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
    Write-Host "`t[VISTA PREVIA] Todos los métodos fallaron, sin vista previa" -ForegroundColor Red
    return $false
}
function Show-PreviewImage {
    param(
        [Parameter(Mandatory=$true)][string]$ImageUrl,
        [string]$Titulo = $null
    )
    try {
        if ($ImageUrl -match '\.webp($|\?)') {
            Write-Host "`t[VISTA PREVIA] Detectado WEBP, intentando conversión..." -ForegroundColor Yellow
            $png = Convert-WebpUrlToPng -Url $ImageUrl
            if ($png -and (Test-Path $png)) {
                try {
                    if ($picPreview.Image) { $picPreview.Image.Dispose() }
                } catch {}
                $imgW = [System.Drawing.Image]::FromFile($png)
                $picPreview.Image = $imgW
                if ($Titulo) { $toolTip.SetToolTip($picPreview, $Titulo) }
                Start-Sleep -Seconds 2
                try { Remove-Item $png -Force -ErrorAction SilentlyContinue } catch {}
                return $true
            }
            return $false
        }
        $img = Get-ImageFromUrl -Url $ImageUrl
        if ($img) {
            try {
                if ($picPreview.Image) { $picPreview.Image.Dispose() }
            } catch {}
            $picPreview.Image = $img
            if ($Titulo) { $toolTip.SetToolTip($picPreview, $Titulo) }
            return $true
        }
        return $false
    } catch {
        Write-Host "`t[VISTA PREVIA] Error en Show-PreviewImage: $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}
function Get-ImageFromUrlFallback {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        Write-Host `t"[IMAGE-FALLBACK] Intentando con Invoke-WebRequest: $Url" -ForegroundColor Cyan
        $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 10
        $bytes = $response.Content
        if ($bytes -and $bytes.Length -gt 0) {
            Write-Host "`t[IMAGE-FALLBACK] Descargados $($bytes.Length) bytes" -ForegroundColor Green
            $ms = New-Object System.IO.MemoryStream(,$bytes)
            return [System.Drawing.Image]::FromStream($ms)
        }
        return $null
    } catch {
        Write-Host "[IMAGE-FALLBACK] Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
}
function Get-BestThumbnailUrl {
    param([Parameter(Mandatory=$true)]$Json)
    $candidate = $null
    if ($Json.thumbnail -and -not [string]::IsNullOrWhiteSpace($Json.thumbnail)) {
        $candidate = [string]$Json.thumbnail
    }
    if (-not $candidate -and $Json.thumbnails -and $Json.thumbnails.Count -gt 0) {
        $ordered = $Json.thumbnails | Sort-Object @{Expression='preference';Descending=$true}, @{Expression='width';Descending=$true}
                $thumbNonWebp = $ordered | Where-Object { $_.url -and ($_.url -notmatch '\.webp($|\?)') } | Select-Object -First 1
        if ($thumbNonWebp -and $thumbNonWebp.url) { $candidate = [string]$thumbNonWebp.url }
        if (-not $candidate) {
            $thumb = $ordered | Select-Object -First 1
            if ($thumb -and $thumb.url) { $candidate = [string]$thumb.url }
        }
    }
    if ($candidate) {
        $candidate = Normalize-ThumbUrl -Url $candidate -Extractor $Json.extractor
    }

    return $candidate
}
function Get-BestStreamUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch { return $null }
    $args = @("-g","-f","best",$Url)
    if ($script:cookiesPath) { $args += @("--cookies",$script:cookiesPath) }
    $res = Invoke-Capture -ExePath $yt.Source -Args $args
    if ($res.ExitCode -ne 0) { return $null }
    $line = ($res.StdOut -split "`r?`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
    return ([string]$line).Trim()
}
function Build-PreviewFromStream {
    param(
        [Parameter(Mandatory=$true)][string]$StreamUrl,
        [int]$SeekSec = 2
    )
    try { $ff = (Get-Command ffmpeg -ErrorAction Stop).Source } catch { return $null }
    $tmp = Join-Path ([IO.Path]::GetTempPath()) ("ytdll_snap_{0}.jpg" -f ([guid]::NewGuid()))
    $args = @(
        "-y","-hide_banner","-loglevel","error",
        "-ss", $SeekSec.ToString(),
        "-i", $StreamUrl,
        "-frames:v","1",
        "-vf","scale=1280:-2",
        $tmp
    )
    $env:FFREPORT=""
    $p = Start-Process -FilePath $ff -ArgumentList $args -NoNewWindow -Wait -PassThru
    if ($p.ExitCode -eq 0 -and (Test-Path $tmp)) { return $tmp }
    return $null
}
function Invoke-ConsultaFromUI {
    param([Parameter(Mandatory = $true)][string]$Url)
    $script:originalUrl = $Url
    $script:isPlaylist = Test-YouTubePlaylist -Url $Url
    if ($script:isPlaylist) {
        Write-Host "[CONSULTA] Detectada playlist de YouTube, extrayendo primer video..." -ForegroundColor Yellow
        $lblEstadoConsulta.Text = "Playlist detectada, extrayendo primer video..."
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
        [System.Windows.Forms.Application]::DoEvents()

        $singleVideoUrl = Extract-VideoFromPlaylist -Url $Url
        if ($singleVideoUrl) {
            Write-Host "[CONSULTA] Usando video individual para previsualización: $singleVideoUrl" -ForegroundColor Green
            $Url = $singleVideoUrl
            $txtUrl.Text = $singleVideoUrl
            $txtUrl.ForeColor = [System.Drawing.Color]::Black
        } else {
            $lblEstadoConsulta.Text = "ADVERTENCIA: No se pudo extraer video individual"
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
            [System.Windows.Forms.MessageBox]::Show(
                "No se pudo extraer un video individual de la playlist. Se intentará con la URL completa pero puede descargar toda la playlist.",
                "Advertencia de playlist",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        }
    }
    Write-Host ("`n`n[CONSULTA] Consultando URL: {0}" -f $Url) -ForegroundColor Cyan
    try {
        $yt = Get-Command yt-dlp -ErrorAction Stop
    } catch {
        $lblEstadoConsulta.Text = "ERROR: yt-dlp no disponible"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
        [System.Windows.Forms.MessageBox]::Show(
            "yt-dlp no está disponible en el PATH. Verifícalo en la sección de Dependencias.",
            "yt-dlp no encontrado",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return $false
    }
    $btnDescargar.Enabled = $false
    $txtUrl.Enabled = $false
    if ($script:ultimaURL -ne $Url) {
        $script:videoConsultado = $false
        $script:formatsEnumerated = $false
    }
    $args = @(
        "--no-playlist",
        "--no-warnings",
        "--ignore-config",
        "--print", "title",
        "--print", "thumbnail",
        "--print", "id",
        $Url
    )
    $lblEstadoConsulta.Text = "Consultando video..."
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
    [System.Windows.Forms.Application]::DoEvents()
    $res = Invoke-CaptureResponsive -ExePath $yt.Source -Args $args -WorkingText "Consultando video" -TimeoutSec 30
    Write-DebugLog "[DEBUG] yt-dlp ExitCode: $($res.ExitCode)" -ForegroundColor Yellow
    if ([string]::IsNullOrWhiteSpace($res.StdOut)) {
        Write-DebugLog "[DEBUG] StdOut está vacío o nulo" -ForegroundColor Red
        if (-not [string]::IsNullOrWhiteSpace($res.StdErr)) {
            Write-DebugLog "[DEBUG] StdErr: $($res.StdErr)" -ForegroundColor Red
        }
    }
    $lines = @()
    if (-not [string]::IsNullOrWhiteSpace($res.StdOut)) {
        $lines = $res.StdOut -split "`r?`n" | Where-Object { $_.Trim() -ne "" }
    }
    $hasValidData = ($lines.Count -ge 3) -and (-not [string]::IsNullOrWhiteSpace($lines[0]))
    if ($res.ExitCode -eq 0 -or $hasValidData) {
        $title = if ($lines.Count -gt 0) { $lines[0] } else { "Título no disponible" }
        $thumbUrl = if ($lines.Count -gt 1) { $lines[1] } else { $null }
        $videoId = if ($lines.Count -gt 2) { $lines[2] } else { $null }
        $script:videoConsultado = $true
        $script:ultimaURL = $Url
        $script:ultimoTitulo = $title
        $script:lastThumbUrl = $thumbUrl
        $script:formatsEnumerated = $false
        $lblEstadoConsulta.Text = "Consulta OK: `"$title`""
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
        Write-Host "`t[CONSULTA] Título: $title" -ForegroundColor Green
 #       Write-Host "[CONSULTA] Thumbnail: $thumbUrl" -ForegroundColor Green
 #       Write-Host "[CONSULTA] Video ID: $videoId" -ForegroundColor Green
        $lblEstadoConsulta.Text = "Cargando vista previa..."
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
        [System.Windows.Forms.Application]::DoEvents()
        Show-PreviewUniversal -Url $Url -Titulo $title -DirectThumbUrl $thumbUrl
        $lblEstadoConsulta.Text = "Obteniendo formatos..."
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
        [System.Windows.Forms.Application]::DoEvents()
        $fmtOk = Fetch-Formats -Url $Url
        if ($fmtOk -and $script:lastFormats) {
            Print-FormatsTable -formats $script:lastFormats
        }
        $btnDescargar.Enabled = $true
        $txtUrl.Enabled = $true
        Set-DownloadButtonVisual
        if ($fmtOk) {
            $lblEstadoConsulta.Text = "Consulta completada - Listo para descargar"
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
        } else {
            $lblEstadoConsulta.Text = "Consulta completada (sin formatos)"
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
        }
        return $true
    }
    else {
        $script:videoConsultado = $false
        $script:ultimaURL = $null
        $script:ultimoTitulo = $null
        $script:formatsEnumerated = $false
        $lblEstadoConsulta.Text = "Error al consultar la URL"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
        $picPreview.Image = $null
        $btnDescargar.Enabled = $true
        $txtUrl.Enabled = $true
        $errorMsg = "yt-dlp devolvió error al consultar la URL. Verifica que la URL sea válida."
        if (-not [string]::IsNullOrWhiteSpace($res.StdErr)) {
            $errorMsg += "`n`nError: $($res.StdErr)"
        }
        [System.Windows.Forms.MessageBox]::Show(
            $errorMsg,
            "Error en consulta",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null

        Write-Host "`t[ERROR] No se pudo consultar el video. ExitCode: $($res.ExitCode)" -ForegroundColor Red
        if (-not [string]::IsNullOrWhiteSpace($res.StdErr)) {
            Write-Host "`t[ERROR] StdErr: $($res.StdErr)" -ForegroundColor Red
        }
        Set-DownloadButtonVisual
        return $false
    }
}
function Start-ThumbnailAndFormatsLoad {
    param([string]$Url, [string]$Title)
    $lblEstadoConsulta.Text = "Cargando vista previa..."
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
    [System.Windows.Forms.Application]::DoEvents()
    $thumbJob = Start-Job -ScriptBlock {
        param($Url, $Title, $LastThumbUrl)
        Add-Type -AssemblyName System.Windows.Forms
        Add-Type -AssemblyName System.Drawing
        try {
            $yt = Get-Command yt-dlp -ErrorAction Stop
            $args = @("-J", "--no-playlist", $Url)
            $res = & $yt.Source $args 2>$null
            if ($res) {
                $json = $res | ConvertFrom-Json
                $thumbUrl = $json.thumbnail
                return @{ Success = $true; ThumbUrl = $thumbUrl }
            }
        } catch {
            return @{ Success = $false }
        }
    } -ArgumentList $Url, $Title, $script:lastThumbUrl
    $timer2 = New-Object System.Windows.Forms.Timer
    $timer2.Interval = 100
    $timer2.Add_Tick({
        if ($thumbJob.State -eq 'Completed') {
            $timer2.Stop()
            $thumbResult = Receive-Job -Job $thumbJob
            Remove-Job -Job $thumbJob
            if ($thumbResult.Success -and $thumbResult.ThumbUrl) {
                try {
                    Show-PreviewUniversal -Url $Url -Titulo $Title -DirectThumbUrl $thumbResult.ThumbUrl
                } catch {
                }
            }
            Start-FormatsLoad -Url $Url
        }
    })
    $timer2.Start()
}
function Start-FormatsLoad {
    param([string]$Url)
    $lblEstadoConsulta.Text = "Obteniendo formatos..."
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
    [System.Windows.Forms.Application]::DoEvents()
    $formatsJob = Start-Job -ScriptBlock {
        param($Url)
        try {
            $yt = Get-Command yt-dlp -ErrorAction Stop
            $args = @("-J", "--no-playlist", $Url)
            $res = & $yt.Source $args 2>$null
            return @{ Success = $true; HasFormats = ($res -ne $null) }
        } catch {
            return @{ Success = $false }
        }
    } -ArgumentList $Url
    $timer3 = New-Object System.Windows.Forms.Timer
    $timer3.Interval = 100
    $timer3.Add_Tick({
        if ($formatsJob.State -eq 'Completed') {
            $timer3.Stop()
            $formatsResult = Receive-Job -Job $formatsJob
            Remove-Job -Job $formatsJob
            $btnDescargar.Enabled = $true
            $txtUrl.Enabled = $true
            if ($formatsResult.Success -and $formatsResult.HasFormats) {
                $lblEstadoConsulta.Text = "Consulta completada - Listo para descargar"
                $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
                $fmtOk = Fetch-Formats -Url $Url
                if ($fmtOk) {
                    Populate-FormatCombos
                }
            } else {
                $lblEstadoConsulta.Text = "Consulta completada (sin formatos)"
                $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
            }
            Set-DownloadButtonVisual
        }
    })
    $timer3.Start()
}
function Get-ToolVersion {
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [string]$ArgsForVersion="--version",
        [ValidateSet("FirstLine","Raw")][string]$Parse="FirstLine"
    )
    try { $cmd = Get-Command $Command -ErrorAction Stop } catch { return $null }
    try {
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $p.StartInfo.FileName = $cmd.Source
        $p.StartInfo.Arguments = $ArgsForVersion
        $p.StartInfo.RedirectStandardOutput = $true
        $p.StartInfo.RedirectStandardError  = $true
        $p.StartInfo.UseShellExecute = $false
        $p.StartInfo.CreateNoWindow  = $true
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
function Ensure-Tool {
    param(
        [Parameter(Mandatory=$true)][string]$CommandName,
        [Parameter(Mandatory=$true)][string]$FriendlyName,
        [Parameter(Mandatory=$true)][string]$ChocoPkg,
        [Parameter(Mandatory=$true)][ref]$LabelRef,
        [string]$VersionArgs="--version",
        [ValidateSet("FirstLine","Raw")][string]$Parse="FirstLine"
    )
    Write-Host ("[CHECK] Verificando {0}..." -f $FriendlyName) -ForegroundColor Cyan
    $version = Get-ToolVersion -Command $CommandName -ArgsForVersion $VersionArgs -Parse $Parse
    if (-not $version) {
        Write-Host ("[WARN] {0} no encontrado." -f $FriendlyName) -ForegroundColor Yellow
        $resp = [System.Windows.Forms.MessageBox]::Show(
            ("{0} no está instalado. ¿Desea instalarlo ahora con Chocolatey?" -f $FriendlyName),
            ("{0} no encontrado" -f $FriendlyName),
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($resp -ne [System.Windows.Forms.DialogResult]::Yes) {
            $LabelRef.Value.Text = ("{0}: no instalado" -f $FriendlyName)
            $LabelRef.Value.ForeColor = [System.Drawing.Color]::Red
            Write-Host ("[CANCEL] Usuario omitió instalación de {0}." -f $FriendlyName) -ForegroundColor Yellow
            return
        }
        Write-Host ("[INSTALL] Instalando {0} con choco install {1} -y" -f $FriendlyName,$ChocoPkg) -ForegroundColor Cyan
        try {
            Start-Process -FilePath "choco" -ArgumentList @("install",$ChocoPkg,"-y") -NoNewWindow -Wait
            $version = Get-ToolVersion -Command $CommandName -ArgsForVersion $VersionArgs -Parse $Parse
            if ($version) {
                $LabelRef.Value.Text = ("{0}: {1}" -f $FriendlyName,$version)
                $LabelRef.Value.ForeColor = [System.Drawing.Color]::ForestGreen
                Write-Host ("`t[OK] {0} instalado: {1}" -f $FriendlyName,$version) -ForegroundColor Green
                [System.Windows.Forms.MessageBox]::Show(
                    ("{0} se instaló correctamente.`n`nPara que el PATH y las variables se apliquen, cierre y vuelva a abrir PowerShell.`nLa aplicación se cerrará ahora." -f $FriendlyName),
                    "Reinicio de PowerShell requerido",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Information
                ) | Out-Null
                try { $formPrincipal.Close(); $formPrincipal.Dispose() } catch {}
                Stop-Process -Id $PID -Force
            }
            else {
                $LabelRef.Value.Text = ("{0}: Instalado (reinicie PowerShell)" -f $FriendlyName)
                $LabelRef.Value.ForeColor = [System.Drawing.Color]::DarkOrange
                Write-Host ("[WARN] {0} instalado, pero versión no detectada. Requiere reinicio de PowerShell." -f $FriendlyName) -ForegroundColor Yellow
                [System.Windows.Forms.MessageBox]::Show(
                    ("{0} parece haberse instalado, pero no se pudo leer la versión inmediatamente.`n`nCierre y vuelva a abrir PowerShell.`nLa aplicación se cerrará ahora." -f $FriendlyName),
                    "Reinicio de PowerShell requerido",
                    [System.Windows.Forms.MessageBoxButtons]::OK,
                    [System.Windows.Forms.MessageBoxIcon]::Warning
                ) | Out-Null
                try { $formPrincipal.Close(); $formPrincipal.Dispose() } catch {}
                Stop-Process -Id $PID -Force
            }
        } catch {
            $LabelRef.Value.Text = ("{0}: error al instalar" -f $FriendlyName)
            $LabelRef.Value.ForeColor = [System.Drawing.Color]::Red
            Write-Host ("[ERROR] Falló instalación de {0}: {1}" -f $FriendlyName,$_ ) -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                ("No se pudo instalar {0} automáticamente.`nRevise la conexión o intente manualmente." -f $FriendlyName),
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    }
    else {
        $LabelRef.Value.Text = ("{0}: {1}" -f $FriendlyName,$version)
        $LabelRef.Value.ForeColor = [System.Drawing.Color]::ForestGreen
        Write-Host ("`t[OK] {0} detectado: {1}" -f $FriendlyName,$version) -ForegroundColor Green
    }
}
function Ensure-ToolHeadless {
    param(
        [Parameter(Mandatory=$true)][string]$CommandName,
        [Parameter(Mandatory=$true)][string]$FriendlyName,
        [Parameter(Mandatory=$true)][string]$ChocoPkg,
        [string]$VersionArgs="--version",
        [ValidateSet("FirstLine","Raw")][string]$Parse="FirstLine"
    )
    Write-Host ("[CHECK] (headless) Verificando {0}..." -f $FriendlyName) -ForegroundColor Cyan
    $version = Get-ToolVersion -Command $CommandName -ArgsForVersion $VersionArgs -Parse $Parse
    if (-not $version) {
        Write-Host ("[WARN] {0} no encontrado." -f $FriendlyName) -ForegroundColor Yellow
        $resp = [System.Windows.Forms.MessageBox]::Show(
            ("{0} no está instalado. ¿Desea instalarlo ahora con Chocolatey?" -f $FriendlyName),
            ("{0} no encontrado" -f $FriendlyName),
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Question
        )
        if ($resp -ne [System.Windows.Forms.DialogResult]::Yes) {
            Write-Host ("[CANCEL] Usuario omitió instalación de {0}." -f $FriendlyName) -ForegroundColor Yellow
            return $false
        }
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Chocolatey no está disponible. Instálalo para continuar.",
                "Chocolatey requerido",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return $false
        }
        Write-Host ("[INSTALL] (headless) choco install {0} -y" -f $ChocoPkg) -ForegroundColor Cyan
        try {
            Start-Process -FilePath "choco" -ArgumentList @("install",$ChocoPkg,"-y") -NoNewWindow -Wait
        } catch {
            Write-Host ("[ERROR] Falló instalación de {0}: {1}" -f $FriendlyName,$_ ) -ForegroundColor Red
            [System.Windows.Forms.MessageBox]::Show(
                ("No se pudo instalar {0} automáticamente." -f $FriendlyName),
                "Error",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            return $false
        }
        $version = Get-ToolVersion -Command $CommandName -ArgsForVersion $VersionArgs -Parse $Parse
        if (-not $version) {
            [System.Windows.Forms.MessageBox]::Show(
                ("{0} fue instalado. Cierre y vuelva a abrir PowerShell para refrescar el PATH. La aplicación se cerrará." -f $FriendlyName),
                "Reinicio de PowerShell requerido",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            Stop-Process -Id $PID -Force
            return $false
        }
    }
    Write-Host ("`t[OK] {0} detectado." -f $FriendlyName) -ForegroundColor Green
    return $true
}
function Test-DotNet6DesktopRuntime {
    try {
        $cmd = Get-Command dotnet -ErrorAction Stop
    } catch {
        return $false
    }

    try {
        $p = New-Object System.Diagnostics.Process
        $p.StartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $p.StartInfo.FileName = $cmd.Source
        $p.StartInfo.Arguments = "--list-runtimes"
        $p.StartInfo.RedirectStandardOutput = $true
        $p.StartInfo.RedirectStandardError  = $true
        $p.StartInfo.UseShellExecute = $false
        $p.StartInfo.CreateNoWindow  = $true
        [void]$p.Start()
        $stdout = $p.StandardOutput.ReadToEnd()
        $stderr = $p.StandardError.ReadToEnd()
        $p.WaitForExit()

        $out = ($stdout + "`n" + $stderr)

        if ($out -match 'Microsoft\.NETCore\.App\s+6\.' -or
            $out -match 'Microsoft\.WindowsDesktop\.App\s+6\.') {
            return $true
        }

        return $false
    } catch {
        return $false
    }
}
function Ensure-DotNet6DesktopRuntime {
    Write-Host "[CHECK] Verificando .NET 6 Desktop Runtime..." -ForegroundColor Cyan
    if (Test-DotNet6DesktopRuntime) {
        Write-Host "`t[OK] .NET 6 Desktop Runtime ya está disponible." -ForegroundColor Green
        return $true
    }
    Write-Host "[WARN] .NET 6 Desktop Runtime no detectado." -ForegroundColor Yellow
    if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
        [System.Windows.Forms.MessageBox]::Show(
            ".NET 6 Desktop Runtime es obligatorio para mpv.net, pero Chocolatey no está disponible." + `
            "`nInstálalo manualmente desde el sitio de Microsoft o instala Chocolatey.",
            ".NET 6 requerido",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        ) | Out-Null
        return $false
    }
    $resp = [System.Windows.Forms.MessageBox]::Show(
        "Es necesario instalar Microsoft .NET 6 Desktop Runtime para reproducir videos con mpv.net." + `
        "`n¿Deseas instalarlo ahora con Chocolatey (dotnet-6.0-desktopruntime)?",
        ".NET 6 Desktop Runtime requerido",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    if ($resp -ne [System.Windows.Forms.DialogResult]::Yes) {
        Write-Host "[CANCEL] Usuario canceló instalación de .NET 6 Desktop Runtime." -ForegroundColor Yellow
        return $false
    }
    Write-Host "[INSTALL] Instalando .NET 6 Desktop Runtime (choco install dotnet-6.0-desktopruntime -y)..." -ForegroundColor Cyan
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
        ".NET 6 Desktop Runtime se instaló, pero no pudo ser detectado de inmediato." + `
        "`nReinicia PowerShell y vuelve a ejecutar la aplicación.",
        "Reinicio requerido",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    ) | Out-Null
    Stop-Process -Id $PID -Force
    return $false
}
function Ensure-MpvNetOptional {
    if (-not (Ensure-DotNet6DesktopRuntime)) {
        return $false
    }
    return (Ensure-ToolHeadless `
        -CommandName "mpvnet" `
        -FriendlyName "mpv.net" `
        -ChocoPkg "mpv.net" `
        -VersionArgs "--version")
}
function Get-DisplayUrl {
    param([string]$Url)
    if ([string]::IsNullOrWhiteSpace($Url)) { return $Url }
    $u = $Url.Trim()
    $u = $u -replace '^https?://', ''
    $u = $u -replace '^www\.', ''
    return $u
}
$mpvnetInstalled = Test-CommandExists -Name "mpvnet"
if ($mpvnetInstalled) {     $mpvnetVersion = Get-ToolVersion -Command "mpvnet" -ArgsForVersion "--version" -Parse "FirstLine" }
function Initialize-AppHeadless {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing
    [System.Windows.Forms.Application]::EnableVisualStyles()
    function Set-RoundedRegion {
        param(
            [Parameter(Mandatory = $true)]
            [System.Windows.Forms.Control]$Control,
            [int]$Radius = 10
        )
        if ($Radius -lt 1 -or -not $Control.Width -or -not $Control.Height) { return }
        $rect = New-Object System.Drawing.Rectangle(0, 0, $Control.Width, $Control.Height)
        $path = New-Object System.Drawing.Drawing2D.GraphicsPath
        $diam = $Radius * 2
        $path.AddArc($rect.X, $rect.Y, $diam, $diam, 180, 90)
        $path.AddArc($rect.Right - $diam, $rect.Y, $diam, $diam, 270, 90)
        $path.AddArc($rect.Right - $diam, $rect.Bottom - $diam, $diam, $diam, 0, 90)
        $path.AddArc($rect.X, $rect.Bottom - $diam, $diam, $diam, 90, 90)
        $path.CloseFigure()
        $Control.Region = New-Object System.Drawing.Region($path)
    }
    if (-not (Check-Chocolatey)) {
        Write-Host "[EXIT] Falta Chocolatey o se requiere reinicio." -ForegroundColor Yellow
        return $false
    }
    if (-not (Ensure-ToolHeadless -CommandName "yt-dlp" -FriendlyName "yt-dlp" -ChocoPkg "yt-dlp" -VersionArgs "--version")) {
        return $false
    }
    if (-not (Ensure-ToolHeadless -CommandName "ffmpeg" -FriendlyName "ffmpeg" -ChocoPkg "ffmpeg" -VersionArgs "-version")) {
        return $false
    }
    if ($script:RequireNode) {
        if (-not (Ensure-ToolHeadless -CommandName "node" -FriendlyName "Node.js" -ChocoPkg "nodejs-lts" -VersionArgs "--version")) {
            return $false
        }
    }
    Write-Host "[CHECK] (headless) Verificando mpvnet: " -NoNewline
    if ($mpvnetInstalled) {
        Write-Host "`n`t[OK] INSTALADO (opcional)" -ForegroundColor Green
    } else {
        Write-Host "`n`t[NO] NO INSTALADO (opcional)" -ForegroundColor Yellow
    }
    return $true
}
if (-not (Initialize-AppHeadless)) {      return  }
function Show-AppInfo {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Información de la aplicación"
    $f.Size = New-Object System.Drawing.Size(520, 850)   # Un poco más alto para el checkbox
    $f.StartPosition = "CenterParent"
    $f.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $f.MaximizeBox = $false
    $f.MinimizeBox = $false
    $f.BackColor = [System.Drawing.Color]::White
    # Título
    $lblTitulo = Create-Label -Text "YTDLL — Información" `
        -Location (New-Object System.Drawing.Point(20,16)) `
        -Size (New-Object System.Drawing.Size(460,28)) `
        -IsTitle
    # Versión
    $lblVer = Create-Label -Text ("Versión: {0}" -f $version) `
        -Location (New-Object System.Drawing.Point(20,46)) `
        -Size (New-Object System.Drawing.Size(460,22)) `
        -Font $defaultFont
    # Checkbox para debug
    $chkDebug = New-Object System.Windows.Forms.CheckBox
    $chkDebug.Location = New-Object System.Drawing.Point(20, 76)
    $chkDebug.Size = New-Object System.Drawing.Size(200, 24)
    $chkDebug.Text = "Mostrar debug en consola"
    $chkDebug.Checked = $script:DebugEnabled
    $chkDebug.Add_CheckedChanged({
        $script:DebugEnabled = $chkDebug.Checked
        Set-IniValue -Section "DEBUG" -Key "ConsoleDebug" -Value ($script:DebugEnabled.ToString().ToLower())
        Write-DebugLog "[CONFIG] Debug en consola: $($script:DebugEnabled)" -ForegroundColor Cyan
    })
    # Cambios recientes
    $lblCamb = Create-Label -Text "Cambios recientes:" `
        -Location (New-Object System.Drawing.Point(20,106)) `
        -Size (New-Object System.Drawing.Size(460,20)) `
        -IsTitle
    $psBlue = [System.Drawing.Color]::FromArgb(1,36,86)      # Azul PS clásico
    $psText = [System.Drawing.Color]::Gainsboro              # Texto claro
    $fontCambios = New-Object System.Drawing.Font("Consolas", 10)
    if ($fontCambios.Name -ne "Consolas") {
        $fontCambios = New-Object System.Drawing.Font("Lucida Console", 10)
    }
    $logCambios = $global:defaultInstructions -replace "`r?`n","`r`n"
    $txtCamb = New-Object System.Windows.Forms.RichTextBox
    $txtCamb.Location   = New-Object System.Drawing.Point(20, 128)
    $txtCamb.Size       = New-Object System.Drawing.Size(460, 150)
    $txtCamb.ReadOnly   = $true
    $txtCamb.BorderStyle= [System.Windows.Forms.BorderStyle]::None
    $txtCamb.BackColor  = $psBlue
    $txtCamb.ForeColor  = $psText
    $txtCamb.Font       = $fontCambios
    $txtCamb.Multiline  = $true
    $txtCamb.WordWrap   = $false
    $txtCamb.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Both
    $txtCamb.DetectUrls = $false
    $txtCamb.Text       = $logCambios
    $lblDeps = Create-Label -Text "Dependencias detectadas:" `
        -Location (New-Object System.Drawing.Point(20,288)) `
        -Size (New-Object System.Drawing.Size(460,22)) `
        -IsTitle
    $lblYtDlp = Create-Label -Text "yt-dlp: verificando..." `
        -Location (New-Object System.Drawing.Point(40, 315)) `
        -Size (New-Object System.Drawing.Size(300, 24)) `
        -Font $defaultFont `
        -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle)
    $lblFfmpeg = Create-Label -Text "ffmpeg: verificando..." `
        -Location (New-Object System.Drawing.Point(40, 345)) `
        -Size (New-Object System.Drawing.Size(300, 24)) `
        -Font $defaultFont `
        -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle)
    $lblNode = Create-Label -Text "Node.js: verificando..." `
        -Location (New-Object System.Drawing.Point(40, 375)) `
        -Size (New-Object System.Drawing.Size(300, 24)) `
        -Font $defaultFont `
        -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle)
    $lblMpvNet = Create-Label -Text "mpv.net: verificando..." `
        -Location (New-Object System.Drawing.Point(40, 405)) `
        -Size (New-Object System.Drawing.Size(300, 24)) `
        -Font $defaultFont `
        -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle)
    $btnYtRefresh = Create-IconButton -Text "↻" `
        -Location (New-Object System.Drawing.Point(350, 315)) `
        -ToolTipText "Buscar/actualizar yt-dlp" `
        -Size (New-Object System.Drawing.Size(24, 24))
    $btnYtUninstall = Create-IconButton -Text "✖" `
        -Location (New-Object System.Drawing.Point(380, 315)) `
        -ToolTipText "Desinstalar yt-dlp" `
        -Size (New-Object System.Drawing.Size(24, 24))
    $btnFfmpegRefresh = Create-IconButton -Text "↻" `
        -Location (New-Object System.Drawing.Point(350, 345)) `
        -ToolTipText "Buscar/actualizar ffmpeg" `
        -Size (New-Object System.Drawing.Size(24, 24))
    $btnFfmpegUninstall = Create-IconButton -Text "✖" `
        -Location (New-Object System.Drawing.Point(380, 345)) `
        -ToolTipText "Desinstalar ffmpeg" `
        -Size (New-Object System.Drawing.Size(24, 24))
    $btnNodeRefresh = Create-IconButton -Text "↻" `
        -Location (New-Object System.Drawing.Point(350, 375)) `
        -ToolTipText "Buscar/actualizar Node.js (LTS)" `
        -Size (New-Object System.Drawing.Size(24, 24))
    $btnNodeUninstall = Create-IconButton -Text "✖" `
        -Location (New-Object System.Drawing.Point(380, 375)) `
        -ToolTipText "Desinstalar Node.js (LTS)" `
        -Size (New-Object System.Drawing.Size(24, 24))
    $btnMpvNetRefresh = Create-IconButton -Text "↻" `
        -Location (New-Object System.Drawing.Point(350, 405)) `
        -ToolTipText "Buscar/actualizar mpv.net" `
        -Size (New-Object System.Drawing.Size(24, 24))
    $btnMpvNetUninstall = Create-IconButton -Text "✖" `
        -Location (New-Object System.Drawing.Point(380, 405)) `
        -ToolTipText "Desinstalar mpv.net" `
        -Size (New-Object System.Drawing.Size(24, 24))
    Refresh-DependencyLabel -CommandName "yt-dlp" -FriendlyName "yt-dlp" -LabelRef ([ref]$lblYtDlp) -VersionArgs "--version" -Parse "FirstLine"
    Refresh-DependencyLabel -CommandName "ffmpeg" -FriendlyName "ffmpeg" -LabelRef ([ref]$lblFfmpeg) -VersionArgs "-version" -Parse "FirstLine"
    if ($script:RequireNode) {
        Refresh-DependencyLabel -CommandName "node" -FriendlyName "Node.js" -LabelRef ([ref]$lblNode) -VersionArgs "--version" -Parse "FirstLine"
    }
    Refresh-DependencyLabel -CommandName "mpvnet" -FriendlyName "mpv.net" -LabelRef ([ref]$lblMpvNet) -VersionArgs "--version" -Parse "FirstLine"
    $btnYtRefresh.Add_Click({
        Update-Dependency -ChocoPkg "yt-dlp" -FriendlyName "yt-dlp" -CommandName "yt-dlp" -LabelRef ([ref]$lblYtDlp) -VersionArgs "--version" -Parse "FirstLine"
    })
    $btnYtUninstall.Add_Click({
        Uninstall-Dependency -ChocoPkg "yt-dlp" -FriendlyName "yt-dlp" -LabelRef ([ref]$lblYtDlp)
    })
    $btnFfmpegRefresh.Add_Click({
        Update-Dependency -ChocoPkg "ffmpeg" -FriendlyName "ffmpeg" -CommandName "ffmpeg" -LabelRef ([ref]$lblFfmpeg) -VersionArgs "-version" -Parse "FirstLine"
    })
    $btnFfmpegUninstall.Add_Click({
        Uninstall-Dependency -ChocoPkg "ffmpeg" -FriendlyName "ffmpeg" -LabelRef ([ref]$lblFfmpeg)
    })
    $btnNodeRefresh.Add_Click({
        Update-Dependency -ChocoPkg "nodejs-lts" -FriendlyName "Node.js" -CommandName "node" -LabelRef ([ref]$lblNode) -VersionArgs "--version" -Parse "FirstLine"
    })
    $btnNodeUninstall.Add_Click({
        Uninstall-Dependency -ChocoPkg "nodejs-lts" -FriendlyName "Node.js" -LabelRef ([ref]$lblNode)
    })
    $btnMpvNetRefresh.Add_Click({
         if (-not (Ensure-DotNet6DesktopRuntime)) {
            return
        }
        Update-Dependency -ChocoPkg "mpv.net" -FriendlyName "mpv.net" -CommandName "mpvnet" -LabelRef ([ref]$lblMpvNet) -VersionArgs "--version" -Parse "FirstLine"
    })
    $btnMpvNetUninstall.Add_Click({
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Chocolatey no está disponible. No se puede desinstalar mpv.net, mpvnet.portable ni .NET 6 Desktop Runtime.",
                "Chocolatey requerido",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        $msg = "Se desinstalarán los siguientes componentes:" +
               [Environment]::NewLine +
               " • mpv.net" + [Environment]::NewLine +
               " • mpvnet.portable" + [Environment]::NewLine +
               " • Microsoft .NET 6 Desktop Runtime" + [Environment]::NewLine + [Environment]::NewLine +
               "¿Deseas continuar?"

        $r = [System.Windows.Forms.MessageBox]::Show(
            $msg,
            "Desinstalar mpv.net + dependencias",
            [System.Windows.Forms.MessageBoxButtons]::YesNo,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )

        if ($r -eq [System.Windows.Forms.DialogResult]::Yes) {
            Uninstall-Dependency -ChocoPkg "mpv.net" -FriendlyName "mpv.net" -LabelRef ([ref]$lblMpvNet)
            try { choco uninstall mpvnet.portable -y | Out-Null } catch {}
            try { choco uninstall "Microsoft .NET 6 Desktop Runtime" -y | Out-Null } catch {}
        }
    })
    function Update-LocalDepsText {
        $ytVer  = (Get-ToolVersion -Command "yt-dlp" -ArgsForVersion "--version" -Parse "FirstLine")
        $ffVer  = (Get-ToolVersion -Command "ffmpeg" -ArgsForVersion "-version"  -Parse "FirstLine")
        $ndVer  = if ($script:RequireNode) { (Get-ToolVersion -Command "node" -ArgsForVersion "--version" -Parse "FirstLine") } else { $null }
        $mpvVer = (Get-ToolVersion -Command "mpvnet" -ArgsForVersion "--version" -Parse "FirstLine")
        # .NET 6 Desktop Runtime
        $dot6Ok = Test-DotNet6DesktopRuntime
        if ($dot6Ok) {
            $dot6Line = ".NET 6 Desktop Runtime: instalado"
        } else {
            $dot6Line = ".NET 6 Desktop Runtime: no detectado"
        }

        $list = @()
        if ($ytVer) {
            $list += "yt-dlp: $ytVer"
        } else {
            $list += "yt-dlp: no instalado"
        }
        if ($ffVer) {
            $list += "ffmpeg: $ffVer"
        } else {
            $list += "ffmpeg: no instalado"
        }
        if ($script:RequireNode) {
            if ($ndVer) {
                $list += "Node.js: $ndVer"
            } else {
                $list += "Node.js: no instalado"
            }
        }
        if ($mpvVer) {
            $list += "mpv.net: $mpvVer"
        } else {
            $list += "mpv.net: no instalado"
        }
        # Agregamos estado de .NET 6
        $list += $dot6Line
    }
    Update-LocalDepsText
    # Proyectos + descripciones
    $lblLinks = Create-Label -Text "Proyectos:" `
        -Location (New-Object System.Drawing.Point(20, 440)) `
        -Size (New-Object System.Drawing.Size(460, 22)) `
        -IsTitle
    # PWytdll
    $lnkApp = New-LinkLabel -Text "PWytdll (GitHub)" `
              -Url "https://github.com/water0ff/PWytdll/tree/main" `
              -Location (New-Object System.Drawing.Point(20, 466)) `
              -Size (New-Object System.Drawing.Size(460, 20))
    $lblAppDesc = Create-Label -Text "Script principal en PowerShell: interfaz gráfica y lógica de YTDLL." `
        -Location (New-Object System.Drawing.Point(40, 484)) `
        -Size (New-Object System.Drawing.Size(440, 18)) `
        -IsTag
    # yt-dlp
    $lnkYt  = New-LinkLabel -Text "yt-dlp" `
              -Url "https://github.com/yt-dlp/yt-dlp" `
              -Location (New-Object System.Drawing.Point(20, 508)) `
              -Size (New-Object System.Drawing.Size(460, 20))
    $lblYtDesc = Create-Label -Text "Extractor/descargador de video/audio usado como motor principal." `
        -Location (New-Object System.Drawing.Point(40, 526)) `
        -Size (New-Object System.Drawing.Size(440, 18)) `
        -IsTag
    $lnkFf  = New-LinkLabel -Text "FFmpeg" `
              -Url "https://ffmpeg.org/" `
              -Location (New-Object System.Drawing.Point(20, 550)) `
              -Size (New-Object System.Drawing.Size(460, 20))
    $lblFfDesc = Create-Label -Text "Herramienta para conversión, fusión de streams y capturas de miniaturas." `
        -Location (New-Object System.Drawing.Point(40, 568)) `
        -Size (New-Object System.Drawing.Size(440, 18)) `
        -IsTag
    $lnkNd  = New-LinkLabel -Text "Node.js" `
              -Url "https://nodejs.org/" `
              -Location (New-Object System.Drawing.Point(20, 592)) `
              -Size (New-Object System.Drawing.Size(460, 20))
    $lblNdDesc = Create-Label -Text "Dependencia adicional (Node.js LTS) requerida para ciertas tareas internas." `
        -Location (New-Object System.Drawing.Point(40, 610)) `
        -Size (New-Object System.Drawing.Size(440, 18)) `
        -IsTag
    $lnkMpv  = New-LinkLabel -Text "mpv.net" `
               -Url "https://github.com/stax76/mpv.net" `
               -Location (New-Object System.Drawing.Point(20, 634)) `
               -Size (New-Object System.Drawing.Size(460, 20))
    $lblMpvDesc = Create-Label -Text "Reproductor de video basado en mpv, usado para la vista previa/reproducción." `
        -Location (New-Object System.Drawing.Point(40, 652)) `
        -Size (New-Object System.Drawing.Size(440, 18)) `
        -IsTag
    $btnActualizarTodo = Create-Button -Text "ACTUALIZAR TODO" `
        -Location (New-Object System.Drawing.Point(20, 680)) `
        -Size (New-Object System.Drawing.Size(150, 30)) `
        -BackColor $ColorPrimary `
        -ForeColor ([System.Drawing.Color]::White) `
        -ToolTipText "Actualizar/verificar todas las dependencias con Chocolatey"
    $btnCerrar = Create-Button -Text "Cerrar" `
        -Location (New-Object System.Drawing.Point(380, 680)) `
        -Size (New-Object System.Drawing.Size(100, 30)) `
        -BackColor ([System.Drawing.Color]::Black) `
        -ForeColor ([System.Drawing.Color]::White) `
        -ToolTipText "Cerrar esta ventana"
    $btnActualizarTodo.Add_Click({
        if (-not (Check-Chocolatey)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Chocolatey no está disponible. No se pueden actualizar dependencias.",
                "Chocolatey requerido",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }
        [void](Ensure-DotNet6DesktopRuntime)
        Update-Dependency -ChocoPkg "yt-dlp" -FriendlyName "yt-dlp" -CommandName "yt-dlp" `
            -LabelRef ([ref]$lblYtDlp) -VersionArgs "--version" -Parse "FirstLine"
        Update-Dependency -ChocoPkg "ffmpeg" -FriendlyName "ffmpeg" -CommandName "ffmpeg" `
            -LabelRef ([ref]$lblFfmpeg) -VersionArgs "-version" -Parse "FirstLine"
        if ($script:RequireNode) {
            Update-Dependency -ChocoPkg "nodejs-lts" -FriendlyName "Node.js" -CommandName "node" `
                -LabelRef ([ref]$lblNode) -VersionArgs "--version" -Parse "FirstLine"
        }
        Update-Dependency -ChocoPkg "mpv.net" -FriendlyName "mpv.net" -CommandName "mpvnet" `
            -LabelRef ([ref]$lblMpvNet) -VersionArgs "--version" -Parse "FirstLine"
        # No es necesario llamar a Update-LocalDepsText porque Update-Dependency ya actualiza las etiquetas
    })
    $btnCerrar.Add_Click({ $f.Close() })
    $f.Controls.AddRange(@(
        $lblTitulo,$lblVer,$chkDebug,$lblCamb,$txtCamb,
        $lblDeps,
        $lblYtDlp,$lblFfmpeg,$lblNode,$lblMpvNet,
        $btnYtRefresh,$btnYtUninstall,
        $btnFfmpegRefresh,$btnFfmpegUninstall,
        $btnNodeRefresh,$btnNodeUninstall,
        $btnMpvNetRefresh,$btnMpvNetUninstall,
        $lblLinks,
        $lnkApp,$lblAppDesc,
        $lnkYt,$lblYtDesc,
        $lnkFf,$lblFfDesc,
        $lnkNd,$lblNdDesc,
        $lnkMpv,$lblMpvDesc,
        $btnActualizarTodo,
        $btnCerrar
    ))
    $f.ShowDialog() | Out-Null
}
#-----------------------------------------------------------
$script:videoConsultado   = $false
$script:ultimaURL         = $null
$script:ultimoTitulo      = $null
$script:lastThumbUrl      = $null
$script:formatsEnumerated = $false
$script:cookiesPath = $null
$script:ultimaRutaDescarga = Get-IniValue -Section "ruta" -Key "Destino" -DefaultValue ([Environment]::GetFolderPath('Desktop'))
$global:UrlPlaceholder = "Escribe la URL del video"
$btnPickCookies = Create-IconButton -Text "🍪" `
    -Location (New-Object System.Drawing.Point(320, 10)) `
    -ToolTipText "Seleccionar cookies.txt (opcional)"
$btnInfo = Create-IconButton -Text "?" `
    -Location (New-Object System.Drawing.Point(340, 10)) `
    -ToolTipText "Información de la aplicación"
$btnInfo.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnInfo.Size = New-Object System.Drawing.Size(26, 24)
$btnInfo.Add_Click({ Show-AppInfo })
$lblDestino = Create-Label -Text "Carpeta de destino:" `
    -Location (New-Object System.Drawing.Point(20, 15)) `
    -Size (New-Object System.Drawing.Size(130, 20)) `
    -IsTitle
$txtDestino = Create-TextBox `
    -Location (New-Object System.Drawing.Point(20, 38)) `
    -Size (New-Object System.Drawing.Size(330, 26)) `
    -ReadOnly $true -Text $script:ultimaRutaDescarga
$btnPickDestino = Create-IconButton -Text "📁" `
    -Location (New-Object System.Drawing.Point(356, 38)) `
    -ToolTipText "Cambiar carpeta de destino"
$lblVideoFmt = Create-Label -Text "Formato de VIDEO:" `
    -Location (New-Object System.Drawing.Point(20, 70)) `
    -Size (New-Object System.Drawing.Size(130, 20)) `
    -IsTitle
$cmbVideoFmt = Create-ComboBox `
    -Location (New-Object System.Drawing.Point(20, 93)) `
    -Size (New-Object System.Drawing.Size(360, 28))
$lblAudioFmt = Create-Label -Text "Formato de AUDIO:" `
    -Location (New-Object System.Drawing.Point(20, 125)) `
    -Size (New-Object System.Drawing.Size(130, 20)) `
    -IsTitle
$cmbAudioFmt = Create-ComboBox `
    -Location (New-Object System.Drawing.Point(20, 148)) `
    -Size (New-Object System.Drawing.Size(360, 28))
$txtUrl = Create-TextBox `
    -Location (New-Object System.Drawing.Point(20, 180)) `
    -Size (New-Object System.Drawing.Size(330, 40)) `
    -Font (New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Regular)) `
    -Text $global:UrlPlaceholder `
    -BackColor ([System.Drawing.Color]::FromArgb(255,255,220)) `
    -ForeColor ([System.Drawing.Color]::Gray) `
    -Multiline $false `
    -ScrollBars ([System.Windows.Forms.ScrollBars]::None)
$txtUrl.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtUrl.TextAlign = [System.Windows.Forms.HorizontalAlignment]::Center
$btnUrlHistory = Create-IconButton -Text "▾" `
    -Location (New-Object System.Drawing.Point(356, 186)) `
    -ToolTipText "Historial de URLs"
$btnUrlHistory.Size = New-Object System.Drawing.Size(24, 28)
$btnUrlHistory.Add_Click({
    Show-UrlHistoryMenu -AnchorControl $btnUrlHistory
})
$formPrincipal.Controls.Add($btnUrlHistory)
    $txtUrl.Add_TextChanged({
        if ($txtUrl.Text -ne $global:UrlPlaceholder -and -not [string]::IsNullOrWhiteSpace($txtUrl.Text)) {
            $toolTip.SetToolTip($txtUrl, (Get-DisplayUrl -Url $txtUrl.Text))
            $txtUrl.ForeColor = [System.Drawing.Color]::Black
            $currentUrl = Get-CurrentUrl
            if ($script:videoConsultado -and $script:ultimaURL -ne $currentUrl) {
                $script:videoConsultado = $false
                $script:formatsEnumerated = $false
            }
        } else {
            $toolTip.SetToolTip($txtUrl, "")
        }

        Set-DownloadButtonVisual
    })
    $txtUrl.Add_LostFocus({
        if ([string]::IsNullOrWhiteSpace($this.Text)) {
            $this.Text = $global:UrlPlaceholder
            $this.ForeColor = [System.Drawing.Color]::Gray
        }
        $this.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 220)
    })
    $txtUrl.Add_GotFocus({
        if ($this.Text -eq $global:UrlPlaceholder) {
            $this.Text = ""
            $this.ForeColor = [System.Drawing.Color]::Black
        }
        $this.BackColor = [System.Drawing.Color]::White
    })
$ctxUrlHistory = New-Object System.Windows.Forms.ContextMenuStrip
$btnDescargar = Create-Button -Text "Descargar" `
    -Location (New-Object System.Drawing.Point(20, 230)) `
    -Size (New-Object System.Drawing.Size(360, 50)) `
    -BackColor $ColorPrimary `
    -ForeColor ([System.Drawing.Color]::White) `
    -ToolTipText "Descargar usando bestvideo+bestaudio -> mp4"
    Set-DownloadButtonVisual
$lblPreview = Create-Label -Text "Vista previa:" `
    -Location (New-Object System.Drawing.Point(20, 280)) `
    -Size (New-Object System.Drawing.Size(130, 22)) `
    -IsTitle
$picPreview = New-Object System.Windows.Forms.PictureBox
    $picPreview.Location   = New-Object System.Drawing.Point(20, 305)
    $picPreview.Size       = New-Object System.Drawing.Size(360, 203)
    $picPreview.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
    $picPreview.SizeMode   = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
    $picPreview.BackColor  = [System.Drawing.Color]::White
    $picPreview.Add_Click({
        if (-not $script:videoConsultado -or [string]::IsNullOrWhiteSpace($script:ultimaURL)) {
            [System.Windows.Forms.MessageBox]::Show(
                "Primero consulta un video para poder reproducirlo.",
                "Sin consulta",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
            return
        }

        $cmd = $null
        try {
            $cmd = Get-Command "mpvnet" -ErrorAction Stop
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "mpv.net no está disponible en el PATH.`nInstálalo o actualízalo desde la sección de Dependencias.",
                "mpv.net no encontrado",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
            return
        }

        $playUrl = $null
        try {
            Write-Host "[PREVIEW-PLAY] Obteniendo stream con yt-dlp..." -ForegroundColor Cyan
            $playUrl = Get-BestStreamUrl -Url $script:ultimaURL
            if ($playUrl) {
                Write-Host "[PREVIEW-PLAY] Stream: $playUrl" -ForegroundColor Cyan
            }
        } catch {
            $playUrl = $null
        }

        if (-not $playUrl) {
            $playUrl = $script:ultimaURL
        }

        try {
            Start-Process -FilePath $cmd.Source -ArgumentList @(
                $playUrl,
                "--title=YTDLL Preview",
                "--ontop=yes",
                "--geometry=50%:50%",
                "--autofit=60%"
            ) | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "No se pudo iniciar mpv.net para reproducir el video.",
                "Error al abrir mpv.net",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
        }
    })
$lblEstadoConsulta = Create-Label `
    -Text "Estado: sin consultar" `
    -Location (New-Object System.Drawing.Point(20, 510)) `
    -Size (New-Object System.Drawing.Size(360, 70)) `
    -Font (New-Object System.Drawing.Font("Consolas", 10)) `
    -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle) `
    -TextAlign ([System.Drawing.ContentAlignment]::MiddleCenter)
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Black
    $lblEstadoConsulta.AutoEllipsis = $false   # dejamos que haga multilínea sin "..."
    $lblEstadoConsulta.UseCompatibleTextRendering = $true
$btnExit = Create-Button -Text "Salir" `
    -Location (New-Object System.Drawing.Point(20, 590)) `
    -Size (New-Object System.Drawing.Size(160, 30)) `
    -BackColor ([System.Drawing.Color]::Black) `
    -ForeColor ([System.Drawing.Color]::White) `
    -ToolTipText "Cerrar la aplicación"
$btnSites = Create-Button -Text "Sitios compatibles" `
    -Location (New-Object System.Drawing.Point(220, 590)) `
    -Size (New-Object System.Drawing.Size(160, 30)) `
    -BackColor $ColorAccent `
    -ForeColor $ColorText `
    -ToolTipText "Mostrar extractores de yt-dlp"
function Show-UrlHistoryMenu {
    param(
        [Parameter(Mandatory = $true)]
        [System.Windows.Forms.Control]$AnchorControl
    )
    $ctxUrlHistory.Items.Clear()
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.Application]::DoEvents()
    try {
        if (Test-Path -LiteralPath $script:LogFile) {
            $content = [System.IO.File]::ReadAllText($script:LogFile, [System.Text.Encoding]::UTF8)
            Write-DebugLog "[DEBUG] Contenido completo del archivo: '$content'" -ForegroundColor Magenta
            $items = @(
                $content -split "`r?`n" |
                    ForEach-Object {
                        $line = $_.Trim()
                        Write-DebugLog "[DEBUG] Procesando línea: '$line'" -ForegroundColor Gray
                        $line
                    } |
                    Where-Object {
                        $isValid = $_ -and ($_ -notmatch '^\s*$')
                        Write-DebugLog "[DEBUG] Línea válida? '$isValid' para: '$_'" -ForegroundColor Gray
                        $isValid
                    } |
                    Select-Object -Unique
            )
        } else {
            $items = @()
        }
    } catch {
        Write-DebugLog "[DEBUG] Error al leer historial: $($_.Exception.Message)" -ForegroundColor Red
        try {
            $items = @(
                Get-Content -LiteralPath $script:LogFile -ErrorAction Stop |
                    ForEach-Object { $_.Trim() } |
                    Where-Object { $_ -and ($_ -notmatch '^\s*$') } |
                    Select-Object -Unique
            )
        } catch {
            $items = @()
        }
    }
    Write-DebugLog "[DEBUG] Items encontrados: $($items.Count)" -ForegroundColor Yellow
    if ($items.Count -gt 0) {
        Write-DebugLog "[DEBUG] Primer item completo: '$($items[0])'" -ForegroundColor Yellow
        Write-DebugLog "[DEBUG] Longitud del primer item: $($items[0].Length)" -ForegroundColor Yellow
    }

    if (-not $items -or $items.Count -eq 0) {
        $miEmpty = New-Object System.Windows.Forms.ToolStripMenuItem
        $miEmpty.Text = "(Sin historial)"
        $miEmpty.Enabled = $false
        [void]$ctxUrlHistory.Items.Add($miEmpty)
    } else {
        $top = [Math]::Min(12, $items.Count)
        Write-DebugLog "[DEBUG] Mostrando $top items" -ForegroundColor Yellow

        for ($i = 0; $i -lt $top; $i++) {
            $displayText = [string]$items[$i]
            if ([string]::IsNullOrWhiteSpace($displayText)) {
                Write-DebugLog "[DEBUG] Item $i está vacío, saltando" -ForegroundColor Red
                continue
            }

            Write-DebugLog "[DEBUG] Procesando item $i : '$displayText'" -ForegroundColor Cyan
            Write-DebugLog "[DEBUG] Longitud del item $i : $($displayText.Length)" -ForegroundColor Cyan

            $urlItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $urlItem.Text = $displayText
            $urlItem.ToolTipText = $displayText

            $urlItem.add_Click({
                param($sender, $e)
                $fullText = [string]($sender -as [System.Windows.Forms.ToolStripMenuItem]).Text
                Write-DebugLog "[DEBUG] Click en: '$fullText'" -ForegroundColor Green

                if ($fullText -match '\|\s*(.+)$') {
                    $urlToSet = $matches[1].Trim()
                } else {
                    $urlToSet = $fullText
                }

                Write-DebugLog "[DEBUG] URL a establecer: '$urlToSet'" -ForegroundColor Cyan
                $txtUrl.Text = $urlToSet
                $txtUrl.ForeColor = [System.Drawing.Color]::Black
                $txtUrl.SelectionStart = $txtUrl.Text.Length
                $txtUrl.SelectionLength = 0
            })

            [void]$ctxUrlHistory.Items.Add($urlItem)
            Write-DebugLog "[DEBUG] Item agregado al menú: '$displayText'" -ForegroundColor Green
        }
    }

    if ($ctxUrlHistory.Items.Count -gt 0) {
        [void]$ctxUrlHistory.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))

        $miClear = New-Object System.Windows.Forms.ToolStripMenuItem
        $miClear.Text = "Borrar historial"
        $miClear.ForeColor = [System.Drawing.Color]::Crimson
        $miClear.add_Click({
            $r = [System.Windows.Forms.MessageBox]::Show(
                "¿Seguro que deseas borrar el historial de URLs?",
                "Confirmar",
                [System.Windows.Forms.MessageBoxButtons]::YesNo,
                [System.Windows.Forms.MessageBoxIcon]::Question
            )
            if ($r -eq [System.Windows.Forms.DialogResult]::Yes) {
                Clear-History
            }
        })
        [void]$ctxUrlHistory.Items.Add($miClear)
    }

    $pt = New-Object System.Drawing.Point(0, $AnchorControl.Height)
    $ctxUrlHistory.Show($AnchorControl, $pt)
}
function Add-HistoryUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    Write-DebugLog "[DEBUG] Add-HistoryUrl iniciada con URL: '$Url'" -ForegroundColor Cyan
    Write-DebugLog "[DEBUG] script:ultimoTitulo: '$($script:ultimoTitulo)'" -ForegroundColor Cyan

    $u = $Url.Trim()
    if ([string]::IsNullOrWhiteSpace($u)) {
        Write-DebugLog "[DEBUG] URL vacía, saliendo" -ForegroundColor Yellow
        return
    }
    if ($u -eq $global:UrlPlaceholder) {
        Write-DebugLog "[DEBUG] URL es placeholder, saliendo" -ForegroundColor Yellow
        return
    }
    if ($u -notmatch '^(\w+://|www\.|\w+\.\w+)') {
        Write-DebugLog "[DEBUG] URL no válida: '$u'" -ForegroundColor Yellow
        return
    }

    $cleanUrl = Get-CleanUrl -Url $u
    Write-DebugLog "[DEBUG] URL limpia: '$cleanUrl'" -ForegroundColor Cyan

    $title = if ($script:ultimoTitulo) {
        $safeTitle = Get-SafeFileName -Name $script:ultimoTitulo
        if ($safeTitle.Length -gt 20) {
            $safeTitle.Substring(0, 20) + "..."
        } else {
            $safeTitle
        }
    } else {
        "Video"
    }

    $historyEntry = "{0} | {1}" -f $title, $cleanUrl
    Write-DebugLog "[DEBUG] Entrada de historial a guardar: '$historyEntry'" -ForegroundColor Cyan

    # Forzar una pausa antes de leer
    Start-Sleep -Milliseconds 50
    [System.Windows.Forms.Application]::DoEvents()

    Write-DebugLog "[DEBUG] Leyendo historial desde: $script:LogFile" -ForegroundColor Cyan

    $currentEntries = @()
    try {
        if (Test-Path -LiteralPath $script:LogFile) {
            $content = [System.IO.File]::ReadAllText($script:LogFile, [System.Text.Encoding]::UTF8)
            Write-DebugLog "[DEBUG] Contenido actual del archivo (raw): '$content'" -ForegroundColor Gray

            $currentEntries = $content -split "`r?`n" |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -and ($_ -notmatch '^\s*$') }
        }
    } catch {
        Write-DebugLog "[DEBUG] Error al leer historial: $($_.Exception.Message)" -ForegroundColor Red
        Write-DebugLog "[DEBUG] Inicializando lista vacía" -ForegroundColor Yellow
        $currentEntries = @()
    }

    Write-DebugLog "[DEBUG] Entradas actuales procesadas: $($currentEntries.Count)" -ForegroundColor Cyan
    Write-DebugLog "[DEBUG] Entradas: $($currentEntries -join ' | ')" -ForegroundColor Gray

    $exists = $false
    Write-DebugLog "[DEBUG] Verificando si '$cleanUrl' ya existe en el historial..." -ForegroundColor Cyan

    foreach ($entry in $currentEntries) {
        Write-DebugLog "[DEBUG] Comparando con entrada: '$entry'" -ForegroundColor Gray
        if ($entry -match '\|\s*(.+)$') {
            $existingUrl = $matches[1].Trim()
            Write-DebugLog "[DEBUG] Extraída URL existente: '$existingUrl'" -ForegroundColor Gray
            if ($existingUrl -eq $cleanUrl) {
                Write-DebugLog "[DEBUG] ¡URL ya existe en el historial!" -ForegroundColor Yellow
                $exists = $true
                break
            }
        } else {
            Write-DebugLog "[DEBUG] Entrada sin formato 'Título | URL': '$entry'" -ForegroundColor Gray
            if ($entry -eq $cleanUrl) {
                Write-DebugLog "[DEBUG] ¡URL ya existe (formato antiguo)!" -ForegroundColor Yellow
                $exists = $true
                break
            }
        }
    }

    if (-not $exists) {
        Write-DebugLog "[DEBUG] URL no existe en historial, procediendo a guardar..." -ForegroundColor Green
        $newList = @($historyEntry) + $currentEntries
        Write-DebugLog "[DEBUG] Nueva lista tendrá $($newList.Count) elementos" -ForegroundColor Cyan

        if ($newList.Count -gt 200) {
            Write-DebugLog "[DEBUG] Recortando lista a 200 elementos" -ForegroundColor Yellow
            $newList = $newList[0..199]
        }

        try {
            Write-DebugLog "[DEBUG] Intentando escribir en: $script:LogFile" -ForegroundColor Cyan
            $contentToWrite = ($newList -join "`r`n") + "`r`n"
            Write-DebugLog "[DEBUG] Contenido a escribir (primeros 500 chars): '$($contentToWrite.Substring(0, [Math]::Min(500, $contentToWrite.Length)))'" -ForegroundColor Gray

            # Usar StreamWriter para mayor control sobre el encoding
            $stream = [System.IO.StreamWriter]::new($script:LogFile, $false, [System.Text.Encoding]::UTF8)
            $stream.Write($contentToWrite)
            $stream.Close()

            Write-DebugLog "[HISTORIAL] ¡Guardado exitosamente: $historyEntry" -ForegroundColor Green
        } catch {
            Write-DebugLog "[ERROR] No se pudo guardar en el historial: $($_.Exception.Message)" -ForegroundColor Red
            Write-DebugLog "[ERROR] Tipo de error: $($_.Exception.GetType().Name)" -ForegroundColor Red
        }
    } else {
        Write-DebugLog "[HISTORIAL] URL ya existe en historial: $cleanUrl" -ForegroundColor Yellow
    }

    Write-DebugLog "[DEBUG] Add-HistoryUrl finalizada" -ForegroundColor Cyan
}
function Get-HistoryUrls {
    try {
        if (Test-Path -LiteralPath $script:LogFile) {
            $content = [System.IO.File]::ReadAllText($script:LogFile, [System.Text.Encoding]::UTF8)
            $lines = $content -split "`r?`n" |
                ForEach-Object { $_.Trim() } |
                Where-Object { $_ -and ($_ -notmatch '^\s*$') } |
                Select-Object -Unique
        } else {
            $lines = @()
        }

        $urls = @()
        foreach ($line in $lines) {
            if ($line -match '\|\s*(.+)$') {
                $urls += $matches[1].Trim()
            } else {
                $urls += $line
            }
        }
        return $urls
    } catch {
        return @()
    }
}
$btnPickCookies.Add_Click({
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Title = "Selecciona cookies.txt"
    $ofd.Filter = "Cookies (*.txt)|*.txt|Todos (*.*)|*.*"
    if ($ofd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:cookiesPath = $ofd.FileName
        [System.Windows.Forms.MessageBox]::Show("Cookies configuradas: $($script:cookiesPath)","OK") | Out-Null
    }
})
if ($script:cookiesPath) {
    $args += @("--cookies", $script:cookiesPath)
}
$btnSites.Add_Click({
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch {
        [System.Windows.Forms.MessageBox]::Show("yt-dlp no está disponible.","Error") | Out-Null
        return
    }
    $res = Invoke-CaptureResponsive -ExePath $yt.Source -Args @("--list-extractors") -WorkingText "Obteniendo sitios…"
        $raw = ($res.StdOut + "`r`n" + $res.StdErr)
        $fmt  = Format-ExtractorsInline -RawText $raw -WrapAt 120
        $allSites = [System.Collections.ArrayList]::new()
        $null = $allSites.AddRange($fmt.List)
        $dlg = Create-Form -Title ("Sitios compatibles — {0} detectados" -f $fmt.Count) `
                           -Size (New-Object System.Drawing.Size(900, 560))
        $txtFiltro = Create-TextBox -Location (New-Object System.Drawing.Point(10,10)) `
                                    -Size (New-Object System.Drawing.Size(780,28)) `
                                    -Text "(buscar sitio)"
        $txtFiltro.ForeColor = [System.Drawing.Color]::Gray

        $txtFiltro.Add_GotFocus({
            if ($this.Text -eq "(buscar sitio)") { $this.Text = ""; $this.ForeColor = [System.Drawing.Color]::Black }
        })
        $txtFiltro.Add_LostFocus({
            if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text = "(buscar sitio)"; $this.ForeColor = [System.Drawing.Color]::Gray }
        })
        $lblCount = Create-Label -Text ("0/{0}" -f $allSites.Count) `
            -Location (New-Object System.Drawing.Point(800, 12)) `
            -Size (New-Object System.Drawing.Size(80,28)) `
            -TextAlign ([System.Drawing.ContentAlignment]::MiddleRight)
        $lst = New-Object System.Windows.Forms.ListBox
        $lst.Location = New-Object System.Drawing.Point(10, 44)
        $lst.Size     = New-Object System.Drawing.Size(864, 440)
        $lst.Font     = New-Object System.Drawing.Font("Consolas", 9)
        $lst.IntegralHeight = $false
        $btnCopy = Create-Button -Text "Copiar selección" `
            -Location (New-Object System.Drawing.Point(664, 490)) `
            -Size (New-Object System.Drawing.Size(120, 30))
        $btnClose = Create-Button -Text "Cerrar" `
            -Location (New-Object System.Drawing.Point(794, 490)) `
            -Size (New-Object System.Drawing.Size(80, 30))
        function Refresh-List([string]$term) {
            $lst.BeginUpdate()
            try {
                $lst.Items.Clear()
                $items = $allSites
                if ($term -and $term -ne "(buscar sitio)") {
                    $rx = [regex]::Escape($term)
                    $items = $allSites | Where-Object { $_ -match $rx }
                }
                $items | ForEach-Object { [void]$lst.Items.Add($_) }
                $lblCount.Text = ("{0}/{1}" -f $lst.Items.Count, $allSites.Count)
            } finally {
                $lst.EndUpdate()
            }
        }
        Refresh-List $null
        $txtFiltro.Add_TextChanged({
            if ($this.ForeColor -eq [System.Drawing.Color]::Gray) { return } # aún placeholder
            Refresh-List $this.Text.Trim()
        })
        $btnCopy.Add_Click({
            if ($lst.SelectedItem) {
                try { [System.Windows.Forms.Clipboard]::SetText([string]$lst.SelectedItem) } catch {}
            }
        })
        $lst.Add_DoubleClick({ if ($lst.SelectedItem) { try { [System.Windows.Forms.Clipboard]::SetText([string]$lst.SelectedItem) } catch {} } })
        $lst.Add_KeyDown({
            param($s,$e)
            if ($e.KeyCode -eq 'Enter' -and $lst.SelectedItem) {
                try { [System.Windows.Forms.Clipboard]::SetText([string]$lst.SelectedItem) } catch {}
                $e.Handled = $true
            }
        })
        $btnClose.Add_Click({ $dlg.Close() })
        $dlg.Controls.Add($txtFiltro)
        $dlg.Controls.Add($lblCount)
        $dlg.Controls.Add($lst)
        $dlg.Controls.Add($btnCopy)
        $dlg.Controls.Add($btnClose)
        $dlg.ShowDialog() | Out-Null
})
$btnPickDestino.Add_Click({
    $fbd = New-Object System.Windows.Forms.FolderBrowserDialog
    $fbd.Description  = "Selecciona la carpeta de descarga"
    $fbd.SelectedPath = if ([string]::IsNullOrWhiteSpace($script:ultimaRutaDescarga)) {
        [Environment]::GetFolderPath('Desktop')
    } else {
        $script:ultimaRutaDescarga
    }
    if ($fbd.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $script:ultimaRutaDescarga = $fbd.SelectedPath
        $txtDestino.Text = $script:ultimaRutaDescarga
        Set-IniValue -Section "ruta" -Key "Destino" -Value $script:ultimaRutaDescarga
        Write-Host ("[DESTINO] Carpeta configurada: {0}" -f $script:ultimaRutaDescarga) -ForegroundColor Cyan
    }
})
    $formPrincipal.Controls.Add($btnExit)
    $formPrincipal.Controls.Add($lblVideoFmt)
    $formPrincipal.Controls.Add($btnPickCookies)
    $formPrincipal.Controls.Add($btnInfo)
    $formPrincipal.Controls.Add($cmbVideoFmt)
    $formPrincipal.Controls.Add($lblAudioFmt)
    $formPrincipal.Controls.Add($cmbAudioFmt)
    $formPrincipal.Controls.Add($lblDestino)
    $formPrincipal.Controls.Add($txtDestino)
    $formPrincipal.Controls.Add($btnPickDestino)
    $formPrincipal.Controls.Add($btnSites)
    $formPrincipal.Controls.Add($lblPreview)
    $formPrincipal.Controls.Add($picPreview)
    $formPrincipal.Controls.Add($txtUrl)
    $formPrincipal.Controls.Add($lblEstadoConsulta)
    $formPrincipal.Controls.Add($btnDescargar)
function New-WorkingBox {
    param([string]$Text)
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Trabajando..."
    $f.Size = New-Object System.Drawing.Size(320,110)
    $f.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $f.StartPosition = "CenterParent"
    $f.MaximizeBox = $false; $f.MinimizeBox = $false; $f.ControlBox = $false
    $f.TopMost = $true
    $lbl = New-Object System.Windows.Forms.Label
    $lbl.Text = $Text; $lbl.AutoSize = $false
    $lbl.Size = New-Object System.Drawing.Size(300,30)
    $lbl.Location = New-Object System.Drawing.Point(10,10)
    $lbl.TextAlign = "MiddleCenter"
    $prg = New-Object System.Windows.Forms.ProgressBar
    $prg.Style = "Marquee"
    $prg.MarqueeAnimationSpeed = 25
    $prg.Size = New-Object System.Drawing.Size(300,20)
    $prg.Location = New-Object System.Drawing.Point(10,45)
    $f.Controls.Add($lbl); $f.Controls.Add($prg)
    $f.Show() | Out-Null
    return @{ Form = $f; Label = $lbl }
}
function Invoke-CaptureResponsive {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [string[]]$Args = @(),
        [string]$WorkingText = "Procesando...",
        [int]$TimeoutSec = 120
    )
    $prevBtnState = $null
    if ($btnConsultar) { $prevBtnState = $btnConsultar.Enabled; $btnConsultar.Enabled = $false }
    $prevLabel = $null
    if ($lblEstadoConsulta) { $prevLabel = $lblEstadoConsulta.Text; $lblEstadoConsulta.Text = $WorkingText }
    $tmpDir  = [System.IO.Path]::GetTempPath()
    $outFile = Join-Path $tmpDir ("proc_stdout_{0}.log" -f ([guid]::NewGuid()))
    $errFile = Join-Path $tmpDir ("proc_stderr_{0}.log" -f ([guid]::NewGuid()))
    $argLine = ($Args | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } }) -join ' '
    $proc = Start-Process -FilePath $ExePath `
        -ArgumentList $argLine `
        -NoNewWindow -PassThru `
        -RedirectStandardOutput $outFile `
        -RedirectStandardError  $errFile
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $dot = 0
    try {
        while (-not $proc.HasExited) {
            [System.Windows.Forms.Application]::DoEvents()
            $dot = ($dot + 1) % 4
            if ($lblEstadoConsulta) { $lblEstadoConsulta.Text = $WorkingText + ("." * $dot) }

            if ($sw.Elapsed.TotalSeconds -ge $TimeoutSec) {
                try { $proc.Kill() } catch {}
                throw "Tiempo de espera agotado ($TimeoutSec s) en '$WorkingText'."
            }
            Start-Sleep -Milliseconds 120
        }
    } finally {
        $sw.Stop()
        if ($btnConsultar -and $prevBtnState -ne $null) { $btnConsultar.Enabled = $prevBtnState }
    }
    $stdout = ""; $stderr = ""
    try { if (Test-Path $outFile) { $stdout = [IO.File]::ReadAllText($outFile) } } catch {}
    try { if (Test-Path $errFile) { $stderr = [IO.File]::ReadAllText($errFile) } } catch {}
    try { Remove-Item -Path $outFile,$errFile -ErrorAction SilentlyContinue } catch {}
    return [pscustomobject]@{ ExitCode = $proc.ExitCode; StdOut = $stdout; StdErr = $stderr }
}
function Invoke-Capture {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [string[]]$Args=@(),
        [int]$TimeoutSeconds = 30
    )
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ExePath
    $psi.Arguments = (($Args | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } }) -join ' ')
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError  = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow  = $true
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    if (-not $p.WaitForExit($TimeoutSeconds * 1000)) {
        try {
            $p.Kill()
            Write-Host "[TIMEOUT] Proceso terminado por timeout después de $TimeoutSeconds segundos" -ForegroundColor Red
        } catch { }
        return [pscustomobject]@{ ExitCode = -1; StdOut = ""; StdErr = "Timeout después de $TimeoutSeconds segundos" }
    }
    $stdout = $p.StandardOutput.ReadToEnd()
    $stderr = $p.StandardError.ReadToEnd()
    return [pscustomobject]@{ ExitCode = $p.ExitCode; StdOut = $stdout; StdErr = $stderr }
}
function Save-Bytes {
    param([byte[]]$Bytes,[string]$Path)
    [System.IO.File]::WriteAllBytes($Path, $Bytes)
    return $Path
}
function Convert-WebpUrlToPng {
    param([Parameter(Mandatory=$true)][string]$Url)
    try {
        $ff = Get-Command ffmpeg -ErrorAction Stop | Select-Object -ExpandProperty Source
    } catch { return $null }
    $webClient = $null
    try {
        $webClient = New-Object System.Net.WebClient
        $webClient.Headers.Add('User-Agent', 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) PowerShell-YTDLL')
        $bytes = $webClient.DownloadData($Url)
        $tmpIn  = Join-Path ([IO.Path]::GetTempPath()) ("ytdll_webp_{0}.webp" -f ([guid]::NewGuid()))
        $tmpOut = [IO.Path]::ChangeExtension($tmpIn, ".png")
        [IO.File]::WriteAllBytes($tmpIn, $bytes)
        $p = Start-Process -FilePath $ff -ArgumentList @("-y","-hide_banner","-loglevel","error","-i", $tmpIn, $tmpOut) `
                           -NoNewWindow -PassThru
        $p.WaitForExit()
        if ($p.ExitCode -eq 0 -and (Test-Path $tmpOut)) { return $tmpOut }
        return $null
    } catch {
        Write-Host "[WEBP-CONVERT] Error: $($_.Exception.Message)" -ForegroundColor Red
        return $null
    }
    finally {
        if ($webClient) { $webClient.Dispose() }
        try { if (Test-Path $tmpIn) { Remove-Item $tmpIn -Force } } catch {}
    }
}
function Invoke-YtDlpConsoleProgress {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [Parameter(Mandatory=$true)][string[]]$Args,
        [switch]$UpdateUi
    )
    try { [Console]::OutputEncoding = [System.Text.Encoding]::UTF8 } catch {}
    $global:ProgressPreference = 'SilentlyContinue'
    $tmpDir  = [System.IO.Path]::GetTempPath()
    $errFile = Join-Path $tmpDir ("yt-dlp-stderr_{0}.log" -f ([guid]::NewGuid()))
    $outFile = Join-Path $tmpDir ("yt-dlp-stdout_{0}.log" -f ([guid]::NewGuid()))
    $argLine = ($Args | ForEach-Object { if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ } }) -join ' '
    $proc = Start-Process -FilePath $ExePath `
        -ArgumentList $argLine `
        -NoNewWindow -PassThru `
        -RedirectStandardError  $errFile `
        -RedirectStandardOutput $outFile
    $fsErr = [System.IO.File]::Open($errFile,[System.IO.FileMode]::OpenOrCreate,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
    $srErr = New-Object System.IO.StreamReader($fsErr)
    $fsOut = [System.IO.File]::Open($outFile,[System.IO.FileMode]::OpenOrCreate,[System.IO.FileAccess]::Read,[System.IO.FileShare]::ReadWrite)
    $srOut = New-Object System.IO.StreamReader($fsOut)
    $script:lastPct        = -1
    $script:lastLineSig    = $null
    $script:hlsDurationSec = $null
    $phase = "Preparando…"
    function Set-Ui([string]$txt) {
        if ($UpdateUi -and $lblEstadoConsulta) { $lblEstadoConsulta.Text = $txt }
    }
    function _PrintLine([string]$text) {
        if ([string]::IsNullOrWhiteSpace($text)) { return }
        $mDur = [regex]::Match($text, 'Duration:\s*(?<h>\d{2}):(?<m>\d{2}):(?<s>\d{2}(?:\.\d+)?)')
        if ($mDur.Success) {
            $h=[int]$mDur.Groups['h'].Value; $m=[int]$mDur.Groups['m'].Value; $s=[double]$mDur.Groups['s'].Value
            $script:hlsDurationSec = ($h*3600 + $m*60 + $s)
            return
        }
        if ($text -match "^\[(?:hls|https)\s@.*\]\s+Opening\s+'.+\.ts'") { return }
        if ($text -match '^\s*(Input\s+#0,|Output\s+#0|Press \[q\] to stop)') { return }
        if ($text -match 'Sleeping\s+(\d+(?:\.\d+)?)\s+seconds') { Set-Ui "Esperando $($Matches[1])s…"; Write-Host "`n$text"; return }
        if ($text -match '^\[download\]\s+Destination:')         { $phase = "Descargando…"; Set-Ui $phase; Write-Host "`n$text"; return }
        if ($text -match '^\[Merger\]\s+Merging formats')        { $phase = "Fusionando…"; Set-Ui $phase; Write-Host "`n$text"; return }
        if ($text -match '^Deleting original file')              { $phase = "Borrando temporales…"; Set-Ui $phase; Write-Host "`n$text"; return }
        if ($text -match '^\[(ExtractAudio|Fixup|EmbedSubtitle|ModifyChapters)\]') { $phase = "Post-procesando…"; Set-Ui $phase; Write-Host "`n$text"; return }
        $m = [regex]::Match($text, 'download:\s*(?<pct>\d+(?:\.\d+)?)%\s*(?:ETA:(?<eta>\S+))?\s*(?:SPEED:(?<spd>.+))?', 'IgnoreCase')
        if (-not $m.Success) { $m = [regex]::Match($text, '(?<pct>\d+(?:\.\d+)?)%\s+of.*?at\s+(?<spd>\S+)\s+ETA\s+(?<eta>\S+)', 'IgnoreCase') }
        if (-not $m.Success) { $m = [regex]::Match($text, '(?<pct>\d+(?:\.\d+)?)%') }
        if ($m.Success) {
            $pct = [int][math]::Min(100,[math]::Round([double]$m.Groups['pct'].Value))
            $eta = $m.Groups['eta'].Value; $spd = $m.Groups['spd'].Value
            if ($pct -ne $script:lastPct) {
                $script:lastPct = $pct
                $etaText = "--:--"
                if ($eta) { $etaText = $eta }
                $spdText = ""
                if ($spd) { $spdText = $spd }
                Set-Ui ("{0} {1}%  ETA {2}  {3}" -f ($phase -replace '\.\.\.$','…'), $pct, $etaText, $spdText)
                Write-Host ("`r[PROGRESO] {0,3}%  ETA {1,-8}  {2,-16}" -f $pct, $eta, $spd) -NoNewline
            }
            return
        }
        $mFfm = [regex]::Match($text, '^frame=\s*\d+.*time=\d{2}:\d{2}:\d{2}(?:\.\d+)?\s+.*speed=\S+')
        if ($mFfm.Success) {
            $line = ($text -replace '\s+',' ').Trim()
            $sig  = [System.BitConverter]::ToString([System.Security.Cryptography.MD5]::Create().ComputeHash([Text.Encoding]::UTF8.GetBytes($line)))
            if ($sig -ne $script:lastLineSig) {
                $script:lastLineSig = $sig
                Set-Ui $line
                Write-Host ("`r[PROGRESO] {0}" -f $line) -NoNewline
            }
            return
        }
        Write-Host "`n$text"
    }
    try {
        Set-Ui "Preparando descarga…"
        $bufErr = ""; $bufOut = ""
        while (-not $proc.HasExited) {
            $bufOut += $srOut.ReadToEnd()
            $bufErr += $srErr.ReadToEnd()
            foreach ($chunk in @($bufOut, $bufErr)) {
                if ([string]::IsNullOrEmpty($chunk)) { continue }
                $parts = [regex]::Split($chunk, "\r\n|\n|\r")
                for ($i=0; $i -lt $parts.Length-1; $i++) { _PrintLine $parts[$i] }
            }
            if ($bufOut) { $bufOut = ([regex]::Split($bufOut, "\r\n|\n|\r") | Select-Object -Last 1) }
            if ($bufErr) { $bufErr = ([regex]::Split($bufErr, "\r\n|\n|\r") | Select-Object -Last 1) }
            [System.Windows.Forms.Application]::DoEvents()
            Start-Sleep -Milliseconds 80
        }
        $bufOut += $srOut.ReadToEnd()
        $bufErr += $srErr.ReadToEnd()
        foreach ($line in ([regex]::Split(($bufOut + "`n" + $bufErr), "\r\n|\n|\r"))) { _PrintLine $line }
    }
    finally {
        try { $srErr.Close(); $fsErr.Close() } catch {}
        try { $srOut.Close(); $fsOut.Close() } catch {}
        Write-Host ""
    }
    $code = $proc.ExitCode
    $script:lastYtDlpExitCode = $code   # lo guardamos por si acaso
    return $code
}
function Invoke-YtDlpQuery {
    param(
        [Parameter(Mandatory=$true)][string]$ExePath,
        [Parameter(Mandatory=$true)][string[]]$Args,
        [switch]$UpdateUi
    )
    try {
        [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    } catch {}
    $global:ProgressPreference = 'SilentlyContinue'
    $tmpDir = [System.IO.Path]::GetTempPath()
    $errFile = Join-Path $tmpDir ("yt-dlp-stderr_{0}.log" -f ([guid]::NewGuid()))
    $outFile = Join-Path $tmpDir ("yt-dlp-stdout_{0}.log" -f ([guid]::NewGuid()))
    $argLine = ($Args | ForEach-Object {
        if ($_ -match '\s') { '"{0}"' -f $_ } else { $_ }
    }) -join ' '
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $ExePath
    $psi.Arguments = $argLine
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.StandardOutputEncoding = [System.Text.Encoding]::UTF8
    $psi.StandardErrorEncoding = [System.Text.Encoding]::UTF8
    $proc = New-Object System.Diagnostics.Process
    $proc.StartInfo = $psi
    $started = $proc.Start()
    if (-not $started) {
        Write-Host "[ERROR] No se pudo iniciar el proceso: $ExePath" -ForegroundColor Red
        return [pscustomobject]@{
            ExitCode = -1
            StdOut = ""
            StdErr = "No se pudo iniciar el proceso"
        }
    }
    $stdoutTask = $proc.StandardOutput.ReadToEndAsync()
    $stderrTask = $proc.StandardError.ReadToEndAsync()
    $proc.WaitForExit()
    $stdout = $stdoutTask.GetAwaiter().GetResult()
    $stderr = $stderrTask.GetAwaiter().GetResult()
    $exitCode = $proc.ExitCode
    $proc.Dispose()
    return [pscustomobject]@{
        ExitCode = $exitCode
        StdOut = $stdout
        StdErr = $stderr
    }
}

$btnDescargar.Add_Click({
    Refresh-GateByDeps
    $currentUrl = Get-CurrentUrl
    $noPlaylistArg = @()
    if ($script:isPlaylist -or (Test-YouTubePlaylist -Url $currentUrl)) {
        $noPlaylistArg = @("--no-playlist")
        Write-Host "[DESCARGA] Forzando --no-playlist para evitar descarga de playlist completa" -ForegroundColor Yellow
    }
    $ready = $script:videoConsultado -and
             -not [string]::IsNullOrWhiteSpace($script:ultimaURL) -and
             ($script:ultimaURL -eq $currentUrl)
    if (-not $ready) {
        if ([string]::IsNullOrWhiteSpace($currentUrl)) {
            $lblEstadoConsulta.Text = "ERROR: Escribe una URL"
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Red
            [System.Windows.Forms.MessageBox]::Show(
                "Escribe una URL de YouTube.",
                "Falta URL",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Warning
            ) | Out-Null
        Invoke-ConsultaFromUI -Url $currentUrl
            return
        }
        $lblEstadoConsulta.Text = "Iniciando consulta..."
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
        $ok =  Invoke-ConsultaFromUI -Url $currentUrl
        if ($ok) {
            Set-DownloadButtonVisual
            [System.Windows.Forms.MessageBox]::Show(
                "Consulta lista. Revisa formatos y vuelve a presionar Descargar para iniciar la descarga.",
                "Consulta completada",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        } else {
            Set-DownloadButtonVisual
        }
        return
    }
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch {
        [System.Windows.Forms.MessageBox]::Show("yt-dlp no está disponible. Valídalo en Dependencias.","yt-dlp no encontrado",
            [System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
        return
    }
    $dest = $script:ultimaRutaDescarga
    if ([string]::IsNullOrWhiteSpace($dest)) {
        $dest = [Environment]::GetFolderPath('Desktop')
        $script:ultimaRutaDescarga = $dest
        try { $txtDestino.Text = $dest } catch {}
    }
    if (-not (Test-Path -LiteralPath $dest)) {
        try { New-Item -ItemType Directory -Path $dest -Force | Out-Null }
        catch {
            [System.Windows.Forms.MessageBox]::Show("No se pudo preparar la carpeta de destino.","Error de destino",
                [System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
            return
        }
    }
        $videoSel = Get-SelectedFormatId -Combo $cmbVideoFmt
        $audioSel = Get-SelectedFormatId -Combo $cmbAudioFmt
        $hayFormatosAudio = ($script:formatsAudio -and $script:formatsAudio.Count -gt 0)

        # Lógica SIMPLE y DIRECTA
        if ($videoSel -and $audioSel) {
            # SI hay selección de audio, FORZAR combinación
            $fSelector = "{0}+{1}" -f $videoSel, $audioSel
            $mergeExt = "mp4"
            Write-DebugLog "[DEBUG] Combinando video ($videoSel) + audio ($audioSel)" -ForegroundColor Green
        }
        elseif ($videoSel -and $hayFormatosAudio) {
            # SI hay video y formatos de audio disponibles, usar bestaudio
            $fSelector = "{0}+bestaudio" -f $videoSel
            $mergeExt = "mp4"
            Write-DebugLog "[DEBUG] Combinando video ($videoSel) + bestaudio" -ForegroundColor Green
        }
        elseif ($videoSel) {
            # Solo video, sin audio disponible
            $fSelector = $videoSel
            $mergeExt = $null
            Write-DebugLog "[DEBUG] Solo video: $videoSel" -ForegroundColor Yellow
        }
        elseif ($audioSel) {
            # Solo audio
            $fSelector = $audioSel
            $mergeExt = $null
            Write-DebugLog "[DEBUG] Solo audio: $audioSel" -ForegroundColor Yellow
        }
        else {
            # Por defecto
            if ($hayFormatosAudio) {
                $fSelector = "bestvideo+bestaudio/best"
                $mergeExt = "mp4"
            } else {
                $fSelector = "best"
                $mergeExt = $null
            }
            Write-DebugLog "[DEBUG] Selector por defecto: $fSelector" -ForegroundColor Cyan
        }
        Write-DebugLog "[DEBUG] Selector de formato: $fSelector" -ForegroundColor Yellow
        Write-DebugLog "[DEBUG] Merge extension: $mergeExt" -ForegroundColor Yellow
        Write-DebugLog "[DEBUG] ¿Hay formatos de audio?: $hayFormatosAudio" -ForegroundColor Yellow
    $prevLbl = $lblEstadoConsulta.Text
    $prevPickDest  = $btnPickDestino.Enabled
    $prevCmbVid    = $cmbVideoFmt.Enabled
    $prevCmbAud    = $cmbAudioFmt.Enabled
    $btnPickDestino.Enabled = $false
    $cmbVideoFmt.Enabled = $false
    $cmbAudioFmt.Enabled = $false
    $lblEstadoConsulta.Text = "Preparando descarga…"
    if ($script:ultimoTitulo) {
    $baseTitle = $script:ultimoTitulo
    } else {
        $vid = Get-YouTubeVideoId -Url $script:ultimaURL
        if ($vid) {
            $baseTitle = "video_$vid"
        } else {
            $baseTitle = "video"
        }
    }
    $baseTitle = Get-SafeFileName -Name $baseTitle
    $finalExt = $mergeExt
    if ([string]::IsNullOrWhiteSpace($finalExt)) { $finalExt = "mp4" }
    $targetPath = Join-Path $dest ("{0}.{1}" -f $baseTitle, $finalExt)
    $idx = 2
    while (Test-Path -LiteralPath $targetPath) {
        $targetPath = Join-Path $dest ("{0}_{1}.{2}" -f $baseTitle, $idx, $finalExt)
        $idx++
    }
    Write-Host ("[OUTPUT] Archivo destino: {0}" -f $targetPath) -ForegroundColor Cyan
        $args = @("--encoding","utf-8","--progress","--no-color","--newline",
        "-f", $fSelector
    ) + $noPlaylistArg + @(
        "-o", $targetPath,
        "--progress-template","download:%(progress._percent_str)s ETA:%(progress._eta_str)s SPEED:%(progress._speed_str)s",
        "--extractor-args","youtube:player_client=default,-web_safari,-web_embedded,-tv"
    )
    if ($mergeExt) {
        $args = @(
            "--encoding","utf-8","--progress","--no-color","--newline",
            "-f", $fSelector
        ) + $noPlaylistArg + @(
            "--merge-output-format", $mergeExt,
            "-o", $targetPath,
            "--progress-template","download:%(progress._percent_str)s ETA:%(progress._eta_str)s SPEED:%(progress._speed_str)s",
            "--extractor-args","youtube:player_client=default,-web_safari,-web_embedded,-tv"
        )
    }
    $args += @(
        "--no-part",
        "--ignore-config"
    ) + $noPlaylistArg  # Agregar nuevamente por si acaso
    if ($script:cookiesPath) {
        $args += @("--cookies", $script:cookiesPath)
    }
    $args += $script:ultimaURL
    $args += @(
        "--retries", "5",
        "--retry-sleep", "2",
        "-N", "4"
    )
        $oldCursor = [System.Windows.Forms.Cursor]::Current
    [System.Windows.Forms.Cursor]::Current = [System.Windows.Forms.Cursors]::WaitCursor
    try {
        $exit = Invoke-YtDlpConsoleProgress -ExePath $yt.Source -Args $args -UpdateUi
        if ($exit -ne 0) {
            $lastErr = $lblEstadoConsulta.Text + " "  # opcional, no siempre contiene stderr
            if ($videoSel -match '^best(video)?$' -and $script:bestProgId) {
                Write-Host "[RETRY] Alias falló; reintento con ID concreto: $($script:bestProgId)" -ForegroundColor Yellow
                $args = @(
                    "--encoding","utf-8","--progress","--no-color","--newline",
                    "-f", $script:bestProgId,
                    "-o", $targetPath,
                    "--progress-template","download:%(progress._percent_str)s ETA:%(progress._eta_str)s SPEED:%(progress._speed_str)s",
                    "--extractor-args","youtube:player_client=default,-web_safari,-web_embedded,-tv"
                )
                $exit = Invoke-YtDlpConsoleProgress -ExePath $yt.Source -Args $args -UpdateUi
            }
        }
        if ($null -eq $exit -and $script:lastYtDlpExitCode -ne $null) {
            $exit = $script:lastYtDlpExitCode
        }
        Write-Host "------------------------" -ForegroundColor DarkGray
        Write-DebugLog "[DEBUG] ExitCode final de yt-dlp: $exit" -ForegroundColor Yellow
        $archivoExiste = Test-Path -LiteralPath $targetPath
        Write-DebugLog "[DEBUG] ¿Archivo final existe?: $archivoExiste" -ForegroundColor Yellow
        Write-DebugLog "[DEBUG] Ruta objetivo: $targetPath" -ForegroundColor DarkCyan
        Write-Host "------------------------" -ForegroundColor DarkGray
        if ($exit -eq 0 -or $archivoExiste) {
            if ($exit -ne 0 -and $archivoExiste) {
                Write-Host "[WARN] ExitCode=$exit pero el archivo final existe. Se considera éxito." -ForegroundColor Yellow
            }
            Add-HistoryUrl -Url $script:ultimaURL
            $lblEstadoConsulta.Text = ("Completado: {0}" -f $script:ultimoTitulo)
            [System.Windows.Forms.MessageBox]::Show(
                ("Descarga finalizada:`n{0}" -f $script:ultimoTitulo),
                "Completado",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Information
            ) | Out-Null
        }
        else {
            $lblEstadoConsulta.Text = "Error durante la descarga"
            [System.Windows.Forms.MessageBox]::Show(
                "Falló la descarga. Revisa conexión/URL/DRM.",
                "Error de descarga",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            ) | Out-Null
            Write-Host "[ERROR] La descarga falló realmente. ExitCode=$exit" -ForegroundColor Red
            Write-Host "[ERROR] No se generó el archivo final: $targetPath" -ForegroundColor Red
        }
    }
    finally {
        [System.Windows.Forms.Cursor]::Current = $oldCursor
        $btnPickDestino.Enabled = $prevPickDest
        $cmbVideoFmt.Enabled    = $prevCmbVid
        $cmbAudioFmt.Enabled    = $prevCmbAud
        Set-DownloadButtonVisual
    }
})
Refresh-GateByDeps
Set-DownloadButtonVisual
try { $txtDestino.Text = $script:ultimaRutaDescarga } catch {}
$btnExit.Add_Click({
    Write-Host "[EXIT] Cerrando aplicación por solicitud del usuario." -ForegroundColor Yellow
    $formPrincipal.Dispose()
    $formPrincipal.Close()
})
$formPrincipal.Refresh()
$formPrincipal.ShowDialog()