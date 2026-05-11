# Plan detallado de implementación: Configuración de IA + Buscador de videos con Gemini Flash en YTDLL

## 1. Objetivo general

Agregar a YTDLL una sección de configuración para activar IA, seleccionar proveedor/modelo y capturar la API Key. Cuando el usuario active la IA, la aplicación habilitará un chat integrado. La primera funcionalidad del chat será un **buscador de videos por enlace**: el usuario pega una URL y la IA ayuda a detectar videos disponibles dentro de ese enlace para agregarlos a la cola de descargas existente.

## 2. Alcance de la primera versión

### Incluido en el MVP

1. Nueva sección de configuración de IA.
2. Activación/desactivación de IA desde la interfaz.
3. Selección de proveedor y modelo.
4. Captura de API Key.
5. Persistencia local de configuración.
6. Chat básico dentro de la app.
7. Buscador de videos desde una URL.
8. Listado de videos encontrados.
9. Selección múltiple de videos detectados.
10. Agregar videos seleccionados a la cola de descargas.
11. Logs de diagnóstico para errores de IA y detección.

### No incluido en el MVP

1. Descarga automática desde el chat sin confirmación del usuario.
2. Soporte para múltiples proveedores además de Gemini.
3. Streaming de respuestas de la IA.
4. Historial largo de conversaciones.
5. Sincronización en la nube.
6. Fine-tuning o entrenamiento de modelos.
7. Análisis profundo de páginas protegidas por login.

## 3. Estado actual del proyecto

El respaldo revisado contiene esta estructura:

```text
YTDLL/
├── Dependencies.ps1
├── Functions.ps1
├── GUI.ps1
├── Main.ps1
├── pwt.ps1
└── README.md
```

Puntos importantes detectados:

1. La aplicación ya usa PowerShell con GUI WPF/XAML.
2. La configuración se guarda en `C:\Temp\ytdll\config.ini`.
3. Ya existen funciones `Get-IniValue` y `Set-IniValue`.
4. Ya existe una cola de descargas persistente.
5. Ya existe integración con `yt-dlp`.
6. Ya existen funciones para consultar metadatos y formatos.
7. El botón principal actualmente alterna entre buscar video y agregar a cola.
8. Ya existe panel lateral de cola de descargas.

La implementación de IA debe reutilizar estas bases para evitar duplicar lógica.

## 4. Decisión técnica principal

Aunque la función se llama “buscador con IA”, la IA no debe ser la única responsable de encontrar videos.

La estrategia recomendada es:

1. **PowerShell + yt-dlp** detectan videos de forma técnica.
2. **Gemini** interpreta la intención del usuario, resume resultados, limpia títulos y ayuda a decidir qué enlaces parecen descargables.
3. **La cola actual de YTDLL** recibe los videos seleccionados.

Esto evita depender de que Gemini pueda abrir o navegar cualquier URL directamente. La IA funciona como asistente y clasificador, mientras que `yt-dlp` sigue siendo el motor confiable de detección/descarga.

## 5. Modelo inicial recomendado

Para la versión gratuita se usará:

```text
gemini-2.5-flash
```

Configuración inicial recomendada:

```ini
[ai]
Enabled=false
Provider=Gemini
Model=gemini-2.5-flash
ApiKey=
Temperature=0.2
MaxOutputTokens=2048
ChatEnabled=false
VideoFinderEnabled=true
```

La temperatura baja ayuda a que las respuestas sean más consistentes y menos creativas, ideal para clasificación de enlaces y generación de JSON.

## 6. Cambios propuestos en `config.ini`

Agregar una nueva sección:

```ini
[ai]
Enabled=false
Provider=Gemini
Model=gemini-2.5-flash
ApiKey=
Temperature=0.2
MaxOutputTokens=2048
ChatEnabled=false
VideoFinderEnabled=true
SaveChatHistory=false
```

Opcional para una segunda etapa:

```ini
[ai_security]
ApiKeyEncrypted=true
ApiKeyStorage=LocalUserDPAPI
```

## 7. Seguridad de la API Key

### Opción MVP

Guardar la API Key en `config.ini` como texto plano.

Ventaja:

- Fácil de implementar.

Desventaja:

- Cualquier usuario o proceso con acceso al archivo puede leer la clave.

### Opción recomendada

