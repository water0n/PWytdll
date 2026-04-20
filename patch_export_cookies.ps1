$file = "c:\Users\water\Documents\githubProyects\YTDLL\Functions.ps1"
$content = Get-Content -Path $file -Raw -Encoding UTF8

$newFunction = @"

function Export-BrowserCookies {
    param([string]`$Browser)
    try { `$yt = Get-Command yt-dlp -ErrorAction Stop } catch { return `$false }
    
    `$tmpCookie = Join-Path `$env:TEMP "ytdll_cookies_`$Browser.txt"
    if (Test-Path `$tmpCookie) { Remove-Item `$tmpCookie -Force -ErrorAction SilentlyContinue }

    `$lblEstadoConsulta.Text = "Extrayendo cookies de `$Browser..."
    `$lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::DarkBlue
    try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}

    `$args = @("--cookies-from-browser", `$Browser, "--cookies", `$tmpCookie, "--print", "''")
    `$res = Invoke-CaptureResponsive -ExePath `$yt.Source -Args `$args -WorkingText "Extrayendo cookies" -TimeoutSec 30

    if (`$res.ExitCode -ne 0 -or -not (Test-Path `$tmpCookie)) {
        `$lblEstadoConsulta.Text = "ERROR: No se pudieron extraer cookies"
        `$lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Red
        [System.Windows.MessageBox]::Show("Hubo un error extrayendo las cookies de `$Browser.`n`nPor favor Cierra tu navegador y vuelve a intentarlo.`n`nDetalles: `$(`$res.StdErr)", "Error de Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Error) | Out-Null
        return `$null
    }
    
    `$lblEstadoConsulta.Text = "Cookies extraídas con éxito."
    `$lblEstadoConsulta.Foreground = [System.Windows.Media.Brushes]::Green
    return `$tmpCookie
}
"@

if ($content -notmatch 'function Export-BrowserCookies') {
    $content += $newFunction
    Set-Content -Path $file -Value $content -Encoding UTF8
    Write-Host "Added Export-BrowserCookies to Functions.ps1"
} else {
    Write-Host "Export-BrowserCookies already exists."
}
