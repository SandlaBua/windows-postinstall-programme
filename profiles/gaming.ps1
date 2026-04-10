. ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/lib/common.ps1')))

$packages = @(
    @{ Id = 'Valve.Steam'; Scope = 'machine'; PreKill = @('steam') }
    @{ Id = 'ElectronicArts.EADesktop'; Scope = 'machine'; PreKill = @('eadesktop', 'eabackgroundservice') }
    @{ Id = 'EpicGames.EpicGamesLauncher'; Scope = 'machine'; PreKill = @('epicgameslauncher') }
    @{ Id = 'Ubisoft.Connect'; Scope = 'machine'; PreKill = @('ubisoftconnect', 'upc') }
    @{ Id = 'Overwolf.CurseForge'; Scope = 'machine'; PreKill = @('curseforge', 'overwolf') }
    @{ Id = 'Google.PlayGames.Beta'; Scope = 'machine'; PreKill = @('googleplaygames') }
    @{ Id = 'RockstarGames.Launcher'; Scope = 'machine'; PreKill = @('launcherpatcher', 'rockstargameslauncher') }
    @{ Id = 'MedalB.V.Medal'; Scope = 'user'; PreKill = @('medal') }
    @{ Id = 'Vendicated.Vencord'; Scope = 'user'; PreKill = @('discord', 'vencordinstaller') }
)

foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Scope $pkg.Scope -PreKill $pkg.PreKill -SkipIfInstalled
}
