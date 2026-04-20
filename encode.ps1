$content = Get-Content -LiteralPath '.\GUI.ps1' -Raw -Encoding UTF8
[System.IO.File]::WriteAllText("c:\Users\water\Documents\githubProyects\YTDLL\GUI.ps1", $content, [System.Text.Encoding]::UTF8)
