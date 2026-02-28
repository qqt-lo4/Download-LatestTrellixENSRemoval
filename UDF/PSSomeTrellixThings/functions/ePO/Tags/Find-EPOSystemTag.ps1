function Find-EPOSystemTag {
    <#
    .SYNOPSIS
        Searches for system tags in the ePO server

    .DESCRIPTION
        Calls the system.findTag Web API command to search for tags by name.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER searchText
        Text to search for in tag names. If omitted, returns all tags.

    .OUTPUTS
        [PSCustomObject[]]. Tag objects.

    .EXAMPLE
        Find-EPOSystemTag -searchText "Windows"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [string]$searchText
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $epoAPI } else { $Global:ePOAPI }
    }
    Process {
        $hArguments = if ($searchText) {
            @{
                searchText = $searchText
            }
        } else {
            @{}
        }
        return $oePOAPI.CallAPI("system.findTag", $hArguments, "json").Value
    }
}