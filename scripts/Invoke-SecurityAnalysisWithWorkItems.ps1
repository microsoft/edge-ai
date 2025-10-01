<#
.SYNOPSIS
    Runs Checkov security analysis on Kubernetes and Arc components, evaluates findings, and creates work item planning files for Azure DevOps handoff.

.DESCRIPTION
    This script orchestrates a multi-stage security analysis workflow:
    1. Executes Checkov security scanning using existing configuration
    2. Parses JSON output to filter K8s/Arc-specific findings
    3. Evaluates security findings by severity and criticality
    4. Creates work item planning files and handoff documentation for subsequent Azure DevOps work item creation

    The script focuses on Kubernetes clusters and Arc components in the edge-ai project,
    integrating with existing Checkov tooling and preparing structured planning files
    that can be used with Azure DevOps MCP server for work item creation workflow.

    docs/security-analysis-workflow.md
    Full instructions on the script usage and workflow are documented in:

.PARAMETER ConfigFile
    Path to the Checkov configuration file. Default is "../.checkov.yml".

.PARAMETER OutputFolder
    Folder to store Checkov reports and analysis results. Default is "./logs/checkov-security-analysis".

.PARAMETER TargetComponents
    JSON string or path to JSON file specifying target components for analysis.
    If not specified, defaults to K8s and Arc components.

.PARAMETER SeverityThreshold
    Minimum severity level for creating work items. Options: LOW, MEDIUM, HIGH, CRITICAL.
    Default is HIGH.

.PARAMETER Project
    Azure DevOps project name. Default is "edge-ai".

.PARAMETER AreaPath
    Azure DevOps area path for created work items. Optional.

.PARAMETER IterationPath
    Azure DevOps iteration path for created work items. Optional.

.PARAMETER Interactive
    Switch to enable interactive mode for manual triage of security findings.

.EXAMPLE
    # Run with defaults on K8s/Arc components
    .\Invoke-SecurityAnalysisWithWorkItems.ps1

.EXAMPLE
    # Run with custom severity threshold and output location
    .\Invoke-SecurityAnalysisWithWorkItems.ps1 -SeverityThreshold MEDIUM -OutputFolder "./security-reports"

.EXAMPLE
    # Run in interactive mode for manual triage
    .\Invoke-SecurityAnalysisWithWorkItems.ps1 -Interactive

.OUTPUTS
    Security analysis report and work item planning files for Azure DevOps handoff.
    Generated planning files follow the structure defined in:
    .github/instructions/ado-wit-planning.instructions.md
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "$PSScriptRoot/../.checkov.yml",

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "./logs/checkov-security-analysis",

    [Parameter(Mandatory = $false)]
    [string]$TargetComponents,

    [Parameter(Mandatory = $false)]
    [ValidateSet("LOW", "MEDIUM", "HIGH", "CRITICAL")]
    [string]$SeverityThreshold = "HIGH",

    [Parameter(Mandatory = $false)]
    [string]$Project = "edge-ai",

    [Parameter(Mandatory = $false)]
    [string]$AreaPath,

    [Parameter(Mandatory = $false)]
    [string]$IterationPath,

    [Parameter(Mandatory = $false)]
    [switch]$Interactive
)

# Import required modules and set error handling
$ErrorActionPreference = "Stop"
Set-StrictMode -Version Latest

# Define severity levels for comparison
$SeverityLevels = @{
    "LOW"      = 1
    "MEDIUM"   = 2
    "HIGH"     = 3
    "CRITICAL" = 4
}

# Default target components focusing on K8s and Arc
$DefaultTargetComponents = @{
    "terraform" = @{
        "has_changes" = $true
        "folders"     = @{
            "folder1" = @{ "folderName" = "src/100-edge/100-cncf-cluster/terraform" }
            "folder2" = @{ "folderName" = "src/100-edge/110-iot-ops/terraform" }
            "folder3" = @{ "folderName" = "src/000-cloud/070-kubernetes/terraform" }
        }
    }
    "bicep"     = @{
        "has_changes" = $true
        "folders"     = @{
            "folder1" = @{ "folderName" = "src/100-edge/100-cncf-cluster/bicep" }
            "folder2" = @{ "folderName" = "src/100-edge/110-iot-ops/bicep" }
        }
    }
}

