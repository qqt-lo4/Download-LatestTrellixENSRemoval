function Test-ePOColumns {
    <#
    .SYNOPSIS
        Tests if ePO table columns exist on the server

    .DESCRIPTION
        Validates a list of column names against the ePO server's table definitions.
        Automatically loads the table list into $Global:EPOTables if not already cached.

    .PARAMETER Columns
        The column names to validate (e.g., "EPOLeafNode.NodeName").

    .PARAMETER FilterInput
        If specified, returns only the existing columns. Otherwise returns an object
        with Existing and NotExisting arrays.

    .OUTPUTS
        [string[]] or [PSCustomObject]. Existing columns, or object with Existing/NotExisting arrays.

    .EXAMPLE
        Test-ePOColumns -Columns @("EPOLeafNode.NodeName", "InvalidTable.Col") -FilterInput

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0)]
        [string[]]$Columns,
        [switch]$FilterInput
    )
    if ((-not ($Global:EPOTables)) -or ($Global:EPOTables.List.Count -eq 0)) {
        $sLanguage = Get-EPOTablesListLanguage
        $Global:EPOTables = Get-EPOTablesList -Language $sLanguage
    }
    $aExistingColumns = @()
    $aNotExistingColumns = @()
    foreach ($sColumn in $Columns) {
        if ($Global:EPOTables.ColumnExists($sColumn)) {
            $aExistingColumns += $sColumn
        } else {
            $aNotExistingColumns += $sColumn
        }
    }
    if ($FilterInput) {
        return $aExistingColumns
    } else {
        return [PSCustomObject]@{
            Existing = $aExistingColumns
            NotExisting = $aNotExistingColumns
        }
    }
}
