. "$PSScriptRoot\..\lib\common.ps1"

$packages = @(
    @{ Id = 'Creality.CrealityScan'; Scope = 'machine'; PreKill = @('crealityscan') }
    @{ Id = 'Bambulab.Bambustudio'; Scope = 'machine'; PreKill = @('bambu studio', 'bambustudio') }
)

foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Scope $pkg.Scope -PreKill $pkg.PreKill -SkipIfInstalled
}
