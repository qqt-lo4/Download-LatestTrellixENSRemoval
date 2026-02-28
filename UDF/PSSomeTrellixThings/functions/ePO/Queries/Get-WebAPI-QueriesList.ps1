function Get-WebAPI-QueriesList {
    <#
    .SYNOPSIS
        Retrieves the list of ePO queries via the Web API

    .DESCRIPTION
        Calls the core.listQueries Web API command to retrieve all available queries
        from the ePO server.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER outputformat
        The output format: xml, json, terse, verbose, or PSObject. Default: xml.

    .OUTPUTS
        Query list in the specified output format.

    .EXAMPLE
        Get-WebAPI-QueriesList -ePOAPI $api -outputformat json

    .EXAMPLE
        Get-WebAPI-QueriesList -outputformat PSObject
        Uses $Global:ePOAPI

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePOAPIInfo class
            1.1.0 - Refactored to use Connect-ePOAPI connection object
    #>
    Param(
        [object]$ePOAPI,
        [ValidateNotNullOrEmpty()]
        [ValidateSet('xml','json','terse', 'verbose', 'PSObject')]
        [string]$outputformat = 'xml'
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        if ($outputformat -eq "PSObject") {
            $xpath = "/result/list/query"
            return $oePOAPI.CallAPI("core.listQueries", @{}, $outputformat, $xpath)
        } else {
            return $oePOAPI.CallAPI("core.listQueries", @{}, $outputformat)
        }
    }
}
