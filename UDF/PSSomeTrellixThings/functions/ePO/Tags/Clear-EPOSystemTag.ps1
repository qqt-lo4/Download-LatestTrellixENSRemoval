function Clear-EPOSystemTag {
    <#
    .SYNOPSIS
        Removes tags from ePO-managed systems

    .DESCRIPTION
        Calls the system.clearTag Web API command to remove a specific tag
        or all tags from one or more systems.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER names
        The system name(s) or ID(s) to clear tags from.

    .PARAMETER tagName
        The specific tag name to remove.

    .PARAMETER all
        Removes all tags from the specified systems.

    .OUTPUTS
        [PSCustomObject]. API result of the tag clearing operation.

    .EXAMPLE
        Clear-EPOSystemTag -names "PC001" -tagName "Windows 10"

    .EXAMPLE
        Clear-EPOSystemTag -names "PC001","PC002" -all

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory, Position = 0)]
        [Alias("ids")]
        [string[]]$names,
        [Parameter(Mandatory, Position = 1, ParameterSetName = "OneTag")]
        [string]$tagName,
        [Parameter(Position = 1, ParameterSetName = "AllTags")]
        [switch]$all
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $epoAPI } else { $Global:ePOAPI }
    }
    Process {
        $hArguments = @{
            names = $names -join ","
        }
        if ($all) {
            $hArguments.all = "true"
        } else {
            $hArguments.tagName = $tagName
        }
        return $oePOAPI.CallAPI("system.clearTag", $hArguments, "json").Value
    }
}