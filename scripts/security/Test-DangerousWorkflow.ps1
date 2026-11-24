#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.4

<#
.SYNOPSIS
    Reports expressions that insert caller- or attacker-controlled text into workflow scripts.

.DESCRIPTION
    Scans every workflow under .github/workflows for ${{ }} expressions inside step
    run: and with.script: values. An expression is reported when it references:

      * a workflow_call or workflow_dispatch input (inputs.<name> or
        github.event.inputs.<name>) whose declared type is not boolean, an undeclared
        input, or the whole inputs object
      * an attacker-controllable event property, such as a pull request title or
        body, an issue or comment body, a commit message or author, or a head ref

    Such expressions are expanded into the script text before the shell runs it, so
    their values can change the script. Pass them through a step-level env: entry and
    read the quoted variable instead. Values passed through env: are not reported.

    Exit codes: 0 no findings, 1 findings (SARIF written), 2 execution error.

.PARAMETER RepoRoot
    Repository root. Defaults to the git top-level directory.

.PARAMETER OutputPath
    SARIF output path.

.EXAMPLE
    ./scripts/security/Test-DangerousWorkflow.ps1

.EXAMPLE
    ./scripts/security/Test-DangerousWorkflow.ps1 -OutputPath logs/dangerous-workflow.sarif
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoRoot = '',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'logs/dangerous-workflow.sarif'
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Modules/WorkflowScanHelpers.psm1') -Force

#region Functions

$script:ToolName = 'Test-DangerousWorkflow'
$script:HelpUri = 'https://docs.github.com/en/actions/reference/security/secure-use#use-an-intermediate-environment-variable'
$script:Rules = @(
    New-SarifRule -Id 'dangerous-workflow/input-interpolation' `
        -ShortDescription 'Non-boolean workflow input interpolated into a script' `
        -FullDescription 'A workflow_call or workflow_dispatch input that is not declared as boolean is expanded into a run or script value. Pass it through a step-level env entry and read the quoted variable.' `
        -HelpUri $script:HelpUri
    New-SarifRule -Id 'dangerous-workflow/untrusted-event-interpolation' `
        -ShortDescription 'Attacker-controllable event value interpolated into a script' `
        -FullDescription 'An event property that an external contributor can set, such as a pull request title or a commit message, is expanded into a run or script value. Pass it through a step-level env entry and read the quoted variable.' `
        -HelpUri $script:HelpUri
)

# Untrusted context values listed in GitHub's script injection guidance.
$script:UntrustedEventPatterns = @(
    'github\.event\.(issue|pull_request|discussion)\.(title|body)'
    'github\.event\.(comment|review|review_comment)\.body'
    'github\.event\.pages(\[[^\]]*\]|\.\*)?\.page_name'
    'github\.event\.(commits(\[[^\]]*\]|\.\*)?|head_commit|workflow_run\.head_commit)\.(message|author\.(email|name))'
    'github\.event\.pull_request\.head\.(ref|label|repo\.default_branch)'
    'github\.event\.workflow_run\.(head_branch|display_title|pull_requests(\[[^\]]*\]|\.\*)?\.head\.ref)'
    'github\.head_ref'
)

$script:NamedInputPattern = '(?<![\w.-])inputs\.([A-Za-z0-9_-]+)|github\.event\.inputs\.([A-Za-z0-9_-]+)'
$script:WholeInputPattern = '(?<![\w.-])inputs(?![\w.-])|github\.event\.inputs(?![\w.-])'
$script:BlockIndicatorPattern = '^[|>][0-9+-]*\s*(#.*)?$'

function Get-WorkflowInputType {
    <#
    .SYNOPSIS
        Returns declared workflow_call and workflow_dispatch input types by name.
    .DESCRIPTION
        A name declared on both triggers keeps a non-boolean type when either declaration is not boolean.
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Document
    )

    $types = @{}
    $trigger = Get-WorkflowTrigger -Document $Document
    if ($trigger -isnot [System.Collections.IDictionary]) {
        return $types
    }

    foreach ($triggerName in 'workflow_call', 'workflow_dispatch') {
        $definition = $trigger[$triggerName]
        if ($definition -isnot [System.Collections.IDictionary]) { continue }
        $inputs = $definition['inputs']
        if ($inputs -isnot [System.Collections.IDictionary]) { continue }

        foreach ($name in $inputs.Keys) {
            $declared = $inputs[$name]
            $type = if ($declared -is [System.Collections.IDictionary] -and $declared['type']) { [string]$declared['type'] } else { 'string' }
            if (-not $types.ContainsKey($name) -or $type -ne 'boolean') {
                $types[$name] = $type
            }
        }
    }
    return $types
}

