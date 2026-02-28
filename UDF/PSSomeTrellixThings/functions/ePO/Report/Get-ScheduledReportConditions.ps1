function Get-ScheduledReportConditions {
    <#
    .SYNOPSIS
        Retrieves filter conditions from a scheduled ePO report task

    .DESCRIPTION
        Extracts runtime parameter conditions from a scheduled report task and converts
        them into S-expression format for use in ePO queries.

    .PARAMETER ePODB
        An ePO database connection object. Falls back to $Global:ePODB if not provided.

    .PARAMETER uniqueKey
        The unique key of the scheduler task.

    .PARAMETER taskName
        The name of the scheduler task.

    .PARAMETER index
        The action index within the task. Default: 0.

    .PARAMETER xmloutput
        Returns raw XML condition nodes instead of S-expression strings.

    .OUTPUTS
        [PSCustomObject] or [System.Xml.XmlNodeList]. Conditions as S-expression or XML.

    .EXAMPLE
        Get-ScheduledReportConditions -ePODB $db -taskName "Daily Report" -index 0

    .NOTES
        Author  : Loïc Ade
        Version : 1.1.0

        Version History:
            1.0.0 - Initial version using ePODBInfo class
            1.1.0 - Refactored to use Connect-ePODB connection object
    #>
    Param(
        [object]$ePODB,
        [Parameter(Mandatory, ParameterSetName="UniqueKey")]
        [string]$uniqueKey,
        [Parameter(Mandatory, ParameterSetName="Name")]
        [string]$taskName,
        [int]$index = 0,
        [switch]$xmloutput
    )
    Begin {
        $oePODB = if ($ePODB) { $ePODB } else { $Global:ePODB }
    }
    Process {
        $taskParams = @{ ePODB = $oePODB }
        switch ($PSCmdlet.ParameterSetName) {
            "UniqueKey" { $taskParams.uniqueKey = $uniqueKey }
            "Name" { $taskParams.taskName = $taskName }
        }
        $tasks = Get-SchedulerTask @taskParams
        foreach ($task in $tasks) {
            if ($index -lt $task.Actions.count) {
                $urlo = Get-URLObject -urlcommand $($task.Actions[$index].Command)
                if ($urlo.command -eq "schedule:report.run") {
                    [xml]$conditionsresult = [xml]$urlo.arguments.runtimeParamXML
                    $xmlresult = $conditionsresult.SelectNodes("/params/param/value/conditions/condition")
                    if ($xmloutput.IsPresent) {
                        $xmlresult
                    } else {
                        $filterResult = @()
                        $propkeys = $xmlresult | Group-Object "prop-key" | Sort-Object "Count" -Descending
                        $filterResult += for ($i = 0; $i -lt $propkeys.Count; $i++) {
                            if ($propkeys[$i].Count -gt 1) {
                                $grouping = $propkeys[$i].Group[0].grouping
                                $conditionsArray = foreach ($cond in $propkeys[$i].Group) {
                                    ConvertTo-SExpressionCondition $cond
                                }
                                "($grouping " + $($conditionsArray -join " ") + ")"
                            } else {
                                ConvertTo-SExpressionCondition $propkeys[$i].Group[0]
                            }
                        }
                        if ($filterResult.Count -gt 1) {
                            $filterResult = "(and " + $($filterResult -join " ") + ")"
                        }
                        $result = @{
                            urlObject = $urlo
                            value = $filterResult
                            command = $tasks
                            taskname = $taskName
                            taskIndex = $index
                            propkeys = $propkeys
                        }
                        return New-Object -TypeName PSCustomObject -Property $result
                    }
                }
            }
        }
    }
}
