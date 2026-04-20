$file = "c:\Users\water\Documents\githubProyects\YTDLL\Functions.ps1"
$content = Get-Content -Path $file -Raw -Encoding UTF8

$content = $content.Replace(
    '`$args = @(`"--cookies-from-browser`", `$Browser, `"--cookies`", `$tmpCookie, `"--print`", `"`'`'`")`n    `$res = Invoke-CaptureResponsive -ExePath `$yt.Source -Args `$args -WorkingText `"Extrayendo cookies`" -TimeoutSec 30',
    '`$args = @(`"--cookies-from-browser`", `$Browser, `"--cookies`", `$tmpCookie, `"--ignore-config`", `"--no-warnings`", `"https://youtube.com/robots.txt`")`n    `$res = Invoke-CaptureResponsive -ExePath `$yt.Source -Args `$args -WorkingText `"Extrayendo cookies`" -TimeoutSec 120'
)

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Host "Patched Export-BrowserCookies with dummy URL and 120s timeout"
