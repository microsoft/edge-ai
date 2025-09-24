﻿#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Verifies and reports on SHA pinning compliance for supply chain security.

.DESCRIPTION
    Cross-platform PowerShell script that analyzes GitHub Actions workflows, Docker images,
    and other dependency declarations to verify compliance with SHA pinning security practices.
    Identifies unpinned dependencies and provides remediation guidance.

.PARAMETER Path
    Root path to scan for dependency files. Defaults to current directory.

.PARAMETER Recursive
    Scan recursively through subdirectories. Default is true.

.PARAMETER Format
    Output format for compliance report. Options: json, sarif, csv, markdown, table.
    Default is 'json' for programmatic processing.

.PARAMETER OutputPath
    Path where compliance results should be saved. Defaults to 'dependency-pinning-report.json'
    in the current directory.

.PARAMETER FailOnViolations
    Exit with error code if pinning violations are found. Default is false for reporting mode.

.PARAMETER ExcludePaths
    Comma-separated list of paths to exclude from scanning (glob patterns supported).

.PARAMETER IncludeTypes
    Comma-separated list of dependency types to check. Options: github-actions, docker, npm, pip, go-mod.
    Default is all types.

.PARAMETER Remediate
    Generate remediation suggestions with specific SHA pins for unpinned dependencies.

.EXAMPLE
    ./Test-DependencyPinning.ps1
    Scan current directory for dependency pinning compliance.

.EXAMPLE
    ./Test-DependencyPinning.ps1 -Path "/workspace" -Format "sarif" -FailOnViolations
    Scan workspace directory, output SARIF format, fail on violations.

.EXAMPLE
    ./Test-DependencyPinning.ps1 -IncludeTypes "github-actions,docker" -Remediate
    Check only GitHub Actions and Docker dependencies with remediation suggestions.

.NOTES
    Requires:
    - PowerShell 7.0 or later for cross-platform compatibility
    - Internet connectivity for SHA resolution (with -Remediate)
    - GitHub API access for action SHA resolution (optional)

    Compatible with:
    - Windows PowerShell 5.1+ (limited cross-platform features)
    - PowerShell 7.x on Windows, Linux, macOS
    - GitHub Actions runners (ubuntu-latest, windows-latest, macos-latest)
    - Azure DevOps agents (Microsoft-hosted and self-hosted)

.LINK
    https://docs.github.com/en/actions/security-guides/security-hardening-for-github-actions#using-third-party-actions
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Path = ".",

    [Parameter(Mandatory = $false)]
    [ValidateSet('json', 'sarif', 'csv', 'markdown', 'table')]
    [string]$Format = 'json',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'dependency-pinning-report.json',

    [Parameter(Mandatory = $false)]
    [switch]$FailOnUnpinned,

    [Parameter(Mandatory = $false)]
    [string]$ExcludePaths = "",

    [Parameter(Mandatory = $false)]
    [string]$IncludeTypes = "github-actions,docker,npm,pip,go-mod"

)

# Set error action preference for consistent error handling
$ErrorActionPreference = 'Stop'

