function Invoke-McAfeeAgentCollectProperties {
    <#
    .SYNOPSIS
        Triggers a McAfee agent properties collection

    .DESCRIPTION
        Runs cmdagent.exe with the -p flag to force the agent to collect
        and send properties to the ePO server.

    .PARAMETER agentInstallPath
        The agent installation directory. Default: detected via Get-McAfeeAgentLocation.

    .PARAMETER DisplayLevel
        The output display level: Full, StdOut, StdErr, ExitCode, or None. Default: Full.

    .OUTPUTS
        Process output depending on DisplayLevel.

    .EXAMPLE
        Invoke-McAfeeAgentCollectProperties

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$agentInstallPath = (Get-McAfeeAgentLocation),
        [ValidateSet("Full","StdOut","StdErr","ExitCode","None")]
        [string]$DisplayLevel = "Full"        
    )
    Invoke-cmdagent -agentInstallPath $agentInstallPath -arguments "-p" -DisplayLevel $DisplayLevel
}