function Zip-Release {
    param (
    [string]$sourceDir,
    [string]$destFile
    )


    # While we could use zipfile from system.io.compression.filesystem, this
    # uses Windows-style path separators all the time! Fixed in CLR 4.6.1 but
    # default Powershell can't access this, PITA. Let's just use the 7z command

    $tempdest =  [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName() + ".zip"
    $zip = get-command 7z
    $zipargs = "a `"$tempdest`" $sourcedir\*"

    try {
        $process = (Start-Process $zip -ArgumentList $zipargs)
        if ($process.ExitCode -ne 0) {
            $code = $process.ExitCode
            throw "Failed to compress, 7z exited with code $code, see above"
        }
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