Guardar la API Key cifrada usando DPAPI de Windows, vinculada al usuario local.

PowerShell puede usar:

```powershell
ConvertFrom-SecureString
ConvertTo-SecureString
```

Ejemplo conceptual:

```powershell
function Protect-ApiKey {
    param([string]$ApiKey)
    $secure = ConvertTo-SecureString $ApiKey -AsPlainText -Force
    return $secure | ConvertFrom-SecureString
}

function Unprotect-ApiKey {
    param([string]$EncryptedApiKey)
    $secure = $EncryptedApiKey | ConvertTo-SecureString
    $ptr = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secure)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($ptr)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($ptr)
    }
}
```

Para el MVP, se puede iniciar con texto plano y dejar una tarea pendiente para cifrado. Si se distribuye públicamente, lo recomendable es implementar DPAPI desde el inicio.

## 8. Diseño de interfaz

### 8.1 Botón o acceso a configuración de IA

Agregar un botón nuevo en la parte superior o inferior:

```text
🤖 IA
```

Opciones posibles:

1. Botón junto a “Info” y “Cookies”.
2. Botón en la zona inferior junto a “Sitios compatibles”.
3. Nueva pestaña o panel lateral.

Recomendación para MVP:

- Agregar botón `🤖 IA` en la barra superior.
- Al hacer clic, abrir ventana modal de configuración.

### 8.2 Ventana de configuración de IA

Campos sugeridos:

| Campo | Tipo | Valor inicial |
|---|---|---|
| Activar IA | CheckBox | false |
| Proveedor | ComboBox | Gemini |
| Modelo | ComboBox/TextBox | gemini-2.5-flash |
| API Key | PasswordBox | vacío |
| Probar conexión | Button | — |
| Guardar | Button | — |
| Cancelar | Button | — |

### 8.3 Chat IA

Cuando la IA esté activa, mostrar un panel o ventana:

```text
┌─────────────────────────────────────┐
│ 🤖 Asistente IA                      │
├─────────────────────────────────────┤
│ Historial de mensajes                │
│                                     │
│ Usuario: busca videos en esta URL... │
│ IA: encontré estos posibles videos...│
├─────────────────────────────────────┤
│ [Pega un enlace o escribe aquí...]   │
│ [Enviar] [Buscar videos]             │
└─────────────────────────────────────┘
```

Recomendación:

- No mezclar el chat dentro del `txtUrl` principal.
- El chat debe tener su propio `TextBox` para entrada.
- Botón específico: `Buscar videos en enlace`.

## 9. Flujo funcional del buscador de videos

### 9.1 Flujo ideal

1. Usuario activa IA.
2. Usuario abre chat.
3. Usuario pega una URL.
4. La app detecta si el texto contiene URL.
5. La app ejecuta detección técnica con `yt-dlp`.
6. Si `yt-dlp` detecta playlist/lista, se obtiene listado plano.
7. Si `yt-dlp` detecta video único, se muestra como resultado.
8. Si `yt-dlp` falla, se intenta extracción básica de HTML.
9. La app manda a Gemini un resumen de candidatos.
10. Gemini devuelve JSON estructurado.
11. La app renderiza la lista.
12. Usuario selecciona videos.
13. Usuario presiona “Agregar seleccionados a cola”.
14. La app agrega cada URL a la cola existente.

### 9.2 Flujo cuando no se encuentran videos

1. Mostrar mensaje claro:

```text
No pude encontrar videos descargables en ese enlace.
```

2. Sugerir:

```text
Puedes intentar con el enlace directo del video, una playlist, canal o página pública compatible con yt-dlp.
```

3. Guardar el error en log si debug está activo.

## 10. Motor de detección de videos

### 10.1 Primer intento: yt-dlp con JSON plano

Para playlists o páginas con varios videos:

```powershell
yt-dlp --flat-playlist --dump-single-json "URL"
```

Ventajas:

- Rápido.
- No descarga video.
- Devuelve estructura JSON.
- Ideal para playlists/canales.

### 10.2 Segundo intento: yt-dlp video único

```powershell
yt-dlp --dump-json --no-playlist "URL"
```

Sirve para detectar si el enlace es un video individual.

### 10.3 Tercer intento: extracción HTML básica

Si `yt-dlp` no encuentra nada:

