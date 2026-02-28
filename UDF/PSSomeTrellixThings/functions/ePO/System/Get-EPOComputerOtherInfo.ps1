function Get-EPOComputerOtherInfo {
    <#
    .SYNOPSIS
        Retrieves network and user information for an ePO-managed computer

    .DESCRIPTION
        Queries ePO for a computer's network information (MAC addresses, IP, users).
        Uses SIR data if available, otherwise falls back to EPOComputerProperties.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER Computer
        The computer name or ePO system object to query.

    .OUTPUTS
        [PSCustomObject[]]. Array of network info objects (MAC addresses, IP, users).

    .EXAMPLE
        Get-EPOComputerOtherInfo -Computer "PC001"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$ePOAPI,
        [Parameter(Mandatory)]
        [object]$Computer
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
        $sComputerId = if ($Computer -is [string]) {
            (Get-EPOLeafNode -ePOAPI $oePOAPI -Name $Computer -FilterDuplicates)."EPOLeafNode.AutoID"
        } else {
            $Computer."EPOLeafNode.AutoID"
        }
    }
    Process {
        $sTarget = "EPOLeafNode"
        $aSIRNetworkInfo = Get-EPOComputerSIRNetworkInfo -ePOAPI $oePOAPI -Computer $Computer
        if ($aSIRNetworkInfo -eq $null) {
            $aColumns = @(
                "EPOLeafNode.AutoID"
                "EPOLeafNode.LastUpdate"
                "EPOLeafNode.NodeName"
                "EPOComputerProperties.UserName"
                "EPOComputerProperties.IPV6"
                "EPOComputerProperties.NetAddress"
                "EPOComputerProperties.EthernetMacAddressCount"
                "EPOComputerProperties.WirelessMacAddressCount"
                "EPOComputerProperties.OtherMacAddressCount"
                "EPOExtendedComputerProperties.EthernetMacAddress_1"
            )    
        } else {
            $aColumns = @(
                "EPOLeafNode.AutoID"
                "EPOLeafNode.LastUpdate"
                "EPOLeafNode.NodeName"
                "EPOComputerProperties.UserName"
                "EPOComputerProperties.IPV6"
            )    
        }
        $aColumns = Test-ePOColumns -Columns $aColumns -FilterInput
        $sSelect = "( select " + ($aColumns -join " ") + ")"
        $sOrderBy = "( order ( asc EPOLeafNode.NodeName ) )"
        $sWhere = "( where ( eq EPOLeafNode.AutoID $sComputerId ) )"
        $oApiResult = Invoke-ExecuteEPOQuery -ePOAPI $oePOAPI -select $sSelect -target $sTarget -order $sOrderBy -where $sWhere -outputformat json
        
        $rawData = $oApiResult.Value
        if ($aSIRNetworkInfo -eq $null) {
            $rawData | Add-Member -NotePropertyName "Mode" -NotePropertyValue "Other"
        } else {
            $rawData | Add-Member -NotePropertyName "Mode" -NotePropertyValue "SIR"
            $rawData | Add-Member -NotePropertyName "SIR" -NotePropertyValue $aSIRNetworkInfo
        }
        # Automatically process IP addresses
        if ($rawData."EPOComputerProperties.IPV6") {
            try {
                $ipObject = Convert-EPOIPObject -IPAddress $rawData."EPOComputerProperties.IPV6"
                $rawData | Add-Member -MemberType NoteProperty -Name "IPObject" -Value $ipObject -Force
            }
            catch {
                Write-Warning "Unable to convert IP '$($rawData."EPOComputerProperties.IPV6")' for $($rawData."EPOLeafNode.NodeName"): $($_.Exception.Message)"
                $rawData | Add-Member -MemberType NoteProperty -Name "IPObject" -Value $null -Force
            }
        }

        return Format-EPONetworkInfo $rawData
    }
}

