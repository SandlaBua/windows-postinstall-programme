# Windows Postinstall Programme

Automatisiertes PowerShell-Tool zum Installieren von Programmen über eine GUI nach einer frischen Windows-Installation.

---

## 🚀 Start

Einfach in **PowerShell (64-Bit, als Administrator)** ausführen:

```powershell
irm https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/launcher.ps1 | iex
```

---

## ⚠️ Voraussetzungen

* Windows 10 / 11
* Internetverbindung
* **64-Bit PowerShell (kein x86!)**
* Administratorrechte

Das Script:

* installiert automatisch **winget**, falls es fehlt
* zeigt Fehler als **GUI**
* gibt am Ende eine **Zusammenfassung aller fehlgeschlagenen Installationen**

---

## 🧠 Features

* GUI zur Auswahl von Programmkategorien
* Automatische Installation via `winget`
* Fallback-Mechanismen für frische Systeme
* Fehlerhandling mit GUI
* Übersicht am Ende:

  * fehlgeschlagene Profile
  * fehlgeschlagene Programme

---

## 📦 Kategorien

### 🌐 Browser & Kommunikation

* Brave
* Google Chrome
* Spotify
* Discord
* WhatsApp

---

### 🎮 Gaming & Launcher

* Steam
* EA App
* Epic Games Launcher
* Ubisoft Connect
* CurseForge
* Google Play Games
* Rockstar Games Launcher
* Medal
* Vencord

---

### 🖥️ Hardware & Tools

* Logitech G HUB
* Logi Options+
* PreSonus Universal Control
* EdgeTX Companion
* HWiNFO

---

### 🌐 Remote & Netzwerk

* Moonlight
* Sunshine
* Parsec
* Tailscale

---

### 🧰 Media & Utilities

* 7-Zip
* Winaero Tweaker
* MakeMKV
* HandBrake
* balenaEtcher
* WinSCP
* AnyBurn
* Raspberry Pi Imager
* Rufus

---

### 🖨️ 3D & Printing

* Creality Scan
* Bambu Studio

---

## ❌ Nicht automatisch installiert

Diese Programme sind aktuell **nicht stabil über winget automatisierbar** oder absichtlich ausgeschlossen:

* Autodesk Fusion 360
* VMware Workstation
* 8BitDo Software
* Easy Smart Configuration Utility
* deej

---

### ❌ winget fehlt

Das Script installiert es automatisch.
Falls es danach noch nicht geht:

* PowerShell neu starten
* Script erneut ausführen

---

### ❌ Falsche PowerShell

Wenn du **Windows PowerShell (x86)** nutzt:

👉 wird blockiert (absichtlich)

---

## 📁 Struktur

```
windows-postinstall-programme/
│
├─ launcher.ps1
├─ lib/
│  └─ common.ps1
└─ profiles/
   ├─ browser-communication.ps1
   ├─ gaming.ps1
   ├─ hardware-tools.ps1
   ├─ remote-network.ps1
   ├─ media-utility.ps1
   └─ printing-3d.ps1
```

---

## 💡 Hinweis

Dieses Tool ist gedacht für:

* frische Windows Installationen
* schnelles Setup von Arbeitsumgebungen
* homelab / gaming setups

---

## 🧠 Empfehlung

Nicht alles blind installieren –
wähle nur das, was du wirklich brauchst.

---

## 🛠️ ToDo (optional)

* Logfile export
* Dark Mode GUI 😄

---

## 👤 Author

Benedikt Sandler
