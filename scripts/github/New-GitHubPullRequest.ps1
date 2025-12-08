#!/usr/bin/env pwsh
#Requires -Version 7.0

<#
.SYNOPSIS
    Creates a GitHub Pull Request using the GitHub REST API.

.DESCRIPTION
    This script creates a pull request in a GitHub repository using an installation token
    from GitHub App authentication. It supports custom titles, bodies, labels, and draft mode.

.PARAMETER InstallationToken
    GitHub App installation token with pull_requests:write permission.

.PARAMETER Repository
    Repository in format "owner/repo" (e.g., "microsoft/edge-ai").

.PARAMETER Head
    The name of the branch where your changes are implemented (source branch).

.PARAMETER Base
    The name of the branch you want the changes pulled into (target branch).

.PARAMETER Title
    The title of the pull request.

.PARAMETER Body
    The contents of the pull request (supports GitHub Flavored Markdown).

.PARAMETER Draft
    Whether to create the pull request as a draft. Default is false.

.PARAMETER Labels
    An array of label names to apply to the pull request.

.EXAMPLE
    ./New-GitHubPullRequest.ps1 -InstallationToken $token -Repository "microsoft/edge-ai" `
        -Head "release/1.2.3" -Base "main" -Title "Release 1.2.3" -Labels @("release")

.OUTPUTS
    Outputs PR number and URL on success, exits with code 1 on failure.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$InstallationToken,

    [Parameter(Mandatory = $true)]
    [ValidatePattern('^[\w\-\.]+/[\w\-\.]+$')]
    [string]$Repository,

    [Parameter(Mandatory = $true)]
    [string]$Head,

    [Parameter(Mandatory = $true)]
    [string]$Base,

    [Parameter(Mandatory = $true)]
    [string]$Title,

    [Parameter(Mandatory = $false)]
    [string]$Body = '',

    [Parameter(Mandatory = $false)]
    [bool]$Draft = $false,

    [Parameter(Mandatory = $false)]
    [string[]]$Labels = @()
)

$ErrorActionPreference = 'Stop'

try {
    Write-Host "=== Creating GitHub Pull Request ==="
    Write-Host "Repository: $Repository"
    Write-Host "Head: $Head"
    Write-Host "Base: $Base"
    Write-Host "Title: $Title"
    Write-Host "Draft: $Draft"
    if ($Labels.Count -gt 0) {
        Write-Host "Labels: $($Labels -join ', ')"
    }
    Write-Host ""

    $headers = @{
        'Accept'               = 'application/vnd.github+json'
        'Authorization'        = "Bearer $InstallationToken"
        'X-GitHub-Api-Version' = '2022-11-28'
    }

    $requestBody = @{
        title = $Title
        head  = $Head
        base  = $Base
        draft = $Draft
    }

    if ($Body) {
        $requestBody['body'] = $Body
    }

    $jsonBody = $requestBody | ConvertTo-Json -Depth 10 -Compress

    $uri = "https://api.github.com/repos/$Repository/pulls"

    Write-Host "Sending request to GitHub API..."
    $response = Invoke-RestMethod -Uri $uri -Headers $headers -Method Post `
        -Body $jsonBody -ContentType 'application/json'

    Write-Host ""
    Write-Host "✓ Pull Request created successfully"
    Write-Host "  PR Number: #$($response.number)"
    Write-Host "  URL: $($response.html_url)"
    Write-Host "  State: $($response.state)"
    Write-Host "  Draft: $($response.draft)"
    Write-Host ""

    # Set Azure DevOps output variables if running in ADO pipeline
    if ($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) {
        Write-Host "##vso[task.setvariable variable=PR_NUMBER;isOutput=true]$($response.number)"
        Write-Host "##vso[task.setvariable variable=PR_URL;isOutput=true]$($response.html_url)"
    }

    # Apply labels if provided
    if ($Labels.Count -gt 0) {
        Write-Host "Applying labels to PR #$($response.number)..."
        $labelsUri = "https://api.github.com/repos/$Repository/issues/$($response.number)/labels"
        $labelsBody = @{
            labels = $Labels
        } | ConvertTo-Json -Compress

        try {
            $null = Invoke-RestMethod -Uri $labelsUri -Headers $headers -Method Post `
                -Body $labelsBody -ContentType 'application/json'
            Write-Host "✓ Labels applied: $($Labels -join ', ')"
        }
        catch {
            Write-Warning "Failed to apply labels (PR created successfully): $($_.Exception.Message)"
        }
    }

    exit 0
}
catch {
    Write-Host ""
    Write-Error "✗ Failed to create pull request"

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
    }
    else {
        Write-Error $_.Exception.Message
    }

    Write-Host ""
    exit 1
}
