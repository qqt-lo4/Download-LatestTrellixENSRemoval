function Find-EPOPackages {
    <#
    .SYNOPSIS
        Searches for packages in the ePO repository

    .DESCRIPTION
        Calls the repository.findPackages Web API command to search for
        packages in the ePO master repository.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER searchText
        Text to search for in package names.

    .OUTPUTS
        [System.Xml.XmlElement[]]. Package objects from the repository.

    .EXAMPLE
        Find-EPOPackages -searchText "AMCore"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,

        [Parameter(Position = 0)]
        [string]$searchText
    )
    Begin {
        $hParameters = Get-FunctionParameters -RemoveParam "ePOAPI"
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        $oAPICall = $oePOAPI.CallAPI("repository.findPackages", $hParameters)
        return $oAPICall.Value.result.list.element.PackageVO
    }
}