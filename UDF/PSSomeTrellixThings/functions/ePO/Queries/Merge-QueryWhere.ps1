function Merge-QueryWhere {
    <#
    .SYNOPSIS
        Merges two where clauses into a single AND condition

    .DESCRIPTION
        Combines a where clause and report conditions into a single S-expression
        where clause using an AND operator.

    .PARAMETER whereCondition
        The primary where clause as an S-expression string.

    .PARAMETER reportConditions
        The report conditions as an S-expression string.

    .OUTPUTS
        [string]. A merged where clause S-expression.

    .EXAMPLE
        Merge-QueryWhere -whereCondition "(where (eq EPOLeafNode.NodeName ""PC01""))" -reportConditions "(newerThan EPOLeafNode.LastUpdate 86400000)"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$whereCondition,
        [Parameter(Mandatory)]
        [string]$reportConditions
    )
    $objWhere = Get-SExpressionObject -sexp $whereCondition
    $objReportConditions = Get-SExpressionObject -sexp $reportConditions
    return "(where (and " + $objWhere.cdr.car.ToString() + " " + $objReportConditions.ToString() + "))"
}