function Write-HostWithTimestamp {
    param(
        [string]$Message,
        [string]$ForegroundColor = "White"
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "[$timestamp] $Message" -ForegroundColor $ForegroundColor
}

function Initialize-OutputFolder {
    param([string]$Path)

    Write-HostWithTimestamp "📁 Initializing output folder: $Path" -ForegroundColor Gray

    if (-not (Test-Path -Path $Path)) {
        New-Item -Path $Path -ItemType Directory -Force | Out-Null
        Write-HostWithTimestamp "✅ Created output folder: $Path" -ForegroundColor Green
    }
    else {
        Write-HostWithTimestamp "📂 Using existing output folder: $Path" -ForegroundColor Gray
    }
}

function Get-TargetComponentsConfig {
    param([string]$TargetComponents)

    if ([string]::IsNullOrEmpty($TargetComponents)) {
        Write-HostWithTimestamp "🎯 Using default K8s/Arc target components" -ForegroundColor Cyan
        return $DefaultTargetComponents
    }

    try {
        if (Test-Path -Path $TargetComponents) {
            Write-HostWithTimestamp "📄 Loading target components from file: $TargetComponents" -ForegroundColor Cyan
            $content = Get-Content -Path $TargetComponents -Raw
            return $content | ConvertFrom-Json -AsHashtable
        }
        else {
            Write-HostWithTimestamp "🔄 Parsing target components from JSON string" -ForegroundColor Cyan
            return $TargetComponents | ConvertFrom-Json -AsHashtable
        }
    }
    catch {
        Write-Warning "❌ Failed to parse target components, using defaults: $_"
        return $DefaultTargetComponents
    }
}

function Invoke-CheckovAnalysis {
    param(
        [hashtable]$TargetConfig,
        [string]$OutputFolder,
        [string]$ConfigFile
    )

    Write-HostWithTimestamp "🔍 Starting Checkov security analysis" -ForegroundColor Yellow

    # Convert target config to JSON for Run-Checkov.ps1
    $inputJson = $TargetConfig | ConvertTo-Json -Depth 10

    # Ensure the config file exists
    if (-not (Test-Path -Path $ConfigFile)) {
        throw "Checkov configuration file not found: $ConfigFile"
    }

    Write-HostWithTimestamp "⚙️ Using Checkov config: $ConfigFile" -ForegroundColor Gray

    # Run the existing Checkov script
    $checkovScript = "$PSScriptRoot/Run-Checkov.ps1"
    if (-not (Test-Path -Path $checkovScript)) {
        throw "Run-Checkov.ps1 script not found: $checkovScript"
    }

    try {
        Write-HostWithTimestamp "🚀 Executing Checkov scan..." -ForegroundColor Yellow

        # Reset LASTEXITCODE before execution
        $global:LASTEXITCODE = $null

        # Execute the script and capture the result
        $result = & $checkovScript -InputJson $inputJson -OutputFolder $OutputFolder -OutputFile "security-analysis.xml" 2>&1
        $exitCode = $global:LASTEXITCODE

        # For PowerShell scripts, we mainly check if there was an exception
        # The warnings about XML parsing are expected and not fatal errors
        Write-HostWithTimestamp "✅ Checkov analysis completed (Exit Code: $exitCode)" -ForegroundColor Green

        # Check if the output folder has the expected JSON files
        $jsonFiles = Get-ChildItem -Path $OutputFolder -Filter "*.json" -Recurse
        if ($jsonFiles.Count -eq 0) {
            Write-Warning "⚠️ No JSON output files found, but continuing with analysis"
        }
        else {
            Write-HostWithTimestamp "📁 Found $($jsonFiles.Count) JSON result files" -ForegroundColor Gray
        }

        return $result
    }
    catch {
        Write-HostWithTimestamp "❌ Failed to execute Checkov analysis: $_" -ForegroundColor Red
        throw
    }
}

function Get-CheckovFinding {
    param([string]$OutputFolder)

    Write-HostWithTimestamp "📊 Parsing Checkov findings from JSON output" -ForegroundColor Cyan

    # Look for JSON output files in the output folder
    $jsonFiles = Get-ChildItem -Path $OutputFolder -Filter "*.json" -Recurse

    if ($jsonFiles.Count -eq 0) {
        Write-Warning "⚠️ No JSON output files found in $OutputFolder"
        return @()
    }

    $allFindings = @()

    foreach ($jsonFile in $jsonFiles) {
        Write-HostWithTimestamp "📄 Processing: $($jsonFile.Name)" -ForegroundColor Gray

        try {
            $content = Get-Content -Path $jsonFile.FullName -Raw | ConvertFrom-Json

            # Process different Checkov output formats
            if ($content -is [array]) {
                # Handle array format with multiple check types
                foreach ($checkTypeResult in $content) {
                    if ($checkTypeResult.results -and $checkTypeResult.results.failed_checks) {
                        $allFindings += $checkTypeResult.results.failed_checks
                    }
                }
            }
            elseif ($content.results) {
                # Handle single result format
                $findings = $content.results.failed_checks
                if ($findings) {
                    $allFindings += $findings
                }
            }
            elseif ($content.failed_checks) {
                # Handle direct failed_checks format
                $allFindings += $content.failed_checks
            }
        }
        catch {
            Write-Warning "⚠️ Failed to parse JSON file $($jsonFile.Name): $_"
        }
    }

    Write-HostWithTimestamp "📈 Found $($allFindings.Count) total security findings" -ForegroundColor Cyan
    return $allFindings
}

function Get-KubernetesArcFinding {
    param([array]$AllFindings)

    Write-HostWithTimestamp "🎯 Filtering K8s and Arc-specific findings" -ForegroundColor Cyan

    # Define patterns for K8s and Arc-related findings
    $k8sArcPatterns = @(
        "CKV_K8S_*",           # Kubernetes checks
        "CKV_AZURE_*",         # Azure-specific checks
        "*kubernetes*",        # General K8s references
        "*k8s*",              # K8s abbreviation
        "*arc*",              # Azure Arc references
        "*cluster*",          # Cluster-related
        "*container*",        # Container security
        "*pod*",              # Pod security
        "*service*",          # Service configurations
        "*rbac*",             # RBAC security
        "*network*",          # Network policies
        "*security*"          # General security contexts
    )

    $filteredFindings = @()

    foreach ($finding in $AllFindings) {
        $isK8sArc = $false

        # Check against patterns in various fields (using correct property names)
        $searchFields = @()
        if ($finding.check_id) { $searchFields += $finding.check_id }
        if ($finding.check_name) { $searchFields += $finding.check_name }
        if ($finding.resource) { $searchFields += $finding.resource }
        if ($finding.file_path) { $searchFields += $finding.file_path }
        if ($finding.repo_file_path) { $searchFields += $finding.repo_file_path }
        if ($finding.description) { $searchFields += $finding.description }

        foreach ($field in $searchFields) {
            if ($field) {
                foreach ($pattern in $k8sArcPatterns) {
                    if ($field -like $pattern) {
                        $isK8sArc = $true
                        break
                    }
                }
                if ($isK8sArc) { break }
            }
        }

        # Also check if the file path contains K8s/Arc component directories
        if (-not $isK8sArc -and $finding.file_path) {
            $k8sArcPaths = @(
                "*/100-cncf-cluster/*",
                "*/070-kubernetes/*",
                "*/110-iot-ops/*"
            )

            foreach ($path in $k8sArcPaths) {
                if ($finding.file_path -like $path) {
                    $isK8sArc = $true
                    break
                }
            }
        }

        if ($isK8sArc) {
            # Add component classification
            $finding | Add-Member -NotePropertyName "component_type" -NotePropertyValue $(
                if ($finding.file_path -like "*100-cncf-cluster*") { "CNCF-Cluster" }
                elseif ($finding.file_path -like "*070-kubernetes*") { "Azure-Kubernetes" }
                elseif ($finding.file_path -like "*110-iot-ops*") { "IoT-Operations" }
                else { "K8s-Arc-Related" }
            ) -Force

            $filteredFindings += $finding
        }
    }

    Write-HostWithTimestamp "🎯 Filtered to $($filteredFindings.Count) K8s/Arc-related findings" -ForegroundColor Green
    return $filteredFindings
}

function Get-FindingSeverity {
    param([object]$Finding)

    # Determine severity based on check type, severity field, or check ID patterns
    if ($Finding.severity) {
        return $Finding.severity.ToUpper()
    }

    # Map check IDs to severity levels based on security impact
    $criticalPatterns = @(
        "*RBAC*", "*ROOT*", "*PRIVILEGED*", "*ADMIN*", "*CLUSTER_ADMIN*"
    )

    $highPatterns = @(
        "*SECURITY*", "*NETWORK*", "*SECRET*", "*CREDENTIAL*", "*TOKEN*"
    )

    $mediumPatterns = @(
        "*RESOURCE*", "*LIMIT*", "*POLICY*", "*CONFIG*"
    )

    $checkInfo = "$($Finding.check_id) $($Finding.check_name) $($Finding.description)".ToLower()

    foreach ($pattern in $criticalPatterns) {
        if ($checkInfo -like $pattern.ToLower()) {
            return "CRITICAL"
        }
    }

    foreach ($pattern in $highPatterns) {
        if ($checkInfo -like $pattern.ToLower()) {
            return "HIGH"
        }
    }

    foreach ($pattern in $mediumPatterns) {
        if ($checkInfo -like $pattern.ToLower()) {
            return "MEDIUM"
        }
    }

    return "LOW"
}

function Show-FindingsSummary {
    param([array]$Findings)

    Write-HostWithTimestamp "📊 Security Findings Summary" -ForegroundColor Yellow
    Write-Host ""

    # Group by severity
    $severityGroups = $Findings | Group-Object { Get-FindingSeverity $_ }

    $summaryTable = @()
    foreach ($group in $severityGroups) {
        $summaryTable += [PSCustomObject]@{
            Severity = $group.Name
            Count    = $group.Count
        }
    }

    $summaryTable | Sort-Object { $SeverityLevels[$_.Severity] } -Descending | Format-Table -AutoSize

    # Group by component
    Write-HostWithTimestamp "🏗️ Findings by Component:" -ForegroundColor Cyan
    $componentGroups = $Findings | Group-Object component_type
    foreach ($group in $componentGroups) {
        Write-Host "  • $($group.Name): $($group.Count) findings" -ForegroundColor Gray
    }
    Write-Host ""
}

function Invoke-InteractiveTriage {
    param([array]$Findings, [string]$SeverityThreshold)

    Write-HostWithTimestamp "🤔 Interactive triage mode enabled" -ForegroundColor Yellow
    Write-Host ""

    $selectedFindings = @()
    $thresholdLevel = $SeverityLevels[$SeverityThreshold]

    foreach ($finding in $Findings) {
        $severity = Get-FindingSeverity $finding
        $severityLevel = $SeverityLevels[$severity]

        if ($severityLevel -ge $thresholdLevel) {
            Write-Host "🔍 Finding Review:" -ForegroundColor Yellow
            Write-Host "   Check ID: $($finding.check_id)" -ForegroundColor White
            Write-Host "   Severity: $severity" -ForegroundColor $(if ($severityLevel -ge 3) { "Red" } elseif ($severityLevel -eq 2) { "Yellow" } else { "Green" })
            Write-Host "   Component: $($finding.component_type)" -ForegroundColor Cyan
            Write-Host "   Resource: $($finding.resource)" -ForegroundColor Gray
            Write-Host "   Description: $($finding.description)" -ForegroundColor Gray
            Write-Host ""

            do {
                $response = Read-Host "Create work item for this finding? [Y/n/q]"
                $response = $response.ToLower()

                if ($response -eq "q") {
                    Write-HostWithTimestamp "⏹️ Triage cancelled by user" -ForegroundColor Yellow
                    return $selectedFindings
                }
                elseif ($response -eq "" -or $response -eq "y") {
                    $selectedFindings += $finding
                    Write-Host "✅ Added to work item creation queue" -ForegroundColor Green
                    break
                }
                elseif ($response -eq "n") {
                    Write-Host "⏭️ Skipped" -ForegroundColor Gray
                    break
                }
                else {
                    Write-Host "Invalid response. Please enter Y, n, or q." -ForegroundColor Red
                }
            } while ($true)

            Write-Host ""
        }
    }

    Write-HostWithTimestamp "📝 Selected $($selectedFindings.Count) findings for work item creation" -ForegroundColor Green
    return $selectedFindings
}

function Get-FindingForWorkItem {
    param([array]$Findings, [string]$SeverityThreshold, [bool]$Interactive)

    if ($Interactive) {
        return Invoke-InteractiveTriage -Findings $Findings -SeverityThreshold $SeverityThreshold
    }

    # Automatic filtering by severity threshold
    $thresholdLevel = $SeverityLevels[$SeverityThreshold]
    $selectedFindings = @()

    foreach ($finding in $Findings) {
        $severity = Get-FindingSeverity $finding
        $severityLevel = $SeverityLevels[$severity]

        if ($severityLevel -ge $thresholdLevel) {
            $selectedFindings += $finding
        }
    }

    Write-HostWithTimestamp "📋 Selected $($selectedFindings.Count) findings meeting severity threshold: $SeverityThreshold" -ForegroundColor Green
    return $selectedFindings
}

function New-WorkItemPlanningFile {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [array]$Findings,
        [string]$Project,
        [string]$AreaPath,
        [string]$IterationPath
    )

    Write-HostWithTimestamp "📝 Creating work item planning files" -ForegroundColor Yellow

    # Create planning folder structure
    $planningFolder = ".copilot-tracking/workitems/security-analysis/checkov-k8s-arc-findings"
    $fullPlanningPath = Join-Path -Path (Get-Location) -ChildPath $planningFolder

    if (-not (Test-Path -Path $fullPlanningPath)) {
        New-Item -Path $fullPlanningPath -ItemType Directory -Force | Out-Null
    }

    # Generate work items based on findings
    $workItemCounter = 1
    $workItemsContent = @()
    $analysisContent = @()

    # Create individual work items for each finding
    foreach ($finding in $Findings) {
        $componentType = $finding.component_type
        $severity = Get-FindingSeverity $finding

        # Create a work item for this individual finding
        $workItemId = "WI{0:D3}" -f $workItemCounter
        $workItemTitle = "Fix Security Issue: $($finding.check_name) in $componentType"

        # Build description for individual finding
        $description = @"
## Security Finding - $($finding.check_id)

This issue tracks a security finding identified by Checkov analysis that requires remediation.

**Severity Level**: $severity
**Component Type**: $componentType
**Detection Method**: Automated Checkov Security Scan
**Check ID**: $($finding.check_id)

### Finding Details:
- **Check Name**: $($finding.check_name)
- **Resource**: $($finding.resource)
- **File Path**: $($finding.file_path)
- **Description**: $($finding.description)

### Recommended Actions:
1. Review the specific security finding in detail
2. Assess impact on production environments
3. Implement security remediation for this specific issue
4. Verify fix with follow-up security scan
5. Update security policies if needed

### Acceptance Criteria:
- [ ] Security finding has been reviewed and understood
- [ ] Security remediation has been implemented
- [ ] Follow-up security scan confirms resolution
- [ ] Documentation updated if applicable
"@

        # Add to work items content
        $workItemsContent += @"
## $workItemId - $workItemTitle
Creating new work item to track a security finding in $componentType components identified through Checkov security analysis.

* $workItemId - System.WorkItemType: Issue
* $workItemId - System.Title: $workItemTitle
* $workItemId - Microsoft.VSTS.Common.Priority: $(if ($severity -eq "CRITICAL" -or $severity -eq "HIGH") { "1" } else { "2" })
* $workItemId - Microsoft.VSTS.Scheduling.StoryPoints: $(if ($severity -eq "CRITICAL") { "5" } elseif ($severity -eq "HIGH") { "3" } else { "2" })
* $workItemId - System.Tags: security; build warning

### $workItemId - System.Description
``````markdown
$description
``````

### $workItemId - Microsoft.VSTS.Common.AcceptanceCriteria
``````markdown
- [ ] Security finding has been reviewed and understood
- [ ] Security remediation has been implemented
- [ ] Follow-up security scan confirms resolution
- [ ] Documentation updated if applicable
``````

"@

        # Add to analysis content
        $analysisContent += @"
### $workItemId - $workItemTitle
* **Working Title**: Security Issues in $componentType Components - $severity Severity
* **Working Type**: Issue
* **Key Search Terms**: "security", "checkov", "$componentType", "$severity"
* **Working Description**:
  ``````markdown
  $description
  ``````
* **Working Acceptance Criteria**:
  ``````markdown
  - [ ] Security finding has been reviewed and understood
  - [ ] Security remediation has been implemented
  - [ ] Follow-up security scan confirms resolution
  - [ ] Documentation updated if applicable
  ``````
* **Suggested Work Item Field Values**:
  * Microsoft.VSTS.Common.Priority: $(if ($severity -eq "CRITICAL" -or $severity -eq "HIGH") { "1" } else { "2" })
  * Microsoft.VSTS.Scheduling.StoryPoints: $(if ($severity -eq "CRITICAL") { "5" } elseif ($severity -eq "HIGH") { "3" } else { "2" })
  * System.Tags: security; build warning

#### $workItemId - Related & Discovered Information
* **Security Finding from Checkov Analysis**:
  * Individual security issue identified in $componentType components
  * Severity level: $severity
  * Check ID: $($finding.check_id)
  * Requires remediation for production security posture

"@

        $workItemCounter++
    }

    # Create work-items.md
    $workItemsFile = @"
<!-- markdownlint-disable-file -->
<!-- markdown-table-prettify-ignore-start -->
# Work Items
* **Project**: $Project
$(if ($AreaPath) { "* **Area Path**: $AreaPath" })
$(if ($IterationPath) { "* **Iteration Path**: $IterationPath" })

$($workItemsContent -join "`n`n")
<!-- markdown-table-prettify-ignore-end -->
"@

    # Create artifact-analysis.md (human-readable analysis table format)
    $analysisFile = @"
<!-- markdownlint-disable-file -->
<!-- markdown-table-prettify-ignore-start -->
# Security Analysis Work Item Analysis - Checkov K8s/Arc Findings
* **Artifact(s)**: Checkov security analysis results from K8s and Arc components
* **Project**: $Project
$(if ($AreaPath) { "* **Area Path**: $AreaPath" })
$(if ($IterationPath) { "* **Iteration Path**: $IterationPath" })

## Planned Work Items Summary

| Work Item | Type | Priority | Story Points | Check ID | Severity | Component | File Path |
|-----------|------|----------|--------------|----------|----------|-----------|-----------|
$(
    # Generate table rows for each work item
    $tableRows = @()
    $counter = 1
    foreach ($finding in $Findings) {
        $componentType = $finding.component_type
        $severity = Get-FindingSeverity $finding
        $workItemId = "WI{0:D3}" -f $counter
        $priority = if ($severity -eq "CRITICAL" -or $severity -eq "HIGH") { "1" } else { "2" }
        $storyPoints = if ($severity -eq "CRITICAL") { "5" } elseif ($severity -eq "HIGH") { "3" } else { "2" }
        $filePath = $finding.file_path -replace '\|', '\|'

        $tableRows += "| $workItemId | Issue | $priority | $storyPoints | $($finding.check_id) | $severity | $componentType | $filePath |"
        $counter++
    }
    $tableRows -join "`n"
)

## Work Item Details

$(
    # Generate concise details for each work item
    $detailSections = @()
    $counter = 1
    foreach ($finding in $Findings) {
        $componentType = $finding.component_type
        $severity = Get-FindingSeverity $finding
        $workItemId = "WI{0:D3}" -f $counter
        $workItemTitle = "Fix Security Issue: $($finding.check_name) in $componentType"

        $detailSections += @"
### $workItemId $workItemTitle

**Summary**: Security finding $($finding.check_id) requiring remediation in $componentType components.

**Key Information**:
- **Check**: $($finding.check_name)
- **Severity**: $severity
- **Resource**: $($finding.resource)
- **Component**: $componentType
- **Search Terms**: "security", "checkov", "$componentType", "$severity", "$($finding.check_id)"
"@
        $counter++
    }
    $detailSections -join "`n`n"
)

## Notes
* Security findings generated from automated Checkov scan focusing on K8s and Arc components
* Each work item represents an individual security finding for focused remediation
* Work items prioritized based on security severity levels
* Analysis conducted on $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
<!-- markdown-table-prettify-ignore-end -->
"@    # Create handoff.md
    $handoffItems = @()
    for ($i = 1; $i -lt $workItemCounter; $i++) {
        $wiId = "WI{0:D3}" -f $i
        $handoffItems += "* [ ] (Create) $wiId Issue"
    }

    $handoffFile = @"
<!-- markdownlint-disable-file -->
<!-- markdown-table-prettify-ignore-start -->
# Work Item Handoff
* **Project**: $Project
* **Repository**: edge-ai
$(if ($AreaPath) { "* **Area Path**: $AreaPath" })
$(if ($IterationPath) { "* **Iteration Path**: $IterationPath" })

## Planning Files:
* .copilot-tracking/workitems/security-analysis/checkov-k8s-arc-findings/handoff.md
* .copilot-tracking/workitems/security-analysis/checkov-k8s-arc-findings/work-items.md
* .copilot-tracking/workitems/security-analysis/checkov-k8s-arc-findings/planning-log.md

## Summary
* Total Items: $($workItemCounter - 1)
* Actions: create $($workItemCounter - 1)
* Types: Issue $($workItemCounter - 1)

## Work Items - work-items.md
$($handoffItems -join "`n")
<!-- markdown-table-prettify-ignore-end -->
"@

    # Create planning-log.md (operational state tracking)
    $planningLogFile = @"
<!-- markdownlint-disable-file -->
<!-- markdown-table-prettify-ignore-start -->
# Security Analysis - Work Item Planning Log
* **Project**: $Project
* **Repository**: edge-ai
* **Previous Phase**: N/A
* **Current Phase**: Complete

## Status
$($workItemCounter - 1)/$($workItemCounter - 1) security findings analyzed, 0/0 ado work items searched, $($workItemCounter - 1)/$($workItemCounter - 1) work items planned

**Summary**: Completed automated security analysis and work item planning for Checkov K8s/Arc findings

## Discovered Artifacts & Related Files
* AT001 Checkov security analysis results - Complete - Processing

## Discovered ADO Work Items
* None discovered - automated security analysis does not require ADO work item search

## Work Items
$(
    # Generate work item status for planning log
    $logItems = @()
    $counter = 1
    foreach ($finding in $Findings) {
        $componentType = $finding.component_type
        $severity = Get-FindingSeverity $finding
        $workItemId = "WI{0:D3}" -f $counter

        $logItems += @"
### **$workItemId** - Issue - Complete
* [$workItemId Fix Security Issue](./artifact-analysis.md)
* Working Search Keywords: "security OR checkov OR $componentType OR $severity OR $($finding.check_id)"
* Related ADO Work Items - Similarity: None (new security finding)
* Suggested Action: Create

**Security Finding Details:**
* Component Type: $componentType
* Severity: $severity
* Check ID: $($finding.check_id)
* File Path: $($finding.file_path)
* Resource: $($finding.resource)

**Possible Work Item Field Values:**
* Working **System.Title**: Security Issue - $($finding.check_name) in $componentType Components
* Working **Microsoft.VSTS.Common.Priority**: $(if ($severity -eq "CRITICAL" -or $severity -eq "HIGH") { "1" } else { "2" })
* Working **Microsoft.VSTS.Scheduling.StoryPoints**: $(if ($severity -eq "CRITICAL") { "5" } elseif ($severity -eq "HIGH") { "3" } else { "2" })
* Working **System.Tags**: security; build warning
"@
        $counter++
    }
    $logItems -join "`n`n"
)

## Doc Analysis - artifact-analysis.md
### Checkov Security Analysis Results
$(
    # Generate doc analysis entries
    $docAnalysisItems = @()
    $counter = 1
    foreach ($finding in $Findings) {
        $workItemId = "WI{0:D3}" -f $counter
        $docAnalysisItems += "* $workItemId - [$workItemId - Create - Fix Security Issue](./artifact-analysis.md): New security finding work item created"
        $counter++
    }
    $docAnalysisItems -join "`n"
)

## ADO Work Items
* None searched - automated security analysis workflow
<!-- markdown-table-prettify-ignore-end -->
"@

    # Write files
    $workItemsPath = Join-Path -Path $fullPlanningPath -ChildPath "work-items.md"
    $analysisPath = Join-Path -Path $fullPlanningPath -ChildPath "artifact-analysis.md"
    $handoffPath = Join-Path -Path $fullPlanningPath -ChildPath "handoff.md"
    $planningLogPath = Join-Path -Path $fullPlanningPath -ChildPath "planning-log.md"

    $workItemsFile | Out-File -FilePath $workItemsPath -Encoding UTF8
    $analysisFile | Out-File -FilePath $analysisPath -Encoding UTF8
    $handoffFile | Out-File -FilePath $handoffPath -Encoding UTF8
    $planningLogFile | Out-File -FilePath $planningLogPath -Encoding UTF8

    Write-HostWithTimestamp "✅ Work item planning files created:" -ForegroundColor Green
    Write-Host "   • $workItemsPath" -ForegroundColor Gray
    Write-Host "   • $analysisPath" -ForegroundColor Gray
    Write-Host "   • $handoffPath" -ForegroundColor Gray
    Write-Host "   • $planningLogPath" -ForegroundColor Gray

    return @{
        PlanningFolder = $fullPlanningPath
        WorkItemsFile  = $workItemsPath
        AnalysisFile   = $analysisPath
        HandoffFile    = $handoffPath
        PlanningLogFile = $planningLogPath
        WorkItemCount  = $workItemCounter - 1
    }
}

