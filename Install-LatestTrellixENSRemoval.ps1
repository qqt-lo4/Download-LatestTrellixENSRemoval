<#
.SYNOPSIS
    Installs or uninstalls the Trellix EPR daily download scheduled task.

.DESCRIPTION
    Standalone interactive script that manages the installation of
    Download-LatestTrellixENSRemoval.ps1 as a Windows scheduled task.

    When run without parameters, prompts the user to choose between
    installation and uninstallation using interactive CLI dialogs.

    Installation copies the download script and its UDF modules to
    the target directory, creates an encrypted password file if needed,
    and registers a daily scheduled task (02:00).

    Requires administrator privileges.

.PARAMETER Action
    The action to perform: Install or Uninstall. If omitted, the user is prompted.

.PARAMETER Server
    ePO database server name. Prompted if not provided during installation.

.PARAMETER Instance
    SQL Server instance name. Optional.

.PARAMETER Database
    ePO database name. Prompted if not provided during installation.

.PARAMETER Port
    SQL Server port number. Defaults to 1433.

.PARAMETER DBUsername
    Database username. Prompted if not provided during installation.

.PARAMETER DBPassword
    Database password as a SecureString. Prompted if not provided during installation.

.PARAMETER OutputDir
    Output directory for downloaded files. Defaults to $ENV:TEMP\TrellixEPR\.

.PARAMETER InstallDir
    Target directory for installation. Defaults to $ENV:ProgramFiles\Trellix Scripts\Download Removal\.

.PARAMETER InstallCred
    Credential for the scheduled task execution account. If omitted, uses the current user (S4U logon).

.PARAMETER TaskName
    Name of the scheduled task. Defaults to "Trellix EPR Daily Download".

.PARAMETER TaskDescription
    Description of the scheduled task.

.EXAMPLE
    .\Install-LatestTrellixENSRemoval.ps1
    # Interactive mode: prompts for action and required parameters

.EXAMPLE
    .\Install-LatestTrellixENSRemoval.ps1 -Action Install -Server "ePOSrv" -Database "ePO_DB" -DBUsername "sa"
    # Installs with specified parameters, prompts only for password

.EXAMPLE
    .\Install-LatestTrellixENSRemoval.ps1 -Action Uninstall
    # Uninstalls the scheduled task and removes the install directory

.NOTES
    Author  : Loic Ade
    Version : 1.1.0
#>
Param(
    [ValidateSet("Install", "Uninstall")]
    [string]$Action,
    [string]$Server,
    [string]$Instance,
    [string]$Database,
    [int]$Port = 1433,
    [string]$DBUsername,
    [securestring]$DBPassword,
    [string]$OutputDir = "$ENV:TEMP\TrellixEPR\",
    [string]$InstallDir = "$ENV:ProgramFiles\Trellix Scripts\Download Removal\",
    [pscredential]$InstallCred,
    [string]$TaskName = "Trellix EPR Daily Download",
    [string]$TaskDescription = "Daily download of Trellix EPR tools from ePO"
)

$ErrorActionPreference = "Stop"

# Load UI module
Import-Module $PSScriptRoot\UDF\PSSomeCLIThings

#region Helper functions

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

#endregion Helper functions

#region Privilege check

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "ERROR: This script requires administrator privileges." -ForegroundColor Red
    Write-Host "Please run PowerShell as administrator and try again." -ForegroundColor Yellow
    exit 1
}

#endregion Privilege check

#region Action selection

if (-not $Action) {
    Write-Host ""
    Write-Host "=== Trellix EPR Download - Setup ===" -ForegroundColor Cyan
    Write-Host ""

    $choice = Invoke-YesNoCLIDialog -Message "What would you like to do?" `
        -YesButtonText "&Install" -NoButtonText "&Uninstall" -CancelButtonText "E&xit" `
        -Vertical -Recommended "Yes" -HeaderForegroundColor Cyan

    switch ($choice) {
        "Yes"   { $Action = "Install" }
        "No"    { $Action = "Uninstall" }
        default { exit 0 }
    }
}

Write-Host ""
Write-Log "$Action mode selected"

#endregion Action selection

#region Uninstall

