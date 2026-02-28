function Get-EPOComputerAppliedTasks {
    <#
    .SYNOPSIS
        Retrieves client tasks applied to a specific computer

    .DESCRIPTION
        Queries the EPOTaskAppliedTasks table for a given computer and enriches
        results with task definitions including product name and task type.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER Computer
        The computer name or ePO system object to query.

    .OUTPUTS
        [PSCustomObject[]]. Applied task objects with enriched properties.

    .EXAMPLE
        Get-EPOComputerAppliedTasks -Computer "PC001"

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
            "EPOLeafNode.NodeName"
            "EPOTaskAppliedTasks.ProductCode"
            "EPOTaskAppliedTasks.Name"
            "EPOTaskAppliedTasks.ServerId"
            "EPOTaskAppliedTasks.NodeTxtPath"
            "EPOTaskAppliedTasks.TagAssigned"
            "EPOTaskAppliedTasks.Description"
            "EPOTaskAppliedTasks.upToDate"
            "EPOTaskAppliedTasks.TaskTypeId"
            "EPOTaskAppliedTasks.UUID" 
        )

        $aColumns = Test-ePOColumns -Columns $aColumns -FilterInput
        if ($aColumns) {
            $oEPOComputer = Get-EPOLeafNode -ePOAPI $oePOAPI -Name $sComputerName
            $iAutoId = $oEPOComputer."EPOLeafNode.AutoID"
            $sTarget = "EPOTaskAppliedTasks"
            $sSelect = "( select " + ($aColumns -join " ") + ")"
            $sOrderBy = "( order ( asc EPOTaskAppliedTasks.NodeTxtPath ) )"
            $sWhere = "( where ( eq EPOLeafNode.AutoID $iAutoId ) )"
            $oApiResult = Invoke-ExecuteEPOQuery -ePOAPI $oePOAPI -select $sSelect -target $sTarget -order $sOrderBy -where $sWhere -outputformat json

            $aTasks = Get-EPOClientTask
            foreach ($oAppliedTask in $oApiResult.Value) {
                $oTask = $aTasks | Where-Object { ($_.productId -eq $oAppliedTask."EPOTaskAppliedTasks.ProductCode") -and 
                                                  ($_.objectName -eq $oAppliedTask."EPOTaskAppliedTasks.Name") }
                $oAppliedTask | Add-Member -NotePropertyName "EPOTaskAppliedTasks.Object" -NotePropertyValue $oTask
                $oAppliedTask | Add-Member -NotePropertyName "EPOTaskAppliedTasks.ObjectId" -NotePropertyValue $oTask.objectId
                $oAppliedTask | Add-Member -NotePropertyName "EPOTaskAppliedTasks.Type" -NotePropertyValue $oTask.typeName.Split(":")[1].Trim()
                $oAppliedTask | Add-Member -NotePropertyName "EPOTaskAppliedTasks.ProductName" -NotePropertyValue $oTask.productName
            }

            return $oApiResult.Value
        } else { 
            return $null
        }
    }
}
