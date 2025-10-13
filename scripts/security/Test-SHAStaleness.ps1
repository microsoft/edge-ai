﻿#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Monitors SHA-pinned dependencies for staleness and security vulnerabilities.

.DESCRIPTION
    This script scans all SHA-pinned dependencies across GitHub Actions, Docker images, and shell scripts
    to identify stale or potentially vulnerable dependencies. It outputs results in structured formats
    that can be consumed by CI/CD systems to generate build warnings.

    Key features:
    - Detects outdated GitHub Actions SHAs
    - Identifies stale Docker image digests
    - Checks shell script dependency freshness
    - Outputs results for CI/CD integration
    - Supports multiple output formats (JSON, Azure DevOps, GitHub Actions)

.PARAMETER OutputFormat
    Output format: 'json', 'azdo', 'github', or 'console' (default: console)

.PARAMETER MaxAge
    Maximum age in days before considering a dependency stale (default: 30)

.PARAMETER LogPath
    Path for security logging (default: ./logs/sha-staleness-monitoring.log)

.PARAMETER OutputPath
    Path to write structured output file (default: ./logs/stale-dependencies.json)

.EXAMPLE
    ./Test-SHAStaleness.ps1 -OutputFormat github
    Check for stale SHAs and output GitHub Actions warnings

.EXAMPLE
    ./Test-SHAStaleness.ps1 -OutputFormat azdo -MaxAge 14
    Check for stale SHAs and output Azure DevOps warnings for dependencies older than 14 days

.EXAMPLE
    ./Test-SHAStaleness.ps1 -OutputFormat json -OutputPath ./security-report.json
    Generate JSON report of all stale dependencies
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet("json", "azdo", "github", "console", "BuildWarning", "Summary")]
    [string]$OutputFormat = "console",

    [Parameter(Mandatory = $false)]
    [int]$MaxAge = 30,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "./logs/sha-staleness-monitoring.log",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./logs/stale-dependencies.json"
)

# Ensure logging directory exists
$LogDir = Split-Path -Parent $LogPath
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

. "$PSScriptRoot/Ros2ExclusionHelper.ps1"

function Write-SecurityLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = "Empty log message"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Console output with colors (only in console mode)
    if ($OutputFormat -eq "console") {
        switch ($Level) {
            "Info" { Write-Information $logEntry -InformationAction Continue }
            "Warning" { Write-Warning $logEntry }
            "Error" { Write-Error $logEntry }
            "Success" { Write-Information $logEntry -InformationAction Continue }
        }
    }

    # File logging
    try {
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Failed to write to log file: $($_.Exception.Message)" -ErrorAction SilentlyContinue
    }
}

# ROS2 components rely on rolling tags; upstream prunes timestamped builds so digest checks are skipped. See docs/build-cicd/security-analysis-workflow.md.
$Ros2ImageExclusionPatterns = Get-Ros2ImageExclusionList

# Structure to hold stale dependency information
$StaleDependencies = @()

function Get-DockerHubManifestDigest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Repository,

        [Parameter(Mandatory = $true)]
        [string]$Tag,

        [Parameter(Mandatory = $true)]
        [string]$CurrentDigest
    )

    $scope = [Uri]::EscapeDataString("repository:$Repository:pull")
    $tokenUri = "https://auth.docker.io/token?service=registry.docker.io&scope=$scope"
    $manifestUri = "https://registry-1.docker.io/v2/$Repository/manifests/$Tag"

    $commonHeaders = @{ 'User-Agent' = 'edge-ai-sha-staleness-check' }
    Write-SecurityLog ("Requesting Docker Hub token for {0}:{1}" -f $Repository, $Tag) -Level Info
    $tokenResponse = Invoke-RestMethod -Uri $tokenUri -Headers $commonHeaders -ErrorAction Stop
    if (-not $tokenResponse.token) {
        throw "Docker Hub token response did not include a token"
    }

    $headers = @{
        Authorization = "Bearer $($tokenResponse.token)"
        Accept        = "application/vnd.docker.distribution.manifest.list.v2+json"
        'User-Agent'  = 'edge-ai-sha-staleness-check'
    }
    Write-SecurityLog ("Fetching Docker Hub manifest for {0}:{1}" -f $Repository, $Tag) -Level Info
    $manifestResponse = Invoke-WebRequest -Uri $manifestUri -Headers $headers -ErrorAction Stop
    $remoteDigest = $manifestResponse.Headers['Docker-Content-Digest']

    if (-not $remoteDigest) {
        $headers['Accept'] = "application/vnd.docker.distribution.manifest.v2+json"
        $manifestResponse = Invoke-WebRequest -Uri $manifestUri -Headers $headers -ErrorAction Stop
        $remoteDigest = $manifestResponse.Headers['Docker-Content-Digest']
    }

    if (-not $remoteDigest) {
        throw "Docker Hub response did not include Docker-Content-Digest header"
    }

    $isStale = $false
    $message = "Digest matches Docker Hub manifest"

    if ($CurrentDigest -ne $remoteDigest) {
        $isStale = $true
        $message = "Pinned digest $CurrentDigest differs from Docker Hub manifest $remoteDigest"
    }

    return @{
        CurrentDigest = $CurrentDigest
        LatestDigest  = $remoteDigest
        IsStale       = $isStale
        Message       = $message
    }
}

