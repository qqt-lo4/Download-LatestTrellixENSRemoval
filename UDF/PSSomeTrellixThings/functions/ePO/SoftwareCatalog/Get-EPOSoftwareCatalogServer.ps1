function Get-EPOSoftwareCatalogServer {
    <#
    .SYNOPSIS
        Retrieves software catalog server configuration from ePO

    .DESCRIPTION
        Queries the EPOSoftwareCatalogServer table for the software catalog
        server name, URLs, and configuration.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .OUTPUTS
        [System.Data.DataTableCollection]. Software catalog server configuration.

    .EXAMPLE
        Get-EPOSoftwareCatalogServer

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
        return $oePODB.RunQuery("SELECT * FROM [dbo].[EPOSoftwareCatalogServer]")
    }
}