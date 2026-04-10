[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$global:PostInstallFailedProfiles = New-Object System.Collections.Generic.List[string]
$global:PostInstallFailedPackages = New-Object System.Collections.Generic.List[string]

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

    try {
        if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
            $powershellPath = "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"
        }
        else {
            $powershellPath = "powershell.exe"
        }

        $command = "irm '$ScriptUrl' | iex"

        Start-Process -FilePath $powershellPath -Verb RunAs -ArgumentList @(
            "-NoProfile",
            "-ExecutionPolicy", "Bypass",
            "-Command", $command
        )

        exit
    }
    catch {
        Show-GuiMessage -Message "Neustart als Administrator fehlgeschlagen:`n$($_.Exception.Message)" -Title 'Admin-Start fehlgeschlagen' -Type Error
        throw
    }
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

        if ($Url -match 'refs/heads') {
            Show-GuiMessage -Message "Falscher GitHub-Link erkannt:`n$Url" -Title 'Ungültiger Link' -Type Error
            throw "Falscher GitHub-Link (refs/heads erkannt): $Url"
        }

        $code = Invoke-RestMethod -Uri $Url -ErrorAction Stop

        if ([string]::IsNullOrWhiteSpace($code)) {
            throw "Script leer geladen."
        }

        if ($code -match 'Show-ProfileSelector') {
            Show-GuiMessage -Message "Es wurde versehentlich wieder der Launcher statt eines Profils geladen.`n`nURL:`n$Url" -Title 'Falsches Script geladen' -Type Error
            throw "Falsches Script geladen (Launcher statt Profil)."
        }

        Write-Host "===== Starte Script: $Name =====" -ForegroundColor Green
        & ([scriptblock]::Create($code))
        Write-Host "===== Fertig: $Name =====" -ForegroundColor Green
        return $true
    }
    catch {
        if (-not $global:PostInstallFailedProfiles.Contains($Name)) {
            $global:PostInstallFailedProfiles.Add($Name)
        }

        Show-GuiMessage -Message "Fehler bei '$Name':`n$($_.Exception.Message)" -Title 'Profil fehlgeschlagen' -Type Error
        Write-Host "Fehler bei '$Name': $($_.Exception.Message)" -ForegroundColor Red
        return $false
    }
}

function Show-ProfileSelector {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Profiles
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Programme installieren'
    $form.Size = New-Object System.Drawing.Size(460, 380)
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false

    $label = New-Object System.Windows.Forms.Label
    $label.Text = 'Welche Script-Pakete möchtest du ausführen?'
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(20, 20)
    $form.Controls.Add($label)

    $checkboxes = @()
    $y = 60

    for ($i = 0; $i -lt $Profiles.Count; $i++) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $Profiles[$i].Name
        $cb.AutoSize = $true
        $cb.Location = New-Object System.Drawing.Point(25, $y)
        $form.Controls.Add($cb)
        $checkboxes += $cb
        $y += 30
    }

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = 'OK'
    $okButton.Size = New-Object System.Drawing.Size(90, 30)
    $okButton.Location = New-Object System.Drawing.Point(240, 290)
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = 'Abbrechen'
    $cancelButton.Size = New-Object System.Drawing.Size(90, 30)
    $cancelButton.Location = New-Object System.Drawing.Point(340, 290)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $form.Controls.Add($cancelButton)

    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton

    $dialogResult = $form.ShowDialog()

    if ($dialogResult -ne [System.Windows.Forms.DialogResult]::OK) {
        return $null
    }

    $selectedProfiles = @()
    for ($i = 0; $i -lt $checkboxes.Count; $i++) {
        if ($checkboxes[$i].Checked) {
            $selectedProfiles += $Profiles[$i]
        }
    }

    return $selectedProfiles
}

function Show-FinalSummary {
    $profileFailures = @($global:PostInstallFailedProfiles | Select-Object -Unique)
    $packageFailures = @($global:PostInstallFailedPackages | Select-Object -Unique)

    if ($profileFailures.Count -eq 0 -and $packageFailures.Count -eq 0) {
        Show-GuiMessage -Message 'Alle ausgewählten Scripts und Pakete wurden erfolgreich verarbeitet.' -Title 'Fertig' -Type Info
        return
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Nicht alles hat funktioniert.")
    $lines.Add("")

    if ($profileFailures.Count -gt 0) {
        $lines.Add("Fehlgeschlagene Profile:")
        foreach ($item in $profileFailures) {
            $lines.Add(" - $item")
        }
        $lines.Add("")
    }

    if ($packageFailures.Count -gt 0) {
        $lines.Add("Fehlgeschlagene Pakete:")
        foreach ($item in $packageFailures) {
            $lines.Add(" - $item")
        }
    }

    Show-GuiMessage -Message ($lines -join [Environment]::NewLine) -Title 'Zusammenfassung' -Type Warning
}

$mainScriptUrl = 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/launcher.ps1'

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

if (-not [Environment]::Is64BitProcess) {
    Show-GuiMessage -Message "Du hast die 32-Bit PowerShell gestartet.`n`nBitte verwende die normale 64-Bit PowerShell als Administrator." -Title 'Falsche PowerShell-Version' -Type Error
    exit
}

if (-not (Test-IsAdmin)) {
    Restart-AsAdminFromUrl -ScriptUrl $mainScriptUrl
}

try {
    $selectedProfiles = Show-ProfileSelector -Profiles $scriptProfiles

    if ($null -eq $selectedProfiles) {
        Show-GuiMessage -Message 'Vorgang abgebrochen.' -Title 'Abbruch' -Type Warning
        exit
    }

    if ($selectedProfiles.Count -eq 0) {
        Show-GuiMessage -Message 'Es wurde nichts ausgewählt.' -Title 'Keine Auswahl' -Type Warning
        exit
    }

    foreach ($profile in $selectedProfiles) {
        [void](Invoke-RemoteScript -Name $profile.Name -Url $profile.Url)
    }

    Show-FinalSummary
}
catch {
    Show-GuiMessage -Message "Unerwarteter Fehler:`n$($_.Exception.Message)" -Title 'Launcher Fehler' -Type Error
    throw
}
