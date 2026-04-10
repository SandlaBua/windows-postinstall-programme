$ErrorActionPreference = 'Stop'

function Test-WingetAvailable {
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
        throw "winget wurde nicht gefunden."
    }
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

    Write-Host ""
    Write-Host "==== Installiere: $Id ====" -ForegroundColor Cyan

    try {
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
