#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Creates a new branch in a GitHub repository.

.DESCRIPTION
    Creates a new branch in a GitHub repository by getting the SHA of a source
    branch and creating a new reference pointing to that SHA. This script uses
    the GitHub REST API and requires a valid installation token.

.PARAMETER InstallationToken
    GitHub App installation token with contents:write permission.

.PARAMETER Repository
    Repository in format "owner/repo" (e.g., "microsoft/edge-ai").

.PARAMETER BranchName
    Name of the new branch to create (without refs/heads/ prefix).
    Example: "release/1.2.3"

.PARAMETER SourceBranch
    Name of the source branch to branch from (without refs/heads/ prefix).
    Example: "dev" or "main"

.OUTPUTS
    System.Int32 - Exit code:
      0: Success - branch created
      1: Error - branch creation failed
      2: Error - source branch not found

    Azure DevOps Output Variables (when run in pipeline):
      BRANCH_SHA: SHA of the created branch
      BRANCH_URL: GitHub URL of the created branch

.EXAMPLE
    ./New-GitHubBranch.ps1 -InstallationToken $token -Repository "microsoft/edge-ai" `
        -BranchName "release/1.2.3" -SourceBranch "dev"

    Creates a new branch "release/1.2.3" from the "dev" branch.

.NOTES
    Requires PowerShell 7.0 or later for REST API calls.
    The installation token must have contents:write permission.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InstallationToken,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[\w\-\.]+/[\w\-\.]+$')]
    [string]$Repository,

    [Parameter(Mandatory = $true)]
    [string]$BranchName,

    [Parameter(Mandatory = $true)]
    [string]$SourceBranch
)

$ErrorActionPreference = 'Stop'

try {
    Write-Host "Creating branch '$BranchName' from '$SourceBranch' in $Repository"
    Write-Host ""

    $headers = @{
        'Accept'               = 'application/vnd.github+json'
        'Authorization'        = "Bearer $InstallationToken"
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    # Get source branch SHA
    $sourceRefUrl = "https://api.github.com/repos/$Repository/git/ref/heads/$SourceBranch"
    Write-Verbose "Fetching source branch: $sourceRefUrl"

    $sourceRef = Invoke-RestMethod -Uri $sourceRefUrl -Headers $headers -Method Get
    $sourceSha = $sourceRef.object.sha

    if (-not $sourceSha) {
        Write-Error "Failed to retrieve SHA for source branch '$SourceBranch'"
        exit 2
    }
    Write-Host "Source branch SHA: $sourceSha"

    # Create new branch
    $refsUrl = "https://api.github.com/repos/$Repository/git/refs"
    $body = @{
        ref = "refs/heads/$BranchName"
        sha = $sourceSha
    } | ConvertTo-Json

    Write-Verbose "Creating branch: $refsUrl"
    $response = Invoke-RestMethod -Uri $refsUrl -Headers $headers -Method Post `
        -Body $body -ContentType 'application/json'

    Write-Host ""
    Write-Host "✓ Branch created successfully"
    Write-Host "  Ref: $($response.ref)"
    Write-Host "  SHA: $($response.object.sha)"
    Write-Host "  URL: https://github.com/$Repository/tree/$BranchName"
    Write-Host ""

    # Set Azure DevOps output variables if running in pipeline
    if ($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) {
        Write-Host "##vso[task.setvariable variable=BRANCH_SHA;isOutput=true]$($response.object.sha)"
        Write-Host "##vso[task.setvariable variable=BRANCH_URL;isOutput=true]https://github.com/$Repository/tree/$BranchName"
    }

    exit 0
}
catch {
    Write-Host ""
    Write-Error "✗ Failed to create branch '$BranchName'"

    if ($_.Exception.Response) {
        $statusCode = [int]$_.Exception.Response.StatusCode
        Write-Error "HTTP Status Code: $statusCode"

        if ($_.ErrorDetails.Message) {
            try {
                $errorJson = $_.ErrorDetails.Message | ConvertFrom-Json
                Write-Error "GitHub Error: $($errorJson.message)"

                if ($errorJson.errors) {
                    foreach ($err in $errorJson.errors) {
                        Write-Error "  - $($err.message)"
                    }
                }
            }
            catch {
                Write-Error $_.ErrorDetails.Message
            }
        }

        # Return appropriate exit code
        if ($statusCode -eq 404) {
            Write-Error "Source branch '$SourceBranch' not found"
            exit 2
        }
    }
    else {
        Write-Error $_.Exception.Message
    }

    Write-Host ""
    exit 1
}
