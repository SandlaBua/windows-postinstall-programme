. ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/lib/common.ps1')))

$packages = @(
    @{ Id = 'Creality.CrealityScan'; Scope = 'machine'; PreKill = @('crealityscan') }
    @{ Id = 'Bambulab.BambuStudio'; Scope = 'machine'; PreKill = @('bambustudio') }
)

foreach ($pkg in $packages) {
    Install-WingetPackage -Id $pkg.Id -Scope $pkg.Scope -PreKill $pkg.PreKill -SkipIfInstalled
}
