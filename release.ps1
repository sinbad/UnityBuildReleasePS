[CmdletBinding()] # Fail on unknown args
param (
    [string]$src,
    # Version to release
    [string]$version,
    # Which service to release on: provide "steam" or "itch"
    [string]$service,
    # Whether to release Windows build (default yes)
    [bool]$windows = $true,
    # Whether to release Mac build (default yes)
    [bool]$mac = $true,
    # Dry-run; does nothing but report what *would* have happened
    [switch]$dryrun = $false,
    [switch]$help = $false
)

. $PSScriptRoot\inc\release_steam.ps1
. $PSScriptRoot\inc\release_itch.ps1

function Print-Usage {
    Write-Output "Old Doorways Release Tool"
    Write-Output "Usage:"
    Write-Output "  release.ps1 [-src:sourcefolder] -version:ver -service:svc [-windows:bool] [-mac:bool] [-dryrun]"
    Write-Output " "
    Write-Output "  -src         : Source folder (current folder if omitted), must contain buildconfig.json"
    Write-Output "  -version:ver : Version to release"
    Write-Output "  -service:svc : 'steam' or 'itch'"
    Write-Output "  -windows:b   : Whether to release for Windows (default true)"
    Write-Output "  -mac:b       : Whether to release for Mac (default true)"
    Write-Output "  -dryrun      : Don't perform any actual actions, just report what would happen"
    Write-Output "  -help        : Print this help"
}

$ErrorActionPreference = "Stop"

if ($help) {
    Print-Usage
    Exit 0
}

# Import config
. $PSScriptRoot\inc\buildconfig.ps1
$config = Load-Build-Config -srcfolder:$src

if ($version.Length -eq 0) {
    Write-Output "Version is mandatory"
    Print-Usage
    Exit 5
}

if ($service -ne "steam" -and $service -ne "itch") {
    Write-Output "Service must be one of 'steam' or 'itch'"
    Print-Usage
    Exit 5
}

try {
    if ($service -eq "steam") {
        Release-Steam -config:$config -version:$version -windows:$windows -mac:$mac -dryrun:$dryrun
    } elseif ($service -eq "itch") {
        Release-Itch -config:$config -version:$version -windows:$windows -mac:$mac -dryrun:$dryrun
    }
} catch {
    Write-Output $_.Exception.Message
    Exit 9
}

