function Save-EPODBInfoToCredManager {
    <#
    .SYNOPSIS
        Saves ePO database connection info to Windows Credential Manager

    .DESCRIPTION
        Stores ePO database connection details (server, instance, port, database, credentials)
        in the Windows Credential Manager for later retrieval.

    .PARAMETER target
        The credential target name to save under in Windows Credential Manager.

    .PARAMETER ePODB
        An ePO database connection object containing the connection details to save.

    .OUTPUTS
        None.

    .EXAMPLE
        Save-EPODBInfoToCredManager -target "ePO_DB_Production" -ePODB $db

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePODBInfo class
            1.1.0 - Refactored to use Connect-ePODB connection object
    #>
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$target,
        [Parameter(Mandatory=$true)]
        [ValidateNotNull()]
        [object]$ePODB
    )
    Save-ManagedConnectCredential -target $target `
                                    -connect1 $ePODB.ConnectionString `
                                    -connect2 $ePODB.DB `
                                    -credential $ePODB.Credential
}
