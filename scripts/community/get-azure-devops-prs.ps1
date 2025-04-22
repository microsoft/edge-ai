# Get-AzureDevOpsPRs.ps1
# Script to analyze Azure DevOps pull request statistics

<#
.SYNOPSIS
Retrieves and analyzes pull request data from Azure DevOps for metrics and team contribution insights.

.DESCRIPTION
This script connects to Azure DevOps, retrieves pull request data, and analyzes it to generate
metrics on team contributions, PR velocity, and code change patterns. It supports exporting to CSV
or generating visualization-ready data formats.

.PARAMETER Organization
The Azure DevOps organization name.

.PARAMETER Project
The Azure DevOps project name.

.PARAMETER Repository
Optional. Specific repository to analyze. If not provided, all repositories in the project will be analyzed.

.PARAMETER Status
The status of pull requests to retrieve: 'active', 'completed', 'abandoned', or 'all'. Default is 'completed'.

.PARAMETER MaxPRs
Maximum number of pull requests to retrieve. Default is 0 (all).

.PARAMETER ReportOutputPath
The path where output files should be saved. Default is the current directory.

.PARAMETER GenerateJsonData
Switch to generate JSON data for visualization tools. Default is false.

.PARAMETER PersonalAccessToken
Optional. Personal Access Token for Azure DevOps. If not provided, will look for AZURE_DEVOPS_PAT environment variable.

.PARAMETER SavePRDataToJson
Switch to save the collected PR data to a JSON file for later reuse. Default is true.

.PARAMETER UseExistingJsonData
Switch to load PR data from an existing JSON file instead of fetching from Azure DevOps.

.PARAMETER JsonDataPath
Optional path to the JSON file to load PR data from. If not specified, defaults to "pr-data.json" in the ReportOutputPath.

.PARAMETER CopilotStartDate
The date when GitHub Copilot was introduced to the team. Used for before/after comparisons.

.EXAMPLE
.\Get-AzureDevOpsPRs.ps1 -Organization "MyOrg" -Project "MyProject" -MaxPRs 100

.EXAMPLE
.\Get-AzureDevOpsPRs.ps1 -Organization "MyOrg" -Project "MyProject" -Status "all"

.EXAMPLE
.\Get-AzureDevOpsPRs.ps1 -Organization "MyOrg" -Project "MyProject" -CopilotStartDate "2025-02-25"

.NOTES
Requires modules in ./modules/AzDO directory
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory=$false)]
    [string]$Organization = "ai-at-the-edge-flagship-accelerator",

    [Parameter(Mandatory=$false)]
    [string]$Project = "edge-ai",

    [Parameter(Mandatory=$false)]
    [string]$Repository = "edge-ai",

    [Parameter(Mandatory=$false)]
    [string]$ReportOutputPath = "./docs",

    [Parameter(Mandatory=$false)]
    [switch]$UseExistingJsonData,

    [Parameter(Mandatory=$false)]
    [string]$JsonDataPath="./pr-data.json"
)

# Get the script path to find module files
$scriptDir = $PSScriptRoot
if (-not $scriptDir) {
    $scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
}

# Define modules path
$modulesPath = Join-Path -Path $scriptDir -ChildPath "modules/AzDO"

# Define the main module path
$mainModulePath = Join-Path -Path $modulesPath -ChildPath "AzDO.psd1"

Write-Host "Loading modules from: $modulesPath" -ForegroundColor Cyan
# Import required modules (using forward slashes for Linux compatibility)
try {
    # Fix the variable name here
    Write-Host "Importing main module from: $mainModulePath" -ForegroundColor Cyan
    Import-Module -Name $mainModulePath -Force -ErrorAction Stop

    # Additional direct imports to ensure all functions are available
    $authModulePath = Join-Path -Path $modulesPath -ChildPath "AzDO-Auth.psm1"
    $mainModulePath = Join-Path -Path $modulesPath -ChildPath "AzDO-Main.psm1"
    $apiModulePath = Join-Path -Path $modulesPath -ChildPath "AzDO-API.psm1"
    $dataCollectionModulePath = Join-Path -Path $modulesPath -ChildPath "AzDO-DataCollection.psm1"
    $dataProcessingModulePath = Join-Path -Path $modulesPath -ChildPath "AzDO-DataProcessing.psm1"
    $reportGenerationModulePath = Join-Path -Path $modulesPath -ChildPath "AzDO-ReportGeneration.psm1"
    $reportTypesModulePath = Join-Path -Path $modulesPath -ChildPath "AzDO-ReportTypes.psm1"
    $typesModulePath = Join-Path -Path $modulesPath -ChildPath "AzDO-Types.psm1"

    Write-Host "Importing individual modules..." -ForegroundColor Cyan
    Import-Module -Name $authModulePath -Force -Global
    Import-Module -Name $mainModulePath -Force -Global
    Import-Module -Name $apiModulePath -Force -Global
    Import-Module -Name $dataCollectionModulePath -Force -Global
    Import-Module -Name $dataProcessingModulePath -Force -Global
    Import-Module -Name $reportGenerationModulePath -Force -Global
    Import-Module -Name $reportTypesModulePath -Force -Global
    Import-Module -Name $typesModulePath -Force -Global

    Write-Host "Successfully loaded required modules." -ForegroundColor Green
} catch {
    Write-Error "Failed to import required modules: $_"
    exit 1
}

# Ensure docs directory exists
if (-not (Test-Path -Path $ReportOutputPath)) {
    try {
        New-Item -Path $ReportOutputPath -ItemType Directory -Force | Out-Null
        Write-Host "Created docs directory: $ReportOutputPath" -ForegroundColor Green
    } catch {
        Write-Error "Could not create docs directory '$ReportOutputPath': $_"
        exit 1
    }
}

# Step 1: Authenticate with Azure DevOps
Write-Host "Authenticating with Azure DevOps..." -ForegroundColor Cyan
$pat = Get-AzureDevOpsPAT -PersonalAccessToken $PersonalAccessToken
$authHeader = Get-AzureDevOpsAuthHeader -Token $pat

# Step 2: Collect detailed PR information
Get-Report `
    -Organization $Organization `
    -Project $Project `
    -Repository $Repository `
    -ReportOutputPath $ReportOutputPath `
    -AuthHeader $authHeader `
    -UseExistingJsonData:$UseExistingJsonData `
    -JsonDataPath $JsonDataPath

