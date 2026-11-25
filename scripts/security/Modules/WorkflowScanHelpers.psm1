# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

# WorkflowScanHelpers.psm1
# Purpose: Shared file discovery, YAML loading, source-line lookup, and SARIF output for the workflow security scanners.

#Requires -Version 7.4

function Get-WorkflowScanRoot {
    <#
    .SYNOPSIS
        Returns the repository root used to resolve workflow paths.
    .PARAMETER RepoRoot
        Explicit root; when empty, the git top-level directory or the current directory.
    .OUTPUTS
        [string] Absolute repository root.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$RepoRoot
    )

    if ([string]::IsNullOrWhiteSpace($RepoRoot)) {
        $RepoRoot = git rev-parse --show-toplevel 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($RepoRoot)) {
            $RepoRoot = (Get-Location).Path
        }
    }
    return (Resolve-Path -Path $RepoRoot -ErrorAction Stop).ProviderPath
}

function Get-WorkflowScanFile {
    <#
    .SYNOPSIS
        Lists workflow files, and optionally composite action files, under a repository root.
    .PARAMETER RepoRoot
        Absolute repository root.
    .PARAMETER IncludeActions
        Also return .github/actions/**/action.yml and action.yaml files.
    .OUTPUTS
        [System.IO.FileInfo[]] Files sorted by path.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $false)]
        [switch]$IncludeActions
    )

    $files = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $workflowDir = Join-Path $RepoRoot '.github/workflows'
    if (Test-Path -Path $workflowDir -PathType Container) {
        Get-ChildItem -Path $workflowDir -File |
            Where-Object { $_.Extension -in '.yml', '.yaml' } |
            ForEach-Object { $files.Add($_) }
    }

    $actionDir = Join-Path $RepoRoot '.github/actions'
    if ($IncludeActions -and (Test-Path -Path $actionDir -PathType Container)) {
        Get-ChildItem -Path $actionDir -File -Recurse |
            Where-Object { $_.Name -in 'action.yml', 'action.yaml' } |
            ForEach-Object { $files.Add($_) }
    }

    return @($files | Sort-Object FullName)
}

function Get-RepoRelativePath {
    <#
    .SYNOPSIS
        Converts an absolute path to a forward-slash path relative to the repository root.
    .OUTPUTS
        [string] Repository-relative path.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    return ([System.IO.Path]::GetRelativePath($RepoRoot, $Path)) -replace '\\', '/'
}

function Import-WorkflowYamlModule {
    <#
    .SYNOPSIS
        Imports powershell-yaml, failing with a clear message when it is not installed.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param()

    if (-not (Get-Command -Name ConvertFrom-Yaml -ErrorAction SilentlyContinue)) {
        try {
            Import-Module -Name powershell-yaml -ErrorAction Stop
        }
        catch {
            throw "The powershell-yaml module is required. Install it with ./scripts/security/Install-PSModules.ps1. ($($_.Exception.Message))"
        }
    }
}

function Read-WorkflowDocument {
    <#
    .SYNOPSIS
        Parses a workflow file into its YAML document and its source lines.
    .OUTPUTS
        [pscustomobject] Document (hashtable) and Lines (string[]).
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    Import-WorkflowYamlModule
    $raw = Get-Content -Path $Path -Raw
    try {
        $document = ConvertFrom-Yaml -Yaml $raw
    }
    catch {
        throw "Cannot parse YAML in ${Path}: $($_.Exception.Message)"
    }
    if ($document -isnot [System.Collections.IDictionary]) {
        throw "Workflow is not a YAML mapping: $Path"
    }

    return [pscustomobject]@{
        Document = $document
        Lines    = @($raw -split "`r?`n")
    }
}

function Get-WorkflowTrigger {
    <#
    .SYNOPSIS
        Returns the workflow trigger map, accepting an 'on' key that a YAML 1.1 loader read as boolean true.
    .OUTPUTS
        [object] The trigger value, or $null.
    #>
    [CmdletBinding()]
    [OutputType([object])]
    param(
        [Parameter(Mandatory = $true)]
        [System.Collections.IDictionary]$Document
    )

    foreach ($key in @($Document.Keys)) {
        if (($key -is [string] -and $key -eq 'on') -or ($key -is [bool] -and $key)) {
            return $Document[$key]
        }
    }
    return $null
}