1. Descargar HTML con `Invoke-WebRequest`.
2. Buscar candidatos en:
   - `href="..."`
   - `src="..."`
   - `og:video`
   - `twitter:player`
   - enlaces a YouTube, Vimeo, Dailymotion, Twitch, TikTok, Facebook, etc.
3. Normalizar URLs relativas contra el dominio base.
4. Mandar candidatos a Gemini para clasificación.
5. Validar candidatos finales con `yt-dlp`.

## 11. Rol exacto de Gemini

Gemini no debe descargar ni validar técnicamente los videos. Su papel será:

1. Interpretar la petición del usuario.
2. Detectar si el mensaje contiene una URL.
3. Clasificar candidatos.
4. Eliminar duplicados.
5. Crear títulos amigables.
6. Devolver JSON que la app pueda procesar.
7. Explicar al usuario qué encontró.

## 12. Formato de respuesta esperado de Gemini

Para evitar errores, pedirle siempre JSON estricto:

```json
{
  "intent": "find_videos",
  "summary": "Encontré 3 posibles videos en el enlace proporcionado.",
  "videos": [
    {
      "title": "Título del video",
      "url": "https://...",
      "source": "youtube",
      "confidence": 0.95,
      "reason": "Detectado por yt-dlp como entrada de playlist"
    }
  ],
  "warnings": []
}
```

Si no encuentra nada:

```json
{
  "intent": "find_videos",
  "summary": "No se encontraron videos descargables.",
  "videos": [],
  "warnings": [
    "El enlace puede requerir inicio de sesión o no ser compatible con yt-dlp."
  ]
}
```

## 13. Prompt base recomendado

```text
Eres el asistente integrado de YTDLL, una aplicación de escritorio para Windows que usa yt-dlp para detectar y descargar videos.

Tu tarea es ayudar a clasificar enlaces de video encontrados por la aplicación.

Reglas:
- No inventes URLs.
- No inventes títulos.
- Solo usa los candidatos proporcionados por la aplicación.
- Devuelve únicamente JSON válido.
- Si no hay candidatos confiables, devuelve una lista vacía.
- La aplicación validará y descargará los videos con yt-dlp.

Formato obligatorio:
{
  "intent": "find_videos",
  "summary": "texto breve",
  "videos": [
    {
      "title": "texto",
      "url": "url",
      "source": "texto",
      "confidence": 0.0,
      "reason": "texto"
    }
  ],
  "warnings": []
}
```

## 14. Funciones nuevas sugeridas en `Functions.ps1`

### 14.1 Configuración IA

```powershell
function Get-AiConfig {
    return [pscustomobject]@{
        Enabled         = [bool]::Parse((Get-IniValue -Section "ai" -Key "Enabled" -DefaultValue "false"))
        Provider        = Get-IniValue -Section "ai" -Key "Provider" -DefaultValue "Gemini"
        Model           = Get-IniValue -Section "ai" -Key "Model" -DefaultValue "gemini-2.5-flash"
        ApiKey          = Get-IniValue -Section "ai" -Key "ApiKey" -DefaultValue ""
        Temperature     = [double](Get-IniValue -Section "ai" -Key "Temperature" -DefaultValue "0.2")
        MaxOutputTokens = [int](Get-IniValue -Section "ai" -Key "MaxOutputTokens" -DefaultValue "2048")
    }
}

function Save-AiConfig {
    param(
        [bool]$Enabled,
        [string]$Provider,
        [string]$Model,
        [string]$ApiKey,
        [double]$Temperature,
        [int]$MaxOutputTokens
    )

    Set-IniValue -Section "ai" -Key "Enabled" -Value ([string]$Enabled).ToLower()
    Set-IniValue -Section "ai" -Key "Provider" -Value $Provider
    Set-IniValue -Section "ai" -Key "Model" -Value $Model
    Set-IniValue -Section "ai" -Key "ApiKey" -Value $ApiKey
    Set-IniValue -Section "ai" -Key "Temperature" -Value ([string]$Temperature)
    Set-IniValue -Section "ai" -Key "MaxOutputTokens" -Value ([string]$MaxOutputTokens)
}
```

### 14.2 Llamada a Gemini

