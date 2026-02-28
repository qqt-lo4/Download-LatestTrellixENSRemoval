function Get-EPOTablesList {
    <#
    .SYNOPSIS
        Lists available tables and columns in the ePO server

    .DESCRIPTION
        Calls the core.listTables Web API command to retrieve table definitions,
        columns, foreign keys, and related tables. Returns parsed objects with
        a ColumnExists helper method.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER table
        A specific table name to query. If omitted, returns all tables.

    .PARAMETER Language
        The language for table descriptions.

    .OUTPUTS
        [PSCustomObject]. Object with List, Hashtable properties and ColumnExists method.

    .EXAMPLE
        Get-EPOTablesList -table "EPOLeafNode"

    .EXAMPLE
        $tables = Get-EPOTablesList
        $tables.ColumnExists("EPOLeafNode.NodeName")

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Position = 0)]
        [string]$table,
        [string]$Language
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
        $hArguments = if ($table) { @{table = $table} } else { @{} }
        $hTranslatedValues = @{
            "Select?" = { $args[0].ToString().ToLower() -in @("true", "vrai") }
            "Condition?" = { $args[0].ToString().ToLower() -in @("true", "vrai") }
            "GroupBy?" = { $args[0].ToString().ToLower() -in @("true", "vrai") }
            "Order?" = { $args[0].ToString().ToLower() -in @("true", "vrai") }
            "Number?" = { $args[0].ToString().ToLower() -in @("true", "vrai") }
            "Allows inverse?" = { $args[0].ToString().ToLower() -in @("true", "vrai") }
            "One-to-one?" = { $args[0].ToString().ToLower() -in @("true", "vrai") }
            "Many-to-one?" = { $args[0].ToString().ToLower() -in @("true", "vrai") }
        }
        $aColumnsHeaders = @("Name", "Type", "Select?", "Condition?", "GroupBy?", "Order?", "Number?")
        $aForeignKeysHeaders = @("Source table", "Source Columns", "Destination table", "Destination columns", "Allows inverse?", "One-to-one?", "Many-to-one?")
    }
    Process {
        $aEPOTableList = ($oePOAPI.CallAPI("core.listTables", $hArguments, "json")).Value | ConvertTo-Hashtable
        $hResult = New-Object System.Collections.Hashtable 
        foreach ($oTable in $aEPOTableList) {
            if ($oTable.foreignKeys) {
                $oTable.foreignKeys = Convert-TSVWithDashLine -dataArray $oTable.foreignKeys -TranslatedHeaders $aForeignKeysHeaders -TranslateValues $hTranslatedValues
            }
            if ($oTable.relatedTables) {
                $aRelatedTables = Convert-TSVWithDashLine -dataArray $oTable.relatedTables
                $aTempResult = @()
                foreach ($obj in $aRelatedTables) {
                    $sNewValue = $obj[$obj.Keys]
                    if (([string]$sNewValue).Trim() -ne "") {
                        $aTempResult += $sNewValue
                    }
                }
                $oTable.relatedTables = $aTempResult
            }
            if ($oTable.columns) {
                $oTable.columns = Convert-TSVWithDashLine -dataArray $oTable.columns -TranslatedHeaders $aColumnsHeaders -TranslateValues $hTranslatedValues
            }
            $hResult.($oTable.target) = $oTable
        }
        if ($table) {
            return $aEPOTableList
        } else {
            $oResult = [pscustomobject]@{
                List = $aEPOTableList
                Hashtable = $hResult
            }
            $oResult | Add-Member -MemberType ScriptMethod -Name "ColumnExists" -Value {
                Param([string]$column)
                $ss = Select-String -InputObject $column -Pattern "(?<table>[^.]+)\.(?<column>.+)" -AllMatches
                $sTable = ($ss.Matches.Groups | Where-Object { $_.name -eq "table" }).Value
                $sColumn = ($ss.Matches.Groups | Where-Object { $_.name -eq "column" }).Value
                $oTable = $this.Hashtable[$sTable]
                if ($oTable) {
                    $oColumn = $oTable.columns | Where-Object { $_.Name -eq $sColumn}
                    return ($null -ne $oColumn)
                } else {
                    return $false
                }
            }
            return $oResult    
        }
    }
}