# Define dependency patterns for different ecosystems
$DependencyPatterns = @{
    'github-actions' = @{
        FilePatterns    = @('**/.github/workflows/*.yml', '**/.github/workflows/*.yaml')
        VersionPatterns = @(
            @{
                Pattern     = 'uses:\s*([^@\s]+)@([^#\s]+)'
                Groups      = @{ Action = 1; Version = 2 }
                Description = 'GitHub Actions uses statements'
            }
        )
        SHAPattern      = '^[a-f0-9]{40}$'
        RemediationUrl  = 'https://api.github.com/repos/{0}/commits/{1}'
    }

    'docker'         = @{
        FilePatterns    = @('**/Dockerfile*', '**/*.dockerfile', '**/docker-compose*.yml', '**/docker-compose*.yaml')
        VersionPatterns = @(
            @{
                Pattern     = 'FROM\s+([^:\s]+):([^@\s]+)'
                Groups      = @{ Image = 1; Tag = 2 }
                Description = 'Docker FROM statements with tags'
            },
            @{
                Pattern     = 'image:\s*([^:\s]+):([^@\s]+)'
                Groups      = @{ Image = 1; Tag = 2 }
                Description = 'Docker Compose image specifications'
            }
        )
        SHAPattern      = '^sha256:[a-f0-9]{64}$'
        RemediationUrl  = 'https://registry.hub.docker.com/v2/repositories/{0}/tags/{1}'
    }

    'npm'            = @{
        FilePatterns    = @('**/package.json', '**/package-lock.json')
        VersionPatterns = @(
            @{
                Pattern     = '"([^"]+)":\s*"([^@][^"]*)"'
                Groups      = @{ Package = 1; Version = 2 }
                Description = 'NPM dependencies in package.json'
            }
        )
        SHAPattern      = '^[a-f0-9]{40}$'
        RemediationUrl  = 'https://registry.npmjs.org/{0}/{1}'
    }

    'pip'            = @{
        FilePatterns    = @('**/requirements*.txt', '**/Pipfile', '**/pyproject.toml', '**/setup.py')
        VersionPatterns = @(
            @{
                Pattern     = '([a-zA-Z0-9\-_]+)==([^#\s]+)'
                Groups      = @{ Package = 1; Version = 2 }
                Description = 'Python pip requirements'
            }
        )
        SHAPattern      = '^[a-f0-9]{40}$'
        RemediationUrl  = 'https://pypi.org/pypi/{0}/{1}/json'
    }

    'go-mod'         = @{
        FilePatterns    = @('**/go.mod', '**/go.sum')
        VersionPatterns = @(
            @{
                Pattern     = '([^\s]+)\s+v([0-9]+\.[0-9]+\.[0-9]+[^\s]*)'
                Groups      = @{ Module = 1; Version = 2 }
                Description = 'Go module dependencies'
            }
        )
        SHAPattern      = '^v[0-9]+\.[0-9]+\.[0-9]+-[0-9]+-[a-f0-9]{12}$'
        RemediationUrl  = 'https://proxy.golang.org/{0}/@v/{1}.info'
    }
}

class DependencyViolation {
    [string]$File
    [int]$Line
    [string]$Type
    [string]$Name
    [string]$Version
    [string]$CurrentRef
    [string]$Severity
    [string]$Description
    [string]$Remediation
    [hashtable]$Metadata

    DependencyViolation() {
        $this.Metadata = @{}
    }
}

class ComplianceReport {
    [string]$ScanPath
    [datetime]$Timestamp
    [int]$TotalFiles
    [int]$ScannedFiles
    [int]$TotalDependencies
    [int]$PinnedDependencies
    [int]$UnpinnedDependencies
    [decimal]$ComplianceScore
    [DependencyViolation[]]$Violations
    [hashtable]$Summary
    [hashtable]$Metadata

    ComplianceReport() {
        $this.Timestamp = Get-Date
        $this.Violations = @()
        $this.Summary = @{}
        $this.Metadata = @{}
    }
}

function Write-PinningLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] [$Level] $Message"
}

function Get-FilesToScan {
    <#
    .SYNOPSIS
    Discovers files to scan based on dependency type patterns.
    #>
    param(
        [string]$ScanPath,
        [string[]]$Types,
        [string[]]$ExcludePatterns
    )

    $allFiles = @()

    foreach ($type in $Types) {
        if ($DependencyPatterns.ContainsKey($type)) {
            $patterns = $DependencyPatterns[$type].FilePatterns

            foreach ($pattern in $patterns) {
                # Convert glob pattern to PowerShell-compatible path
                $searchPath = Join-Path $ScanPath $pattern

                try {
                    if ($Recursive) {
                        $files = Get-ChildItem -Path $searchPath -Recurse -File -ErrorAction SilentlyContinue
                    }
                    else {
                        $files = Get-ChildItem -Path $searchPath -File -ErrorAction SilentlyContinue
                    }

                    # Apply exclusion filters
                    if ($ExcludePatterns) {
                        foreach ($exclude in $ExcludePatterns) {
                            $files = $files | Where-Object { $_.FullName -notlike "*$exclude*" }
                        }
                    }

                    $allFiles += $files | ForEach-Object {
                        @{
                            Path         = $_.FullName
                            Type         = $type
                            RelativePath = [System.IO.Path]::GetRelativePath($ScanPath, $_.FullName)
                        }
                    }
                }
                catch {
                    Write-PinningLog "Error scanning for $type files with pattern $pattern`: $($_.Exception.Message)" -Level Warning
                }
            }
        }
    }

    return $allFiles | Sort-Object Path -Unique
}

