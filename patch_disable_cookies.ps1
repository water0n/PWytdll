$fileFunc = "c:\Users\water\Documents\githubProyects\YTDLL\Functions.ps1"
$contentFunc = Get-Content -Path $fileFunc -Raw -Encoding UTF8

$contentFunc = $contentFunc -replace '(?m)^\s*if \(\$script:cookiesBrowser\)\s*\{[^\}]+\}\s*$', ''
$contentFunc = $contentFunc -replace '(?m)^\s*elseif \(\$script:cookiesPath\)\s*\{[^\}]+\}\s*$', ''

Set-Content -Path $fileFunc -Value $contentFunc -Encoding UTF8

$fileMain = "c:\Users\water\Documents\githubProyects\YTDLL\Main.ps1"
$contentMain = Get-Content -Path $fileMain -Raw -Encoding UTF8

$contentMain = $contentMain -replace '(?m)^\s*if \(\$script:cookiesBrowser\)\s*\{[^\}]+\}\s*$', ''
$contentMain = $contentMain -replace '(?m)^\s*elseif \(\$script:cookiesPath\)\s*\{[^\}]+\}\s*$', ''

Set-Content -Path $fileMain -Value $contentMain -Encoding UTF8
Write-Host "Cookies disabled in Functions.ps1 and Main.ps1"
