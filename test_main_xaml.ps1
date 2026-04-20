Add-Type -AssemblyName PresentationFramework

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
        <!-- Estilo de Botón Primario -->
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
        <!-- Estilo de TextBox -->
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
        <!-- Estilo de ComboBox -->
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
                <RowDefinition Height="Auto"/> <!-- Header -->
                <RowDefinition Height="*"/>    <!-- Content -->
            </Grid.RowDefinitions>

            <!-- Header (Draggable Area) -->
            <Border Name="TitleBar" Grid.Row="0" Background="Transparent" Height="50" CornerRadius="16,16,0,0">
                <Grid>
                    <TextBlock Text="YTDLL" FontSize="16" FontWeight="SemiBold" VerticalAlignment="Center" HorizontalAlignment="Center"/>
                    <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" VerticalAlignment="Center" Margin="0,0,15,0">
                        <Button Name="btnPickCookies" Content="&amp;#x1F36A;" ToolTip="Cookies.txt" Background="Transparent" Foreground="$ColorSubText" BorderThickness="0" FontSize="18" Margin="0,0,10,0" Cursor="Hand"/>
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
            <StackPanel Grid.Row="1" Margin="25,5,25,25">
                
                <!-- URL Input -->
                <TextBox Name="txtUrl" Text="Escribe la URL del video" FontSize="16" TextAlignment="Center" Foreground="#8E8E93" Height="45" Margin="0,0,0,5" VerticalContentAlignment="Center"/>
                <Button Name="btnUrlHistory" Content="&amp;#x25BE; Historial" Background="Transparent" Foreground="$ColorPrimary" BorderThickness="0" Cursor="Hand" HorizontalAlignment="Right" Margin="0,0,0,20"/>
                <ContextMenu x:Name="ctxUrlHistory" Placement="Bottom" PlacementTarget="{Binding ElementName=btnUrlHistory}"/>

                <!-- Destination -->
                <Label Content="Carpeta de destino"/>
                <Grid Margin="0,0,0,15">
                    <Grid.ColumnDefinitions>
                        <ColumnDefinition Width="*"/>
                        <ColumnDefinition Width="Auto"/>
                    </Grid.ColumnDefinitions>
                    <TextBox Name="txtDestino" Grid.Column="0" IsReadOnly="True" Background="#E5E5EA" Foreground="$ColorSubText"/>
                    <Button Name="btnPickDestino" Grid.Column="1" Content="&amp;#x1F4C1;" Width="36" Margin="10,0,0,0" Background="#E5E5EA" Foreground="$ColorText" BorderThickness="0" Cursor="Hand">
                        <Button.Template>
                            <ControlTemplate TargetType="Button">
                                <Border Background="{TemplateBinding Background}" CornerRadius="8">
                                    <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                                </Border>
                            </ControlTemplate>
                        </Button.Template>
                    </Button>
                </Grid>

                <!-- Formats -->
                <Label Content="Formato de VIDEO"/>
                <ComboBox Name="cmbVideoFmt" Margin="0,0,0,15"/>
                
                <Label Content="Formato de AUDIO"/>
                <ComboBox Name="cmbAudioFmt" Margin="0,0,0,25"/>

                <!-- Download Button -->
                <Button Name="btnDescargar" Content="Descargar" Style="{StaticResource PrimaryButton}" Height="50" Margin="0,0,0,25"/>

                <!-- Preview Image -->
                <Label Content="Vista previa"/>
                <Border CornerRadius="12" Background="#E5E5EA" Height="180" Margin="0,0,0,20">
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

                <!-- Status Console -->
                <Border Background="#E5E5EA" CornerRadius="8" Padding="15" Margin="0,0,0,20">
                    <TextBlock Name="lblEstadoConsulta" Text="Estado: sin consultar" FontFamily="Consolas" FontSize="12" Foreground="$ColorText" TextWrapping="Wrap" TextAlignment="Center"/>
                </Border>

                <!-- Footer Actions -->
                <Grid>
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

            </StackPanel>
        </Grid>
    </Border>
</Window>
"@

try {
    $reader = (New-Object System.Xml.XmlNodeReader $xaml)
    $formPrincipal = [System.Windows.Markup.XamlReader]::Load($reader)
    Write-Host "PARSED OK!"
} catch {
    Write-Host "ERROR:" $_.Exception.Message
    $ex = $_.Exception
    while ($ex.InnerException) {
        $ex = $ex.InnerException
        Write-Host "INNER:" $ex.Message
    }
}
