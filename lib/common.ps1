$ErrorActionPreference = 'Stop'

# ---------------------------------------
# Winget sicherstellen
# ---------------------------------------

function Install-Winget {
    Write-Host "Installiere winget..." -ForegroundColor Yellow

    try {
        # Microsoft offizieller Installer
        $url = "https://aka.ms/getwinget"
        $file = "$env:TEMP\winget.appxbundle"

        Invoke-WebRequest -Uri $url -OutFile $file -UseBasicParsing

        Add-AppxPackage -Path $file

        Write-Host "winget erfolgreich installiert." -ForegroundColor Green
    }
    catch {
        Write-Host "Fehler bei winget Installation: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

function Test-WingetAvailable {
    $winget = Get-Command winget -ErrorAction SilentlyContinue

    if (-not $winget) {
        Write-Host "winget nicht gefunden → Installation wird gestartet..." -ForegroundColor Yellow
        Install-Winget

        Start-Sleep -Seconds 3

        $winget = Get-Command winget -ErrorAction SilentlyContinue

        if (-not $winget) {
            throw "winget konnte nicht installiert werden."
        }
    }

    Write-Host "winget bereit." -ForegroundColor DarkGray
}

# ---------------------------------------
# Check ob Programm schon installiert
# ---------------------------------------

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

# ---------------------------------------
# Prozesse killen
# ---------------------------------------

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

# ---------------------------------------
# Installation
# ---------------------------------------

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
            Write-Host "Fehlercode bei ${Id}: $($proc.ExitCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Fehler bei ${Id}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# ---------------------------------------
# INIT (wird automatisch ausgeführt)
# ---------------------------------------

Test-WingetAvailable
