function Invoke-cmdagent {
    <#
    .SYNOPSIS
        Executes the McAfee/Trellix cmdagent.exe command

    .DESCRIPTION
        Wrapper around Invoke-Process for running cmdagent.exe with specified arguments.

    .PARAMETER agentInstallPath
        The agent installation directory. Default: detected via Get-McAfeeAgentLocation.

    .PARAMETER arguments
        The command-line arguments to pass to cmdagent.exe.

    .PARAMETER DisplayLevel
        The output display level: Full, StdOut, StdErr, ExitCode, or None. Default: Full.

    .OUTPUTS
        Process output depending on DisplayLevel.

    .EXAMPLE
        Invoke-cmdagent -arguments "-i"

    .EXAMPLE
        Invoke-cmdagent -arguments "-p" -DisplayLevel StdOut

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$agentInstallPath = (Get-McAfeeAgentLocation),
        [ValidateNotNullOrEmpty()]
        [Parameter(Mandatory)]
        [string]$arguments,
        [ValidateSet("Full","StdOut","StdErr","ExitCode","None")]
        [string]$DisplayLevel = "Full"
    )
    $cmdagent_path = ($agentInstallPath + "cmdagent.exe")
    if (Test-Path -Path $cmdagent_path) {
        Invoke-Process -FilePath $cmdagent_path -DisplayLevel $DisplayLevel -ArgumentList $arguments 
    }
}
