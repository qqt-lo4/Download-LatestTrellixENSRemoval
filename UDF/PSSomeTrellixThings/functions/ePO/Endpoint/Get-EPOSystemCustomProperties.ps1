function Get-EPOSystemCustomProperties {
    <#
    .SYNOPSIS
        Get custom properties for system from Trellix ePO
        
    .DESCRIPTION
        Get custom properties for system from Trellix ePO

    .LINK
        Import Needed: Test-ePOColumns, Invoke-ExecuteEPOQuery

    .EXAMPLE
        Get-EPOSystemCustomProperties -Name $env:COMPUTERNAME
        Will get system custom properties from ePO for the current computer

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
        1.0.0 - Initial version
        1.1.0 - Using Get-EPOLeafNode to remove duplicates
    #>    
    
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
    }
    Process {
        $aColumns = @(
            "EPOLeafNode.NodeName"
            "EPOBranchNode.NodeTextPath2"
            "EPOLeafNode.LastUpdate"
            "EPOLeafNode.Tags"
            "EPOComputerProperties.UserProperty1"
            "EPOComputerProperties.UserProperty2"
            "EPOComputerProperties.UserProperty3"
            "EPOComputerProperties.UserProperty4"
            "EPOComputerProperties.UserProperty5"
            "EPOComputerProperties.UserProperty6"
            "EPOComputerProperties.UserProperty7"
            "EPOComputerProperties.UserProperty8"
        )
        $oResult = Get-EPOLeafNode -ePOAPI $oePOAPI -Name $Name -Columns $aColumns -FilterDuplicates
        return $oResult
    }
}
