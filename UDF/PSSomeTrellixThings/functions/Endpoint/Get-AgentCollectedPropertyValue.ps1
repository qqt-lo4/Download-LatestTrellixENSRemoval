function Get-AgentCollectedPropertyValue {
    <#
    .SYNOPSIS
        Retrieves a collected property value from the McAfee agent database

    .DESCRIPTION
        Queries the local McAfee agent SQLite database to retrieve a specific
        property value for a given product.

    .PARAMETER SQLiteConnection
        An open SQLite connection to the McAfee agent database.

    .PARAMETER product
        The product path to query (e.g., "EPOAGENT3000").

    .PARAMETER property
        The property name to retrieve.

    .OUTPUTS
        [PSCustomObject]. Object with Product, Name, and Value properties.

    .EXAMPLE
        Get-AgentCollectedPropertyValue -SQLiteConnection $conn -product "EPOAGENT3000" -property "AgentGUID"

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [System.Data.SQLite.SQLiteConnection]$SQLiteConnection,
        [Parameter(Mandatory)]
        [string]$product,
        [Parameter(Mandatory)]
        [string]$property
    )
    return Invoke-SqliteQuery -SQLiteConnection $SQLiteConnection -Query "select '$product' as Product,Name as Name,cast(Value as text) as Value from AGENT_CHILD Where ID in (select ID from AGENT_PARENT Where Path like '$product') and NAME like '$property'"
}