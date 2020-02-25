[CmdletBinding()] # Fail on unknown args
param (
    # Version to release
    [string]$version,
    # Which service to release on: provide "steam" or "itch"
    [string]$service,
    # Unity source folder (assumes current dir if not specified)
    [string]$src,
    # Whether to release Windows build (default yes)
    [bool]$windows = $true,
    # Whether to release Mac build (default yes)
    [bool]$mac = $true,
    # Whether to release Linux build (default true)
    [bool]$linux = $true,
    # Dry-run; does nothing but report what *would* have happened
    [switch]$dryrun = $false,
    [switch]$help = $false
)

. $PSScriptRoot\inc\buildconfig.ps1
. $PSScriptRoot\inc\release_steam.ps1
. $PSScriptRoot\inc\release_itch.ps1

function Print-Usage {
    Write-Output "Old Doorways Release Tool"
    Write-Output "Usage:"
    Write-Output "  release.ps1 -version:ver -service:svc [-src:sourcefolder] [-windows:bool] [-mac:bool] [-dryrun]"
    Write-Output " "
    Write-Output "  -version:ver : Version to release"
    Write-Output "  -service:svc : 'steam' or 'itch'"
    Write-Output "  -src         : Source folder (current folder if omitted), must contain buildconfig.json"
    Write-Output "  -windows:b   : Whether to release for Windows (default true)"
    Write-Output "  -mac:b       : Whether to release for Mac (default true)"
    Write-Output "  -linux:b     : Whether to release for Linux (default false)"
    Write-Output "  -dryrun      : Don't perform any actual actions, just report what would happen"
    Write-Output "  -help        : Print this help"
}

$ErrorActionPreference = "Stop"

if ($help) {
    Print-Usage
    Exit 0
}

if ($src.Length -eq 0) {
    $src = "."
    Write-Verbose "-src not specified, assuming current directory"
}

# Import config
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
        Release-Steam -config:$config -version:$version -windows:$windows -mac:$mac -linux:$linux -dryrun:$dryrun
    } elseif ($service -eq "itch") {
        Release-Itch -config:$config -version:$version -windows:$windows -mac:$mac -linux:$linux -dryrun:$dryrun
    }
} catch {
    Write-Output $_.Exception.Message
    Exit 9
}

