function Get-EPOClientTask {
    <#
    .SYNOPSIS
        Searches for ePO client tasks

    .DESCRIPTION
        Calls the clienttask.find Web API command to search for client tasks
        and enriches the results with task definitions from clienttask.export.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER searchText
        Text to search for in client task names.

    .OUTPUTS
        [PSCustomObject[]]. Client task objects with Definition property.

    .EXAMPLE
        Get-EPOClientTask -searchText "Update"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [string]$searchText
    )
    Begin {
        $hParameters = Get-FunctionParameters -RemoveParam @("ePOAPI", "Verbose")
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        $aTasksResult = ($oePOAPI.CallAPI("clienttask.find", $hParameters, "json")).Value
        $hTasksDefinitions = @{}
        foreach ($sProduct in ($aTasksResult.ProductId | Select-Object -Unique)) {
            $aProductTasks = Export-EPOClientTask -ePOAPI $oePOAPI -productId $sProduct
            if ($aProductTasks) {
                $hTasksDefinitions.$sProduct = $aProductTasks
            }
        }
        foreach ($oTask in $aTasksResult) {
            $oTaskDefinition = $hTasksDefinitions[$oTask.productId] | Where-Object { $_.name -eq $oTask.objectName }
            if ($oTaskDefinition) {
                $oTask | Add-Member -NotePropertyName "Definition" -NotePropertyValue $oTaskDefinition
            }
        }
        return $aTasksResult
    }
}