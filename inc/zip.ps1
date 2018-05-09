function Zip-Release {
    param (
    [string]$sourceDir,
    [string]$destFile
    )


    # While we could use zipfile from system.io.compression.filesystem, this
    # uses Windows-style path separators all the time! Fixed in CLR 4.6.1 but
    # default Powershell can't access this, PITA. Let's just use the 7z command

    $tempdest =  [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName() + ".zip"
    $zipargs = "a `"$tempdest`" $sourcedir\*"

    try {
        7z a "$tempdest" "$sourcedir\*"
    }
    catch {
        Remove-Item $tempdest -Force
        throw
    }

    # If successful, move into final location
    if (Test-Path $destFile) {
        Remove-item $destFile
    }
    Move-Item $tempdest $destFile
}