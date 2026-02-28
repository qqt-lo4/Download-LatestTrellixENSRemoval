function Get-ENSTPPoliciesNames {
    <#
    .SYNOPSIS
        Gets the ENS Threat Prevention policy names from the local registry

    .DESCRIPTION
        Reads the McAfee Endpoint AV registry key to retrieve the names of
        applied Threat Prevention policies.

    .OUTPUTS
        [PSObject]. Object with policy name properties.

    .EXAMPLE
        Get-ENSTPPoliciesNames

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    $result = @{}
    (Get-ItemProperty -Path "hklm:\SOFTWARE\McAfee\Endpoint\AV").PSObject.Properties | ForEach-Object { #Write-Host $_.Name
                                                                                                        if ($_.Name -match ".+PolicyName") {
                                                                                                            $result.Add($_.Name, $_.Value)
                                                                                                        } 
                                                                                                    }
    return New-Object -TypeName psobject -Property $result
}
