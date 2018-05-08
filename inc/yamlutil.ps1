function Yaml-Load {

    param (
        [string]$infile,
        [bool]$convertFromLF = $true
    )

    Write-Verbose "[yaml] Reading $infile"

    if ($convertFromLF) {
        $yaml = (Get-Content "$infile" -Raw) -replace "`n","`r`n"
    } else {
        $yaml = Get-Content "$infile"
    }

    return ConvertFrom-Yaml $yaml

}

function Yaml-Save {
    param (
        [System.Object]$obj,
        [string]$outfile,
        [bool]$convertToLF
    )

    Write-Verbose "[yaml] Writing $outfile"

    if ($convertToLF) {
        $yamllf = (ConvertTo-Yaml $obj) -replace "`r`n","`n"
        Set-Content $yamllf -Path $outfile -NoNewline -Force
    } else {
        ConvertTo-Yaml $obj -OutFile $outfile -Force
    }

}