if ($Action -eq "Uninstall") {
    Write-Host ""
    $uninstallDialog = New-CLIDialog -Rows @(
        New-CLIDialogSeparator -Text "Uninstall Settings" -AutoLength -ForegroundColor Cyan
        New-CLIDialogText -Text ""
        New-CLIDialogTextBox -Header "Install directory" -Name "InstallDir" -Text $InstallDir `
            -SeparatorLocation 22 -Prefix "  " -FocusedPrefix "> "
        New-CLIDialogTextBox -Header "Task name" -Name "TaskName" -Text $TaskName `
            -SeparatorLocation 22 -Prefix "  " -FocusedPrefix "> "
        New-CLIDialogText -Text ""
        New-CLIDialogObjectsRow -Row @(
            New-CLIDialogButton -Text "&OK" -Validate
            New-CLIDialogButton -Text "&Cancel" -Cancel
        )
    )
    $uninstallResult = $uninstallDialog.InvokeValidate()

    if (-not $uninstallResult -or $uninstallResult.Action -in @("Cancel", "Exit")) {
        Write-Log "Uninstallation cancelled by user"
        exit 0
    }

    $uninstallValues = $uninstallDialog.GetValue()
    $InstallDir = $uninstallValues.InstallDir
    $TaskName = $uninstallValues.TaskName

    Write-Host ""
    Write-Host "The following will be removed:" -ForegroundColor Yellow
    [ordered]@{
        "Scheduled task" = $TaskName
        "Directory"      = $InstallDir
    } | Format-ListCustom -PropertiesColor Yellow

    Write-Host ""
    $confirm = Invoke-YesNoCLIDialog -Message "Proceed with uninstallation?" -YN -Recommended "No"
    if ($confirm -ne "Yes") {
        Write-Log "Uninstallation cancelled by user"
        exit 0
    }

    try {
        Write-Log "Starting uninstallation"

        # Remove scheduled task
        $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
        if ($existingTask) {
            Write-Log "Removing scheduled task: $TaskName"
            Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
        } else {
            Write-Log "Scheduled task '$TaskName' not found, skipping" -Level "Warning"
        }

        # Remove install directory
        if (Test-Path $InstallDir) {
            Write-Log "Removing install directory: $InstallDir"
            Remove-Item -Path $InstallDir -Recurse -Force
        } else {
            Write-Log "Directory '$InstallDir' not found, skipping" -Level "Warning"
        }

        Write-Log "Uninstallation completed successfully"
        exit 0

    } catch {
        Write-Log "Uninstallation error: $($_.Exception.Message)" -Level "Error"
        exit 1
    }
}

#endregion Uninstall

#region Install - Gather parameters

# ePO Database Connection
Write-Host ""
$dbDialog = New-CLIDialog -Rows @(
    New-CLIDialogSeparator -Text "ePO Database Connection" -AutoLength -ForegroundColor Cyan
    New-CLIDialogText -Text ""
    New-CLIDialogTextBox -Header "Server" -Name "Server" -Text $Server `
        -SeparatorLocation 15 -Prefix "  " -FocusedPrefix "> " `
        -ValidationScript { param($t) -not [string]::IsNullOrWhiteSpace($t) } `
        -ValidationErrorReason "Server is required" -FieldNameInErrorReason "Server"
    New-CLIDialogTextBox -Header "Instance" -Name "Instance" -Text $Instance `
        -SeparatorLocation 15 -Prefix "  " -FocusedPrefix "> "
    New-CLIDialogTextBox -Header "Database" -Name "Database" -Text $Database `
        -SeparatorLocation 15 -Prefix "  " -FocusedPrefix "> " `
        -ValidationScript { param($t) -not [string]::IsNullOrWhiteSpace($t) } `
        -ValidationErrorReason "Database is required" -FieldNameInErrorReason "Database"
    New-CLIDialogTextBox -Header "Port" -Name "Port" -Text $Port.ToString() `
        -SeparatorLocation 15 -Prefix "  " -FocusedPrefix "> " `
        -ValidationScript { param($t) ($t -as [int]) -and ([int]$t -ge 1) -and ([int]$t -le 65535) } `
        -ValueConvertFunction { param($t) [int]$t } `
        -ValidationErrorReason "Port must be between 1 and 65535" -FieldNameInErrorReason "Port"
    New-CLIDialogTextBox -Header "Username" -Name "DBUsername" -Text $DBUsername `
        -SeparatorLocation 15 -Prefix "  " -FocusedPrefix "> "
    New-CLIDialogText -Text ""
    New-CLIDialogObjectsRow -Row @(
        New-CLIDialogButton -Text "&OK" -Validate
        New-CLIDialogButton -Text "&Cancel" -Cancel
    )
) -ValidationErrorDetails $true

