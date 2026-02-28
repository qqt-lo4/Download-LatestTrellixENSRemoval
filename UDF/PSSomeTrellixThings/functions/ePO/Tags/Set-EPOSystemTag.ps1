function Set-EPOSystemTag {
    <#
    .SYNOPSIS
        Applies a tag to ePO-managed systems

    .DESCRIPTION
        Calls the system.applyTag Web API command to apply a tag
        to one or more systems.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER names
        The system name(s) to apply the tag to.

    .PARAMETER tagName
        The tag name to apply.

    .OUTPUTS
        [PSCustomObject]. API result of the tag application.

    .EXAMPLE
        Set-EPOSystemTag -names "PC001" -tagName "Windows 11"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string[]]$names,
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$tagName
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $epoAPI } else { $Global:ePOAPI }
    }
    Process {
        $hArguments = @{
            names = $names -join ","
            tagName = $tagName
        }
        return $oePOAPI.CallAPI("system.applyTag", $hArguments)
    }
}