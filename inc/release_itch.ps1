. "$PSScriptRoot\pathutils.ps1"

function Release-Itch {
    param (
        [BuildConfig]$config,
        [string]$version,
        [bool]$windows = $true,
        [bool]$mac = $true,
        [switch]$dryrun = $false
    )

    foreach ($target in $config.Targets) {
        if ($target -like '*Win*' -and -not $windows) {
            continue
        } elseif ($target -like '*Mac*' -and -not $mac) {
            continue
        }

        $channel = $config.ItchChannelByTarget[$target]

        $sourcefolder = Get-Build-Full-Path -config:$config -version:$version -target:$target -steam:$false -development:$false

        if (-not (Test-Path "$sourcefolder" -PathType Container)) {
            if ($dryrun) {
                Write-Output "ERROR: Missing build path $sourcefolder"
                Write-Output "  (Continuing because -dryrun)"
            } else {
                throw "Missing build path $sourcefolder"
            }
        }

        if ($dryrun) {
            Write-Output "dryrun: Would have run butler command:"
            Write-Output "  butler push --userversion=$version '$sourcefolder' $($config.ItchAppId):$channel"
        } else {
            Write-Output "Releasing version $version to Itch.io at $($config.ItchAppId):$channel"
            Write-Output " Source: $sourcefolder"

            butler push --userversion=$version "$sourcefolder" $($config.ItchAppId)S:$channel
            Write-Output "Itch.io Release Done!"
        }
    }

}