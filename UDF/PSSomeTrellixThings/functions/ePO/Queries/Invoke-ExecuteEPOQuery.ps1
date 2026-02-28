function Invoke-ExecuteEPOQuery {
    <#
    .SYNOPSIS
        Executes an ePO query via the API connection object

    .DESCRIPTION
        Calls core.executeQuery on the ePO API connection to run a saved query by ID
        or a custom query with S-expression clauses. Uses the $Global:ePOAPI connection
        if no ePOAPI parameter is provided.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER id
        The saved query ID to execute.

    .PARAMETER outputformat
        The output format: xml, json, terse, or verbose. Default: xml.

    .PARAMETER target
        The target table for a custom query.

    .PARAMETER select
        The select clause (S-expression) for a custom query.

    .PARAMETER where
        The where clause (S-expression) for a custom query.

    .PARAMETER order
        The order clause (S-expression) for a custom query.

    .PARAMETER group
        The group clause for a custom query.

    .PARAMETER database
        The database name for a custom query.

    .PARAMETER depth
        The depth parameter for a custom query.

    .PARAMETER joinTables
        The join tables for a custom query.

    .PARAMETER XPath
        An XPath expression to filter XML output.

    .OUTPUTS
        [PSCustomObject]. API result object.

    .EXAMPLE
        Invoke-ExecuteEPOQuery -target "EPOLeafNode" -select "(select EPOLeafNode.NodeName)" -outputformat json

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory=$true, ParameterSetName="id")]
        [string]$id,
        [ValidateNotNullOrEmpty()]
        [ValidateSet('xml','json','terse', 'verbose')]
        [string]$outputformat = 'xml',
        [Parameter(ParameterSetName="custom")]
        [string]$target,
        [Parameter(ParameterSetName="custom")]
        [string]$select,
        [Parameter(ParameterSetName="custom")]
        [string]$where,
        [Parameter(ParameterSetName="custom")]
        [string]$order,
        [Parameter(ParameterSetName="custom")]
        [string]$group,
        [Parameter(ParameterSetName="custom")]
        [string]$database,
        [Parameter(ParameterSetName="custom")]
        [string]$depth,
        [Parameter(ParameterSetName="custom")]
        [string]$joinTables,
        [string]$XPath = ""
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        $command = "core.executeQuery"
        [hashtable]$arguments = switch ($PsCmdlet.ParameterSetName) {
            "id" { @{queryId = $id} }
            "custom" { 
                [hashtable]$result = @{ target = $target }
                if ($select) { $result.Add("select", $select) }
                if ($where) { $result.Add("where", $where) }
                if ($order) { $result.Add("order", $order) }
                if ($group) { $result.Add("group", $group) }
                if ($database) { $result.Add("database", $database) }
                if ($depth) { $result.Add("depth", $depth) }
                if ($joinTables) { $result.Add("joinTables", $joinTables) }
                $result
            }
        }
        return $oePOAPI.CallAPI($command, $arguments, $outputformat, $XPath)
    }
}