```powershell
function Invoke-GeminiGenerateContent {
    param(
        [Parameter(Mandatory=$true)][string]$Prompt,
        [string]$SystemInstruction = "",
        [string]$Model = "gemini-2.5-flash",
        [string]$ApiKey,
        [double]$Temperature = 0.2,
        [int]$MaxOutputTokens = 2048
    )

    if ([string]::IsNullOrWhiteSpace($ApiKey)) {
        throw "No se ha configurado la API Key de Gemini."
    }

    $uri = "https://generativelanguage.googleapis.com/v1beta/models/$Model`:generateContent"

    $body = @{
        systemInstruction = @{
            parts = @(@{ text = $SystemInstruction })
        }
        contents = @(
            @{
                role = "user"
                parts = @(@{ text = $Prompt })
            }
        )
        generationConfig = @{
            temperature = $Temperature
            maxOutputTokens = $MaxOutputTokens
            responseMimeType = "application/json"
        }
    } | ConvertTo-Json -Depth 12

    $headers = @{
        "x-goog-api-key" = $ApiKey
        "Content-Type"   = "application/json"
    }

    try {
        $response = Invoke-RestMethod -Method Post -Uri $uri -Headers $headers -Body $body -TimeoutSec 60
        return $response.candidates[0].content.parts[0].text
    } catch {
        throw "Error llamando a Gemini: $($_.Exception.Message)"
    }
}
```

### 14.3 Probar conexión IA

```powershell
function Test-AiConnection {
    $cfg = Get-AiConfig
    $prompt = "Devuelve este JSON exacto: {`"ok`":true,`"message`":`"conexion correcta`"}"

    try {
        $result = Invoke-GeminiGenerateContent `
            -Prompt $prompt `
            -SystemInstruction "Responde solo JSON válido." `
            -Model $cfg.Model `
            -ApiKey $cfg.ApiKey `
            -Temperature 0 `
            -MaxOutputTokens 128

        return [pscustomobject]@{
            Ok = $true
            Message = $result
        }
    } catch {
        return [pscustomobject]@{
            Ok = $false
            Message = $_.Exception.Message
        }
    }
}
```

## 15. Funciones nuevas para buscar videos

### 15.1 Función principal

```powershell
function Find-VideosFromUrlWithAi {
    param([Parameter(Mandatory=$true)][string]$Url)

    $technicalCandidates = @()

    # 1. Intento con playlist/listado plano
    $flat = Invoke-YtDlpFlatPlaylist -Url $Url
    if ($flat -and $flat.Count -gt 0) {
        $technicalCandidates += $flat
    }

    # 2. Intento video individual
    if ($technicalCandidates.Count -eq 0) {
        $single = Invoke-YtDlpSingleVideoInfo -Url $Url
        if ($single) { $technicalCandidates += $single }
    }

    # 3. Intento HTML/candidatos
    if ($technicalCandidates.Count -eq 0) {
        $htmlCandidates = Find-VideoLinksInHtml -Url $Url
        if ($htmlCandidates -and $htmlCandidates.Count -gt 0) {
            $technicalCandidates += $htmlCandidates
        }
    }

    # 4. Clasificación con IA
    return Invoke-AiVideoCandidateClassifier -OriginalUrl $Url -Candidates $technicalCandidates
}
```

### 15.2 Detección por yt-dlp playlist

```powershell
function Invoke-YtDlpFlatPlaylist {
    param([string]$Url)

    try {
        $yt = Get-Command yt-dlp -ErrorAction Stop
        $args = @("--flat-playlist", "--dump-single-json", "--no-warnings", $Url)
        $output = & $yt.Source @args 2>$null

        if ([string]::IsNullOrWhiteSpace($output)) { return @() }

        $json = $output | ConvertFrom-Json
        $items = @()

        if ($json.entries) {
            foreach ($entry in $json.entries) {
                if ($entry.url -or $entry.webpage_url) {
                    $videoUrl = if ($entry.webpage_url) { $entry.webpage_url } else { $entry.url }
                    $items += [pscustomobject]@{
                        Title = $entry.title
                        Url = $videoUrl
                        Source = $json.extractor
                        DetectionMethod = "yt-dlp-flat-playlist"
                    }
                }
            }
        }

        return $items
    } catch {
        Write-DebugLog "[AI_VIDEO_FINDER] Error flat playlist: $($_.Exception.Message)" "Yellow"
        return @()
    }
}
```

### 15.3 Detección de video único

```powershell
function Invoke-YtDlpSingleVideoInfo {
    param([string]$Url)

    try {
        $yt = Get-Command yt-dlp -ErrorAction Stop
        $args = @("--dump-json", "--no-playlist", "--no-warnings", $Url)
        $output = & $yt.Source @args 2>$null

        if ([string]::IsNullOrWhiteSpace($output)) { return $null }

        $json = $output | ConvertFrom-Json

        if ($json.title) {
            return [pscustomobject]@{
                Title = $json.title
                Url = if ($json.webpage_url) { $json.webpage_url } else { $Url }
                Source = $json.extractor
                DetectionMethod = "yt-dlp-single-video"
            }
        }

        return $null
    } catch {
        Write-DebugLog "[AI_VIDEO_FINDER] Error single video: $($_.Exception.Message)" "Yellow"
        return $null
    }
}
```

### 15.4 Extracción HTML básica

```powershell
function Find-VideoLinksInHtml {
    param([string]$Url)

    try {
        $res = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 30
        $html = $res.Content
        $baseUri = [Uri]$Url
        $candidates = New-Object System.Collections.ArrayList

        $patterns = @(
            'https?://[^"''\s<>]+',
            'href=["'']([^"'']+)["'']',
            'src=["'']([^"'']+)["'']',
            'property=["'']og:video["''][^>]+content=["'']([^"'']+)["'']',
            'name=["'']twitter:player["''][^>]+content=["'']([^"'']+)["'']'
        )

        foreach ($pattern in $patterns) {
            $matches = [regex]::Matches($html, $pattern, [System.Text.RegularExpressions.RegexOptions]::IgnoreCase)
            foreach ($m in $matches) {
                $candidateUrl = if ($m.Groups.Count -gt 1 -and $m.Groups[1].Value) { $m.Groups[1].Value } else { $m.Value }

                if ($candidateUrl -match '^(//)') {
                    $candidateUrl = "$($baseUri.Scheme):$candidateUrl"
                } elseif ($candidateUrl -match '^/') {
                    $candidateUrl = "$($baseUri.Scheme)://$($baseUri.Host)$candidateUrl"
                }

                if ($candidateUrl -match 'youtube|youtu\.be|vimeo|dailymotion|twitch|tiktok|facebook|instagram|\.mp4|\.m3u8') {
                    [void]$candidates.Add([pscustomobject]@{
                        Title = "Candidato detectado en HTML"
                        Url = $candidateUrl
                        Source = "html"
                        DetectionMethod = "html-regex"
                    })
                }
            }
        }

        return $candidates | Sort-Object Url -Unique
    } catch {
        Write-DebugLog "[AI_VIDEO_FINDER] Error HTML: $($_.Exception.Message)" "Yellow"
        return @()
    }
}
```

## 16. Clasificación con IA

```powershell
function Invoke-AiVideoCandidateClassifier {
    param(
        [string]$OriginalUrl,
        [array]$Candidates
    )

    $cfg = Get-AiConfig

    if (-not $cfg.Enabled) {
        throw "La IA no está activada."
    }

    if (-not $Candidates -or $Candidates.Count -eq 0) {
        return [pscustomobject]@{
            intent = "find_videos"
            summary = "No se encontraron videos descargables."
            videos = @()
            warnings = @("No hubo candidatos técnicos para clasificar.")
        }
    }

    $system = @"
Eres el asistente integrado de YTDLL. Clasifica candidatos de video encontrados por la aplicación.
No inventes URLs. No inventes títulos. Devuelve únicamente JSON válido.
"@

    $candidateJson = $Candidates | ConvertTo-Json -Depth 6

    $prompt = @"
URL original:
$OriginalUrl

Candidatos técnicos encontrados:
$candidateJson

Devuelve JSON con este formato:
{
  "intent": "find_videos",
  "summary": "texto breve",
  "videos": [
    {
      "title": "texto",
      "url": "url",
      "source": "texto",
      "confidence": 0.0,
      "reason": "texto"
    }
  ],
  "warnings": []
}
"@

    $raw = Invoke-GeminiGenerateContent `
        -Prompt $prompt `
        -SystemInstruction $system `
        -Model $cfg.Model `
        -ApiKey $cfg.ApiKey `
        -Temperature $cfg.Temperature `
        -MaxOutputTokens $cfg.MaxOutputTokens

    try {
        return $raw | ConvertFrom-Json
    } catch {
        throw "Gemini respondió, pero no devolvió JSON válido. Respuesta: $raw"
    }
}
```

## 17. Integración con la cola existente

Actualmente la app ya maneja una cola con objetos que contienen propiedades como:

- `Url`
- `Title`
- `Destination`
- `FormatSelector`
- `MergeExt`
- `Status`
- `Phase`
- `StartRequested`

La nueva función debe convertir cada video elegido en un elemento compatible con esa cola.

### Estrategia recomendada

Crear una función:

```powershell
function Add-VideoFinderResultsToQueue {
    param([array]$Videos)

    foreach ($video in $Videos) {
        # Reutilizar la lógica existente siempre que sea posible.
        # O crear un item con la misma forma que Initialize-QueueItemShape.
    }

    Save-DownloadQueue
    Refresh-QueuePanel
    Start-NextQueuedDownloads
}
```

Mejor opción:

1. Crear una función genérica nueva:

```powershell
function Add-UrlToDownloadQueue {
    param(
        [string]$Url,
        [string]$Title = "Video"
    )

    # Construir objeto compatible con Initialize-QueueItemShape
}
```

2. Modificar `Add-CurrentDownloadToQueue` para que también use `Add-UrlToDownloadQueue`.
3. Así se evita duplicar lógica entre el botón normal y la IA.

## 18. Nuevos elementos visuales para resultados

Después de buscar videos, mostrar una lista como esta:

```text
Videos encontrados
[✓] Video 1 - https://...
[✓] Video 2 - https://...
[ ] Video 3 - https://...

