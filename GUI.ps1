<#
.SYNOPSIS
    YTDLL — Módulo de GUI
    Construye todos los controles de la interfaz gráfica y define las funciones
    de fábrica de widgets reutilizables (Create-Button, Create-Label, etc.).

    Compatible con PowerShell 5.x
    Cargado mediante dot-sourcing desde Main.ps1 DESPUÉS de Dependencies.ps1 y Functions.ps1.

    Al ejecutarse (dot-source), este script:
      1. Define las funciones de fábrica de controles.
      2. Crea $formPrincipal y todos los controles como variables de script.
      3. Define Show-AppInfo, Show-SitesDialog, Show-UrlHistoryMenu,
         Show-PreviewUniversal, Show-PreviewImage, Set-DownloadButtonVisual,
         Refresh-GateByDeps.
#>

# ─── Ensamblados y estilos ─────────────────────────────────────────────────────
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

# ─── Tema / Colores / Fuentes ──────────────────────────────────────────────────
$defaultFont      = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$boldFont         = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$ColorBgForm      = [System.Drawing.Color]::FromArgb(209, 209, 214)
$ColorPrimary     = [System.Drawing.Color]::FromArgb(94, 92, 230)
$ColorPrimaryDark = [System.Drawing.Color]::FromArgb(0, 92, 197)
$ColorPrimaryLight = [System.Drawing.Color]::FromArgb(142, 209, 255)
$ColorSurface     = [System.Drawing.Color]::FromArgb(255, 255, 255)
$ColorPanel       = [System.Drawing.Color]::FromArgb(242, 242, 247)
$ColorText        = [System.Drawing.Color]::FromArgb(28, 28, 30)
$ColorSubText     = [System.Drawing.Color]::FromArgb(142, 142, 147)
$ColorAccent      = [System.Drawing.Color]::FromArgb(72, 169, 197)
$toolTip          = New-Object System.Windows.Forms.ToolTip

# ═══════════════════════════════════════════════════════════════════════════════
#  FUNCIONES DE FÁBRICA DE CONTROLES
# ═══════════════════════════════════════════════════════════════════════════════

function Set-RoundedRegion {
    param(
        [Parameter(Mandatory=$true)][System.Windows.Forms.Control]$Control,
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
    param(
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
    $button.Text      = $Text;   $button.Size     = $Size
    $button.Location  = $Location; $button.BackColor = $BackColor
    $button.ForeColor = $ForeColor; $button.Font    = $Font
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize           = 0
    $button.FlatAppearance.MouseDownBackColor   = $ColorPrimaryDark
    $button.FlatAppearance.MouseOverBackColor   = $ColorPrimary
    $button.Tag     = $BackColor
    $button.Enabled = $Enabled
    $button.Add_MouseEnter({ $this.BackColor = $ColorPrimaryDark; $this.Font = $boldFont; $this.Cursor = [System.Windows.Forms.Cursors]::Hand })
    $button.Add_MouseLeave({ $this.BackColor = $this.Tag; $this.Font = $defaultFont; $this.Cursor = [System.Windows.Forms.Cursors]::Default })
    $button.Add_Resize({
        param($sender, $e)
        $r = [int]([math]::Round($sender.Height / 2))
        if ($r -lt 10) { $r = 10 }
        Set-RoundedRegion -Control $sender -Radius $r
    })
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
    $label.Text = $Text; $label.Size = $Size; $label.Location = $Location
    $label.BackColor = $BackColor; $label.ForeColor = $ForeColor
    $label.Font = $Font; $label.BorderStyle = $BorderStyle; $label.TextAlign = $TextAlign
    if ($IsTitle) { $label.Font = $boldFont; $label.ForeColor = $ColorPrimaryDark }
    if ($IsTag)   { $label.BackColor = [System.Drawing.Color]::FromArgb(230,235,245); $label.ForeColor = $ColorSubText }
    if ($ToolTipText) { $toolTip.SetToolTip($label, $ToolTipText) }
    return $label
}

function Create-Form {
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(350,200)),
        [System.Windows.Forms.FormStartPosition]$StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen,
        [System.Windows.Forms.FormBorderStyle]$FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog,
        [bool]$MaximizeBox = $false, [bool]$MinimizeBox = $false,
        [bool]$TopMost = $false,    [bool]$ControlBox = $true,
        [System.Drawing.Icon]$Icon = $null,
        [System.Drawing.Color]$BackColor = [System.Drawing.SystemColors]::Control
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
        [System.Drawing.Point]$Location,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(200,30)),
        [System.Windows.Forms.ComboBoxStyle]$DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList,
        [System.Drawing.Font]$Font = $defaultFont,
        [string[]]$Items = @(),
        [int]$SelectedIndex = -1,
        [string]$DefaultText = $null
    )
    $cb = New-Object System.Windows.Forms.ComboBox
    $cb.Location=$Location; $cb.Size=$Size; $cb.DropDownStyle=$DropDownStyle; $cb.Font=$Font
    if ($Items.Count -gt 0) { $cb.Items.AddRange($Items); $cb.SelectedIndex=$SelectedIndex }
    if ($DefaultText) { $cb.Text = $DefaultText }
    return $cb
}

function Create-TextBox {
    param(
        [System.Drawing.Point]$Location,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(200,30)),
        [System.Drawing.Color]$BackColor = [System.Drawing.Color]::White,
        [System.Drawing.Color]$ForeColor = [System.Drawing.Color]::Black,
        [System.Drawing.Font]$Font = $defaultFont,
        [string]$Text = "",
        [bool]$Multiline = $false,
        [System.Windows.Forms.ScrollBars]$ScrollBars = [System.Windows.Forms.ScrollBars]::None,
        [bool]$ReadOnly = $false,
        [bool]$UseSystemPasswordChar = $false
    )
    $tb = New-Object System.Windows.Forms.TextBox
    $tb.Location=$Location; $tb.Size=$Size; $tb.BackColor=$BackColor; $tb.ForeColor=$ForeColor
    $tb.Font=$Font; $tb.Text=$Text; $tb.Multiline=$Multiline; $tb.ScrollBars=$ScrollBars
    $tb.ReadOnly=$ReadOnly; $tb.WordWrap=$false
    if ($UseSystemPasswordChar) { $tb.UseSystemPasswordChar = $true }
    return $tb
}

