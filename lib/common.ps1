$ErrorActionPreference = 'Stop'

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

function Install-Winget {
    Write-Host "winget/App Installer fehlt. Installation wird gestartet..." -ForegroundColor Yellow

    $bundlePath = Join-Path $env:TEMP 'Microsoft.DesktopAppInstaller.msixbundle'

    try {
        Invoke-WebRequest -Uri 'https://aka.ms/getwinget' -OutFile $bundlePath -UseBasicParsing
        Add-AppxPackage -Path $bundlePath -ErrorAction Stop
        Start-Sleep -Seconds 5
    }
    catch {
        throw "Winget/App Installer konnte nicht installiert werden: $($_.Exception.Message)"
    }
}

function Test-WingetAvailable {
    $wingetCmd = Get-WingetCommand
    if ($wingetCmd) {
        Write-Host "winget bereit." -ForegroundColor DarkGray
        return
    }

    if (-not (Test-AppInstallerPackage)) {
        Install-Winget
    }
    else {
        Write-Host "App Installer ist vorhanden, aber winget ist in dieser Session noch nicht verfügbar." -ForegroundColor Yellow
        Start-Sleep -Seconds 3
    }

    $wingetCmd = Get-WingetCommand
    if ($wingetCmd) {
        Write-Host "winget bereit." -ForegroundColor DarkGray
        return
    }

    if (Test-AppInstallerPackage) {
        throw "App Installer wurde erkannt, aber 'winget' ist noch nicht verfügbar. Starte das Hauptscript bitte einmal neu."
    }

    throw "winget wurde nicht gefunden."
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
            Write-Host "Fehlercode bei ${Id}: $($proc.ExitCode)" -ForegroundColor Yellow
        }
    }
    catch {
        Write-Host "Fehler bei ${Id}: $($_.Exception.Message)" -ForegroundColor Red
    }
}

Test-WingetAvailable
