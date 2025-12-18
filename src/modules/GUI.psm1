# Variables de estilo globales
$script:defaultFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
$script:boldFont = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Bold)
$script:ColorBgForm = [System.Drawing.Color]::FromArgb(209, 209, 214)
$script:ColorPrimary = [System.Drawing.Color]::FromArgb(94, 92, 230)
$script:ColorPrimaryDark = [System.Drawing.Color]::FromArgb(0, 92, 197)
$script:ColorPrimaryLight = [System.Drawing.Color]::FromArgb(142, 209, 255)
$script:ColorSurface = [System.Drawing.Color]::FromArgb(255, 255, 255)
$script:ColorPanel = [System.Drawing.Color]::FromArgb(242, 242, 247)
$script:ColorText = [System.Drawing.Color]::FromArgb(28, 28, 30)
$script:ColorSubText = [System.Drawing.Color]::FromArgb(142, 142, 147)
$script:ColorAccent = [System.Drawing.Color]::FromArgb(72, 169, 197)

# Soporte para arrastrar ventana sin borde
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

# Función para bordes redondeados
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

# Función para crear botones con íconos
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
    $btn.Text = $Text
    $btn.Location = $Location
    $btn.Size = $Size
    $btn.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $btn.FlatAppearance.BorderSize = 0
    $btn.FlatAppearance.MouseOverBackColor = $script:ColorPrimaryLight
    $btn.FlatAppearance.MouseDownBackColor = $script:ColorPrimaryDark
    $btn.BackColor = $script:ColorSurface
    $btn.ForeColor = $script:ColorText

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
    }

    return $btn
}

# Función para crear LinkLabel
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

# Función para crear botones
function Create-Button {
    param (
        [string]$Text,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$BackColor = $script:ColorPrimary,
        [System.Drawing.Color]$ForeColor = [System.Drawing.Color]::White,
        [string]$ToolTipText = $null,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(220, 35)),
        [System.Drawing.Font]$Font = $script:defaultFont,
        [bool]$Enabled = $true
    )
    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Size = $Size
    $button.Location = $Location
    $button.BackColor = $BackColor
    $button.ForeColor = $ForeColor
    $button.Font = $Font
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderSize = 0
    $button.FlatAppearance.MouseDownBackColor = $script:ColorPrimaryDark
    $button.FlatAppearance.MouseOverBackColor = $script:ColorPrimary
    $button.Tag = $BackColor

    $button_MouseEnter = {
        $this.BackColor = $script:ColorPrimaryDark
        $this.Font = $script:boldFont
        $this.Cursor = [System.Windows.Forms.Cursors]::Hand
    }
    $button_MouseLeave = {
        $this.BackColor = $this.Tag
        $this.Font = $script:defaultFont
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
    if ($ToolTipText) { $script:toolTip.SetToolTip($button, $ToolTipText) }

    return $button
}

# Función para crear etiquetas
function Create-Label {
    param(
        [string]$Text,
        [System.Drawing.Point]$Location,
        [System.Drawing.Color]$BackColor = [System.Drawing.Color]::Transparent,
        [System.Drawing.Color]$ForeColor = $script:ColorText,
        [string]$ToolTipText = $null,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(200, 30)),
        [System.Drawing.Font]$Font = $script:defaultFont,
        [System.Windows.Forms.BorderStyle]$BorderStyle = [System.Windows.Forms.BorderStyle]::None,
        [System.Drawing.ContentAlignment]$TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft,
        [switch]$IsTitle,
        [switch]$IsTag
    )
    $label = New-Object System.Windows.Forms.Label
    $label.Text = $Text
    $label.Size = $Size
    $label.Location = $Location
    $label.BackColor = $BackColor
    $label.ForeColor = $ForeColor
    $label.Font = $Font
    $label.BorderStyle = $BorderStyle
    $label.TextAlign = $TextAlign

    if ($IsTitle) {
        $label.Font = $script:boldFont
        $label.ForeColor = $script:ColorPrimaryDark
    }
    if ($IsTag) {
        $label.BackColor = [System.Drawing.Color]::FromArgb(230,235,245)
        $label.ForeColor = $script:ColorSubText
    }

    if ($ToolTipText) { $script:toolTip.SetToolTip($label, $ToolTipText) }
    return $label
}

# Función para crear formularios
function Create-Form {
    param(
        [Parameter(Mandatory=$true)][string]$Title,
        [Parameter()][System.Drawing.Size]$Size = (New-Object System.Drawing.Size(350,200)),
        [Parameter()][System.Windows.Forms.FormStartPosition]$StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen,
        [Parameter()][System.Windows.Forms.FormBorderStyle]$FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog,
        [Parameter()][bool]$MaximizeBox = $false,
        [Parameter()][bool]$MinimizeBox = $false,
        [Parameter()][bool]$TopMost = $false,
        [Parameter()][bool]$ControlBox = $true,
        [Parameter()][System.Drawing.Icon]$Icon = $null,
        [Parameter()][System.Drawing.Color]$BackColor = [System.Drawing.SystemColors]::Control
    )
    $form = New-Object System.Windows.Forms.Form
    $form.Text=$Title
    $form.Size=$Size
    $form.StartPosition=$StartPosition
    $form.FormBorderStyle=$FormBorderStyle
    $form.MaximizeBox=$MaximizeBox
    $form.MinimizeBox=$MinimizeBox
    $form.TopMost=$TopMost
    $form.ControlBox=$ControlBox
    if ($Icon) { $form.Icon = $Icon }
    $form.BackColor = $BackColor
    return $form
}

