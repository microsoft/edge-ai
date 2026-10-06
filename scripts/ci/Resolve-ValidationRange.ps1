#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.0

<#
.SYNOPSIS
    Resolves an immutable validation range for GitHub Actions events.
.DESCRIPTION
    Verifies the checked-out event revision and emits either a provable Git range or
    a conservative full-validation contract.
.PARAMETER EventName
    Name of the GitHub Actions event.
.PARAMETER ExpectedHeadSha
    Event SHA that must match the checked-out HEAD.
.PARAMETER PullRequestBaseSha
    Immutable base SHA from a pull_request payload.
.PARAMETER PullRequestHeadSha
    Immutable source head SHA from a pull_request payload.
.PARAMETER MergeGroupBaseSha
    Immutable base SHA from a merge_group payload.
.PARAMETER MergeGroupHeadSha
    Immutable head SHA from a merge_group payload.
.PARAMETER OutputFile
    GitHub Actions output file that receives the resolver contract.
.EXAMPLE
    ./Resolve-ValidationRange.ps1 -EventName pull_request -ExpectedHeadSha $env:GITHUB_SHA -OutputFile $env:GITHUB_OUTPUT
.NOTES
    The repository must be checked out at the event SHA with full history.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$EventName,

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$ExpectedHeadSha,

    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$PullRequestBaseSha = '',

    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$PullRequestHeadSha = '',

    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$MergeGroupBaseSha = '',

    [Parameter(Mandatory = $false)]
    [AllowEmptyString()]
    [string]$MergeGroupHeadSha = '',

    [Parameter(Mandatory = $true)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFile
)

$ErrorActionPreference = 'Stop'

#region Functions

function Test-GitCommit {
    <#
    .SYNOPSIS
        Tests whether a Git object is available as a commit.
    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Sha
    )

    & git cat-file -e "$Sha`^{commit}" 2>$null
    return $LASTEXITCODE -eq 0
}

function Test-GitAncestor {
    <#
    .SYNOPSIS
        Tests whether one commit is an ancestor of another commit.
    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$AncestorSha,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$DescendantSha
    )

    & git merge-base --is-ancestor $AncestorSha $DescendantSha
    if ($LASTEXITCODE -eq 0) {
        return $true
    }
    if ($LASTEXITCODE -eq 1) {
        return $false
    }

    throw "Git could not test whether '$AncestorSha' is an ancestor of '$DescendantSha'."
}

function Test-GitDiffable {
    <#
    .SYNOPSIS
        Tests whether Git can compare two commits.
    .OUTPUTS
        System.Boolean
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BaseSha,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$HeadSha
    )

    & git diff --quiet $BaseSha $HeadSha --
    if ($LASTEXITCODE -in @(0, 1)) {
        return $true
    }

    throw "Git could not compare '$BaseSha' and '$HeadSha'."
}

function Resolve-ValidationRange {
    <#
    .SYNOPSIS
        Resolves the validation contract for a supported event.
    .OUTPUTS
        System.Management.Automation.PSCustomObject
    #>
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$EventName,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$ExpectedHeadSha,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$CheckedOutHeadSha,

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$PullRequestBaseSha = '',

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$PullRequestHeadSha = '',

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$MergeGroupBaseSha = '',

        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$MergeGroupHeadSha = ''
    )

    if ($CheckedOutHeadSha -ne $ExpectedHeadSha) {
        throw "Checked-out HEAD '$CheckedOutHeadSha' does not match event SHA '$ExpectedHeadSha'."
    }

    $Result = [pscustomobject]@{
        Mode    = 'full'
        BaseSha = ''
        HeadSha = $CheckedOutHeadSha
    }

    if ($EventName -eq 'workflow_dispatch') {
        return $Result
    }

    if ($EventName -eq 'pull_request') {
        $BaseSha = $PullRequestBaseSha
        $ResolvedHeadSha = $CheckedOutHeadSha
        $RequiredAncestorSha = $PullRequestHeadSha
    }
    elseif ($EventName -eq 'merge_group') {
        $BaseSha = $MergeGroupBaseSha
        $ResolvedHeadSha = $MergeGroupHeadSha
        $RequiredAncestorSha = ''
    }
    else {
        return $Result
    }

    if ([string]::IsNullOrWhiteSpace($BaseSha) -or
        [string]::IsNullOrWhiteSpace($ResolvedHeadSha) -or
        $BaseSha -eq $ResolvedHeadSha -or
        $ResolvedHeadSha -ne $CheckedOutHeadSha) {
        return $Result
    }

    if (-not (Test-GitCommit -Sha $BaseSha) -or
        -not (Test-GitCommit -Sha $ResolvedHeadSha)) {
        return $Result
    }

    if (-not [string]::IsNullOrWhiteSpace($RequiredAncestorSha)) {
        if (-not (Test-GitCommit -Sha $RequiredAncestorSha) -or
            -not (Test-GitAncestor -AncestorSha $RequiredAncestorSha -DescendantSha $ResolvedHeadSha)) {
            return $Result
        }
    }

    if (-not (Test-GitAncestor -AncestorSha $BaseSha -DescendantSha $ResolvedHeadSha) -or
        -not (Test-GitDiffable -BaseSha $BaseSha -HeadSha $ResolvedHeadSha)) {
        return $Result
    }

    $Result.Mode = 'range'
    $Result.BaseSha = $BaseSha
    return $Result
}

#endregion Functions

#region Main Execution

if ($MyInvocation.InvocationName -ne '.') {
    try {
        if ($null -eq (Get-Command git -ErrorAction SilentlyContinue)) {
            throw 'Git is required to resolve the validation range.'
        }

        $CheckedOutHeadSha = & git rev-parse HEAD
        if ($LASTEXITCODE -ne 0) {
            throw 'Git could not resolve the checked-out HEAD.'
        }

        $ResolveParameters = @{
            EventName            = $EventName
            ExpectedHeadSha      = $ExpectedHeadSha
            CheckedOutHeadSha    = $CheckedOutHeadSha
            PullRequestBaseSha   = $PullRequestBaseSha
            PullRequestHeadSha   = $PullRequestHeadSha
            MergeGroupBaseSha    = $MergeGroupBaseSha
            MergeGroupHeadSha    = $MergeGroupHeadSha
        }
        $Result = Resolve-ValidationRange @ResolveParameters

        "mode=$($Result.Mode)" | Add-Content -Path $OutputFile -Encoding utf8
        "base-sha=$($Result.BaseSha)" | Add-Content -Path $OutputFile -Encoding utf8
        "head-sha=$($Result.HeadSha)" | Add-Content -Path $OutputFile -Encoding utf8
    }
    catch {
        Write-Error -ErrorAction Continue "Resolve-ValidationRange failed: $($_.Exception.Message)"
        exit 1
    }
}

#endregion Main Execution
