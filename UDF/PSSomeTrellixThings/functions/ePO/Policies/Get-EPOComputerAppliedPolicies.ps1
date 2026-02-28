function Get-EPOComputerAppliedPolicies {
    <#
    .SYNOPSIS
        Retrieves policies applied to a specific computer

    .DESCRIPTION
        Queries the EPOAssignedPolicy table for a given computer and enriches
        results with policy details including product name, type, and name.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER Computer
        The computer name or ePO system object to query.

    .OUTPUTS
        [PSCustomObject[]]. Applied policy objects with enriched properties.

    .EXAMPLE
        Get-EPOComputerAppliedPolicies -Computer "PC001"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory)]
        [object]$Computer
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
        $sComputerName = if ($Computer -is [string]) { $Computer } else { $Computer."EPOLeafNode.NodeName" }
    }
    Process {
        $aColumns = @(
            "EPOLeafNode.AutoID"
            "EPOAssignedPolicy.NodeName"
            "EPOAssignedPolicy.PolicyObjectID"
            "EPOAssignedPolicy.Origin"
            "EPOAssignedPolicy.PolicyDesc"
            "EPOAssignedPolicy.upToDate"
            "EPOAssignedPolicy.uid"
        )
        $aColumns = Test-ePOColumns -Columns $aColumns -FilterInput
        if ($aColumns) {
            $oEPOComputer = Get-EPOLeafNode -ePOAPI $oePOAPI -Name $sComputerName
            $iAutoId = $oEPOComputer."EPOLeafNode.AutoID"
            $sTarget = "EPOAssignedPolicy"
            $sSelect = "( select " + ($aColumns -join " ") + ")"
            $sOrderBy = "( order ( asc EPOAssignedPolicy.NodeName ) )"
            $sWhere = "( where ( eq EPOLeafNode.AutoID $iAutoId ) )"
            $oApiResult = Invoke-ExecuteEPOQuery -ePOAPI $oePOAPI -select $sSelect -target $sTarget -order $sOrderBy -where $sWhere -outputformat json
            
            $aPolicies = Find-EPOPolicy
            foreach ($oAppliedPolicy in $oApiResult.Value) {
                $oPolicy = $aPolicies | Where-Object { $_.objectId -eq $oAppliedPolicy."EPOAssignedPolicy.PolicyObjectID" }
                $oAppliedPolicy | Add-Member -NotePropertyName "EPOAssignedPolicy.Object" -NotePropertyValue $oPolicy
                $oAppliedPolicy | Add-Member -NotePropertyName "EPOAssignedPolicy.Product" -NotePropertyValue $oPolicy.productName
                $oAppliedPolicy | Add-Member -NotePropertyName "EPOAssignedPolicy.Type" -NotePropertyValue $oPolicy.typeName
                $oAppliedPolicy | Add-Member -NotePropertyName "EPOAssignedPolicy.Name" -NotePropertyValue $oPolicy.objectName
            }
            return $oApiResult.Value
        } else { 
            return $null
        }
    }
}