function Get-BulkGitHubActionsStalenesss {
    param(
        [Parameter(Mandatory = $true)]
        [array]$ActionRepos,

        [Parameter(Mandatory = $true)]
        [hashtable]$ShaToActionMap
    )

    # Setup headers with authentication
    $headers = @{
        "Content-Type" = "application/json"
    }

    # Check multiple potential sources for GitHub token
    $githubToken = $null
    if ($env:GITHUB_TOKEN) {
        $githubToken = $env:GITHUB_TOKEN
        Write-SecurityLog "Using GITHUB_TOKEN environment variable" -Level Info
    }
    elseif ($env:SYSTEM_ACCESSTOKEN -and $env:BUILD_REPOSITORY_PROVIDER -eq "GitHub") {
        # Azure DevOps with GitHub repository might have this
        $githubToken = $env:SYSTEM_ACCESSTOKEN
        Write-SecurityLog "Using Azure DevOps SYSTEM_ACCESSTOKEN for GitHub repo" -Level Info
    }
    elseif ($env:GH_TOKEN) {
        # Alternative GitHub token environment variable
        $githubToken = $env:GH_TOKEN
        Write-SecurityLog "Using GH_TOKEN environment variable" -Level Info
    }

    if ($githubToken) {
        $headers['Authorization'] = "Bearer $githubToken"
        Write-SecurityLog "Using authenticated GraphQL API (5,000 points/hour)" -Level Info
    }
    else {
        Write-SecurityLog "No GitHub token found - using unauthenticated GraphQL API (60 points/hour)" -Level Warning
        Write-SecurityLog "Set GITHUB_TOKEN environment variable for higher rate limits" -Level Warning
    }

    # Build GraphQL query for multiple repositories (batch 1: get default branches)
    $repoQueries = @()
    $aliasMap = @{}

    foreach ($i in 0..($ActionRepos.Count - 1)) {
        $repo = $ActionRepos[$i]
        $alias = "repo$i"
        $aliasMap[$alias] = $repo

        # Parse owner/repo
        $parts = $repo.Split('/')
        if ($parts.Count -ne 2) { continue }
        $owner = $parts[0]
        $repoName = $parts[1]

        $repoQueries += @"
        $alias`: repository(owner: "$owner", name: "$repoName") {
            name
            defaultBranchRef {
                target {
                    ... on Commit {
                        oid
                        committedDate
                    }
                }
            }
        }
"@
    }

    # Single GraphQL query for all repository default branches
    $graphqlQuery = @{
        query = @"
        query {
            $($repoQueries -join "`n            ")
            rateLimit {
                limit
                remaining
                used
                resetAt
            }
        }
"@
    } | ConvertTo-Json -Depth 10

    try {
        $repoResponse = Invoke-RestMethod -Uri "https://api.github.com/graphql" -Method POST -Headers $headers -Body $graphqlQuery -ContentType "application/json"

        Write-SecurityLog "GraphQL Rate Limit: $($repoResponse.data.rateLimit.remaining)/$($repoResponse.data.rateLimit.limit) remaining" -Level Info

        if ($repoResponse.errors) {
            Write-SecurityLog "GraphQL errors: $($repoResponse.errors | ConvertTo-Json)" -Level Warning
        }
    }
    catch {
        $statusCode = $null
        if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
            $statusCode = [int]$_.Exception.Response.StatusCode
        }

        if ($statusCode -in 403, 429) {
            Write-SecurityLog "Repository GraphQL query hit rate limit ($statusCode). Falling back to REST checks." -Level Warning
        }
        else {
            Write-SecurityLog "Repository GraphQL query failed: $($_.Exception.Message)" -Level Error
        }

        throw
    }

    # Collect commit queries for all current SHAs
    $commitQueries = @()
    $commitAliasMap = @{}
    $commitIndex = 0

    foreach ($key in $ShaToActionMap.Keys) {
        $action = $ShaToActionMap[$key]
        $alias = "commit$commitIndex"
        $commitAliasMap[$alias] = $key

        # Parse owner/repo
        $parts = $action.Repo.Split('/')
        if ($parts.Count -ne 2) { continue }
        $owner = $parts[0]
        $repoName = $parts[1]

        $commitQueries += @"
        $alias`: repository(owner: "$owner", name: "$repoName") {
            object(oid: "$($action.SHA)") {
                ... on Commit {
                    oid
                    committedDate
                }
            }
        }
"@
        $commitIndex++
    }

    # Batch commit queries (max 20 per query to avoid complexity limits)
    $batchSize = 20
    $allCommitResults = @{}

    for ($i = 0; $i -lt $commitQueries.Count; $i += $batchSize) {
        $endIndex = [Math]::Min($i + $batchSize - 1, $commitQueries.Count - 1)
        $batchQueries = $commitQueries[$i..$endIndex]

        $commitGraphqlQuery = @{
            query = @"
            query {
                $($batchQueries -join "`n                ")
                rateLimit {
                    remaining
                    cost
                }
            }
