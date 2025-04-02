# Build-Consistency-Check.ps1
#
# This script analyzes Azure DevOps templates and GitHub workflow files for file naming consistency
# and checks that there are comparable CI/CD definitions in both systems with the correct naming patterns.
#
# Usage:
# .\Build-Consistency-Check.ps1 [-AzDoPath <path>] [-GitHubPath <path>] [-ExcludeFiles <string[]>] [-Verbose] [-Report]
#
# Parameters:
#   -AzDoPath:     Path to Azure DevOps templates (defaults to .azdo/templates)
#   -GitHubPath:   Path to GitHub workflow files (defaults to .github/workflows)
#   -ExcludeFiles: Array of workflow filenames to exclude from comparison (e.g. main.yml, pr-validation.yml)
#   -Verbose:      Enable verbose output with detailed comparison information
#   -Report:       Generate a detailed report file in JSON format
#
# Output:
#   - Console output with comparison results
#   - Optional JSON report file with detailed analysis
#   - Exit code 0 if consistent, 1 if inconsistencies found

[CmdletBinding()]
param(
    [Parameter()]
    [string]$AzDoPath = ".azdo/templates",

    [Parameter()]
    [string]$GitHubPath = ".github/workflows",

    [Parameter()]
    [string[]]$ExcludeFiles = @("main.yml", "pr-validation.yml", "pages-deploy.yml", "wiki-update-template.yml"),

    [Parameter()]
    [switch]$Report
)

# Function to extract base name from a file (removing extension and template suffix)
function Get-BaseName {
    param(
        [Parameter(Mandatory)]
        [string]$FileName,

        [Parameter()]
        [string]$System
    )

    $baseName = [System.IO.Path]::GetFileNameWithoutExtension($FileName)

    # For Azure DevOps files, remove the "-template" suffix
    if ($System -eq "AzDo" -and $baseName.EndsWith("-template")) {
        $baseName = $baseName.Substring(0, $baseName.Length - 9)  # Remove "-template"
    }

    return $baseName
}

# Function to compare file content and parameters between AzDo and GitHub files
function Compare-FileContent {
    param(
        [Parameter(Mandatory)]
        [string]$AzDoFilePath,

        [Parameter(Mandatory)]
        [string]$GitHubFilePath
    )

    $azDoContent = Get-Content -Path $AzDoFilePath -Raw
    $githubContent = Get-Content -Path $GitHubFilePath -Raw

    $results = @{
        AzDoFile = (Split-Path -Leaf $AzDoFilePath)
        GitHubFile = (Split-Path -Leaf $GitHubFilePath)
        ParameterDifferences = @()
        StepDifferences = @()
    }

    # Extract parameters from AzDo template
    $azDoParams = @()
    if ($azDoContent -match '(?s)parameters:(.*?)(?:steps:|jobs:|stages:|---|\Z)') {
        $paramSection = $matches[1]
        $paramMatches = [regex]::Matches($paramSection, '(?m)^\s*-\s*name:\s*(\w+)')
        foreach ($match in $paramMatches) {
            $azDoParams += $match.Groups[1].Value
        }
    }

    # Extract inputs from GitHub workflow
    $githubInputs = @()
    if ($githubContent -match '(?s)inputs:(.*?)(?:runs:|jobs:|\Z)') {
        $inputSection = $matches[1]
        $inputMatches = [regex]::Matches($inputSection, '(?m)^\s*(\w+):')
        foreach ($match in $inputMatches) {
            $githubInputs += $match.Groups[1].Value
        }
    }

    # Compare parameters
    $azDoParamsNotInGitHub = $azDoParams | Where-Object { $githubInputs -notcontains $_ }
    $githubInputsNotInAzDo = $githubInputs | Where-Object { $azDoParams -notcontains $_ }

    if ($azDoParamsNotInGitHub.Count -gt 0 -or $githubInputsNotInAzDo.Count -gt 0) {
        $results.ParameterDifferences = @{
            OnlyInAzDo = $azDoParamsNotInGitHub
            OnlyInGitHub = $githubInputsNotInAzDo
        }
    }

    # Simple content size comparison as a basic check
    $azDoSize = $azDoContent.Length
    $githubSize = $githubContent.Length
    $sizeDifferencePercent = [Math]::Abs(($azDoSize - $githubSize) / [Math]::Max($azDoSize, 1)) * 100

    $results.ContentSimilarity = @{
        AzDoSize = $azDoSize
        GitHubSize = $githubSize
        DifferencePercent = $sizeDifferencePercent
    }

    return $results
}

# Main script execution starts here
Write-Host "Comparing Azure DevOps templates with GitHub workflow files..." -ForegroundColor Cyan

# Verify paths exist
if (-not (Test-Path -Path $AzDoPath)) {
    Write-Error "Azure DevOps template path not found: $AzDoPath"
    exit 1
}

if (-not (Test-Path -Path $GitHubPath)) {
    Write-Error "GitHub workflow path not found: $GitHubPath"
    exit 1
}

# Get all template/workflow files
$azDoFiles = Get-ChildItem -Path $AzDoPath -Filter "*-template.yml" -Recurse
$githubFiles = Get-ChildItem -Path $GitHubPath -Filter "*.yml" -Recurse |
    Where-Object { -not $_.Name.EndsWith("-template.yml") } |
    Where-Object { $ExcludeFiles -notcontains $_.Name }

Write-Host "Found $($azDoFiles.Count) Azure DevOps templates and $($githubFiles.Count) GitHub workflows" -ForegroundColor Green

# Create mapping of base names to files
$azDoBaseNames = @{}
foreach ($file in $azDoFiles) {
    $baseName = Get-BaseName -FileName $file.Name -System "AzDo"
    $azDoBaseNames[$baseName] = $file
}

