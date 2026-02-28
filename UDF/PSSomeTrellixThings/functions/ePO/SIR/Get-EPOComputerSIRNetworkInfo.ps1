function Get-EPOComputerSIRNetworkInfo {
    <#
    .SYNOPSIS
        Retrieves SIR network information for an ePO-managed computer

    .DESCRIPTION
        Queries the MPSDE_SIRGenericView table for Ethernet and WiFi network adapter
        information (friendly names and MAC addresses) reported by the SIR module.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER Computer
        The computer name or ePO system object to query.

    .OUTPUTS
        [PSCustomObject[]] or $null. Array of network adapter objects with Type, Number,
        Connection Name, and Value (MAC address) properties. Returns $null if SIR columns
        are not available.

    .EXAMPLE
        Get-EPOComputerSIRNetworkInfo -Computer "PC001"

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
        $sComputerName = if ($Computer -is [string]) { $Computer } else { $Computer."EPOLeafNode.NodeName" }
    }
    Process {
        $aColumns = @(
            "MPSDE_SIRGenericView.SettingName"
            "MPSDE_SIRGenericView.Value"
        )
        $aColumns = Test-ePOColumns -Columns $aColumns -FilterInput
        if ($aColumns) {
            $oEPOComputer = Get-EPOLeafNode -ePOAPI $oePOAPI -Name $sComputerName
            $iAutoId = $oEPOComputer."EPOLeafNode.AutoID"
            $sTarget = "MPSDE_SIRGenericView"
            $sSelect = "( select " + ($aColumns -join " ") + ")"
            $sOrderBy = "( order ( asc MPSDE_SIRGenericView.Nodename ) )"
            $sWhere = "( where ( and ( eq MPSDE_SIRGenericView.SectionName ""Additional Sys info"" ) ( eq EPOLeafNode.AutoID $iAutoId ) ) )"
            $oApiResult = Invoke-ExecuteEPOQuery -ePOAPI $oePOAPI -select $sSelect -target $sTarget -order $sOrderBy -where $sWhere -outputformat json
            $InputTable = $oApiResult.Value | Where-Object { ($_."MPSDE_SIRGenericView.SettingName" -like "Ethernet*") -or ($_."MPSDE_SIRGenericView.SettingName" -like "Wifi*") }

            $networkData = @{}

            # Iterate through each row of the input table
            foreach ($row in $InputTable) {
                $settingName = $row."MPSDE_SIRGenericView.SettingName"
                $value = $row."MPSDE_SIRGenericView.Value"
                
                # Parse the setting name to extract type and number
                if ($settingName -match '^(Ethernet|Wifi)(FriendlyName|MacAddress)(\d+)$') {
                    $type = $matches[1]
                    $property = $matches[2]
                    $number = $matches[3]
                    
                    # Create a unique key for this network adapter
                    $key = "$type$number"
                    
                    # Initialize the object if it doesn't exist yet
                    if (-not $networkData.ContainsKey($key)) {
                        $networkData[$key] = @{
                            Type = $type
                            Number = [int]$number
                            "Connection Name" = $null
                            "Mac Address" = $null
                        }
                    }
                    
                    # Assign value based on property type
                    if ($property -eq "FriendlyName") {
                        $networkData[$key]."Connection Name" = $value
                    }
                    elseif ($property -eq "MacAddress") {
                        $networkData[$key]."Mac Address" = New-MACAddressObject $value
                    }
                }
            }
            
            # Convert the hashtable to an array of PowerShell objects
            $result = @()
            foreach ($key in ($networkData.Keys | Sort-Object)) {
                $item = $networkData[$key]
                $result += [PSCustomObject]@{
                    Type = "Mac " + $item.Type
                    Number = [int]$item.Number
                    "Connection Name" = $item."Connection Name"
                    "Value" = $item."Mac Address"
                }
            }
            
            return $result
        } else { 
            return $null
        }
    }
}
