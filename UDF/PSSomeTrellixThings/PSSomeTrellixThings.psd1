@{
    # Module manifest for PSSomeTrellixThings

    # Script module associated with this manifest
    RootModule        = 'PSSomeTrellixThings.psm1'

    # Version number of this module
    ModuleVersion     = '1.0.0'

    # ID used to uniquely identify this module
    GUID              = '6c4d8e2f-a173-4b95-80d6-e9f3a52b1c78'

    # Author of this module
    Author            = 'Loïc Ade'

    # Description of the functionality provided by this module
    Description       = 'Trellix (McAfee) management utilities: endpoint agent operations, ePO API and database queries, policies, client tasks, software catalog, tags, and reporting.'

    # Minimum version of PowerShell required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = '*'

    # Cmdlets to export from this module
    CmdletsToExport   = @()

    # Variables to export from this module
    VariablesToExport  = @()

    # Aliases to export from this module
    AliasesToExport    = @()

    # Private data to pass to the module specified in RootModule
    PrivateData       = @{
        PSData = @{
            Tags       = @('Trellix', 'McAfee', 'ePO', 'Endpoint', 'Security', 'ENS', 'API')
            ProjectUri = ''
        }
    }
}