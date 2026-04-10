$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms | Out-Null

function Show-GuiMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [string]$Title = 'Windows Postinstall',

        [ValidateSet('Info', 'Warning', 'Error')]
        [string]$Type = 'Info'
    )

    $icon = switch ($Type) {
        'Info'    { [System.Windows.Forms.MessageBoxIcon]::Information }
        'Warning' { [System.Windows.Forms.MessageBoxIcon]::Warning }
        'Error'   { [System.Windows.Forms.MessageBoxIcon]::Error }
    }

    [System.Windows.Forms.MessageBox]::Show(
        $Message,
        $Title,
        [System.Windows.Forms.MessageBoxButtons]::OK,
        $icon
    ) | Out-Null
}

function Test-Is64BitProcess {
    return [Environment]::Is64BitProcess
}

function Get-WingetCommand {
    return Get-Command winget -ErrorAction SilentlyContinue
}

function Test-AppInstallerPackage {
    try {
        $pkg = Get-AppxPackage Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue
        return ($null -ne $pkg)
    }
    catch {
        return $false
    }
}

function Download-File {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$Destination
    )

    $downloaded = $false

    # 1) BITS zuerst
    try {
        $bits = Get-Command Start-BitsTransfer -ErrorAction SilentlyContinue
        if ($bits) {
            Write-Host "Download mit Start-BitsTransfer..." -ForegroundColor DarkGray
            Start-BitsTransfer -Source $Url -Destination $Destination -ErrorAction Stop
            $downloaded = $true
        }
    }
    catch {
        Write-Host "BITS-Download fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    if ($downloaded -and (Test-Path $Destination)) {
        return
    }

    # 2) Fallback auf curl.exe
    try {
        $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
        if ($curl) {
            Write-Host "Download mit curl.exe..." -ForegroundColor DarkGray
            & curl.exe -L $Url -o $Destination --silent --show-error
            if ($LASTEXITCODE -eq 0 -and (Test-Path $Destination)) {
                $downloaded = $true
            }
        }
    }
    catch {
        Write-Host "curl-Download fehlgeschlagen: $($_.Exception.Message)" -ForegroundColor Yellow
    }

    if (-not $downloaded -or -not (Test-Path $Destination)) {
        throw "Datei konnte nicht heruntergeladen werden: $Url"
    }
}

function Install-Winget {
    if (-not (Test-Is64BitProcess)) {
        $msg = @"
Dieses Script läuft gerade in einer 32-Bit PowerShell (x86).

Bitte starte die normale 64-Bit PowerShell als Administrator
und führe den Launcher dann erneut aus.

Die x86-PowerShell wird für die winget/App-Installer-Installation hier absichtlich blockiert.
"@
        Show-GuiMessage -Message $msg -Title 'Falsche PowerShell-Version' -Type Error
        throw "32-Bit PowerShell erkannt."
    }

    Write-Host "winget/App Installer fehlt. Installation wird gestartet..." -ForegroundColor Yellow

    $bundlePath = Join-Path $env:TEMP 'Microsoft.DesktopAppInstaller.msixbundle'

    try {
        if (Test-Path $bundlePath) {
            Remove-Item $bundlePath -Force -ErrorAction SilentlyContinue
        }

        Download-File -Url 'https://aka.ms/getwinget' -Destination $bundlePath

        if (-not (Test-Path $bundlePath)) {
            throw "Die heruntergeladene Datei wurde nicht gefunden."
        }

        Add-AppxPackage -Path $bundlePath -ErrorAction Stop
        Start-Sleep -Seconds 5
    }
    catch {
        $msg = @"
winget/App Installer konnte nicht automatisch installiert werden.

Fehler:
$($_.Exception.Message)

Mögliche Ursachen:
- falsche PowerShell (x86)
- Store/App Installer-Komponenten fehlen
- Download wurde blockiert
- Netzwerk-/Proxy-Problem

Versuche danach den Launcher erneut.
"@
        Show-GuiMessage -Message $msg -Title 'winget Installation fehlgeschlagen' -Type Error
        throw
    }
}

function Test-WingetAvailable {
    $wingetCmd = Get-WingetCommand
    if ($wingetCmd) {
        Write-Host "winget bereit." -ForegroundColor DarkGray
        return
    }

    if (-not (Test-Is64BitProcess)) {
        $msg = @"
Dieses Script wurde in Windows PowerShell (x86) gestartet.

Bitte verwende die normale 64-Bit PowerShell als Administrator.

Der Launcher wird jetzt abgebrochen.
"@
        Show-GuiMessage -Message $msg -Title '32-Bit PowerShell nicht unterstützt' -Type Error
        throw "winget-Prüfung in x86 PowerShell abgebrochen."
    }

    if (-not (Test-AppInstallerPackage)) {
        Install-Winget
    }
    else {
        Write-Host "App Installer ist vorhanden, aber winget ist noch nicht verfügbar." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }

    $wingetCmd = Get-WingetCommand
    if ($wingetCmd) {
        Write-Host "winget bereit." -ForegroundColor DarkGray
        return
    }

    $msg = @"
winget ist nach der Installation noch nicht verfügbar.

Bitte schließe PowerShell, starte die normale 64-Bit PowerShell als Administrator neu
und führe den Launcher erneut aus.
"@
    Show-GuiMessage -Message $msg -Title 'winget noch nicht verfügbar' -Type Warning
    throw "winget wurde nach der Installation noch nicht gefunden."
}

function Test-WingetPackageInstalled {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    try {
        $output = winget list --id $Id --exact --accept-source-agreements 2>$null
        return ($output -match [regex]::Escape($Id))
    }
    catch {
        return $false
    }
}

function Stop-IfRunning {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$ProcessNames
    )

    foreach ($name in $ProcessNames) {
        try {
            Get-Process -Name $name -ErrorAction SilentlyContinue |
                Stop-Process -Force -ErrorAction SilentlyContinue
        }
        catch {}
    }
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id,

        [ValidateSet('machine', 'user')]
        [string]$Scope = 'machine',

        [string[]]$PreKill = @(),

        [switch]$SkipIfInstalled
    )

    if ($SkipIfInstalled -and (Test-WingetPackageInstalled -Id $Id)) {
        Write-Host "Bereits installiert: $Id" -ForegroundColor DarkGray
        return
    }

    if ($PreKill.Count -gt 0) {
        Stop-IfRunning -ProcessNames $PreKill
        Start-Sleep -Seconds 2
    }

    Write-Host ""
    Write-Host "==== Installiere: $Id ====" -ForegroundColor Cyan

    try {
        $args = @(
            'install',
            '--id', $Id,
            '--exact',
            '--scope', $Scope,
            '--silent',
            '--accept-source-agreements',
            '--accept-package-agreements',
            '--disable-interactivity'
        )

        $proc = Start-Process -FilePath 'winget' -ArgumentList $args -Wait -PassThru -NoNewWindow

        if ($proc.ExitCode -eq 0) {
            Write-Host "OK: $Id" -ForegroundColor Green
        }
        else {
            $msg = "Installation von '$Id' ist fehlgeschlagen. ExitCode: $($proc.ExitCode)"
            Show-GuiMessage -Message $msg -Title 'Paketinstallation fehlgeschlagen' -Type Warning
            Write-Host $msg -ForegroundColor Yellow
        }
    }
    catch {
        $msg = "Fehler bei '$Id': $($_.Exception.Message)"
        Show-GuiMessage -Message $msg -Title 'Paketinstallation fehlgeschlagen' -Type Error
        Write-Host $msg -ForegroundColor Red
    }
}

Test-WingetAvailable
