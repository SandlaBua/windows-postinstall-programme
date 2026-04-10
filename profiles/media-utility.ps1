. ([scriptblock]::Create((Invoke-RestMethod 'https://raw.githubusercontent.com/SandlaBua/windows-postinstall-programme/main/lib/common.ps1')))

$packages = @(
    @{ Id = '7zip.7zip';                                Scope = 'machine'; PreKill = @('7zfm', '7zg') }
    @{ Id = 'winaero.tweaker';                          Scope = 'machine'; PreKill = @('winaerotweaker') }
    @{ Id = 'GuinpinSoft.MakeMKV';                      Scope = 'machine'; PreKill = @('makemkv') }
    @{ Id = 'HandBrake.HandBrake';                      Scope = 'machine'; PreKill = @('handbrake') }
    @{ Id = 'Balena.Etcher';                            Scope = 'machine'; PreKill = @('balenaetcher') }
    @{ Id = 'WinSCP.WinSCP';                            Scope = 'user';    PreKill = @('winscp') }
    @{ Id = 'PowerSoftware.AnyBurn';                    Scope = 'machine'; PreKill = @('anyburn') }
    @{ Id = 'RaspberryPiFoundation.RaspberryPiImager';  Scope = 'machine'; PreKill = @('rpi-imager') }
    @{ Id = 'Rufus.Rufus';                              Scope = 'user';    PreKill = @('rufus') }
)

$ui = Show-StatusWindow -Title 'Media & Utility' -InitialText 'Starte Installation...'
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
