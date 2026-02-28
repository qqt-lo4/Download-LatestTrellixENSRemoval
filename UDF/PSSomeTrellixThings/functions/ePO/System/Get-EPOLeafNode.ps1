function Get-EPOLeafNode {
    <#
    .SYNOPSIS
        Get system info from Trellix ePO
        
    .DESCRIPTION
        Get installed products, versions, Tags, system tree path and AMCore version

    .LINK
        Import Needed: Test-ePOColumns, Invoke-ExecuteEPOQuery

    .EXAMPLE
        Get-EPOSystemInstalledProducts -Name $env:COMPUTERNAME
        Will get Endpoint product installed and component versions for the current computer

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
        1.0.0 - Initial version
        1.1.0 - Fixed bug when $Columns was not provided
    #>    
    
    Param(
        [object]$ePOAPI,
        [Parameter(Position = 0)]
        [string]$Name,
        [string[]]$Columns,
        [switch]$FilterDuplicates
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
        $aColumns = @()
        if ("EPOLeafNode.AutoID" -notin $Columns) {
            $aColumns += "EPOLeafNode.AutoID"
        } 
        if ("EPOLeafNode.LastUpdate" -notin $Columns) {
            $aColumns += "EPOLeafNode.LastUpdate"
        }
        if ($Columns) {
            $aColumns += $Columns
        }
    }
    Process {
        $sTarget = "EPOLeafNode"
        $sOrderBy = "( order ( asc EPOLeafNode.NodeName ) )"
        $aColumns = Test-ePOColumns -Columns $aColumns -FilterInput
        $sSelect = "( select " + ($aColumns -join " ") + ")"
        $sWhere = if ($Name) {
            if ($Name -match "^[0-9]+$") {
                "( where ( eq EPOLeafNode.AutoID $Name ) )"
            } else {
                "( where ( eq EPOLeafNode.NodeName `"$Name`" ) )"
            }
        } else { 
            ""
        }
        $oApiResult = Invoke-ExecuteEPOQuery -ePOAPI $oePOAPI -select $sSelect -target $sTarget -order $sOrderBy -where $sWhere -outputformat json
        if ($FilterDuplicates) {
            if ($oApiResult.Value.Count -gt 1) {
                $oDate = Get-Date -Year 1 -Month 1 -Day 1 -Hour 0 -Minute 0
                $oResult = $null 
                foreach ($oSystem in $oApiResult.Value) {
                    if (($oSystem."EPOLeafNode.LastUpdate" -ne "null") -and ([datetime]($oSystem."EPOLeafNode.LastUpdate") -gt $oDate)) {
                        $oDate = [datetime]($oSystem."EPOLeafNode.LastUpdate")
                        $oResult = $oSystem
                    }
                } 
                return $oResult
            } else {
                return $oApiResult.Value
            }
        } else {
            return $oApiResult.Value
        }
    }
}
