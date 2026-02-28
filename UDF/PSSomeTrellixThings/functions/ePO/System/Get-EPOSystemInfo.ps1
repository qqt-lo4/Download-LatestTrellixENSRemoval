function Get-EPOSystemInfo {
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
        Version : 1.3.0

        Version History:
        1.0.0 - Initial version
        1.1.0 - Added EPOProductPropertyProducts.Products
        1.2.0 - Changed to use Get-EPOLeafNode
        1.3.0 - Added username and Refresh method
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
            "EPOComputerProperties.OSType"
            "EPOComputerProperties.OSVersion"
            "EPOLeafNode.Tags"
            "EPOLeafNode.LastUpdate"
            "EPOComputerProperties.UserName"
            "EPOProductPropertyProducts.Products"
            "EPOProdPropsView_EPOAGENT.productversion"
            "EPOProdPropsView_ENDPOINTSECURITYPLATFORM.productversion"
            "EPOProdPropsView_THREATPREVENTION.productversion"
            "EPOProdPropsView_TIECLIENTMETA.productversion"
            "AM_CustomProps.ManifestVersion"
            "AM_CustomProps.AMCoreContentDate"
            "AM_CustomProps.V2DATVersion"
            "EPOProdPropsView_VIRUSCAN.productversion"
            "EPOProdPropsView_VIRUSCAN.datver"
        )
        $oResult = Get-EPOLeafNode -ePOAPI $oePOAPI -Name $Name -Columns $aColumns -FilterDuplicates
        $oResult.PSTypeNames.Insert(0, "EPOSystem")
        $oResult | Add-Member -NotePropertyName "AdditionalProperties" -NotePropertyValue @{
            ePOAPI = $oePOAPI
            Columns = $aColumns
            Name = $Name
        }
        $oResult | Add-Member -MemberType ScriptMethod -Name "Refresh" -Value {
            $hAdditionalProperties = $this.AdditionalProperties
            $oNewResult = Get-EPOLeafNode @hAdditionalProperties -FilterDuplicates
            $aProperties = $this.PSObject.Properties | Where-Object { $_.Name -ne "AdditionalProperties" }
            foreach ($oProp in $aProperties) {
                $oPropName = $($oProp.Name)
                $this.$oPropName = $oNewResult.$oPropName
            }
        }
        return $oResult
    }
}
