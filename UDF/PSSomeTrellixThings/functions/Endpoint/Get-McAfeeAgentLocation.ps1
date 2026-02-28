function Get-McAfeeAgentLocation {
    <#
    .SYNOPSIS
        This function will retrieve the Trellix/McAfee agent install location
    .DESCRIPTION
        This function will retrieve the Trellix/McAfee agent install location
        It will be used to find and use McAfee binaries in other functions like "Invoke-cmdagent"
    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
        1.0.0 - Initial version
        1.1.0 - Added remote execution feature ($ComputerName, $Credential and $Session parameters)
    .EXAMPLE
        Get-McAfeeAgentLocation
        Should get "C:\Program Files\McAfee\Agent\". Might change after McAfee renamed to Trellix
    #>
    [CmdletBinding()]
    Param(
        [string]$ComputerName,
        [pscredential]$Credential,
        [System.Management.Automation.Runspaces.PSSession]$Session
    )
    if ($ComputerName -or $Session) {
        Invoke-ThisFunctionRemotely -ImportFunctions @("Get-ApplicationUninstallRegKey", "Get-InstalledProgramPath")
    } else {
        $McAfeeAgentLocation = Get-InstalledProgramPath -valueData "McAfee Agent"
        if (($null -eq $McAfeeAgentLocation) -or ($McAfeeAgentLocation -eq "")) {
            return Get-InstalledProgramPath -valueData "Trellix Agent"
        } else {
            return $McAfeeAgentLocation
        }    
    }
}
