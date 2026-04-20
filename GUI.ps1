<#
.SYNOPSIS
    YTDLL — Módulo de GUI (WPF)
#>

Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

$ColorPrimary     = "#007AFF"
$ColorPrimaryDark = "#0056B3"
$ColorAccent      = "#5E5CE6"
$ColorSurface     = "#FFFFFF"
$ColorBgForm      = "#F5F5F7"
$ColorText        = "#1D1D1F"
$ColorSubText     = "#86868B"

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="YTDLL" Height="780" Width="460"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        WindowStartupLocation="CenterScreen" ResizeMode="NoResize">
    <Window.Resources>
        <!-- Estilos base -->
        <Style TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Foreground" Value="$ColorText"/>
        </Style>
        <Style TargetType="Label">
            <Setter Property="FontFamily" Value="Segoe UI Semibold"/>
            <Setter Property="Foreground" Value="$ColorText"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="Padding" Value="0,0,0,5"/>
        </Style>
        <Style x:Key="PrimaryButton" TargetType="Button">
            <Setter Property="Background" Value="$ColorPrimary"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="FontSize" Value="16"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="12">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="$ColorPrimaryDark"/>
                </Trigger>
                <Trigger Property="IsEnabled" Value="False">
                    <Setter Property="Background" Value="#D1D1D6"/>
                    <Setter Property="Foreground" Value="#8E8E93"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Padding" Value="10,8"/>
            <Setter Property="FontSize" Value="14"/>
            <Setter Property="BorderBrush" Value="#D1D1D6"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Background" Value="White"/>
            <Setter Property="Foreground" Value="$ColorText"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="TextBox">
                        <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="8">
                            <ScrollViewer x:Name="PART_ContentHost"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Padding" Value="10,6"/>
            <Setter Property="FontSize" Value="13"/>
        </Style>
    </Window.Resources>

    <Border Background="$ColorBgForm" CornerRadius="16" Margin="15">
        <Border.Effect>
            <DropShadowEffect Color="Black" Opacity="0.15" BlurRadius="25" ShadowDepth="5" Direction="270"/>
        </Border.Effect>
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>

            <!-- Header -->
            <Border Name="TitleBar" Grid.Row="0" Background="Transparent" Height="50" CornerRadius="16,16,0,0">
                <Grid>
                    <TextBlock Text="YTDLL" FontSize="16" FontWeight="SemiBold" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,15,0">
                        <Button Name="btnPickCookies" Content="🍪" ToolTip="Cookies" Background="Transparent" Foreground="$ColorSubText" BorderThickness="0" FontSize="18" Margin="0,0,10,0" Cursor="Hand">
                            <Button.ContextMenu>
                                <ContextMenu x:Name="ctxCookies" Placement="Bottom" PlacementTarget="{Binding RelativeSource={RelativeSource AncestorType=Button}}">
                                    <MenuItem Name="miCookieEdge" Header="🔵 Edge"/>
                                    <MenuItem Name="miCookieChrome" Header="🔴 Chrome"/>
                                    <MenuItem Name="miCookieFirefox" Header="🦊 Firefox"/>
                                    <MenuItem Name="miCookieBrave" Header="🦁 Brave"/>
                                    <MenuItem Name="miCookieOpera" Header="⭕ Opera"/>
                                    <MenuItem Name="miCookieVivaldi" Header="🟣 Vivaldi"/>
                                    <Separator/>
                                    <MenuItem Name="miCookieFile" Header="📁 Seleccionar archivo txt manualmente..."/>
                                </ContextMenu>
                            </Button.ContextMenu>
                        </Button>
                        <Button Name="btnInfo" Content="?" ToolTip="Información" Background="#E5E5EA" Foreground="$ColorText" BorderThickness="0" Width="24" Height="24" FontSize="14" FontWeight="Bold" Cursor="Hand">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border Background="{TemplateBinding Background}" CornerRadius="12">
                                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                </ControlTemplate>
                            </Button.Template>
                        </Button>
                    </StackPanel>
                </Grid>
            </Border>

            <!-- Main Content -->
            <StackPanel Grid.Row="1" Margin="25,5,25,15">

                <!-- Destination -->
                <Label Content="Carpeta de destino"/>
                <Grid Margin="0,0,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtDestino" Grid.Column="0" IsReadOnly="True" Background="#E5E5EA" Foreground="$ColorSubText"/>
                    <Button Name="btnPickDestino" Grid.Column="1" Content="📁" Width="36" Margin="10,0,0,0" Background="#E5E5EA" Foreground="$ColorText" BorderThickness="0" Cursor="Hand">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border Background="{TemplateBinding Background}" CornerRadius="8">
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                </Grid>

                <!-- URL Input -->
                <TextBox Name="txtUrl" Text="BUSCAR VIDEO" FontSize="16" TextAlignment="Center" Foreground="#8E8E93" Height="45" Margin="0,0,0,5" VerticalContentAlignment="Center"/>
                <Button Name="btnUrlHistory" Content="▾ Historial" Background="Transparent" Foreground="$ColorPrimary" BorderThickness="0" Cursor="Hand" HorizontalAlignment="Right" Margin="0,0,0,20">
                    <Button.ContextMenu>
                        <ContextMenu x:Name="ctxUrlHistory" Placement="Bottom" PlacementTarget="{Binding RelativeSource={RelativeSource AncestorType=Button}}"/>
                    </Button.ContextMenu>
                </Button>

                <!-- Formats -->
                <Label Content="Formato de VIDEO"/>
                <ComboBox Name="cmbVideoFmt" Margin="0,0,0,15"/>

                <Label Content="Formato de AUDIO"/>
                <ComboBox Name="cmbAudioFmt" Margin="0,0,0,25"/>

                <!-- Download Button -->
                <Button Name="btnDescargar" Content="Descargar" Style="{StaticResource PrimaryButton}" Height="50" Margin="0,0,0,25"/>

                <!-- Preview Image -->
                <Label Content="Vista previa"/>
                <Border CornerRadius="12" Background="#E5E5EA" Height="140" Margin="0,0,0,5">
                    <Border.Effect>
                        <DropShadowEffect Color="Black" Opacity="0.1" BlurRadius="10" ShadowDepth="2" Direction="270"/>
                    </Border.Effect>
                    <Grid>
                        <!-- Image Container with Clipping -->
                        <Border x:Name="imgClip" CornerRadius="12" Background="Transparent" ClipToBounds="True">
                            <Image Name="picPreview" Stretch="UniformToFill" Cursor="Hand" ToolTip="Clic para reproducir"/>
                        </Border>
                    </Grid>
                </Border>

                <!-- Video Info Label -->
                <TextBlock Name="lblVideoInfo" Text="" TextAlignment="Center" Foreground="$ColorSubText" FontSize="11" Margin="0,0,0,15" TextWrapping="Wrap"/>

                <!-- Status Console -->
                <Border Background="#E5E5EA" CornerRadius="8" Padding="15">
                    <TextBlock Name="lblEstadoConsulta" Text="Estado: sin consultar" FontFamily="Consolas" FontSize="12" Foreground="$ColorText" TextWrapping="Wrap" TextAlignment="Center"/>
                </Border>

            </StackPanel>

            <!-- Footer Actions -->
            <Grid Grid.Row="2" Margin="25,0,25,25">
                <Grid.ColumnDefinitions>
                    <ColumnDefinition Width="*"/>
                    <ColumnDefinition Width="10"/>
                    <ColumnDefinition Width="*"/>
                </Grid.ColumnDefinitions>
                <Button Name="btnExit" Grid.Column="0" Content="Salir" Height="36" Background="#1D1D1F" Foreground="White" BorderThickness="0" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="8">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                <Button Name="btnSites" Grid.Column="2" Content="Sitios compatibles" Height="36" Background="#E5E5EA" Foreground="$ColorText" BorderThickness="0" Cursor="Hand">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Background="{TemplateBinding Background}" CornerRadius="8">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                            </Border>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </Grid>
        </Grid>
    </Border>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$formPrincipal = [System.Windows.Markup.XamlReader]::Load($reader)

