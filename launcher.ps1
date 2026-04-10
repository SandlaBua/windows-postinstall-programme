[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Restart-AsAdminFromUrl {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ScriptUrl
    )

    $command = "irm '$ScriptUrl' | iex"

    Start-Process powershell.exe -Verb RunAs -ArgumentList @(
        "-NoProfile",
        "-ExecutionPolicy Bypass",
        "-Command", $command
    )

    exit
}

function Invoke-RemoteScript {
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    try {
        Write-Host ""
        Write-Host "===== Lade Script: $Name =====" -ForegroundColor Cyan
        Write-Host "URL: $Url" -ForegroundColor DarkGray

        # Schutz gegen falsche URLs
        if ($Url -match "refs/heads") {
            throw "Falscher GitHub-Link (refs/heads erkannt): $Url"
        }

        $code = Invoke-RestMethod -Uri $Url -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($code)) {
            throw "Script leer geladen"
        }

        # Schutz: falls du aus Versehen wieder den Launcher lädst
        if ($code -match "Show-ProfileSelector") {
            throw "Falsches Script geladen (Launcher statt Profil)"
        }

        Write-Host "===== Starte Script: $Name =====" -ForegroundColor Green
        & ([scriptblock]::Create($code))
        Write-Host "===== Fertig: $Name =====" -ForegroundColor Green
    }
    catch {
        Write-Host "Fehler bei '$Name': $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Show-ProfileSelector {
    param([array]$Profiles)

    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Programme installieren'
    $form.Size = New-Object System.Drawing.Size(450, 360)
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true

    $label = New-Object System.Windows.Forms.Label
    $label.Text = 'Welche Script-Pakete möchtest du ausführen?'
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(20,20)
    $form.Controls.Add($label)

    $checkboxes = @()
    $y = 60

    foreach ($profile in $Profiles) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $profile.Name
        $cb.AutoSize = $true
        $cb.Location = New-Object System.Drawing.Point(25,$y)
        $form.Controls.Add($cb)
        $checkboxes += $cb
        $y += 30
    }

    $ok = New-Object System.Windows.Forms.Button
    $ok.Text = "OK"
    $ok.Location = New-Object System.Drawing.Point(230,260)
    $ok.DialogResult = "OK"
    $form.Controls.Add($ok)

    $cancel = New-Object System.Windows.Forms.Button
    $cancel.Text = "Abbrechen"
    $cancel.Location = New-Object System.Drawing.Point(330,260)
    $cancel.DialogResult = "Cancel"
    $form.Controls.Add($cancel)

    $form.AcceptButton = $ok
    $form.CancelButton = $cancel

    if ($form.ShowDialog() -ne "OK") {
        return $null
    }

    $selected = @()

    for ($i=0; $i -lt $checkboxes.Count; $i++) {
        if ($checkboxes[$i].Checked) {
            $selected += $Profiles[$i]
        }
    }

    return $selected
}

# 🔥 WICHTIG: richtiger Raw-Link zu DIESEM Script
$mainScriptUrl = "https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/launcher.ps1"

# 🔥 PROFILE MIT KORREKTEN LINKS
$scriptProfiles = @(
    @{
        Name = 'Browser & Kommunikation'
        Url  = 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/profiles/browser-communication.ps1'
    }
    @{
        Name = 'Gaming & Launcher'
        Url  = 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/profiles/gaming.ps1'
    }
    @{
        Name = 'Hardware Tools'
        Url  = 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/profiles/hardware-tools.ps1'
    }
    @{
        Name = 'Remote & Netzwerk'
        Url  = 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/profiles/remote-network.ps1'
    }
    @{
        Name = 'Media & Utility'
        Url  = 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/profiles/media-utility.ps1'
    }
    @{
        Name = '3D & Printing'
        Url  = 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/profiles/printing-3d.ps1'
    }
)

# Admin check
if (-not (Test-IsAdmin)) {
    Restart-AsAdminFromUrl -ScriptUrl $mainScriptUrl
}

# GUI
$selectedProfiles = Show-ProfileSelector -Profiles $scriptProfiles

if ($null -eq $selectedProfiles) {
    Write-Host "Abgebrochen." -ForegroundColor Yellow
    exit
}

if ($selectedProfiles.Count -eq 0) {
    Write-Host "Nichts ausgewählt." -ForegroundColor Yellow
    exit
}

# Execute
foreach ($profile in $selectedProfiles) {
    Invoke-RemoteScript -Name $profile.Name -Url $profile.Url
}

Write-Host ""
Write-Host "Fertig." -ForegroundColor Cyan
