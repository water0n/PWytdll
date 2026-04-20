$file = "c:\Users\water\Documents\githubProyects\YTDLL\Functions.ps1"
$content = Get-Content -Path $file -Raw -Encoding UTF8

$content = $content.Replace(
    '`n    $psi.RedirectStandardOutput = $true`n    $psi.RedirectStandardError  = $true`n    $psi.UseShellExecute        = $false`n    $psi.CreateNoWindow         = $true`n    Write-DebugLog "Exec: $ExePath $($psi.Arguments)"`n    $psi.RedirectStandardError  = $true`n    $psi.UseShellExecute        = $false`n    $psi.CreateNoWindow         = $true',
    '`n    $psi.RedirectStandardOutput = $true`n    $psi.RedirectStandardError  = $true`n    $psi.UseShellExecute        = $false`n    $psi.CreateNoWindow         = $true`n    Write-DebugLog "Exec: $ExePath $($psi.Arguments)"'
)

$content = $content.Replace(
    '$proc    = Start-Process -FilePath $ExePath -ArgumentList $argLine `',
    'Write-DebugLog "Exec: $ExePath $argLine"`n    $proc    = Start-Process -FilePath $ExePath -ArgumentList $argLine `'
)

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Host "Patched Functions.ps1 for DebugLog"