$TitleBar = $formPrincipal.FindName("TitleBar")
$btnPickCookies = $formPrincipal.FindName("btnPickCookies")
$btnInfo = $formPrincipal.FindName("btnInfo")
$txtUrl = $formPrincipal.FindName("txtUrl")
$btnUrlHistory = $formPrincipal.FindName("btnUrlHistory")
$ctxUrlHistory = $formPrincipal.FindName("ctxUrlHistory")
$txtDestino = $formPrincipal.FindName("txtDestino")
$btnPickDestino = $formPrincipal.FindName("btnPickDestino")
$cmbVideoFmt = $formPrincipal.FindName("cmbVideoFmt")
$cmbAudioFmt = $formPrincipal.FindName("cmbAudioFmt")
$btnDescargar = $formPrincipal.FindName("btnDescargar")
$picPreview = $formPrincipal.FindName("picPreview")
$lblVideoInfo = $formPrincipal.FindName("lblVideoInfo")
$lblEstadoConsulta = $formPrincipal.FindName("lblEstadoConsulta")
$btnExit = $formPrincipal.FindName("btnExit")
$btnSites = $formPrincipal.FindName("btnSites")

# ── Wiring: menú de cookies 🍪 ───────────────────────────────────────────────
$miCookieEdge    = $formPrincipal.FindName("miCookieEdge")
$miCookieChrome  = $formPrincipal.FindName("miCookieChrome")
$miCookieFirefox = $formPrincipal.FindName("miCookieFirefox")
$miCookieBrave   = $formPrincipal.FindName("miCookieBrave")
$miCookieOpera   = $formPrincipal.FindName("miCookieOpera")
$miCookieVivaldi = $formPrincipal.FindName("miCookieVivaldi")
$miCookieFile    = $formPrincipal.FindName("miCookieFile")

# Helper: aplicar cookies al estado de la app y actualizar tooltip del botón
function Set-CookiesActive {
    param([string]$Path, [string]$Label)
    $script:cookiesPath = $Path
    $btnPickCookies.ToolTip = "Cookies activas: $Label`nClic para cambiar"
    Write-Host "[COOKIES] Cookies activas: $Path" -ForegroundColor Green
}

