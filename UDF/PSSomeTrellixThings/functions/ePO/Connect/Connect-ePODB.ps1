function Connect-EPODB {
    <#
    .SYNOPSIS
        Connects to a Trellix ePO SQL Server database

    .DESCRIPTION
        Creates a direct SQL connection to the ePO database server.
        The returned object includes a RunQuery script method for executing SQL queries.

    .PARAMETER Server
        The SQL Server hostname or IP address.

    .PARAMETER Instance
        The SQL Server instance name.

    .PARAMETER Database
        The ePO database name.

    .PARAMETER Port
        The SQL Server port.

    .PARAMETER Username
        The username for SQL authentication.

    .PARAMETER Password
        The password as a SecureString.

    .PARAMETER Credential
        A PSCredential object for SQL authentication.

    .PARAMETER GlobalVar
        Stores the connection object in the $Global:ePODB variable.

    .OUTPUTS
        [PSCustomObject]. Connection object with RunQuery method.

    .EXAMPLE
        Connect-EPODB -Server "sqlsrv01" -Database "ePO_DB" -Port 1433 -Credential (Get-Credential) -GlobalVar

    .NOTES
        Author  : Loïc Ade
        Version : 1.0.0
    #>
    Param(
        [Parameter(Mandatory)]
        [string]$Server,
        [string]$Instance,
        [Parameter(Mandatory)]
        [string]$Database,
        [Parameter(Mandatory)]
        [int]$Port,
        [Parameter(Mandatory, ParameterSetName = "userpasswd")]
        [string]$Username,
        [Parameter(Mandatory, ParameterSetName = "userpasswd")]
        [securestring]$Password,
        [Parameter(Mandatory, ParameterSetName = "credential")]
        [pscredential]$Credential,
        [switch]$GlobalVar
    )
    $hResult = @{
        Server = $Server
        Port = $Port
        Instance = $Instance
        DB = $Database
    }
    $hResult.Credential = if ($Credential) { $Credential } else {
        New-Object System.Management.Automation.PSCredential($Username, $Password)
    }
    $hResult.ConnectionString = if ($Instance -eq "") {
        $Server + "," + $Port
    } else {
        $Server + "\" + $Instance + "," + $Port
    }
    
    $connectionString = "Server=" + $hResult.ConnectionString + ";Initial Catalog=" + $Database
    $hResult.Credential.Password.MakeReadOnly()
    [System.Data.SqlClient.SqlCredential] $sqlCred = New-Object System.Data.SqlClient.SqlCredential($hResult.Credential.UserName, $hResult.Credential.Password) 
    $hResult.sqlConnection = New-Object System.Data.SqlClient.SqlConnection($connectionString, $sqlCred)
    $hResult.sqlConnection.Open()

    $hResult = [PSCustomObject]$hResult

    $hResult | Add-Member -MemberType ScriptMethod -Name "RunQuery" -Value {
        Param(
            [Parameter(Mandatory)]
            [string]$SQLQuery
        )
        [System.Data.SqlClient.SqlCommand]$sqlcmd = $this.sqlConnection.CreateCommand()
        $sqlcmd.CommandText = $SQLQuery
        [System.Data.SqlClient.SqlDataAdapter]$adp = New-Object System.Data.SqlClient.SqlDataAdapter $sqlcmd
        [System.Data.DataSet]$data = New-Object System.Data.DataSet
        $adp.Fill($data) | Out-Null
        return $data.Tables
    }

    if ($GlobalVar) {
        $Global:ePODB = $hResult
    } else {
        return $hResult
    }
}