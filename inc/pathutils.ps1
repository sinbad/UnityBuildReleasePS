# Return build path for version/steam/dev, targets will be subdirs
function Get-Build-Base-Path {
    param (
        [BuildConfig]$config,
        [string]$version,
        [bool]$steam,
        [bool]$development
    )
    $steamornot = if ($steam) { "steam" } else { "general" }
    $devsuffix = if ($development) { "-dev" } else { "" }
    return "$($config.BuildDir)\$version$devsuffix\$steamornot"
}

# Return output build path including target
function Get-Build-Full-Path {
    param (
        [BuildConfig]$config,
        [string]$target,
        [string]$version,
        [bool]$steam,
        [bool]$development
    )

    $base = Get-Build-Base-Path -config:$config -version:$version -steam:$steam -development:$development
    return "$base\$target"

}