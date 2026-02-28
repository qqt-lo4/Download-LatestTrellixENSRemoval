function Find-EPOSystem {
    <#
    .SYNOPSIS
        Searches for systems in the ePO server

    .DESCRIPTION
        Calls the system.find Web API command to search for managed systems
        by name or other properties.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER searchText
        The search text to find systems. Default: empty (returns all).

    .PARAMETER searchNameOnly
        Restricts the search to system names only.

    .OUTPUTS
        [PSCustomObject[]]. System objects typed as EPOSystem.

    .EXAMPLE
        Find-EPOSystem -searchText "PC001"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,

        [Parameter(Position = 0)]
        [string]$searchText = "",

        [Parameter(Position = 1)]
        [switch]$searchNameOnly
    )
    Begin {
        $hParameters = Get-FunctionParameters -RemoveParam @("ePOAPI", "Verbose")
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        $aResult = $oePOAPI.CallAPI("system.find", $hParameters, "json")
        return $aResult.Value | ForEach-Object { $_.PSTypeNames.Insert(0, "EPOSystem") ; $_ }
    }
}
