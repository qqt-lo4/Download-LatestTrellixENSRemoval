function GetMcAfeeAgentCustomProps {
    <#
    .SYNOPSIS
        This function will get the custom properties from the computer
    .DESCRIPTION
        This function will get the custom properties from the computer
    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    .LINK
        Import: 
        . $PSScriptRoot\UDF\CLI\Invoke-Process.ps1
        . $PSScriptRoot\UDF\McAfee\Get-McAfeeAgentLocation.ps1
        . $PSScriptRoot\UDF\Programs\Get-ApplicationUninstallRegKey.ps1
        . $PSScriptRoot\UDF\Programs\Get-InstalledProgramPath.ps1
        . $PSScriptRoot\UDF\Remote\Invoke-ThisFunctionRemotely.ps1
        . $PSScriptRoot\UDF\Script\Get-FunctionCode.ps1
    .EXAMPLE
        Get-McAfeeAgentCustomProps
        Will return a hashtable with all custom properties
    #>
        
    Param(
        [string]$agentInstallPath = (Get-McAfeeAgentLocation),
        [System.Management.Automation.Runspaces.PSSession]$Session
    )

    if ($Session) {
        $aImportFunctions = @("Invoke-Process", "Get-ApplicationUninstallRegKey", "Get-InstalledProgramPath", "Get-McAfeeAgentLocation")
        return Invoke-ThisFunctionRemotely -ThisFunctionName $MyInvocation.InvocationName -ThisFunctionParameters $PSBoundParameters -ImportFunctions $aImportFunctions
    } else {
        $cmdagent_path = ($agentInstallPath + "cmdagent.exe")
        if (Test-Path -Path $cmdagent_path) {
            $cmdagentOutput = Invoke-Process -FilePath $cmdagent_path -ArgumentList "-x" -DisplayLevel StdOut
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
}
