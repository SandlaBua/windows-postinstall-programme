Start-Sleep -Seconds 10

[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'

function Show-GuiMessage {
    param(
        [string]$Message,
        [string]$Title = 'Windows Postinstall',
        [ValidateSet('Info','Warning','Error')]
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

function Test-Winget {
    return (Get-Command winget -ErrorAction SilentlyContinue)
}

function Test-AppInstaller {
    try {
        return (Get-AppxPackage Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue)
    } catch {
        return $null
    }
}

function Install-Winget {
    Write-Host "Installiere winget..." -ForegroundColor Yellow

    $tmp = "$env:TEMP\winget.msixbundle"

    try {
        if (Test-Path $tmp) { Remove-Item $tmp -Force }

        # stabiler Download (kein irm!)
        $wc = New-Object System.Net.WebClient
        $wc.DownloadFile("https://aka.ms/getwinget", $tmp)

        if (-not (Test-Path $tmp)) {
            throw "Download fehlgeschlagen"
        }

        Add-AppxPackage -Path $tmp
        Start-Sleep -Seconds 5
    }
    catch {
        Show-GuiMessage -Message "Winget konnte nicht installiert werden:`n$($_.Exception.Message)" -Type Error
        throw
    }
}

function Ensure-Winget {
    if (Test-Winget) {
        Write-Host "winget bereit." -ForegroundColor DarkGray
        return
    }

    if (-not [Environment]::Is64BitProcess) {
        Show-GuiMessage -Message "32-Bit PowerShell erkannt. Bitte 64-Bit verwenden." -Type Error
        throw "x86 PowerShell"
    }

    if (-not (Test-AppInstaller)) {
        Install-Winget
    }

    # nochmal prüfen
    if (-not (Test-Winget)) {
        Show-GuiMessage -Message "winget ist nach Installation noch nicht verfügbar. Bitte Script neu starten." -Type Warning
        throw "winget fehlt"
    }
}

# 🔥 HIER AUSFÜHREN (wichtig!)
Ensure-Winget


try {
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
} catch {}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$global:PostInstallFailedPackages = New-Object System.Collections.Generic.List[string]

$script:RepoBase = 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main'
$script:LauncherUrl = "$($script:RepoBase)/launcher.ps1"
$script:CommonUrl   = "$($script:RepoBase)/lib/common.ps1"
$script:PackagesUrl = "$($script:RepoBase)/config/packages.ps1"

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
        $powershellPath = if ([Environment]::Is64BitOperatingSystem -and -not [Environment]::Is64BitProcess) {
            "$env:WINDIR\SysNative\WindowsPowerShell\v1.0\powershell.exe"
        }
        else {
            "powershell.exe"
        }

        $command = "[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12; irm '$ScriptUrl' | iex"

        Start-Process -FilePath $powershellPath -Verb RunAs -WindowStyle Hidden -ArgumentList @(
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

function Get-RemoteObject {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Url
    )

    if ($Url -match 'refs/heads') {
        throw "Falscher GitHub-Link erkannt: $Url"
    }

    $code = Invoke-RestMethod -Uri $Url -ErrorAction Stop

    if ([string]::IsNullOrWhiteSpace($code)) {
        throw "Remote-Datei ist leer: $Url"
    }

    return & ([scriptblock]::Create($code))
}

function New-DarkButton {
    param(
        [string]$Text,
        [int]$X,
        [int]$Y,
        [int]$Width = 100,
        [int]$Height = 34
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Text = $Text
    $button.Size = New-Object System.Drawing.Size -ArgumentList $Width, $Height
    $button.Location = New-Object System.Drawing.Point -ArgumentList $X, $Y
    $button.BackColor = [System.Drawing.Color]::FromArgb(50, 50, 50)
    $button.ForeColor = [System.Drawing.Color]::White
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.FlatAppearance.BorderColor = [System.Drawing.Color]::FromArgb(85, 85, 85)
    $button.FlatAppearance.MouseOverBackColor = [System.Drawing.Color]::FromArgb(68, 68, 68)
    $button.FlatAppearance.MouseDownBackColor = [System.Drawing.Color]::FromArgb(90, 90, 90)
    $button.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    return $button
}

function Show-ProgramSelector {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Categories
    )

    $columnWidth = 240
    $columnSpacing = 18
    $leftMargin = 20
    $topMargin = 95

    $maxPrograms = ($Categories | ForEach-Object { $_.Programs.Count } | Measure-Object -Maximum).Maximum
    if (-not $maxPrograms) { $maxPrograms = 1 }

    $contentHeight = 80 + ($maxPrograms * 24)
    $formWidth = ($leftMargin * 2) + ($Categories.Count * $columnWidth) + (($Categories.Count - 1) * $columnSpacing) + 20
    $formHeight = [Math]::Max(420, 190 + $contentHeight)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Programme installieren'
    $form.Size = New-Object System.Drawing.Size -ArgumentList $formWidth, $formHeight
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $form.ForeColor = [System.Drawing.Color]::White

    $titleLabel = New-Object System.Windows.Forms.Label
    $titleLabel.Text = 'Programme installieren'
    $titleLabel.Font = New-Object System.Drawing.Font('Segoe UI', 14, [System.Drawing.FontStyle]::Bold)
    $titleLabel.ForeColor = [System.Drawing.Color]::White
    $titleLabel.AutoSize = $true
    $titleLabel.Location = New-Object System.Drawing.Point -ArgumentList 20, 15
    $form.Controls.Add($titleLabel)

    $subLabel = New-Object System.Windows.Forms.Label
    $subLabel.Text = 'Von links nach rechts nach Kategorien sortiert. Programme einzeln oder pro Spalte komplett auswählen.'
    $subLabel.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $subLabel.ForeColor = [System.Drawing.Color]::Gainsboro
    $subLabel.AutoSize = $true
    $subLabel.Location = New-Object System.Drawing.Point -ArgumentList 22, 48
    $form.Controls.Add($subLabel)

    $allProgramEntries = New-Object System.Collections.Generic.List[object]

    for ($i = 0; $i -lt $Categories.Count; $i++) {
        $category = $Categories[$i]
        $x = $leftMargin + ($i * ($columnWidth + $columnSpacing))

        $header = New-Object System.Windows.Forms.Label
        $header.Text = $category.Name
        $header.Font = New-Object System.Drawing.Font('Segoe UI', 10, [System.Drawing.FontStyle]::Bold)
        $header.ForeColor = [System.Drawing.Color]::White
        $header.AutoSize = $true
        $header.Location = New-Object System.Drawing.Point -ArgumentList $x, $topMargin
        $form.Controls.Add($header)

        $selectAll = New-Object System.Windows.Forms.CheckBox
        $selectAll.Text = 'Alles auswählen'
        $selectAll.Font = New-Object System.Drawing.Font('Segoe UI', 9)
        $selectAll.ForeColor = [System.Drawing.Color]::White
        $selectAll.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
        $selectAll.AutoSize = $true
        $selectAll.Location = New-Object System.Drawing.Point -ArgumentList $x, ($topMargin + 28)
        $form.Controls.Add($selectAll)

        $children = New-Object System.Collections.Generic.List[System.Windows.Forms.CheckBox]
        $y = $topMargin + 58

        foreach ($program in $category.Programs) {
            $cb = New-Object System.Windows.Forms.CheckBox
            $cb.Text = $program.Name
            $cb.Font = New-Object System.Drawing.Font('Segoe UI', 9)
            $cb.ForeColor = [System.Drawing.Color]::White
            $cb.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
            $cb.AutoSize = $true
            $cb.Location = New-Object System.Drawing.Point -ArgumentList ($x + 4), $y
            $form.Controls.Add($cb)

            $children.Add($cb)
            $allProgramEntries.Add([pscustomobject]@{
                Category = $category.Name
                Program  = $program
                CheckBox = $cb
            })

            $y += 24
        }

        $selectAll.Tag = @($children.ToArray())
        $selectAll.Add_CheckedChanged({
            foreach ($child in @($this.Tag)) {
                $child.Checked = $this.Checked
            }
        })
    }

    $okButton = New-DarkButton -Text 'OK' -X ($form.ClientSize.Width - 220) -Y ($form.ClientSize.Height - 50)
    $cancelButton = New-DarkButton -Text 'Abbrechen' -X ($form.ClientSize.Width - 110) -Y ($form.ClientSize.Height - 50)

    $okButton.Anchor = 'Bottom,Right'
    $cancelButton.Anchor = 'Bottom,Right'

    $form.Controls.Add($okButton)
    $form.Controls.Add($cancelButton)

    $okButton.Add_Click({
        $selected = foreach ($entry in $allProgramEntries) {
            if ($entry.CheckBox.Checked) {
                $entry.Program
            }
        }

        $form.Tag = @($selected)
        $form.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $form.Close()
    })

    $cancelButton.Add_Click({
        $form.Tag = $null
        $form.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
        $form.Close()
    })

    $null = $form.ShowDialog()
    return $form.Tag
}

function Show-InstallStatusWindow {
    param(
        [Parameter(Mandatory = $true)]
        [int]$Total
    )

    $form = New-Object System.Windows.Forms.Form
    $form.Text = 'Installation läuft'
    $form.Size = New-Object System.Drawing.Size -ArgumentList 540, 175
    $form.StartPosition = 'CenterScreen'
    $form.TopMost = $true
    $form.FormBorderStyle = 'FixedDialog'
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(30, 30, 30)
    $form.ForeColor = [System.Drawing.Color]::White

    $title = New-Object System.Windows.Forms.Label
    $title.Text = 'Programme werden installiert'
    $title.Font = New-Object System.Drawing.Font('Segoe UI', 12, [System.Drawing.FontStyle]::Bold)
    $title.ForeColor = [System.Drawing.Color]::White
    $title.AutoSize = $true
    $title.Location = New-Object System.Drawing.Point -ArgumentList 20, 18
    $form.Controls.Add($title)

    $status = New-Object System.Windows.Forms.Label
    $status.Text = 'Starte...'
    $status.Font = New-Object System.Drawing.Font('Segoe UI', 10)
    $status.ForeColor = [System.Drawing.Color]::Gainsboro
    $status.AutoSize = $true
    $status.Location = New-Object System.Drawing.Point -ArgumentList 22, 55
    $form.Controls.Add($status)

    $progress = New-Object System.Windows.Forms.ProgressBar
    $progress.Location = New-Object System.Drawing.Point -ArgumentList 22, 88
    $progress.Size = New-Object System.Drawing.Size -ArgumentList 480, 22
    $progress.Style = 'Continuous'
    $form.Controls.Add($progress)

    $counter = New-Object System.Windows.Forms.Label
    $counter.Text = "0 / $Total"
    $counter.Font = New-Object System.Drawing.Font('Segoe UI', 9)
    $counter.ForeColor = [System.Drawing.Color]::Gainsboro
    $counter.AutoSize = $true
    $counter.Location = New-Object System.Drawing.Point -ArgumentList 22, 118
    $form.Controls.Add($counter)

    $form.Show()
    $form.Refresh()

    return @{
        Form     = $form
        Status   = $status
        Progress = $progress
        Counter  = $counter
        Total    = $Total
    }
}

function Update-InstallStatusWindow {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Window,

        [Parameter(Mandatory = $true)]
        [string]$Text,

        [Parameter(Mandatory = $true)]
        [int]$Current
    )

    $percent = if ($Window.Total -gt 0) {
        [int](($Current / $Window.Total) * 100)
    }
    else {
        0
    }

    $Window.Status.Text = $Text
    $Window.Progress.Value = [Math]::Max(0, [Math]::Min(100, $percent))
    $Window.Counter.Text = "$Current / $($Window.Total)"
    $Window.Form.Refresh()
    [System.Windows.Forms.Application]::DoEvents()
}

function Close-InstallStatusWindow {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Window
    )

    Start-Sleep -Milliseconds 400
    $Window.Form.Close()
    $Window.Form.Dispose()
}

function Show-FinalSummary {
    $packageFailures = @($global:PostInstallFailedPackages | Select-Object -Unique)

    if ($packageFailures.Count -eq 0) {
        Show-GuiMessage -Message 'Alle ausgewählten Programme wurden erfolgreich verarbeitet.' -Title 'Fertig' -Type Info
        return
    }

    $lines = New-Object System.Collections.Generic.List[string]
    $lines.Add("Nicht alles hat funktioniert.")
    $lines.Add("")
    $lines.Add("Fehlgeschlagene Pakete:")

    foreach ($item in $packageFailures) {
        $lines.Add(" - $item")
    }

    Show-GuiMessage -Message ($lines -join [Environment]::NewLine) -Title 'Zusammenfassung' -Type Warning
}

if (-not [Environment]::Is64BitProcess) {
    Show-GuiMessage -Message "Du hast die 32-Bit PowerShell gestartet.`n`nBitte verwende die normale 64-Bit PowerShell als Administrator." -Title 'Falsche PowerShell-Version' -Type Error
    exit
}

if (-not (Test-IsAdmin)) {
    Restart-AsAdminFromUrl -ScriptUrl $script:LauncherUrl
}

try {
    # common.ps1 MUSS auf Top-Level geladen werden, nicht in einer Funktion,
    # sonst landen seine Funktionen nur im Funktions-Scope
    $commonCode = Invoke-RestMethod -Uri $script:CommonUrl -ErrorAction Stop
    if ([string]::IsNullOrWhiteSpace($commonCode)) {
        throw "lib/common.ps1 ist leer."
    }
    . ([scriptblock]::Create($commonCode))

    $categories = Get-RemoteObject -Url $script:PackagesUrl

    if (-not $categories -or $categories.Count -eq 0) {
        throw "Keine Pakete aus config/packages.ps1 geladen."
    }

    $selectedPrograms = Show-ProgramSelector -Categories $categories

    if ($null -eq $selectedPrograms) {
        Show-GuiMessage -Message 'Vorgang abgebrochen.' -Title 'Abbruch' -Type Warning
        exit
    }

    if (@($selectedPrograms).Count -eq 0) {
        Show-GuiMessage -Message 'Es wurde nichts ausgewählt.' -Title 'Keine Auswahl' -Type Warning
        exit
    }

    $statusWindow = Show-InstallStatusWindow -Total @($selectedPrograms).Count
    $index = 0

    foreach ($program in $selectedPrograms) {
        $index++
        Update-InstallStatusWindow -Window $statusWindow -Text "Installiere: $($program.Name)" -Current $index

        Install-WingetPackage `
            -Id $program.Id `
            -Scope $program.Scope `
            -PreKill $program.PreKill `
            -SkipIfInstalled
    }

    Update-InstallStatusWindow -Window $statusWindow -Text 'Fertig.' -Current @($selectedPrograms).Count
    Close-InstallStatusWindow -Window $statusWindow

    Show-FinalSummary
}
catch {
    Show-GuiMessage -Message "Launcher Fehler:`n$($_.Exception.Message)" -Title 'Launcher Fehler' -Type Error
    throw
}
