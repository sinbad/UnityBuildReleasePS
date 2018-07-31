. $PSScriptRoot\buildconfig.ps1

# Return build path for version/steam/dev, targets will be subdirs
function Get-Build-Base-Path {
    param (
        [string]$builddir,
        [string]$version,
        [bool]$steam,
        [bool]$development
    )
    $steamornot = if ($steam) { "steam" } else { "general" }
    $devsuffix = if ($development) { "-dev" } else { "" }
    return "$buildDir\$version$devsuffix\$steamornot"
}

# Return output build path including target
function Get-Build-Full-Path {
    param (
        [string]$builddir,
        [string]$target,
        [string]$version,
        [bool]$steam,
        [bool]$development
    )

    $base = Get-Build-Base-Path -builddir:$builddir -version:$version -steam:$steam -development:$development
    return "$base\$target"

}

# Return output full binary file path, the folder where the executable is
function Get-Build-Full-Binary-Folder-Path {
    param (
        [string]$builddir,
        [string]$productName,
        [string]$target,
        [string]$version,
        [bool]$steam,
        [bool]$development
    )

    $ret = Get-Build-Full-Path -builddir:$builddir -target:$target -version:$version -steam:$steam -development:$development

    if ($target.StartsWith("Mac")) {
        $ret = "$ret\$($productName).app\Contents\MacOS"
    }
    return $ret

}
