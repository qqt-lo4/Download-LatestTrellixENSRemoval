function Get-EPOExtension {
    <#
    .SYNOPSIS
        Retrieves ePO server extensions from the database

    .DESCRIPTION
        Queries the OrionExtensions table to retrieve installed extensions,
        optionally filtered by name.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER Name
        The extension name to filter by. If omitted, returns all extensions.

    .OUTPUTS
        [System.Data.DataTableCollection]. Extension records.

    .EXAMPLE
        Get-EPOExtension -Name "SoftwareMgmt"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePODB,
        [string]$Name
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        if ($Name) {
            return $oePODB.RunQuery("SELECT * FROM [dbo].[OrionExtensions] Where Name = '$Name'")
        } else {
            return $oePODB.RunQuery("SELECT * FROM [dbo].[OrionExtensions]")
        }
    }
}