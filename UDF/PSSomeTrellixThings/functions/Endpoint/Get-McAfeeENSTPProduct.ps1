function Get-McAfeeENSTPProduct {
    <#
    .SYNOPSIS
        Gets the McAfee ENS Threat Prevention product info

    .DESCRIPTION
        Retrieves the installed ENS Threat Prevention product information
        by searching for its MSI package name.

    .PARAMETER programs
        A collection of installed programs to search through.

    .OUTPUTS
        Product information object for ENS Threat Prevention.

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
    Get-ProductByPackageName -programs $programs -packageName @("McAfee_Threat_Prevention_x64.msi", "McAfee_Threat_Prevention_x86.msi")
}