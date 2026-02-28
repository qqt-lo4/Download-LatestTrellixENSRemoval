function Find-EPOPolicy {
    <#
    .SYNOPSIS
        Searches for policies in the ePO server

    .DESCRIPTION
        Calls the policy.find Web API command to search for policies by name.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER searchText
        Text to search for in policy names. If omitted, returns all policies.

    .OUTPUTS
        [PSCustomObject[]]. Policy objects.

    .EXAMPLE
        Find-EPOPolicy -searchText "Threat Prevention"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [string]$searchText
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
        $hParam = if ($searchText) { @{searchText = $searchText} } else { @{} }
    }
    Process {
        $oePOAPI.CallAPI("policy.find", $hParam, "json").Value
    }
}
