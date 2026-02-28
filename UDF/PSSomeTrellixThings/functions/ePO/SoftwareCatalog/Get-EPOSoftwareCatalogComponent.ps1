function Get-EPOSoftwareCatalogComponent {
    <#
    .SYNOPSIS
        Retrieves software catalog products and components

    .DESCRIPTION
        Gets products and optionally a specific component from the Trellix
        software catalog.

    .PARAMETER EPODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER Product
        The product name to filter by.

    .PARAMETER Component
        The component name to filter by within a product.

    .OUTPUTS
        [System.Xml.XmlElement]. Product or component XML elements.

    .EXAMPLE
        Get-EPOSoftwareCatalogComponent -Product "Trellix Agent" -Component "Windows"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [object]$EPODB,
        [string]$Product,
        [string]$Component
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        $oCatalog = Get-EPOSoftwareCatalogContent -ePODB $oePODB
        if ($Product) {
            $oProduct = $oCatalog.SoftwareCatalogProducts.Products.Product | Where-Object { $_.Name -eq $Product }
            if ($Component) {
                return ($oProduct.Components.Component | Where-Object { $_.Name -eq $Component })
            } else {
                return $oProduct
            }
        } else {
            return $oCatalog.SoftwareCatalogProducts.Products.Product
        }
    }
}
