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
        Title="YTDLL" Height="780" Width="500"
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

    <Grid>
        <Grid.ColumnDefinitions>
            <ColumnDefinition Width="460"/>
            <ColumnDefinition x:Name="queueColumn" Width="0"/>
        </Grid.ColumnDefinitions>

    <Border Grid.Column="0" Background="$ColorBgForm" CornerRadius="16" Margin="15,15,0,15">
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
                        <Button Name="btnAi" ToolTip="Asistente IA" Width="32" Height="32" Cursor="Hand" BorderThickness="0" Margin="0,0,8,0">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border Name="aiBorder" Background="{TemplateBinding Background}" CornerRadius="16">
                                        <TextBlock Text="IA" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter TargetName="aiBorder" Property="Opacity" Value="0.85"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
                                </ControlTemplate>
                            </Button.Template>
                        </Button>
                        <Button Name="btnPickCookies" ToolTip="Configurar cookies de YouTube" Width="32" Height="32" Cursor="Hand" BorderThickness="0" Margin="0,0,8,0">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border Name="cookieBorder" Background="{TemplateBinding Background}" CornerRadius="16">
                                        <TextBlock Text="🍪" FontSize="15" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter TargetName="cookieBorder" Property="Opacity" Value="0.8"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
                                </ControlTemplate>
                            </Button.Template>
                        </Button>
                        <Button Name="btnInfo" ToolTip="Información y dependencias" Width="32" Height="32" Cursor="Hand" BorderThickness="0">
                            <Button.Template>
                                <ControlTemplate TargetType="Button">
                                    <Border Name="infoBorder" Background="{TemplateBinding Background}" CornerRadius="16">
                                        <TextBlock Text="⚙" FontSize="15" HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                    </Border>
                                    <ControlTemplate.Triggers>
                                        <Trigger Property="IsMouseOver" Value="True">
                                            <Setter TargetName="infoBorder" Property="Background" Value="#C7C7CC"/>
                                        </Trigger>
                                    </ControlTemplate.Triggers>
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

        <Button Name="btnQueueToggle" Grid.Column="0" Panel.ZIndex="5" Content="»" Width="30" Height="64"
                VerticalAlignment="Center" HorizontalAlignment="Right" Margin="0,0,-15,0" Cursor="Hand"
                Background="$ColorBgForm" Foreground="$ColorText" BorderBrush="#D1D1D6" BorderThickness="1,1,1,1">
            <Button.Template>
                <ControlTemplate TargetType="Button">
                    <Border Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}"
                            BorderThickness="{TemplateBinding BorderThickness}" CornerRadius="0,10,10,0">
                        <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                    </Border>
                </ControlTemplate>
            </Button.Template>
        </Button>

        <Border Name="QueuePanel" Grid.Column="1" Background="$ColorBgForm" CornerRadius="0,16,16,0"
                Margin="0,15,15,15" Visibility="Collapsed">
            <Border.Effect>
                <DropShadowEffect Color="Black" Opacity="0.15" BlurRadius="25" ShadowDepth="5" Direction="270"/>
            </Border.Effect>
            <Grid Margin="18">
                <Grid.RowDefinitions>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="Auto"/>
                    <RowDefinition Height="*"/>
                </Grid.RowDefinitions>

                <Grid Grid.Row="0" Margin="0,0,0,12">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBlock Text="Descargas" FontSize="18" FontWeight="SemiBold" VerticalAlignment="Center"/>
                    <TextBlock Name="txtQueueSummary" Grid.Column="1" Text="0 activas" FontSize="12"
                               Foreground="$ColorSubText" VerticalAlignment="Center"/>
                </Grid>

                <Grid Grid.Row="1" Margin="0,0,0,12">
                    <Grid.RowDefinitions>
                        <RowDefinition Height="Auto"/>
                        <RowDefinition Height="Auto"/>
                    </Grid.RowDefinitions>
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <CheckBox Name="chkAutoDownload" Grid.Row="0" Grid.Column="0"
                              Content="Autodescargar al agregar" FontFamily="Segoe UI" FontSize="12"
                              Foreground="$ColorText" VerticalAlignment="Center"/>
                    <StackPanel Grid.Row="0" Grid.Column="1" Orientation="Horizontal" VerticalAlignment="Center">
                        <TextBlock Text="Simultaneas" FontSize="12" Foreground="$ColorSubText" VerticalAlignment="Center" Margin="0,0,6,0"/>
                        <ComboBox Name="cmbMaxConcurrent" Width="54" Height="28" FontSize="12">
                            <ComboBoxItem Content="1"/>
                            <ComboBoxItem Content="2"/>
                            <ComboBoxItem Content="3"/>
                            <ComboBoxItem Content="4"/>
                            <ComboBoxItem Content="5"/>
                        </ComboBox>
                    </StackPanel>
                    <Button Name="btnStartQueue" Grid.Row="1" Grid.Column="0" Content="Iniciar cola"
                            Height="32" Margin="0,10,8,0" Background="#34C759" Foreground="White"
                            BorderThickness="0" Cursor="Hand" FontWeight="SemiBold"/>
                    <Button Name="btnClearCompleted" Grid.Row="1" Grid.Column="1" Content="Borrar completadas"
                            Height="32" Margin="0,10,0,0" Background="#E5E5EA" Foreground="$ColorText"
                            BorderThickness="0" Cursor="Hand"/>
                </Grid>

                <ScrollViewer Grid.Row="2" VerticalScrollBarVisibility="Auto">
                    <StackPanel>
                        <TextBlock Name="lblActiveHeader" Text="En progreso (0)" FontWeight="SemiBold" FontSize="13" Margin="0,0,0,8"/>
                        <StackPanel Name="spActiveDownloads" Margin="0,0,0,14"/>
                        <TextBlock Name="lblWaitingHeader" Text="En espera (0)" FontWeight="SemiBold" FontSize="13" Margin="0,0,0,8"/>
                        <StackPanel Name="spWaitingDownloads" Margin="0,0,0,14"/>
                        <Grid Margin="0,0,0,8">
                            <Grid.ColumnDefinitions>
                                <ColumnDefinition Width="*"/>
                                <ColumnDefinition Width="Auto"/>
                            </Grid.ColumnDefinitions>
                            <TextBlock Name="lblCompletedHeader" Text="Completadas (0)" FontWeight="SemiBold" FontSize="13"/>
                        </Grid>
                        <StackPanel Name="spCompletedDownloads"/>
                    </StackPanel>
                </ScrollViewer>
            </Grid>
        </Border>
    </Grid>