function Write-SecurityAnalysisReport {
    param(
        [array]$AllFindings,
        [array]$FilteredFindings,
        [array]$SelectedFindings,
        [hashtable]$PlanningFiles,
        [string]$OutputFolder
    )

    $reportPath = Join-Path -Path $OutputFolder -ChildPath "security-analysis-summary.md"

    $report = @"
# Security Analysis Report - K8s and Arc Components

**Analysis Date**: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
**Target Components**: Kubernetes clusters and Azure Arc components
**Analysis Method**: Checkov automated security scanning

## Executive Summary

* **Total Findings**: $($AllFindings.Count)
* **K8s/Arc Findings**: $($FilteredFindings.Count)
* **Planning Files Created**: $(if ($PlanningFiles) { $PlanningFiles.WorkItemCount } else { "0" })
* **Severity Threshold**: $SeverityThreshold

## Findings by Severity

$(
    $FilteredFindings | Group-Object { Get-FindingSeverity $_ } | Sort-Object { $SeverityLevels[$_.Name] } -Descending | ForEach-Object {
        "* **$($_.Name)**: $($_.Count) findings"
    }
)

## Findings by Component

$(
    $FilteredFindings | Group-Object component_type | ForEach-Object {
        "* **$($_.Name)**: $($_.Count) findings"
    }
)

## Work Item Planning

$(if ($PlanningFiles) {
"* **Planning Folder**: $($PlanningFiles.PlanningFolder)
* **Work Items File**: $($PlanningFiles.WorkItemsFile)
* **Analysis File**: $($PlanningFiles.AnalysisFile)
* **Handoff File**: $($PlanningFiles.HandoffFile)"
} else {
"No planning files created (no findings above threshold)"
})

## Next Steps

1. **Review Planning Files**: Examine the generated work item planning files
2. **Create Work Items**: Use Azure DevOps MCP server tools to create work items from planning files
3. **Assign and Prioritize**: Assign created work items to appropriate team members
4. **Track Progress**: Monitor resolution of security findings through Azure DevOps
5. **Follow-up Scan**: Run another security scan after remediation

## Detailed Findings

$(
    $SelectedFindings | ForEach-Object {
        $severity = Get-FindingSeverity $_
        @"
### $($_.check_id) - $severity
* **Component**: $($_.component_type)
* **Resource**: $($_.resource)
* **File**: $($_.file_path)
* **Description**: $($_.description)

"@
    }
)

---
*Generated by Invoke-SecurityAnalysisWithWorkItems.ps1*
"@

    $report | Out-File -FilePath $reportPath -Encoding UTF8
    Write-HostWithTimestamp "📄 Security analysis report saved: $reportPath" -ForegroundColor Green
    return $reportPath
}