# Navegadores: cada handler captura $browserName en su propio scope
foreach ($entry in @(
    @{ Item = $miCookieEdge;    Name = "edge"    },
    @{ Item = $miCookieChrome;  Name = "chrome"  },
    @{ Item = $miCookieFirefox; Name = "firefox" },
    @{ Item = $miCookieBrave;   Name = "brave"   },
    @{ Item = $miCookieOpera;   Name = "opera"   },
    @{ Item = $miCookieVivaldi; Name = "vivaldi" }
)) {
    # Crear closure con copia local del nombre del navegador
    $browserName = $entry.Name
    $menuItem    = $entry.Item
    $menuItem.Add_Click({
        $path = Export-BrowserCookies -Browser $browserName
        if ($path) {
            Set-CookiesActive -Path $path -Label $browserName
            [System.Windows.MessageBox]::Show(
                "Cookies de $browserName configuradas.`nPuedes consultar y descargar ahora.",
                "Cookies listas",
                [System.Windows.MessageBoxButton]::OK,
                [System.Windows.MessageBoxImage]::Information
            ) | Out-Null
        }
    }.GetNewClosure())  # GetNewClosure() captura $browserName correctamente en PS5
}

# Archivo manual
$miCookieFile.Add_Click({
    $ofd = New-Object Microsoft.Win32.OpenFileDialog
    $ofd.Title  = "Selecciona tu archivo cookies.txt"
    $ofd.Filter = "Cookies (*.txt)|*.txt|Todos (*.*)|*.*"
    if ($ofd.ShowDialog() -eq $true) {
        Set-CookiesActive -Path $ofd.FileName -Label $ofd.SafeFileName
        [System.Windows.MessageBox]::Show(
            "Archivo de cookies configurado:`n$($ofd.FileName)",
            "Cookies activas",
            [System.Windows.MessageBoxButton]::OK,
            [System.Windows.MessageBoxImage]::Information
        ) | Out-Null
    }
})

# Eventos Base
$TitleBar.Add_MouseLeftButtonDown({
    $formPrincipal.DragMove()
})

$txtUrl.Add_TextChanged({
    if ($txtUrl.Text -ne $global:UrlPlaceholder -and -not [string]::IsNullOrWhiteSpace($txtUrl.Text)) {
        $txtUrl.ToolTip = (Get-DisplayUrl -Url $txtUrl.Text)
        $txtUrl.Foreground = [System.Windows.Media.Brushes]::Black
        $currentUrl = Get-CurrentUrl
        if ($script:videoConsultado -and $script:ultimaURL -ne $currentUrl) {
            $script:videoConsultado   = $false
            $script:formatsEnumerated = $false
        }
    } else {
        $txtUrl.ToolTip = $null
    }
    Set-DownloadButtonVisual
})

$txtUrl.Add_GotFocus({
    if ($txtUrl.Text -eq $global:UrlPlaceholder) {
        $txtUrl.Text = ""
        $txtUrl.Foreground = [System.Windows.Media.Brushes]::Black
    }
})

$txtUrl.Add_LostFocus({
    if ([string]::IsNullOrWhiteSpace($txtUrl.Text)) {
        $txtUrl.Text = $global:UrlPlaceholder
        $txtUrl.Foreground = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(142, 142, 147)))
    }
})

$picPreview.Add_MouseLeftButtonDown({
    if (-not $script:videoConsultado -or [string]::IsNullOrWhiteSpace($script:ultimaURL)) {
        [System.Windows.MessageBox]::Show("Primero consulta un video para poder reproducirlo.", "Sin consulta", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        return
    }
    $cmd = $null
    try { $cmd = Get-Command "mpvnet" -ErrorAction Stop } catch {
        [System.Windows.MessageBox]::Show("mpv.net no está disponible en el PATH.", "mpv.net no encontrado", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        return
    }
    $playUrl = $null
    try { $playUrl = Get-BestStreamUrl -Url $script:ultimaURL } catch { $playUrl = $null }
    if (-not $playUrl) { $playUrl = $script:ultimaURL }
    try {
        Start-Process -FilePath $cmd.Source -ArgumentList @($playUrl,"--title=YTDLL Preview","--ontop=yes","--geometry=50%:50%","--autofit=60%") | Out-Null
    } catch {
        [System.Windows.MessageBox]::Show("No se pudo iniciar mpv.net.", "Error al abrir mpv.net", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
    }
})

function Set-DownloadButtonVisual {
    $haveYt   = Test-CommandExists -Name "yt-dlp"
    $haveFfm  = Test-CommandExists -Name "ffmpeg"
    $haveNode = if ($script:RequireNode) { Test-CommandExists -Name "node" } else { $true }
    $depsOk   = $haveYt -and $haveFfm -and $haveNode

    if (-not $depsOk) {
        $btnDescargar.IsEnabled = $false
        $btnDescargar.Content = "Descargar"
        $btnDescargar.ToolTip = "Deshabilitado: instala/activa dependencias"
        return
    }

    $currentUrl = Get-CurrentUrl
    $isConsulted = $script:videoConsultado -and
                   -not [string]::IsNullOrWhiteSpace($script:ultimaURL) -and
                   ($script:ultimaURL -eq $currentUrl)

    $btnDescargar.IsEnabled = $true

    if (-not $isConsulted) {
        $btnDescargar.Content = "Buscar Video"
        $btnDescargar.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(0, 122, 255)))
        $btnDescargar.ToolTip = "Aún no consultado: al hacer clic validará la URL"
    } elseif (-not $script:formatsEnumerated) {
        $btnDescargar.Content = "Buscar Video"
        $btnDescargar.IsEnabled = $true
        $btnDescargar.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 149, 0)))
        $btnDescargar.ToolTip = "No se pudieron extraer formatos. Presiona 'Buscar Video' para reintentar."
        if ($lblEstadoConsulta) {
            $lblEstadoConsulta.Text = "No fue posible extraer formatos. Presiona 'Buscar Video' para volver a consultar."
            $lblEstadoConsulta.Foreground = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 149, 0)))
        }
    } else {
        $btnDescargar.Content = "Descargar Video"
        $btnDescargar.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(52, 199, 89)))
        $btnDescargar.ToolTip = "Consulta válida: listo para descargar"
    }
}