[Agregar seleccionados a cola]
```

Cada elemento debe tener:

1. CheckBox.
2. Título.
3. URL abreviada.
4. Fuente.
5. Confianza.
6. Botón “Probar”.
7. Botón “Copiar URL”.

## 19. Validaciones importantes

Antes de agregar a la cola:

1. URL no vacía.
2. URL con formato válido.
3. No duplicar si ya existe en la cola.
4. Si es playlist, preguntar si se agregarán todos los videos.
5. Si la URL requiere cookies, mostrar advertencia.
6. Si no hay API Key, bloquear chat IA y abrir configuración.
7. Si se supera límite de API, mostrar error claro.

## 20. Manejo de errores

### Sin API Key

```text
La IA está activada, pero no se ha configurado una API Key de Gemini.
```

### API Key inválida

```text
No se pudo conectar con Gemini. Revisa que la API Key sea correcta.
```

### Cuota agotada

```text
Gemini rechazó la solicitud por límite de uso. Intenta más tarde o cambia de modelo/proveedor.
```

### URL sin videos

```text
No encontré videos descargables en ese enlace.
```

### JSON inválido desde IA

```text
La IA respondió en un formato no válido. Se usarán solo los resultados técnicos detectados por yt-dlp.
```

## 21. Logs recomendados

Crear archivo:

```text
C:\Temp\ytdll\logs\ai.log
```

Registrar:

1. Fecha/hora.
2. Modelo usado.
3. URL consultada.
4. Cantidad de candidatos técnicos.
5. Cantidad de videos aceptados por IA.
6. Errores de API.
7. Errores de JSON.
8. Tiempo de respuesta.

No registrar la API Key.

## 22. Dependencias nuevas

No se requiere instalar SDK de Google para el MVP.

Se puede usar REST directamente con:

```powershell
Invoke-RestMethod
```

Esto evita agregar más dependencias al instalador.

## 23. Cambios sugeridos por archivo

### `Main.ps1`

1. Cargar variables globales de IA después de cargar configuración.
2. Inicializar feature flag:

```powershell
$script:AiEnabled = [bool]::Parse((Get-IniValue -Section "ai" -Key "Enabled" -DefaultValue "false"))
```

### `Functions.ps1`

Agregar:

1. `Get-AiConfig`
2. `Save-AiConfig`
3. `Invoke-GeminiGenerateContent`
4. `Test-AiConnection`
5. `Show-AiSettingsDialog`
6. `Show-AiChatWindow`
7. `Find-VideosFromUrlWithAi`
8. `Invoke-YtDlpFlatPlaylist`
9. `Invoke-YtDlpSingleVideoInfo`
10. `Find-VideoLinksInHtml`
11. `Invoke-AiVideoCandidateClassifier`
12. `Add-VideoFinderResultsToQueue`
13. `Write-AiLog`

### `GUI.ps1`

Agregar:

1. Botón `btnAi`.
2. Evento click para abrir configuración/chat.
3. Referencias con `FindName`.
4. Opcional: indicador visual de IA activa.

### `README.md`

Agregar sección:

```markdown
## IA con Gemini

