function Convert-EPOIPObject {
    <#
    .SYNOPSIS
        Converts an ePO IP address string to an IP object

    .DESCRIPTION
        Parses IP address strings from ePO (standard IPv4, IPv4-mapped IPv6, or pure IPv6)
        and returns the appropriate IP object using New-IPv4Object or New-IPv6Object.

    .PARAMETER IPAddress
        The IP address string to convert.

    .OUTPUTS
        IPv4 or IPv6 object depending on the input format.

    .EXAMPLE
        Convert-EPOIPObject -IPAddress "192.168.1.1"

    .EXAMPLE
        Convert-EPOIPObject -IPAddress "0:0:0:0:0:FFFF:C0A8:0101"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position = 0, ValueFromPipeline)]
        [string]$IPAddress
    )
    
    $cleanIP = $IPAddress.Trim()
    
    # Check if it's a standard IPv4
    if ($cleanIP -match "^(\d{1,3}\.){3}\d{1,3}$") {
        return New-IPv4Object -InputObject $cleanIP
    }
    
    # Check if it's a mapped IPv4: 0:0:0:0:0:FFFF:xxxx:xxxx
    if ($cleanIP -match "^0:0:0:0:0:FFFF:([0-9A-Fa-f]{1,4}):([0-9A-Fa-f]{1,4})$") {
        # Convert hex parts to IPv4
        $firstGroup = [Convert]::ToUInt16($matches[1], 16)
        $secondGroup = [Convert]::ToUInt16($matches[2], 16)
        
        $byte1 = ($firstGroup -shr 8) -band 0xFF
        $byte2 = $firstGroup -band 0xFF
        $byte3 = ($secondGroup -shr 8) -band 0xFF
        $byte4 = $secondGroup -band 0xFF
        
        $ipv4 = "$byte1.$byte2.$byte3.$byte4"
        return New-IPv4Object -InputObject $ipv4
    }
    
    # Check if it's a mapped IPv4: ::FFFF:x.x.x.x
    if ($cleanIP -match "^::FFFF:(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})$") {
        return New-IPv4Object -InputObject $matches[1]
    }
    
    # Otherwise, treat as IPv6
    return New-IPv6Object -InputObject $cleanIP
}