function Get-StepScriptBlock {
    <#
    .SYNOPSIS
        Returns the source lines of every run and script value in a workflow's jobs.
    .DESCRIPTION
        Bodies of other block scalars are skipped, so text that merely looks like a
        run key inside another multi-line value is not treated as a script.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $blocks = [System.Collections.Generic.List[object]]::new()
    $ranges = Get-WorkflowJobRange -Lines $Lines
    foreach ($range in $ranges.Values) {
        $i = $range.StartIndex + 1
        while ($i -le $range.EndIndex) {
            $line = $Lines[$i]
            if (-not ($line -match '^(?<indent>\s*)(?<dash>-\s+)?(?<key>[A-Za-z0-9_.-]+)\s*:\s*(?<value>.*)$')) {
                $i++
                continue
            }

            $keyIndent = $Matches.indent.Length + $Matches.dash.Length
            $key = $Matches.key
            $value = $Matches.value

            if ($value -match $script:BlockIndicatorPattern) {
                $body = [System.Collections.Generic.List[object]]::new()
                $j = $i + 1
                while ($j -le $range.EndIndex) {
                    $candidate = $Lines[$j]
                    if ($candidate.Trim().Length -gt 0 -and (Get-IndentWidth -Line $candidate) -le $keyIndent) { break }
                    $body.Add([pscustomobject]@{ Number = $j + 1; Text = $candidate })
                    $j++
                }
                if ($key -in 'run', 'script') {
                    $blocks.Add([pscustomobject]@{ Kind = $key; Lines = @($body) })
                }
                $i = $j
                continue
            }

            if ($key -in 'run', 'script' -and $value.Trim().Length -gt 0) {
                $blocks.Add([pscustomobject]@{ Kind = $key; Lines = @([pscustomobject]@{ Number = $i + 1; Text = $value }) })
            }
            $i++
        }
    }
    return @($blocks)
}

function Get-ExpressionFinding {
    <#
    .SYNOPSIS
        Classifies one expression and returns zero, one, or two findings.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)][string]$Expression,
        [Parameter(Mandatory = $true)][hashtable]$InputTypes,
        [Parameter(Mandatory = $true)][string]$Kind,
        [Parameter(Mandatory = $true)][string]$RelativePath,
        [Parameter(Mandatory = $true)][int]$Line
    )

    $findings = [System.Collections.Generic.List[object]]::new()
    $display = '${{' + $Expression + '}}'

    $unsafeInputs = [System.Collections.Generic.List[string]]::new()
    foreach ($match in [regex]::Matches($Expression, $script:NamedInputPattern)) {
        $name = if ($match.Groups[1].Success) { $match.Groups[1].Value } else { $match.Groups[2].Value }
        if (-not $InputTypes.ContainsKey($name) -or $InputTypes[$name] -ne 'boolean') {
            if (-not $unsafeInputs.Contains($name)) { $unsafeInputs.Add($name) }
        }
    }
    if ([regex]::IsMatch($Expression, $script:WholeInputPattern)) {
        $unsafeInputs.Add('(all inputs)')
    }
    if ($unsafeInputs.Count -gt 0) {
        $findings.Add((New-SarifFinding -RuleId 'dangerous-workflow/input-interpolation' -Path $RelativePath -Line $Line `
                    -Message "$display in a $Kind value interpolates non-boolean input(s) $($unsafeInputs -join ', '); pass the value through a step-level env entry."))
    }

    foreach ($pattern in $script:UntrustedEventPatterns) {
        $match = [regex]::Match($Expression, $pattern)
        if ($match.Success) {
            $findings.Add((New-SarifFinding -RuleId 'dangerous-workflow/untrusted-event-interpolation' -Path $RelativePath -Line $Line `
                        -Message "$display in a $Kind value interpolates attacker-controllable $($match.Value); pass the value through a step-level env entry."))
            break
        }
    }

    return @($findings)
}

function Get-DangerousWorkflowFinding {
    <#
    .SYNOPSIS
        Returns injection findings for one workflow file.
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
    $inputTypes = Get-WorkflowInputType -Document $parsed.Document
    $findings = [System.Collections.Generic.List[object]]::new()

    foreach ($block in Get-StepScriptBlock -Lines $parsed.Lines) {
        $text = ($block.Lines | ForEach-Object Text) -join "`n"
        $offsets = [System.Collections.Generic.List[int]]::new()
        $position = 0
        foreach ($entry in $block.Lines) {
            $offsets.Add($position)
            $position += $entry.Text.Length + 1
        }

        foreach ($match in [regex]::Matches($text, '\$\{\{(.*?)\}\}', [System.Text.RegularExpressions.RegexOptions]::Singleline)) {
            $lineIndex = 0
            for ($k = 0; $k -lt $offsets.Count; $k++) {
                if ($offsets[$k] -le $match.Index) { $lineIndex = $k } else { break }
            }
            $line = $block.Lines[$lineIndex].Number
            foreach ($finding in Get-ExpressionFinding -Expression $match.Groups[1].Value -InputTypes $inputTypes -Kind $block.Kind -RelativePath $RelativePath -Line $line) {
                $findings.Add($finding)
            }
        }
    }

    return @($findings)
}

function Invoke-DangerousWorkflowScan {
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
        foreach ($finding in Get-DangerousWorkflowFinding -Path $file.FullName -RelativePath $relative) {
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
        $findings = @(Invoke-DangerousWorkflowScan -RepoRoot $root -OutputPath $OutputPath)
        if ($findings.Count -gt 0) { exit 1 }
        exit 0
    }
    catch {
        Write-Error -ErrorAction Continue "Test-DangerousWorkflow failed: $($_.Exception.Message)"
        exit 2
    }
}

#endregion Main Execution
