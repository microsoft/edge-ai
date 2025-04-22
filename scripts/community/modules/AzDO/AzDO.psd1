#
# Module manifest for module 'AzDO'
#

@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'AzDO-Main.psm1'

    # Version number of this module.
    ModuleVersion = '0.1.0'

    # ID used to uniquely identify this module
    GUID = 'b4e7548c-2d7f-4e58-a0b5-e536c29d2e6b'

    # Author of this module
    Author = 'Azure IoT Operations Team'

    # Company or vendor of this module
    CompanyName = 'Microsoft'

    # Copyright statement for this module
    Copyright = '(c) Microsoft. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'Azure DevOps Pull Request analysis module for edge-ai project'

    # Minimum version of the Windows PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Modules that must be imported into the global environment prior to importing this module
    RequiredModules = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    NestedModules = @(
        'AzDO-API.psm1',
        'AzDO-Auth.psm1',
        'AzDO-DataCollection.psm1',
        'AzDO-DataProcessing.psm1',
        'AzDO-Main.psm1',
        'AzDO-ReportGeneration.psm1',
        'AzDO-ReportTypes.psm1',
        'AzDO-Types.psm1'
    )

    # Functions to export from this module
    FunctionsToExport = @(
        # Auth functions
        'Get-AzureDevOpsPAT',
        'Get-AzureDevOpsAuthHeader',

        # API functions
        'Get-AzureDevOpsItem',
        'Invoke-AzureDevOpsApi',

        # Data Collection functions
        'Get-RepositoryId',
        'Get-PullRequestList',
        'Get-AzDOPullRequestThread',
        'Get-PullRequestWorkItemDetail',
        'Get-PullRequestCommitList',
        'Get-PullRequestReviewerList',
        'Get-AzDOMainBranchMetric',
        'Get-AzDORepositoryMetric',
        'Get-MainBranchFileExtension',

        # Data Processing functions
        'Get-FileExtensionMetric',
        'Get-FileExtensionSummary',
        'Get-AzDOReportSummary',
        'Get-PRMonthlyMetric',
        'Get-PRWeeklyMetric',
        'Get-PRSizeMetric',
        'Get-PRCompletionTimeDistribution',
        'Get-PRFirstResponseSLOMetric',
        'Get-PRComplexityChartData',
        'Get-ContributorReturnMetric',
        'Get-ContributorMetricData',
        'Get-ReviewerMetricData',
        'Get-CopilotImpactMetric',
        'Get-FocusAreaMetric',

        # Report Generation functions
        'Get-ReportSummary',
        'Get-PRMetricsByInterval',
        'Get-SLOComplianceTableContent',
        'Get-ContributorSummary',
        'Format-FileExtensionTable',
        'Get-FocusAreaSection',
        'Get-PRComplexityChart',
        'Get-MermaidChart',
        'Get-CopilotImpactSection',
        'Get-ReportFooter',
        'Get-ReportHeader',

        # Main processing functions
        'Get-Report'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module. These help with module discovery in online galleries.
            Tags = @('AzureDevOps', 'Git', 'PullRequest', 'Analysis')

            # A URL to the license for this module.
            LicenseUri = 'https://github.com/Microsoft/edge-ai/blob/main/LICENSE'

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/Microsoft/edge-ai'
        }
    }
}
