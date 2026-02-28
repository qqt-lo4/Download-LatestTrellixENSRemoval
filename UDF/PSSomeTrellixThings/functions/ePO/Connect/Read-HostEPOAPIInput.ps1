function Read-HostEPOAPIInput {
    <#
    .SYNOPSIS
        Prompts the user for ePO API connection details

    .DESCRIPTION
        Interactively collects ePO API connection information (server, port,
        credentials, SSL settings) via Read-Host prompts and returns an ePO API
        connection object.

    .OUTPUTS
        [PSCustomObject]. ePO API connection object with CallAPI method.

    .EXAMPLE
        $api = Read-HostEPOAPIInput

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version returning ePOAPIInfo class
            1.1.0 - Refactored to return Connect-ePOAPI connection object
    #>
    $server = Read-Host -Prompt "Please provide EPO server"
    if ($server -match "^(.+):([0-9]{1,5})$") {
        $port = $Matches.2
        $server = $Matches.1
    } else {
        $port = Read-Host -Prompt "What is the port number"
    }
    $user = Read-Host -Prompt "Please provide username"
    $password = Read-Host -Prompt "Please enter password" -AsSecureString
    $credential = New-Object System.Management.Automation.PSCredential($user, $password)
    $insecure = Read-Host -Prompt "Do you want to ignore SSL verification?"
    $ignoreSSL = $insecure.ToLower() -match "y(es)?"
    return Connect-ePOAPI -Server $server -Port $port -Credential $credential -IgnoreSSLError:$ignoreSSL
}
