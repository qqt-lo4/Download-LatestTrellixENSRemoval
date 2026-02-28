function Find-EPOSystemOnNetwork {
    <#
    .SYNOPSIS
        Finds ePO-managed systems on a specific network

    .DESCRIPTION
        Queries the ePO server for systems matching a network address, IP range,
        or single IP address using IPv6-based filtering.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER Network
        The network, IP range, or IP address object to search.

    .OUTPUTS
        [PSCustomObject[]]. System objects typed as EPOSystem.

    .EXAMPLE
        Find-EPOSystemOnNetwork -Network $networkObject

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,

        [Parameter(Mandatory, Position = 0)]
        [Alias("IP", "Range")]
        [object]$Network
    )

    $aColumns = @(
        "EPOComputerProperties.ParentID"
        "EPOComputerProperties.ComputerName"
        "EPOComputerProperties.Description"
        "EPOComputerProperties.ComputerDescription"
        "EPOComputerProperties.TimeZone"
        "EPOComputerProperties.DefaultLangID"
        "EPOComputerProperties.UserName"
        "EPOComputerProperties.DomainName"
        "EPOComputerProperties.IPHostName"
        "EPOComputerProperties.IPV6"
        "EPOComputerProperties.IPAddress"
        "EPOComputerProperties.IPSubnet"
        "EPOComputerProperties.IPSubnetMask"
        "EPOComputerProperties.IPV4x"
        "EPOComputerProperties.IPXAddress"
        "EPOComputerProperties.SubnetAddress"
        "EPOComputerProperties.SubnetMask"
        "EPOComputerProperties.NetAddress"
        "EPOComputerProperties.OSType"
        "EPOComputerProperties.OSVersion"
        "EPOComputerProperties.OSCsdVersion"
        "EPOComputerProperties.OSBuildNum"
        "EPOComputerProperties.OSPlatform"
        "EPOComputerProperties.OSOEMID"
        "EPOComputerProperties.CPUType"
        "EPOComputerProperties.CPUSpeed"
        "EPOComputerProperties.NumOfCPU"
        "EPOComputerProperties.CPUSerialNumber"
        "EPOComputerProperties.TotalPhysicalMemory"
        "EPOComputerProperties.FreeMemory"
        "EPOComputerProperties.FreeDiskSpace"
        "EPOComputerProperties.TotalDiskSpace"
        "EPOComputerProperties.IsPortable"
        "EPOComputerProperties.Vdi"
        "EPOComputerProperties.OSBitMode"
        "EPOComputerProperties.LastAgentHandler"
        "EPOComputerProperties.UserProperty1"
        "EPOComputerProperties.UserProperty2"
        "EPOComputerProperties.UserProperty3"
        "EPOComputerProperties.UserProperty4"
        "EPOComputerProperties.UserProperty5"
        "EPOComputerProperties.UserProperty6"
        "EPOComputerProperties.UserProperty7"
        "EPOComputerProperties.UserProperty8"
        "EPOComputerProperties.Free_Space_of_Drive_C"
        "EPOComputerProperties.Total_Space_of_Drive_C"
        "EPOLeafNode.Tags"
        "EPOLeafNode.ExcludedTags"
        "EPOLeafNode.LastUpdate"
        "EPOLeafNode.ManagedState"
        "EPOLeafNode.AgentGUID"
        "EPOLeafNode.AgentVersion"
        "EPOBranchNode.AutoID"
    )

    $sTarget = "EPOLeafNode"
    $sOrderBy = "( order ( asc EPOLeafNode.NodeName ) )"
    $aColumns = Test-ePOColumns -Columns $aColumns -FilterInput
    $sSelect = "( select " + ($aColumns -join " ") + ")"
    $sWhere = switch ($Network.Type) {
        "Network" {
            "(where (in_ipv6_subnet EPOComputerProperties.IPV6 (ipv6 ""$($Network.Network.ToString())"" ) $($Network.Mask.GetMaskLength()) ))"
        }
        "Range" {
            "(where (between EPOComputerProperties.IPV6 (ipv6 ""$($Network.First.ToString())"") (ipv6 ""$($Network.Last.ToString())"") ))"
        }
        "IP" {
            "(where (eq EPOComputerProperties.IPV6 (ipv6 ""$($Network.ToString())"")))"
        }
    }
    $oApiResult = Invoke-ExecuteEPOQuery -ePOAPI $oePOAPI -select $sSelect -target $sTarget -order $sOrderBy -where $sWhere -outputformat json
    return $oApiResult.Value | ForEach-Object { $_.PSTypeNames.Insert(0, "EPOSystem") ; $_ }
}
