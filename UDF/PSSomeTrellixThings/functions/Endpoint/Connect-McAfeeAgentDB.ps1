function Connect-McAfeeAgentDB {
    <#
    .SYNOPSIS
        Opens a read-only SQLite connection to the McAfee agent database

    .DESCRIPTION
        Creates a read-only SQLite connection to the local McAfee/Trellix agent
        database file (ma.db).

    .PARAMETER madb_file
        Path to the ma.db file. Default: "C:\ProgramData\McAfee\Agent\DB\ma.db".

    .OUTPUTS
        [System.Data.SQLite.SQLiteConnection]. A read-only SQLite connection.

    .EXAMPLE
        $conn = Connect-McAfeeAgentDB

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    [OutputType([System.Data.SQLite.SQLiteConnection])]
    Param(
        [string]$madb_file = "C:\ProgramData\McAfee\Agent\DB\ma.db"
    )
    if (Test-Path -Path $madb_file -PathType Leaf) {
        New-SQLiteConnection -DataSource $madb_file -ReadOnly
    } else {
        throw [System.IO.FileNotFoundException] "The file does not exists"
    }
}