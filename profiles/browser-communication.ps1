. ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/lib/common.ps1')))

$packages = @(
    @{ Id = 'Brave.Brave'; Scope = 'machine'; PreKill = @('brave') }
    @{ Id = 'Google.Chrome'; Scope = 'machine'; PreKill = @('chrome') }
    @{ Id = 'Spotify.Spotify'; Scope = 'user'; PreKill = @('spotify') }
    @{ Id = 'Discord.Discord'; Scope = 'user'; PreKill = @('discord', 'update') }
    @{ Id = 'WhatsApp.WhatsApp'; Scope = 'user'; PreKill = @('whatsapp') }
)

foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Scope $pkg.Scope -PreKill $pkg.PreKill -SkipIfInstalled
}
