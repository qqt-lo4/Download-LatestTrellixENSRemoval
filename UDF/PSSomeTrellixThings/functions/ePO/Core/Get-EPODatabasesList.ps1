function Get-EPODatabaseList {
    <#
    .SYNOPSIS
        Lists available databases in the ePO server

    .DESCRIPTION
        Calls the core.listDatabases Web API command to retrieve the list of
        databases registered in the ePO server.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .OUTPUTS
        [string[]]. List of database names.

    .EXAMPLE
        Get-EPODatabaseList

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
        return ($oePOAPI.CallAPI("core.listDatabases", @{}, "xml", "/result/list/database/name")).Value
    }
}