function Get-CurrentRepositoryAMCore {
    <#
    .SYNOPSIS
        Gets the current AMCore content version from the ePO repository

    .DESCRIPTION
        Queries the ePO repository for the current branch AMCORE package
        and returns its major version number.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .OUTPUTS
        [int]. The AMCore major version number.

    .EXAMPLE
        Get-CurrentRepositoryAMCore

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        return [int]((Find-EPOPackages -ePOAPI $oePOAPI -searchText "AMCORE" | Where-Object { $_.packageBranch -eq "Current" }).productDetectionProductVersion.Split(".")[0])
    }
}