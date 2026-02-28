function Get-McAfeeENSATPProduct {
    <#
    .SYNOPSIS
        Gets the McAfee ENS Adaptive Threat Protection product info

    .DESCRIPTION
        Retrieves the installed ENS Adaptive Threat Protection product information
        by searching for its MSI package name.

    .PARAMETER programs
        A collection of installed programs to search through.

    .OUTPUTS
        Product information object for ENS ATP.

    .EXAMPLE
        Get-McAfeeENSATPProduct -programs $installedPrograms

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    param (
        [Parameter(Position = 0)]
        [object]$programs
    )
    Get-ProductByPackageName -programs $programs -packageName @("McAfee_Adaptive_Threat_Protection_x64.msi", "McAfee_Adaptive_Threat_Protection_x86.msi")
}