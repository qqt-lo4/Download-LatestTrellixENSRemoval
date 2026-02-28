function Save-EPOAPIInfoToCredManager {
    <#
    .SYNOPSIS
        Saves ePO API connection info to Windows Credential Manager

    .DESCRIPTION
        Stores ePO API connection details (server, port, credentials, SSL settings)
        in the Windows Credential Manager for later retrieval.

    .PARAMETER target
        The credential target name to save under in Windows Credential Manager.

    .PARAMETER ePOAPI
        An ePO API connection object containing the connection details to save.

    .OUTPUTS
        None.

    .EXAMPLE
        Save-EPOAPIInfoToCredManager -target "ePO_Production" -ePOAPI $api

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePOAPIInfo class
            1.1.0 - Refactored to use Connect-ePOAPI connection object
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$target,
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [object]$ePOAPI
    )
    Save-ManagedConnectCredential -target $target `
                                    -connect1 $ePOAPI.Server `
                                    -connect2 $ePOAPI.Port `
                                    -credential $ePOAPI.Credential `
                                    -options @{insecure=$(if ($ePOAPI.IgnoreSSLError) { "true"} else { "false" })}
}