"@
        } | ConvertTo-Json -Depth 10

        try {
            $commitResponse = Invoke-RestMethod -Uri "https://api.github.com/graphql" -Method POST -Headers $headers -Body $commitGraphqlQuery -ContentType "application/json"

            # Merge results
            foreach ($property in $commitResponse.data.PSObject.Properties) {
                if ($property.Name -ne "rateLimit") {
                    $allCommitResults[$property.Name] = $property.Value
                }
            }

            Write-SecurityLog "GraphQL batch $([Math]::Floor($i / $batchSize) + 1): Cost $($commitResponse.data.rateLimit.cost), $($commitResponse.data.rateLimit.remaining) remaining" -Level Info
        }
        catch {
            Write-SecurityLog "Commit GraphQL batch query failed: $($_.Exception.Message)" -Level Warning
        }
    }

    # Process results and return staleness information
    $results = @()

    foreach ($key in $ShaToActionMap.Keys) {
        $action = $ShaToActionMap[$key]

        # Find repository data
        $repoAlias = $null
        for ($i = 0; $i -lt $ActionRepos.Count; $i++) {
            if ($ActionRepos[$i] -eq $action.Repo) {
                $repoAlias = "repo$i"
                break
            }
        }

        if (-not $repoAlias -or -not $repoResponse.data.$repoAlias) {
            Write-SecurityLog "No repository data found for $($action.Repo)" -Level Warning
            continue
        }

        $repoData = $repoResponse.data.$repoAlias
        if (-not $repoData.defaultBranchRef) {
            Write-SecurityLog "No default branch found for $($action.Repo)" -Level Warning
            continue
        }

        $latestSHA = $repoData.defaultBranchRef.target.oid
        $latestDate = [DateTime]::Parse($repoData.defaultBranchRef.target.committedDate)

        # Find current commit data
        $commitAlias = $null
        foreach ($alias in $commitAliasMap.Keys) {
            if ($commitAliasMap[$alias] -eq $key) {
                $commitAlias = $alias
                break
            }
        }

        if ($commitAlias -and $allCommitResults[$commitAlias] -and $allCommitResults[$commitAlias].object) {
            $currentCommit = $allCommitResults[$commitAlias].object
            $currentDate = [DateTime]::Parse($currentCommit.committedDate)
            $daysOld = [Math]::Round((Get-Date).Subtract($currentDate).TotalDays)

            $results += @{
                ActionRepo  = $action.Repo
                CurrentSHA  = $action.SHA
                LatestSHA   = $latestSHA
                CurrentDate = $currentDate
                LatestDate  = $latestDate
                DaysOld     = $daysOld
                IsStale     = $action.SHA -ne $latestSHA -and $daysOld -gt $MaxAge
                File        = $action.File
            }
        }
        else {
            Write-SecurityLog "No commit data found for $($action.Repo)@$($action.SHA)" -Level Warning
        }
    }

    $totalCalls = 1 + [Math]::Ceiling($commitQueries.Count / $batchSize)
    $originalCalls = $ShaToActionMap.Count * 3
    $reduction = [Math]::Round((1 - ($totalCalls / $originalCalls)) * 100, 1)

    Write-SecurityLog "GraphQL optimization: Reduced from ~$originalCalls REST calls to $totalCalls GraphQL calls ($reduction% reduction)" -Level Success

    return $results
}

