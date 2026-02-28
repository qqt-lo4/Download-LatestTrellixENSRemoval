# PSSomeTrellixThings

PowerShell module for Trellix (McAfee) management: ePO API and database queries, endpoint agent operations, policies, client tasks, software catalog, tags, and reporting.

## Requirements

- PowerShell 5.1+
- Trellix/McAfee ePO server access (for ePO functions)
- Trellix/McAfee agent installed (for Endpoint functions)

## Installation

```powershell
Import-Module .\PSSomeTrellixThings.psd1
```

## Functions

### ePO / Connect

| Function | Description |
|----------|-------------|
| Connect-ePOAPI | Connects to a Trellix ePO server via the Web API |
| Connect-EPODB | Connects to a Trellix ePO SQL Server database |
| Get-EPOAPIInfoFromCredManager | Retrieves ePO API connection info from Windows Credential Manager |
| Get-EPODBInfoFromCredManager | Retrieves ePO database connection info from Windows Credential Manager |
| Save-EPOAPIInfoToCredManager | Saves ePO API connection info to Windows Credential Manager |
| Save-EPODBInfoToCredManager | Saves ePO database connection info to Windows Credential Manager |
| Read-HostEPOAPIInput | Prompts the user for ePO API connection details |
| Read-HostEPODBInput | Prompts the user for ePO database connection details |
| Read-ePOAPI | Prompts the user for ePO API connection details (named groups) |

### ePO / WebAPI

| Function | Description |
|----------|-------------|
| Invoke-EPOWebAPI | Invokes a Trellix ePO Web API command |
| Test-WebAPIConnection | Tests if the ePO Web API connection is active |

### ePO / Queries

| Function | Description |
|----------|-------------|
| Get-WebAPI-QueriesList | Retrieves the list of ePO queries via the Web API |
| Get-WebAPI-executeQuery | Executes an ePO query via the Web API |
| Invoke-ExecuteEPOQuery | Executes an ePO query via the API connection object |
| Get-EPOQuery | Retrieves an ePO query definition from the database |
| Get-EPOQueryID | Gets the ID of an ePO query by its unique key |
| Merge-QueryWhere | Merges two where clauses into a single AND condition |
| Merge-WhereClauses | Merges two where clauses using a logical operator |
| ConvertTo-SExpressionCondition | Converts an XML condition element to an S-expression string |
| Get-SExpressionObject | Parses an S-expression string into an object tree |

### ePO / SQL

| Function | Description |
|----------|-------------|
| Get-EPOSQLQueryResult | Executes a SQL query against the ePO database |

### ePO / Core

| Function | Description |
|----------|-------------|
| Get-EPODatabaseList | Lists available databases in the ePO server |
| Get-EPOTablesList | Lists available tables and columns in the ePO server |
| Get-EPOTablesListLanguage | Detects the language of the ePO server tables |
| Test-ePOColumns | Tests if ePO table columns exist on the server |
| Get-EPOServerInfo | Retrieves ePO server information from the database |

### ePO / Report

| Function | Description |
|----------|-------------|
| Get-EPOReport | Retrieves ePO report definitions from the database |
| Get-ScheduledReportConditions | Retrieves filter conditions from a scheduled ePO report task |
| Get-ServerTaskEPOReport | Retrieves an ePO report with its scheduled task filter conditions |

### ePO / ClientTask

| Function | Description |
|----------|-------------|
| Export-EPOClientTask | Exports ePO client task definitions |
| Get-EPOClientTask | Searches for ePO client tasks |
| Invoke-EPOClientTask | Runs an ePO client task on specified systems |
| Get-EPOComputerAppliedTasks | Retrieves client tasks applied to a specific computer |

### ePO / System

| Function | Description |
|----------|-------------|
| Get-EPOLeafNode | Retrieves system info from Trellix ePO |
| Get-EPOSystemInfo | Gets system info with products, tags, and AMCore version |
| Find-EPOSystem | Searches for systems in the ePO server |
| Find-EPOSystemOnNetwork | Finds ePO-managed systems on a specific network |
| Get-EPOSystemClientTask | Gets client tasks applicable to a specific system |
| Invoke-EPOAgentWakeUp | Sends an agent wake-up call to ePO-managed systems |
| Get-EPOComputerOtherInfo | Retrieves network and user information for an ePO-managed computer |
| Format-EPONetworkInfo | Formats raw ePO network data into structured objects |