function Refresh-GateByDeps {
    Set-DownloadButtonVisual
}

function Show-PreviewImage {
    param([Parameter(Mandatory=$true)][string]$ImageUrl, [string]$Titulo = $null)
    try {
        if ($ImageUrl -match '\.webp($|\?)') {
            $png = Convert-WebpUrlToPng -Url $ImageUrl
            if ($png -and (Test-Path $png)) {
                $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
                $bitmap.BeginInit()
                $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
                $bitmap.UriSource = New-Object Uri($png)
                $bitmap.EndInit()
                $picPreview.Source = $bitmap
                if ($Titulo) { $picPreview.ToolTip = $Titulo }

                Start-Job -ScriptBlock { param($f); Start-Sleep -Seconds 5; try { Remove-Item $f -Force -ErrorAction SilentlyContinue } catch {} } -ArgumentList $png | Out-Null
                return $true
            }
            return $false
        }

        $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
        $bitmap.BeginInit()
        $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
        $bitmap.UriSource = New-Object Uri($ImageUrl)
        $bitmap.EndInit()
        $picPreview.Source = $bitmap
        if ($Titulo) { $picPreview.ToolTip = $Titulo }
        return $true
    } catch { return $false }
}

function Show-PreviewUniversal {
    param(
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$Titulo = $null,
        [string]$DirectThumbUrl = $null
    )
    $lblEstadoConsulta.Text = "Obteniendo miniaturas..."
    $lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Blue

    if ($global:videoJsonData) {
        $title = $global:videoJsonData.title
        $uploader = $global:videoJsonData.uploader
        $duration = $global:videoJsonData.duration_string
        if ($title) {
            $info = "$title"
            if ($uploader) { $info += " • $uploader" }
            if ($duration) { $info += " • $duration" }
            $lblVideoInfo.Text = $info
        }
    } else {
        $lblVideoInfo.Text = ""
    }

    $thumbFile = Fetch-ThumbnailFile -Url $Url
    if ($thumbFile -and (Test-Path $thumbFile)) {
        try {
            $bitmap = New-Object System.Windows.Media.Imaging.BitmapImage
            $bitmap.BeginInit()
            $bitmap.CacheOption = [System.Windows.Media.Imaging.BitmapCacheOption]::OnLoad
            $bitmap.UriSource = New-Object Uri($thumbFile)
            $bitmap.EndInit()
            $picPreview.Source = $bitmap
            if ($Titulo) { $picPreview.ToolTip = $Titulo }

            $lblEstadoConsulta.Text = "Vista previa cargada"
            $lblEstadoConsulta.Foreground = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(52, 199, 89)))

            Start-Job -ScriptBlock { param($f); Start-Sleep -Seconds 5; try { Remove-Item $f -Force -ErrorAction SilentlyContinue } catch {} } -ArgumentList $thumbFile | Out-Null
            return $true
        } catch {}
    }

    $thumbList = Get-ThumbnailListFromYtDlp -Url $Url
    if ($thumbList -and $thumbList.Count -gt 0) {
        $sortedThumbs = $thumbList | Sort-Object @{Expression={$_.Width * $_.Height};Descending=$true} | Select-Object -First 3
        foreach ($thumb in $sortedThumbs) {
            if (Show-PreviewImage -ImageUrl $thumb.Url -Titulo $Titulo) {
                $lblEstadoConsulta.Text = "Vista previa cargada"
                $lblEstadoConsulta.Foreground = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(52, 199, 89)))
                return $true
            }
        }
    }

    if ($DirectThumbUrl -and (Show-PreviewImage -ImageUrl $DirectThumbUrl -Titulo $Titulo)) {
        $lblEstadoConsulta.Text = "Vista previa cargada"
        $lblEstadoConsulta.Foreground = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(52, 199, 89)))
        return $true
    }

    $lblEstadoConsulta.Text = "No se pudo cargar vista previa"
    $lblEstadoConsulta.Foreground = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255, 149, 0)))
    return $false
}