$dbResult = $dbDialog.InvokeValidate()
if (-not $dbResult -or $dbResult.Action -in @("Cancel", "Exit")) {
    Write-Log "Installation cancelled by user"
    exit 0
}

$dbValues = $dbDialog.GetValue()
$Server = $dbValues.Server
$Instance = $dbValues.Instance
$Database = $dbValues.Database
$Port = $dbValues.Port
$DBUsername = $dbValues.DBUsername

# Password prompt (only if username provided and password not already set)
if ($DBUsername -and -not $DBPassword) {
    Write-Host ""
    $pwDialog = New-CLIDialog -Rows @(
        New-CLIDialogText -Text "Enter password for '$DBUsername'" -ForegroundColor Cyan
        New-CLIDialogText -Text ""
        New-CLIDialogTextBox -Header "Password" -Name "Password" -PasswordChar '*' `
            -Prefix "  " -FocusedPrefix "> "
        New-CLIDialogText -Text ""
        New-CLIDialogObjectsRow -Row @(
            New-CLIDialogButton -Text "&OK" -Validate
            New-CLIDialogButton -Text "&Cancel" -Cancel
        )
    )
    $pwResult = $pwDialog.InvokeValidate()
    if (-not $pwResult -or $pwResult.Action -in @("Cancel", "Exit")) {
        Write-Log "Installation cancelled by user"
        exit 0
    }
    $DBPassword = $pwDialog.GetValue().Password
}

# Installation Settings
Write-Host ""
$settingsDialog = New-CLIDialog -Rows @(
    New-CLIDialogSeparator -Text "Installation Settings" -AutoLength -ForegroundColor Cyan
    New-CLIDialogText -Text ""
    New-CLIDialogTextBox -Header "Install directory" -Name "InstallDir" -Text $InstallDir `
        -SeparatorLocation 22 -Prefix "  " -FocusedPrefix "> "
    New-CLIDialogTextBox -Header "Output directory" -Name "OutputDir" -Text $OutputDir `
        -SeparatorLocation 22 -Prefix "  " -FocusedPrefix "> "
    New-CLIDialogTextBox -Header "Task name" -Name "TaskName" -Text $TaskName `
        -SeparatorLocation 22 -Prefix "  " -FocusedPrefix "> "
    New-CLIDialogText -Text ""
    New-CLIDialogObjectsRow -Row @(
        New-CLIDialogButton -Text "&OK" -Validate
        New-CLIDialogButton -Text "&Cancel" -Cancel
    )
)

$settingsResult = $settingsDialog.InvokeValidate()
if (-not $settingsResult -or $settingsResult.Action -in @("Cancel", "Exit")) {
    Write-Log "Installation cancelled by user"
    exit 0
}

$settingsValues = $settingsDialog.GetValue()
$InstallDir = $settingsValues.InstallDir
$OutputDir = $settingsValues.OutputDir
$TaskName = $settingsValues.TaskName

# Task account
Write-Host ""
$useCustomCred = Invoke-YesNoCLIDialog -Message "Use a specific account for the scheduled task?" -YN -Recommended "No"
if ($useCustomCred -eq "Yes" -and -not $InstallCred) {
    $InstallCred = Read-CLIDialogCredential -Message "Enter credentials for the scheduled task execution account" -AddCancel
    if (-not $InstallCred) {
        Write-Log "Installation cancelled by user"
        exit 0
    }
}

#endregion Install - Gather parameters

#region Install - Summary and confirmation

Write-Host ""
Write-Host " Installation Summary" -ForegroundColor Cyan
Write-Separator -Char "-" -Length 50 -ForegroundColor Cyan

[ordered]@{
    "Server"       = $(if ($Instance) { "$Server\$Instance" } else { $Server })
    "Database"     = $Database
    "Port"         = $Port
    "DB Username"  = $(if ($DBUsername) { $DBUsername } else { "(Windows auth)" })
    "Install dir"  = $InstallDir
    "Output dir"   = $OutputDir
    "Task name"    = $TaskName
    "Task account" = $(if ($InstallCred) { $InstallCred.UserName } else { "$env:USERNAME (current user)" })
} | Format-ListCustom -PropertiesColor Cyan

Write-Host ""
$confirm = Invoke-YesNoCLIDialog -Message "Proceed with installation?" -YN -Recommended "No"
if ($confirm -ne "Yes") {
    Write-Log "Installation cancelled by user"
    exit 0
}

#endregion Install - Summary and confirmation

#region Install - Execution

try {
    Write-Log "Starting installation"

    # Determine task account
    if ($InstallCred) {
        Write-Log "Using specified account: $($InstallCred.UserName)"
        $taskUser = $InstallCred.UserName
        $taskPassword = $InstallCred.Password
    } else {
        Write-Log "Using current user account: $($env:USERNAME)"
        $taskUser = $env:USERNAME
        $taskPassword = $null
    }

    # Create install directory
    if (-not (Test-Path $InstallDir)) {
        Write-Log "Creating install directory: $InstallDir"
        New-Item -Path $InstallDir -ItemType Directory -Force | Out-Null
    }

    # Copy main download script
    $downloadScript = Join-Path $PSScriptRoot "Download-LatestTrellixENSRemoval.ps1"
    if (-not (Test-Path $downloadScript)) {
        throw "Download script not found: $downloadScript"
    }
    $installedScriptPath = Join-Path $InstallDir (Split-Path $downloadScript -Leaf)
    Write-Log "Copying script to: $installedScriptPath"
    Copy-Item -Path $downloadScript -Destination $installedScriptPath -Force

    # Copy UDF modules folder
    $sourceUDFPath = Join-Path $PSScriptRoot "UDF"
    $destUDFPath = Join-Path $InstallDir "UDF"

    if (Test-Path $sourceUDFPath) {
        Write-Log "Copying UDF modules folder to: $destUDFPath"
        if (Test-Path $destUDFPath) {
            Remove-Item -Path $destUDFPath -Recurse -Force
        }
        Copy-Item -Path $sourceUDFPath -Destination $destUDFPath -Recurse -Force
    }

    # Handle password file
    $passwordFile = Join-Path $InstallDir "epo_password.txt"

    if ($DBPassword) {
        Write-Log "Creating encrypted password file"
        $DBPassword | ConvertFrom-SecureString | Out-File -FilePath $passwordFile -Force
    } else {
        Write-Log "No password provided - using Windows authentication" -Level "Warning"
    }

    # Build scheduled task arguments
    $taskArguments = @(
        "-File `"$installedScriptPath`"",
        "-Server `"$Server`"",
        "-Database `"$Database`"",
        "-Port $Port"
    )

    if ($DBUsername) {
        $taskArguments += "-DBUsername `"$DBUsername`""
    }

    if (Test-Path $passwordFile) {
        $taskArguments += "-EncryptedPasswordFile `"$passwordFile`""
    }

    if ($Instance) {
        $taskArguments += "-Instance `"$Instance`""
    }

    if ($OutputDir -and $OutputDir -ne "$ENV:TEMP\TrellixEPR\") {
        $taskArguments += "-OutputDir `"$OutputDir`""
    }

    $argumentString = $taskArguments -join " "
    Write-Log "Task arguments: $argumentString"

    # Remove existing task if present
    $existingTask = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue
    if ($existingTask) {
        Write-Log "Removing existing task: $TaskName"
        Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false
    }

    # Create scheduled task
    Write-Log "Creating scheduled task: $TaskName"

    $taskAction = New-ScheduledTaskAction -Execute "PowerShell.exe" -Argument $argumentString
    $taskTrigger = New-ScheduledTaskTrigger -Daily -At "02:00"
    $taskSettings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable -RunOnlyIfNetworkAvailable

    if ($taskPassword) {
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId $taskUser -LogonType Password -RunLevel Highest
        Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Principal $taskPrincipal -User $taskUser -Password ([Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($taskPassword)))
    } else {
        $taskPrincipal = New-ScheduledTaskPrincipal -UserId $taskUser -LogonType S4U -RunLevel Highest
        Register-ScheduledTask -TaskName $TaskName -Description $TaskDescription -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -Principal $taskPrincipal
    }

    Write-Log "Scheduled task created successfully"
    Write-Host ""
    Write-Log "Installation completed successfully"
    Write-Log "Install directory: $InstallDir"
    Write-Log "Scheduled task: $TaskName (daily execution at 02:00)"

} catch {
    Write-Log "Installation error: $($_.Exception.Message)" -Level "Error"
    exit 1
}

#endregion Install - Execution
