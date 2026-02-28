function Get-EPOSchedulerTask {
    <#
    .SYNOPSIS
        Retrieves ePO server tasks via the Web API

    .DESCRIPTION
        Calls scheduler.getServerTask or scheduler.listAllServerTasks to retrieve
        server task definitions by name or ID.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER taskName
        The task name to retrieve. If omitted, returns all tasks.

    .PARAMETER taskId
        The task ID to retrieve.

    .OUTPUTS
        [PSCustomObject[]]. Server task objects.

    .EXAMPLE
        Get-EPOSchedulerTask -taskName "Repository Pull"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [cmdletbinding(DefaultParameterSetName = "Name")]
    Param(
        [object]$ePOAPI,
        [Parameter(ParameterSetName = "Name")]
        [string]$taskName,
        [Parameter(ParameterSetName = "Id")]
        [int]$taskId
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $epoAPI } else { $Global:ePOAPI }
    }
    Process {
        $sCommand, $hArguments = if ($PSCmdlet.ParameterSetName -eq "Name") {
            if ($taskName) {
                "scheduler.getServerTask", @{taskName = $taskName}
            } else {
                "scheduler.listAllServerTasks", @{}
            }
        } else {
            "scheduler.getServerTask", @{taskId = $taskId}
        }
        return $oePOAPI.CallAPI($sCommand, $hArguments, "json").Value
    }
}