function Create-IconButton {
    param(
        [Parameter(Mandatory=$true)][string]$Text,
        [Parameter(Mandatory=$true)][System.Drawing.Point]$Location,
        [System.Drawing.Size]$Size = $(New-Object System.Drawing.Size(26, 26)),
        [string]$ToolTipText
    )
    $btn = New-Object System.Windows.Forms.Button
    $btn.Text=$Text; $btn.Location=$Location; $btn.Size=$Size
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize           = 0
    $btn.FlatAppearance.MouseOverBackColor   = $ColorPrimaryLight
    $btn.FlatAppearance.MouseDownBackColor   = $ColorPrimaryDark
    $btn.BackColor = $ColorSurface; $btn.ForeColor = $ColorText
    try   { $btn.Font = New-Object System.Drawing.Font("Segoe UI Emoji", 10, [System.Drawing.FontStyle]::Regular) }
    catch { $btn.Font = New-Object System.Drawing.Font("Segoe UI",       10, [System.Drawing.FontStyle]::Regular) }
    try { Set-RoundedRegion -Control $btn -Radius 8 } catch {}
    if ($ToolTipText) { $toolTip.SetToolTip($btn, $ToolTipText) }
    return $btn
}

function New-LinkLabel {
    param([string]$Text, [string]$Url, [System.Drawing.Point]$Location, [System.Drawing.Size]$Size)
    $ll = New-Object System.Windows.Forms.LinkLabel
    $ll.Text=$Text; $ll.AutoSize=$false; $ll.Location=$Location; $ll.Size=$Size
    $ll.LinkBehavior = [System.Windows.Forms.LinkBehavior]::HoverUnderline
    [void]$ll.Links.Add(0, $Text.Length, $Url)
    $ll.add_LinkClicked({ param($s,$e); try { Start-Process $e.Link.LinkData } catch {} })
    return $ll
}

function New-WorkingBox {
    param([string]$Text)
    $f = New-Object System.Windows.Forms.Form
    $f.Text="Trabajando..."; $f.Size=New-Object System.Drawing.Size(320,110)
    $f.FormBorderStyle=[System.Windows.Forms.FormBorderStyle]::FixedDialog
    $f.StartPosition="CenterParent"; $f.MaximizeBox=$false; $f.MinimizeBox=$false
    $f.ControlBox=$false; $f.TopMost=$true
    $lbl=New-Object System.Windows.Forms.Label; $lbl.Text=$Text; $lbl.AutoSize=$false
    $lbl.Size=New-Object System.Drawing.Size(300,30); $lbl.Location=New-Object System.Drawing.Point(10,10)
    $lbl.TextAlign="MiddleCenter"
    $prg=New-Object System.Windows.Forms.ProgressBar; $prg.Style="Marquee"
    $prg.MarqueeAnimationSpeed=25; $prg.Size=New-Object System.Drawing.Size(300,20)
    $prg.Location=New-Object System.Drawing.Point(10,45)
    $f.Controls.Add($lbl); $f.Controls.Add($prg); $f.Show() | Out-Null
    return @{ Form=$f; Label=$lbl }
}

# ═══════════════════════════════════════════════════════════════════════════════
#  LÓGICA GUI (funciones que mezclan UI + estado de app)
# ═══════════════════════════════════════════════════════════════════════════════

function Set-DownloadButtonVisual {
    $haveYt   = Test-CommandExists -Name "yt-dlp"
    $haveFfm  = Test-CommandExists -Name "ffmpeg"
    $haveNode = if ($script:RequireNode) { Test-CommandExists -Name "node" } else { $true }
    $depsOk   = $haveYt -and $haveFfm -and $haveNode
    if (-not $depsOk) {
        $btnDescargar.Enabled   = $false
        $btnDescargar.BackColor = [System.Drawing.Color]::Black
        $btnDescargar.ForeColor = [System.Drawing.Color]::White
        $btnDescargar.Text      = "Descargar"
        $toolTip.SetToolTip($btnDescargar,"Deshabilitado: instala/activa dependencias")
        $btnDescargar.Tag = $btnDescargar.BackColor
        return
    }
    $currentUrl = Get-CurrentUrl
    $isConsulted = $script:videoConsultado -and
                   -not [string]::IsNullOrWhiteSpace($script:ultimaURL) -and
                   ($script:ultimaURL -eq $currentUrl)
    $btnDescargar.Enabled = $true
    if (-not $isConsulted) {
        $btnDescargar.Text      = "Buscar Video"
        $btnDescargar.BackColor = [System.Drawing.Color]::DodgerBlue
        $btnDescargar.ForeColor = [System.Drawing.Color]::White
        $toolTip.SetToolTip($btnDescargar,"Aún no consultado: al hacer clic validará la URL")
    } elseif (-not $script:formatsEnumerated) {
        $btnDescargar.Text      = "Buscar Video"
        $btnDescargar.Enabled   = $true
        $btnDescargar.BackColor = [System.Drawing.Color]::DarkOrange
        $btnDescargar.ForeColor = [System.Drawing.Color]::White
        $toolTip.SetToolTip($btnDescargar,"No se pudieron extraer formatos. Presiona 'Buscar Video' para reintentar.")
        if ($lblEstadoConsulta) {
            $lblEstadoConsulta.Text     = "No fue posible extraer formatos. Presiona 'Buscar Video' para volver a consultar."
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
        }
    } else {
        $btnDescargar.Text      = "Descargar Video"
        $btnDescargar.BackColor = [System.Drawing.Color]::ForestGreen
        $btnDescargar.ForeColor = [System.Drawing.Color]::White
        $toolTip.SetToolTip($btnDescargar,"Consulta válida: listo para descargar")
    }
    $btnDescargar.Tag = $btnDescargar.BackColor
}

