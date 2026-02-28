function Get-EPOReport {
    <#
    .SYNOPSIS
        Retrieves ePO report definitions from the database

    .DESCRIPTION
        Queries the OrionReport table and parses report XML to extract query definitions,
        report grids, and associated query clauses. Enriches each report with Queries
        and ReportDef properties.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER name
        Filter by report name (supports LIKE pattern matching).

    .PARAMETER id
        Filter by report ID.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .OUTPUTS
        [PSCustomObject[]]. Report objects with Queries and ReportDef properties.

    .EXAMPLE
        Get-EPOReport -ePODB $db -name "Compliance%"

    .NOTES
        Author  : Loïc Ade
        Version : 1.2.0

        Version History:
            1.0.0 - Initial version using ePOAPIInfo and ePODBInfo classes
            1.1.0 - Refactored to use Connect-ePOAPI connection object
            1.2.0 - Refactored to use Connect-ePODB connection object
    #>
    [CmdletBinding(DefaultParameterSetName = 'All')]
    Param(
        [Parameter(HelpMessage = "Enter epo DB connection object", Position = 0, ParameterSetName = "All")]
        [Parameter(HelpMessage = "Enter epo DB connection object", Position = 0, ParameterSetName = "Name")]
        [Parameter(HelpMessage = "Enter epo DB connection object", Position = 0, ParameterSetName = "Id")]
        [object]$ePODB,
        [Parameter(HelpMessage = "Enter report name", ParameterSetName = "Name")]
        [string]$name,
        [Parameter(HelpMessage = "Enter report Id", ParameterSetName = "Id")]
        [string]$id,
        [object]$ePOAPI
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        $db = $oePODB.DB
        $query = "SELECT * FROM [$db].[dbo].[OrionReport]"
        switch ($PSCmdlet.ParameterSetName) {
            "Name" {
                $query += " WHERE [Name] like '" + $name + "'"
            }
            "Id" {
                $query += " WHERE [Id] = '" + $id + "'"
            }
        }
        $result = $oePODB.RunQuery($query)
        foreach ($report in $result) {
            $xmlreport = [xml]$report.ReportXML
            $queries = $xmlreport.SelectNodes("//element[@type=""queryChart"" or @type=""queryTable""]")
            [hashtable]$queriesHT = @{}
            foreach ($element in $queries) {
                $querySQLObject = if ($element.HasAttribute("uniqueKey")) {
                    Get-EPOQuery -ePODB $oePODB -uniqueKey $element.uniqueKey -expandObject
                } else {
                    Get-EPOQuery -ePODB $oePODB -id $element.queryId -expandObject
                }
                if (-not $element.HasAttribute("queryId")) {
                    $attrib = $element.OwnerDocument.CreateAttribute("queryId")
                    $attrib.Value = $querySQLObject.Id
                    $element.Attributes.Append($attrib) | Out-Null
                }
                if (-not $queriesHT.ContainsKey($element.queryId)) {
                    $queriesHT.Add($element.queryId, $querySQLObject)
                }
            }
            $report | Add-Member -NotePropertyName "Queries" -NotePropertyValue $queriesHT
            $report.ReportXML = $xmlreport.OuterXml
            [xml]$rp = $report.ReportXML
            $reportLines = @()
            foreach ($reportline in $rp.report.grid) {
                $reportNewLine = @()
                foreach ($element in $reportline.element) {
                    if (($element.type -eq "queryTable") -or ($element.type -eq "queryChart")) {
                        $queryDef = $report.Queries[$element.queryId.toString()]
                        $element | Add-Member -NotePropertyName "query" -NotePropertyValue $queryDef
                    }
                    $reportNewLine += $element
                }
                $reportLines += @(, ($reportNewLine))
            }
            $report | Add-Member -NotePropertyName "ReportDef" -NotePropertyValue $reportLines
        }
        return $result
    }
}