function Get-IndentWidth {
    <#
    .SYNOPSIS
        Returns the count of leading spaces in a line.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Line
    )

    return $Line.Length - $Line.TrimStart(' ').Length
}

function Test-ContentLine {
    <#
    .SYNOPSIS
        Returns whether a line holds YAML content rather than whitespace or a comment.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Line
    )

    $trimmed = $Line.Trim()
    return ($trimmed.Length -gt 0 -and -not $trimmed.StartsWith('#'))
}

function Get-WorkflowJobRange {
    <#
    .SYNOPSIS
        Locates each job's key line and line range in a workflow's source text.
    .OUTPUTS
        [hashtable] Job ID to an object with KeyLine, StartIndex, and EndIndex (0-based, inclusive).
    #>
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines
    )

    $ranges = @{}
    $jobsIndex = -1
    for ($i = 0; $i -lt $Lines.Count; $i++) {
        if ($Lines[$i] -match '^jobs:\s*(#.*)?$') { $jobsIndex = $i; break }
    }
    if ($jobsIndex -lt 0) { return $ranges }

    $jobIndent = -1
    $current = $null
    for ($i = $jobsIndex + 1; $i -lt $Lines.Count; $i++) {
        $line = $Lines[$i]
        if (-not (Test-ContentLine -Line $line)) { continue }
        $indent = Get-IndentWidth -Line $line
        if ($indent -eq 0) { break }
        if ($jobIndent -lt 0) { $jobIndent = $indent }

        if ($indent -eq $jobIndent -and $line -match '^\s*(?:"([^"]+)"|''([^'']+)''|([A-Za-z0-9_-]+))\s*:\s*(#.*)?$') {
            if ($null -ne $current) { $current.EndIndex = $i - 1 }
            $id = @($Matches[1], $Matches[2], $Matches[3]) | Where-Object { $_ } | Select-Object -First 1
            $current = [pscustomobject]@{ KeyLine = $i + 1; StartIndex = $i; EndIndex = $Lines.Count - 1; Indent = $indent }
            $ranges[$id] = $current
        }
        elseif ($indent -lt $jobIndent) {
            break
        }
    }

    if ($null -ne $current -and $i -lt $Lines.Count) {
        $current.EndIndex = $i - 1
    }
    return $ranges
}

function Find-JobPropertyLine {
    <#
    .SYNOPSIS
        Returns the 1-based line of a job-level property, or the job key line when absent.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string[]]$Lines,

        [Parameter(Mandatory = $true)]
        [pscustomobject]$Range,

        [Parameter(Mandatory = $true)]
        [string]$Property
    )

    $pattern = '^\s+' + [regex]::Escape($Property) + '\s*:'
    for ($i = $Range.StartIndex + 1; $i -le $Range.EndIndex; $i++) {
        $line = $Lines[$i]
        if ((Test-ContentLine -Line $line) -and (Get-IndentWidth -Line $line) -gt $Range.Indent -and $line -match $pattern) {
            return $i + 1
        }
    }
    return $Range.KeyLine
}

function New-SarifRule {
    <#
    .SYNOPSIS
        Builds a SARIF reportingDescriptor.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Builds an in-memory object and changes no state.')]
    [CmdletBinding()]
    [OutputType([System.Collections.Specialized.OrderedDictionary])]
    param(
        [Parameter(Mandatory = $true)][string]$Id,
        [Parameter(Mandatory = $true)][string]$ShortDescription,
        [Parameter(Mandatory = $true)][string]$FullDescription,
        [Parameter(Mandatory = $true)][string]$HelpUri,
        [Parameter(Mandatory = $false)][ValidateSet('error', 'warning', 'note')][string]$Level = 'error'
    )

    return [ordered]@{
        id                   = $Id
        name                 = ($Id -split '/')[-1]
        shortDescription     = @{ text = $ShortDescription }
        fullDescription      = @{ text = $FullDescription }
        helpUri              = $HelpUri
        defaultConfiguration = @{ level = $Level }
    }
}