function Test-SHAPinning {
    <#
    .SYNOPSIS
    Tests if a version reference is properly SHA-pinned.
    #>
    param(
        [string]$Version,
        [string]$Type
    )

    if ($DependencyPatterns.ContainsKey($Type) -and $DependencyPatterns[$Type].SHAPattern) {
        $shaPattern = $DependencyPatterns[$Type].SHAPattern
        return $Version -match $shaPattern
    }

    return $false
}

function Get-DependencyViolation {
    <#
    .SYNOPSIS
    Scans a file for dependency pinning violations.
    #>
    param(
        [hashtable]$FileInfo
    )

    $violations = @()
    $filePath = $FileInfo.Path
    $fileType = $FileInfo.Type

    if (!(Test-Path $filePath)) {
        return $violations
    }

    try {
        $content = Get-Content -Path $filePath -Raw
        $lines = Get-Content -Path $filePath

        $patterns = $DependencyPatterns[$fileType].VersionPatterns

        foreach ($patternInfo in $patterns) {
            $pattern = $patternInfo.Pattern
            $groups = $patternInfo.Groups
            $description = $patternInfo.Description

            $regexMatches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Multiline)

            foreach ($match in $regexMatches) {
                # Find line number
                $lineNumber = 1
                $position = $match.Index
                for ($i = 0; $i -lt $position; $i++) {
                    if ($content[$i] -eq "`n") {
                        $lineNumber++
                    }
                }

                # Extract dependency information
                $dependencyName = $match.Groups[($groups.Keys | Where-Object { $groups[$_] -eq 1 })].Value
                $version = $match.Groups[($groups.Keys | Where-Object { $groups[$_] -eq 2 })].Value

                # Check if properly pinned
                if (!(Test-SHAPinning -Version $version -Type $fileType)) {
                    $violation = [DependencyViolation]::new()
                    $violation.File = $FileInfo.RelativePath
                    $violation.Line = $lineNumber
                    $violation.Type = $fileType
                    $violation.Name = $dependencyName
                    $violation.Version = $version
                    $violation.CurrentRef = $match.Value
                    $violation.Description = "Unpinned dependency: $description"
                    $violation.Severity = if ($fileType -eq 'github-actions') { 'High' } else { 'Medium' }
                    $violation.Metadata['PatternDescription'] = $description
                    $violation.Metadata['LineContent'] = $lines[$lineNumber - 1]

                    $violations += $violation
                }
            }
        }
    }
    catch {
        Write-PinningLog "Error scanning file $filePath`: $($_.Exception.Message)" -Level Warning
    }

    return $violations
}

function Get-RemediationSuggestion {
    <#
    .SYNOPSIS
    Generates remediation suggestions for unpinned dependencies.
    #>
    param(
        [DependencyViolation]$Violation
    )

    if (!$Remediate) {
        return "Enable -Remediate flag for specific SHA suggestions"
    }

    $type = $Violation.Type
    $name = $Violation.Name
    $version = $Violation.Version

    try {
        switch ($type) {
            'github-actions' {
                # For GitHub Actions, resolve tag to commit SHA
                $apiUrl = "https://api.github.com/repos/$name/commits/$version"
                $headers = @{}

                if ($env:GITHUB_TOKEN) {
                    $headers['Authorization'] = "Bearer $env:GITHUB_TOKEN"
                }

                $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -TimeoutSec 30
                $sha = $response.sha

                if ($sha) {
                    return "Pin to SHA: uses: $name@$sha # $version"
                }
            }

            'docker' {
                # For Docker images, suggest using digest instead of tag
                return "Use image digest instead of tag. Run: docker pull $name`:$version && docker inspect --format='{{index .RepoDigests 0}}' $name`:$version"
            }

            default {
                return "Research and pin to specific commit SHA or content hash for $type dependencies"
            }
        }
    }
    catch {
        Write-PinningLog "Could not generate automatic remediation for $($Violation.Name): $($_.Exception.Message)" -Level Warning
    }

    return "Manually research and pin to immutable reference"
}

