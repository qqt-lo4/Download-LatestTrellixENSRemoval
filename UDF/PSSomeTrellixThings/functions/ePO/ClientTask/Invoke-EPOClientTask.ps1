function Invoke-EPOClientTask {
    <#
    .SYNOPSIS
        Runs an ePO client task on specified systems

    .DESCRIPTION
        Calls the clienttask.run Web API command to execute a client task
        on one or more systems with configurable retry and timeout settings.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER names
        The system name(s) to run the task on.

    .PARAMETER productId
        The product ID of the client task.

    .PARAMETER taskId
        The task ID to execute.

    .PARAMETER retryAttempts
        Number of retry attempts. Default: 1.

    .PARAMETER retryIntervalInSeconds
        Interval between retries in seconds. Default: 30.

    .PARAMETER abortAfterMinutes
        Abort task after this many minutes. Default: 5.

    .PARAMETER useAllAgentHandlers
        Use all available agent handlers.

    .PARAMETER stopAfterMinutes
        Stop task after this many minutes. Default: 20.

    .PARAMETER randomMinutes
        Random delay in minutes before execution. Default: 0.

    .PARAMETER timeoutInHours
        Task timeout in hours. Default: 48.

    .OUTPUTS
        [PSCustomObject]. API result of the client task execution.

    .EXAMPLE
        Invoke-EPOClientTask -names "PC001" -productId "EPOAGENT____3000" -taskId "123"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory, Position = 0)]
        [string[]]$names,
        [Parameter(Mandatory, Position = 1)]
        [string]$productId,
        [Parameter(Mandatory, Position = 2)]
        [string]$taskId,
        [int]$retryAttempts = 1,
        [int]$retryIntervalInSeconds = 30,
        [int]$abortAfterMinutes = 5,
        [switch]$useAllAgentHandlers,
        [int]$stopAfterMinutes = 20,
        [int]$randomMinutes = 0,
        [int]$timeoutInHours = 48
    )
    Begin {
        $hParameters = Get-FunctionParameters -RemoveParam @("ePOAPI", "Verbose")
        $hParameters.names = $hParameters.names -join ","
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        return ($oePOAPI.CallAPI("clienttask.run", $hParameters, "json"))
    }
}