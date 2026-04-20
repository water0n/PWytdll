$file = "c:\Users\water\Documents\githubProyects\YTDLL\Main.ps1"
$content = Get-Content -Path $file -Raw -Encoding UTF8

$browsers = @("edge", "chrome", "firefox", "brave", "opera", "vivaldi")

foreach ($b in $browsers) {
    $BName = (Get-Culture).TextInfo.ToTitleCase($b)
    
    $oldLine = "`$formPrincipal.FindName(`"miCookie$BName`").add_Click({ `$script:cookiesBrowser = `"$b`"; `$script:cookiesPath = `$null; Set-IniValue -Section `"cookies`" -Key `"Browser`" -Value `"$b`"; Set-IniValue -Section `"cookies`" -Key `"Path`" -Value `"`"; [System.Windows.MessageBox]::Show(`"Cookies: Navegador $BName seleccionado y guardado.`", `"Cookies`", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null })"
    
    $newLine = "`$formPrincipal.FindName(`"miCookie$BName`").add_Click({`n" +
               "    `$res = Export-BrowserCookies -Browser `"$b`"`n" +
               "    if (`$res) {`n" +
               "        `$script:cookiesPath = `$res`n" +
               "        `$script:cookiesBrowser = `$null`n" +
               "        Set-IniValue -Section `"cookies`" -Key `"Browser`" -Value `"$b`"`n" +
               "        Set-IniValue -Section `"cookies`" -Key `"Path`" -Value `$res`n" +
               "        [System.Windows.MessageBox]::Show(`"Cookies extraídas de $BName exitosamente.`", `"Cookies`", [System.Windows.MessageBoxButton]::OK, [System.Windows.MessageBoxImage]::Information) | Out-Null`n" +
               "    }`n" +
               "})"
    
    $content = $content.Replace($oldLine, $newLine)
}

$content = $content.Replace(
    '`$script:cookiesBrowser    = Get-IniValue -Section `"cookies`" -Key `"Browser`" -DefaultValue `$null',
    '`$script:cookiesBrowser    = `$null'
)

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Host "Patched Main.ps1 for Export-BrowserCookies"