</Window>
"@

$reader = (New-Object System.Xml.XmlNodeReader $xaml)
$formPrincipal = [System.Windows.Markup.XamlReader]::Load($reader)

$TitleBar = $formPrincipal.FindName("TitleBar")
$btnAi = $formPrincipal.FindName("btnAi")
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
$btnQueueToggle = $formPrincipal.FindName("btnQueueToggle")
$QueuePanel = $formPrincipal.FindName("QueuePanel")
$queueColumn = $formPrincipal.FindName("queueColumn")
$txtQueueSummary = $formPrincipal.FindName("txtQueueSummary")
$chkAutoDownload = $formPrincipal.FindName("chkAutoDownload")
$cmbMaxConcurrent = $formPrincipal.FindName("cmbMaxConcurrent")
$btnStartQueue = $formPrincipal.FindName("btnStartQueue")
$btnClearCompleted = $formPrincipal.FindName("btnClearCompleted")
$lblActiveHeader = $formPrincipal.FindName("lblActiveHeader")
$lblWaitingHeader = $formPrincipal.FindName("lblWaitingHeader")
$lblCompletedHeader = $formPrincipal.FindName("lblCompletedHeader")
$spActiveDownloads = $formPrincipal.FindName("spActiveDownloads")
$spWaitingDownloads = $formPrincipal.FindName("spWaitingDownloads")
$spCompletedDownloads = $formPrincipal.FindName("spCompletedDownloads")

# Helper: guardar cookies en estado de la app (usada por Show-CookieDialog)
function Set-CookiesActive {
    param([string]$Path, [string]$Label)
    $script:cookiesPath = $Path
    Set-IniValue -Section "cookies" -Key "Path" -Value $Path
    Set-IniValue -Section "cookies" -Key "Label" -Value $Label
    Write-Host "[COOKIES] cookiesPath establecido y guardado en ini: $Path" -ForegroundColor Green
}

function Update-AiButtonVisual {
    if (-not $btnAi) { return }
    $cfg = Get-AiConfig
    if ($cfg.Enabled) {
        $btnAi.Background = "#34C759"
        $btnAi.Foreground = "White"
        $btnAi.ToolTip = "Asistente IA activo"
    } else {
        $btnAi.Background = "#E5E5EA"
        $btnAi.Foreground = "#1D1D1F"
        $btnAi.ToolTip = "Configurar asistente IA"
    }
}

