function Test-WebAPIConnection {
    <#
    .SYNOPSIS
        Tests if the ePO Web API connection is active

    .DESCRIPTION
        Validates the ePO API connection by calling core.help and checking for a successful response.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .OUTPUTS
        [bool]. $true if the connection is active, $false otherwise.

    .EXAMPLE
        Test-WebAPIConnection -ePOAPI $api

    .EXAMPLE
        Test-WebAPIConnection
        Uses $Global:ePOAPI

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePOAPIInfo class
            1.1.0 - Refactored to use Connect-ePOAPI connection object
    #>
    Param(
        [object]$ePOAPI
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        try {
            return $oePOAPI.CallAPI("core.help").Success
        } catch {
            return $false
        }
    }
}
