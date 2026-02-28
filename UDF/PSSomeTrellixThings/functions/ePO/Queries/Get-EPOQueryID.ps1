function Get-EPOQueryID {
    <#
    .SYNOPSIS
        Gets the ID of an ePO query by its unique key

    .DESCRIPTION
        Retrieves a query from the ePO database by its unique key and returns its ID.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER uniqueKey
        The unique key identifying the query.

    .OUTPUTS
        [string]. The query ID.

    .EXAMPLE
        Get-EPOQueryID -ePODB $db -uniqueKey "epo.query.key"

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
        [Parameter(Mandatory)]
        [ValidateNotNull()]
        [string]$uniqueKey
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        $ePOQuery = Get-EPOQuery -ePODB $oePODB -uniqueKey $uniqueKey
        return $ePOQuery.Id
    }
}
