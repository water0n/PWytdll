$file = "c:\Users\water\Documents\githubProyects\YTDLL\Dependencies.ps1"
$content = Get-Content -Path $file -Encoding UTF8

$content = $content -replace '\.ForeColor\s*=\s*\[System\.Drawing\.Color\]::ForestGreen', '.Foreground = [System.Windows.Media.Brushes]::ForestGreen'
$content = $content -replace '\.ForeColor\s*=\s*\[System\.Drawing\.Color\]::Red', '.Foreground = [System.Windows.Media.Brushes]::Red'
$content = $content -replace '\.ForeColor\s*=\s*\[System\.Drawing\.Color\]::Orange', '.Foreground = [System.Windows.Media.Brushes]::Orange'
$content = $content -replace '\.ForeColor\s*=\s*\[System\.Drawing\.Color\]::Black', '.Foreground = [System.Windows.Media.Brushes]::Black'

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Host "Replaced ForeColor in Dependencies.ps1"
