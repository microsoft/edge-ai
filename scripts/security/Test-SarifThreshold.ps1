#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.4

<#
.SYNOPSIS
    Fails when SARIF results are not covered by tracked exceptions.

.DESCRIPTION
    Evaluates one or more SARIF 2.1.0 files against a zero-result threshold. Every
    result counts regardless of its level, and inline SARIF suppressions are ignored.

    Results are grouped by tool (runs[].tool.driver.name), rule ID, and the first
    location's repository-relative path. A group is excused only by an exception with
    the same tool, rule, and path whose count equals the group's result count.

    An exception whose tool appears in the analyzed SARIF but matches no result is
    stale and fails the gate. Exceptions for tools absent from the analyzed SARIF are
    ignored, so one exceptions file can serve several scanners.

    Exit codes:
      0  every result is excused and every applicable exception matches
      1  unexcused results, a count mismatch, or a stale exception
      2  missing, unreadable, or run-less SARIF, or a malformed exceptions file

.PARAMETER SarifPath
    One or more SARIF files to evaluate.

.PARAMETER ExceptionsPath
    Tracked exceptions file. Defaults to workflow-scan-exceptions.json beside this script.

.PARAMETER AnnotationLevel
    CI annotation level for unexcused results.

.EXAMPLE
    ./scripts/security/Test-SarifThreshold.ps1 -SarifPath logs/workflow-runner.sarif

.EXAMPLE
    ./scripts/security/Test-SarifThreshold.ps1 -SarifPath a.sarif, b.sarif -AnnotationLevel Warning
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string[]]$SarifPath = @(),

    [Parameter(Mandatory = $false)]
    [string]$ExceptionsPath = (Join-Path $PSScriptRoot 'workflow-scan-exceptions.json'),

    [Parameter(Mandatory = $false)]
    [ValidateSet('Warning', 'Error')]
    [string]$AnnotationLevel = 'Error'
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../ci/Modules/CIHelpers.psm1') -Force

#region Functions

class SarifGateInputException : System.Exception {
    SarifGateInputException([string]$Message) : base($Message) {}
}

$script:ExceptionFields = @('tool', 'rule', 'path', 'count', 'reason', 'issue')
$script:RequiredExceptionFields = @('tool', 'rule', 'path', 'count', 'reason')
$script:UnexceptableRules = @('action-pin/upstream-unavailable')

function ConvertTo-RepoRelativeUri {
    <#
    .SYNOPSIS
        Normalizes a SARIF artifact URI to a forward-slash repository-relative path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [AllowNull()]
        [string]$Uri
    )

    if ([string]::IsNullOrWhiteSpace($Uri)) {
        return '(no location)'
    }
    $normalized = $Uri -replace '\\', '/'
    while ($normalized.StartsWith('./')) {
        $normalized = $normalized.Substring(2)
    }
    return $normalized
}

function Read-SarifResult {
    <#
    .SYNOPSIS
        Reads SARIF files and returns their results and the tools that ran.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$Path
    )

    if ($Path.Count -eq 0) {
        throw [SarifGateInputException]::new('No SARIF files were supplied.')
    }

    $results = [System.Collections.Generic.List[object]]::new()
    $tools = [System.Collections.Generic.HashSet[string]]::new()

    foreach ($file in $Path) {
        if (-not (Test-Path -Path $file -PathType Leaf)) {
            throw [SarifGateInputException]::new("SARIF file not found: $file")
        }

        try {
            $sarif = Get-Content -Path $file -Raw | ConvertFrom-Json -Depth 64
        }
        catch {
            throw [SarifGateInputException]::new("SARIF file is unreadable: $file ($($_.Exception.Message))")
        }

        $runs = @($sarif.runs | Where-Object { $null -ne $_ })
        if ($runs.Count -eq 0) {
            throw [SarifGateInputException]::new("SARIF file has no runs: $file")
        }

        foreach ($run in $runs) {
            $tool = [string]$run.tool.driver.name
            if ([string]::IsNullOrWhiteSpace($tool)) {
                throw [SarifGateInputException]::new("SARIF run has no tool.driver.name: $file")
            }
            [void]$tools.Add($tool)

            foreach ($result in @($run.results | Where-Object { $null -ne $_ })) {
                $rule = [string]$result.ruleId
                if ([string]::IsNullOrWhiteSpace($rule)) { $rule = [string]$result.rule.id }
                if ([string]::IsNullOrWhiteSpace($rule)) { $rule = '(unknown rule)' }

                $location = @($result.locations)[0]
                $physical = $location.physicalLocation
                $line = 0
                if ($null -ne $physical.region.startLine) { $line = [int]$physical.region.startLine }

                $results.Add([pscustomobject]@{
                        Tool    = $tool
                        Rule    = $rule
                        Path    = ConvertTo-RepoRelativeUri -Uri ([string]$physical.artifactLocation.uri)
                        Line    = $line
                        Message = [string]$result.message.text
                    })
            }
        }
    }

    return @{
        Results = @($results)
        Tools   = @($tools)
    }
}

