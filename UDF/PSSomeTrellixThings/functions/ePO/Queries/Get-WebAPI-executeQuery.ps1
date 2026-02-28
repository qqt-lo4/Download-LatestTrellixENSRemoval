function Get-WebAPI-executeQuery {
    <#
    .SYNOPSIS
        Executes an ePO query via the Web API

    .DESCRIPTION
        Calls the core.executeQuery Web API command to run a saved query by ID
        or a custom query with target, select, where, order, and group clauses.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER id
        The saved query ID to execute.

    .PARAMETER outputformat
        The output format: xml, json, terse, verbose, or PSObject. Default: PSObject.

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

    .OUTPUTS
        Query results in the specified output format.

    .EXAMPLE
        Get-WebAPI-executeQuery -ePOAPI $api -id "123"

    .EXAMPLE
        Get-WebAPI-executeQuery -target "EPOLeafNode" -select "(select EPOLeafNode.NodeName)"
        Uses $Global:ePOAPI

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePOAPIInfo class
            1.1.0 - Refactored to use Connect-ePOAPI connection object
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory=$true, ParameterSetName="id")]
        [string]$id,
        [ValidateNotNullOrEmpty()]
        [ValidateSet('xml','json','terse', 'verbose', 'PSObject')]
        [string]$outputformat = 'PSObject',
        [Parameter(Mandatory=$true, ParameterSetName="custom")]
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
        [string]$joinTables
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
        if ($outputformat -eq "PSObject") {
            return $oePOAPI.CallAPI($command, $arguments, $outputformat, "/result/list/row")
        } else {
            return $oePOAPI.CallAPI($command, $arguments, $outputformat)
        }
    }
}
