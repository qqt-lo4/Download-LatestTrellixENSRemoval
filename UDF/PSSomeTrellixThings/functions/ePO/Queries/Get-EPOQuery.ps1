function Get-EPOQuery {
    <#
    .SYNOPSIS
        Retrieves an ePO query definition from the database

    .DESCRIPTION
        Queries the OrionQuery table in the ePO database to retrieve query definitions
        by ID, unique key, or name. Optionally expands the query object with parsed
        select, where, and order clauses.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER name
        The query name (supports LIKE pattern matching).

    .PARAMETER uniqueKey
        The unique key identifying the query.

    .PARAMETER id
        The query ID.

    .PARAMETER expandObject
        Parses and adds select, where, and order clause properties to the result.

    .OUTPUTS
        [System.Data.DataSet]. Query definition objects from the database.

    .EXAMPLE
        Get-EPOQuery -ePODB $db -uniqueKey "epo.query.key" -expandObject

    .EXAMPLE
        Get-EPOQuery -ePODB $db -name "My Query%"

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePODBInfo class
            1.1.0 - Refactored to use Connect-ePODB connection object
    #>
    [OutputType([System.Data.DataSet])]
    [CmdletBinding(DefaultParameterSetName = 'Id')]
    Param(
        [Parameter(
		    HelpMessage						= "Enter epo DB connection object",
		    Position						= 0
	  	)]
        [Parameter(ParameterSetName="Id")]
        [Parameter(ParameterSetName="UniqueKey")]
        [Parameter(ParameterSetName="Name")]
        [object]$ePODB,
        [Parameter(Mandatory=$true, ParameterSetName="Name")]
        [string]$name,
        [Parameter(Mandatory=$true, ParameterSetName="UniqueKey")]
        [string]$uniqueKey,
        [Parameter(Mandatory=$true, ParameterSetName="Id")]
        [string]$id,
        [Parameter(ParameterSetName="Id")]
        [Parameter(ParameterSetName="UniqueKey")]
        [Parameter(ParameterSetName="Name")]
        [switch]$expandObject
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        $sqlwhere = switch($PsCmdlet.ParameterSetName) {
            "Id" { "WHERE [Id] = '$id'" }
            "UniqueKey" { "WHERE [UniqueKey] = '$uniqueKey'" }
            "Name" { "WHERE [Name] like '$name'" }
        }
        $db = $oePODB.DB
        $query = "SELECT * FROM [$db].[dbo].[OrionQuery] $sqlwhere"
        $queries = $oePODB.RunQuery($query)
        if ($expandObject.IsPresent) {
            foreach ($q in $queries) {
                $sqlColumns = $q.PSObject.Properties.Name | Where-Object { $_ -like "*URI" }
                $queryClauses = @{}
                foreach ($sqlC in $sqlColumns) {
                    Select-String "\?[^$]+" -input $q.$sqlC -AllMatches | ForEach-Object {$_.matches.Value} | `
                        Select-String "[^&?]+" -AllMatches | ForEach-Object {$_.matches.Value} | `
                        ForEach-Object {
                                if ($_ -match "^([^=]+)=(.+)$") {
                                    $queryClauses.Add($Matches.1, [System.Web.HttpUtility]::UrlDecode($Matches.2))
                                }
                        }
                }
                $q | Add-Member -NotePropertyName "Clauses" -NotePropertyValue (New-Object PSObject -Property $queryClauses)
                $where_clause = Merge-WhereClauses -leftClause $queryClauses["orion.condition.sexp"] -rightClause $queryClauses["orion.requied.sexp"]
                $q | Add-Member -NotePropertyName "where" -NotePropertyValue $where_clause
                if ($queryClauses.ContainsKey("orion.table.columns")) {
                    $selectClauseValue = "( select " + $queryClauses["orion.table.columns"].Replace(":", " ") + " )"
                    $q | Add-Member -NotePropertyName "select" -NotePropertyValue $selectClauseValue
                }
                if ($queryClauses.ContainsKey("orion.table.order.by") -and $queryClauses.ContainsKey("orion.table.order")) {
                    $orderOrder = $queryClauses["orion.table.order"]
                    $orderByColumns = $queryClauses["orion.table.order.by"].Split(":")
                    $orderClause = "(order "
                    ForEach ($item in $orderByColumns) {
                        $orderClause += "($orderOrder $item) "
                    }
                    $orderClause = $orderClause + ")"
                    $q | Add-Member -NotePropertyName "order" -NotePropertyValue $orderClause
                }
            }
        }
        return $queries
    }
}

function Merge-WhereClauses {
    <#
    .SYNOPSIS
        Merges two where clauses into a single combined clause

    .DESCRIPTION
        Combines two S-expression where clauses using the specified logical operator.
        Handles cases where one or both clauses may be empty.

    .PARAMETER leftClause
        The left where clause S-expression.

    .PARAMETER rightClause
        The right where clause S-expression.

    .PARAMETER operator
        The logical operator to combine clauses. Default: "and".

    .OUTPUTS
        [string]. A merged where clause S-expression.

    .EXAMPLE
        Merge-WhereClauses -leftClause "(where (eq col1 val1))" -rightClause "(where (eq col2 val2))"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [AllowEmptyString()]
        [string]$leftClause,
        [AllowEmptyString()]
        [string]$rightClause,
        [string]$operator = "and"
    )
    $where_clauses = if ($leftClause) {
        if ($rightClause) {
            @($leftClause, $rightClause)
        } else {
            $leftClause
        }
    } else {
        if ($rightClause) {
            $rightClause
        } else {
            ""
        }
    }
    if ($where_clauses -eq "") {
        return ""
    } else {
        $where_clause = ""
        if ($where_clauses.Count -gt 1) {
            $where_clause = "( $operator "
        }
        foreach ($c in $where_clauses) {
            if ($c -match "^ *\( *where *(.+) *\) *$") {
                $where_clause += $Matches.1 + " "
            }
        }
        if ($where_clauses.Count -gt 1) {
            $where_clause += ")"
        }
        return "(where " + $where_clause + ")"
    }
}
