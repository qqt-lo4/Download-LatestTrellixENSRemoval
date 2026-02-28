function Export-EPOClientTask {
    <#
    .SYNOPSIS
        Exports ePO client task definitions

    .DESCRIPTION
        Calls the clienttask.export Web API command to retrieve client task
        definitions for a specific product.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER productId
        The product ID to export tasks for.

    .OUTPUTS
        [System.Xml.XmlElement[]]. Client task definition objects.

    .EXAMPLE
        Export-EPOClientTask -productId "EPOAGENT____3000"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [string]$productId
    )
    Begin {
        $hParameters = Get-FunctionParameters -RemoveParam @("ePOAPI", "Verbose")
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        return ([xml]($oePOAPI.CallAPI("clienttask.export", $hParameters, "xml", "/result")).Value."#text").EPOTaskSchema.EPOTaskObjectInstance
    }
}