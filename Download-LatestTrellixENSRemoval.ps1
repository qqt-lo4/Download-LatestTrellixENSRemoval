Param(
    [Parameter(Mandatory)]
    [string]$Server,
    [string]$Instance,
    [Parameter(Mandatory)]
    [string]$Database,
    [int]$Port = 1433,
    [Parameter(Mandatory, ParameterSetName = "passwdfile")]
    [Parameter(Mandatory, ParameterSetName = "userpasswd")]
    [string]$DBUsername,
    [Parameter(Mandatory, ParameterSetName = "userpasswd")]
    [securestring]$DBPassword,
    [Parameter(Mandatory, ParameterSetName = "passwdfile")]
    [string]$EncryptedPasswordFile,
    [Parameter(Mandatory, ParameterSetName = "credential")]
    [pscredential]$Credential,
    [string]$OutputDir = "$ENV:TEMP\TrellixEPR\",
    [switch]$Force
)

# Preference configuration
$ErrorActionPreference = "Stop"

# Load required assemblies
Add-Type -AssemblyName System.Web

# Avoid dependency on Internet Explorer engine
$PSDefaultParameterValues['Invoke-WebRequest:UseBasicParsing'] = $true

#region Includes
Import-Module $PSScriptRoot\UDF\PSSomeTrellixThings
Import-Module $PSScriptRoot\UDF\PSSomeAPIThings
Import-Module $PSScriptRoot\UDF\PSSomeAuthThings
#endregion Includes

#region script info
#scriptType=standard
#scriptVersion=1.0
#outputMode=multiple
#outputMultipleChoices=EPO
#endregion script info

#region export script EPO
#New-OutputFolder "output\%scriptName%\%scriptVersion%\"
#Write-OutputScript "%scriptFile%" "%outputDir%"
#endregion export script EPO

# Logging function
function Write-Log {
    <#
    .SYNOPSIS
        Writes a timestamped log message to the console.

    .DESCRIPTION
        Outputs a formatted log message with timestamp and severity level.
        Info messages are displayed in green, warnings use Write-Warning,
        and errors use Write-Error.

    .PARAMETER Message
        The log message text to display.

    .PARAMETER Level
        The severity level of the message: Info, Warning, or Error. Defaults to Info.

    .OUTPUTS
        None. Writes to the console output streams.

    .EXAMPLE
        Write-Log "Operation completed successfully"

    .EXAMPLE
        Write-Log "File not found, skipping" -Level "Warning"

    .NOTES
        Author  : Loic Ade
        Version : 1.0.0
    #>
    param(
        [string]$Message,
        [ValidateSet("Info", "Warning", "Error")]
        [string]$Level = "Info"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logMessage = "[$timestamp] [$Level] $Message"

    switch ($Level) {
        "Info" { Write-Host $logMessage -ForegroundColor Green }
        "Warning" { Write-Warning $logMessage }
        "Error" { Write-Error $logMessage }
    }
}

try {
    Write-Log "Starting ePO download script"

    # Standardized credential retrieval
    $authCredentials = Get-AuthenticationCredentials -Username $DBUsername -Password $DBPassword -EncryptedPasswordFile $EncryptedPasswordFile -Credential $Credential

    # Connect to ePO database
    Write-Log "Connecting to ePO database: $Server\$Database"

    $connectionParams = @{
        Server = $Server
        Database = $Database
        Port = $Port
        GlobalVar = $true
    }

    # Add credentials if available
    if ($authCredentials.Username) {
        $connectionParams.Username = $authCredentials.Username
        $connectionParams.Password = $authCredentials.Password
    }

    Connect-EPODB @connectionParams
    Write-Log "Database connection established"

    # Search for EPR Tool component
    Write-Log "Searching for 'EPR Tool' component in software catalog"
    $removal = Get-EPOSoftwareCatalogComponent -EPODB $ePODB -Product "Endpoint Product Removal" -Component "EPR Tool"

    if (-not $removal) {
        throw "Component 'EPR Tool' not found in software catalog"
    }

    $fileNameToDownload = $removal.downloadURL."#text"
    if (-not $fileNameToDownload) {
        throw "Download URL not found for EPR Tool component"
    }

    Write-Log "Component found: $fileNameToDownload"

    # Retrieve download URL
    Write-Log "Retrieving download URL"
    $dlURL = Get-EPOSoftwareDownloadURL -ePODB $ePODB -FileNames $fileNameToDownload

    if (-not $dlURL) {
        throw "Unable to retrieve download URL"
    }

    $sFileName = $dlURL.FileName.Split("/")[-1]
    Write-Log "File to download: $sFileName"

    # Create output directory
    if (-not (Test-Path -Path $OutputDir -PathType Container)) {
        Write-Log "Creating output directory: $OutputDir"
        New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
    }

    # Check if file already exists
    $fullPath = Join-Path $OutputDir $sFileName
    if (Test-Path -Path $fullPath -PathType Leaf) {
        if ($Force) {
            Write-Log "File already exists, forcing overwrite: $fullPath" -Level "Warning"
        } else {
            Write-Log "File already exists: $fullPath" -Level "Warning"
            Write-Log "Use -Force to overwrite the file"
            return
        }
    }

    # Download file
    Write-Log "Downloading from: $($dlURL.FileURL)"
    Write-Log "Destination: $fullPath"

    $webRequest = @{
        Uri = $dlURL.FileURL
        OutFile = $fullPath
        UseBasicParsing = $true
    }

    Invoke-WebRequest @webRequest

    # Verify download
    if (Test-Path $fullPath) {
        $fileSize = (Get-Item $fullPath).Length
        Write-Log "Download completed successfully"
        Write-Log "File size: $([math]::Round($fileSize / 1MB, 2)) MB"
    } else {
        throw "Download failed: file was not created"
    }

    Write-Log "Script completed successfully"

} catch {
    Write-Log "Execution error: $($_.Exception.Message)" -Level "Error"
    Write-Log "Error at line: $($_.InvocationInfo.ScriptLineNumber)" -Level "Error"
    exit 1
} finally {
    # Clean up connections
    if ($ePODB -and $ePODB.sqlConnection) {
        try {
            if ($ePODB.sqlConnection.State -eq 'Open') {
                $ePODB.sqlConnection.Close()
                Write-Log "SQL connection closed"
            }
        } catch {
            Write-Log "Error closing connection: $($_.Exception.Message)" -Level "Warning"
        }
    }
}
