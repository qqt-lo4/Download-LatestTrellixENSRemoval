function Get-EPOServerTaskLogMessages {
    <#
    .SYNOPSIS
        Retrieves server task log messages from the ePO server

    .DESCRIPTION
        Calls the tasklog.listTaskSources Web API command to retrieve
        server task log messages.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .OUTPUTS
        [PSCustomObject[]]. Task log message objects.

    .EXAMPLE
        Get-EPOServerTaskLogMessages

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