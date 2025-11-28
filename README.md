🎬 YTDLL - Descargador de Videos y Audio
https://img.shields.io/badge/PowerShell-5.1+-blue.svg
https://img.shields.io/badge/Platform-Windows-lightgrey.svg
https://img.shields.io/badge/Version-beta%2520251121.1825-green.svg

📖 Índice / Table of Contents
Descripción General

Características

Requisitos del Sistema

Instalación

Uso

Estructura del Proyecto

Capturas de Pantalla

Sitios Compatibles

Solución de Problemas

Contribuciones

Licencia

🌎 Descripción General
YTDLL es una aplicación gráfica moderna desarrollada en PowerShell que proporciona una interfaz amigable para yt-dlp, permitiendo descargar videos y audio de más de 1000 sitios web compatibles.

English Description
YTDLL is a modern graphical application developed in PowerShell that provides a user-friendly interface for yt-dlp, enabling video and audio downloads from over 1000 supported websites.

✨ Características / Features
🔥 Características Principales
🖼️ Vista previa en tiempo real de videos antes de descargar

🎯 Selección inteligente de formatos de video y audio

📁 Gestor de destino con interfaz gráfica

🔄 Actualización automática de dependencias via Chocolatey

📊 Progreso en tiempo real en la consola

🍪 Soporte para cookies (para contenido restringido)

📜 Historial de descargas persistente

🎮 Reproducción rápida con mpv.net integrado

🌐 Compatibilidad Multiplataforma
YouTube, Twitch, Twitter, TikTok, Instagram

Vimeo, Dailymotion, Facebook, Reddit

Y 1000+ sitios más soportados por yt-dlp

English Features
🖼️ Real-time preview of videos before downloading

🎯 Smart selection of video and audio formats

📁 Destination manager with graphical interface

🔄 Automatic dependency updates via Chocolatey

📊 Real-time progress in console

🍪 Cookies support (for restricted content)

📜 Persistent download history

🎮 Quick playback with integrated mpv.net

⚙️ Requisitos del Sistema / System Requirements
Requisitos Mínimos
Windows 10 o superior

PowerShell 5.1+ o PowerShell 7+

Conexión a Internet para descargas

4GB RAM recomendados

Dependencias Automáticas
El script gestiona automáticamente:

yt-dlp - Motor principal de descargas

FFmpeg - Procesamiento de medios

Node.js (LTS) - Para funcionalidades adicionales

mpv.net - Reproductor de video (opcional)

Chocolatey - Gestor de paquetes

English System Requirements
Windows 10 or later

PowerShell 5.1+ or PowerShell 7+

Internet connection for downloads

4GB RAM recommended

🚀 Instalación / Installation
Método Rápido (Recomendado)
powershell
# Ejecutar en PowerShell como administrador
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/tu-usuario/PWytdll/main/ytdll.ps1'))
Instalación Manual
Clona el repositorio:

powershell
git clone https://github.com/water0ff/PWytdll.git
cd PWytdll
Ejecuta el script:

powershell
.\ytdll.ps1
English Installation
powershell
# Run in PowerShell as administrator
Set-ExecutionPolicy Bypass -Scope Process -Force
iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/your-username/PWytdll/main/ytdll.ps1'))
🎮 Uso / Usage
Interfaz Gráfica
Pega la URL del video en el campo superior

Haz clic en "Buscar Video" para previsualizar

Selecciona formatos de video y audio

Elige carpeta destino con el botón 📁

Haz clic en "Descargar Video"

Características Avanzadas
🔄 Botón de información (?) - Estado del sistema y dependencias

📊 Vista previa - Haz clic en la miniatura para reproducir

🎛️ Selector de formatos - Control total sobre calidad

📜 Historial - Menú desplegable con URLs anteriores

🌐 Sitios compatibles - Lista completa de plataformas soportadas

English Usage
Paste video URL in the top field

Click "Search Video" to preview

Select video and audio formats

