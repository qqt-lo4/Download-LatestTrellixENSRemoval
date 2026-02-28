function Get-EPOAPIInfoFromCredManager {
    <#
    .SYNOPSIS
        Retrieves ePO API connection info from Windows Credential Manager

    .DESCRIPTION
        Reads stored ePO API credentials (server, port, SSL settings) from the
        Windows Credential Manager and returns an ePO API connection object.

    .PARAMETER target
        The credential target name in Windows Credential Manager.

    .OUTPUTS
        [PSCustomObject]. ePO API connection object with CallAPI method.

    .EXAMPLE
        $api = Get-EPOAPIInfoFromCredManager -target "ePO_Production"

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version returning ePOAPIInfo class
            1.1.0 - Refactored to return Connect-ePOAPI connection object
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$target
    )
    $credTarget = Get-ManagedConnectCredential -target $target
    if ($null -eq $credTarget) {
        throw [System.ArgumentException] "Target does not exists in Windows credentials manager"
    } else {
        if (($credTarget.connect1 -match "^[a-z-A-Z-0-9_.-]+$") `
            -and ($credTarget.connect2 -match  "^([0-9]{1,5})$")) {
            $ignoreSSLError = (($credTarget.options -is [System.Collections.IDictionary]) `
                            -and ($credTarget.options.ContainsKey("insecure")) `
                            -and ($credTarget.options["insecure"] -eq "true"))
            return Connect-ePOAPI -Server $credTarget.connect1 -Port $credTarget.connect2 -Credential $credTarget.credential -IgnoreSSLError:$ignoreSSLError
        } else {
            throw [System.ArgumentException] "Target does not exists in Windows credentials manager"
        }
    }
}