function Show-AiSettingsDialog {
    $cfg = Get-AiConfig
    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Configuracion de IA" Height="470" Width="460"
        WindowStartupLocation="CenterOwner" ResizeMode="NoResize" Background="#F5F5F7">
    <Window.Resources>
        <Style TargetType="TextBox">
            <Setter Property="Height" Value="34"/>
            <Setter Property="Padding" Value="8,0"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="BorderBrush" Value="#D1D1D6"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
        <Style TargetType="PasswordBox">
            <Setter Property="Height" Value="34"/>
            <Setter Property="Padding" Value="8,0"/>
            <Setter Property="VerticalContentAlignment" Value="Center"/>
            <Setter Property="BorderBrush" Value="#D1D1D6"/>
            <Setter Property="BorderThickness" Value="1"/>
        </Style>
        <Style TargetType="ComboBox">
            <Setter Property="Height" Value="34"/>
            <Setter Property="Padding" Value="6,0"/>
        </Style>
        <Style TargetType="Button">
            <Setter Property="Height" Value="34"/>
            <Setter Property="MinWidth" Value="92"/>
            <Setter Property="Padding" Value="12,0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Background" Value="#E5E5EA"/>
            <Setter Property="Foreground" Value="#1D1D1F"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>
    </Window.Resources>
    <Grid Margin="24">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>

        <StackPanel Grid.Row="0" Margin="0,0,0,18">
            <TextBlock Text="IA con Gemini" FontSize="22" FontWeight="SemiBold"/>
            <TextBlock Text="Activa el asistente para buscar videos dentro de enlaces." Foreground="#6E6E73" Margin="0,4,0,0" TextWrapping="Wrap"/>
        </StackPanel>

        <Grid Grid.Row="1">
            <Grid.RowDefinitions>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
                <RowDefinition Height="Auto"/>
            </Grid.RowDefinitions>
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="150"/>
                <ColumnDefinition Width="*"/>
            </Grid.ColumnDefinitions>

            <CheckBox Name="chkEnabled" Grid.Row="0" Grid.ColumnSpan="2" Content="Activar IA" Margin="0,0,0,14"/>
            <TextBlock Grid.Row="1" Grid.Column="0" Text="Proveedor" VerticalAlignment="Center" Margin="0,0,12,10"/>
            <ComboBox Name="cmbProvider" Grid.Row="1" Grid.Column="1" Margin="0,0,0,10">
                <ComboBoxItem Content="Gemini"/>
            </ComboBox>
            <TextBlock Grid.Row="2" Grid.Column="0" Text="Modelo" VerticalAlignment="Center" Margin="0,0,12,10"/>
            <ComboBox Name="cmbModel" Grid.Row="2" Grid.Column="1" IsEditable="True" Margin="0,0,0,10">
                <ComboBoxItem Content="gemini-2.5-flash"/>
                <ComboBoxItem Content="gemini-2.5-flash-lite"/>
                <ComboBoxItem Content="gemini-flash-latest"/>
            </ComboBox>
            <TextBlock Grid.Row="3" Grid.Column="0" Text="API Key" VerticalAlignment="Center" Margin="0,0,12,10"/>
            <PasswordBox Name="pwdApiKey" Grid.Row="3" Grid.Column="1" Margin="0,0,0,10"/>
            <TextBlock Grid.Row="4" Grid.Column="0" Text="Temperatura" VerticalAlignment="Center" Margin="0,0,12,10"/>
            <TextBox Name="txtTemperature" Grid.Row="4" Grid.Column="1" Margin="0,0,0,10"/>
            <TextBlock Grid.Row="5" Grid.Column="0" Text="Max tokens" VerticalAlignment="Center" Margin="0,0,12,10"/>
            <TextBox Name="txtMaxTokens" Grid.Row="5" Grid.Column="1" Margin="0,0,0,10"/>
            <CheckBox Name="chkVideoFinder" Grid.Row="6" Grid.ColumnSpan="2" Content="Habilitar buscador de videos" Margin="0,4,0,0"/>
        </Grid>

        <Grid Grid.Row="2" Margin="0,20,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <Button Name="btnTestAi" Grid.Column="0" Content="Probar conexion" HorizontalAlignment="Left"/>
            <Button Name="btnCancelAi" Grid.Column="1" Content="Cancelar" Margin="8,0,0,0"/>
            <Button Name="btnSaveAi" Grid.Column="2" Content="Guardar" Margin="8,0,0,0" Background="#007AFF" Foreground="White"/>
        </Grid>
    </Grid>
</Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $dlg = [System.Windows.Markup.XamlReader]::Load($reader)
    $dlg.Owner = $formPrincipal

    $chkEnabled = $dlg.FindName("chkEnabled")
    $cmbProvider = $dlg.FindName("cmbProvider")
    $cmbModel = $dlg.FindName("cmbModel")
    $pwdApiKey = $dlg.FindName("pwdApiKey")
    $txtTemperature = $dlg.FindName("txtTemperature")
    $txtMaxTokens = $dlg.FindName("txtMaxTokens")
    $chkVideoFinder = $dlg.FindName("chkVideoFinder")

    $chkEnabled.IsChecked = [bool]$cfg.Enabled
    $cmbProvider.Text = $cfg.Provider
    $cmbModel.Text = $cfg.Model
    $pwdApiKey.Password = $cfg.ApiKey
    $txtTemperature.Text = $cfg.Temperature.ToString([System.Globalization.CultureInfo]::InvariantCulture)
    $txtMaxTokens.Text = [string]$cfg.MaxOutputTokens
    $chkVideoFinder.IsChecked = [bool]$cfg.VideoFinderEnabled

    $dlg.FindName("btnTestAi").Add_Click({
        $temp = 0.2
        $tokens = 128
        [void][double]::TryParse($txtTemperature.Text, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$temp)
        [void][int]::TryParse($txtMaxTokens.Text, [ref]$tokens)
        $result = Test-AiConnection -Model $cmbModel.Text -ApiKey $pwdApiKey.Password -Temperature 0 -MaxOutputTokens 128
        if ($result.Ok) {
            [System.Windows.MessageBox]::Show("Conexion correcta con Gemini.", "IA", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        } else {
            [System.Windows.MessageBox]::Show($result.Message, "No se pudo conectar", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        }
    })
    $dlg.FindName("btnCancelAi").Add_Click({ $dlg.Close() })
    $dlg.FindName("btnSaveAi").Add_Click({
        $temp = 0.2
        $tokens = 2048
        [void][double]::TryParse($txtTemperature.Text, [System.Globalization.NumberStyles]::Float, [System.Globalization.CultureInfo]::InvariantCulture, [ref]$temp)
        [void][int]::TryParse($txtMaxTokens.Text, [ref]$tokens)
        Save-AiConfig `
            -Enabled ([bool]$chkEnabled.IsChecked) `
            -Provider $cmbProvider.Text `
            -Model $cmbModel.Text `
            -ApiKey $pwdApiKey.Password `
            -Temperature $temp `
            -MaxOutputTokens $tokens `
            -ChatEnabled ([bool]$chkEnabled.IsChecked) `
            -VideoFinderEnabled ([bool]$chkVideoFinder.IsChecked)
        $script:AiEnabled = [bool]$chkEnabled.IsChecked
        Update-AiButtonVisual
        $dlg.DialogResult = $true
        $dlg.Close()
    })

    $dlg.ShowDialog() | Out-Null
}

function Add-AiChatMessage {
    param($Panel, [string]$Author, [string]$Text, [bool]$IsError = $false)
    if (-not $Panel) { return }
    $border = New-Object System.Windows.Controls.Border
    $border.Margin = "0,0,0,8"
    $border.Padding = "10"
    $border.CornerRadius = "6"
    $border.Background = if ($IsError) { "#FFF0F0" } elseif ($Author -eq "Usuario") { "#E8F2FF" } else { "#F2F2F7" }
    $stack = New-Object System.Windows.Controls.StackPanel
    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = $Author
    $title.FontWeight = "SemiBold"
    $title.Margin = "0,0,0,4"
    $body = New-Object System.Windows.Controls.TextBlock
    $body.Text = $Text
    $body.TextWrapping = "Wrap"
    $body.Foreground = if ($IsError) { "#B00020" } else { "#1D1D1F" }
    [void]$stack.Children.Add($title)
    [void]$stack.Children.Add($body)
    $border.Child = $stack
    [void]$Panel.Children.Add($border)
}

function Add-AiVideoResultCard {
    param($Panel, $Video, $Checks)
    $card = New-Object System.Windows.Controls.Border
    $card.Margin = "0,0,0,8"
    $card.Padding = "10"
    $card.BorderBrush = "#D1D1D6"
    $card.BorderThickness = "1"
    $card.CornerRadius = "6"
    $card.Background = "White"

    $grid = New-Object System.Windows.Controls.Grid
    $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" }))
    $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "*" }))
    $grid.ColumnDefinitions.Add((New-Object System.Windows.Controls.ColumnDefinition -Property @{ Width = "Auto" }))

    $chk = New-Object System.Windows.Controls.CheckBox
    $chk.IsChecked = $true
    $chk.VerticalAlignment = "Top"
    $chk.Margin = "0,3,10,0"
    $chk.Tag = $Video
    [System.Windows.Controls.Grid]::SetColumn($chk, 0)

    $textStack = New-Object System.Windows.Controls.StackPanel
    $title = New-Object System.Windows.Controls.TextBlock
    $title.Text = if ($Video.title) { [string]$Video.title } else { "Video" }
    $title.FontWeight = "SemiBold"
    $title.TextWrapping = "Wrap"
    $url = New-Object System.Windows.Controls.TextBlock
    $url.Text = [string]$Video.url
    $url.Foreground = "#6E6E73"
    $url.FontSize = 12
    $url.TextWrapping = "Wrap"
    $meta = New-Object System.Windows.Controls.TextBlock
    $confidence = if ($Video.confidence -ne $null) { "{0:P0}" -f ([double]$Video.confidence) } else { "n/d" }
    $meta.Text = "Fuente: {0}   Confianza: {1}" -f $Video.source, $confidence
    $meta.Foreground = "#6E6E73"
    $meta.FontSize = 12
    $meta.Margin = "0,4,0,0"
    [void]$textStack.Children.Add($title)
    [void]$textStack.Children.Add($url)
    [void]$textStack.Children.Add($meta)
    [System.Windows.Controls.Grid]::SetColumn($textStack, 1)

    $btns = New-Object System.Windows.Controls.StackPanel
    $btns.Orientation = "Horizontal"
    $btns.Margin = "10,0,0,0"
    $btnCopy = New-Object System.Windows.Controls.Button
    $btnCopy.Content = "Copiar"
    $btnCopy.Height = 28
    $btnCopy.MinWidth = 64
    $btnCopy.Margin = "0,0,6,0"
    $copyUrl = [string]$Video.url
    $btnCopy.Add_Click({ try { [System.Windows.Clipboard]::SetText($copyUrl) } catch {} }.GetNewClosure())
    $btnProbe = New-Object System.Windows.Controls.Button
    $btnProbe.Content = "Probar"
    $btnProbe.Height = 28
    $btnProbe.MinWidth = 64
    $probeUrl = [string]$Video.url
    $btnProbe.Add_Click({
        $probe = Invoke-YtDlpSingleVideoInfo -Url $probeUrl
        if ($probe) {
            [System.Windows.MessageBox]::Show("yt-dlp pudo leer el video.", "Prueba", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        } else {
            [System.Windows.MessageBox]::Show("yt-dlp no pudo validar este enlace.", "Prueba", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
        }
    }.GetNewClosure())
    [void]$btns.Children.Add($btnCopy)
    [void]$btns.Children.Add($btnProbe)
    [System.Windows.Controls.Grid]::SetColumn($btns, 2)

    [void]$grid.Children.Add($chk)
    [void]$grid.Children.Add($textStack)
    [void]$grid.Children.Add($btns)
    $card.Child = $grid
    [void]$Panel.Children.Add($card)
    [void]$Checks.Add($chk)
}

function Show-AiChatWindow {
    $cfg = Get-AiConfig
    if (-not $cfg.Enabled -or [string]::IsNullOrWhiteSpace($cfg.ApiKey)) {
        [System.Windows.MessageBox]::Show("Activa la IA y configura una API Key de Gemini.", "IA", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        Show-AiSettingsDialog
        $cfg = Get-AiConfig
        if (-not $cfg.Enabled -or [string]::IsNullOrWhiteSpace($cfg.ApiKey)) { return }
    }

    $xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Asistente IA" Height="680" Width="780"
        WindowStartupLocation="CenterOwner" Background="#F5F5F7">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Height" Value="34"/>
            <Setter Property="MinWidth" Value="92"/>
            <Setter Property="Padding" Value="12,0"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Background" Value="#E5E5EA"/>
            <Setter Property="Foreground" Value="#1D1D1F"/>
            <Setter Property="BorderThickness" Value="0"/>
        </Style>
    </Window.Resources>
    <Grid Margin="18">
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="2*"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="2*"/>
            <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Grid Grid.Row="0" Margin="0,0,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <StackPanel>
                <TextBlock Text="Asistente IA" FontSize="22" FontWeight="SemiBold"/>
                <TextBlock Name="lblAiStatus" Text="Gemini listo" Foreground="#6E6E73" Margin="0,3,0,0"/>
            </StackPanel>
            <Button Name="btnAiSettings" Grid.Column="1" Content="Configurar"/>
        </Grid>
        <Border Grid.Row="1" Background="White" BorderBrush="#D1D1D6" BorderThickness="1" CornerRadius="6">
            <ScrollViewer Name="svMessages" VerticalScrollBarVisibility="Auto" Padding="10">
                <StackPanel Name="spAiMessages"/>
            </ScrollViewer>
        </Border>
        <Grid Grid.Row="2" Margin="0,12,0,12">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox Name="txtAiInput" Grid.Column="0" Height="66" AcceptsReturn="True" TextWrapping="Wrap" VerticalScrollBarVisibility="Auto" Padding="8"/>
            <Button Name="btnAiSend" Grid.Column="1" Content="Enviar" Margin="8,0,0,0" Background="#007AFF" Foreground="White"/>
            <Button Name="btnAiFindVideos" Grid.Column="2" Content="Buscar videos" Margin="8,0,0,0" Background="#34C759" Foreground="White"/>
        </Grid>
        <Border Grid.Row="3" Background="White" BorderBrush="#D1D1D6" BorderThickness="1" CornerRadius="6">
            <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="10">
                <StackPanel Name="spAiResults"/>
            </ScrollViewer>
        </Border>
        <Grid Grid.Row="4" Margin="0,12,0,0">
            <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBlock Name="lblAiFooter" Text="Pega un enlace o escribe una peticion." Foreground="#6E6E73" VerticalAlignment="Center"/>
            <Button Name="btnAddAiVideosToQueue" Grid.Column="1" Content="Agregar seleccionados" Background="#007AFF" Foreground="White"/>
            <Button Name="btnCloseAi" Grid.Column="2" Content="Cerrar" Margin="8,0,0,0"/>
        </Grid>
    </Grid>
</Window>
"@
    $reader = New-Object System.Xml.XmlNodeReader ([xml]$xaml)
    $win = [System.Windows.Markup.XamlReader]::Load($reader)
    $win.Owner = $formPrincipal

    $spMessages = $win.FindName("spAiMessages")
    $svMessages = $win.FindName("svMessages")
    $txtInput = $win.FindName("txtAiInput")
    $spResults = $win.FindName("spAiResults")
    $lblStatus = $win.FindName("lblAiStatus")
    $lblFooter = $win.FindName("lblAiFooter")
    $btnSend = $win.FindName("btnAiSend")
    $btnFind = $win.FindName("btnAiFindVideos")
    $btnAdd = $win.FindName("btnAddAiVideosToQueue")
    $checks = New-Object System.Collections.ArrayList

    Add-AiChatMessage -Panel $spMessages -Author "IA" -Text "Pega un enlace y usa Buscar videos para detectar opciones descargables."

    $win.FindName("btnAiSettings").Add_Click({ Show-AiSettingsDialog; Update-AiButtonVisual })
    $win.FindName("btnCloseAi").Add_Click({ $win.Close() })

    $btnSend.Add_Click({
        $message = $txtInput.Text.Trim()
        if ([string]::IsNullOrWhiteSpace($message)) { return }
        Add-AiChatMessage -Panel $spMessages -Author "Usuario" -Text $message
        $txtInput.Clear()
        $lblStatus.Text = "Consultando Gemini..."
        $btnSend.IsEnabled = $false
        try {
            $currentCfg = Get-AiConfig
            $reply = Invoke-GeminiGenerateContent `
                -Prompt $message `
                -SystemInstruction "Eres el asistente de YTDLL. Responde breve y en espanol." `
                -Model $currentCfg.Model `
                -ApiKey $currentCfg.ApiKey `
                -Temperature $currentCfg.Temperature `
                -MaxOutputTokens $currentCfg.MaxOutputTokens `
                -ResponseMimeType "text/plain"
            Add-AiChatMessage -Panel $spMessages -Author "IA" -Text $reply
        } catch {
            Add-AiChatMessage -Panel $spMessages -Author "Error" -Text $_.Exception.Message -IsError $true
        } finally {
            $btnSend.IsEnabled = $true
            $lblStatus.Text = "Gemini listo"
            try { $svMessages.ScrollToEnd() } catch {}
        }
    })

    $btnFind.Add_Click({
        $message = $txtInput.Text.Trim()
        $url = Get-FirstUrlFromText -Text $message
        if ([string]::IsNullOrWhiteSpace($url)) {
            [System.Windows.MessageBox]::Show("Pega una URL para buscar videos.", "Falta URL", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Warning) | Out-Null
            return
        }
        Add-AiChatMessage -Panel $spMessages -Author "Usuario" -Text $message
        $txtInput.Clear()
        $spResults.Children.Clear()
        $checks.Clear()
        $lblStatus.Text = "Buscando videos..."
        $lblFooter.Text = "Analizando enlace..."
        $btnFind.IsEnabled = $false
        try {
            $result = Find-VideosFromUrlWithAi -Url $url
            Add-AiChatMessage -Panel $spMessages -Author "IA" -Text $result.summary
            foreach ($warning in @($result.warnings)) {
                if (-not [string]::IsNullOrWhiteSpace($warning)) {
                    Add-AiChatMessage -Panel $spMessages -Author "Aviso" -Text ([string]$warning)
                }
            }
            foreach ($video in @($result.videos)) {
                Add-AiVideoResultCard -Panel $spResults -Video $video -Checks $checks
            }
            if (@($result.videos).Count -eq 0) {
                $empty = New-Object System.Windows.Controls.TextBlock
                $empty.Text = "No se encontraron videos descargables en ese enlace."
                $empty.Foreground = "#6E6E73"
                $empty.Margin = "4"
                [void]$spResults.Children.Add($empty)
            }
            $lblFooter.Text = "{0} resultado(s) listo(s)." -f @($result.videos).Count
        } catch {
            Add-AiChatMessage -Panel $spMessages -Author "Error" -Text $_.Exception.Message -IsError $true
            $lblFooter.Text = "No se pudo completar la busqueda."
        } finally {
            $btnFind.IsEnabled = $true
            $lblStatus.Text = "Gemini listo"
            try { $svMessages.ScrollToEnd() } catch {}
        }
    })

    $btnAdd.Add_Click({
        $selected = @()
        foreach ($chk in @($checks)) {
            if ($chk.IsChecked) { $selected += $chk.Tag }
        }
        if ($selected.Count -eq 0) {
            [System.Windows.MessageBox]::Show("Selecciona al menos un video.", "Cola", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
            return
        }
        $res = Add-VideoFinderResultsToQueue -Videos $selected
        $text = "Agregados: {0}`nOmitidos: {1}" -f $res.Added, $res.Skipped
        if ($res.Messages.Count -gt 0) { $text += "`n`n" + (($res.Messages | Select-Object -First 5) -join "`n") }
        [System.Windows.MessageBox]::Show($text, "Cola de descargas", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null
        $lblFooter.Text = "Cola actualizada."
    })

    $win.ShowDialog() | Out-Null
}

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
        $btnDescargar.Content = "Agregar a cola"
        $btnDescargar.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(52, 199, 89)))
        $btnDescargar.ToolTip = "Consulta válida: agregar esta descarga a la cola"
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

function Update-CookieButtonVisual {
    <#
    .SYNOPSIS
        Pinta el boton 🍪 segun el estado de cookies:
        Verde  = hay cookies activas en sesion
        Naranja= hay archivos guardados pero ninguno activo ahora
        Rojo   = no hay nada configurado
    #>
    $hasActive = -not [string]::IsNullOrWhiteSpace($script:cookiesPath) -and
                 (Test-Path -LiteralPath $script:cookiesPath -ErrorAction SilentlyContinue)

    $anySaved = @("edge","chrome","brave","firefox","opera","vivaldi") |
                Where-Object { Test-Path (Join-Path $env:TEMP "ytdll_cookies_$_.txt") -ErrorAction SilentlyContinue } |
                Select-Object -First 1

    if ($hasActive) {
        $kb = [math]::Round((Get-Item $script:cookiesPath).Length / 1KB, 1)
        $btnPickCookies.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(52,199,89)))
        $btnPickCookies.ToolTip    = "Cookies activas ($kb KB)`nClic para cambiar"
    } elseif ($anySaved) {
        $btnPickCookies.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255,159,10)))
        $btnPickCookies.ToolTip    = "Cookies guardadas disponibles`nClic para activar"
    } else {
        $btnPickCookies.Background = (New-Object System.Windows.Media.SolidColorBrush([System.Windows.Media.Color]::FromRgb(255,59,48)))
        $btnPickCookies.ToolTip    = "Sin cookies configuradas`nClic para configurar"
    }
}

