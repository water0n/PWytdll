$file = "c:\Users\water\Documents\githubProyects\YTDLL\Functions.ps1"
$content = Get-Content -Path $file -Raw -Encoding UTF8

$content = $content.Replace(
    'throw "Tiempo de espera agotado ($TimeoutSec s) en ''$WorkingText''."',
    'return [pscustomobject]@{ ExitCode = -1; StdOut = ""; StdErr = "Tiempo de espera agotado ($TimeoutSec s) en ''$WorkingText''." }'
)

$content = $content.Replace(
    '-TimeoutSec 30',
    '-TimeoutSec 60'
)

Set-Content -Path $file -Value $content -Encoding UTF8
Write-Host "Patched Timeout crash in Functions.ps1"
