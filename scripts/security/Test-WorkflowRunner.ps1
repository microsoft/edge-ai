#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.4

<#
.SYNOPSIS
    Reports GitHub Actions jobs that do not run on a dated GitHub-hosted Ubuntu label.

.DESCRIPTION
    Parses every workflow under .github/workflows and checks each job's runs-on value.
    Only exact dated labels such as ubuntu-24.04 and ubuntu-24.04-arm are allowed, so
    runner image upgrades arrive as reviewed changes. Floating labels (ubuntu-latest),
    other operating systems, self-hosted or list or group forms, expressions, and a
    missing runs-on are reported. Jobs that call a reusable workflow are not evaluated.

    Exit codes: 0 no findings, 1 findings (SARIF written), 2 execution error.

.PARAMETER RepoRoot
    Repository root. Defaults to the git top-level directory.

.PARAMETER OutputPath
    SARIF output path.

.EXAMPLE
    ./scripts/security/Test-WorkflowRunner.ps1

.EXAMPLE
    ./scripts/security/Test-WorkflowRunner.ps1 -OutputPath logs/workflow-runner.sarif
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoRoot = '',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'logs/workflow-runner.sarif'
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Modules/WorkflowScanHelpers.psm1') -Force

#region Functions

$script:ToolName = 'Test-WorkflowRunner'
$script:DatedRunnerPattern = '^ubuntu-\d{2}\.\d{2}(-arm)?$'
$script:Rules = @(
    New-SarifRule -Id 'workflow-runner/undated-label' `
        -ShortDescription 'Job does not run on a dated GitHub-hosted Ubuntu label' `
        -FullDescription 'Every job must set runs-on to a dated GitHub-hosted Ubuntu label such as ubuntu-24.04 or ubuntu-24.04-arm, so runner image upgrades are reviewed changes rather than silent migrations.' `
        -HelpUri 'https://github.com/actions/runner-images#available-images'
)

function Get-WorkflowRunnerFinding {
    <#
    .SYNOPSIS
        Returns runner findings for one workflow file.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $parsed = Read-WorkflowDocument -Path $Path
    $jobs = $parsed.Document['jobs']
    if ($jobs -isnot [System.Collections.IDictionary]) {
        return @()
    }

    $ranges = Get-WorkflowJobRange -Lines $parsed.Lines
    $findings = [System.Collections.Generic.List[object]]::new()

    foreach ($jobId in $jobs.Keys) {
        $job = $jobs[$jobId]
        if ($job -is [System.Collections.IDictionary] -and $job.Contains('uses')) {
            continue
        }

        $runsOn = if ($job -is [System.Collections.IDictionary]) { $job['runs-on'] } else { $null }
        if ($runsOn -is [string] -and $runsOn -match $script:DatedRunnerPattern) {
            continue
        }

        $line = 1
        if ($ranges.ContainsKey([string]$jobId)) {
            $line = Find-JobPropertyLine -Lines $parsed.Lines -Range $ranges[[string]$jobId] -Property 'runs-on'
        }

        $described = if ($null -eq $runsOn) {
            'has no runs-on'
        }
        elseif ($runsOn -is [string]) {
            "runs on '$runsOn'"
        }
        else {
            'uses a list or group runs-on value'
        }

        $findings.Add((New-SarifFinding -RuleId 'workflow-runner/undated-label' -Path $RelativePath -Line $line `
                    -Message "Job '$jobId' $described; use a dated GitHub-hosted Ubuntu label such as ubuntu-24.04."))
    }

    return @($findings)
}

function Invoke-WorkflowRunnerScan {
    <#
    .SYNOPSIS
        Scans every workflow, writes SARIF, and returns the findings.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath
    )

    $files = Get-WorkflowScanFile -RepoRoot $RepoRoot
    $findings = [System.Collections.Generic.List[object]]::new()
    foreach ($file in $files) {
        $relative = Get-RepoRelativePath -RepoRoot $RepoRoot -Path $file.FullName
        foreach ($finding in Get-WorkflowRunnerFinding -Path $file.FullName -RelativePath $relative) {
            $findings.Add($finding)
        }
    }

    Write-ScanSarif -ToolName $script:ToolName -InformationUri 'https://github.com/microsoft/edge-ai/blob/main/docs/build-cicd/security-scanning.md' `
        -Rules $script:Rules -Findings @($findings) -OutputPath $OutputPath
    Write-ScanSummary -ToolName $script:ToolName -FileCount $files.Count -Findings @($findings)
    return @($findings)
}

#endregion Functions

#region Main Execution

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $root = Get-WorkflowScanRoot -RepoRoot $RepoRoot
        $findings = @(Invoke-WorkflowRunnerScan -RepoRoot $root -OutputPath $OutputPath)
        if ($findings.Count -gt 0) { exit 1 }
        exit 0
    }
    catch {
        Write-Error -ErrorAction Continue "Test-WorkflowRunner failed: $($_.Exception.Message)"
        exit 2
    }
}

#endregion Main Execution
