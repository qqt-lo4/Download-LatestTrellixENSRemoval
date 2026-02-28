function Get-EPOSystemProtectionStatus {
    <#
    .SYNOPSIS
        Get system info from Trellix ePO
        
    .DESCRIPTION
        Get installed products, versions, Tags, system tree path and AMCore version

    .LINK
        Import Needed: Test-ePOColumns, Invoke-ExecuteEPOQuery

    .EXAMPLE
        Get-EPOSystemProtectionStatus -Name $env:COMPUTERNAME
        Will get Endpoint product installed and component versions for the current computer

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
            "EPOLeafNode.LastUpdate"
            "EPOComputerProperties.OSVersion"
            "EPOComputerProperties.OSType"
            "EPOProductPropertyProducts.Products"
            "GS_CustomProps.IsSPEnabled"
            "AM_CustomProps.bOASEnabled"
            "AM_CustomProps.scanUsingAMSIHooks"
            "AM_CustomProps.bAPEnabled"
            "AM_CustomProps.bBOEnabled"
            "AM_CustomProps.bScriptScanEnabled"
            "AM_CustomProps.ManifestVersion"
            "AM_CustomProps.AMCoreContentDate"
            "AM_CustomProps.V2DATVersion"
            "ATP_CustomProps.ATPEnabled"
            "ATP_CustomProps.RPStaticEnabled"
            "ATP_CustomProps.RPEnabled"
        )
        $oResult = Get-EPOLeafNode -ePOAPI $oePOAPI -Name $Name -Columns $aColumns -FilterDuplicates
        return $oResult
    }
}
