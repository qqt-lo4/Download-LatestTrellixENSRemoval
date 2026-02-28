function Connect-ePOAPI {
    <#
    .SYNOPSIS
        Connects to a Trellix ePO server via the Web API

    .DESCRIPTION
        Creates an ePO API connection object with credentials and server information.
        The returned object includes a CallAPI script method for executing ePO Web API commands.

    .PARAMETER Server
        The ePO server hostname or IP address.

    .PARAMETER Port
        The ePO server port. Default: 8443.

    .PARAMETER Username
        The username for authentication.

    .PARAMETER Password
        The password as a SecureString.

    .PARAMETER Credential
        A PSCredential object for authentication.

    .PARAMETER IgnoreSSLError
        Ignores SSL certificate errors when connecting.

    .PARAMETER GlobalVar
        Stores the connection object in the $Global:ePOAPI variable.

    .OUTPUTS
        [PSCustomObject]. Connection object with CallAPI method.

    .EXAMPLE
        Connect-ePOAPI -Server "epo01" -Credential (Get-Credential) -GlobalVar

    .EXAMPLE
        $api = Connect-ePOAPI -Server "epo01" -Port 8443 -Username "admin" -Password $secPwd

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [ValidatePattern("^[a-z-A-Z0-9._-]+$")]
        [string]$Server,
        [ValidateRange(0, 65535)]
        [int]$Port = 8443,
        [Parameter(Mandatory, ParameterSetName = "Userpassword")]
        [string]$Username,
        [Parameter(Mandatory, ParameterSetName = "Userpassword")]
        [securestring]$Password,
        [Parameter(Mandatory, ParameterSetName = "Cred")]
        [pscredential]$Credential,
        [switch]$IgnoreSSLError,
        [switch]$GlobalVar
    )
    Process {
        $oCred = if ($PSCmdlet.ParameterSetName -eq "Cred") {
            $Credential
        } else {
            New-Object System.Management.Automation.PSCredential($Username,$Password)
        }
        $oResult = [PSCustomObject]@{
            Credential = $oCred
            Server = $Server
            Port = $Port
            BaseURL = "https://$Server`:$Port/remote/"
            IgnoreSSLError = $IgnoreSSLError
        }
        $oResult | Add-Member -MemberType ScriptMethod -Name "CallAPI" -Value {
            Param([string]$command, [hashtable]$arguments = @{}, [string]$output = "xml", [string]$XPath = "", [string]$locale = "en")
            if ($this.IgnoreSSLError) {
                Invoke-IgnoreSSL
            }
            $sUrl = $this.BaseURL + $command + "?"
            $hArg = $arguments
            if ($hArg) {
                $hArg.":output" = $output
            } else {
                $hArg = @{":output" = $output}
            }
            $hArg.add(":locale", $locale)
            Add-Type -AssemblyName System.Web
            $sUrl += $(($hArg.GetEnumerator() | ForEach-Object { "$($_.Key)=$([System.Web.HttpUtility]::UrlEncode($_.Value.ToString()))" }) -join '&')

            $hHeaders = @{
                "Accept-Language" = "en"
            }
            $iwr = if ($this.IgnoreSSLError) {
                Invoke-WebRequest -Uri $sUrl -Method Get -Credential $this.Credential -Headers $hHeaders -UseBasicParsing
            }
            $bSuccess, $sStatus, $sAPIResult = if ($iwr.Content -match "^(?<status>[a-zA-Z 0-9]+):`r`n(?<apiresult>(.*`r`n|.*`n|.*)*)") {
                ($Matches.status -eq "OK"), $Matches.status, $Matches.apiresult
            } else {
                $false, "Bad result of WebAPI", ""
            }
            $oResult = [PSCustomObject]@{
                Http = $iwr
                Success = $bSuccess
                Status = $sStatus
                Value = switch ($output) {
                    "json" { $sAPIResult | ConvertFrom-Json } 
                    "xml" { 
                        $oXMLResult = if ($XPath) {
                            ([xml]$sAPIResult).SelectNodes($XPath)
                        } else {
                            [xml]$sAPIResult
                        }
                        $oXMLResult
                    }
                    default { $sAPIResult }
                }
                OutputType = $output
                URL = $sUrl
            }
            return $oResult
        }
    }
    End {
        if ($GlobalVar.IsPresent) {
            $Global:ePOAPI = $oResult
        } else {
            return $oResult
        }
    }
}
