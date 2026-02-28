function Get-EPOServerInfo {
    <#
    .SYNOPSIS
        Retrieves ePO server information from the database

    .DESCRIPTION
        Queries the EPOServerInfo table in the ePO database to retrieve
        server configuration and version information.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .OUTPUTS
        [System.Data.DataTableCollection]. Server information from the EPOServerInfo table.

    .EXAMPLE
        Get-EPOServerInfo

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePODB
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        return $oePODB.RunQuery("SELECT * FROM [dbo].[EPOServerInfo]")
    }   
}