function New-SarifFinding {
    <#
    .SYNOPSIS
        Builds a scanner finding with a repository-relative location.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification = 'Builds an in-memory object and changes no state.')]
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)][string]$RuleId,
        [Parameter(Mandatory = $true)][string]$Message,
        [Parameter(Mandatory = $true)][string]$Path,
        [Parameter(Mandatory = $true)][int]$Line
    )

    return [pscustomobject]@{
        RuleId  = $RuleId
        Message = $Message
        Path    = $Path
        Line    = [Math]::Max(1, $Line)
    }
}

function Write-ScanSarif {
    <#
    .SYNOPSIS
        Writes findings as a SARIF 2.1.0 log with one run.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)][string]$ToolName,
        [Parameter(Mandatory = $true)][string]$InformationUri,
        [Parameter(Mandatory = $true)][object[]]$Rules,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Findings,
        [Parameter(Mandatory = $true)][string]$OutputPath
    )

    $ruleIndex = @{}
    for ($i = 0; $i -lt $Rules.Count; $i++) { $ruleIndex[$Rules[$i].id] = $i }

    $results = foreach ($finding in $Findings) {
        $rule = $Rules[$ruleIndex[$finding.RuleId]]
        [ordered]@{
            ruleId    = $finding.RuleId
            ruleIndex = $ruleIndex[$finding.RuleId]
            level     = $rule.defaultConfiguration.level
            message   = @{ text = $finding.Message }
            locations = @(
                @{
                    physicalLocation = @{
                        artifactLocation = @{ uri = $finding.Path; uriBaseId = '%SRCROOT%' }
                        region           = @{ startLine = $finding.Line }
                    }
                }
            )
        }
    }

    $sarif = [ordered]@{
        '$schema' = 'https://json.schemastore.org/sarif-2.1.0.json'
        version   = '2.1.0'
        runs      = @(
            [ordered]@{
                tool    = @{ driver = [ordered]@{ name = $ToolName; informationUri = $InformationUri; rules = @($Rules) } }
                results = @($results)
            }
        )
    }

    $directory = [System.IO.Path]::GetDirectoryName([System.IO.Path]::GetFullPath($OutputPath))
    if (-not (Test-Path -Path $directory)) {
        New-Item -ItemType Directory -Path $directory -Force | Out-Null
    }
    $sarif | ConvertTo-Json -Depth 20 | Set-Content -Path $OutputPath -Encoding utf8
}

function Write-ScanSummary {
    <#
    .SYNOPSIS
        Prints findings to the console grouped by file.
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory = $true)][string]$ToolName,
        [Parameter(Mandatory = $true)][int]$FileCount,
        [Parameter(Mandatory = $true)][AllowEmptyCollection()][object[]]$Findings
    )

    if ($Findings.Count -eq 0) {
        Write-Host "${ToolName}: no findings in $FileCount file(s)"
        return
    }

    Write-Host "${ToolName}: $($Findings.Count) finding(s) in $FileCount file(s)"
    foreach ($finding in ($Findings | Sort-Object Path, Line)) {
        Write-Host "  $($finding.Path):$($finding.Line) [$($finding.RuleId)] $($finding.Message)"
    }
}

Export-ModuleMember -Function @(
    'Find-JobPropertyLine',
    'Get-IndentWidth',
    'Get-RepoRelativePath',
    'Get-WorkflowJobRange',
    'Get-WorkflowScanFile',
    'Get-WorkflowScanRoot',
    'Get-WorkflowTrigger',
    'Import-WorkflowYamlModule',
    'New-SarifFinding',
    'New-SarifRule',
    'Read-WorkflowDocument',
    'Test-ContentLine',
    'Write-ScanSarif',
    'Write-ScanSummary'
)
