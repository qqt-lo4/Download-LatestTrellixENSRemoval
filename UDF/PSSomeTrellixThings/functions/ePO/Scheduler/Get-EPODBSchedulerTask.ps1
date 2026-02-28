function Get-EPODBSchedulerTask {
    <#
    .SYNOPSIS
        Retrieves ePO scheduler tasks from the database

    .DESCRIPTION
        Queries the OrionSchedulerTask and OrionSchedulerCommand tables to
        retrieve scheduler task definitions with their associated actions.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER uniqueKey
        The unique key of the scheduler task.

    .PARAMETER taskName
        The task name (supports LIKE pattern matching).

    .OUTPUTS
        [PSCustomObject[]]. Scheduler task objects with Actions property.

    .EXAMPLE
        Get-EPODBSchedulerTask -ePODB $db -taskName "Daily Report"

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePODBInfo class
            1.1.0 - Refactored to use Connect-ePODB connection object
    #>
    Param(
        [object]$ePODB,
        [Parameter(Mandatory, ParameterSetName="UniqueKey")]
        [string]$uniqueKey,
        [Parameter(Mandatory, ParameterSetName="Name")]
        [string]$taskName
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        # Get tasks
        $sqlwhere = switch($PsCmdlet.ParameterSetName) {
            "UniqueKey" { "WHERE [UniqueKey] = '$uniqueKey'" }
            "Name" { "WHERE [Name] like '$taskName'" }
        }
        $db = $oePODB.DB
        $query = "SELECT * FROM [$db].[dbo].[OrionSchedulerTask] $sqlwhere"
        $tasks = $oePODB.RunQuery($query)
        # Get actions
        foreach ($task in $tasks) {
            $query = "SELECT * FROM [$db].[dbo].[OrionSchedulerCommand] WHERE SchedulerTaskId=" + $task.Id
            $stp = $oePODB.RunQuery($query)
            $stpRoot = $stp | Where-Object { $_.ParentId -eq 0 }
            $actions = $stp | Where-Object { $_.ParentId -eq $stpRoot.Id }
            $actionsArray = @()
            foreach ($action in $actions) {
                $subtaskActions = $stp | Where-Object { $_.ParentId -eq $action.Id }
                $subActions = @()
                foreach ($subtaskAction in $subtaskActions) {
                    $subActions += $subtaskAction
                }
                $action | Add-Member -NotePropertyName "SubActions" -NotePropertyValue $subActions
                $actionsArray += $action
            }
            $task | Add-Member -NotePropertyName "Actions" -NotePropertyValue $actionsArray
        }
        return $tasks
    }
}