YTDLL permite activar un asistente IA usando Gemini Flash para ayudar a buscar videos dentro de enlaces y agregarlos a la cola de descargas.
```

## 24. Fases de implementación

### Fase 1: Configuración IA

Objetivo: permitir activar IA y guardar proveedor/modelo/API Key.

Tareas:

1. Crear sección `[ai]` en `config.ini`.
2. Crear `Get-AiConfig`.
3. Crear `Save-AiConfig`.
4. Crear ventana `Show-AiSettingsDialog`.
5. Agregar botón `🤖 IA`.
6. Validar guardado y lectura.

Criterio de aceptación:

- El usuario puede activar IA, escribir API Key, seleccionar modelo y guardar.

### Fase 2: Prueba de conexión Gemini

Objetivo: validar que la API Key funciona.

Tareas:

1. Crear `Invoke-GeminiGenerateContent`.
2. Crear `Test-AiConnection`.
3. Agregar botón “Probar conexión”.
4. Mostrar resultado en MessageBox.

Criterio de aceptación:

- Al presionar “Probar conexión”, la app confirma si Gemini responde correctamente.

### Fase 3: Chat IA básico

Objetivo: permitir conversación sencilla.

Tareas:

1. Crear ventana `Show-AiChatWindow`.
2. Agregar historial visual.
3. Agregar entrada de texto.
4. Agregar botón “Enviar”.
5. Llamar a Gemini y mostrar respuesta.

Criterio de aceptación:

- El usuario puede escribir un mensaje y recibir respuesta de Gemini.

### Fase 4: Buscador de videos

Objetivo: detectar videos desde una URL.

Tareas:

1. Crear `Find-VideosFromUrlWithAi`.
2. Crear detección `yt-dlp --flat-playlist`.
3. Crear detección `yt-dlp --dump-json`.
4. Crear extracción HTML básica.
5. Crear clasificador con Gemini.

Criterio de aceptación:

- Al pegar una URL, la app muestra una lista de videos detectados.

### Fase 5: Agregar a cola

Objetivo: pasar resultados seleccionados a la cola existente.

Tareas:

1. Crear función genérica `Add-UrlToDownloadQueue`.
2. Reutilizar estructura de cola existente.
3. Agregar botón “Agregar seleccionados a cola”.
4. Evitar duplicados.
5. Refrescar panel de cola.

Criterio de aceptación:

- El usuario puede seleccionar videos encontrados y agregarlos a la cola.

### Fase 6: Pulido y errores

Objetivo: mejorar UX y robustez.

Tareas:

1. Mensajes claros de error.
2. Logs IA.
3. Manejo de cuota agotada.
4. Manejo de API Key inválida.
5. Fallback si Gemini responde mal.
6. Indicador de carga.

Criterio de aceptación:

- La app no se bloquea ante errores de red, IA o enlaces inválidos.

## 25. Casos de prueba

### Configuración

| Caso | Resultado esperado |
|---|---|
| Activar IA sin API Key | Mostrar advertencia |
| Guardar API Key | Persistir en config.ini |
| Cambiar modelo | Guardar modelo nuevo |
| Probar API Key válida | Mostrar conexión correcta |
| Probar API Key inválida | Mostrar error claro |

### Buscador

| Caso | Resultado esperado |
|---|---|
| URL de video único YouTube | Mostrar 1 resultado |
| URL de playlist YouTube | Mostrar varios resultados |
| URL de canal compatible | Mostrar videos detectados si yt-dlp soporta la página |
| URL sin videos | Mostrar “no encontrados” |
| URL con login requerido | Mostrar advertencia de cookies/login |
| Página con enlaces embebidos | Intentar extracción HTML |

### Cola

| Caso | Resultado esperado |
|---|---|
| Agregar 1 video | Aparece en cola |
| Agregar varios videos | Aparecen en cola |
| Agregar video duplicado | Se evita duplicado o se avisa |
| AutoDownload activo | Inicia según configuración de cola |
| AutoDownload apagado | Queda en espera |

## 26. Recomendaciones de UX

1. No llamar “Descargar con IA”; llamar “Buscar videos con IA”.
2. Mostrar siempre los videos antes de agregarlos.
3. No descargar nada sin confirmación.
4. Mostrar fuente de detección.
5. Mostrar si el resultado vino de `yt-dlp`, HTML o IA.
6. Usar estados:
   - Buscando...
   - Analizando con IA...
   - Validando resultados...
   - Listo.

## 27. Riesgos técnicos

| Riesgo | Mitigación |
|---|---|
| Gemini no puede abrir URLs directamente | Usar yt-dlp/HTML como fuente técnica |
| API Key expuesta | Cifrar con DPAPI |
| Respuesta IA no es JSON | Usar `responseMimeType=application/json` y fallback |
| Cuota gratuita limitada | Mostrar error claro y evitar llamadas innecesarias |
| Páginas protegidas | Usar cookies cuando aplique |
| Videos duplicados | Normalizar URLs y comparar cola actual |
| UI congelada | Ejecutar llamadas largas fuera del hilo principal |

## 28. Punto importante sobre rendimiento

Las llamadas a:

1. Gemini.
2. `yt-dlp`.
3. `Invoke-WebRequest`.

no deben ejecutarse bloqueando la interfaz. Para evitar que la ventana se congele, usar:

- Runspaces.
- Jobs.
- Dispatcher para actualizar UI.
- Patrón similar al usado para descargas en cola.

## 29. Propuesta de nombres internos

| Elemento | Nombre sugerido |
|---|---|
| Botón IA | `btnAi` |
| Ventana config | `Show-AiSettingsDialog` |
| Ventana chat | `Show-AiChatWindow` |
| TextBox chat | `txtAiInput` |
| Panel historial | `spAiMessages` |
| Botón buscar videos | `btnAiFindVideos` |
| Lista resultados | `lstAiVideoResults` |
| Botón agregar cola | `btnAddAiVideosToQueue` |

## 30. Ejemplo de experiencia final

1. Usuario abre YTDLL.
2. Presiona `🤖 IA`.
3. Activa IA.
4. Selecciona `Gemini`.
5. Modelo: `gemini-2.5-flash`.
6. Escribe API Key.
7. Presiona “Probar conexión”.
8. Guarda.
9. Abre chat IA.
10. Escribe:

```text
Busca videos en este enlace: https://example.com/pagina-con-videos
```

11. La app responde:

```text
Encontré 4 posibles videos. Selecciona cuáles quieres agregar a la cola.
```

12. Usuario marca 2 videos.
13. Presiona “Agregar seleccionados a cola”.
14. La cola lateral muestra los 2 videos listos para descargar.

## 31. Orden recomendado para programar

1. Crear configuración `[ai]`.
2. Crear botón `🤖 IA`.
3. Crear ventana de configuración.
4. Crear llamada REST a Gemini.
5. Crear botón “Probar conexión”.
6. Crear ventana de chat.
7. Crear detección técnica con `yt-dlp`.
8. Crear clasificación con Gemini.
9. Crear visualización de resultados.
10. Integrar resultados con cola.
11. Agregar logs.
12. Probar casos reales.
13. Cifrar API Key.
14. Documentar en README.

## 32. Dudas o decisiones pendientes

1. ¿El chat debe abrirse como ventana independiente o como panel lateral dentro de la ventana principal?
2. ¿La API Key se guardará en texto plano para el MVP o se implementará cifrado desde el inicio?
3. ¿La IA debe estar disponible solo para buscar videos o también para explicar errores de descarga?
4. ¿Los videos encontrados se deben agregar en espera o iniciar automáticamente si `AutoDownload` está activo?
5. ¿Se permitirá que el usuario escriba manualmente modelos distintos a los del ComboBox?

## 33. Recomendación final

Implementar primero la configuración y la prueba de conexión. Después agregar el chat básico. Finalmente integrar el buscador de videos usando `yt-dlp` como motor principal y Gemini como asistente de clasificación.

La clave para que esta función sea estable es no depender de que la IA “adivine” videos. La app debe detectar candidatos reales y usar Gemini para organizarlos, explicarlos y presentarlos mejor al usuario.
