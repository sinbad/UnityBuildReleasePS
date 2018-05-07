# enable -major or -minor, or defaults to incrementing patch

function Bump-Version {

    param (
        [string]$asmfile,
        [bool]$major,
        [bool]$minor,
        [bool]$patch,
        [bool]$hotfix,
        [bool]$dryrun = $false
        )

    if (($major + $minor + $patch + $hotfix) -gt 1) {
        throw "Can't set more than one of major/minor/patch/hotfix at the same time!"
    }

    Write-Verbose "[bumpver] M:$major m:$minor p:$patch h:$hotfix"

    # We have to use Write-Verbose now that we're using the return value, Write-Output
    # appends to the return value. Write-Verbose works but doesn't appear by default
    # Unless user sets $VerbosePreference="Continue"

    # Bump the version number of the build
    Write-Verbose "[bumpver] Updating $asmfile"

    $regex = "\[assembly: AssemblyVersion\(`"(\d+)\.(\d+)\.(\d+)\.(\d+)`"\)\]"
    $matches = Select-String -Path "$asmfile" -Pattern $regex
    if (($matches.Matches.Count -gt 0) -and ($matches.Matches[0].Groups.Count -eq 5)) {
        [int]$maj = [int]$matches.Matches[0].Groups[1].Value
        [int]$min = [int]$matches.Matches[0].Groups[2].Value
        [int]$pat = [int]$matches.Matches[0].Groups[3].Value
        [int]$hf = [int]$matches.Matches[0].Groups[4].Value

        Write-Verbose "[bumpver] Current version is $maj.$min.$pat.$hf"

        if ($major) {
            $maj = $maj + 1
            $min = 0
            $pat = 0
            $hf = 0

        } elseif ($minor) {
            $min = $min + 1
            $pat = 0
            $hf = 0
        } elseif ($patch) {
            $pat = $pat + 1
            $hf = 0
        } else {
            $hf = $hf + 1
        }
        $newver = "$maj.$min.$pat.$hf"
        Write-Verbose "[bumpver] Bumping version to $newver"

        $origline = $matches.Matches[0].Value
        $newline = "[assembly: AssemblyVersion(`"$newver`")]"
        if ($dryrun) {
            Write-Verbose "[bumpver] dryrun: not changing $asmfile"
        } else {
            (Get-Content "$asmfile").replace($origline, $newline) | Set-Content "$asmfile"
            Write-Verbose "[bumpver] Success! Version is now $newver"
        }

        return "$newver"

    } else {
        throw "Unable to read current version"
    }
}

function GetVersion {
    param (
        [string]$asmfile
    )

    $regex = "\[assembly: AssemblyVersion\(`"(\d+\.\d+\.\d+\.\d+)`"\)\]"
    $matches = Select-String -Path "$asmfile" -Pattern $regex
    if (($matches.Matches.Count -gt 0) -and ($matches.Matches[0].Groups.Count -eq 2)) {
        return [string]$matches.Matches[0].Groups[1].Value
    } else {
        throw "Unable to read current version"
    }

}