function Get-DockerImageLatestDigest {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Mandatory = $true)]
        [string]$CurrentDigest
    )

    try {
        $separatorIndex = $ImageName.IndexOf(':')
        if ($separatorIndex -lt 0) {
            throw "Image name $ImageName is missing a tag"
        }

        $repositoryPart = $ImageName.Substring(0, $separatorIndex)
        $tag = $ImageName.Substring($separatorIndex + 1)

        $segments = $repositoryPart.Split('/')
        if ($segments.Count -eq 0) {
            throw "Unable to parse repository from $ImageName"
        }

        $registryCandidate = $segments[0]
        $registry = "docker.io"
        $repoSegments = $segments

        if ($segments.Count -gt 1 -and ($registryCandidate -like "*.*" -or $registryCandidate -like "*:*" -or $registryCandidate -eq "localhost")) {
            $registry = $registryCandidate
            $repoSegments = $segments[1..($segments.Count - 1)]
        }

        if ($registry -eq "mcr.microsoft.com") {
            return @{
                CurrentDigest = $CurrentDigest
                LatestDigest  = "unknown"
                IsStale       = $false
                Message       = "MCR digest checking not implemented"
            }
        }

        if ($registry -ne "docker.io") {
            return @{
                CurrentDigest = $CurrentDigest
                LatestDigest  = "unknown"
                IsStale       = $false
                Message       = "Registry not supported for automated checking"
            }
        }

        if ($repoSegments.Count -eq 0) {
            throw "Docker Hub repository path not found for $ImageName"
        }

        $repositoryPath = $repoSegments -join '/'
        if ($repoSegments.Count -eq 1) {
            $repositoryPath = "library/$repositoryPath"
        }

        return Get-DockerHubManifestDigest -Repository $repositoryPath -Tag $tag -CurrentDigest $CurrentDigest
    }
    catch {
        Write-SecurityLog "Failed to check Docker image $ImageName`: $($_.Exception.Message)" -Level Warning
        return @{
            CurrentDigest = $CurrentDigest
            LatestDigest  = "error"
            IsStale       = $false
            Message       = $_.Exception.Message
        }
    }
}

