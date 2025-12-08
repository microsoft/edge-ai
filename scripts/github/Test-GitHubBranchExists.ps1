#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Tests if a branch exists in a GitHub repository.

.DESCRIPTION
    Checks whether a specified branch exists in a GitHub repository using the
    GitHub REST API. This is a read-only operation useful for validation and
    collision detection before creating new branches.

.PARAMETER InstallationToken
    GitHub App installation token with metadata:read permission.

.PARAMETER Repository
    Repository in format "owner/repo" (e.g., "microsoft/edge-ai").

.PARAMETER BranchName
    Branch name to check (without refs/heads/ prefix).
    Example: "release/1.2.3"

.OUTPUTS
    System.Int32 - Exit code:
      0: Branch does NOT exist (safe to create)
      1: Branch EXISTS (collision detected)
      2: Error checking (API failure)

    Azure DevOps Output Variables (when run in pipeline):
      BRANCH_EXISTS: "true" or "false"
      BRANCH_SHA: SHA if exists, empty otherwise
      BRANCH_PROTECTED: "true" or "false" if exists

.EXAMPLE
    ./Test-GitHubBranchExists.ps1 -InstallationToken $token `
        -Repository "microsoft/edge-ai" -BranchName "release/1.2.3"

    Checks if branch "release/1.2.3" exists. Returns exit code 0 if it doesn't exist,
    1 if it does exist.

.NOTES
    Requires PowerShell 7.0 or later for REST API calls.
    Uses HTTP 404 status to determine branch non-existence.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InstallationToken,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[\w\-\.]+/[\w\-\.]+$')]
    [string]$Repository,

    [Parameter(Mandatory = $true)]
    [string]$BranchName
)

$ErrorActionPreference = 'Stop'

$headers = @{
    'Accept'               = 'application/vnd.github+json'
    'Authorization'        = "Bearer $InstallationToken"
    'X-GitHub-Api-Version' = '2022-11-28'
}

$branchUrl = "https://api.github.com/repos/$Repository/branches/$BranchName"

try {
    Write-Verbose "Checking branch: $branchUrl"
    $branchInfo = Invoke-RestMethod -Uri $branchUrl -Headers $headers -Method Get -ErrorAction Stop

    # Branch exists - collision detected
    Write-Information "##[section]Branch Collision Detected"
    Write-Information ""
    Write-Information "✗ Branch '$BranchName' already exists in $Repository"
    Write-Information ""
    Write-Information "Branch details:"
    Write-Information "  Name: $($branchInfo.name)"
    Write-Information "  SHA: $($branchInfo.commit.sha)"
    Write-Information "  Protected: $($branchInfo.protected)"
    Write-Information "  Commit Date: $($branchInfo.commit.commit.author.date)"
    Write-Information "  Commit Author: $($branchInfo.commit.commit.author.name)"

    $commitMessage = ($branchInfo.commit.commit.message -split "`n")[0]
    if ($commitMessage.Length -gt 80) {
        $commitMessage = $commitMessage.Substring(0, 77) + "..."
    }
    Write-Information "  Commit Message: $commitMessage"
    Write-Information ""
    Write-Information "View branch: https://github.com/$Repository/tree/$BranchName"
    Write-Information ""

    # Set Azure DevOps output variables if running in pipeline
    if ($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) {
        Write-Information "##vso[task.setvariable variable=BRANCH_EXISTS;isOutput=true]true"
        Write-Information "##vso[task.setvariable variable=BRANCH_SHA;isOutput=true]$($branchInfo.commit.sha)"
        Write-Information "##vso[task.setvariable variable=BRANCH_PROTECTED;isOutput=true]$($branchInfo.protected)"
    }

    exit 1  # Branch exists (collision)
}
catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        # Branch does not exist - success
        Write-Information "✓ Branch does not exist (HTTP 404 - expected)"

        # Set Azure DevOps output variables if running in pipeline
        if ($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) {
            Write-Information "##vso[task.setvariable variable=BRANCH_EXISTS;isOutput=true]false"
            Write-Information "##vso[task.setvariable variable=BRANCH_SHA;isOutput=true]"
            Write-Information "##vso[task.setvariable variable=BRANCH_PROTECTED;isOutput=true]false"
        }

        exit 0  # Branch does not exist (success)
    }
    else {
        # Unexpected error
        Write-Information ""
        Write-Error "✗ Unexpected error checking branch '$BranchName'"

        if ($_.Exception.Response) {
            $statusCode = [int]$_.Exception.Response.StatusCode
            Write-Error "HTTP Status Code: $statusCode"
        }

        Write-Error $_.Exception.Message

        if ($_.ErrorDetails.Message) {
            try {
                $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Error "GitHub Error: $($errorJson.message)"
            }
            catch {
                Write-Error $_.ErrorDetails.Message
            }
        }

        Write-Information ""
        exit 2  # API error
    }
}