# Main execution
try {
    Write-HostWithTimestamp "🚀 Starting Security Analysis with Work Item Planning" -ForegroundColor Green
    Write-Host ""

    # Initialize environment
    Initialize-OutputFolder -Path $OutputFolder
    $targetConfig = Get-TargetComponentsConfig -TargetComponents $TargetComponents

    # Stage 1: Security Scanning
    Write-HostWithTimestamp "🔬 Stage 1: Checkov Security Analysis" -ForegroundColor Magenta
    $checkovResult = Invoke-CheckovAnalysis -TargetConfig $targetConfig -OutputFolder $OutputFolder -ConfigFile $ConfigFile
    Write-HostWithTimestamp "📊 Checkov analysis result: $checkovResult" -ForegroundColor Gray

    # Stage 2: Parse and Filter Findings
    Write-HostWithTimestamp "🔍 Stage 2: Finding Analysis and Filtering" -ForegroundColor Magenta
    $allFindings = Get-CheckovFinding -OutputFolder $OutputFolder
    $k8sArcFindings = Get-KubernetesArcFinding -AllFindings $allFindings

    # Show summary
    Show-FindingsSummary -Findings $k8sArcFindings

    # Stage 3: Severity Evaluation and Selection
    Write-HostWithTimestamp "⚖️ Stage 3: Severity Evaluation and Triage" -ForegroundColor Magenta
    $selectedFindings = Get-FindingForWorkItem -Findings $k8sArcFindings -SeverityThreshold $SeverityThreshold -Interactive $Interactive.IsPresent

    # Ensure we have an array (handle null from cancelled interactive triage)
    if ($null -eq $selectedFindings) {
        $selectedFindings = @()
    }

    # Stage 4: Work Item Planning
    $planningFiles = $null
    if ($selectedFindings.Count -gt 0) {
        Write-HostWithTimestamp "📋 Stage 4: Work Item Planning File Generation" -ForegroundColor Magenta
        $planningFiles = New-WorkItemPlanningFile -Findings $selectedFindings -Project $Project -AreaPath $AreaPath -IterationPath $IterationPath

        Write-HostWithTimestamp "✅ Work item planning files created" -ForegroundColor Green
        Write-Host ""
        Write-HostWithTimestamp "📝 Next Steps:" -ForegroundColor Yellow
        Write-Host "   1. Review planning files in: $($planningFiles.PlanningFolder)" -ForegroundColor Gray
        Write-Host "   2. Use Copilot chat with the handoff.md file to create actual Azure DevOps work items" -ForegroundColor Gray
        Write-Host "   3. Monitor progress through Azure DevOps after work items are created" -ForegroundColor Gray
    }
    else {
        Write-HostWithTimestamp "ℹ️ No findings above severity threshold for planning file creation" -ForegroundColor Cyan
    }

    # Stage 5: Generate Report (only if we have selected findings or planning files)
    $reportPath = $null
    if ($selectedFindings.Count -gt 0 -or $planningFiles) {
        Write-HostWithTimestamp "📊 Stage 5: Report Generation" -ForegroundColor Magenta
        $reportPath = Write-SecurityAnalysisReport -AllFindings $allFindings -FilteredFindings $k8sArcFindings -SelectedFindings $selectedFindings -PlanningFiles $planningFiles -OutputFolder $OutputFolder

        Write-Host ""
        Write-HostWithTimestamp "🎉 Security analysis workflow completed successfully!" -ForegroundColor Green
        Write-HostWithTimestamp "📄 Report available at: $reportPath" -ForegroundColor Cyan

        Write-Host ""
        Write-HostWithTimestamp "🔗 Work Item Planning Files:" -ForegroundColor Yellow
        Write-Host "   • Handoff: $($planningFiles.HandoffFile)" -ForegroundColor Gray
        Write-Host "   • Work Items: $($planningFiles.WorkItemsFile)" -ForegroundColor Gray
        Write-Host "   • Analysis: $($planningFiles.AnalysisFile)" -ForegroundColor Gray
        Write-Host "   • Planning Log: $($planningFiles.PlanningLogFile)" -ForegroundColor Gray
    }
    else {
        Write-Host ""
        Write-HostWithTimestamp "✅ Security analysis completed - no findings to report" -ForegroundColor Green
    }


}
catch {
    Write-Error "❌ Security analysis workflow failed: $_"
    Write-Host "Error details:" -ForegroundColor Red
    Write-Host $_.Exception.Message -ForegroundColor Red
    Write-Host $_.ScriptStackTrace -ForegroundColor Red
    exit 1
}