function Test-GitHubActionsForStaleness {
    Write-SecurityLog "Scanning GitHub Actions workflows for stale SHAs..." -Level Info

    $WorkflowFiles = Get-ChildItem -Path ".github/workflows" -Filter "*.yml" -ErrorAction SilentlyContinue
    $allActionRepos = @()
    $shaToActionMap = @{}

    # First pass: collect all unique repositories and SHAs
    foreach ($File in $WorkflowFiles) {
        $Content = Get-Content -Path $File.FullName -Raw
        $SHAMatches = [regex]::Matches($Content, "uses:\s*([^@\s]+)@([a-f0-9]{40})")

        foreach ($Match in $SHAMatches) {
            $ActionRepo = $Match.Groups[1].Value
            $CurrentSHA = $Match.Groups[2].Value

            if ($ActionRepo -notin $allActionRepos) {
                $allActionRepos += $ActionRepo
            }

            $shaToActionMap["$ActionRepo@$CurrentSHA"] = @{
                Repo = $ActionRepo
                SHA  = $CurrentSHA
                File = $File.FullName
            }
        }
    }

    if ($allActionRepos.Count -eq 0) {
        Write-SecurityLog "No SHA-pinned GitHub Actions found" -Level Info
        return
    }

    Write-SecurityLog "Found $($allActionRepos.Count) unique repositories with $($shaToActionMap.Count) SHA-pinned actions" -Level Info

    # Bulk query for all actions using GraphQL optimization
    try {
        $bulkResults = Get-BulkGitHubActionsStalenesss -ActionRepos $allActionRepos -ShaToActionMap $shaToActionMap

        foreach ($result in $bulkResults) {
            if ($result.IsStale) {
                $script:StaleDependencies += [PSCustomObject]@{
                    Type           = "GitHubAction"
                    File           = $result.File
                    Name           = $result.ActionRepo
                    CurrentVersion = $result.CurrentSHA
                    LatestVersion  = $result.LatestSHA
                    DaysOld        = $result.DaysOld
                    Severity       = if ($result.DaysOld -gt 90) { "High" } elseif ($result.DaysOld -gt 60) { "Medium" } else { "Low" }
                    Message        = "GitHub Action is $($result.DaysOld) days old (current: $($result.CurrentSHA.Substring(0,8)), latest: $($result.LatestSHA.Substring(0,8)))"
                }

                Write-SecurityLog "Found stale GitHub Action: $($result.ActionRepo) ($($result.DaysOld) days old)" -Level Warning
            }
            else {
                Write-SecurityLog "GitHub Action is up-to-date: $($result.ActionRepo)" -Level Info
            }
        }
    }
    catch {
        Write-SecurityLog "Bulk GraphQL check failed, falling back to individual checks: $($_.Exception.Message)" -Level Warning

        # Fallback to individual REST API calls if GraphQL fails
        $defaultBranchCache = @{}
        $rateLimitExceeded = $false
        foreach ($key in $shaToActionMap.Keys) {
            $action = $shaToActionMap[$key]

            Write-SecurityLog "Checking GitHub Action (fallback): $($action.Repo)@$($action.SHA)" -Level Info

            # Individual REST API call as fallback
            try {
                $headers = @{}
                if ($env:GITHUB_TOKEN) {
                    $headers['Authorization'] = "token $env:GITHUB_TOKEN"
                }

                $repoSegments = $action.Repo.Split('/')
                if ($repoSegments.Count -lt 2) {
                    Write-SecurityLog "Invalid GitHub Action repository format: $($action.Repo)" -Level Warning
                    continue
                }

                $owner = $repoSegments[0]
                $repoName = $repoSegments[1]
                $repoLookup = "$owner/$repoName"

                if (-not $defaultBranchCache.ContainsKey($repoLookup)) {
                    try {
                        $repoInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoLookup" -Headers $headers -ErrorAction Stop
                        $defaultBranch = if ($repoInfo.default_branch) { $repoInfo.default_branch } else { "main" }
                        $defaultBranchCache[$repoLookup] = $defaultBranch
                    }
                    catch {
                        Write-SecurityLog "Failed to discover default branch for $repoLookup, defaulting to 'main': $($_.Exception.Message)" -Level Warning
                        $defaultBranchCache[$repoLookup] = "main"
                    }
                }

                $branchName = $defaultBranchCache[$repoLookup]

                $BranchInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoLookup/branches/$branchName" -Headers $headers -ErrorAction Stop
                $LatestSHA = $BranchInfo.commit.sha

                if ($action.SHA -ne $LatestSHA) {
                    $CurrentCommit = Invoke-RestMethod -Uri "https://api.github.com/repos/$repoLookup/commits/$($action.SHA)" -Headers $headers -ErrorAction Stop
                    $CurrentDate = [DateTime]::Parse($CurrentCommit.commit.author.date)
                    $DaysOld = [Math]::Round((Get-Date).Subtract($CurrentDate).TotalDays)

                    if ($DaysOld -gt $MaxAge) {
                        $script:StaleDependencies += [PSCustomObject]@{
                            Type           = "GitHubAction"
                            File           = $action.File
                            Name           = $action.Repo
                            CurrentVersion = $action.SHA
                            LatestVersion  = $LatestSHA
                            DaysOld        = $DaysOld
                            Severity       = if ($DaysOld -gt 90) { "High" } elseif ($DaysOld -gt 60) { "Medium" } else { "Low" }
                            Message        = "GitHub Action is $DaysOld days old (current: $($action.SHA.Substring(0,8)), latest: $($LatestSHA.Substring(0,8)))"
                        }

                        Write-SecurityLog "Found stale GitHub Action (fallback): $($action.Repo) ($DaysOld days old)" -Level Warning
                    }
                }
            }
            catch {
                $statusCode = $null
                if ($_.Exception.Response -and $_.Exception.Response.StatusCode) {
                    $statusCode = [int]$_.Exception.Response.StatusCode
                }
                elseif ($_.Exception.StatusCode) {
                    $statusCode = [int]$_.Exception.StatusCode
                }

                if ($statusCode -eq 403 -or $statusCode -eq 429) {
                    Write-SecurityLog "GitHub API rate limit exceeded for $($action.Repo) - skipping remaining GitHub Action checks" -Level Warning
                    $rateLimitExceeded = $true
                }
                else {
                    Write-SecurityLog "Failed to check GitHub Action $($action.Repo): $($_.Exception.Message)" -Level Warning
                }
            }

            if ($rateLimitExceeded) {
                break
            }
        }

        if ($rateLimitExceeded) {
            Write-SecurityLog "GitHub Action staleness results are incomplete due to API rate limiting. Provide a token via GITHUB_TOKEN to enable full coverage." -Level Warning
        }
    }
}

