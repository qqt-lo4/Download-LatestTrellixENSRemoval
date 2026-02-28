function Set-McAfeeAgentCustomProperty {
    <#
    .SYNOPSIS
        This function can change mcafee agent properties
    .DESCRIPTION
        This function can change mcafee agent properties on the local computer or remotely
    .LINK
        Import:
        . $PSScriptRoot\UDF\CLI\Invoke-Process.ps1
        . $PSScriptRoot\UDF\McAfee\Get-McAfeeAgentLocation.ps1
        . $PSScriptRoot\UDF\Programs\Get-ApplicationUninstallRegKey.ps1
        . $PSScriptRoot\UDF\Programs\Get-InstalledProgramPath.ps1
        . $PSScriptRoot\UDF\Remote\Invoke-ThisFunctionRemotely.ps1
        . $PSScriptRoot\UDF\Script\Get-FunctionCode.ps1
    .EXAMPLE
        Set-McAfeeAgentCustomProperty -propNumber 2 -value "Hello"
        Will change the custom property number 2 to "Hello"
    .EXAMPLE
        Set-McAfeeAgentCustomProperty -prop1 "Hello" -prop2 "Loïc"
        Will change the custom property number 1 to "Hello" and property number 2 to "Loïc"
    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
        1.0.0 - Initial version
        1.1.0 - Added remote run feature (parameter $Session),
                 removed mandatory for $value to allow clearing a custom property
    #>

    Param(
        [string]$agentInstallPath = (Get-McAfeeAgentLocation),

        [ValidateSet(1, 2, 3, 4, 5, 6, 7, 8)]
        [Parameter(Mandatory, ParameterSetName = "OneProperty")]
        [int]$propNumber,

        [Parameter(ParameterSetName = "OneProperty")]
        [string]$value,

        [AllowEmptyString()]
        [Parameter(ParameterSetName = "SeveralProperties")]
        [string]$prop1,

        [AllowEmptyString()]
        [Parameter(ParameterSetName = "SeveralProperties")]
        [string]$prop2,

        [AllowEmptyString()]
        [Parameter(ParameterSetName = "SeveralProperties")]
        [string]$prop3,

        [AllowEmptyString()]
        [Parameter(ParameterSetName = "SeveralProperties")]
        [string]$prop4,

        [AllowEmptyString()]
        [Parameter(ParameterSetName = "SeveralProperties")]
        [string]$prop5,

        [AllowEmptyString()]
        [Parameter(ParameterSetName = "SeveralProperties")]
        [string]$prop6,

        [AllowEmptyString()]
        [Parameter(ParameterSetName = "SeveralProperties")]
        [string]$prop7,

        [AllowEmptyString()]
        [Parameter(ParameterSetName = "SeveralProperties")]
        [string]$prop8,

        [System.Management.Automation.Runspaces.PSSession]$Session,
        [string]$ComputerName,
        [pscredential]$Credential
    )

    if ($Session -or $ComputerName) {
        $aImportFunctions = @("Get-McAfeeAgentLocation", "Invoke-Process", "Get-ApplicationUninstallRegKey", "Get-InstalledProgramPath", "Get-FunctionCode")
        return Invoke-ThisFunctionRemotely -ImportFunctions $aImportFunctions
    } else {
        $maconfig_path = ($agentInstallPath + "maconfig.exe")
        if (Test-Path -Path $maconfig_path) {
            $sArguments = if ($PSCmdlet.ParameterSetName -eq "OneProperty") {
                "-custom -prop$propNumber `"$value`""
            } else {
                $aProps = @()
                foreach ($prop in $PSBoundParameters.Keys) {
                    if ($prop -like "prop[1-8]") {
                        $sValue = $($PSBoundParameters[$prop])
                        $sEncodedValue = [System.Text.Encoding]::ASCII.GetString([System.Console]::OutputEncoding.GetBytes($sValue))
                        $aProps += "-$prop `"$sEncodedValue`""
                    }
                }
                "-custom " + ($aProps -join " ")
            }
            #$oResult = Start-Process $maconfig_path -ArgumentList $sArguments -NoNewWindow -PassThru -Wait 
            $oResult = $(Invoke-Process -FilePath $maconfig_path -ArgumentList $sArguments)
            return $oResult
        } else {
            return $null
        }
    }
}
