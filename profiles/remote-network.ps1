. "$PSScriptRoot\..\lib\common.ps1"

$packages = @(
    @{ Id = 'MoonlightGameStreamingProject.Moonlight'; Scope = 'user'; PreKill = @('moonlight') }
    @{ Id = 'LizardByte.Sunshine'; Scope = 'machine'; PreKill = @('sunshine') }
    @{ Id = 'Parsec.Parsec'; Scope = 'user'; PreKill = @('parsecd', 'parsec') }
    @{ Id = 'Parsec.ParsecVDD'; Scope = 'machine'; PreKill = @() }
    @{ Id = 'Tailscale.Tailscale'; Scope = 'machine'; PreKill = @('tailscale-ipn', 'tailscale') }
)

foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Scope $pkg.Scope -PreKill $pkg.PreKill -SkipIfInstalled
}
