. ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/lib/common.ps1')))

$packages = @(
    @{ Id = 'Brave.Brave';          Scope = 'machine'; PreKill = @('brave') }
    @{ Id = 'Google.Chrome';        Scope = 'machine'; PreKill = @('chrome') }
    @{ Id = 'Spotify.Spotify';      Scope = 'user';    PreKill = @('spotify') }
    @{ Id = 'Discord.Discord';      Scope = 'user';    PreKill = @('discord', 'update') }
    @{ Id = 'WhatsApp.WhatsApp';    Scope = 'user';    PreKill = @('whatsapp') }
)

$ui = Show-StatusWindow -Title 'Browser & Kommunikation' -InitialText 'Starte Installation...'
$total = $packages.Count
$current = 0

foreach ($pkg in $packages) {
    $current++
    $percent = [int](($current / $total) * 100)
    Update-StatusWindow -Window $ui -Text "Installiere: $($pkg.Id)" -Percent $percent

    Install-WingetPackage `
        -Id $pkg.Id `
        -Scope $pkg.Scope `
        -PreKill $pkg.PreKill `
        -SkipIfInstalled
}

Update-StatusWindow -Window $ui -Text 'Fertig.' -Percent 100
Close-StatusWindow -Window $ui