function Show-UrlHistoryMenu {
    $ctxUrlHistory.Items.Clear()
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
        $mi = New-Object System.Windows.Controls.MenuItem
        $mi.Header = "(Sin historial)"
        $mi.IsEnabled = $false
        [void]$ctxUrlHistory.Items.Add($mi)
    } else {
        $top = [Math]::Min(12, $items.Count)
        for ($i = 0; $i -lt $top; $i++) {
            $displayText = [string]$items[$i]
            if ([string]::IsNullOrWhiteSpace($displayText)) { continue }
            $urlItem = New-Object System.Windows.Controls.MenuItem
            $urlItem.Header = $displayText
            $urlItem.ToolTip = $displayText
            $urlItem.add_Click({
                param($sender, $e)
                $fullText = $sender.Header
                $urlToSet = if ($fullText -match '\|\s*(.+)$') { $matches[1].Trim() } else { $fullText }
                $txtUrl.Text = $urlToSet
                $txtUrl.Foreground = [System.Windows.Media.Brushes]::Black
            })
            [void]$ctxUrlHistory.Items.Add($urlItem)
        }
        [void]$ctxUrlHistory.Items.Add((New-Object System.Windows.Controls.Separator))
        $miClear = New-Object System.Windows.Controls.MenuItem
        $miClear.Header = "Borrar historial"
        $miClear.Foreground = [System.Windows.Media.Brushes]::Crimson
        $miClear.add_Click({
            $r = [System.Windows.MessageBox]::Show("¿Seguro que deseas borrar el historial de URLs?", "Confirmar", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Question)
            if ($r -eq [System.Windows.MessageBoxResult]::Yes) { Clear-History }
        })
        [void]$ctxUrlHistory.Items.Add($miClear)
    }
    $ctxUrlHistory.IsOpen = $true
}

$btnUrlHistory.Add_Click({ Show-UrlHistoryMenu })

