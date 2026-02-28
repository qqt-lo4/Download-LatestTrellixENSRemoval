function Get-EPOSoftwareDownloadURL {
    <#
    .SYNOPSIS
        Gets download URLs for Trellix software files

    .DESCRIPTION
        Queries the Trellix software catalog server to obtain download URLs
        for specified software file names.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER FileNames
        The file name(s) to get download URLs for.

    .OUTPUTS
        [System.Xml.XmlElement[]]. Download URL elements from the catalog.

    .EXAMPLE
        Get-EPOSoftwareDownloadURL -FileNames "FramePkg.exe"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePODB,
        [Parameter(Mandatory)]
        [string[]]$FileNames
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        $oEPOServerInfo = Get-EPOServerInfo
        $oSoftwareCatalogServer = Get-EPOSoftwareCatalogServer -ePODB $oePODB
        $sLicenseKey = $oEPOServerInfo.ePOLicense
        $sURL = "https://" + $oSoftwareCatalogServer.ServerName + "/" + $oSoftwareCatalogServer.DownloadUriURL
        $scVersion = (Get-EPOExtension -Name "SoftwareMgmt").Version
        $hArguments = @{
            licenseKey = $sLicenseKey
            epoVersion = $oEPOServerInfo.ePOVersion
            ibu = $oSoftwareCatalogServer.ibu
            scVersion = $scVersion
            fileNamesString = $FileNames -join "|"
        }
        $sFullURL = ConvertTo-URL -URL $sURL -Arguments $hArguments
        return ([xml]((Invoke-WebRequest -Uri $sFullURL -UseBasicParsing).Content)).SoftwareCatalogDownloadURL.DownloadFileURLs.DownloadFileURL
    }
}