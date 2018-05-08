. $PSScriptRoot\yamlutil.ps1

# Builds specified targets (Win32, Mac64 etc) with deploy/dev switches
function Build-Targets {

    param (
        [string]$src,
        [BuildConfig]$config,
        [string]$version,
        [array]$targets,
        [bool]$steam,
        [switch]$development = $false,
        [switch]$dryrun = $false
    )

    $basedir = Get-Build-Base-Path -config:$config -version:$version -steam:$steam -development:$development
    $deploydesc = if ($steam) { "Steam"} else { "General" }
    if ($development) {
        if ($dryrun) {
            Write-Output "dryrun: Would build $targets in Development mode for $deploydesc"
        } else {
            Write-Output "Building $targets in Development mode for $deploydesc"
        }
    } else {
        if ($dryrun) {
            Write-Output "dryrun: Would build $targets in Production mode for $deploydesc"
        } else {
            Write-Output "Building $targets in Production mode for $deploydesc"
        }
    }

    if ($steam) {
        $defines = "ENABLE_UBERLOGGING_ERRORS;STEAM_BUILD"
    } else {
        $defines = "ENABLE_UBERLOGGING_ERRORS;DISABLESTEAMWORKS"
    }


    if (-not $dryrun) {
        Write-Output "Setting #defines to $defines"
        $projfile = "$src\ProjectSettings\ProjectSettings.asset"
        # YAML parser requires CRLF and ProjectSettings.asset is LF because crlf-auto doesn't match
        $settings = Yaml-Load $projfile -convertFromLF $true
        # We can't use Yaml-Save to overwrite this since Unity uses its own YAML
        # headers and seems to hate it when things are re-encoded. Just use
        # this parsed version to efficiently swap in-place
        $olddefines = $settings["PlayerSettings"]["scriptingDefineSymbols"]["1"]

        $content = Get-Content -Path $projfile -Raw
        $content = $content.Replace($olddefines, $defines)
        Set-Content -Value $content -Path $projfile -Force -NoNewline

    } else {
        Write-Output "dryrun: Would set #defines to $defines"
    }

    # Unity location
    $unity = 'C:\Program Files\Unity\Editor\Unity.exe'

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

    $func = "MultiBuild.Builder.BuildCommandLine"

    $isdev = if ($development) { "true" } else { "false" }
    $cmdargs = "-projectPath `"$src`" -quit -batchmode -executeMethod $func `"$basedir`" $isdev $($targets -join `" `")"

    mkdir "$basedir" -ErrorAction SilentlyContinue > $null

    if (-not $dryrun) {
        # Remove previous builds
        foreach ($target in $targets) {
            $dir = Get-Build-Full-Path -config:$config -version:$version -target:$target -steam:$steam -development:$development
            Remove-Item "$dir" -Recurse -Force -ErrorAction SilentlyContinue
        }

        $process = (Start-Process $unity -ArgumentList $cmdargs -PassThru -Wait)
        if ($process.ExitCode -ne 0) {
            $code = $process.ExitCode
            throw "*** Unity exited with code $code, see above"
        }

        # Restore project settings
        Push-Location $src
        git checkout ./ProjectSettings/ProjectSettings.asset
        Pop-Location
    }

}