function Get-ComplianceReportData {
    <#
    .SYNOPSIS
    Generates a comprehensive compliance report.
    #>
    param(
        [DependencyViolation[]]$Violations,
        [hashtable[]]$ScannedFiles,
        [string]$ScanPath
    )

    $report = [ComplianceReport]::new()
    $report.ScanPath = $ScanPath
    $report.ScannedFiles = $ScannedFiles.Count
    $report.Violations = $Violations

    # Calculate metrics
    $totalDeps = ($Violations | Measure-Object).Count
    $unpinnedDeps = ($Violations | Where-Object { $_.Severity -ne 'Info' } | Measure-Object).Count
    $pinnedDeps = $totalDeps - $unpinnedDeps

    $report.TotalDependencies = $totalDeps
    $report.PinnedDependencies = $pinnedDeps
    $report.UnpinnedDependencies = $unpinnedDeps

    if ($totalDeps -gt 0) {
        $report.ComplianceScore = [math]::Round(($pinnedDeps / $totalDeps) * 100, 2)
    }
    else {
        $report.ComplianceScore = 100.0
    }

    # Generate summary by type
    $report.Summary = @{}
    foreach ($type in ($Violations | Group-Object Type)) {
        $report.Summary[$type.Name] = @{
            Total  = $type.Count
            High   = ($type.Group | Where-Object { $_.Severity -eq 'High' } | Measure-Object).Count
            Medium = ($type.Group | Where-Object { $_.Severity -eq 'Medium' } | Measure-Object).Count
            Low    = ($type.Group | Where-Object { $_.Severity -eq 'Low' } | Measure-Object).Count
        }
    }

    # Add metadata
    $report.Metadata = @{
        PowerShellVersion  = $PSVersionTable.PSVersion.ToString()
        Platform           = $PSVersionTable.Platform
        ScanTimestamp      = $report.Timestamp.ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
        IncludedTypes      = $IncludeTypes
        ExcludedPaths      = $ExcludePaths
        RemediationEnabled = $Remediate.IsPresent
    }

    return $report
}