function Test-DockerImagesForStaleness {
    Write-SecurityLog "Scanning Docker images for stale digests..." -Level Info

    $DockerFiles = Get-ChildItem -Path "." -Recurse -Include "Dockerfile", "docker-compose.yml", "docker-compose.yaml" | Where-Object { $_.FullName -notmatch "node_modules" }

    foreach ($File in $DockerFiles) {
        $skipRos2 = $false
        foreach ($pattern in $Ros2ImageExclusionPatterns) {
            if ($File.FullName -like $pattern) {
                $skipRos2 = $true
                Write-SecurityLog "Skipping ROS2 image staleness check: $($File.FullName)" -Level Info
                break
            }
        }

        if ($skipRos2) {
            continue
        }

        $Content = Get-Content -Path $File.FullName -Raw

        # Find SHA-pinned Docker images
        $DigestMatches = [regex]::Matches($Content, "([^\s:]+):([^@\s]+)@sha256:([a-f0-9]{64})")

        foreach ($Match in $DigestMatches) {
            $ImageName = "$($Match.Groups[1].Value):$($Match.Groups[2].Value)"
            $CurrentDigest = "sha256:$($Match.Groups[3].Value)"

            Write-SecurityLog "Checking Docker image: $ImageName@$CurrentDigest" -Level Info

            $StalenessInfo = Get-DockerImageLatestDigest -ImageName $ImageName -CurrentDigest $CurrentDigest

            if ($StalenessInfo.IsStale) {
                $script:StaleDependencies += [PSCustomObject]@{
                    Type           = "DockerImage"
                    File           = $File.FullName
                    Name           = $ImageName
                    CurrentVersion = $CurrentDigest
                    LatestVersion  = $StalenessInfo.LatestDigest
                    DaysOld        = "unknown"
                    Severity       = "Medium"
                    Message        = "Docker image digest may be stale: $($StalenessInfo.Message)"
                }

                Write-SecurityLog "Found potentially stale Docker image: $ImageName" -Level Warning
            }
        }
    }
}

function Test-ShellScriptsForStaleness {
    Write-SecurityLog "Scanning shell scripts for stale dependencies..." -Level Info

    $ShellScripts = Get-ChildItem -Path "." -Recurse -Include "*.sh" | Where-Object { $_.FullName -notmatch "node_modules" }

    foreach ($Script in $ShellScripts) {
        $Content = Get-Content -Path $Script.FullName -Raw

        # Look for TODO comments added by our SHA pinning scripts
        $TodoMatches = [regex]::Matches($Content, "# TODO: Pin .* - (.+)")

        foreach ($Match in $TodoMatches) {
            $DependencyUrl = $Match.Groups[1].Value

            $script:StaleDependencies += [PSCustomObject]@{
                Type           = "ShellScriptDependency"
                File           = $Script.FullName
                Name           = $DependencyUrl
                CurrentVersion = "unpinned"
                LatestVersion  = "unknown"
                DaysOld        = "unknown"
                Severity       = "High"
                Message        = "Shell script dependency is not SHA-pinned: $DependencyUrl"
            }

            Write-SecurityLog "Found unpinned shell script dependency: $DependencyUrl" -Level Warning
        }
    }
}