function Refresh-GateByDeps {
    $haveYt   = Test-CommandExists -Name "yt-dlp"
    $haveFfm  = Test-CommandExists -Name "ffmpeg"
    $haveNode = if ($script:RequireNode) { Test-CommandExists -Name "node" } else { $true }
    # $allOk = $haveYt -and $haveFfm -and $haveNode  # se evalúa dentro de Set-DownloadButtonVisual
    Set-DownloadButtonVisual
}

function Show-PreviewImage {
    param([Parameter(Mandatory=$true)][string]$ImageUrl, [string]$Titulo = $null)
    try {
        if ($ImageUrl -match '\.webp($|\?)') {
            $png = Convert-WebpUrlToPng -Url $ImageUrl
            if ($png -and (Test-Path $png)) {
                try { if ($picPreview.Image) { $picPreview.Image.Dispose() } } catch {}
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
            try { if ($picPreview.Image) { $picPreview.Image.Dispose() } } catch {}
            $picPreview.Image = $img
            if ($Titulo) { $toolTip.SetToolTip($picPreview, $Titulo) }
            return $true
        }
        return $false
    } catch { return $false }
}

function Show-PreviewUniversal {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$Titulo = $null,
        [string]$DirectThumbUrl = $null
    )
    $lblEstadoConsulta.Text     = "Obteniendo miniaturas..."
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkBlue
    $thumbFile = Fetch-ThumbnailFile -Url $Url
    if ($thumbFile -and (Test-Path $thumbFile)) {
        try {
            if ($picPreview.Image) { $picPreview.Image.Dispose() }
            $imgW = [System.Drawing.Image]::FromFile($thumbFile)
            $picPreview.Image = $imgW
            if ($Titulo) { $toolTip.SetToolTip($picPreview, $Titulo) }
            $lblEstadoConsulta.Text     = "Vista previa cargada"
            $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
            Start-Job -ScriptBlock { param($f); Start-Sleep -Seconds 5; try { Remove-Item $f -Force -ErrorAction SilentlyContinue } catch {} } -ArgumentList $thumbFile | Out-Null
            return $true
        } catch {}
    }
    $thumbList = Get-ThumbnailListFromYtDlp -Url $Url
    if ($thumbList -and $thumbList.Count -gt 0) {
        $sortedThumbs = $thumbList | Sort-Object @{Expression={$_.Width * $_.Height};Descending=$true} | Select-Object -First 3
        foreach ($thumb in $sortedThumbs) {
            if (Show-PreviewImage -ImageUrl $thumb.Url -Titulo $Titulo) {
                $lblEstadoConsulta.Text     = "Vista previa cargada"
                $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
                return $true
            }
        }
    }
    if ($DirectThumbUrl -and (Show-PreviewImage -ImageUrl $DirectThumbUrl -Titulo $Titulo)) {
        $lblEstadoConsulta.Text     = "Vista previa cargada"
        $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkGreen
        return $true
    }
    $lblEstadoConsulta.Text     = "No se pudo cargar vista previa"
    $lblEstadoConsulta.ForeColor = [System.Drawing.Color]::DarkOrange
    return $false
}

# ═══════════════════════════════════════════════════════════════════════════════
#  VENTANAS SECUNDARIAS
# ═══════════════════════════════════════════════════════════════════════════════

