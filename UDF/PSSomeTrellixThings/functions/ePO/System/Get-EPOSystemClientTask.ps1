function Get-EPOSystemClientTask {
    <#
    .SYNOPSIS
        Gets client tasks applicable to a specific system

    .DESCRIPTION
        Retrieves all client tasks that match the products installed on a given system.
        Optionally filters out read-only tasks without definitions.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER Name
        The system name to query.

    .PARAMETER IgnoreROTasks
        Ignores tasks without a definition (read-only tasks).

    .OUTPUTS
        [PSCustomObject[]]. Client task objects applicable to the system.

    .EXAMPLE
        Get-EPOSystemClientTask -Name "PC001" -IgnoreROTasks

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory, Position = 0)]
        [string]$Name,
        [switch]$IgnoreROTasks
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
        $aColumns = @(
            "EPOLeafNode.AutoID"
            "EPOLeafNode.NodeName"
            "EPOComputerProperties.OSType"
            "EPOComputerProperties.OSVersion"
            "EPOProductPropertyProducts.Products"
        )
        $oSystem = Get-EPOLeafNode -ePOAPI $oePOAPI -Name $Name -Columns $aColumns -FilterDuplicates
        $aSystemProducts = $oSystem."EPOProductPropertyProducts.Products".Split(",").Trim()
        $aAllTasks = Get-EPOClientTask -ePOAPI $oePOAPI
        $aResult = @()
    }
    Process {
        foreach ($oTask in $aAllTasks) {
            if ($oTask.typeName.Split(":")[0] -in $aSystemProducts) {
                if ($oTask.Definition) {
                    $aResult += $oTask
                } else {
                    if (-not $IgnoreROTasks) {
                        $aResult += $oTask
                    }
                }
            }
        }
        return $aResult
    }
}