# Función para crear ComboBox
function Create-ComboBox {
    param(
        [System.Drawing.Point]$Location,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(200,30)),
        [System.Windows.Forms.ComboBoxStyle]$DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList,
        [System.Drawing.Font]$Font = $script:defaultFont,
        [string[]]$Items = @(),
        [int]$SelectedIndex = -1,
        [string]$DefaultText = $null
    )
    $comboBox = New-Object System.Windows.Forms.ComboBox
    $comboBox.Location = $Location
    $comboBox.Size = $Size
    $comboBox.DropDownStyle = $DropDownStyle
    $comboBox.Font = $Font
    if ($Items.Count -gt 0) { $comboBox.Items.AddRange($Items); $comboBox.SelectedIndex = $SelectedIndex }
    if ($DefaultText) { $comboBox.Text = $DefaultText }
    return $comboBox
}

# Función para crear TextBox
function Create-TextBox {
    param(
        [System.Drawing.Point]$Location,
        [System.Drawing.Size]$Size = (New-Object System.Drawing.Size(200,30)),
        [System.Drawing.Color]$BackColor=[System.Drawing.Color]::White,
        [System.Drawing.Color]$ForeColor=[System.Drawing.Color]::Black,
        [System.Drawing.Font]$Font=$script:defaultFont,
        [string]$Text="",
        [bool]$Multiline=$false,
        [System.Windows.Forms.ScrollBars]$ScrollBars=[System.Windows.Forms.ScrollBars]::None,
        [bool]$ReadOnly=$false,
        [bool]$UseSystemPasswordChar=$false
    )
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location=$Location
    $textBox.Size=$Size
    $textBox.BackColor=$BackColor
    $textBox.ForeColor=$ForeColor
    $textBox.Font=$Font
    $textBox.Text=$Text
    $textBox.Multiline=$Multiline
    $textBox.ScrollBars=$ScrollBars
    $textBox.ReadOnly=$ReadOnly
    $textBox.WordWrap=$false
    if ($UseSystemPasswordChar) { $textBox.UseSystemPasswordChar = $true }
    return $textBox
}

function New-MainForm {
    Write-Host "Creando formulario principal..." -ForegroundColor Yellow
    try {
        # Código del formulario principal aquí...
        # (Esta función se mantendría en GUI.psm1 pero sería muy larga)
        # Recomiendo mantenerla separada o dividirla en funciones más pequeñas
    } catch {
        Write-Host "✗ Error creando formulario: $($_.Exception.Message)" -ForegroundColor Red
        Write-Host "  Detalle: $($_.InvocationInfo.PositionMessage)" -ForegroundColor Yellow
        Write-Host "  Stack : $($_.ScriptStackTrace)" -ForegroundColor DarkYellow
        throw
    }
}

function Start-Application {
    Write-Host "Iniciando aplicación..." -ForegroundColor Cyan

    if (-not (Initialize-Environment)) {
        Write-Host "Error inicializando entorno. Saliendo..." -ForegroundColor Red
        return
    }
    $mainForm = New-MainForm
    if ($mainForm -eq $null) {
        Write-Host "Error: No se pudo crear el formulario principal" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show("No se pudo crear la interfaz gráfica. Verifique los logs.", "Error crítico")
        return
    }
    try {
        Write-Host "Mostrando formulario..." -ForegroundColor Yellow
        $mainForm.ShowDialog()
        Write-Host "Aplicación finalizada correctamente." -ForegroundColor Green
    } catch {
        Write-Host "Error mostrando formulario: $_" -ForegroundColor Red
        [System.Windows.Forms.MessageBox]::Show("Error: $_", "Error en la aplicación")
    }
}

function Initialize-Environment {
    if (!(Test-Path -Path "C:\Temp")) {
        try {
            New-Item -ItemType Directory -Path "C:\Temp" -Force | Out-Null
            Write-Host "Carpeta 'C:\Temp' creada." -ForegroundColor Green
        } catch {
            Write-Host "Error creando C:\Temp: $_" -ForegroundColor Yellow
        }
    }
    try {
        $debugEnabled = Initialize-DzToolsConfig
        Write-DzDebug "`t[DEBUG]Configuración de debug cargada (debug=$debugEnabled)" -Color DarkGray
    } catch {
        Write-Host "Advertencia: No se pudo inicializar la configuración de debug. $_" -ForegroundColor Yellow
    }
    return $true
}

# Exportar todo
Export-ModuleMember -Function Set-RoundedRegion, Create-IconButton, New-LinkLabel, `
    Create-Button, Create-Label, Create-Form, Create-ComboBox, Create-TextBox, `
    New-MainForm, Start-Application, Initialize-Environment `
    -Variable defaultFont, boldFont, ColorBgForm, ColorPrimary, ColorPrimaryDark, `
    ColorPrimaryLight, ColorSurface, ColorPanel, ColorText, ColorSubText, ColorAccent