function Read-ScanException {
    <#
    .SYNOPSIS
        Reads and validates the tracked exceptions file.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    if (-not (Test-Path -Path $Path -PathType Leaf)) {
        throw [SarifGateInputException]::new("Exceptions file not found: $Path")
    }

    try {
        $document = Get-Content -Path $Path -Raw | ConvertFrom-Json -Depth 16
    }
    catch {
        throw [SarifGateInputException]::new("Exceptions file is unreadable: $Path ($($_.Exception.Message))")
    }

    if ($null -eq $document -or $document.PSObject.Properties.Name -notcontains 'exceptions') {
        throw [SarifGateInputException]::new("Exceptions file has no 'exceptions' array: $Path")
    }

    $entries = [System.Collections.Generic.List[object]]::new()
    $keys = [System.Collections.Generic.HashSet[string]]::new()
    $index = 0
    foreach ($entry in @($document.exceptions | Where-Object { $null -ne $_ })) {
        $index++
        $where = "exception #$index in $Path"
        $names = @($entry.PSObject.Properties.Name)

        $unknown = @($names | Where-Object { $_ -notin $script:ExceptionFields })
        if ($unknown.Count -gt 0) {
            throw [SarifGateInputException]::new("Unknown field(s) $($unknown -join ', ') in $where")
        }
        foreach ($field in $script:RequiredExceptionFields) {
            if ($names -notcontains $field) {
                throw [SarifGateInputException]::new("Missing field '$field' in $where")
            }
        }
        foreach ($field in @('tool', 'rule', 'path', 'reason')) {
            if ($entry.$field -isnot [string] -or [string]::IsNullOrWhiteSpace($entry.$field)) {
                throw [SarifGateInputException]::new("Field '$field' must be a non-empty string in $where")
            }
        }
        if ($names -contains 'issue' -and ($entry.issue -isnot [string] -or [string]::IsNullOrWhiteSpace($entry.issue))) {
            throw [SarifGateInputException]::new("Field 'issue' must be a non-empty string when present in $where")
        }
        if (($entry.count -isnot [long] -and $entry.count -isnot [int]) -or [long]$entry.count -lt 1) {
            throw [SarifGateInputException]::new("Field 'count' must be a positive integer in $where")
        }
        if ($entry.rule -in $script:UnexceptableRules) {
            throw [SarifGateInputException]::new("Rule '$($entry.rule)' cannot be excepted ($where)")
        }

        $normalizedPath = ConvertTo-RepoRelativeUri -Uri $entry.path
        $key = "$($entry.tool)|$($entry.rule)|$normalizedPath"
        if (-not $keys.Add($key)) {
            throw [SarifGateInputException]::new("Duplicate exception for $($entry.tool) $($entry.rule) $normalizedPath")
        }

        $entries.Add([pscustomobject]@{
                Tool   = $entry.tool
                Rule   = $entry.rule
                Path   = $normalizedPath
                Count  = [int]$entry.count
                Reason = $entry.reason
                Key    = $key
            })
    }

    return @($entries)
}

function Test-SarifThreshold {
    <#
    .SYNOPSIS
        Matches result groups to exceptions and returns the gate evaluation.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Results,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$AnalyzedTools,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [object[]]$Exceptions
    )

    $exceptionsByKey = @{}
    foreach ($exception in $Exceptions) { $exceptionsByKey[$exception.Key] = $exception }

    $unexcused = [System.Collections.Generic.List[object]]::new()
    $excused = [System.Collections.Generic.List[object]]::new()
    $mismatched = [System.Collections.Generic.List[object]]::new()
    $matchedKeys = [System.Collections.Generic.HashSet[string]]::new()

    $groups = $Results | Group-Object -Property { "$($_.Tool)|$($_.Rule)|$($_.Path)" }
    foreach ($group in $groups) {
        $first = $group.Group[0]
        $summary = [pscustomobject]@{
            Tool    = $first.Tool
            Rule    = $first.Rule
            Path    = $first.Path
            Count   = $group.Count
            Results = @($group.Group)
        }

        $exception = $exceptionsByKey[$group.Name]
        if ($null -eq $exception) {
            $unexcused.Add($summary)
            continue
        }

        [void]$matchedKeys.Add($group.Name)
        if ($exception.Count -eq $group.Count) {
            $excused.Add([pscustomobject]@{ Group = $summary; Reason = $exception.Reason })
        }
        else {
            $mismatched.Add([pscustomobject]@{ Group = $summary; Expected = $exception.Count })
            $unexcused.Add($summary)
        }
    }

    $stale = @($Exceptions | Where-Object { $_.Tool -in $AnalyzedTools -and -not $matchedKeys.Contains($_.Key) })

    return [pscustomobject]@{
        Unexcused  = @($unexcused)
        Excused    = @($excused)
        Mismatched = @($mismatched)
        Stale      = $stale
        Passed     = ($unexcused.Count -eq 0 -and $stale.Count -eq 0)
    }
}

