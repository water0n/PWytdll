$content = Get-Content -Path "c:\Users\water\Documents\githubProyects\YTDLL\Functions.ps1"
for ($i = 0; $i -lt $content.Count; $i++) {
    if ($content[$i] -match "(?i)Drawing\.Color|Windows\.Forms|lblEstadoConsulta") {
        Write-Output "Line $($i+1): $($content[$i].Trim())"
    }
}
