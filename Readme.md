# Unity Powershell Scripts for Batch Build & Release

This is a set of Powershell scripts I wrote for our Unity game which allows us
to build multiple configurations easily, and to release to Steam and Itch
repeatably.

## Build tool

The **build** tool performs a number of tasks:

1. Increments the version number
2. Tags the git repo
3. Builds the combination of variants in one go:
   * Multiple platform targets
   * Development mode
   * Different #define modes (currently just used to enable/disable Steam specific code)
4. Places output in sensible version-and-variant labelled folders
5. Protects you from silly mistakes e.g. forgetting to build from a clean copy

```
Old Doorways Unity Build Tool
Usage:
  build.ps1 [-src:sourcefolder] [-major|-minor|-patch|-hotfix] [-keepversion] [-force] [-devonly] [-prodonly] [-skipsteam] [-test] [-dryrun]

  -src         : Source folder (current folder if omitted), must contain buildconfig.json
  -major       : Increment major version i.e. [x++].0.0.0
  -minor       : Increment minor version i.e. x.[x++].0.0
  -patch       : Increment patch version i.e. x.x.[x++].0
  -hotfix      : Increment hotfix version i.e. x.x.x.[x++]
               : (-patch is assumed if none are supplied)
  -keepversion : Keep current version number
  -force       : Move version tag
  -devonly     : Build development version only (builds both otherwise)
  -prodonly    : Build production version only (builds both otherwise)
  -skipsteam   : Skip the Steam build
  -test        : Testing mode, don't fail on dirty working copy etc
  -dryrun      : Don't perform any actual actions, just report what would happen
  -help        : Print this help
```

## Release tool

The **release** tool automates uploading builds to Steam and Itch.io:

```
Old Doorways Release Tool
Usage:
  release.ps1 [-src:sourcefolder] -version:ver -service:svc [-windows:bool] [-mac:bool] [-dryrun]

  -src         : Source folder (current folder if omitted), must contain buildconfig.json
  -version:ver : Version to release
  -service:svc : 'steam' or 'itch'
  -windows:b   : Whether to release for Windows (default true)
  -mac:b       : Whether to release for Mac (default true)
  -dryrun      : Don't perform any actual actions, just report what would happen
  -help        : Print this help
```

## Requirements

1. Unity project using 2017.3 or newer
2. [Multibuild](https://github.com/sinbad/UnityMultiBuild) installed - this tool
   uses its batch mode for simplicity
3. Powershell v5.1+ installed
4. `powershell-yaml` installed (`Install-Module powershell-yaml`)
5. Steamworks SDK installed if you're releasing to Steam
6. Itch.io's `butler` tool installed if you're releasing to Itch

## How to use

1. Place the contents of this folder anywhere you like
2. Make sure you have [Multibuild](https://github.com/sinbad/UnityMultiBuild) in
   your project assets
3. Place a file called `buildconfig.json` in your Unity project root, see `buildconfig_template.json`, see below for more discussion
4. Run `build.ps1` or `release.ps1` as above, use `-help` to get assistance
    * Ideally, add the folder containing `build.ps1` to your `PATH` and run from inside your Unity project root folder
    * Alternatively, pass `-src:\path\to\unity\project` to both scripts to run from anywhere


## Build Config

The build config file is just a JSON file telling the tools how to behave. There
is a template in `buildconfig_template.json`, and the meaning of the properties
is as follows:

* **UnityExe**: Path to Unity.exe, defaults to "C:\Program Files\Unity\Editor\Unity.exe"
* **BuildDir**: Path to the location in which build output will be produced.
  It can be relative, in which case it is relative to the Unity project folder.
  * Subdirectories will be created while building, of the form {BuildDir}/{version}/{general|steam}/{target}/
* **ReleaseDir**: Path to the folder where zipped release versions will be created
* **Targets**: Array of strings of targets to build. These must match the enum names of [`MultiBuild.Target`](https://github.com/sinbad/UnityMultiBuild/blob/866b2bb2d2d816e6244b7df5f33335df425f1802/Assets/MultiBuild/Editor/Settings.cs#L9), e.g. "Mac64"
* **AssemblyInfo**: Path to the AssemblyInfo.cs file containing the version number.
  This will be updated when bumping the version number
* **DefinesAlways**: Set global `#define`s applied to all builds (semicolon separated)
* **DefinesDevMode**:  Additional global `#define`s when building in Development mode
* **DefinesNonDevMode**: Addition global `#define`s when building in non-Development mode
* **DefinesSteam**:  Additional global `#define`s when building for Steam
* **DefinesNonSteam**: Addition global `#define`s when building for Itch or general use
* **ItchAppId**: The id of your application at [Itch.io](https://itch.io) if you're releasing there
* **ItchChannelByTarget**: Dictionary mapping the target names specified previously to Itch.io channel names
* **SteamAppId**: The ID of your app on Steam if you're releasing there
* **SteamDepotsByTarget**: A dictionary mapping target names to Depot IDs in Steam.
  Currently only 1 depot per target is supported (1 per platform)
* **SteamLogin**: The login name you'll use to upload to Steam

## Current Assumptions

I built this tool for myself so it's not entirely general purpose. It contains
some useful functionality you could probably adapt to work a bit differently if
you wanted. Here are the major assumptions:

### Global preprocessor defines (IMPORTANT)

To globally set `#define` entries which apply across all files in Unity, these
scripts replace the `scriptingDefineSymbols` setting in
`.\ProjectSettings\ProjectSettings.asset`. You can set what these definitions will
be using the `Defines*` settings listed above.

However it does mean that if you've already set the Scripting Define Symbols
yourself in the Unity editor, you need to migrate those settings to the
`Define*` settings in `buildconfig.json`, because they will be replaced during
the build (although reverted afterwards). It's simply easier to completely
replace these settings than to try to merge them with Editor changes, since you
might have just been experimenting ad-hoc in the editor.

### Production and development builds

This tool will by default built a version of the game in Unity's "development mode"
and a version without this set. We have various debug options enabled in development
builds in our game (replay functionality, triggering events manually etc) which
are excluded in production mode. You can choose to build one or other variant
with the `-prodonly` and `-devonly` options to `build.ps1`

Only the non-development builds are considered for release to Itch.io and Steam.

### Steam is its own build config

There are 2 build variants of each target, "steam" and "general". The "steam"
variant is built with the defines set in **DefinesSteam**, and the "general" variant is
built with the defines set in **DefinesNonSteam**.

The "general" build variant is used for internal testing (and has a -dev variant)
and Itch.io.

### Steam depots are 1:1 with targets

Right now each target (e.g. Mac64, Win32) only has a single Steam Depot ID
associated with it. This is probably too limiting for larger projects but it
was all I needed right now. PRs welcome!

Probably the **SteamDepotsByTarget** setting should be a hashtable to array of
Depot IDs instead, and the release script should write a file for each unique
Depot ID across all targets. However since I don't have a real-world use of this
yet I haven't attempted to do that.

### Zipped local builds

After building, the "general" variants (including development mode) are zipped
up and placed in a version-named file (with a `-dev` suffix for development mode)
in the **ReleaseDir** you set in your `buildconfig.json`.

These are just handy for internal testing, particularly the `-dev` variants.