function Show-AppInfo {
    [xml]$xamlInfo = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Información de la Aplicación" Height="620" Width="760"
        WindowStartupLocation="CenterOwner" Background="#F5F5F7" ResizeMode="NoResize">
    <Window.Resources>
        <Style TargetType="TextBlock">
            <Setter Property="FontFamily" Value="Segoe UI"/>
            <Setter Property="Foreground" Value="#1D1D1F"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Background" Value="#007AFF"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="10,5"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#0056B3"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="ActionButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#E5E5EA"/>
            <Setter Property="Foreground" Value="#1D1D1F"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#D1D1D6"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="DangerButton" TargetType="Button" BasedOn="{StaticResource {x:Type Button}}">
            <Setter Property="Background" Value="#FF3B30"/>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#C9302C"/>
                </Trigger>
            </Style.Triggers>
        </Style>
        <Style x:Key="LinkText" TargetType="TextBlock">
            <Setter Property="Foreground" Value="#007AFF"/>
            <Setter Property="Cursor" Value="Hand"/>
        </Style>
    </Window.Resources>
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <TextBlock Grid.Row="0" Text="YTDLL — Versión: `$version" FontSize="20" FontWeight="Bold" Margin="0,0,0,10"/>

        <CheckBox Name="chkDebug" Grid.Row="1" Content="Mostrar debug en consola" Margin="0,0,0,20"/>

        <Border Grid.Row="2" Background="White" CornerRadius="10" Padding="15">
            <Border.Effect>
                <DropShadowEffect Color="Black" Opacity="0.05" BlurRadius="10" ShadowDepth="2"/>
            </Border.Effect>
            <StackPanel>
                <TextBlock Text="Dependencias y herramientas necesarias" FontSize="16" FontWeight="SemiBold" Margin="0,0,0,15"/>

                <!-- yt-dlp -->
                <Grid Margin="0,5,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="150"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0" VerticalAlignment="Center">
                        <TextBlock Text="yt-dlp" FontWeight="Bold" FontSize="14"/>
                        <TextBlock Name="lnkYtDlp" Text="Ir a GitHub" Style="{StaticResource LinkText}" FontSize="12" Margin="0,2,0,0"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="Motor principal de descarga de videos." FontSize="12" Foreground="#86868B" TextWrapping="Wrap"/>
                        <TextBlock Name="lblYtDlp" Text="Verificando..." FontSize="12" Margin="0,3,0,0"/>
                    </StackPanel>
                    <Button Name="btnYtRefresh" Grid.Column="2" Content="↻ Actualizar" Style="{StaticResource ActionButton}" Margin="10,0,0,0" VerticalAlignment="Center"/>
                    <Button Name="btnYtUninstall" Grid.Column="3" Content="✖" Style="{StaticResource DangerButton}" Margin="5,0,0,0" Width="30" VerticalAlignment="Center"/>
                </Grid>

                <!-- ffmpeg -->
                <Grid Margin="0,5,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="150"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0" VerticalAlignment="Center">
                        <TextBlock Text="ffmpeg" FontWeight="Bold" FontSize="14"/>
                        <TextBlock Name="lnkFfmpeg" Text="Ir a Página Oficial" Style="{StaticResource LinkText}" FontSize="12" Margin="0,2,0,0"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="Herramienta para procesar y unir audio y video." FontSize="12" Foreground="#86868B" TextWrapping="Wrap"/>
                        <TextBlock Name="lblFfmpeg" Text="Verificando..." FontSize="12" Margin="0,3,0,0"/>
                    </StackPanel>
                    <Button Name="btnFfmpegRefresh" Grid.Column="2" Content="↻ Actualizar" Style="{StaticResource ActionButton}" Margin="10,0,0,0" VerticalAlignment="Center"/>
                    <Button Name="btnFfmpegUninstall" Grid.Column="3" Content="✖" Style="{StaticResource DangerButton}" Margin="5,0,0,0" Width="30" VerticalAlignment="Center"/>
                </Grid>

                <!-- Node.js -->
                <Grid Margin="0,5,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="150"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0" VerticalAlignment="Center">
                        <TextBlock Text="Node.js" FontWeight="Bold" FontSize="14"/>
                        <TextBlock Name="lnkNode" Text="Ir a Página Oficial" Style="{StaticResource LinkText}" FontSize="12" Margin="0,2,0,0"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="Requerido por yt-dlp para extracción en ciertos sitios web." FontSize="12" Foreground="#86868B" TextWrapping="Wrap"/>
                        <TextBlock Name="lblNode" Text="Verificando..." FontSize="12" Margin="0,3,0,0"/>
                    </StackPanel>
                    <Button Name="btnNodeRefresh" Grid.Column="2" Content="↻ Actualizar" Style="{StaticResource ActionButton}" Margin="10,0,0,0" VerticalAlignment="Center"/>
                    <Button Name="btnNodeUninstall" Grid.Column="3" Content="✖" Style="{StaticResource DangerButton}" Margin="5,0,0,0" Width="30" VerticalAlignment="Center"/>
                </Grid>

                <!-- mpv.net -->
                <Grid Margin="0,5,0,5">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="150"/>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <StackPanel Grid.Column="0" VerticalAlignment="Center">
                        <TextBlock Text="mpv.net" FontWeight="Bold" FontSize="14"/>
                        <TextBlock Name="lnkMpv" Text="Ir a GitHub" Style="{StaticResource LinkText}" FontSize="12" Margin="0,2,0,0"/>
                    </StackPanel>
                    <StackPanel Grid.Column="1" VerticalAlignment="Center">
                        <TextBlock Text="Reproductor opcional para la vista previa de videos." FontSize="12" Foreground="#86868B" TextWrapping="Wrap"/>
                        <TextBlock Name="lblMpvNet" Text="Verificando..." FontSize="12" Margin="0,3,0,0"/>
                    </StackPanel>
                    <Button Name="btnMpvNetRefresh" Grid.Column="2" Content="↻ Actualizar" Style="{StaticResource ActionButton}" Margin="10,0,0,0" VerticalAlignment="Center"/>
                    <Button Name="btnMpvNetUninstall" Grid.Column="3" Content="✖" Style="{StaticResource DangerButton}" Margin="5,0,0,0" Width="30" VerticalAlignment="Center"/>
                </Grid>
            </StackPanel>
        </Border>

        <Grid Grid.Row="3" Margin="0,20,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Button Name="btnActualizarTodo" Grid.Column="0" Content="ACTUALIZAR TODO" HorizontalAlignment="Left" Width="150" Height="36"/>
            <Button Name="btnCerrarInfo" Grid.Column="1" Content="Cerrar" Width="100" Height="36" Style="{StaticResource ActionButton}"/>
        </Grid>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xamlInfo)
    $winInfo = [System.Windows.Markup.XamlReader]::Load($reader)
    $winInfo.Owner = $formPrincipal

    $chkDebug = $winInfo.FindName("chkDebug")
    $chkDebug.IsChecked = $global:DebugEnabled
    $chkDebug.add_Checked({
        $global:DebugEnabled = $true
        Set-IniValue -Section "DEBUG" -Key "ConsoleDebug" -Value "true"
    })
    $chkDebug.add_Unchecked({
        $global:DebugEnabled = $false
        Set-IniValue -Section "DEBUG" -Key "ConsoleDebug" -Value "false"
    })

    $lblYtDlp = $winInfo.FindName("lblYtDlp")
    $lblFfmpeg = $winInfo.FindName("lblFfmpeg")
    $lblNode = $winInfo.FindName("lblNode")
    $lblMpvNet = $winInfo.FindName("lblMpvNet")

    Refresh-DependencyLabel -CommandName "yt-dlp"  -FriendlyName "yt-dlp"  -LabelRef ([ref]$lblYtDlp)  -VersionArgs "--version" -Parse "FirstLine"
    Refresh-DependencyLabel -CommandName "ffmpeg"  -FriendlyName "ffmpeg"  -LabelRef ([ref]$lblFfmpeg) -VersionArgs "-version"  -Parse "FirstLine"
    if ($script:RequireNode) {
        Refresh-DependencyLabel -CommandName "node" -FriendlyName "Node.js" -LabelRef ([ref]$lblNode) -VersionArgs "--version" -Parse "FirstLine"
    }
    Refresh-DependencyLabel -CommandName "mpvnet"  -FriendlyName "mpv.net" -LabelRef ([ref]$lblMpvNet) -VersionArgs "--version" -Parse "FirstLine"

    $winInfo.FindName("lnkYtDlp").add_MouseLeftButtonDown({ Start-Process "https://github.com/yt-dlp/yt-dlp" })
    $winInfo.FindName("lnkFfmpeg").add_MouseLeftButtonDown({ Start-Process "https://ffmpeg.org/" })
    $winInfo.FindName("lnkNode").add_MouseLeftButtonDown({ Start-Process "https://nodejs.org/" })
    $winInfo.FindName("lnkMpv").add_MouseLeftButtonDown({ Start-Process "https://github.com/mpvnet-player/mpv.net" })

    $winInfo.FindName("btnYtRefresh").add_Click({ Update-Dependency -ChocoPkg "yt-dlp" -FriendlyName "yt-dlp" -CommandName "yt-dlp" -LabelRef ([ref]$lblYtDlp) -VersionArgs "--version" -Parse "FirstLine" })
    $winInfo.FindName("btnYtUninstall").add_Click({ Uninstall-Dependency -ChocoPkg "yt-dlp" -FriendlyName "yt-dlp" -LabelRef ([ref]$lblYtDlp) })

    $winInfo.FindName("btnFfmpegRefresh").add_Click({ Update-Dependency -ChocoPkg "ffmpeg" -FriendlyName "ffmpeg" -CommandName "ffmpeg" -LabelRef ([ref]$lblFfmpeg) -VersionArgs "-version" -Parse "FirstLine" })
    $winInfo.FindName("btnFfmpegUninstall").add_Click({ Uninstall-Dependency -ChocoPkg "ffmpeg" -FriendlyName "ffmpeg" -LabelRef ([ref]$lblFfmpeg) })

    $winInfo.FindName("btnNodeRefresh").add_Click({ Update-Dependency -ChocoPkg "nodejs-lts" -FriendlyName "Node.js" -CommandName "node" -LabelRef ([ref]$lblNode) -VersionArgs "--version" -Parse "FirstLine" })
    $winInfo.FindName("btnNodeUninstall").add_Click({ Uninstall-Dependency -ChocoPkg "nodejs-lts" -FriendlyName "Node.js" -LabelRef ([ref]$lblNode) })

    $winInfo.FindName("btnMpvNetRefresh").add_Click({
        if (-not (Ensure-DotNet6DesktopRuntime)) { return }
        Update-Dependency -ChocoPkg "mpv.net" -FriendlyName "mpv.net" -CommandName "mpvnet" -LabelRef ([ref]$lblMpvNet) -VersionArgs "--version" -Parse "FirstLine"
    })
    $winInfo.FindName("btnMpvNetUninstall").add_Click({
        if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
            [System.Windows.MessageBox]::Show("Chocolatey no está disponible.", "Chocolatey requerido", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
        $r = [System.Windows.MessageBox]::Show("Se desinstalarán: mpv.net, mpvnet.portable y .NET 6 Desktop Runtime.`n¿Continuar?", "Confirmar", [System.Windows.MessageBoxButton]::YesNo, [System.Windows.MessageBoxImage]::Warning)
        if ($r -eq [System.Windows.MessageBoxResult]::Yes) {
            Uninstall-Dependency -ChocoPkg "mpv.net" -FriendlyName "mpv.net" -LabelRef ([ref]$lblMpvNet)
            try { choco uninstall mpvnet.portable -y | Out-Null } catch {}
            try { choco uninstall "Microsoft .NET 6 Desktop Runtime" -y | Out-Null } catch {}
        }
    })

    $winInfo.FindName("btnActualizarTodo").add_Click({
        if (-not (Check-Chocolatey)) { return }
        [void](Ensure-DotNet6DesktopRuntime)
        Update-Dependency -ChocoPkg "yt-dlp"      -FriendlyName "yt-dlp"  -CommandName "yt-dlp"  -LabelRef ([ref]$lblYtDlp)  -VersionArgs "--version" -Parse "FirstLine"
        Update-Dependency -ChocoPkg "ffmpeg"       -FriendlyName "ffmpeg"  -CommandName "ffmpeg"  -LabelRef ([ref]$lblFfmpeg) -VersionArgs "-version"  -Parse "FirstLine"
        if ($script:RequireNode) {
            Update-Dependency -ChocoPkg "nodejs-lts" -FriendlyName "Node.js" -CommandName "node" -LabelRef ([ref]$lblNode) -VersionArgs "--version" -Parse "FirstLine"
        }
        Update-Dependency -ChocoPkg "mpv.net"     -FriendlyName "mpv.net" -CommandName "mpvnet"  -LabelRef ([ref]$lblMpvNet) -VersionArgs "--version" -Parse "FirstLine"
    })

    $winInfo.FindName("btnCerrarInfo").add_Click({ $winInfo.Close() })
    $winInfo.ShowDialog() | Out-Null
}

