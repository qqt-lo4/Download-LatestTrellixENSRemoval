function Get-EPOTaskSources {
    <#
    .SYNOPSIS
        Lists task log sources from the ePO server

    .DESCRIPTION
        Calls the tasklog.listTaskSources Web API command to retrieve available
        task log sources.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .OUTPUTS
        [PSCustomObject[]]. Task source objects.

    .EXAMPLE
        Get-EPOTaskSources

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $epoAPI } else { $Global:ePOAPI }
    }
    Process {
        return $oePOAPI.CallAPI("tasklog.listTaskSources", @{}, "json").Value
    }
}