Choose destination folder with 📁 button

Click "Download Video"

📁 Estructura del Proyecto / Project Structure
text
PWytdll/
├── ytdll.ps1                 # Script principal / Main script
├── README.md                 # Este archivo / This file
└── assets/                   # Recursos (si existen) / Resources (if any)
    ├── screenshots/          # Capturas de pantalla / Screenshots
    └── icons/                # Iconos de la aplicación / App icons
Archivos de Configuración
C:\Temp\ytdll\config.ini - Configuración de la aplicación

C:\Temp\ytdll\ytdll_history.txt - Historial de descargas

C:\Temp\ytdll\miniaturas\ - Miniaturas en caché

🖼️ Capturas de Pantalla / Screenshots
(Incluir capturas de pantalla de la interfaz aquí)

Interfaz Principal / Main Interface
https://assets/screenshots/main-interface.png

Selector de Formatos / Format Selector
https://assets/screenshots/format-selector.png

Información del Sistema / System Info
https://assets/screenshots/system-info.png

🌐 Sitios Compatibles / Supported Sites
Plataformas Principales
✅ YouTube (videos, shorts, playlists)

✅ Twitch (VODs, clips)

✅ Twitter/X (videos)

✅ TikTok (sin marca de agua)

✅ Instagram (publicaciones, stories)

✅ Facebook (videos)

✅ Reddit (videos)

✅ Vimeo, Dailymotion

✅ Y muchos más...

Ver Lista Completa
Haz clic en "Sitios compatibles" en la aplicación para ver los 1000+ extractores disponibles.

English Supported Sites
✅ YouTube (videos, shorts, playlists)

✅ Twitch (VODs, clips)

✅ Twitter/X (videos)

✅ TikTok (watermark-free)

✅ Instagram (posts, stories)

✅ Facebook (videos)

✅ Reddit (videos)

✅ Vimeo, Dailymotion

✅ And many more...

🔧 Solución de Problemas / Troubleshooting
Problemas Comunes / Common Issues
❌ "yt-dlp no encontrado"
Solución: La aplicación instalará automáticamente yt-dlp. Si falla:

powershell
choco install yt-dlp -y
❌ Error de permisos
Solución: Ejecutar PowerShell como administrador

❌ Vista previa no carga
Solución: Verificar que mpv.net esté instalado desde la sección de dependencias

❌ Descarga lenta
Solución:

Verificar conexión a Internet

Intentar con otro formato

Usar cookies para contenido restringido

English Troubleshooting
❌ "yt-dlp not found"
Solution: The app will auto-install yt-dlp. If it fails:

powershell
choco install yt-dlp -y
❌ Permission errors
Solution: Run PowerShell as administrator

❌ Preview not loading
Solution: Check mpv.net installation in dependencies section

❌ Slow downloads
Solution:

Check internet connection

Try different format

Use cookies for restricted content

🤝 Contribuciones / Contributions
¡Las contribuciones son bienvenidas! / Contributions are welcome!

Cómo Contribuir / How to Contribute
Haz fork del proyecto / Fork the project

Crea una rama feature / Create a feature branch

Realiza tus cambios / Commit your changes

Abre un Pull Request / Open a Pull Request

Reportar Problemas / Report Issues
Si encuentras un error, por favor abre un issue en GitHub con:

Descripción detallada del problema

Pasos para reproducir

Capturas de pantalla (si aplica)

Versión del script y sistema operativo

📄 Licencia / License
Este proyecto está bajo la Licencia MIT. Ver el archivo LICENSE para más detalles.

🔗 Enlaces Rápidos / Quick Links
📥 Descargar última versión

🐛 Reportar un problema

💡 Solicitar característica

📖 Documentación de yt-dlp

<div align="center">
¿Te gusta este proyecto? ¡Dale una ⭐ en GitHub!
Like this project? Give it a ⭐ on GitHub!

⬆ Volver al inicio / Back to top

</div>
