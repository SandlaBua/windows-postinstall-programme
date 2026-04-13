# windows-postinstall-programme

PowerShell-Tool für die Programminstallation nach einer frischen Windows-Installation.

Die Auswahl erfolgt über eine GUI im Dark Mode.
Programme sind in Kategorien aufgeteilt und können entweder **einzeln** oder **komplett pro Spalte** ausgewählt werden.

---

## Features

* Dark-Mode GUI
* Programme nach Kategorien in Spalten sortiert
* Einzelne Programme auswählbar
* "Alles auswählen" pro Spalte
* Automatische Installation per `winget`
* Prüft, ob `winget` vorhanden ist
* Installiert `winget` bei Bedarf automatisch
* Fehler werden per GUI angezeigt
* Abschluss-Zusammenfassung mit fehlgeschlagenen Paketen

---

## Struktur

```text
windows-postinstall-programme/
│
├─ launcher.ps1
├─ launcher.vbs
│
├─ lib/
│  └─ common.ps1
│
└─ config/
   └─ packages.ps1
```

---

## Dateien

### `launcher.ps1`

Das Hauptscript.

Aufgaben:

* GUI anzeigen
* Programme aus `config/packages.ps1` laden
* Auswahl verarbeiten
* Installation starten
* Abschluss-Zusammenfassung anzeigen

---

### `lib/common.ps1`

Gemeinsame Funktionen.

Enthält u. a.:

* GUI-Meldungen
* `winget`-Prüfung
* automatische `winget`-Installation
* Download per `Start-BitsTransfer` mit Fallback auf `curl.exe`
* Paketinstallation mit `Scope`, `PreKill` und Fehlerbehandlung

---

### `config/packages.ps1`

Zentrale Paketliste.

Hier sind alle Programme nach Kategorien definiert, z. B.:

* Name
* Winget-ID
* Scope (`machine` / `user`)
* Prozesse, die vor der Installation beendet werden sollen

---

### `launcher.vbs`

Optionaler Starter, damit **keine PowerShell-Konsole sichtbar** ist.

Wenn du die Konsole nicht sehen willst, starte **nicht direkt `launcher.ps1`**, sondern `launcher.vbs`.

---

## Start

### Variante 1: Direkt über PowerShell

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/launcher.ps1 | iex
```

### Variante 2: Ohne sichtbare Shell

Über `launcher.vbs`

---

## Voraussetzungen

* Windows 10 oder Windows 11
* Internetverbindung
* 64-Bit PowerShell
* Administratorrechte

---

## Hinweis zu 32-Bit PowerShell

Die 32-Bit Version von Windows PowerShell (`x86`) wird absichtlich blockiert.

Wenn das Script in `Windows PowerShell (x86)` gestartet wird, erscheint eine Fehlermeldung.

Verwende die normale 64-Bit PowerShell.

---

## Kategorien

Aktuell sind die Programme in diese Kategorien aufgeteilt:

* Browser & Kommunikation
* Gaming & Launcher
* Hardware Tools
* Remote & Netzwerk
* Media & Utility
* 3D & Printing

Die eigentlichen Programme stehen in `config/packages.ps1`.

---

## Anpassungen

Wenn du Programme hinzufügen, entfernen oder verschieben willst, musst du nur `config/packages.ps1` ändern.

Die GUI baut sich daraus automatisch neu auf.

Du musst also nicht jedes Mal den Launcher selbst umbauen.

---

## Bekannte Hinweise

### TLS / SSL Fehler

Falls beim Start über `irm` ein TLS- oder SSL-Fehler kommt, nutze:

```powershell
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
```

Direkt vor dem `irm`-Befehl.

---

### `winget` fehlt

Wenn `winget` auf einem frischen Windows nicht vorhanden ist, versucht `common.ps1`, es automatisch zu installieren.

Falls `winget` danach noch nicht verfügbar ist:

* PowerShell schließen
* neu als Administrator öffnen
* Launcher erneut starten

---

### Keine Konsole sichtbar

Das geht nicht sauber, wenn du den Launcher direkt per `irm ... | iex` startest.

Wenn du **gar keine Shell sehen willst**, nutze `launcher.vbs`.

---

## Ziel des Projekts

Das Projekt ist dafür gedacht, nach einer Windows-Neuinstallation schnell die wichtigsten Programme einzurichten, ohne alles manuell zusammensuchen und installieren zu müssen.

---

## Author

Benedikt Sandler
