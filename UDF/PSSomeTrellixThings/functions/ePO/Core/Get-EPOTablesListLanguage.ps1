function Get-EPOTablesListLanguage {
    <#
    .SYNOPSIS
        Detects the language of the ePO server tables

    .DESCRIPTION
        Queries the EPOComputerProperties table name via the Web API to determine
        if the ePO server is configured in French or English.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .OUTPUTS
        [string]. The detected language code: "fr" or "en".

    .EXAMPLE
        Get-EPOTablesListLanguage

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
        $hArguments = @{table = "EPOComputerProperties"}
    }
    Process {
        $oEPOComputerPropertiesTable = ($oePOAPI.CallAPI("core.listTables", $hArguments, "json")).Value | ConvertTo-Hashtable
        $sTableName = $oEPOComputerPropertiesTable.name
    }
    End {
        $sResult = switch ($sTableName) {
            "Propriétés de l'ordinateur" { "fr" }
            Default { "en" }
        }    
        return $sResult
    }
}