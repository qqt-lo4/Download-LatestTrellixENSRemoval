function Get-McAfeeVersionsKey {
    <#
    .SYNOPSIS
        Gets McAfee product version registry keys

    .DESCRIPTION
        Reads the ePO Application Plugins registry keys to retrieve installed
        McAfee/Trellix product version information.

    .PARAMETER nameFilter
        A wildcard filter for the plugin name. If omitted, returns all plugins.

    .OUTPUTS
        [Microsoft.Win32.RegistryKey[]]. Registry key objects for matching plugins.

    .EXAMPLE
        Get-McAfeeVersionsKey -nameFilter "VIRUSCAN*"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Position = 0)]
        [string]$nameFilter = "" 
    )
    $versionKey = if ([Environment]::Is64BitOperatingSystem) {
        "hklm:\SOFTWARE\WOW6432Node\Network Associates\ePolicy Orchestrator\Application Plugins"
    } else {
        "hklm:\SOFTWARE\Network Associates\ePolicy Orchestrator\Application Plugins"
    }
    $result = Get-ChildItem $versionKey
    if ($nameFilter) {
        $result = $result | Where-Object { $_.Name.Split("\")[-1] -like $nameFilter }
    }
    return $result
}