function Show-AppInfo {
    $f = New-Object System.Windows.Forms.Form
    $f.Text = "Información de la aplicación"
    $f.Size = New-Object System.Drawing.Size(520, 850)
    $f.StartPosition = "CenterParent"
    $f.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $f.MaximizeBox = $false; $f.MinimizeBox = $false
    $f.BackColor = [System.Drawing.Color]::White

    $lblTitulo = Create-Label -Text "YTDLL — Información" `
        -Location (New-Object System.Drawing.Point(20,16)) -Size (New-Object System.Drawing.Size(460,28)) -IsTitle
    $lblVer = Create-Label -Text ("Versión: {0}" -f $version) `
        -Location (New-Object System.Drawing.Point(20,46)) -Size (New-Object System.Drawing.Size(460,22)) -Font $defaultFont
    $chkDebug = New-Object System.Windows.Forms.CheckBox
    $chkDebug.Location = New-Object System.Drawing.Point(20, 76)
    $chkDebug.Size     = New-Object System.Drawing.Size(200, 24)
    $chkDebug.Text     = "Mostrar debug en consola"
    $chkDebug.Checked  = $script:DebugEnabled
    $chkDebug.Add_CheckedChanged({
        $script:DebugEnabled = $chkDebug.Checked
        Set-IniValue -Section "DEBUG" -Key "ConsoleDebug" -Value ($script:DebugEnabled.ToString().ToLower())
    })
    $lblCamb = Create-Label -Text "Cambios recientes:" `
        -Location (New-Object System.Drawing.Point(20,106)) -Size (New-Object System.Drawing.Size(460,20)) -IsTitle
    $psBlue = [System.Drawing.Color]::FromArgb(1,36,86); $psText = [System.Drawing.Color]::Gainsboro
    $fontCambios = New-Object System.Drawing.Font("Consolas", 10)
    if ($fontCambios.Name -ne "Consolas") { $fontCambios = New-Object System.Drawing.Font("Lucida Console", 10) }
    $txtCamb = New-Object System.Windows.Forms.RichTextBox
    $txtCamb.Location=$([System.Drawing.Point]::new(20,128)); $txtCamb.Size=$([System.Drawing.Size]::new(460,150))
    $txtCamb.ReadOnly=$true; $txtCamb.BorderStyle=[System.Windows.Forms.BorderStyle]::None
    $txtCamb.BackColor=$psBlue; $txtCamb.ForeColor=$psText; $txtCamb.Font=$fontCambios
    $txtCamb.Multiline=$true; $txtCamb.WordWrap=$false
    $txtCamb.ScrollBars=[System.Windows.Forms.RichTextBoxScrollBars]::Both; $txtCamb.DetectUrls=$false
    $txtCamb.Text = ($global:defaultInstructions -replace "`r?`n","`r`n")

    $lblDeps   = Create-Label -Text "Dependencias detectadas:" -Location (New-Object System.Drawing.Point(20,288)) -Size (New-Object System.Drawing.Size(460,22)) -IsTitle
    $lblYtDlp  = Create-Label -Text "yt-dlp: verificando..."  -Location (New-Object System.Drawing.Point(40,315))  -Size (New-Object System.Drawing.Size(300,24)) -Font $defaultFont -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle)
    $lblFfmpeg = Create-Label -Text "ffmpeg: verificando..."  -Location (New-Object System.Drawing.Point(40,345))  -Size (New-Object System.Drawing.Size(300,24)) -Font $defaultFont -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle)
    $lblNode   = Create-Label -Text "Node.js: verificando..."  -Location (New-Object System.Drawing.Point(40,375)) -Size (New-Object System.Drawing.Size(300,24)) -Font $defaultFont -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle)
    $lblMpvNet = Create-Label -Text "mpv.net: verificando..."  -Location (New-Object System.Drawing.Point(40,405)) -Size (New-Object System.Drawing.Size(300,24)) -Font $defaultFont -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle)

    $btnYtRefresh      = Create-IconButton -Text "↻" -Location (New-Object System.Drawing.Point(350,315)) -ToolTipText "Buscar/actualizar yt-dlp"  -Size (New-Object System.Drawing.Size(24,24))
    $btnYtUninstall    = Create-IconButton -Text "✖" -Location (New-Object System.Drawing.Point(380,315)) -ToolTipText "Desinstalar yt-dlp"         -Size (New-Object System.Drawing.Size(24,24))
    $btnFfmpegRefresh  = Create-IconButton -Text "↻" -Location (New-Object System.Drawing.Point(350,345)) -ToolTipText "Buscar/actualizar ffmpeg"   -Size (New-Object System.Drawing.Size(24,24))
    $btnFfmpegUninstall= Create-IconButton -Text "✖" -Location (New-Object System.Drawing.Point(380,345)) -ToolTipText "Desinstalar ffmpeg"          -Size (New-Object System.Drawing.Size(24,24))
    $btnNodeRefresh    = Create-IconButton -Text "↻" -Location (New-Object System.Drawing.Point(350,375)) -ToolTipText "Buscar/actualizar Node.js"  -Size (New-Object System.Drawing.Size(24,24))
    $btnNodeUninstall  = Create-IconButton -Text "✖" -Location (New-Object System.Drawing.Point(380,375)) -ToolTipText "Desinstalar Node.js"         -Size (New-Object System.Drawing.Size(24,24))
    $btnMpvNetRefresh  = Create-IconButton -Text "↻" -Location (New-Object System.Drawing.Point(350,405)) -ToolTipText "Buscar/actualizar mpv.net"  -Size (New-Object System.Drawing.Size(24,24))
    $btnMpvNetUninstall= Create-IconButton -Text "✖" -Location (New-Object System.Drawing.Point(380,405)) -ToolTipText "Desinstalar mpv.net"         -Size (New-Object System.Drawing.Size(24,24))

    Refresh-DependencyLabel -CommandName "yt-dlp"  -FriendlyName "yt-dlp"  -LabelRef ([ref]$lblYtDlp)  -VersionArgs "--version" -Parse "FirstLine"
    Refresh-DependencyLabel -CommandName "ffmpeg"  -FriendlyName "ffmpeg"  -LabelRef ([ref]$lblFfmpeg) -VersionArgs "-version"  -Parse "FirstLine"
    if ($script:RequireNode) {
        Refresh-DependencyLabel -CommandName "node" -FriendlyName "Node.js" -LabelRef ([ref]$lblNode) -VersionArgs "--version" -Parse "FirstLine"
    }
    Refresh-DependencyLabel -CommandName "mpvnet"  -FriendlyName "mpv.net" -LabelRef ([ref]$lblMpvNet) -VersionArgs "--version" -Parse "FirstLine"

    $btnYtRefresh.Add_Click(    { Update-Dependency   -ChocoPkg "yt-dlp"  -FriendlyName "yt-dlp"  -CommandName "yt-dlp"  -LabelRef ([ref]$lblYtDlp)  -VersionArgs "--version" -Parse "FirstLine" })
    $btnYtUninstall.Add_Click(  { Uninstall-Dependency -ChocoPkg "yt-dlp"  -FriendlyName "yt-dlp"  -LabelRef ([ref]$lblYtDlp) })
    $btnFfmpegRefresh.Add_Click({ Update-Dependency   -ChocoPkg "ffmpeg"  -FriendlyName "ffmpeg"  -CommandName "ffmpeg"  -LabelRef ([ref]$lblFfmpeg) -VersionArgs "-version"  -Parse "FirstLine" })
    $btnFfmpegUninstall.Add_Click({Uninstall-Dependency -ChocoPkg "ffmpeg"  -FriendlyName "ffmpeg"  -LabelRef ([ref]$lblFfmpeg) })
    $btnNodeRefresh.Add_Click(  { Update-Dependency   -ChocoPkg "nodejs-lts" -FriendlyName "Node.js" -CommandName "node"  -LabelRef ([ref]$lblNode)   -VersionArgs "--version" -Parse "FirstLine" })
    $btnNodeUninstall.Add_Click({ Uninstall-Dependency -ChocoPkg "nodejs-lts" -FriendlyName "Node.js" -LabelRef ([ref]$lblNode) })
    $btnMpvNetRefresh.Add_Click({
        if (-not (Ensure-DotNet6DesktopRuntime)) { return }
        Update-Dependency -ChocoPkg "mpv.net" -FriendlyName "mpv.net" -CommandName "mpvnet" -LabelRef ([ref]$lblMpvNet) -VersionArgs "--version" -Parse "FirstLine"
    })
    $btnMpvNetUninstall.Add_Click({
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            [System.Windows.Forms.MessageBox]::Show("Chocolatey no está disponible.","Chocolatey requerido",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
            return
        }
        $r = [System.Windows.Forms.MessageBox]::Show(
            "Se desinstalarán: mpv.net, mpvnet.portable y .NET 6 Desktop Runtime.`n¿Continuar?",
            "Desinstalar mpv.net + dependencias",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Warning)
        if ($r -eq [System.Windows.Forms.DialogResult]::Yes) {
            Uninstall-Dependency -ChocoPkg "mpv.net" -FriendlyName "mpv.net" -LabelRef ([ref]$lblMpvNet)
            try { choco uninstall mpvnet.portable -y | Out-Null } catch {}
            try { choco uninstall "Microsoft .NET 6 Desktop Runtime" -y | Out-Null } catch {}
        }
    })

    $lblLinks   = Create-Label -Text "Proyectos:" -Location (New-Object System.Drawing.Point(20,440)) -Size (New-Object System.Drawing.Size(460,22)) -IsTitle
    $lnkApp     = New-LinkLabel -Text "PWytdll (GitHub)"  -Url "https://github.com/water0ff/PWytdll/tree/main" -Location (New-Object System.Drawing.Point(20,466)) -Size (New-Object System.Drawing.Size(460,20))
    $lblAppDesc = Create-Label -Text "Script principal en PowerShell: interfaz gráfica y lógica de YTDLL." -Location (New-Object System.Drawing.Point(40,484)) -Size (New-Object System.Drawing.Size(440,18)) -IsTag
    $lnkYt      = New-LinkLabel -Text "yt-dlp"   -Url "https://github.com/yt-dlp/yt-dlp" -Location (New-Object System.Drawing.Point(20,508)) -Size (New-Object System.Drawing.Size(460,20))
    $lblYtDesc  = Create-Label -Text "Extractor/descargador de video/audio usado como motor principal." -Location (New-Object System.Drawing.Point(40,526)) -Size (New-Object System.Drawing.Size(440,18)) -IsTag
    $lnkFf      = New-LinkLabel -Text "FFmpeg"   -Url "https://ffmpeg.org/" -Location (New-Object System.Drawing.Point(20,550)) -Size (New-Object System.Drawing.Size(460,20))
    $lblFfDesc  = Create-Label -Text "Herramienta para conversión, fusión de streams y capturas de miniaturas." -Location (New-Object System.Drawing.Point(40,568)) -Size (New-Object System.Drawing.Size(440,18)) -IsTag
    $lnkNd      = New-LinkLabel -Text "Node.js"  -Url "https://nodejs.org/" -Location (New-Object System.Drawing.Point(20,592)) -Size (New-Object System.Drawing.Size(460,20))
    $lblNdDesc  = Create-Label -Text "Dependencia adicional (Node.js LTS) requerida para ciertas tareas internas." -Location (New-Object System.Drawing.Point(40,610)) -Size (New-Object System.Drawing.Size(440,18)) -IsTag
    $lnkMpv     = New-LinkLabel -Text "mpv.net"  -Url "https://github.com/stax76/mpv.net" -Location (New-Object System.Drawing.Point(20,634)) -Size (New-Object System.Drawing.Size(460,20))
    $lblMpvDesc = Create-Label -Text "Reproductor de video basado en mpv, usado para la vista previa/reproducción." -Location (New-Object System.Drawing.Point(40,652)) -Size (New-Object System.Drawing.Size(440,18)) -IsTag

    $btnActualizarTodo = Create-Button -Text "ACTUALIZAR TODO" -Location (New-Object System.Drawing.Point(20,680)) -Size (New-Object System.Drawing.Size(150,30)) -BackColor $ColorPrimary -ForeColor ([System.Drawing.Color]::White)
    $btnCerrar         = Create-Button -Text "Cerrar"          -Location (New-Object System.Drawing.Point(380,680)) -Size (New-Object System.Drawing.Size(100,30)) -BackColor ([System.Drawing.Color]::Black) -ForeColor ([System.Drawing.Color]::White)

    $btnActualizarTodo.Add_Click({
        if (-not (Check-Chocolatey)) { return }
        [void](Ensure-DotNet6DesktopRuntime)
        Update-Dependency -ChocoPkg "yt-dlp"      -FriendlyName "yt-dlp"  -CommandName "yt-dlp"  -LabelRef ([ref]$lblYtDlp)  -VersionArgs "--version" -Parse "FirstLine"
        Update-Dependency -ChocoPkg "ffmpeg"       -FriendlyName "ffmpeg"  -CommandName "ffmpeg"  -LabelRef ([ref]$lblFfmpeg) -VersionArgs "-version"  -Parse "FirstLine"
        if ($script:RequireNode) {
            Update-Dependency -ChocoPkg "nodejs-lts" -FriendlyName "Node.js" -CommandName "node" -LabelRef ([ref]$lblNode) -VersionArgs "--version" -Parse "FirstLine"
        }
        Update-Dependency -ChocoPkg "mpv.net"     -FriendlyName "mpv.net" -CommandName "mpvnet"  -LabelRef ([ref]$lblMpvNet) -VersionArgs "--version" -Parse "FirstLine"
    })
    $btnCerrar.Add_Click({ $f.Close() })

    $f.Controls.AddRange(@(
        $lblTitulo,$lblVer,$chkDebug,$lblCamb,$txtCamb,
        $lblDeps,$lblYtDlp,$lblFfmpeg,$lblNode,$lblMpvNet,
        $btnYtRefresh,$btnYtUninstall,$btnFfmpegRefresh,$btnFfmpegUninstall,
        $btnNodeRefresh,$btnNodeUninstall,$btnMpvNetRefresh,$btnMpvNetUninstall,
        $lblLinks,$lnkApp,$lblAppDesc,$lnkYt,$lblYtDesc,$lnkFf,$lblFfDesc,$lnkNd,$lblNdDesc,$lnkMpv,$lblMpvDesc,
        $btnActualizarTodo,$btnCerrar
    ))
    $f.ShowDialog() | Out-Null
}

