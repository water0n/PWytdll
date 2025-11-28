🎬 YTDLL – Video & Audio Downloader

Un poderoso GUI para yt-dlp hecho en PowerShell

<p align="center"> <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg"> <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg"> <img src="https://img.shields.io/badge/Version-beta%20251121.1825-green.svg"> </p>
📖 Índice / Table of Contents

🌎 Descripción General

✨ Características / Features

⚙️ Requisitos del Sistema

🚀 Instalación

🎮 Uso

📁 Estructura del Proyecto

🖼️ Capturas de Pantalla

🌐 Sitios Compatibles

🔧 Solución de Problemas

🤝 Contribuciones

📄 Licencia

🌎 Descripción General / Overview

ES: YTDLL es una aplicación gráfica moderna desarrollada en PowerShell. Combina simplicidad con potencia ofreciendo una GUI limpia e intuitiva para yt-dlp, permitiendo descargar videos y audio desde más de 1000 sitios compatibles.

EN: YTDLL is a modern graphical application built in PowerShell. It provides a clean, intuitive user interface for yt-dlp, enabling seamless video and audio downloads from 1000+ supported websites.

✨ Características / Features
🔥 Principales

🖼️ Vista previa en tiempo real

🎯 Selección inteligente de formato (video/audio)

📁 Gestor de destino con explorador gráfico

🔄 Auto-instalación/actualización de dependencias (Chocolatey)

📊 Progreso en tiempo real (parsing avanzado de yt-dlp)

🍪 Soporte de cookies para contenido restringido

📜 Historial persistente de URLs

🎮 Reproducción rápida con mpv.net

⚡ GUI moderna (borderless, esquinas redondeadas, tooltips, hover-effects)

🧠 Funciones Avanzadas

Detección automática de dependencias: yt-dlp, ffmpeg, mpv.net, Node.js

Clasificación inteligente de formatos: audio-only, video-only, progressive

Miniaturas obtenidas desde múltiples fuentes

Cache local de imágenes y metadatos

Sistemas de fallback cuando un método falla

Modo debug y logs detallados

Reintentos automáticos de descarga

Limpieza automática de archivos temporales

⚙️ Requisitos del Sistema / System Requirements
Requisitos mínimos

Windows 10 o superior

PowerShell 5.1+ o PowerShell 7+

Conexión a Internet

4GB RAM (recomendado)

Dependencias gestionadas automáticamente

yt-dlp

FFmpeg

Node.js (LTS)

mpv.net (opcional pero recomendado)

Chocolatey

🚀 Instalación / Installation
⭐ Método Rápido (Recomendado)

Ejecuta en PowerShell como administrador:

Set-ExecutionPolicy Bypass -Scope Process -Force
irm bit.ly/ytdll | iex

📦 Instalación Manual
git clone https://github.com/water0ff/PWytdll.git
cd PWytdll
.\ytdll.ps1

🎮 Uso / Usage
Interfaz Gráfica

Pega la URL del video

Presiona Buscar Video

Selecciona el formato de video y audio

Elige carpeta destino

Haz clic en Descargar

Características Avanzadas

❓ Botón “Info”: estado de dependencias

🖼️ Click en miniatura → abre vista previa en mpv

🎛️ Selector inteligente de formatos

📜 Historial desplegable

🍪 Carga de cookies para contenido bloqueado

📁 Estructura del Proyecto / Project Structure
PWytdll/
├── ytdll.ps1                 # Main script
├── README.md                 # Documentation
└── assets/
    ├── screenshots/          # Screenshots
    └── icons/                # Icons used by the app


Archivos de configuración

C:\Temp\ytdll\config.ini

C:\Temp\ytdll\ytdll_history.txt

C:\Temp\ytdll\miniaturas\

🖼️ Capturas de Pantalla / Screenshots

⬇️ Añade tus capturas aquí (secciones sugeridas)

🪟 Interfaz Principal / Main UI

(coloca la imagen aquí)

🎚️ Selector de Formatos

(coloca la imagen aquí)

🧩 Información del Sistema

(coloca la imagen aquí)

🌐 Sitios Compatibles / Supported Sites
Plataformas Principales

YouTube (videos, shorts, playlists)

Twitch (VODs, clips)

Twitter / X

TikTok

Instagram

Facebook

Reddit

Vimeo, Dailymotion

+1000 sitios más vía yt-dlp

Dentro de la aplicación puedes ver la lista completa actualizada.

🔧 Solución de Problemas / Troubleshooting
Problemas Comunes
❌ “yt-dlp no encontrado”

Solución automática incluida.
Manual:

choco install yt-dlp -y

❌ Errores de permisos

Ejecuta PowerShell como administrador.

❌ Vista previa no carga

Revisa instalación de mpv.net.

❌ Descargas lentas

Verifica tu red

Elige otro formato

Usa cookies para contenido privado

🤝 Contribuciones / Contributions

Las contribuciones son bienvenidas.

Pasos

Fork

Nueva rama feature/nombre

Commit

Pull Request

Reportar Problemas

Incluye:

Descripción del error

Pasos para reproducir

Capturas

Versión del sistema y script

📄 Licencia / License

Este proyecto está bajo licencia MIT.
Consulta el archivo LICENSE.

<div align="center">
⭐ ¿Te gusta este proyecto?

¡Considera dejar una estrella en GitHub!

⬆ Volver al inicio

</div>
