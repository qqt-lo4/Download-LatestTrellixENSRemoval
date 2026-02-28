function Get-McAfeeENSTPProduct {
    <#
    .SYNOPSIS
        Gets the McAfee ENS Platform (Common) product info

    .DESCRIPTION
        Retrieves the installed ENS Platform product information
        by searching for its MSI package name (McAfee_Common).

    .PARAMETER programs
        A collection of installed programs to search through.

    .OUTPUTS
        Product information object for ENS Platform.

    .EXAMPLE
        Get-McAfeeENSTPProduct -programs $installedPrograms

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param (
        [Parameter(Position = 0)]
        [object]$programs
    )
    Get-ProductByPackageName -programs $programs -packageName @("McAfee_Common_x64.msi", "McAfee_Common_x86.msi")
}