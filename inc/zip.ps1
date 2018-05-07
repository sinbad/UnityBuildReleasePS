function Zip-Release {
    param (
    [string]$sourceDir,
    [string]$destFile
    )


    # While we could use zipfile from system.io.compression.filesystem, this
    # uses Windows-style path separators all the time! Fixed in CLR 4.6.1 but
    # default Powershell can't access this, PITA. Let's just use the zip command

    $tempdest =  [System.IO.Path]::GetTempPath() + [System.IO.Path]::GetRandomFileName() + ".zip"
    $zip = get-command zip
    # Rely on -WorkingDir $sourcedir and get *, otherwise zip includes full paths from root
    $zipargs = "-r `"$tempdest`" *"

    try {
        $process = (Start-Process $zip -ArgumentList $zipargs -WorkingDirectory $sourcedir -PassThru -Wait)
        if ($process.ExitCode -ne 0) {
            $code = $process.ExitCode
            throw "Failed to compress, zip exited with code $code, see above"
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