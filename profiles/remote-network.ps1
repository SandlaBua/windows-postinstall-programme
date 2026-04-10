. ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/lib/common.ps1')))

$packages = @(
    @{ Id = 'Parsec.Parsec'; Scope = 'user'; PreKill = @('parsec', 'parsecd') }
    @{ Id = 'Tailscale.Tailscale'; Scope = 'machine'; PreKill = @('tailscale', 'tailscale-ipn') }
)

foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Scope $pkg.Scope -PreKill $pkg.PreKill -SkipIfInstalled
}
