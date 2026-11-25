#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.4

<#
.SYNOPSIS
    Reports pinned actions whose version comment does not name the release at the pinned commit.

.DESCRIPTION
    Scans uses: references in .github/workflows and .github/actions/**/action.yml. A remote
    reference passes only when it is pinned to a 40-character commit SHA and its comment
    is exactly one release tag (vX.Y.Z) that, in the publisher's own repository, points
    at that commit. Because tags are read from the publisher's refs, a commit that exists
    only in a fork can never pass.

    Each failing reference reports one result, using the first rule that applies:

      action-pin/not-sha-pinned         the ref is not a 40-character SHA
      action-pin/upstream-unavailable   the publisher's tags could not be read after retries
      action-pin/tag-object             the SHA is an annotated tag object, not a commit
      action-pin/untagged-commit        no tag in the publisher repository points at the commit
      action-pin/comment-missing        the reference has no version comment
      action-pin/comment-not-release    the comment is not vX.Y.Z, such as v1, v1.2, or 1.2.3
      action-pin/comment-mismatch       the named tag is absent or points at another commit

    Tags come from one git ls-remote call per repository, so no token or API quota is used.
    Local (./) and docker:// references are skipped.

    Exit codes: 0 no findings, 1 findings (SARIF written), 2 execution error.

.PARAMETER RepoRoot
    Repository root. Defaults to the git top-level directory.

.PARAMETER OutputPath
    SARIF output path.

.PARAMETER MaxAttempts
    Maximum git ls-remote attempts per repository.

.PARAMETER RetryDelaySeconds
    Delay before the second attempt; each later delay doubles.

.EXAMPLE
    ./scripts/security/Test-ActionPinProvenance.ps1

.EXAMPLE
    ./scripts/security/Test-ActionPinProvenance.ps1 -OutputPath logs/action-pin-provenance.sarif
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoRoot = '',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'logs/action-pin-provenance.sarif',

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 3)]
    [int]$MaxAttempts = 3,

    [Parameter(Mandatory = $false)]
    [ValidateRange(0, 60)]
    [int]$RetryDelaySeconds = 5
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'Modules/WorkflowScanHelpers.psm1') -Force

#region Functions

$script:ToolName = 'Test-ActionPinProvenance'
$script:ReleaseTagPattern = '^v\d+\.\d+\.\d+$'
$script:HelpUri = 'https://github.com/microsoft/edge-ai/blob/main/.github/ACTIONS-SECURITY.md'
$script:Rules = @(
    New-SarifRule -Id 'action-pin/not-sha-pinned' -HelpUri $script:HelpUri `
        -ShortDescription 'Action is not pinned to a commit SHA' `
        -FullDescription 'Remote actions and reusable workflows must be pinned to a full 40-character commit SHA.'
    New-SarifRule -Id 'action-pin/upstream-unavailable' -HelpUri $script:HelpUri `
        -ShortDescription 'Publisher tags could not be read' `
        -FullDescription 'The publisher repository tags could not be read after retries, so the pin is unverified. Rerun the scan; this result cannot be excepted.'
    New-SarifRule -Id 'action-pin/tag-object' -HelpUri $script:HelpUri `
        -ShortDescription 'Pin names an annotated tag object' `
        -FullDescription 'The pinned SHA is an annotated tag object rather than a commit. Pin the commit the tag points at.'
    New-SarifRule -Id 'action-pin/untagged-commit' -HelpUri $script:HelpUri `
        -ShortDescription 'Pinned commit is not tagged by the publisher' `
        -FullDescription 'No tag in the publisher repository points at the pinned commit. It may be unreleased, or a commit that exists only in a fork. Pin a commit from a release tag.'
    New-SarifRule -Id 'action-pin/comment-missing' -HelpUri $script:HelpUri `
        -ShortDescription 'Pin has no version comment' `
        -FullDescription 'Every SHA pin needs a # vX.Y.Z comment naming the release at the pinned commit.'
    New-SarifRule -Id 'action-pin/comment-not-release' -HelpUri $script:HelpUri `
        -ShortDescription 'Version comment is not an exact release' `
        -FullDescription 'The version comment must be one exact vX.Y.Z release tag. Moving major or minor tags such as v1 can change without any change to the pin.'
    New-SarifRule -Id 'action-pin/comment-mismatch' -HelpUri $script:HelpUri `
        -ShortDescription 'Version comment does not match the pinned commit' `
        -FullDescription 'The release named in the version comment is absent from the publisher repository or points at a different commit than the pin.'
)