function Show-SitesDialog {
    try { $yt = Get-Command yt-dlp -ErrorAction Stop } catch {
        [System.Windows.MessageBox]::Show("yt-dlp no está disponible.", "Error", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        return
    }
    $res = Invoke-CaptureResponsive -ExePath $yt.Source -Args @("--list-extractors") -WorkingText "Obteniendo sitios…"
    $raw = ($res.StdOut + "`r`n" + $res.StdErr)
    $fmt = Format-ExtractorsInline -RawText $raw -WrapAt 120
    $allSites = [System.Collections.ArrayList]::new(); $null = $allSites.AddRange($fmt.List)

    [xml]$xamlSites = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Sitios compatibles — `$(`$fmt.Count) detectados" Height="600" Width="800"
        WindowStartupLocation="CenterOwner" Background="#F5F5F7">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Background" Value="#E5E5EA"/>
            <Setter Property="Foreground" Value="#1D1D1F"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="15,8"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}" CornerRadius="6">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
            <Style.Triggers>
                <Trigger Property="IsMouseOver" Value="True">
                    <Setter Property="Background" Value="#D1D1D6"/>
                </Trigger>
            </Style.Triggers>
        </Style>
    </Window.Resources>
    <Grid Margin="20">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <Grid Grid.Row="0" Margin="0,0,0,15">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox Name="txtFiltro" Grid.Column="0" Text="(buscar sitio)" Foreground="#8E8E93" Padding="10,8" FontSize="14">
                <TextBox.Template>
                    <ControlTemplate TargetType="TextBox">
                        <Border Background="White" CornerRadius="8" BorderBrush="#D1D1D6" BorderThickness="1">
                            <ScrollViewer x:Name="PART_ContentHost"/>
                        </Border>
                    </ControlTemplate>
                </TextBox.Template>
            </TextBox>
            <TextBlock Name="lblCount" Grid.Column="1" Text="0/`$(`$allSites.Count)" VerticalAlignment="Center" Margin="15,0,0,0" FontSize="14"/>
        </Grid>

        <ListBox Name="lstSites" Grid.Row="1" FontFamily="Consolas" FontSize="13" BorderThickness="0" Margin="0,0,0,15">
            <ListBox.Template>
                <ControlTemplate TargetType="ListBox">
                    <Border Background="White" CornerRadius="8" BorderBrush="#D1D1D6" BorderThickness="1">
                        <ScrollViewer>
                            <ItemsPresenter/>
                        </ScrollViewer>
                    </Border>
                </ControlTemplate>
            </ListBox.Template>
        </ListBox>

        <StackPanel Grid.Row="2" Orientation="Horizontal" HorizontalAlignment="Right">
            <Button Name="btnCopy" Content="Copiar selección" Margin="0,0,10,0"/>
            <Button Name="btnClose" Content="Cerrar"/>
        </StackPanel>
    </Grid>