function Show-SitesDialog {
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch {
        [System.Windows.Forms.MessageBox]::Show("yt-dlp no está disponible.","Error") | Out-Null; return
    }
    $res = Invoke-CaptureResponsive -ExePath $yt.Source -Args @("--list-extractors") -WorkingText "Obteniendo sitios…"
    $raw = ($res.StdOut + "`r`n" + $res.StdErr)
    $fmt = Format-ExtractorsInline -RawText $raw -WrapAt 120
    $allSites = [System.Collections.ArrayList]::new(); $null = $allSites.AddRange($fmt.List)

    $dlg     = Create-Form -Title ("Sitios compatibles — {0} detectados" -f $fmt.Count) -Size (New-Object System.Drawing.Size(900,560))
    $txtFiltro = Create-TextBox -Location (New-Object System.Drawing.Point(10,10)) -Size (New-Object System.Drawing.Size(780,28)) -Text "(buscar sitio)"
    $txtFiltro.ForeColor = [System.Drawing.Color]::Gray
    $txtFiltro.Add_GotFocus({  if ($this.Text -eq "(buscar sitio)") { $this.Text=""; $this.ForeColor=[System.Drawing.Color]::Black } })
    $txtFiltro.Add_LostFocus({ if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text="(buscar sitio)"; $this.ForeColor=[System.Drawing.Color]::Gray } })
    $lblCount = Create-Label -Text ("0/{0}" -f $allSites.Count) -Location (New-Object System.Drawing.Point(800,12)) -Size (New-Object System.Drawing.Size(80,28)) -TextAlign ([System.Drawing.ContentAlignment]::MiddleRight)
    $lst = New-Object System.Windows.Forms.ListBox
    $lst.Location = New-Object System.Drawing.Point(10,44); $lst.Size = New-Object System.Drawing.Size(864,440)
    $lst.Font = New-Object System.Drawing.Font("Consolas",9); $lst.IntegralHeight = $false
    $btnCopy  = Create-Button -Text "Copiar selección" -Location (New-Object System.Drawing.Point(664,490)) -Size (New-Object System.Drawing.Size(120,30))
    $btnClose = Create-Button -Text "Cerrar"            -Location (New-Object System.Drawing.Point(794,490)) -Size (New-Object System.Drawing.Size(80,30))
    function Refresh-List([string]$term) {
        $lst.BeginUpdate()
        try {
            $lst.Items.Clear()
            $items = $allSites
            if ($term -and $term -ne "(buscar sitio)") { $rx = [regex]::Escape($term); $items = $allSites | Where-Object { $_ -match $rx } }
            $items | ForEach-Object { [void]$lst.Items.Add($_) }
            $lblCount.Text = ("{0}/{1}" -f $lst.Items.Count, $allSites.Count)
        } finally { $lst.EndUpdate() }
    }
    Refresh-List $null
    $txtFiltro.Add_TextChanged({ if ($this.ForeColor -eq [System.Drawing.Color]::Gray) { return }; Refresh-List $this.Text.Trim() })
    $btnCopy.Add_Click({ if ($lst.SelectedItem) { try { [System.Windows.Forms.Clipboard]::SetText([string]$lst.SelectedItem) } catch {} } })
    $lst.Add_DoubleClick({ if ($lst.SelectedItem) { try { [System.Windows.Forms.Clipboard]::SetText([string]$lst.SelectedItem) } catch {} } })
    $lst.Add_KeyDown({ param($s,$e); if ($e.KeyCode -eq 'Enter' -and $lst.SelectedItem) { try { [System.Windows.Forms.Clipboard]::SetText([string]$lst.SelectedItem) } catch {}; $e.Handled=$true } })
    $btnClose.Add_Click({ $dlg.Close() })
    $dlg.Controls.AddRange(@($txtFiltro,$lblCount,$lst,$btnCopy,$btnClose))
    $dlg.ShowDialog() | Out-Null
}