function Export-ComplianceReport {
    <#
    .SYNOPSIS
    Exports compliance report in specified format.
    #>
    param(
        [ComplianceReport]$Report,
        [string]$Format,
        [string]$OutputPath
    )

    switch ($Format.ToLower()) {
        'json' {
            $Report | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        }

        'sarif' {
            $sarif = @{
                version    = "2.1.0"
                "`$schema" = "https://json.schemastore.org/sarif-2.1.0.json"
                runs       = @(@{
                        tool    = @{
                            driver = @{
                                name           = "dependency-pinning-analyzer"
                                version        = "1.0.0"
                                informationUri = "https://github.com/microsoft/edge-ai"
                            }
                        }
                        results = @($Report.Violations | ForEach-Object {
                                @{
                                    ruleId     = "dependency-not-pinned"
                                    level      = switch ($_.Severity) { 'High' { 'error' } 'Medium' { 'warning' } default { 'note' } }
                                    message    = @{ text = $_.Description }
                                    locations  = @(@{
                                            physicalLocation = @{
                                                artifactLocation = @{ uri = $_.File }
                                                region           = @{ startLine = $_.Line }
                                            }
                                        })
                                    properties = @{
                                        dependencyName = $_.Name
                                        currentVersion = $_.Version
                                        remediation    = $_.Remediation
                                    }
                                }
                            })
                    })
            }
            $sarif | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
        }

        'csv' {
            $Report.Violations | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
        }

        'markdown' {
            $markdown = @"
# Dependency Pinning Compliance Report

**Scan Date:** $($Report.Timestamp.ToString('yyyy-MM-dd HH:mm:ss'))
**Scan Path:** $($Report.ScanPath)
**Compliance Score:** $($Report.ComplianceScore)%

## Summary

| Metric | Count |
|--------|--------|
| Total Files Scanned | $($Report.ScannedFiles) |
| Total Dependencies | $($Report.TotalDependencies) |
| Pinned Dependencies | $($Report.PinnedDependencies) |
| Unpinned Dependencies | $($Report.UnpinnedDependencies) |

## Violations by Type

"@
            foreach ($type in $Report.Summary.Keys) {
                $summary = $Report.Summary[$type]
                $markdown += @"

### $type
- **Total:** $($summary.Total)
- **High Severity:** $($summary.High)
- **Medium Severity:** $($summary.Medium)
- **Low Severity:** $($summary.Low)

"@
            }

            if ($Report.Violations.Count -gt 0) {
                $markdown += @"

## Detailed Violations

| File | Line | Type | Dependency | Current Version | Severity | Remediation |
|------|------|------|------------|----------------|----------|-------------|
"@
                foreach ($violation in $Report.Violations) {
                    $markdown += "|$($violation.File)|$($violation.Line)|$($violation.Type)|$($violation.Name)|$($violation.Version)|$($violation.Severity)|$($violation.Remediation)|`n"
                }
            }

            $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
        }

        'table' {
            # Display formatted table to console and save simple text format
            if ($Report.Violations.Count -gt 0) {
                $Report.Violations | Format-Table -Property File, Line, Type, Name, Version, Severity -AutoSize | Out-File -FilePath $OutputPath -Encoding UTF8 -Width 200
            }
            else {
                "No dependency pinning violations found." | Out-File -FilePath $OutputPath -Encoding UTF8
            }
        }
    }

    Write-PinningLog "Compliance report exported to: $OutputPath" -Level Success
}

function Export-CICDArtifact {
    <#
    .SYNOPSIS
    Exports compliance report as CI/CD artifacts for both GitHub Actions and Azure DevOps.
    #>
    param(
        [ComplianceReport]$Report,
        [string]$ReportPath
    )

    Write-PinningLog "Preparing compliance artifacts for CI/CD systems..." -Level Info

    # GitHub Actions artifact export
    if ($env:GITHUB_ACTIONS -eq 'true') {
        Write-PinningLog "Detected GitHub Actions environment - setting up artifacts" -Level Info

        # Set outputs for GitHub Actions
        if ($env:GITHUB_OUTPUT) {
            "dependency-report=$ReportPath" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8
            "compliance-score=$($Report.ComplianceScore)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8
            "unpinned-count=$($Report.UnpinnedDependencies)" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8
        }

        # Set up for actions/upload-artifact@v4
        $artifactDir = Join-Path $PWD "dependency-pinning-artifacts"
        New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
        Copy-Item -Path $ReportPath -Destination $artifactDir -Force

        # Create GitHub summary
        $summaryPath = Join-Path $artifactDir "github-summary.md"
        @"
# 📌 Dependency Pinning Analysis

**Compliance Score:** $($Report.ComplianceScore)%
**Unpinned Dependencies:** $($Report.UnpinnedDependencies)
**Total Dependencies Scanned:** $($Report.TotalDependencies)

$(if ($Report.UnpinnedDependencies -gt 0) { "⚠️ **Action Required:** $($Report.UnpinnedDependencies) dependencies are not properly pinned to immutable references." } else { "✅ **All Clear:** All dependencies are properly pinned!" })
"@ | Out-File -FilePath $summaryPath -Encoding UTF8

        if ($env:GITHUB_STEP_SUMMARY) {
            Copy-Item -Path $summaryPath -Destination $env:GITHUB_STEP_SUMMARY -Force
        }
    }

    # Azure DevOps artifact export
    if ($env:TF_BUILD -eq 'True' -or $env:AZURE_PIPELINES -eq 'True') {
        Write-PinningLog "Detected Azure DevOps environment - setting up artifacts" -Level Info

        # Set Azure DevOps variables
        Write-Output "##vso[task.setvariable variable=dependencyReport;isOutput=true]$ReportPath"
        Write-Output "##vso[task.setvariable variable=complianceScore;isOutput=true]$($Report.ComplianceScore)"
        Write-Output "##vso[task.setvariable variable=unpinnedCount;isOutput=true]$($Report.UnpinnedDependencies)"

        # Publish as pipeline artifact
        Write-Output "##vso[artifact.upload containerfolder=dependency-pinning;artifactname=dependency-pinning-report]$ReportPath"

        # Add to build summary
        Write-Output "##[section]Dependency Pinning Compliance Report"
        Write-Output "Compliance Score: $($Report.ComplianceScore)%"
        Write-Output "Unpinned Dependencies: $($Report.UnpinnedDependencies)"
        Write-Output "Total Dependencies: $($Report.TotalDependencies)"
    }

    Write-PinningLog "Compliance artifacts prepared for CI/CD consumption" -Level Success
}

