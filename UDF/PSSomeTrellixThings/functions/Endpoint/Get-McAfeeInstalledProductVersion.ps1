function Get-McAfeeInstalledProductVersion {
    <#
    .SYNOPSIS
        Gets the version of an installed McAfee/Trellix product

    .DESCRIPTION
        Reads the version from the ePO Application Plugins registry key
        for a specific product.

    .PARAMETER McAfeeVersionsKey
        Registry key objects to search. Default: all keys from Get-McAfeeVersionsKey.

    .PARAMETER product
        The product name to look up (supports wildcards).

    .OUTPUTS
        [version]. The product version.

    .EXAMPLE
        Get-McAfeeInstalledProductVersion -product "VIRUSCAN*"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Microsoft.Win32.RegistryKey[]]$McAfeeVersionsKey = $(Get-McAfeeVersionsKey),
        [Parameter(Mandatory)]
        [string]$product
    )
    $McAfeeProductKey = $McAfeeVersionsKey | Where-Object { $_.Name.Split("\")[-1] -like $product }
    $McAfeeProductVersion = $McAfeeProductKey | ForEach-Object { [version]$_.GetValue("Version") }
    return [version]$McAfeeProductVersion
}
