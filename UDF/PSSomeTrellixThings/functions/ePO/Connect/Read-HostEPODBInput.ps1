function Read-HostEPODBInput {
    <#
    .SYNOPSIS
        Prompts the user for ePO database connection details

    .DESCRIPTION
        Interactively collects ePO database connection information (server, instance,
        port, database name, credentials) via Read-Host prompts. Supports composite
        server strings like "server\instance,port".

    .OUTPUTS
        [PSCustomObject]. ePO database connection object with RunQuery method.

    .EXAMPLE
        $db = Read-HostEPODBInput

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version returning ePODBInfo class
            1.1.0 - Refactored to return Connect-ePODB connection object
    #>
    $server = Read-Host -Prompt "Please provide DB server"
    switch -regex ($server) {
        "^([^\\]+)\\([^,]+),([0-9]{1,5})$" {
            $server = $Matches.1
            $instance = $Matches.2
            $port = $Matches.3
            Break
        }
        "^([^\\]+)\\([^,]+)$"  {
            $server = $Matches.1
            $instance = $Matches.2
            Break
        }
        "^([^\\]+),([0-9]{1,5})$"  {
            $server = $Matches.1
            $port = $Matches.2
            $instanceUnnamed = $true
        }
        "^([^\\,]+)$"  {
            $server = $Matches.1
            Break
        }
    }
    if ((-not $instance) -and (-not $instanceUnnamed)) {
        $instance = Read-Host -Prompt "What is the instance name"
    }
    if (-not $port) {
        $port = Read-Host -Prompt "What is the port number"
    }
    $db = Read-Host -Prompt "Please enter the DB name"
    $user = Read-Host -Prompt "Please provide username"
    $password = Read-Host -Prompt "Please enter password" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($user, $password)
    return Connect-EPODB -Server $server -Instance $instance -Database $db -Port $port -Credential $credential
}
