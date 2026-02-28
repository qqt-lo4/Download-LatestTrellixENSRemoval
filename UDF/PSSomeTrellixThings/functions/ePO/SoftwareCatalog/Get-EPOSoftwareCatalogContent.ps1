function Get-EPOSoftwareCatalogContent {
    <#
    .SYNOPSIS
        Downloads the full Trellix software catalog content

    .DESCRIPTION
        Retrieves the complete licensed software catalog XML from the Trellix
        software catalog server using the ePO license key and server info.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .OUTPUTS
        [System.Xml.XmlDocument]. The software catalog XML content.

    .EXAMPLE
        $catalog = Get-EPOSoftwareCatalogContent

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePODB
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        $oEPOServerInfo = Get-EPOServerInfo -ePODB $oePODB
        $oSoftwareCatalogServer = Get-EPOSoftwareCatalogServer -ePODB $oePODB
        $sLicenseKey = $oEPOServerInfo.ePOLicense
        $sURL = "https://" + $oSoftwareCatalogServer.ServerName + "/" + $oSoftwareCatalogServer.LicensedURL
        $scVersion = (Get-EPOExtension -Name "SoftwareMgmt").Version
        $hArguments = @{
            licenseKey = $sLicenseKey
            epoVersion = $oEPOServerInfo.ePOVersion
            ibu = $oSoftwareCatalogServer.ibu
            scVersion = $scVersion
        }
        $sFullURL = ConvertTo-URL -URL $sURL -Arguments $hArguments
        Write-Progress -Activity "Downloading Software Catalog content"
        $oResult = [xml]((Invoke-WebRequest -Uri $sFullURL -UseBasicParsing).Content)
        Write-Progress -Activity "Downloading Software Catalog content" -Completed
        return $oResult
    }
}