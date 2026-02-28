function Get-MAdbPath {
    <#
    .SYNOPSIS
        Finds the path to the McAfee agent database file

    .DESCRIPTION
        Checks known locations for the McAfee/Trellix agent database file (ma.db)
        and returns the first valid path found.

    .OUTPUTS
        [string]. The path to ma.db, or an empty string if not found.

    .EXAMPLE
        Get-MAdbPath

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    $p1 = "C:\ProgramData\McAfee\Agent\DB\ma.db"
    $p2 = "C:\ProgramData\McAfee\Common Framework\DB\ma.db"
    if (Test-Path -Path $p1) {
        return $p1 
    } elseif (Test-Path -Path $p2) {
        return $p2 
    } else {
        return ""
    }
}