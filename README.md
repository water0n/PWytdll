# 🎬 YTDLL – Video & Audio Downloader
Un poderoso GUI para yt-dlp hecho en PowerShell

<p align="center">
  <img src="https://img.shields.io/badge/PowerShell-5.1+-blue.svg">
  <img src="https://img.shields.io/badge/Platform-Windows-lightgrey.svg">
  <img src="https://img.shields.io/badge/Version-beta%20251121.1825-green.svg">
</p>

---

# 📖 Índice / Table of Contents
- [🌎 Descripción General](#-descripción-general--overview)
- [✨ Características](#-características--features)
  - [🔥 Principales](#-principales)
  - [🧠 Avanzadas](#-funciones-avanzadas)
- [⚙️ Requisitos](#️-requisitos-del-sistema--system-requirements)
- [🚀 Instalación](#-instalación--installation)
- [🎮 Uso](#-uso--usage)
- [📁 Estructura del Proyecto](#-estructura-del-proyecto--project-structure)
- [🖼️ Capturas de Pantalla](#️-capturas-de-pantalla--screenshots)
- [🌐 Sitios Compatibles](#-sitios-compatibles--supported-sites)
- [📄 Licencia](#-licencia--license)

---

## 🌎 Descripción General / Overview
**ES:**  
YTDLL es una aplicación gráfica moderna desarrollada en PowerShell. Combina simplicidad con potencia ofreciendo una GUI limpia e intuitiva para yt-dlp, permitiendo descargar videos y audio desde más de 1000 sitios compatibles.

**EN:**  
YTDLL is a modern GUI built in PowerShell. It provides a clean and intuitive interface for yt-dlp, enabling seamless video/audio downloads from 1000+ supported sites.

---

## ✨ Características / Features

### 🔥 Principales
- 🖼️ Vista previa en tiempo real  
- 🎯 Selección inteligente de formato (video/audio)  
- 📁 Explorador gráfico para carpeta destino  
- 🔄 Auto-instalación/actualización de dependencias (Chocolatey)  
- 📊 Progreso en tiempo real con parser avanzado  
- 🍪 Soporte de cookies  
- 📜 Historial persistente de URLs  
- 🎮 Reproducción rápida con mpv.net  
- ⚡ GUI moderna (borderless, esquinas redondeadas)

### 🧠 Funciones Avanzadas
- Detección automática de dependencias  
- Clasificación inteligente de formatos (audio-only, video-only, progressive)  
- Miniaturas desde múltiples fuentes  
- Cache local de imágenes/metadatos  
- Fallbacks inteligentes  
- Modo debug + logs detallados  
- Reintentos automáticos  
- Limpieza de temporales  

---

## ⚙️ Requisitos del Sistema / System Requirements
- Windows 10 o superior  
- PowerShell 5.1+ o PowerShell 7+  
- Internet  
- 4GB RAM recomendado  

**Dependencias manejadas automáticamente:**

- yt-dlp  
- FFmpeg  
- Node.js (LTS)  
- mpv.net (opcional)  
- Chocolatey  

---

## 🚀 Instalación / Installation

### ⭐ Método Rápido (Recomendado)
Ejecuta en PowerShell (Admin):

irm bit.ly/ytdll | iex

🎮 Uso / Usage
Interfaz Gráfica

Pega la URL del video

Presiona Buscar Video

Selecciona formato de video/audio

Elige carpeta destino

Clic en Descargar

Funciones Avanzadas

❓ Botón “Info”: estado de dependencias

🖼️ Click en miniatura → abre mpv

🎛️ Selector inteligente de formatos

📜 Historial desplegable

🍪 Soporte para cookies

## 📁 Estructura del Proyecto / Project Structure
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

## 🖼️ Capturas de Pantalla / Screenshots
🪟 Interfaz Principal

![Interfaz Principal](Screenshots/principal.png)

🎚️ Selector de Formatos

![Selector de Formatos](Screenshots/formatos.png)

🧩 Información del Sistema

![Información del Sistema](Screenshots/appinfo.png)

## 🌐 Sitios Compatibles / Supported Sites
Plataformas Principales

YouTube (videos, shorts, playlists)
Twitch (VODs, clips)
Twitter / X
TikTok
Instagram
Facebook
Reddit
Vimeo
Dailymotion

➡️ Más de 1000 sitios vía yt-dlp.

## 📄 Licencia / License

Este proyecto está bajo licencia MIT.
Consulta el archivo LICENSE.

<div align="center">

⭐ ¿Te gusta este proyecto? Considera dejar una estrella en GitHub.
⬆ Volver al inicio

</div> ```
Set-ExecutionPolicy Bypass -Scope Process -Force
irm bit.ly/ytdll | iex