function Write-GateReport {
    <#
    .SYNOPSIS
        Writes the console summary, CI annotations, and step summary for an evaluation.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Evaluation,

        [Parameter(Mandatory = $true)]
        [string]$AnnotationLevel
    )

    $summary = [System.Collections.Generic.List[string]]::new()
    $summary.Add('## SARIF Threshold Gate')
    $summary.Add('')

    foreach ($group in $Evaluation.Unexcused) {
        Write-Host "FAIL $($group.Tool) $($group.Rule) $($group.Path): $($group.Count) unexcused result(s)"
        foreach ($result in $group.Results) {
            Write-CIAnnotation -Level $AnnotationLevel -Message "[$($result.Rule)] $($result.Message)" -File $result.Path -Line $result.Line
        }
    }
    foreach ($item in $Evaluation.Mismatched) {
        Write-Host "FAIL exception count mismatch for $($item.Group.Tool) $($item.Group.Rule) $($item.Group.Path): expected $($item.Expected), found $($item.Group.Count)"
    }
    foreach ($exception in $Evaluation.Stale) {
        Write-Host "FAIL stale exception for $($exception.Tool) $($exception.Rule) $($exception.Path): no matching results"
        Write-CIAnnotation -Level $AnnotationLevel -Message "Stale exception for $($exception.Tool) $($exception.Rule) $($exception.Path); remove it from the exceptions file."
    }
    foreach ($item in $Evaluation.Excused) {
        Write-Host "EXCUSED $($item.Group.Tool) $($item.Group.Rule) $($item.Group.Path): $($item.Group.Count) result(s). Reason: $($item.Reason)"
    }

    $unexcusedCount = ($Evaluation.Unexcused | Measure-Object -Property Count -Sum).Sum
    $summary.Add("| Unexcused results | Excused groups | Stale exceptions | Count mismatches |")
    $summary.Add("|---|---|---|---|")
    $summary.Add("| $([int]$unexcusedCount) | $($Evaluation.Excused.Count) | $($Evaluation.Stale.Count) | $($Evaluation.Mismatched.Count) |")

    if ($Evaluation.Excused.Count -gt 0) {
        $summary.Add('')
        $summary.Add('### Excused by tracked exceptions')
        $summary.Add('')
        foreach ($item in $Evaluation.Excused) {
            $summary.Add("* $($item.Group.Tool) ``$($item.Group.Rule)`` in ``$($item.Group.Path)`` ($($item.Group.Count)): $($item.Reason)")
        }
    }

    Write-CIStepSummary -Content ($summary -join "`n")

    if ($Evaluation.Passed) {
        Write-Host "PASS: no unexcused SARIF results"
    }
}

#endregion Functions

#region Main Execution

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $read = Read-SarifResult -Path $SarifPath
        $exceptions = Read-ScanException -Path $ExceptionsPath
        $evaluation = Test-SarifThreshold -Results @($read.Results) -AnalyzedTools @($read.Tools) -Exceptions @($exceptions)
        Write-GateReport -Evaluation $evaluation -AnnotationLevel $AnnotationLevel
        if ($evaluation.Passed) { exit 0 }
        exit 1
    }
    catch [SarifGateInputException] {
        Write-CIAnnotation -Level 'Error' -Message "SARIF threshold gate input error: $($_.Exception.Message)"
        Write-Error -ErrorAction Continue "Test-SarifThreshold input error: $($_.Exception.Message)"
        exit 2
    }
    catch {
        Write-Error -ErrorAction Continue "Test-SarifThreshold failed: $($_.Exception.Message)"
        exit 2
    }
}

#endregion Main Execution
