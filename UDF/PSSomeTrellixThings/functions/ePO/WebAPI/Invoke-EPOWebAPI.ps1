function Invoke-EPOWebAPI {
    <#
    .SYNOPSIS
        Invokes a Trellix ePO Web API command

    .DESCRIPTION
        Executes an ePO Web API command with the specified output format, locale, and arguments.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER OutputFormat
        The output format: xml, json, terse, verbose, or PSObject. Default: xml.

    .PARAMETER Command
        The ePO API command to execute (e.g., "system.find").

    .PARAMETER Locale
        The locale for the API response: fr or en. Default: en.

    .PARAMETER Arguments
        A hashtable of additional arguments for the API command.

    .PARAMETER XPath
        An XPath expression to filter XML output.

    .OUTPUTS
        [PSCustomObject]. API result with Http, Success, Status, Value, OutputType, and URL properties.

    .EXAMPLE
        Invoke-EPOWebAPI -Command "system.find" -Arguments @{searchText="PC001"} -OutputFormat json

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [ValidateNotNullOrEmpty()]
        [ValidateSet('xml','json','terse','verbose','PSObject')]
        [string]$OutputFormat = 'xml',
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Command,
        [ValidateNotNullOrEmpty()]
        [ValidateSet('fr','en')]
        [string]$Locale = 'en',
        [hashtable]$Arguments = @{},
        [string]$XPath = ""
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        $oAPIResult = $oePOAPI.CallAPI($Command, $Arguments, $OutputFormat, $XPath, $Locale)
        return $oAPIResult
    }    
}
