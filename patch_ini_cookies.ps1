$file = "c:\Users\water\Documents\githubProyects\YTDLL\Main.ps1"
$content = Get-Content -Path $file -Raw -Encoding UTF8

$content = $content.Replace(
    '$script:cookiesPath       = $null`n$script:cookiesBrowser    = $null',
    '`$script:cookiesPath       = Get-IniValue -Section `"cookies`" -Key `"Path`" -DefaultValue `$null`n`$script:cookiesBrowser    = Get-IniValue -Section `"cookies`" -Key `"Browser`" -DefaultValue `$null'
)

$content = $content.Replace(
    '$formPrincipal.FindName("miCookieEdge").add_Click({ $script:cookiesBrowser = "edge"; $script:cookiesPath = $null; [System.Windows.MessageBox]::Show("Cookies: Navegador Edge seleccionado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })',
    '$formPrincipal.FindName("miCookieEdge").add_Click({ $script:cookiesBrowser = "edge"; $script:cookiesPath = $null; Set-IniValue -Section "cookies" -Key "Browser" -Value "edge"; Set-IniValue -Section "cookies" -Key "Path" -Value ""; [System.Windows.MessageBox]::Show("Cookies: Navegador Edge seleccionado y guardado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })'
)

$content = $content.Replace(
    '$formPrincipal.FindName("miCookieChrome").add_Click({ $script:cookiesBrowser = "chrome"; $script:cookiesPath = $null; [System.Windows.MessageBox]::Show("Cookies: Navegador Chrome seleccionado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })',
    '$formPrincipal.FindName("miCookieChrome").add_Click({ $script:cookiesBrowser = "chrome"; $script:cookiesPath = $null; Set-IniValue -Section "cookies" -Key "Browser" -Value "chrome"; Set-IniValue -Section "cookies" -Key "Path" -Value ""; [System.Windows.MessageBox]::Show("Cookies: Navegador Chrome seleccionado y guardado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })'
)

$content = $content.Replace(
    '$formPrincipal.FindName("miCookieFirefox").add_Click({ $script:cookiesBrowser = "firefox"; $script:cookiesPath = $null; [System.Windows.MessageBox]::Show("Cookies: Navegador Firefox seleccionado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })',
    '$formPrincipal.FindName("miCookieFirefox").add_Click({ $script:cookiesBrowser = "firefox"; $script:cookiesPath = $null; Set-IniValue -Section "cookies" -Key "Browser" -Value "firefox"; Set-IniValue -Section "cookies" -Key "Path" -Value ""; [System.Windows.MessageBox]::Show("Cookies: Navegador Firefox seleccionado y guardado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })'
)

$content = $content.Replace(
    '$formPrincipal.FindName("miCookieBrave").add_Click({ $script:cookiesBrowser = "brave"; $script:cookiesPath = $null; [System.Windows.MessageBox]::Show("Cookies: Navegador Brave seleccionado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })',
    '$formPrincipal.FindName("miCookieBrave").add_Click({ $script:cookiesBrowser = "brave"; $script:cookiesPath = $null; Set-IniValue -Section "cookies" -Key "Browser" -Value "brave"; Set-IniValue -Section "cookies" -Key "Path" -Value ""; [System.Windows.MessageBox]::Show("Cookies: Navegador Brave seleccionado y guardado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })'
)

$content = $content.Replace(
    '$formPrincipal.FindName("miCookieOpera").add_Click({ $script:cookiesBrowser = "opera"; $script:cookiesPath = $null; [System.Windows.MessageBox]::Show("Cookies: Navegador Opera seleccionado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })',
    '$formPrincipal.FindName("miCookieOpera").add_Click({ $script:cookiesBrowser = "opera"; $script:cookiesPath = $null; Set-IniValue -Section "cookies" -Key "Browser" -Value "opera"; Set-IniValue -Section "cookies" -Key "Path" -Value ""; [System.Windows.MessageBox]::Show("Cookies: Navegador Opera seleccionado y guardado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })'
)

$content = $content.Replace(
    '$formPrincipal.FindName("miCookieVivaldi").add_Click({ $script:cookiesBrowser = "vivaldi"; $script:cookiesPath = $null; [System.Windows.MessageBox]::Show("Cookies: Navegador Vivaldi seleccionado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })',
    '$formPrincipal.FindName("miCookieVivaldi").add_Click({ $script:cookiesBrowser = "vivaldi"; $script:cookiesPath = $null; Set-IniValue -Section "cookies" -Key "Browser" -Value "vivaldi"; Set-IniValue -Section "cookies" -Key "Path" -Value ""; [System.Windows.MessageBox]::Show("Cookies: Navegador Vivaldi seleccionado y guardado.", "Cookies", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })'
)

$content = $content.Replace(
    '$script:cookiesBrowser = $null`n        [System.Windows.MessageBox]::Show("Cookies configuradas archivo: $($script:cookiesPath)"',
    '$script:cookiesBrowser = $null`n        Set-IniValue -Section "cookies" -Key "Browser" -Value ""`n        Set-IniValue -Section "cookies" -Key "Path" -Value $script:cookiesPath`n        [System.Windows.MessageBox]::Show("Cookies configuradas archivo: $($script:cookiesPath)"'
)

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Host "Patched Main.ps1 for INI Cookies persistence"
