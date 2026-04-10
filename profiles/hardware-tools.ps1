. "$PSScriptRoot\..\lib\common.ps1"

$packages = @(
    @{ Id = 'Logitech.GHUB'; Scope = 'machine'; PreKill = @('lghub', 'lghub_agent', 'lghub_updater') }
    @{ Id = 'Logitech.OptionsPlus'; Scope = 'machine'; PreKill = @('logioptionsplus_agent', 'logioptionsplus_appbroker') }
    @{ Id = 'PreSonus.UniversalControl'; Scope = 'machine'; PreKill = @('ucsurface', 'universalcontrol') }
    @{ Id = 'EdgeTX.Companion'; Scope = 'machine'; PreKill = @('companion') }
    @{ Id = 'REALiX.HWiNFO'; Scope = 'machine'; PreKill = @('hwinfo64') }
)

foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Scope $pkg.Scope -PreKill $pkg.PreKill -SkipIfInstalled
}
