. "$PSScriptRoot\pathutils.ps1"


function Release-Steam {
    param (
        [BuildConfig]$config,
        [string]$version,
        [bool]$windows = $true,
        [bool]$mac = $true,
        [switch]$dryrun = $false
    )

    # Root folder is where we'll write the scripts
    $rootfolder = Get-Build-Base-Path -builddir:$config.BuildDir -version:$version -steam:$true -development:$false
    # Preview mode in Steam build just outputs logs so it's dryrun
    $preview = if($dryrun) { "1" } else { "0"}

    # write app file up to depot section then fill that in as we do depots
    $appfile = "$rootfolder\app_build_$($config.SteamAppId).vdf"
    Write-Output "Creating app build config $appfile"
    Remove-Item $appfile -Force -ErrorAction SilentlyContinue
    $appfp = New-Object -TypeName System.IO.FileStream(
        $appfile,
        [System.IO.FileMode]::Create,
        [System.IO.FileAccess]::Write)
    $appstream = New-Object System.IO.StreamWriter ($appfp, [System.Text.Encoding]::UTF8)

    $appstream.WriteLine("`"appbuild`"")
    $appstream.WriteLine("{")
    $appstream.WriteLine("    `"appid`" `"$($config.SteamAppId)`"")
    $appstream.WriteLine("    `"desc`" `"$version`"")
    $appstream.WriteLine("    `"buildoutput`" `".\steamcmdbuild`"")
    # we don't set contentroot in app file, we specify in depot files
    $appstream.WriteLine("    `"setlive`" `"`"") # never try to set live
    $appstream.WriteLine("    `"preview`" `"$preview`"")
    $appstream.WriteLine("    `"local`" `"`"")
    $appstream.WriteLine("    `"depots`"")
    $appstream.WriteLine("    {")

    # From here we pause, to fill in the rest in depots

    # Build depot configuration files
    foreach ($target in $config.Targets) {
        # Itch channels identify platform
        if ($target -like '*Win*' -and -not $windows) {
            continue
        } elseif ($target -like '*Mac*' -and -not $mac) {
            continue
        }

        # Source folder is the actual source of data
        $sourcefolder = Get-Build-Full-Path -builddir:$config.BuildDir -version:$version -target:$target -steam:$true -development:$false

        $depotid = $config.SteamDepotsByTarget[$target];
        # Build a single depot file
        $depotfilerel = "depot_${target}_${depotid}.vdf"
        $depotfile = "$rootfolder\$depotfilerel"
        Write-Output "Creating depot build config $depotfile"
        Remove-Item $depotfile -Force -ErrorAction SilentlyContinue
        $depotfp = New-Object -TypeName System.IO.FileStream(
            $depotfile,
            [System.IO.FileMode]::Create,
            [System.IO.FileAccess]::Write)
        $depotstream = New-Object System.IO.StreamWriter($depotfp, [System.Text.Encoding]::UTF8)
        $depotstream.WriteLine("`"DepotBuildConfig`"")
        $depotstream.WriteLine("{")
        $depotstream.WriteLine("    `"DepotID`" `"$depotid`"")
        # We'll set ContentRoot specifically for
        $depotstream.WriteLine("    `"ContentRoot`" `"$sourcefolder`"")
        $depotstream.WriteLine("    `"FileMapping`"")
        $depotstream.WriteLine("    {")
        $depotstream.WriteLine("        `"LocalPath`" `"*`"")
        $depotstream.WriteLine("        `"DepotPath`" `".`"")
        $depotstream.WriteLine("        `"recursive`" `"1`"")
        $depotstream.WriteLine("    }")
        $depotstream.WriteLine("    `"FileExclusion`" `"*.pdb`"")
        $depotstream.WriteLine("}")
        $depotstream.Close()
        $depotfp.Close()

        # Now write depot entry to in-progress app file, relative file (same folder)
        $appstream.WriteLine("        `"$depotid`" `"$depotfilerel`"")

    }

    $appstream.WriteLine("    }")
    $appstream.WriteLine("}")
    $appstream.Close()

    if (-not $dryrun) {
        Write-Output "Releasing version $version to Steam ($($config.SteamAppId))"
        steamcmd +login $($config.SteamLogin) +run_app_build_http $appfile +quit
        Write-Output "Steam Upload Done!"
        Write-Output "-- Remember to release this file in Steamworks Admin --"
    } else {
        Write-Output "dryrun: Would have run Steam command:"
        Write-Output "  steamcmd +login $($config.SteamLogin) +run_app_build_http $appfile +quit"
    }

}