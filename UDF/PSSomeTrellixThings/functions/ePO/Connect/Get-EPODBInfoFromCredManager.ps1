function Get-EPODBInfoFromCredManager {
    <#
    .SYNOPSIS
        Retrieves ePO database connection info from Windows Credential Manager

    .DESCRIPTION
        Reads stored ePO database credentials (server, instance, port, database name)
        from the Windows Credential Manager and returns an ePO database connection object.

    .PARAMETER target
        The credential target name in Windows Credential Manager.

    .OUTPUTS
        [PSCustomObject]. ePO database connection object with RunQuery method.

    .EXAMPLE
        $db = Get-EPODBInfoFromCredManager -target "ePO_DB_Production"

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version returning ePODBInfo class
            1.1.0 - Refactored to return Connect-ePODB connection object
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
        if ($credTarget.connect1 -match "^([a-z-A-Z-0-9_.-]+)(\\([a-z-A-Z-0-9_.-]+))?,([0-9]+)$") {
            $dbserver = $Matches.1
            $dbinstance = $Matches.3
            $dbport = $Matches.4
            return Connect-EPODB -Server $dbserver -Instance $dbinstance -Database $credTarget.connect2 -Port $dbport -Credential $credTarget.credential
        } else {
            throw [System.ArgumentException] "Target does not exists in Windows credentials manager"
        }
    }
}
