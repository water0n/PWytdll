$file = "c:\Users\water\Documents\githubProyects\YTDLL\Functions.ps1"
$content = Get-Content -Path $file -Encoding UTF8

$replacements = @{
    '\[System\.Windows\.Forms\.Application\]::DoEvents\(\)' = 'try { [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background) } catch {}'
    '\.ForeColor\s*=\s*\[System\.Drawing\.Color\]::Red' = '.Foreground = [System.Windows.Media.Brushes]::Red'
    '\.ForeColor\s*=\s*\[System\.Drawing\.Color\]::DarkBlue' = '.Foreground = [System.Windows.Media.Brushes]::DarkBlue'
    '\.ForeColor\s*=\s*\[System\.Drawing\.Color\]::DarkOrange' = '.Foreground = [System.Windows.Media.Brushes]::DarkOrange'
    '\.ForeColor\s*=\s*\[System\.Drawing\.Color\]::DarkGreen' = '.Foreground = [System.Windows.Media.Brushes]::DarkGreen'
    '\.ForeColor\s*=\s*\[System\.Drawing\.Color\]::Black' = '.Foreground = [System.Windows.Media.Brushes]::Black'
    '\[System\.Windows\.Forms\.MessageBox\]::Show\("([^"]+)",\s*"([^"]+)",\s*\[System\.Windows\.Forms\.MessageBoxButtons\]::OK,\s*\[System\.Windows\.Forms\.MessageBoxIcon\]::Error\)' = '[System.Windows.MessageBox]::Show("$1","$2",[System.Windows.MessageBoxButton]::OK,[System.Windows.MessageBoxImage]::Error)'
    '\[System\.Windows\.Forms\.ComboBox\]\$Combo' = '[System.Windows.Controls.ComboBox]$Combo'
}

foreach ($key in $replacements.Keys) {
    $content = $content -replace $key, $replacements[$key]
}

Set-Content -Path $file -Value $content -Encoding UTF8