function Show-CookieDialog {
    <#
    .SYNOPSIS
        Ventana estilo macOS centrada en formPrincipal.
        Tarjetas grandes con emoji real (via ConvertFromUtf32) y colores por estado.
        Rojo  = instalado, sin cookies
        Verde = tiene archivo de cookies guardado
        Azul  = activo en esta sesion
        Gris  = navegador no instalado
    #>

    # ── Emojis via ConvertFromUtf32 (evita problemas de encoding en bytes) ──
    $eEdge    = [char]::ConvertFromUtf32(0x1F535)  # 🔵
    $eChrome  = [char]::ConvertFromUtf32(0x1F534)  # 🔴
    $eBrave   = [char]::ConvertFromUtf32(0x1F981)  # 🦁
    $eFirefox = [char]::ConvertFromUtf32(0x1F98A)  # 🦊
    $eOpera   = [char]0x2295                        # ⊕
    $eVivaldi = [char]::ConvertFromUtf32(0x1F7E3)  # 🟣
    $eFile    = [char]::ConvertFromUtf32(0x1F4C1)  # 📁

    # ── Tabla de navegadores ─────────────────────────────────────────────────
    $browsers = @(
        @{ Id="edge";    Label="Edge";    Emoji=$eEdge;    Profile="$env:LOCALAPPDATA\Microsoft\Edge\User Data" },
        @{ Id="chrome";  Label="Chrome";  Emoji=$eChrome;  Profile="$env:LOCALAPPDATA\Google\Chrome\User Data" },
        @{ Id="brave";   Label="Brave";   Emoji=$eBrave;   Profile="$env:LOCALAPPDATA\BraveSoftware\Brave-Browser\User Data" },
        @{ Id="firefox"; Label="Firefox"; Emoji=$eFirefox; Profile="$env:APPDATA\Mozilla\Firefox\Profiles" },
        @{ Id="opera";   Label="Opera";   Emoji=$eOpera;   Profile="$env:APPDATA\Opera Software\Opera Stable" },
        @{ Id="vivaldi"; Label="Vivaldi"; Emoji=$eVivaldi; Profile="$env:LOCALAPPDATA\Vivaldi\User Data" }
    )

    # ── Helper: color segun estado ───────────────────────────────────────────
    function Get-CardBrush([hashtable]$b) {
        $cookieFile = Join-Path $env:TEMP "ytdll_cookies_$($b.Id).txt"
        $isActive   = ($script:cookiesPath -and $script:cookiesPath -eq $cookieFile -and (Test-Path $cookieFile))
        $hasFile    = (Test-Path $cookieFile -ErrorAction SilentlyContinue)
        $installed  = (Test-Path $b.Profile -ErrorAction SilentlyContinue)
        $hex = if ($isActive)       { "#007AFF" }   # Azul  - activo ahora
               elseif ($hasFile)    { "#34C759" }   # Verde - cookies guardadas
               elseif ($installed)  { "#FF3B30" }   # Rojo  - instalado, sin cookies
               else                 { "#8E8E93" }   # Gris  - no instalado
        $c = [System.Windows.Media.ColorConverter]::ConvertFromString($hex)
        return New-Object System.Windows.Media.SolidColorBrush($c)
    }

    # ── XAML - tarjetas con nombres, emoji interpolado via PS ────────────────
[xml]$dlgXaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Cookies" Width="620" SizeToContent="Height"
        WindowStartupLocation="CenterOwner" ResizeMode="NoResize"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent">
    <Border Background="#F5F5F7" CornerRadius="20" Margin="12">
        <Border.Effect>
            <DropShadowEffect Color="Black" Opacity="0.22" BlurRadius="32" ShadowDepth="8" Direction="270"/>
        </Border.Effect>
        <StackPanel Margin="28,22,28,26">

            <TextBlock Text="Cookies de YouTube" FontSize="19" FontWeight="Bold"
                       Foreground="#1D1D1F" HorizontalAlignment="Center" Margin="0,0,0,6"/>

            <TextBlock TextWrapping="Wrap" HorizontalAlignment="Center"
                       Foreground="#86868B" FontSize="13" TextAlignment="Center" Margin="0,0,0,18">
                Elige tu navegador. Cierra el navegador por completo antes de continuar.
            </TextBlock>

            <!-- Leyenda -->
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,20">
                <Ellipse Fill="#FF3B30" Width="10" Height="10" VerticalAlignment="Center" Margin="0,0,5,0"/>
                <TextBlock Text="Sin cookies" Foreground="#86868B" FontSize="11" VerticalAlignment="Center" Margin="0,0,14,0"/>
                <Ellipse Fill="#34C759" Width="10" Height="10" VerticalAlignment="Center" Margin="0,0,5,0"/>
                <TextBlock Text="Guardadas" Foreground="#86868B" FontSize="11" VerticalAlignment="Center" Margin="0,0,14,0"/>
                <Ellipse Fill="#007AFF" Width="10" Height="10" VerticalAlignment="Center" Margin="0,0,5,0"/>
                <TextBlock Text="Activo" Foreground="#86868B" FontSize="11" VerticalAlignment="Center" Margin="0,0,14,0"/>
                <Ellipse Fill="#8E8E93" Width="10" Height="10" VerticalAlignment="Center" Margin="0,0,5,0"/>
                <TextBlock Text="No instalado" Foreground="#86868B" FontSize="11" VerticalAlignment="Center"/>
            </StackPanel>

            <!-- Tarjetas (6 navegadores en WrapPanel) -->
            <WrapPanel HorizontalAlignment="Center" Margin="0,0,0,20">
                <Border Name="card_edge"    Width="88" Height="88" CornerRadius="18" Margin="7" Cursor="Hand">
                    <Border.Effect><DropShadowEffect Color="Black" Opacity="0.13" BlurRadius="10" ShadowDepth="3" Direction="270"/></Border.Effect>
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                        <TextBlock Name="ico_edge"    Text="$eEdge"    FontSize="30" HorizontalAlignment="Center"/>
                        <TextBlock Text="Edge"    Foreground="White" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Border>
                <Border Name="card_chrome"  Width="88" Height="88" CornerRadius="18" Margin="7" Cursor="Hand">
                    <Border.Effect><DropShadowEffect Color="Black" Opacity="0.13" BlurRadius="10" ShadowDepth="3" Direction="270"/></Border.Effect>
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                        <TextBlock Name="ico_chrome"  Text="$eChrome"  FontSize="30" HorizontalAlignment="Center"/>
                        <TextBlock Text="Chrome"  Foreground="White" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Border>
                <Border Name="card_brave"   Width="88" Height="88" CornerRadius="18" Margin="7" Cursor="Hand">
                    <Border.Effect><DropShadowEffect Color="Black" Opacity="0.13" BlurRadius="10" ShadowDepth="3" Direction="270"/></Border.Effect>
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                        <TextBlock Name="ico_brave"   Text="$eBrave"   FontSize="30" HorizontalAlignment="Center"/>
                        <TextBlock Text="Brave"   Foreground="White" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Border>
                <Border Name="card_firefox" Width="88" Height="88" CornerRadius="18" Margin="7" Cursor="Hand">
                    <Border.Effect><DropShadowEffect Color="Black" Opacity="0.13" BlurRadius="10" ShadowDepth="3" Direction="270"/></Border.Effect>
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                        <TextBlock Name="ico_firefox" Text="$eFirefox" FontSize="30" HorizontalAlignment="Center"/>
                        <TextBlock Text="Firefox" Foreground="White" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Border>
                <Border Name="card_opera"   Width="88" Height="88" CornerRadius="18" Margin="7" Cursor="Hand">
                    <Border.Effect><DropShadowEffect Color="Black" Opacity="0.13" BlurRadius="10" ShadowDepth="3" Direction="270"/></Border.Effect>
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                        <TextBlock Name="ico_opera"   Text="$eOpera"   FontSize="30" HorizontalAlignment="Center"/>
                        <TextBlock Text="Opera"   Foreground="White" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Border>
                <Border Name="card_vivaldi" Width="88" Height="88" CornerRadius="18" Margin="7" Cursor="Hand">
                    <Border.Effect><DropShadowEffect Color="Black" Opacity="0.13" BlurRadius="10" ShadowDepth="3" Direction="270"/></Border.Effect>
                    <StackPanel VerticalAlignment="Center" HorizontalAlignment="Center">
                        <TextBlock Name="ico_vivaldi" Text="$eVivaldi" FontSize="30" HorizontalAlignment="Center"/>
                        <TextBlock Text="Vivaldi" Foreground="White" FontSize="11" FontWeight="SemiBold" HorizontalAlignment="Center" Margin="0,5,0,0"/>
                    </StackPanel>
                </Border>
            </WrapPanel>

            <Separator Margin="0,0,0,16"/>

            <!-- Opciones extra -->
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Center" Margin="0,0,0,4">
                <Button Name="btnSelectFile"   Content="  $eFile  Seleccionar archivo cookies.txt  "
                        Cursor="Hand" Height="36" FontSize="13"
                        Background="#E5E5EA" Foreground="#1D1D1F" BorderThickness="0" Margin="0,0,12,0">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Name="fb" Background="{TemplateBinding Background}" CornerRadius="10">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="14,0"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="fb" Property="Background" Value="#D1D1D6"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
                <Button Name="btnClearCookies" Content="  Borrar activas  "
                        Cursor="Hand" Height="36" FontSize="13"
                        Background="#FF3B30" Foreground="White" BorderThickness="0">
                    <Button.Template>
                        <ControlTemplate TargetType="Button">
                            <Border Name="cb" Background="{TemplateBinding Background}" CornerRadius="10">
                                <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center" Margin="14,0"/>
                            </Border>
                            <ControlTemplate.Triggers>
                                <Trigger Property="IsMouseOver" Value="True">
                                    <Setter TargetName="cb" Property="Background" Value="#C9302C"/>
                                </Trigger>
                            </ControlTemplate.Triggers>
                        </ControlTemplate>
                    </Button.Template>
                </Button>
            </StackPanel>

            <Button Name="btnCloseDlg" Content="Cancelar" Cursor="Hand" Height="32"
                    FontSize="13" Background="Transparent" Foreground="#86868B"
                    BorderThickness="0" HorizontalAlignment="Center" Margin="0,12,0,0"/>
        </StackPanel>
    </Border>
</Window>
"@

    $reader = (New-Object System.Xml.XmlNodeReader $dlgXaml)
    $dlg    = [System.Windows.Markup.XamlReader]::Load($reader)
    $dlg.Owner = $formPrincipal

    # ── Aplicar colores a las tarjetas segun estado ──────────────────────────
    foreach ($b in $browsers) {
        $card = $dlg.FindName("card_$($b.Id)")
        if ($card) { $card.Background = Get-CardBrush $b }
    }

    # ── Conectar eventos de tarjetas ─────────────────────────────────────────
    $fnExport3  = ${function:Export-BrowserCookies}
    $fnSetAct3  = ${function:Set-CookiesActive}
    $fnUpdBtn3  = ${function:Update-CookieButtonVisual}

    foreach ($b in $browsers) {
        $card   = $dlg.FindName("card_$($b.Id)")
        if (-not $card) { continue }
        $bid    = $b.Id
        $blabel = $b.Label
        $lE = $fnExport3; $lS = $fnSetAct3; $lU = $fnUpdBtn3; $lD = $dlg

        $card.Add_MouseLeftButtonUp({
            Write-Host "[COOKIES] Tarjeta: $bid" -ForegroundColor Cyan
            $lD.Hide()
            $path = & $lE -Browser $bid
            if ($path) {
                & $lS -Path $path -Label $blabel
                & $lU
                $lD.Close()
            } else {
                $lD.ShowDialog() | Out-Null
            }
        }.GetNewClosure())

        $card.Add_MouseEnter({ $this.Opacity = 0.80 })
        $card.Add_MouseLeave({ $this.Opacity = 1.0  })
    }

    # ── Archivo manual ────────────────────────────────────────────────────────
    $lS4 = $fnSetAct3; $lU4 = $fnUpdBtn3; $lD4 = $dlg
    $dlg.FindName("btnSelectFile").Add_Click({
        $ofd = New-Object Microsoft.Win32.OpenFileDialog
        $ofd.Title  = "Selecciona tu archivo cookies.txt"
        $ofd.Filter = "Cookies (*.txt)|*.txt|Todos (*.*)|*.*"
        if ($ofd.ShowDialog() -eq $true) {
            & $lS4 -Path $ofd.FileName -Label $ofd.SafeFileName
            & $lU4
            $lD4.Close()
        }
    }.GetNewClosure())

    # ── Borrar cookies activas ────────────────────────────────────────────────
    $lU5 = $fnUpdBtn3; $lD5 = $dlg
    $dlg.FindName("btnClearCookies").Add_Click({
        $script:cookiesPath = $null
        Write-Host "[COOKIES] Cookies activas borradas del estado." -ForegroundColor Yellow
        & $lU5
        $lD5.Close()
    }.GetNewClosure())

    $dlg.FindName("btnCloseDlg").Add_Click({ $dlg.Close() })
    $dlg.ShowDialog() | Out-Null
}

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
