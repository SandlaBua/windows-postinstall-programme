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

function New-DarkButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 90,
        [int]$Height = 30
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Size = New-Object System.Drawing.Size($Width, $Height)
    $button.Location = New-Object System.Drawing.Point($X, $Y)
    $button.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(80, 80, 80)
    $button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(70, 70, 70)
    $button.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
    $button.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    return $button
}

function Show-ProfileSelector {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Profiles
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Programme installieren'
    $form.Size = New-Object System.Drawing.Size(340, 420)
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $form.ForeColor = [System.Drawing.Color]::White

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = 'Programme installieren'
    $titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 13, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.BackColor = [System.Drawing.Color]::Transparent
    $titleLabel.AutoSize = $true
    $titleLabel.Location = New-Object System.Drawing.Point(20, 18)
    $form.Controls.Add($titleLabel)

    $subtitleLabel = New-Object System.Windows.Forms.Label
    $subtitleLabel.Text = 'Welche Script-Pakete möchtest du ausführen?'
    $subtitleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Regular)
    $subtitleLabel.ForeColor = [System.Drawing.Color]::Gainsboro
    $subtitleLabel.BackColor = [System.Drawing.Color]::Transparent
    $subtitleLabel.AutoSize = $true
    $subtitleLabel.Location = New-Object System.Drawing.Point(22, 52)
    $form.Controls.Add($subtitleLabel)

    $checkboxes = @()
    $y = 95

    for ($i = 0; $i -lt $Profiles.Count; $i++) {
        $cb = New-Object System.Windows.Forms.CheckBox
        $cb.Text = $Profiles[$i].Name
        $cb.AutoSize = $true
        $cb.Location = New-Object System.Drawing.Point(25, $y)
        $cb.ForeColor = [System.Drawing.Color]::White
        $cb.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $cb.Font = New-Object System.Drawing.Font("Segoe UI", 10, [System.Drawing.FontStyle]::Regular)
        $form.Controls.Add($cb)
        $checkboxes += $cb
        $y += 38
    }

    $okButton = New-DarkButton -Text 'OK' -X 120 -Y 330 -Width 90 -Height 32
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $form.Controls.Add($okButton)

    $cancelButton = New-DarkButton -Text 'Abbrechen' -X 220 -Y 330 -Width 90 -Height 32
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
