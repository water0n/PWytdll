$file = "c:\Users\water\Documents\githubProyects\YTDLL\Functions.ps1"
$content = Get-Content -Path $file -Raw -Encoding UTF8

$content = $content.Replace(
    '$obj = Invoke-CaptureResponsive -ExePath $yt.Source -Args @("-J","--no-playlist",$Url) -WorkingText "Leyendo metadatos."',
    "`$tmpArgs = @(`"-J`",`"--no-playlist`")`n    if (`$script:cookiesBrowser)           { `$tmpArgs += @(`"--cookies-from-browser`", `$script:cookiesBrowser) }`n    elseif (`$script:cookiesPath)          { `$tmpArgs += @(`"--cookies`",`$script:cookiesPath) }`n    `$tmpArgs += `$Url`n    `$obj = Invoke-CaptureResponsive -ExePath `$yt.Source -Args `$tmpArgs -WorkingText `"Leyendo metadatos.`""
)

$content = $content.Replace(
    '$res = Invoke-Capture -ExePath $yt.Source -Args @("--flat-playlist","--print","url","--no-warnings","--playlist-items","1",$Url)',
    "`$tmpArgs = @(`"--flat-playlist`",`"--print`",`"url`",`"--no-warnings`",`"--playlist-items`",`"1`")`n        if (`$script:cookiesBrowser)           { `$tmpArgs += @(`"--cookies-from-browser`", `$script:cookiesBrowser) }`n        elseif (`$script:cookiesPath)          { `$tmpArgs += @(`"--cookies`",`$script:cookiesPath) }`n        `$tmpArgs += `$Url`n        `$res = Invoke-Capture -ExePath `$yt.Source -Args `$tmpArgs"
)

$content = $content.Replace(
    '$res = Invoke-Capture -ExePath $yt.Source -Args @("--list-thumbnails",$Url)',
    "`$tmpArgs = @(`"--list-thumbnails`")`n    if (`$script:cookiesBrowser)           { `$tmpArgs += @(`"--cookies-from-browser`", `$script:cookiesBrowser) }`n    elseif (`$script:cookiesPath)          { `$tmpArgs += @(`"--cookies`",`$script:cookiesPath) }`n    `$tmpArgs += `$Url`n    `$res = Invoke-Capture -ExePath `$yt.Source -Args `$tmpArgs"
)

$content = $content.Replace(
    '$args1 = @("-J","--no-playlist","--ignore-config","--no-warnings",$Url)',
    "`$args1 = @(`"-J`",`"--no-playlist`",`"--ignore-config`",`"--no-warnings`")`n    if (`$script:cookiesBrowser)           { `$args1 += @(`"--cookies-from-browser`", `$script:cookiesBrowser) }`n    elseif (`$script:cookiesPath)          { `$args1 += @(`"--cookies`",`$script:cookiesPath) }`n    `$args1 += `$Url"
)

$content = $content.Replace(
    '$args = @("--no-playlist","--no-warnings","--ignore-config","--print","title","--print","thumbnail","--print","id",$Url)',
    "`$args = @(`"--no-playlist`",`"--no-warnings`",`"--ignore-config`",`"--print`",`"title`",`"--print`",`"thumbnail`",`"--print`",`"id`")`n    if (`$script:cookiesBrowser)           { `$args += @(`"--cookies-from-browser`", `$script:cookiesBrowser) }`n    elseif (`$script:cookiesPath)          { `$args += @(`"--cookies`",`$script:cookiesPath) }`n    `$args += `$Url"
)

$content = $content.Replace(
    '$picPreview.Image = $null',
    '$picPreview.Source = $null'
)

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Host "Patched Functions.ps1"