### ePO / Endpoint

| Function | Description |
|----------|-------------|
| Get-EPOSystemProtectionStatus | Gets protection status from Trellix ePO |
| Get-EPOSystemCustomProperties | Gets custom properties for a system from Trellix ePO |

### ePO / Other

| Function | Description |
|----------|-------------|
| Convert-EPOIPObject | Converts an ePO IP address string to an IP object |

### ePO / SIR

| Function | Description |
|----------|-------------|
| Get-EPOComputerSIRNetworkInfo | Retrieves SIR network information for an ePO-managed computer |

### ePO / SoftwareCatalog

| Function | Description |
|----------|-------------|
| Get-EPOLicenseKey | Retrieves the ePO license key from the database |
| Get-EPOSoftwareCatalogServer | Retrieves software catalog server configuration |
| Get-EPOSoftwareCatalogComponent | Retrieves software catalog products and components |
| Get-EPOSoftwareCatalogContent | Downloads the full Trellix software catalog content |
| Get-EPOSoftwareDownloadURL | Gets download URLs for Trellix software files |

### ePO / Extensions

| Function | Description |
|----------|-------------|
| Get-EPOExtension | Retrieves ePO server extensions from the database |

### ePO / Policies

| Function | Description |
|----------|-------------|
| Find-EPOPolicy | Searches for policies in the ePO server |
| Get-EPOComputerAppliedPolicies | Retrieves policies applied to a specific computer |

### ePO / Scheduler

| Function | Description |
|----------|-------------|
| Get-EPOSchedulerTask | Retrieves ePO server tasks via the Web API |
| Get-EPODBSchedulerTask | Retrieves ePO scheduler tasks from the database |

### ePO / Tasklog

| Function | Description |
|----------|-------------|
| Get-EPOTaskSources | Lists task log sources from the ePO server |
| Get-EPOServerTaskLogMessages | Retrieves server task log messages |

### ePO / Tags

| Function | Description |
|----------|-------------|
| Find-EPOSystemTag | Searches for system tags in the ePO server |
| Set-EPOSystemTag | Applies a tag to ePO-managed systems |
| Clear-EPOSystemTag | Removes tags from ePO-managed systems |

### ePO / Repository

| Function | Description |
|----------|-------------|
| Find-EPOPackages | Searches for packages in the ePO repository |
| Get-CurrentRepositoryAMCore | Gets the current AMCore version from the ePO repository |
| Get-CurrentTrellixAMCore | Gets the latest AMCore DAT version from Trellix update servers |

### Endpoint

| Function | Description |
|----------|-------------|
| Get-McAfeeAgentLocation | Retrieves the Trellix/McAfee agent install location |
| Get-McAfeeAgentCustomProps | Gets custom properties from the local agent |
| Set-McAfeeAgentCustomProperty | Sets McAfee agent custom properties |
| Connect-McAfeeAgentDB | Opens a read-only SQLite connection to the agent database |
| Get-AgentCollectedPropertyValue | Retrieves a collected property from the agent database |
| Get-AgentInfo | Retrieves agent information from cmdagent.exe |
| Invoke-cmdagent | Executes cmdagent.exe with specified arguments |
| Invoke-McAfeeAgentCollectProperties | Triggers an agent properties collection |
| Get-MAdbPath | Finds the path to the McAfee agent database file |
| Get-McAfeeENSATPProduct | Gets ENS Adaptive Threat Protection product info |
| Get-McAfeeENSTPProduct | Gets ENS Threat Prevention product info |
| Get-ENSTPPoliciesNames | Gets ENS Threat Prevention policy names from the registry |
| Get-McAfeeVersionsKey | Gets McAfee product version registry keys |
| Get-McAfeeInstalledProductVersion | Gets the version of an installed McAfee product |

## Author

**Loic Ade**

## License

This project is licensed under the [PolyForm Noncommercial License 1.0.0](LICENSE).