function Show-UrlHistoryMenu {
    param([Parameter(Mandatory=$true)][System.Windows.Forms.Control]$AnchorControl)
    $ctxUrlHistory.Items.Clear()
    Start-Sleep -Milliseconds 100
    [System.Windows.Forms.Application]::DoEvents()
    $items = @()
    try {
        if (Test-Path -LiteralPath $script:LogFile) {
            $content = [System.IO.File]::ReadAllText($script:LogFile, [System.Text.Encoding]::UTF8)
            $items = @($content -split "`r?`n" | ForEach-Object { $_.Trim() } | Where-Object { $_ -and ($_ -notmatch '^\s*$') } | Select-Object -Unique)
        }
    } catch {
        try { $items = @(Get-Content -LiteralPath $script:LogFile -ErrorAction Stop | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique) } catch { $items = @() }
    }
    if (-not $items -or $items.Count -eq 0) {
        $mi = New-Object System.Windows.Forms.ToolStripMenuItem; $mi.Text = "(Sin historial)"; $mi.Enabled = $false
        [void]$ctxUrlHistory.Items.Add($mi)
    } else {
        $top = [Math]::Min(12, $items.Count)
        for ($i = 0; $i -lt $top; $i++) {
            $displayText = [string]$items[$i]
            if ([string]::IsNullOrWhiteSpace($displayText)) { continue }
            $urlItem = New-Object System.Windows.Forms.ToolStripMenuItem
            $urlItem.Text = $displayText; $urlItem.ToolTipText = $displayText
            $urlItem.add_Click({
                param($sender, $e)
                $fullText = [string]($sender -as [System.Windows.Forms.ToolStripMenuItem]).Text
                $urlToSet = if ($fullText -match '\|\s*(.+)$') { $matches[1].Trim() } else { $fullText }
                $txtUrl.Text = $urlToSet; $txtUrl.ForeColor = [System.Drawing.Color]::Black
                $txtUrl.SelectionStart = $txtUrl.Text.Length; $txtUrl.SelectionLength = 0
            })
            [void]$ctxUrlHistory.Items.Add($urlItem)
        }
        [void]$ctxUrlHistory.Items.Add((New-Object System.Windows.Forms.ToolStripSeparator))
        $miClear = New-Object System.Windows.Forms.ToolStripMenuItem; $miClear.Text = "Borrar historial"; $miClear.ForeColor = [System.Drawing.Color]::Crimson
        $miClear.add_Click({
            $r = [System.Windows.Forms.MessageBox]::Show("¿Seguro que deseas borrar el historial de URLs?","Confirmar",[System.Windows.Forms.MessageBoxButtons]::YesNo,[System.Windows.Forms.MessageBoxIcon]::Question)
            if ($r -eq [System.Windows.Forms.DialogResult]::Yes) { Clear-History }
        })
        [void]$ctxUrlHistory.Items.Add($miClear)
    }
    $ctxUrlHistory.Show($AnchorControl, (New-Object System.Drawing.Point(0, $AnchorControl.Height)))
}

