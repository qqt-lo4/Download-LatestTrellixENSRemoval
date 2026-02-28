function Get-AgentInfo {
    <#
    .SYNOPSIS
        Retrieves McAfee/Trellix agent information from cmdagent.exe

    .DESCRIPTION
        Runs cmdagent.exe with the -i flag and parses the output into a
        PSObject with agent properties.

    .PARAMETER agentInstallPath
        The agent installation directory. Default: detected via Get-McAfeeAgentLocation.

    .OUTPUTS
        [PSObject] or $null. Agent information properties, or $null if not found.

    .EXAMPLE
        Get-AgentInfo

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [string]$agentInstallPath = (Get-McAfeeAgentLocation)
    )
    $cmdagent_path = ($agentInstallPath + "cmdagent.exe")
    if (Test-Path -Path $cmdagent_path) {
        $cmdagentOutput = Invoke-Process -FilePath $cmdagent_path -ArgumentList "-i" -DisplayLevel StdOut
        $result = @{}
        foreach ($line in $cmdagentOutput.Split("`r`n")) {
            if ($line -match "^([^:]+): (.+)$") {
                $prop = $Matches.1
                $val = ($Matches.2).ToString().Trim()
                $result.Add($prop, $val)
            }
        }
        return $(New-Object PSObject -Property $result)    
    } else {
        return $null
    }
}

#. "G:\Scripts\PowerShell\UDF\Programs\Get-ApplicationUninstallRegKey.ps1"
#. "G:\Scripts\PowerShell\UDF\Programs\Get-InstalledProgramPath.ps1"
#. "G:\Scripts\PowerShell\UDF\CLI\Invoke-Process.ps1"
#. "G:\Scripts\PowerShell\UDF\McAfee\Invoke-cmdagent.ps1"
#$o = Get-AgentInfo -arguments "-p"
#$o