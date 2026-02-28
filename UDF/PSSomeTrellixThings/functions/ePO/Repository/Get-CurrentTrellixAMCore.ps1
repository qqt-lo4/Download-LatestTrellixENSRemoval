function Get-CurrentTrellixAMCore {
    <#
    .SYNOPSIS
        Gets the latest AMCore DAT version from Trellix update servers

    .DESCRIPTION
        Queries the Trellix update server to find the latest available
        AMCore DAT v3 version number.

    .PARAMETER server
        The update server hostname. Default: "update.nai.com".

    .OUTPUTS
        [int]. The latest DAT version number.

    .EXAMPLE
        Get-CurrentTrellixAMCore

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$server = "update.nai.com"
    )
    Process {
        $webpage = Invoke-WebRequest -Uri "https://$server/Products/datfiles/v3dat/"
        $lastExe = $webpage.Links.outerText | Where-Object { $_ -like "*.exe"} | Select-Object -Last 1
        if ($lastExe) {
            if ($lastExe -match ".+_(?<version>[0-9]+).+") {
                return [int]($Matches.version)
            } else {
                throw "Can't find DAT version"
            }
        } else {
            throw "Can't find a DAT v3 EXE"
        }
    }
}