# ═══════════════════════════════════════════════════════════════════════════════
#  CONSTRUCCIÓN DEL FORMULARIO PRINCIPAL
#  Todo el código de aquí en adelante se ejecuta al hacer dot-source de este archivo.
#  Los controles quedan disponibles en el scope del llamador (Main.ps1).
# ═══════════════════════════════════════════════════════════════════════════════

$formPrincipal = New-Object System.Windows.Forms.Form
$formPrincipal.Size          = New-Object System.Drawing.Size(400, 650)
$formPrincipal.StartPosition = "CenterScreen"
$formPrincipal.BackColor     = $ColorBgForm
$formPrincipal.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::None
$formPrincipal.ControlBox    = $false
$formPrincipal.MaximizeBox   = $false
$formPrincipal.MinimizeBox   = $false
$formPrincipal.Opacity       = 0.97

$formPrincipal.Add_Shown({   param($sender,$e); Set-RoundedRegion -Control $sender -Radius 20 })
$formPrincipal.Add_Resize({  param($sender,$e); Set-RoundedRegion -Control $sender -Radius 20 })
$formPrincipal.Add_MouseDown({
    param($sender,$e)
    if ($e.Button -eq [System.Windows.Forms.MouseButtons]::Left) {
        [NativeDrag]::ReleaseCapture() | Out-Null
        [NativeDrag]::SendMessage($sender.Handle,[NativeDrag]::WM_NCLBUTTONDOWN,[NativeDrag]::HTCAPTION,0) | Out-Null
    }
})

# ── Controles principales ──────────────────────────────────────────────────────
$btnPickCookies = Create-IconButton -Text "🍪" -Location (New-Object System.Drawing.Point(320,10)) -ToolTipText "Seleccionar cookies.txt (opcional)"
$btnInfo        = Create-IconButton -Text "?"  -Location (New-Object System.Drawing.Point(340,10)) -ToolTipText "Información de la aplicación"
$btnInfo.Anchor = [System.Windows.Forms.AnchorStyles]::Top -bor [System.Windows.Forms.AnchorStyles]::Right
$btnInfo.Size   = New-Object System.Drawing.Size(26, 24)

$lblDestino  = Create-Label -Text "Carpeta de destino:" -Location (New-Object System.Drawing.Point(20,15))  -Size (New-Object System.Drawing.Size(130,20)) -IsTitle
$txtDestino  = Create-TextBox -Location (New-Object System.Drawing.Point(20,38)) -Size (New-Object System.Drawing.Size(330,26)) -ReadOnly $true -Text $script:ultimaRutaDescarga
$btnPickDestino = Create-IconButton -Text "📁" -Location (New-Object System.Drawing.Point(356,38))  -ToolTipText "Cambiar carpeta de destino"

$lblVideoFmt = Create-Label -Text "Formato de VIDEO:" -Location (New-Object System.Drawing.Point(20,70)) -Size (New-Object System.Drawing.Size(130,20)) -IsTitle
$cmbVideoFmt = Create-ComboBox -Location (New-Object System.Drawing.Point(20,93))  -Size (New-Object System.Drawing.Size(360,28))
$lblAudioFmt = Create-Label -Text "Formato de AUDIO:" -Location (New-Object System.Drawing.Point(20,125)) -Size (New-Object System.Drawing.Size(130,20)) -IsTitle
$cmbAudioFmt = Create-ComboBox -Location (New-Object System.Drawing.Point(20,148)) -Size (New-Object System.Drawing.Size(360,28))