$githubBaseNames = @{}
foreach ($file in $githubFiles) {
    $baseName = Get-BaseName -FileName $file.Name -System "GitHub"
    $githubBaseNames[$baseName] = $file
}

# Find all unique base names
$allBaseNames = @($azDoBaseNames.Keys) + @($githubBaseNames.Keys) | Sort-Object -Unique

$results = @()
$inconsistentFiles = 0
$missingFiles = 0

foreach ($baseName in $allBaseNames) {
    $hasAzDo = $azDoBaseNames.ContainsKey($baseName)
    $hasGitHub = $githubBaseNames.ContainsKey($baseName)

    if ($hasAzDo -and $hasGitHub) {
        # Both systems have a file with this base name
        $azDoFile = $azDoBaseNames[$baseName]
        $githubFile = $githubBaseNames[$baseName]

        # Check expected naming convention
        $azDoFileExpectedName = "$baseName-template.yml"
        $githubFileExpectedName = "$baseName.yml"

        $azDoNamingCorrect = $azDoFile.Name -eq $azDoFileExpectedName
        $githubNamingCorrect = $githubFile.Name -eq $githubFileExpectedName

        $contentComparison = Compare-FileContent -AzDoFilePath $azDoFile.FullName -GitHubFilePath $githubFile.FullName

        $result = @{
            BaseName = $baseName
            AzDoFile = $azDoFile.Name
            GitHubFile = $githubFile.Name
            AzDoNamingCorrect = $azDoNamingCorrect
            GitHubNamingCorrect = $githubNamingCorrect
            ContentComparison = $contentComparison
            Status = if ($azDoNamingCorrect -and $githubNamingCorrect) { "Consistent" } else { "InconsistentNaming" }
        }

        if (-not ($azDoNamingCorrect -and $githubNamingCorrect)) {
            $inconsistentFiles++
        }

        # Display results to console
        Write-Host "`nComparing files for base name: $baseName" -ForegroundColor Yellow
        Write-Host "  Azure DevOps: $($azDoFile.Name) $(if($azDoNamingCorrect){"✅"}else{"❌"})"
        Write-Host "  GitHub: $($githubFile.Name) $(if($githubNamingCorrect){"✅"}else{"❌"})"

        if ($contentComparison.ParameterDifferences.Count -gt 0) {
            Write-Host "  Parameter differences found:" -ForegroundColor Magenta

            if ($contentComparison.ParameterDifferences.OnlyInAzDo.Count -gt 0) {
                Write-Host "    - Only in Azure DevOps: $($contentComparison.ParameterDifferences.OnlyInAzDo -join ', ')"
            }

            if ($contentComparison.ParameterDifferences.OnlyInGitHub.Count -gt 0) {
                Write-Host "    - Only in GitHub: $($contentComparison.ParameterDifferences.OnlyInGitHub -join ', ')"
            }
        }

        Write-Host "  Content similarity: $(100 - [Math]::Round($contentComparison.ContentSimilarity.DifferencePercent, 1))%"
    }
    else {
        # Missing in one of the systems
        $status = if (-not $hasAzDo) { "MissingInAzDo" } else { "MissingInGitHub" }
        $missingFiles++

        $result = @{
            BaseName = $baseName
            AzDoFile = if ($hasAzDo) { $azDoBaseNames[$baseName].Name } else { "Missing" }
            GitHubFile = if ($hasGitHub) { $githubBaseNames[$baseName].Name } else { "Missing" }
            AzDoNamingCorrect = if ($hasAzDo) { $azDoBaseNames[$baseName].Name -eq "$baseName-template.yml" } else { $false }
            GitHubNamingCorrect = if ($hasGitHub) { $githubBaseNames[$baseName].Name -eq "$baseName.yml" } else { $false }
            Status = $status
        }

        # Display results
        Write-Host "`nFile missing for base name: $baseName" -ForegroundColor Red

        if ($hasAzDo) {
            Write-Host "  Azure DevOps: $($azDoBaseNames[$baseName].Name) ✅"
            Write-Host "  GitHub: Missing ❌"
            Write-Host "  Expected GitHub file name would be: $baseName.yml"
        }
        else {
            Write-Host "  Azure DevOps: Missing ❌"
            Write-Host "  GitHub: $($githubBaseNames[$baseName].Name) ✅"
            Write-Host "  Expected Azure DevOps file name would be: $baseName-template.yml"
        }
    }

    $results += $result
}

# Generate report if requested
if ($Report) {
    $reportPath = "ci-consistency-report.json"
    $results | ConvertTo-Json -Depth 5 | Out-File -FilePath $reportPath
    Write-Host "`nDetailed report saved to: $reportPath" -ForegroundColor Cyan
}

# Summary
Write-Host "`n==== Summary ====" -ForegroundColor Cyan
Write-Host "Total files analyzed: $($allBaseNames.Count)" -ForegroundColor White
Write-Host "Files with naming inconsistencies: $inconsistentFiles" -ForegroundColor $(if ($inconsistentFiles -gt 0) { "Red" } else { "Green" })
Write-Host "Files missing in one system: $missingFiles" -ForegroundColor $(if ($missingFiles -gt 0) { "Red" } else { "Green" })

if ($inconsistentFiles -gt 0 -or $missingFiles -gt 0) {
    Write-Host "`n❌ Inconsistencies found. Please review and align Azure DevOps templates with GitHub workflows." -ForegroundColor Red
    exit 1
} else {
    Write-Host "`n✅ All files are consistent between Azure DevOps and GitHub." -ForegroundColor Green
    exit 0
}