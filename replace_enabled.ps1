$file = "c:\Users\water\Documents\githubProyects\YTDLL\Functions.ps1"
$content = Get-Content -Path $file -Encoding UTF8

$content = $content -replace '\.Enabled\s*=\s*\$false', '.IsEnabled = $false'
$content = $content -replace '\.Enabled\s*=\s*\$true', '.IsEnabled = $true'

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Host "Replaced IsEnabled"
