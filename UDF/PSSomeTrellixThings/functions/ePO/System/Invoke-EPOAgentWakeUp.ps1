function Invoke-EPOAgentWakeUp {
    <#
    .SYNOPSIS
        Sends an agent wake-up call to ePO-managed systems

    .DESCRIPTION
        Calls the system.wakeupAgent Web API command to trigger an agent wake-up
        on one or more systems with configurable retry and timeout settings.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER names
        The system name(s) to wake up.

    .PARAMETER fullProps
        Requests a full properties collection.

    .PARAMETER superAgent
        Targets super agents.

    .PARAMETER randomMinutes
        Random delay in minutes before the wake-up. Default: 0.

    .PARAMETER forceFullPolicyUpdate
        Forces a full policy update.

    .PARAMETER useAllHandlers
        Uses all available agent handlers.

    .PARAMETER retryIntervalSeconds
        Interval between retries in seconds. Default: 60.

    .PARAMETER attempts
        Number of retry attempts. Default: 0.

    .PARAMETER abortAfterMinutes
        Abort after this many minutes. Default: 20.

    .PARAMETER includeSubgroups
        Includes subgroups in the wake-up scope.

    .OUTPUTS
        [PSCustomObject]. API result of the wake-up command.

    .EXAMPLE
        Invoke-EPOAgentWakeUp -names "PC001" -fullProps

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory, Position = 0)]
        [string[]]$names,
        [switch]$fullProps,
        [switch]$superAgent,
        [int]$randomMinutes = 0,
        [switch]$forceFullPolicyUpdate,
        [switch]$useAllHandlers,
        [int]$retryIntervalSeconds = 60,
        [int]$attempts = 0,
        [int]$abortAfterMinutes = 20,
        [switch]$includeSubgroups
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
        $hParameters = Get-FunctionParameters -RemoveParam @("ePOAPI", "Verbose")
        $hParameters.names = $hParameters.names -join ","
    }
    Process {
        return ($oePOAPI.CallAPI("system.wakeupAgent", $hParameters, "verbose"))
    }
}
