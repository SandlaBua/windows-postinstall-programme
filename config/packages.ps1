@(
    [pscustomobject]@{
        Name = 'Browser & Kommunikation'
        Programs = @(
            [pscustomobject]@{ Name = 'Brave';        Id = 'Brave.Brave';       Scope = 'machine'; PreKill = @('brave') }
            [pscustomobject]@{ Name = 'Chrome';       Id = 'Google.Chrome';     Scope = 'machine'; PreKill = @('chrome') }
            [pscustomobject]@{ Name = 'WhatsApp';     Id = 'WhatsApp.WhatsApp'; Scope = 'user';    PreKill = @('whatsapp') }
            [pscustomobject]@{ Name = 'Spotify';      Id = 'Spotify.Spotify';   Scope = 'user';    PreKill = @('spotify') }
            [pscustomobject]@{ Name = 'Discord';      Id = 'Discord.Discord';   Scope = 'user';    PreKill = @('discord', 'update') }
            [pscustomobject]@{ Name = 'Vencord';               Id = 'Vendicated.Vencord';          Scope = 'user';    PreKill = @('discord', 'vencordinstaller') }
        )
    }

    [pscustomobject]@{
        Name = 'Gaming & Launcher'
        Programs = @(
            [pscustomobject]@{ Name = 'Steam';                  Id = 'Valve.Steam';                  Scope = 'machine'; PreKill = @('steam') }
            [pscustomobject]@{ Name = 'EA App';                 Id = 'ElectronicArts.EADesktop';    Scope = 'machine'; PreKill = @('eadesktop', 'eabackgroundservice') }
            [pscustomobject]@{ Name = 'Epic Games Launcher';   Id = 'EpicGames.EpicGamesLauncher'; Scope = 'machine'; PreKill = @('epicgameslauncher') }
            [pscustomobject]@{ Name = 'Ubisoft Connect';       Id = 'Ubisoft.Connect';             Scope = 'machine'; PreKill = @('ubisoftconnect', 'upc') }
            [pscustomobject]@{ Name = 'CurseForge';            Id = 'Overwolf.CurseForge';         Scope = 'machine'; PreKill = @('curseforge', 'overwolf') }
            [pscustomobject]@{ Name = 'Google Play Games';     Id = 'Google.PlayGames.Beta';       Scope = 'machine'; PreKill = @('googleplaygames') }
            [pscustomobject]@{ Name = 'Rockstar Launcher';     Id = 'RockstarGames.Launcher';      Scope = 'machine'; PreKill = @('rockstargameslauncher', 'launcherpatcher') }
            [pscustomobject]@{ Name = 'Medal';                 Id = 'MedalB.V.Medal';              Scope = 'user';    PreKill = @('medal') }
            
        )
    }

    [pscustomobject]@{
        Name = 'Hardware Tools'
        Programs = @(
            [pscustomobject]@{ Name = 'Logitech G HUB';              Id = 'Logitech.GHUB';             Scope = 'machine'; PreKill = @('lghub', 'lghub_agent', 'lghub_updater') }
            [pscustomobject]@{ Name = 'Logi Options+';               Id = 'Logitech.OptionsPlus';      Scope = 'machine'; PreKill = @('logioptionsplus_agent', 'logioptionsplus_appbroker') }
            [pscustomobject]@{ Name = 'PreSonus Universal Control';  Id = 'PreSonus.UniversalControl'; Scope = 'machine'; PreKill = @('ucsurface', 'universalcontrol') }
            [pscustomobject]@{ Name = 'HWiNFO';                      Id = 'REALiX.HWiNFO';             Scope = 'machine'; PreKill = @('hwinfo64') }
            [pscustomobject]@{ Name = 'EdgeTX Companion';            Id = 'EdgeTX.Companion';          Scope = 'machine'; PreKill = @('companion') }
        )
    }

    [pscustomobject]@{
        Name = 'Remote & Netzwerk'
        Programs = @(
            [pscustomobject]@{ Name = 'Moonlight';   Id = 'MoonlightGameStreamingProject.Moonlight'; Scope = 'user';    PreKill = @('moonlight') }
            [pscustomobject]@{ Name = 'Sunshine';    Id = 'LizardByte.Sunshine';                     Scope = 'machine'; PreKill = @('sunshine') }
            [pscustomobject]@{ Name = 'Parsec';      Id = 'Parsec.Parsec';                           Scope = 'user';    PreKill = @('parsec', 'parsecd') }
            [pscustomobject]@{ Name = 'Tailscale';   Id = 'Tailscale.Tailscale';                     Scope = 'machine'; PreKill = @('tailscale', 'tailscale-ipn') }
        )
    }

    [pscustomobject]@{
        Name = 'Media & Utility'
        Programs = @(
            [pscustomobject]@{ Name = '7-Zip';                Id = '7zip.7zip';                               Scope = 'machine'; PreKill = @('7zfm', '7zg') }
            [pscustomobject]@{ Name = 'Winaero Tweaker';     Id = 'winaero.tweaker';                         Scope = 'machine'; PreKill = @('winaerotweaker') }
            [pscustomobject]@{ Name = 'MakeMKV';             Id = 'GuinpinSoft.MakeMKV';                     Scope = 'machine'; PreKill = @('makemkv') }
            [pscustomobject]@{ Name = 'HandBrake';           Id = 'HandBrake.HandBrake';                     Scope = 'machine'; PreKill = @('handbrake') }
            [pscustomobject]@{ Name = 'WinSCP';              Id = 'WinSCP.WinSCP';                           Scope = 'user';    PreKill = @('winscp') }
            [pscustomobject]@{ Name = 'AnyBurn';             Id = 'PowerSoftware.AnyBurn';                   Scope = 'machine'; PreKill = @('anyburn') }
            [pscustomobject]@{ Name = 'Raspberry Pi Imager'; Id = 'RaspberryPiFoundation.RaspberryPiImager'; Scope = 'machine'; PreKill = @('rpi-imager') }
            [pscustomobject]@{ Name = 'Rufus';               Id = 'Rufus.Rufus';                             Scope = 'user';    PreKill = @('rufus') }
            [pscustomobject]@{ Name = 'balenaEtcher';        Id = 'Balena.Etcher';                           Scope = 'machine'; PreKill = @('balenaetcher') }
        )
    }

    [pscustomobject]@{
        Name = '3D & Printing'
        Programs = @(
            [pscustomobject]@{ Name = 'Creality Scan';  Id = 'Creality.CrealityScan'; Scope = 'machine'; PreKill = @('crealityscan') }
            [pscustomobject]@{ Name = 'Bambu Studio';   Id = 'Bambulab.BambuStudio';  Scope = 'machine'; PreKill = @('bambustudio') }
        )
    }
)