function Format-EPONetworkInfo {
    <#
    .SYNOPSIS
        Formats raw ePO network data into structured objects

    .DESCRIPTION
        Processes raw network data from ePO queries and classifies MAC addresses
        by type (Ethernet, WiFi, Other), adds IP address and user information.

    .PARAMETER NetworkData
        The raw network data object from ePO queries.

    .OUTPUTS
        [PSCustomObject[]]. Array of formatted network info objects.

    .EXAMPLE
        $rawData | Format-EPONetworkInfo

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [object]$NetworkData
    )
    
    Process {
        $results = @()
        
        if ($NetworkData.Mode -eq "SIR") {
            foreach ($oConn in $NetworkData.SIR) {
                $results += $oConn
            }
        } else {
            # Retrieve Ethernet MACs
            $ethernetMacs = @()
            if ($NetworkData."EPOExtendedComputerProperties.EthernetMacAddress_1" -and $NetworkData."EPOExtendedComputerProperties.EthernetMacAddress_1" -ne "") {
                $ethernetMacs += [string]$NetworkData."EPOExtendedComputerProperties.EthernetMacAddress_1"
            }
            
            $wifiMacs = @()
            $otherMacs = @()
            
            # Parse NetAddress based on counters
            $netAddr = [string]$NetworkData."EPOComputerProperties.NetAddress"
            $ethernetCount = if ($NetworkData."EPOComputerProperties.EthernetMacAddressCount") { [int]$NetworkData."EPOComputerProperties.EthernetMacAddressCount" } else { 0 }
            $wirelessCount = if ($NetworkData."EPOComputerProperties.WirelessMacAddressCount") { [int]$NetworkData."EPOComputerProperties.WirelessMacAddressCount" } else { 0 }
            $otherCount = if ($NetworkData."EPOComputerProperties.OtherMacAddressCount") { [int]$NetworkData."EPOComputerProperties.OtherMacAddressCount" } else { 0 }
            
            if ($netAddr -and $netAddr -ne "") {
                # Normalize for comparison
                $normalizedNetAddr = $netAddr -replace "[-:]", ""
                $normalizedEthernet1 = if ($NetworkData."EPOExtendedComputerProperties.EthernetMacAddress_1") { 
                    ([string]$NetworkData."EPOExtendedComputerProperties.EthernetMacAddress_1") -replace "[-:]", "" 
                } else { "" }
                
                # If NetAddress differs from EthernetMacAddress_1, determine its type
                if ($normalizedNetAddr -ne $normalizedEthernet1) {
                    if ($wirelessCount -gt 0 -and $ethernetCount -le 1 -and $otherCount -eq 0) {
                        # Probably WiFi
                        $wifiMacs += [string]$netAddr
                    }
                    elseif ($ethernetCount -gt 1 -and $wirelessCount -eq 0 -and $otherCount -eq 0) {
                        # Probably additional Ethernet
                        $ethernetMacs += [string]$netAddr
                    }
                    elseif ($otherCount -gt 0) {
                        # Probably other type (VPN, Virtual, etc.)
                        $otherMacs += [string]$netAddr
                    }
                    elseif ($wirelessCount -gt 0) {
                        # Default to WiFi if there are wireless interfaces
                        $wifiMacs += [string]$netAddr
                    }
                    else {
                        # Ambiguous case, classify as "Other"
                        $otherMacs += [string]$netAddr
                    }
                }
            }
            
            # Add Ethernet MACs
            for ($i = 0; $i -lt $ethernetMacs.Count; $i++) {
                $results += [PSCustomObject]@{
                    Type = "Mac Ethernet"
                    Number = $i + 1
                    Value = New-MACAddressObject $ethernetMacs[$i]
                }
            }
            
            # Add WiFi MACs
            for ($i = 0; $i -lt $wifiMacs.Count; $i++) {
                $results += [PSCustomObject]@{
                    Type = "Mac Wifi"
                    Number = $i + 1
                    Value = New-MACAddressObject $wifiMacs[$i]
                }
            }
            
            # Add other MACs
            for ($i = 0; $i -lt $otherMacs.Count; $i++) {
                $results += [PSCustomObject]@{
                    Type = "Mac Other"
                    Number = $i + 1
                    Value = New-MACAddressObject $otherMacs[$i]
                }
            }
        }
        
        # Add IP address if available
        if ($NetworkData.IPObject) {
            $results += [PSCustomObject]@{
                Type = "IP Address"
                Number = 1
                Value = $NetworkData.IPObject
            }
        }

        if ($NetworkData."EPOComputerProperties.UserName") {
            $aUsers = $NetworkData."EPOComputerProperties.UserName".Split(",")
            for ($i = 0; $i -lt $aUsers.Count; $i++) {
                $results += [PSCustomObject]@{
                    Type = "User"
                    Number = $i
                    Value = $aUsers[$i]
                }   
            }
        }
        
        return $results
    }
}