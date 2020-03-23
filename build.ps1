# Defaults to building a patch release, which increments the 3rd build number
[CmdletBinding()] # Fail on unknown args
param (
    [string]$src,
    [switch]$major = $false,
    [switch]$minor = $false,
    [switch]$patch = $false,
    [switch]$hotfix = $false,
    # -keepversion means version number stays the same but tag is moved (if not -test, requires -force)
    [switch]$keepversion = $false,
    # Ignore production warnings
    [switch]$force = $false,
    # Build for development only, not production
    [switch]$devonly = $false,
    # Build for production only, not production
    [switch]$prodonly = $false,
    # Skip build for Steam (included by default)
    [switch]$skipsteam = $false,
    # Testing mode; skips clean checks, tags, puts output in builddir
    [switch]$test = $false,
    # Dry-run; does nothing but report what *would* have happened
    [switch]$dryrun = $false,
    [switch]$help = $false
)

# Import utils
# For some reason we have to import powershell-yaml here and not in inc\yamlutil.ps1
# Doing the latter modifies the $PSScriptRoot to the inc\ subfolder & messes everything up
# on the first run only
# I have no idea if this is a bug in the module or expected behaviour
Import-Module powershell-yaml
. $PSScriptRoot\inc\buildtarget.ps1
. $PSScriptRoot\inc\buildconfig.ps1
. $PSScriptRoot\inc\pathutils.ps1
. $PSScriptRoot\inc\bumpversion.ps1
. $PSScriptRoot\inc\zip.ps1

function Print-Usage {
    Write-Output "Old Doorways Unity Build Tool"
    Write-Output "Usage:"
    Write-Output "  build.ps1 [-src:sourcefolder] [-major|-minor|-patch|-hotfix] [-keepversion] [-force] [-devonly] [-prodonly] [-skipsteam] [-test] [-dryrun]"
    Write-Output " "
    Write-Output "  -src         : Source folder (current folder if omitted), must contain buildconfig.json"
    Write-Output "  -major       : Increment major version i.e. [x++].0.0.0"
    Write-Output "  -minor       : Increment minor version i.e. x.[x++].0.0"
    Write-Output "  -patch       : Increment patch version i.e. x.x.[x++].0"
    Write-Output "  -hotfix      : Increment hotfix version i.e. x.x.x.[x++]"
    Write-Output "               : (-patch is assumed if none are supplied)"
    Write-Output "  -keepversion : Keep current version number"
    Write-Output "  -force       : Move version tag"
    Write-Output "  -devonly     : Build development version only (builds both otherwise)"
    Write-Output "  -prodonly    : Build production version only (builds both otherwise)"
    Write-Output "  -skipsteam   : Skip the Steam build"
    Write-Output "  -test        : Testing mode, don't fail on dirty working copy etc"
    Write-Output "  -dryrun      : Don't perform any actual actions, just report on what you would do"
    Write-Output "  -help        : Print this help"
}

if ($src.Length -eq 0) {
    $src = "."
    Write-Verbose "-src not specified, assuming current directory"
}

# Import config
$config = Load-Build-Config -srcfolder:$src

$ErrorActionPreference = "Stop"

if ($help) {
    Print-Usage
    Exit 0
}

# Override release dir if test mode
if ($test) {
    Write-Output "TEST MODE: Output archives will be in $($config.BuildDir)"
    $config.ReleaseDir = $config.BuildDir
}


if (([bool]$major + [bool]$minor + [bool]$patch + [bool]$hotfix) -gt 1) {
    Write-Output "ERROR: Can't set more than one of major/minor/patch/hotfix at the same time!"
    Print-Usage
    Exit 5
}
if (($major -or $minor -or $patch -or $hotfix) -and $keepversion) {
    Write-Output  "ERROR: Can't set keepversion at the same time as major/minor/patch/hotfix!"
    Print-Usage
    Exit 5
}
if ($devonly -and $prodonly) {
    Write-Output  "ERROR: Cannot set both -devonly or -prodonly"
    Print-Usage
    Exit 5
}

if ($keepversion -and -not $devonly -and -not $force -and -not $test) {
    Write-Output "Keeping the current version for production will not update properly for users!"
    Write-Output "Aborting; you can override with -force but BE SURE YOU HAVEN'T RELEASED"
    Exit 5
}

# Close Unity as early as possible; sometimes Unity can write some files on close
## and we need to check for modifications after that
if (-not $dryrun) {
    # Check if Unity is running, if so try to shut it gracefully
    $unityproc = Get-Process Unity -ErrorAction SilentlyContinue
    if ($unityproc) {
        Write-Output "Unity is currently running, trying to gracefully shut window "
        $unityproc.CloseMainWindow()
        Sleep 5
        if (!$unityproc.HasExited) {
            throw "Couldn't close Unity gracefully, aborting!"
        }
    }
    Remove-Variable unityproc
}


