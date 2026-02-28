function ConvertTo-SExpressionCondition {
    <#
    .SYNOPSIS
        Converts an XML condition element to an S-expression string

    .DESCRIPTION
        Takes an XML element representing a query condition (with op-key, prop-key, and value)
        and converts it into an ePO S-expression condition string.

    .PARAMETER xmlcondition
        The XML element containing the condition definition.

    .OUTPUTS
        [string]. An S-expression condition string.

    .EXAMPLE
        ConvertTo-SExpressionCondition -xmlcondition $xmlNode

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory, Position=0)]
        [System.Xml.XmlElement]$xmlcondition
    )
    $result = "(" + $xmlcondition."op-key" + " " + $xmlcondition."prop-key" + " "
    $result += "`"" + $xmlcondition.value."#cdata-section" + "`")"
    #$result += $xmlcondition.value."#cdata-section" + ")"
    #if ($xmlcondition."op-key" -eq "contains") {
    #    $result += "`"" + $xmlcondition.value."#cdata-section" + "`")"
    #} else {
    #    $result += "`"" + $xmlcondition.value."#cdata-section" + "`")"
    #}
    return $result
}