</Window>
"@
    $reader = (New-Object System.Xml.XmlNodeReader $xamlSites)
    $winSites = [System.Windows.Markup.XamlReader]::Load($reader)
    $winSites.Owner = $formPrincipal

    $txtFiltro = $winSites.FindName("txtFiltro")
    $lblCount = $winSites.FindName("lblCount")
    $lstSites = $winSites.FindName("lstSites")

    function Refresh-List([string]$term) {
        $lstSites.Items.Clear()
        $items = $allSites
        if ($term -and $term -ne "(buscar sitio)") {
            $rx = [regex]::Escape($term)
            $items = $allSites | Where-Object { $_ -match $rx }
        }
        $items | ForEach-Object { [void]$lstSites.Items.Add($_) }
        $lblCount.Text = "$($lstSites.Items.Count)/$($allSites.Count)"
    }

    Refresh-List $null

    $txtFiltro.add_GotFocus({
        if ($txtFiltro.Text -eq "(buscar sitio)") {
            $txtFiltro.Text = ""
            $txtFiltro.Foreground = [System.Windows.Media.Brushes]::Black
        }
    })

    $txtFiltro.add_LostFocus({
        if ([string]::IsNullOrWhiteSpace($txtFiltro.Text)) {
            $txtFiltro.Text = "(buscar sitio)"
            $txtFiltro.Foreground = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(142, 142, 147)))
        }
    })

    $txtFiltro.add_TextChanged({
        if ($txtFiltro.Foreground.ToString() -ne "#FF000000") { return }
        Refresh-List $txtFiltro.Text.Trim()
    })

    $winSites.FindName("btnCopy").add_Click({
        if ($lstSites.SelectedItem) {
            try { [System.Windows.Clipboard]::SetText([string]$lstSites.SelectedItem) } catch {}
        }
    })

    $lstSites.add_MouseDoubleClick({
        if ($lstSites.SelectedItem) {
            try { [System.Windows.Clipboard]::SetText([string]$lstSites.SelectedItem) } catch {}
        }
    })

    $winSites.FindName("btnClose").add_Click({ $winSites.Close() })
    $winSites.ShowDialog() | Out-Null
}