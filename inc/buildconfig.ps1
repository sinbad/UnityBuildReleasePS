# Our config for both building and releasing
class BuildConfig {
    # The location of the Unity exe, defaults to C:\Program Files\Unity\Editor\Unity.exe
    [string]$UnityExe
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
    # Global defines which are always included
    [string]$DefinesAlways
    # Global defines which are only included in development builds
    [string]$DefinesDevMode
    # Global defines which are only included in non-development builds
    [string]$DefinesNonDevMode
    # Global defines which are only included in Steam builds
    [string]$DefinesSteam
    # Global defines which are only included in non-Steam builds
    [string]$DefinesNonSteam

    # Whether to build for Steam
    [bool]$BuildSteam = $true
    # Whether to build non-Steam
    [bool]$BuildNonSteam = $true

    # Whether to build a dev variant of Steam build
    [bool]$BuildSteamDevMode = $false
    # Whether to build a dev variant of non-Steam build
    [bool]$BuildNonSteamDevMode = $true

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

    $configfile = Resolve-Path "$srcfolder\buildconfig.json"
    if (-not (Test-Path $configfile -PathType Leaf)) {
        throw "$srcfolder\buildconfig.json does not exist!"
    }

    $obj = (Get-Content $configfile) | ConvertFrom-Json

    $ret = [BuildConfig]::New()
    if ($obj.UnityExe.Length -eq 0) {
        $ret.UnityExe = "C:\Program Files\Unity\Editor\Unity.exe"
    } else {
        $ret.UnityExe = $obj.UnityExe
    }
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
    $ret.DefinesAlways = $obj.DefinesAlways
    $ret.DefinesDevMode = $obj.DefinesDevMode
    $ret.DefinesNonDevMode = $obj.DefinesNonDevMode
    $ret.DefinesSteam = $obj.DefinesSteam
    $ret.DefinesNonSteam = $obj.DefinesNonSteam
    $ret.ItchAppId = $obj.ItchAppId
    $ret.BuildSteamDevMode = $obj.BuildSteamDevMode
    $ret.BuildNonSteamDevMode = $obj.BuildNonSteamDevMode
    $ret.BuildSteam = $obj.BuildSteam
    $ret.BuildNonSteam = $obj.BuildNonSteam

    # Have to convert from PSCustomObject to hashtable
    $ret.ItchChannelByTarget = @{}
    $obj.ItchChannelByTarget.psobject.properties | ForEach-Object { $ret.ItchChannelByTarget[$_.Name] = $_.Value  }
    $ret.SteamAppId = $obj.SteamAppId
    $ret.SteamDepotsByTarget = @{}
    $obj.SteamDepotsByTarget.psobject.properties | ForEach-Object { $ret.SteamDepotsByTarget[$_.Name] = $_.Value  }
    $ret.SteamLogin = $obj.SteamLogin

    return $ret
}
