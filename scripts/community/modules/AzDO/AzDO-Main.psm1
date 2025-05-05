# AzDO-Main.psm1
# Main processing functions for Azure DevOps

using module "./AzDO-Types.psm1"
using module "./AzDO-ReportTypes.psm1"

function Get-Report {
    <#
    .SYNOPSIS
    Retrieves and processes detailed pull request information from Azure DevOps.

    .DESCRIPTION
    This function handles the main workflow for collecting detailed pull request information.
    It can either fetch data from Azure DevOps API or use existing JSON data.

    .PARAMETER Organization
    The Azure DevOps organization name.

    .PARAMETER Project
    The Azure DevOps project name.

    .PARAMETER Repository
    The repository name in Azure DevOps.

    .PARAMETER ReportOutputPath
    The path where output files should be saved.

    .PARAMETER AuthHeader
    The authentication header for Azure DevOps API calls.

    .PARAMETER UseExistingJsonData
    Switch to load PR data from an existing JSON file instead of fetching from Azure DevOps.

    .PARAMETER JsonDataPath
    Optional path to the JSON file to load PR data from.

    .PARAMETER SLOHours
    The number of hours for the SLO window. Defaults to 48 hours.

    .OUTPUTS
    None. This function generates a markdown report file saved to the specified output path.

    .EXAMPLE
    Get-Report -Organization "MyOrg" -Project "MyProject" -Repository "MyRepo" -ReportOutputPath "./output" -AuthHeader $authHeader
    #>
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory=$true)]
        [string]$Organization,

        [Parameter(Mandatory=$true)]
        [string]$Project,

        [Parameter(Mandatory=$true)]
        [string]$Repository,

        [Parameter(Mandatory=$true)]
        [string]$ReportOutputPath,

        [Parameter(Mandatory=$true)]
        [hashtable]$AuthHeader,

        [Parameter(Mandatory=$false)]
        [switch]$UseExistingJsonData,

        [Parameter(Mandatory=$false)]
        [string]$JsonDataPath,

        [Parameter(Mandatory=$false)]
        [int]$SLOHours = 48
    )

    # Initialize the collection for PRs
    $enhancedPRs = @()

    # Only proceed with fetching from Azure DevOps if we haven't loaded from JSON
    if (-not $UseExistingJsonData) {

        # Step 1: Retrieve ALL pull request data
        Write-Host "Retrieving pull request data for project '$Project' in organization '$Organization'..." -ForegroundColor Cyan

        $azDOApiParameters = [AzDOApiParameters]::new($Organization, $Project, $Repository, $AuthHeader, "api-version=7.0")

        # Set the repository ID if provided
        $azDOApiParameters.RepositoryId = Get-RepositoryId -Params $azDOApiParameters

        # Get all basic PR information first
        Write-Host "Phase 1: Retrieving basic PR information..." -ForegroundColor Cyan
        $pullRequests = Get-PullRequestList -Params $azDOApiParameters

        # Removed null check for pullRequests - assume we always have PRs
        Write-Host "Retrieved $($pullRequests.Count) pull requests. Now collecting detailed information..." -ForegroundColor Green

        # Step 2: Collect detailed information for each PR sequentially
        Write-Host "Phase 2: Collecting detailed information for each PR..." -ForegroundColor Cyan
        $startTime = Get-Date

        # Process PRs sequentially with standard progress reporting
        $total = $pullRequests.Count
        $counter = 0

        foreach ($pr in $pullRequests) {
            # Update progress counter
            $counter++
            $percent = [Math]::Round(($counter / $total) * 100, 0)

            # Calculate ETA
            $elapsed = (Get-Date) - $startTime
            if ($counter -gt 1) {
                $estimatedTotal = $elapsed.TotalSeconds / ($counter - 1) * $total
                $remaining = $estimatedTotal - $elapsed.TotalSeconds
                if ($remaining -gt 0) {
                    Write-Progress -Activity "Collecting PR Details" -Status "$counter of $total PRs ($percent%)" -PercentComplete $percent -SecondsRemaining $remaining
                }
            }

            # Get detailed PR statistics with error handling
            try {
                $prId = $pr.pullRequestId

                # Get the repository path (current directory) for Git-based metrics fallback
                $repoPath = Get-Location

                Write-Verbose "Will use Git repository at $repoPath for fallback metrics if needed"

                # Get PR Commits
                [AzDOPullRequestCommit[]]$prCommits = Get-PullRequestCommitList -Params $azDOApiParameters -PullRequestId $pr.pullRequestId

                # Use Get-MainBranchPRMetric to get file changes, additions and deletions if the PR is completed
                if($pr.status -eq "completed") {
                    [PullRequestFileChangeMetric]$pullRequestFileChangeMetric = Get-MainBranchPRMetric -PullRequestId $pr.pullRequestId -PullRequestStatus $pr.status -PullRequestClosedDate $pr.ClosedDate -PullRequestTitle $pr.title -PullRequestSourceBranch $pr.SourceBranch -RepositoryPath $repoPath
                }

                # Get PR Work Items
                [AzDOWorkItem[]]$workItemDetails = Get-PullRequestWorkItemDetail -PullRequestId $pr.pullRequestId -Params $azDOApiParameters

                # Get PR Reviewers
                [AzDOPullRequestReviewer[]]$prReviewers = Get-PullRequestReviewerList -Params $azDOApiParameters -PullRequestId $pr.pullRequestId

                # Get Threads
                [AzDOPullRequestThread[]]$prThreads = Get-AzDOPullRequestThread -Params $azDOApiParameters -PullRequestId $pr.pullRequestId

                # Add PR plus all details to the enhancedPRs array
                $enhancedPR = [PSCustomObject]@{
                    # Basic PR information
                    ID = $prId
                    Title = $pr.Title
                    Description = $pr.Description
                    Status = $pr.Status
                    MergeStatus = $pr.MergeStatus
                    IsDraft = $pr.IsDraft
                    Url = $pr.Url

                    # Author information
                    CreatedBy = $pr.CreatedByDisplayName
                    CreatedById = $pr.CreatedById
                    CreatedByEmail = $pr.CreatedByEmail

                    # Timeline information
                    CreatedDate = $pr.CreationDate
                    ClosedDate = $pr.ClosedDate
                    LastUpdateTime = $pr.LastUpdateTime

                    # Repository & branch information
                    RepositoryId = $pr.RepositoryId
                    RepositoryName = $pr.RepositoryName
                    SourceBranch = $pr.SourceBranch
                    TargetBranch = $pr.TargetBranch

                    # PR content & details
                    Commits = $prCommits
                    LastMergeCommit = $pr.LastMergeCommit
                    WorkItems = $workItemDetails
                    Reviewers = $prReviewers
                    Threads = $prThreads
                    DetailedFiles = $pullRequestFileChangeMetric
                }
                $enhancedPRs += $enhancedPR
                Write-Verbose "Processed PR #$($prId) - $($pr.title) with $($pullRequestFileChangeMetric.Count) files changed."

            } catch {
                Write-Warning "Error processing PR $prId : $_"
            }
        }

        Write-Progress -Activity "Collecting PR Details" -Completed
        Write-Host "Detailed information collected for $($enhancedPRs.Count) pull requests in $([Math]::Round(((Get-Date) - $startTime).TotalMinutes, 2)) minutes." -ForegroundColor Green

        # Save PR data to JSON
        Write-Host "Phase 3: Saving PR data to JSON: $JsonDataPath" -ForegroundColor Cyan
        try {
            # Increase depth to 20 and ensure array structure is preserved
            $jsonContent = $enhancedPRs | ConvertTo-Json -Depth 20 -AsArray

            # Write to file with UTF8 encoding
            $jsonContent | Out-File -FilePath $JsonDataPath -Force -Encoding UTF8

            # Report file size as a data integrity check
            $fileSize = (Get-Item -Path $JsonDataPath).Length
            Write-Host "PR data successfully saved to JSON ($([Math]::Round($fileSize/1MB, 2)) MB) with $($enhancedPRs.Count) pull requests." -ForegroundColor Green
        } catch {
            Write-Error "Failed to save PR data to JSON: $_"
        }
    }

    # If we're using existing JSON data or if we've just created it and want to load it back
    if ($UseExistingJsonData -and (Test-Path -Path $JsonDataPath)) {
        Write-Host "Phase 4: Loading PR data from existing JSON file: $JsonDataPath" -ForegroundColor Cyan
        try {
            # Use -Raw to ensure the entire file is read as a single string for proper JSON parsing
            $enhancedPRs = Get-Content -Path $JsonDataPath -Raw | ConvertFrom-Json

            # Validate data integrity after loading
            $prCount = 0
            foreach ($pr in $enhancedPRs) {
                $prCount++
                # Log file associations to verify correct mapping
                Write-Verbose "PR #$($pr.ID) by $($pr.'Created By') has $($pr.DetailedFiles.Count) files"
            }

            Write-Host "Successfully loaded $prCount PRs from JSON file." -ForegroundColor Green
        } catch {
            Write-Error "Failed to load PR data from JSON file: $_"
            Write-Host "Falling back to fetching PR data from Azure DevOps." -ForegroundColor Yellow
        }
    } elseif ($UseExistingJsonData) {
        Write-Warning "JSON data file not found at: $JsonDataPath"
        Write-Host "Falling back to fetching PR data from Azure DevOps." -ForegroundColor Yellow
    }

    Write-Host "Phase 5: Generating report analytics..." -ForegroundColor Cyan

    # Initialize file extensions hashtable
    Write-Host "Generating local repository analytics..." -ForegroundColor Cyan
    $repoPath = Get-Location # Get the current repository path
    $mainBranchFileExtensions = Get-MainBranchFileExtension -RepoPath $repoPath
    if ($null -eq $mainBranchFileExtensions) {
        Write-Warning "No file extension data retrieved from the local repository"
        $mainBranchFileExtensions = @{} # Initialize empty hashtable to avoid null
    }

    # Process the file extensions to get metrics
    $fileExtensions = Get-FileExtensionMetric -PullRequests $enhancedPRs -FileExtensions $mainBranchFileExtensions
    $fileExtensionSummary = Get-FileExtensionSummary -FileExtensions $fileExtensions

    # Get the industry backlog data
    Write-Host "Retrieving industry backlog data..." -ForegroundColor Cyan
    # Call Get-IndustryBacklogItemsFromAzDO directly
    $industryBacklogHierarchy = Get-IndustryBacklogItemsFromAzDO -Organization $Organization -Project $Project -AuthHeader $AuthHeader

    # Generate the Sankey visualization - always assume we have sufficient data
    [IndustryBacklogSankey]$industryBacklogSankeyData = Get-BacklogHierarchySankeyObject -BacklogCollection $industryBacklogHierarchy
    Write-Host "Generated Sankey data with $($industryBacklogSankeyData.Nodes.Count) nodes and $($industryBacklogSankeyData.Links.Count) links"

    # Calculate report summary using the data processing function
    $reportSummary = Get-AzDOReportSummary -PullRequests $enhancedPRs
    Write-Verbose "Report summary generated: $($reportSummary.CompletedCount) completed, $($reportSummary.ActiveCount) active, $($reportSummary.AbandonedCount) abandoned"

    # Calculate monthly PR metrics
    $monthlyPRMetrics = Get-PRMonthlyMetric -PullRequests $enhancedPRs
    $createdPRsData = $monthlyPRMetrics.CreatedPRs
    $completedPRsData = $monthlyPRMetrics.CompletedPRs

    # Calculate weekly completion metrics
    $weeklyCompletionMetrics = Get-PRWeeklyMetric -PullRequests $enhancedPRs

    # Calculate PR Size metrics
    $prSizeMetrics = Get-PRSizeMetric -PullRequests $enhancedPRs

    # Calculate PR completion time distribution
    $prCompletionTimeDistribution = Get-PRCompletionTimeDistribution -PullRequests $enhancedPRs
    $underOneDayCount = $prCompletionTimeDistribution.UnderOneDayCount
    $oneToThreeDaysCount = $prCompletionTimeDistribution.OneToThreeDaysCount
    $fourToSevenDaysCount = $prCompletionTimeDistribution.FourToSevenDaysCount
    $overSevenDaysCount = $prCompletionTimeDistribution.OverSevenDaysCount

    # Interval metrics object
    $metricsData = [PRMetricsIntervalData]::new(
        $createdPRsData,
        $completedPRsData,
        $weeklyCompletionMetrics,
        $prSizeMetrics,
        $underOneDayCount,
        $oneToThreeDaysCount,
        $fourToSevenDaysCount,
        $overSevenDaysCount
    )

    # Calculate SLO compliance metrics
    Write-Host "Calculating First Response SLO metrics ($SLOHours hour window)..." -ForegroundColor Cyan
    $sloComplianceData = Get-PRFirstResponseSLOMetric -PullRequests $enhancedPRs -SLOHours $SLOHours
    Write-Verbose "Generated SLO metrics for $($sloComplianceData.Count) weeks"

    # Calculate PR complexity metrics for chart visualization
    Write-Host "Calculating PR complexity metrics for charts..." -ForegroundColor Cyan
    $complexityChartData = Get-PRComplexityChartData -PullRequests $enhancedPRs
    Write-Verbose "Generated complexity metrics for $($complexityChartData.Months.Count) months"

    # Calculate contributor metrics (new vs. returning contributors)
    Write-Host "Calculating contributor metrics..." -ForegroundColor Cyan
    $contributorReturnMetrics = Get-ContributorReturnMetric -PullRequests $enhancedPRs -MonthsToInclude 7
    Write-Verbose "Generated contributor metrics for $($contributorReturnMetrics.Months.Count) months"

    # Calculate GitHub Copilot impact metrics
    Write-Host "Calculating GitHub Copilot impact metrics..." -ForegroundColor Cyan
    $copilotImpactData = Get-CopilotImpactMetric -PullRequests $enhancedPRs -AdoptionDate ([DateTime]::Parse("2025-02-25"))
    Write-Verbose "Generated Copilot impact metrics: $($copilotImpactData.FilesChangedPercentChange)% change in files changed"

    # Create a ContributorMetrics[] object with properly typed ContributorMetrics objects
    [ContributorMetrics[]]$contributorMetrics = Get-ContributorMetricData -PullRequests $enhancedPRs

    # Create a ReviewerMetrics[] object with properly typed ReviewerMetrics objects
    [ReviewerMetrics[]]$reviewerMetrics = Get-ReviewerMetricData -PullRequests $enhancedPRs
    Write-Host "Generated reviewer metrics for $($reviewerMetrics.Count) reviewers"

    # Calculate focus area metrics
    Write-Host "Calculating focus area metrics..." -ForegroundColor Cyan
    $focusAreaMetrics = Get-FocusAreaMetric -PullRequests $enhancedPRs -FileExtensions $mainBranchFileExtensions -MonthsToInclude 8

    Write-Host "Phase 6: Generating Markdown report..." -ForegroundColor Cyan

    # Generate the markdown report by calling functions in the right order
    $markdownParts = @()

    # 1. Report Header
    $markdownParts += Get-ReportHeader -ReportTitle "Pull Request Analysis for edge-ai" -Project "edge-ai" -Organization "ai-at-the-edge-flagship-accelerator"

    # 2. Summary statistics
    $markdownParts += Get-ReportSummary -Summary $reportSummary

    # 3. PR Metrics by Interval
    $markdownParts += Get-PRMetricsByInterval -MetricsData $metricsData

    # 4. SLO Compliance Trend
    $markdownParts += Get-SLOComplianceTableContent -SLOComplianceData $sloComplianceData -SLOHours $SLOHours -WeeklyCompletionMetrics $weeklyCompletionMetrics

    # 5. GitHub Copilot Impact with PR Complexity Chart
    # Pass the adoption date explicitly to avoid null error
    $markdownParts += Get-CopilotImpactSection -ImpactData $copilotImpactData -ComplexityChartData $complexityChartData -AdoptionDate ([DateTime]::Parse("2025-02-25"))

    # 6. Contributor Trends - Use properly typed object
    $markdownParts += Get-ContributorSummary -Contributors $contributorMetrics -ContributorReturnMetrics $contributorReturnMetrics -ReviewerMetrics $reviewerMetrics

    # 7. File Types
    $markdownParts += Format-FileExtensionTable -Summary $fileExtensionSummary

    # 8. Focus Area Section - Ensure the chart data is not null
    $markdownParts += Get-FocusAreaSection -FocusAreaMetrics $focusAreaMetrics

    # 9. Industry Backlog Sankey Diagram
    # Generate the Sankey diagram section using the converted data
    $markdownParts += Get-IndustryBacklogSankeySection -SankeyData $industryBacklogSankeyData

    # 10. Report Footer
    $markdownParts += Get-ReportFooter -CompletedCount $reportSummary.CompletedCount -ActiveCount $reportSummary.ActiveCount -AbandonedCount $reportSummary.AbandonedCount -Project "edge-ai"

    # Join all parts and save to markdown file
    $mdPath = Join-Path -Path $ReportOutputPath -ChildPath "contributions.md"
    $mdContent = $markdownParts -join "`n`n"

    # Save markdown content to file
    try {
        $mdContent | Out-File -FilePath $mdPath -Force -Encoding UTF8
        Write-Host "Successfully generated markdown report: $mdPath" -ForegroundColor Green
    }
    catch {
        Write-Error "Failed to save markdown report: $_"
    }

    Write-Host "Analysis complete! Output files are available in: $ReportOutputPath" -ForegroundColor Green
    Write-Host "Contribution report is available at: $mdPath" -ForegroundColor Green

    # Run markdown-table-formatter to format the markdown tables in the report
    try {
        # Check if markdown-table-formatter is available
        $mdTableFormatterExists = npm list -g markdown-table-formatter 2>$null

        if (-not $mdTableFormatterExists) {
            Write-Host "markdown-table-formatter not found. Installing globally..." -ForegroundColor Yellow
            npm install -g markdown-table-formatter
        }

        # Run the formatter on the markdown file
        Write-Host "Formatting tables in the markdown report..." -ForegroundColor Cyan
        npx markdown-table-formatter $mdPath
        Write-Host "Tables formatted successfully." -ForegroundColor Green
    }
    catch {
        Write-Warning "Failed to run markdown-table-formatter: $_"
        Write-Host "You can manually format tables by installing markdown-table-formatter: npm install -g markdown-table-formatter" -ForegroundColor Yellow
    }
}

# Export all functions
Export-ModuleMember -Function Get-Report