function Get-ActionReference {
    <#
    .SYNOPSIS
        Returns the remote uses: references in one file with their line numbers.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $references = [System.Collections.Generic.List[object]]::new()
    $lines = @(Get-Content -Path $Path)
    for ($i = 0; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -notmatch '^\s*(?:-\s+)?uses:\s*(?<ref>[^\s#]+)\s*(?:#\s*(?<comment>.*?))?\s*$') { continue }

        $ref = $Matches.ref.Trim('''', '"')
        $comment = if ($Matches.comment) { $Matches.comment.Trim() } else { '' }
        if ($ref.StartsWith('./') -or $ref.StartsWith('docker://')) { continue }

        $at = $ref.LastIndexOf('@')
        $target = if ($at -ge 0) { $ref.Substring(0, $at) } else { $ref }
        $version = if ($at -ge 0) { $ref.Substring($at + 1) } else { '' }
        $segments = $target -split '/'
        $repository = if ($segments.Count -ge 2) { "$($segments[0])/$($segments[1])" } else { $target }

        $references.Add([pscustomobject]@{
                Path       = $RelativePath
                Line       = $i + 1
                Target     = $target
                Repository = $repository
                Version    = $version
                Comment    = $comment
            })
    }
    return @($references)
}

function Invoke-GitLsRemote {
    <#
    .SYNOPSIS
        Lists the tags of a GitHub repository with git ls-remote.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repository
    )

    $env:GIT_TERMINAL_PROMPT = '0'
    $output = & git ls-remote --tags "https://github.com/$Repository.git" 2>&1
    if ($LASTEXITCODE -ne 0) {
        throw "git ls-remote failed for ${Repository}: $($output -join ' ')"
    }
    return @($output | ForEach-Object { [string]$_ })
}

function Get-UpstreamTagSet {
    <#
    .SYNOPSIS
        Reads a repository's tags with retries and returns tag-to-commit and tag-object maps, or $null.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repository,

        [Parameter(Mandatory = $true)]
        [int]$MaxAttempts,

        [Parameter(Mandatory = $true)]
        [int]$RetryDelaySeconds
    )

    $lines = $null
    $delay = $RetryDelaySeconds
    for ($attempt = 1; $attempt -le $MaxAttempts; $attempt++) {
        try {
            $lines = Invoke-GitLsRemote -Repository $Repository
            break
        }
        catch {
            Write-Warning "Reading tags for $Repository failed (attempt $attempt/$MaxAttempts): $($_.Exception.Message)"
            if ($attempt -lt $MaxAttempts) {
                Start-Sleep -Seconds $delay
                $delay *= 2
            }
        }
    }
    if ($null -eq $lines) { return $null }

    $direct = @{}
    $peeled = @{}
    foreach ($line in $lines) {
        if ($line -notmatch '^(?<sha>[0-9a-f]{40})\s+refs/tags/(?<name>.+?)(?<peel>\^\{\})?$') { continue }
        if ($Matches.peel) { $peeled[$Matches.name] = $Matches.sha } else { $direct[$Matches.name] = $Matches.sha }
    }

    $tags = @{}
    $tagObjects = @{}
    foreach ($name in $direct.Keys) {
        if ($peeled.ContainsKey($name)) {
            $tags[$name] = $peeled[$name]
            $tagObjects[$direct[$name]] = $name
        }
        else {
            $tags[$name] = $direct[$name]
        }
    }

    return [pscustomobject]@{ Tags = $tags; TagObjects = $tagObjects }
}

function Get-PinFinding {
    <#
    .SYNOPSIS
        Evaluates one reference against its publisher's tags and returns a finding or $null.
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Reference,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [pscustomobject]$Upstream
    )

    $where = "$($Reference.Target)@$($Reference.Version)"
    $short = if ($Reference.Version.Length -ge 12) { "$($Reference.Target)@$($Reference.Version.Substring(0, 12))" } else { $where }

    if ($Reference.Version -notmatch '^[0-9a-f]{40}$') {
        return New-SarifFinding -RuleId 'action-pin/not-sha-pinned' -Path $Reference.Path -Line $Reference.Line `
            -Message "$where is not pinned to a 40-character commit SHA."
    }
    if ($null -eq $Upstream) {
        return New-SarifFinding -RuleId 'action-pin/upstream-unavailable' -Path $Reference.Path -Line $Reference.Line `
            -Message "Could not read tags for $($Reference.Repository), so $short was not verified. Rerun the scan."
    }
    if ($Upstream.TagObjects.ContainsKey($Reference.Version)) {
        $tagName = $Upstream.TagObjects[$Reference.Version]
        return New-SarifFinding -RuleId 'action-pin/tag-object' -Path $Reference.Path -Line $Reference.Line `
            -Message "$short is the annotated tag object for '$tagName'; pin commit $($Upstream.Tags[$tagName]) instead."
    }

    $tagsAtCommit = @($Upstream.Tags.Keys | Where-Object { $Upstream.Tags[$_] -eq $Reference.Version } | Sort-Object)
    $releaseTags = @($tagsAtCommit | Where-Object { $_ -match $script:ReleaseTagPattern })
    $suggestion = if ($releaseTags.Count -gt 0) { $releaseTags -join ', ' } elseif ($tagsAtCommit.Count -gt 0) { "$($tagsAtCommit -join ', ') (no vX.Y.Z release)" } else { 'none' }

    if ($tagsAtCommit.Count -eq 0) {
        return New-SarifFinding -RuleId 'action-pin/untagged-commit' -Path $Reference.Path -Line $Reference.Line `
            -Message "No tag in $($Reference.Repository) points at $short; it may be unreleased or exist only in a fork. Pin a commit from a release tag."
    }
    if ([string]::IsNullOrWhiteSpace($Reference.Comment)) {
        return New-SarifFinding -RuleId 'action-pin/comment-missing' -Path $Reference.Path -Line $Reference.Line `
            -Message "$short has no version comment. Tags at this commit: $suggestion."
    }
    if ($Reference.Comment -cnotmatch $script:ReleaseTagPattern) {
        return New-SarifFinding -RuleId 'action-pin/comment-not-release' -Path $Reference.Path -Line $Reference.Line `
            -Message "$short is labeled '$($Reference.Comment)', which is not an exact vX.Y.Z release. Tags at this commit: $suggestion."
    }
    if (-not $Upstream.Tags.ContainsKey($Reference.Comment) -or $Upstream.Tags[$Reference.Comment] -ne $Reference.Version) {
        return New-SarifFinding -RuleId 'action-pin/comment-mismatch' -Path $Reference.Path -Line $Reference.Line `
            -Message "$short is labeled '$($Reference.Comment)', but that tag does not point at this commit. Tags at this commit: $suggestion."
    }
    return $null
}

function Invoke-ActionPinProvenanceScan {
    <#
    .SYNOPSIS
        Scans workflows and composite actions, writes SARIF, and returns the findings.
    #>
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [int]$MaxAttempts,

        [Parameter(Mandatory = $true)]
        [int]$RetryDelaySeconds
    )

    $files = Get-WorkflowScanFile -RepoRoot $RepoRoot -IncludeActions
    $references = foreach ($file in $files) {
        Get-ActionReference -Path $file.FullName -RelativePath (Get-RepoRelativePath -RepoRoot $RepoRoot -Path $file.FullName)
    }
    $references = @($references)

    $upstreamByRepo = @{}
    $pinnedRepos = @($references | Where-Object { $_.Version -match '^[0-9a-f]{40}$' } | ForEach-Object Repository | Sort-Object -Unique)
    foreach ($repository in $pinnedRepos) {
        $upstreamByRepo[$repository] = Get-UpstreamTagSet -Repository $repository -MaxAttempts $MaxAttempts -RetryDelaySeconds $RetryDelaySeconds
    }

    $findings = [System.Collections.Generic.List[object]]::new()
    foreach ($reference in $references) {
        $finding = Get-PinFinding -Reference $reference -Upstream $upstreamByRepo[$reference.Repository]
        if ($null -ne $finding) { $findings.Add($finding) }
    }

    $unavailable = @($pinnedRepos | Where-Object { $null -eq $upstreamByRepo[$_] })
    Write-Host "Checked $($references.Count) reference(s) across $($pinnedRepos.Count) repositories; unavailable: $($unavailable.Count)"

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
        $findings = @(Invoke-ActionPinProvenanceScan -RepoRoot $root -OutputPath $OutputPath -MaxAttempts $MaxAttempts -RetryDelaySeconds $RetryDelaySeconds)
        if ($findings.Count -gt 0) { exit 1 }
        exit 0
    }
    catch {
        Write-Error -ErrorAction Continue "Test-ActionPinProvenance failed: $($_.Exception.Message)"
        exit 2
    }
}

#endregion Main Execution
