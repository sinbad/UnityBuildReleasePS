# Our config for both building and releasing
class BuildConfig {
    # The root of the folder structure which will contain build output
    # Will be structured $BuildDir/$version/[general|steam]/$target
    # If relative, will be considered relative to source folder
    [string]$BuildDir
    # Folder to place zipped releases
    # If relative, will be considered relative to source folder
    [string]$ReleaseDir
    # Array of targets (strings), each must match and entry in enum MultiBuild.Target
    [array]$Targets
    # Location of AssemblyInfo.cs containing version number, relative to source folder
    [string]$AssemblyInfo

    # Itch config, only needed if releasing to Itch
    # Itch app id, of the form "owner/appname"
    [string]$ItchAppId
    # Maps each target to an Itch channel name
    [hashtable]$ItchChannelByTarget

    # Steam config, only needed if releasing to Steam
    # Steam application id, will be a 6-digit number (or 7 eventually)
    [string]$SteamAppId
    # Map of target to depot ID (only 1 depot supported per target right now)
    [hashtable]$SteamDepotsByTarget
    # Steam login name (if you haven't cached your credential already you'll get a login prompt)
    [string]$SteamLogin
}

# Load a buildconfig.json file from a source location and return BuildConfig instance
function Load-Build-Config {
    param (
        [string]$srcfolder
    )

    if ($srcfolder.Length -eq 0) {
        $srcfolder = "."
        Write-Verbose "-src not specified, assuming current directory"
    }

    $configfile = Resolve-Path "$srcfolder\buildconfig.json"
    if (-not (Test-Path $configfile -PathType Leaf)) {
        throw "$srcfolder\buildconfig.json does not exist!"
    }

    $obj = (Get-Content $configfile) | ConvertFrom-Json

    $ret = New-Object BuildConfig
    if ([System.IO.Path]::IsPathRooted($obj.BuildDir)) {
        $ret.BuildDir = Resolve-Path $obj.BuildDir
    } else {
        $ret.BuildDir = Resolve-Path "$srcfolder/$($obj.BuildDir)"
    }

    if ([System.IO.Path]::IsPathRooted($obj.ReleaseDir)) {
        $ret.ReleaseDir = Resolve-Path $obj.ReleaseDir
    } else {
        $ret.ReleaseDir = Resolve-Path "$srcfolder/$($obj.ReleaseDir)"
    }
    $ret.Targets = $obj.Targets
    $ret.AssemblyInfo = $obj.AssemblyInfo
    $ret.ItchAppId = $obj.ItchAppId
    # Have to convert from PSCustomObject to hashtable
    $ret.ItchChannelByTarget = @{}
    $obj.ItchChannelByTarget.psobject.properties | ForEach-Object { $ret.ItchChannelByTarget[$_.Name] = $_.Value  }
    $ret.SteamAppId = $obj.SteamAppId
    $ret.SteamDepotsByTarget = @{}
    $obj.SteamDepotsByTarget.psobject.properties | ForEach-Object { $ret.SteamDepotsByTarget[$_.Name] = $_.Value  }
    $ret.SteamLogin = $obj.SteamLogin

    return $ret
}