$txtUrl = Create-TextBox -Location (New-Object System.Drawing.Point(20,180)) -Size (New-Object System.Drawing.Size(330,40)) `
    -Font (New-Object System.Drawing.Font("Segoe UI",16,[System.Drawing.FontStyle]::Regular)) `
    -Text $global:UrlPlaceholder -BackColor ([System.Drawing.Color]::FromArgb(255,255,220)) `
    -ForeColor ([System.Drawing.Color]::Gray) -Multiline $false -ScrollBars ([System.Windows.Forms.ScrollBars]::None)
$txtUrl.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$txtUrl.TextAlign   = [System.Windows.Forms.HorizontalAlignment]::Center

$txtUrl.Add_TextChanged({
    if ($txtUrl.Text -ne $global:UrlPlaceholder -and -not [string]::IsNullOrWhiteSpace($txtUrl.Text)) {
        $toolTip.SetToolTip($txtUrl, (Get-DisplayUrl -Url $txtUrl.Text))
        $txtUrl.ForeColor = [System.Drawing.Color]::Black
        $currentUrl = Get-CurrentUrl
        if ($script:videoConsultado -and $script:ultimaURL -ne $currentUrl) {
            $script:videoConsultado   = $false
            $script:formatsEnumerated = $false
        }
    } else { $toolTip.SetToolTip($txtUrl,"") }
    Set-DownloadButtonVisual
})
$txtUrl.Add_LostFocus({ if ([string]::IsNullOrWhiteSpace($this.Text)) { $this.Text=$global:UrlPlaceholder; $this.ForeColor=[System.Drawing.Color]::Gray }; $this.BackColor=[System.Drawing.Color]::FromArgb(255,255,220) })
$txtUrl.Add_GotFocus({ if ($this.Text -eq $global:UrlPlaceholder) { $this.Text=""; $this.ForeColor=[System.Drawing.Color]::Black }; $this.BackColor=[System.Drawing.Color]::White })

$ctxUrlHistory  = New-Object System.Windows.Forms.ContextMenuStrip
$btnUrlHistory  = Create-IconButton -Text "▾" -Location (New-Object System.Drawing.Point(356,186)) -ToolTipText "Historial de URLs"
$btnUrlHistory.Size = New-Object System.Drawing.Size(24,28)
$btnUrlHistory.Add_Click({ Show-UrlHistoryMenu -AnchorControl $btnUrlHistory })

$btnDescargar = Create-Button -Text "Descargar" -Location (New-Object System.Drawing.Point(20,230)) -Size (New-Object System.Drawing.Size(360,50)) `
    -BackColor $ColorPrimary -ForeColor ([System.Drawing.Color]::White) -ToolTipText "Descargar usando bestvideo+bestaudio -> mp4"

$lblPreview = Create-Label -Text "Vista previa:" -Location (New-Object System.Drawing.Point(20,280)) -Size (New-Object System.Drawing.Size(130,22)) -IsTitle
$picPreview = New-Object System.Windows.Forms.PictureBox
$picPreview.Location   = New-Object System.Drawing.Point(20,305)
$picPreview.Size       = New-Object System.Drawing.Size(360,203)
$picPreview.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$picPreview.SizeMode   = [System.Windows.Forms.PictureBoxSizeMode]::Zoom
$picPreview.BackColor  = [System.Drawing.Color]::White
$picPreview.Add_Click({
    if (-not $script:videoConsultado -or [string]::IsNullOrWhiteSpace($script:ultimaURL)) {
        [System.Windows.Forms.MessageBox]::Show("Primero consulta un video para poder reproducirlo.","Sin consulta",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Information) | Out-Null
        return
    }
    $cmd = $null
    try { $cmd = Get-Command "mpvnet" -ErrorAction Stop } catch {
        [System.Windows.Forms.MessageBox]::Show("mpv.net no está disponible en el PATH.","mpv.net no encontrado",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Warning) | Out-Null
        return
    }
    $playUrl = $null
    try { $playUrl = Get-BestStreamUrl -Url $script:ultimaURL } catch { $playUrl = $null }
    if (-not $playUrl) { $playUrl = $script:ultimaURL }
    try {
        Start-Process -FilePath $cmd.Source -ArgumentList @($playUrl,"--title=YTDLL Preview","--ontop=yes","--geometry=50%:50%","--autofit=60%") | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show("No se pudo iniciar mpv.net.","Error al abrir mpv.net",[System.Windows.Forms.MessageBoxButtons]::OK,[System.Windows.Forms.MessageBoxIcon]::Error) | Out-Null
    }
})

$lblEstadoConsulta = Create-Label -Text "Estado: sin consultar" `
    -Location (New-Object System.Drawing.Point(20,510)) -Size (New-Object System.Drawing.Size(360,70)) `
    -Font (New-Object System.Drawing.Font("Consolas",10)) `
    -BorderStyle ([System.Windows.Forms.BorderStyle]::FixedSingle) `
    -TextAlign ([System.Drawing.ContentAlignment]::MiddleCenter)
$lblEstadoConsulta.ForeColor = [System.Drawing.Color]::Black
$lblEstadoConsulta.AutoEllipsis = $false
$lblEstadoConsulta.UseCompatibleTextRendering = $true

$btnExit  = Create-Button -Text "Salir"             -Location (New-Object System.Drawing.Point(20,590))  -Size (New-Object System.Drawing.Size(160,30)) -BackColor ([System.Drawing.Color]::Black) -ForeColor ([System.Drawing.Color]::White) -ToolTipText "Cerrar la aplicación"
$btnSites = Create-Button -Text "Sitios compatibles" -Location (New-Object System.Drawing.Point(220,590)) -Size (New-Object System.Drawing.Size(160,30)) -BackColor $ColorAccent -ForeColor $ColorText -ToolTipText "Mostrar extractores de yt-dlp"

# ── Agregar controles al formulario ───────────────────────────────────────────
$formPrincipal.Controls.AddRange(@(
    $btnExit, $lblVideoFmt, $btnPickCookies, $btnInfo,
    $cmbVideoFmt, $lblAudioFmt, $cmbAudioFmt,
    $lblDestino, $txtDestino, $btnPickDestino,
    $btnSites, $lblPreview, $picPreview,
    $txtUrl, $btnUrlHistory, $lblEstadoConsulta,
    $btnDescargar
))
