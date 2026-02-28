function Get-EPOSQLQueryResult {
    <#
    .SYNOPSIS
        Executes a SQL query against the ePO database

    .DESCRIPTION
        Runs a raw SQL query against the ePO database using the provided
        Connect-ePODB connection object and returns the result tables.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER query
        The SQL query string to execute.

    .OUTPUTS
        [System.Data.DataTableCollection]. The result tables from the SQL query.

    .EXAMPLE
        Get-EPOSQLQueryResult -ePODB $db -query "SELECT * FROM [dbo].[EPOLeafNode]"

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePODBInfo class
            1.1.0 - Refactored to use Connect-ePODB connection object
    #>
    Param(
        [Parameter(
		    HelpMessage						= "Enter epo DB connection object",
		    Position						= 0
	  	)]
        [object]$ePODB,
        [Parameter(
		    HelpMessage						= "Enter sql query to run",
		    Position						= 1,
		    Mandatory						= $true
	  	)]
		[ValidateNotNullOrEmpty()]
        [string]$query
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        return $oePODB.RunQuery($query)
    }
}
