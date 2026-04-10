. ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/lib/common.ps1')))

$packages = @(
    @{ Id = 'Parsec.Parsec';                          Scope = 'user';    PreKill = @('parsec', 'parsecd') }
    @{ Id = 'Tailscale.Tailscale';                    Scope = 'machine'; PreKill = @('tailscale', 'tailscale-ipn') }
)

$ui = Show-StatusWindow -Title 'Remote & Netzwerk' -InitialText 'Starte Installation...'
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
