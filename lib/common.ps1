$ErrorActionPreference = 'Stop'

try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing | Out-Null

if (-not $global:PostInstallFailedPackages) {
    $global:PostInstallFailedPackages = New-Object System.Collections.Generic.List[string]
}

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

function Add-FailedPackage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Id
    )

    if (-not $global:PostInstallFailedPackages.Contains($Id)) {
        $global:PostInstallFailedPackages.Add($Id)
    }
}

function Show-StatusWindow {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Title,

        [string]$InitialText = 'Starte Installation...'
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $Title
    $form.Size = New-Object System.Drawing.Size(460, 160)
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $form.ForeColor = [System.Drawing.Color]::White

    $label = New-Object System.Windows.Forms.Label
    $label.Text = $InitialText
    $label.ForeColor = [System.Drawing.Color]::White
    $label.BackColor = [System.Drawing.Color]::Transparent
    $label.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(20, 20)

    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point(20, 65)
    $progress.Size = New-Object System.Drawing.Size(400, 22)
    $progress.Style = 'Continuous'

    $form.Controls.Add($label)
    $form.Controls.Add($progress)

    $form.Show()
    $form.Refresh()

    return @{
        Form     = $form
        Label    = $label
        Progress = $progress
    }
}

function Update-StatusWindow {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Window,

        [Parameter(Mandatory = $true)]
        [string]$Text,

        [int]$Percent = -1
    )

    $Window.Label.Text = $Text

    if ($Percent -ge 0) {
        $value = [Math]::Max(0, [Math]::Min(100, $Percent))
        $Window.Progress.Value = $value
    }

    $Window.Form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Close-StatusWindow {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Window
    )

    Start-Sleep -Milliseconds 400
    $Window.Form.Close()
    $Window.Form.Dispose()
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
            Add-FailedPackage -Id $Id
            $msg = "Installation von '$Id' ist fehlgeschlagen. ExitCode: $($proc.ExitCode)"
            Show-GuiMessage -Message $msg -Title 'Paketinstallation fehlgeschlagen' -Type Warning
            Write-Host $msg -ForegroundColor Yellow
        }
    }
    catch {
        Add-FailedPackage -Id $Id
        $msg = "Fehler bei '$Id': $($_.Exception.Message)"
        Show-GuiMessage -Message $msg -Title 'Paketinstallation fehlgeschlagen' -Type Error
        Write-Host $msg -ForegroundColor Red
    }
}

Test-WingetAvailable