# Check working copy is clean
if (-not $test) {
    if ($src -ne ".") { Push-Location $src }
    git diff --no-patch --exit-code
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Working copy is not clean (unstaged changes)"
        if ($dryrun) {
            Write-Output "dryrun: Continuing but this will fail without -dryrun"
        } else {
            Exit $LASTEXITCODE
        }
    }
    git diff --no-patch --cached --exit-code
    if ($LASTEXITCODE -ne 0) {
        Write-Output "Working copy is not clean (staged changes)"
        if ($dryrun) {
            Write-Output "dryrun: Continuing but this will fail without -dryrun"
        } else {
            Exit $LASTEXITCODE
        }
    }
    if ($src -ne ".") { Pop-Location }
}

# Don't need the serial if not using advanced features
# if ([string]::IsNullOrEmpty($Env:UNITY_SERIAL)) {
#     Write-Output "You must set the UNITY_SERIAL environment variable"
#     Exit 3
# }

Write-Output ""
Write-Output "Build configuration:"
Write-Output $config

try {
    if (([bool]$major + [bool]$minor + [bool]$patch + [bool]$hotfix) -eq 0) {
        $patch = $true
    }
    $mainver = $null
    $asmfile = Resolve-Path "$src\$($config.AssemblyInfo)"
    if ($keepversion) {
        $mainver = GetVersion -asmfile:$asmfile
    } else {
        # Bump up version, passthrough options
        try {
            $mainver = Bump-Version -asmfile:$asmfile -major:$major -minor:$minor -patch:$patch -hotfix:$hotfix -dryrun:$dryrun
            if (-not $dryrun) {
                if ($src -ne ".") { Push-Location $src }

                git add "$($config.AssemblyInfo)"
                if ($LASTEXITCODE -ne 0) { Exit $LASTEXITCODE }
                git commit -m "Version bump"
                if ($LASTEXITCODE -ne 0) { Exit $LASTEXITCODE }

                if ($src -ne ".") { Pop-Location }
            }
        }
        catch {
            Write-Output $_.Exception.Message
            Exit 6
        }
    }
    if ($test) {
        $mainver = "$mainver-test"
    }
    Write-Output "Next version will be: $mainver"

    # For tagging release
    # We only need to grab the main version once
    $forcearg = ""
    if ($keepversion) {
        $forcearg = "-f"
    }
    if (-not $test -and -not $dryrun) {
        if ($src -ne ".") { Push-Location $src }
        git tag $forcearg -a $mainver -m "Automated release tag"
        if ($LASTEXITCODE -ne 0) { Exit $LASTEXITCODE }
        if ($src -ne ".") { Pop-Location }
    }

    # Determine the types of build to make
    class Build {
        [bool]$development
        [bool]$steam
    }
    $builds = New-Object System.Collections.ArrayList

    if (-not $devonly) {
        if ($config.BuildNonSteam) {
            $builds.Add([Build]@{
                development=$false
                steam=$false
            }) > $null
        }
        if ($config.BuildSteam -and -not $skipsteam) {
            $builds.Add([Build]@{
                development=$false
                steam=$true
            }) > $null
        }
    }
    if (-not $prodonly) {
        if ($config.BuildNonSteam -and $config.BuildNonSteamDevMode) {
            $builds.Add([Build]@{
                development=$true
                steam=$false
            }) > $null
        }
        if ($config.BuildSteam -and $config.BuildSteamDevMode -and -not $skipsteam) {
            $builds.Add([Build]@{
                development=$true
                steam=$true
            }) > $null
        }
    }

    foreach ($bld in $builds) {

        Build-Targets -src:$src -config:$config -version:$mainver -targets:$config.Targets -steam:$bld.steam -development:$bld.development -dryrun:$dryrun

        # Zip up direct/general resources or steam dev mode
        if ($bld.steam -eq $false -or $bld.development) {
            $steamsuffix = if ($bld.steam) { "-steam" } else { "" }
            $devsuffix = if ($bld.development) { "-dev" } else { "" }
            foreach ($target in $config.Targets) {
                $dest = "$($config.ReleaseDir)\WashedUp-$mainver-$target$steamsuffix$devsuffix.zip"
                $targetdir = Get-Build-Full-Path -builddir:$config.BuildDir -version:$mainver -target:$target -steam:$bld.steam -development:$bld.development

                # Compress
                if (-not $dryrun) {
                    Write-Output "Zipping to $dest..."
                    Zip-Release -sourceDir:"$targetdir" -destFile:$dest
                } else {
                    Write-Output "dryrun: Would zip $targetdir to $dest"
                }
            }
        }
    }


}
catch {
    Write-Output $_.Exception.Message
    Exit 9
}
