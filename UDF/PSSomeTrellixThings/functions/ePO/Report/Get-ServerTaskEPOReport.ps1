function Get-ServerTaskEPOReport {
    <#
    .SYNOPSIS
        Retrieves an ePO report with its scheduled task filter conditions

    .DESCRIPTION
        Gets a report definition and merges the scheduled task's runtime filter conditions
        into the report's query where clauses.

    .PARAMETER ePOAPI
        An ePO API connection object. Falls back to $Global:ePOAPI if not provided.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER schedulerTaskName
        The name of the scheduler task that runs the report.

    .PARAMETER index
        The action index within the scheduler task.

    .OUTPUTS
        [PSCustomObject]. Report object with merged filter conditions.

    .EXAMPLE
        Get-ServerTaskEPOReport -ePOAPI $api -ePODB $db -schedulerTaskName "Daily Report" -index 0

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePOAPIInfo and ePODBInfo classes
            1.1.0 - Refactored to use Connect-ePOAPI connection object
                    Refactored to use Connect-ePODB connection object
    #>
    Param(
        [object]$ePOAPI,
        [object]$ePODB,
        [Parameter(Mandatory)]
        [string]$schedulerTaskName,
        [Parameter(Mandatory)]
        [int]$index
    )
    Begin {
        $oePOAPI = if ($ePOAPI) { $ePOAPI } else { $Global:ePOAPI }
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        $t = Get-SchedulerTask -ePODB $oePODB -taskName $schedulerTaskName
        if (($index -ge $t.Actions.Count) -or ($index -lt 0)) {
            throw [System.IndexOutOfRangeException] "Index is out of bound for this ePO Task"
        }
        $urlCommand = $t.Actions[$index].Command
        $urlObject = Get-URLObject -urlcommand $urlcommand
        if ($urlObject.command -ne "schedule:report.run") {
            throw [System.ArgumentException] "This task is not a run report task."
        }
        $reportId = $urlObject.arguments["reportId"]
        $report = Get-EPOReport -ePODB $oePODB -ePOAPI $oePOAPI -id $reportId

        $filter = Get-ScheduledReportConditions -ePODB $oePODB -taskName $schedulerTaskName -index $index
        if ($filter) {
            $report | Add-Member -NotePropertyName "Filter" -NotePropertyValue $filter
            foreach ($line in $report.ReportDef) {
                foreach ($item in $line) {
                    if ($item.type -in @("queryChart","queryTable")) {
                        if ($item.query.PSObject.Properties.Name.Contains("where")) {
                            if ($item.query.where -match "^ *\( *where *(.*) *\) *$") {
                                #where clause is included
                                $newWhere = "( where ( and " + $filter.value + " " + $Matches.1 + " ) )"
                                $item.query | Add-Member -NotePropertyName "where_without_filter" -NotePropertyValue $item.query.where
                                $item.query.where = $newWhere
                            } else {
                                #query with no where clause,
                                $item.query.where = "( where " + $filter.value + ")"
                            }
                        } else {
                            #query does not have a where clause
                            $item.query | Add-Member -NotePropertyName "where" -NotePropertyValue ("( where " + $filter.value + ")")
                        }
                    }
                }
            }
        }
        return $report
    }
}
