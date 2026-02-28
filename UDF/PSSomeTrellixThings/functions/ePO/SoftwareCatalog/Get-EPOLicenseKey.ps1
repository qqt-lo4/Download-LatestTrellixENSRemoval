function Get-EPOLicenseKey {
    <#
    .SYNOPSIS
        Retrieves the ePO license key from the database

    .DESCRIPTION
        Gets the ePO license key from the EPOServerInfo table.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .OUTPUTS
        [string]. The ePO license key.

    .EXAMPLE
        Get-EPOLicenseKey

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
        return (Get-EPOServerInfo -ePODB $oePODB).ePOLicense
    }
}