function Write-OutputResult {
    param(
        [Parameter(Mandatory = $false)]
        [array]$Dependencies = @(),

        [Parameter(Mandatory)]
        [ValidateSet("json", "azdo", "github", "console", "BuildWarning", "Summary")]
        [string]$OutputFormat,

        [Parameter()]
        [string]$OutputPath
    )

    switch ($OutputFormat) {
        "json" {
            $JsonOutput = @{
                Timestamp       = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                MaxAgeThreshold = $MaxAge
                TotalStaleItems = $Dependencies.Count
                Dependencies    = $Dependencies
            } | ConvertTo-Json -Depth 10

            # Ensure output directory exists
            $OutputDir = Split-Path -Parent $OutputPath
            if (!(Test-Path $OutputDir)) {
                New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
            }

            Set-Content -Path $OutputPath -Value $JsonOutput
            Write-SecurityLog "JSON report written to: $OutputPath" -Level Success
        }

        "github" {
            foreach ($Dep in $Dependencies) {
                $Message = "::warning file=$($Dep.File.Replace('\', '/'))::[$($Dep.Severity)] $($Dep.Message)"
                Write-Output $Message
            }

            if ($Dependencies.Count -eq 0) {
                Write-Output "::notice::No stale dependencies detected"
            }
            else {
                Write-Output "::error::Found $($Dependencies.Count) stale dependencies that may pose security risks"
            }
        }

        "azdo" {
            foreach ($Dep in $Dependencies) {
                $Message = "##vso[task.logissue type=warning;sourcepath=$($Dep.File);][$($Dep.Severity)] $($Dep.Message)"
                Write-Output $Message
            }

            if ($Dependencies.Count -eq 0) {
                Write-Output "##vso[task.logissue type=info]No stale dependencies detected"
            }
            else {
                Write-Output "##vso[task.logissue type=error]Found $($Dependencies.Count) stale dependencies that may pose security risks"
                Write-Output "##vso[task.complete result=SucceededWithIssues]"
            }
        }

        "console" {
            if ($Dependencies.Count -eq 0) {
                Write-SecurityLog "No stale dependencies detected!" -Level Success
            }
            else {
                Write-SecurityLog "=== STALE DEPENDENCIES DETECTED ===" -Level Warning
                foreach ($Dep in $Dependencies) {
                    Write-SecurityLog "[$($Dep.Severity)] $($Dep.Type): $($Dep.Name)" -Level Warning
                    Write-SecurityLog "  File: $($Dep.File)" -Level Info
                    Write-SecurityLog "  Message: $($Dep.Message)" -Level Info
                    Write-Information "" -InformationAction Continue
                }
                Write-SecurityLog "Total stale dependencies: $($Dependencies.Count)" -Level Warning
            }
        }

        "Summary" {
            if ($Dependencies.Count -eq 0) {
                Write-Output "No stale dependencies detected!"
            }
            else {
                Write-Output "=== SHA Staleness Summary ==="
                Write-Output "Total stale dependencies: $($Dependencies.Count)"
                $ByType = $Dependencies | Group-Object Type
                foreach ($Group in $ByType) {
                    Write-Output "$($Group.Name): $($Group.Count)"
                }
            }
        }
    }
}

# Main execution
Write-SecurityLog "Starting SHA staleness monitoring..." -Level Info
Write-SecurityLog "Max age threshold: $MaxAge days" -Level Info
Write-SecurityLog "Output format: $OutputFormat" -Level Info

# Run all staleness checks
Test-GitHubActionsForStaleness
Test-DockerImagesForStaleness
Test-ShellScriptsForStaleness

# Output results
Write-OutputResult -Dependencies $StaleDependencies -OutputFormat $OutputFormat -OutputPath $OutputPath

Write-SecurityLog "SHA staleness monitoring completed" -Level Success
Write-SecurityLog "Stale dependencies found: $($StaleDependencies.Count)" -Level Info

# Exit with appropriate code for CI/CD
if ($StaleDependencies.Count -gt 0) {
    exit 1  # Indicate issues found
}
else {
    exit 0  # All good
}