# Main execution
try {
    Write-PinningLog "Starting dependency pinning compliance analysis..." -Level Info
    Write-PinningLog "PowerShell Version: $($PSVersionTable.PSVersion)" -Level Info
    Write-PinningLog "Platform: $($PSVersionTable.Platform)" -Level Info

    # Parse include types and exclude paths
    $typesToCheck = $IncludeTypes.Split(',') | ForEach-Object { $_.Trim() }
    $excludePatterns = if ($ExcludePaths) { $ExcludePaths.Split(',') | ForEach-Object { $_.Trim() } } else { @() }

    Write-PinningLog "Scanning path: $Path" -Level Info
    Write-PinningLog "Include types: $($typesToCheck -join ', ')" -Level Info
    if ($excludePatterns) { Write-PinningLog "Exclude patterns: $($excludePatterns -join ', ')" -Level Info }

    # Discover files to scan
    $filesToScan = Get-FilesToScan -ScanPath $Path -Types $typesToCheck -ExcludePatterns $excludePatterns
    Write-PinningLog "Found $($filesToScan.Count) files to scan" -Level Info

    # Scan for violations
    $allViolations = @()
    foreach ($fileInfo in $filesToScan) {
        Write-PinningLog "Scanning: $($fileInfo.RelativePath)" -Level Info
        $violations = Get-DependencyViolation -FileInfo $fileInfo

        # Add remediation suggestions
        foreach ($violation in $violations) {
            $violation.Remediation = Get-RemediationSuggestion -Violation $violation
        }

        $allViolations += $violations
    }

    Write-PinningLog "Found $($allViolations.Count) dependency pinning violations" -Level Info

    # Generate compliance report
    $report = Get-ComplianceReportData -Violations $allViolations -ScannedFiles $filesToScan -ScanPath $Path

    # Export report
    Export-ComplianceReport -Report $report -Format $Format -OutputPath $OutputPath

    # Export CI/CD artifacts
    Export-CICDArtifact -Report $report -ReportPath $OutputPath

    # Display summary
    Write-PinningLog "Compliance Analysis Complete!" -Level Success
    Write-PinningLog "Compliance Score: $($report.ComplianceScore)%" -Level Info
    Write-PinningLog "Total Dependencies: $($report.TotalDependencies)" -Level Info
    Write-PinningLog "Unpinned Dependencies: $($report.UnpinnedDependencies)" -Level Info

    if ($report.UnpinnedDependencies -gt 0) {
        Write-PinningLog "$($report.UnpinnedDependencies) dependencies require SHA pinning for security compliance" -Level Warning

        if ($FailOnUnpinned) {
            Write-PinningLog "Failing build due to dependency pinning violations (-FailOnViolations enabled)" -Level Error
            exit 1
        }
    }
    else {
        Write-PinningLog "All dependencies are properly pinned! ✅" -Level Success
    }

}
catch {
    Write-PinningLog "Dependency pinning analysis failed: $($_.Exception.Message)" -Level Error
    Write-PinningLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
