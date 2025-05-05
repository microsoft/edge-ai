function Get-FileExtensionMetric {
    <#
    .SYNOPSIS
    Analyzes file extensions from pull requests to categorize them by technology type.

    .DESCRIPTION
    This function processes pull request data to extract file extensions and categorize
    them into technology types such as Documentation, PowerShell, Python, etc.
    It returns an array of FileExtensionData objects with detailed metrics.

    .PARAMETER PullRequests
    An array of pull request objects with detailed statistics, including file information.

    .PARAMETER FileExtensions
    Optional hashtable with pre-populated file extension data from the main branch.

    .EXAMPLE
    $fileExtensionData = Get-FileExtensionMetric -PullRequests $prs -FileExtensions $mainBranchExtensions

    .NOTES
    This function categorizes files based on their extensions and returns structured metrics.
    #>
    [CmdletBinding()]
    [OutputType([FileExtensionData[]])]
    param(
        [Parameter(Mandatory=$true)]
        [array]$PullRequests,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$FileExtensions
    )

    # Create a hashtable for tracking PR file changes by category
    $prChanges = @{}

    # Process each PR to categorize file extensions
    foreach ($pr in $PullRequests) {
        if ($null -ne $pr -and $null -ne $pr.DetailedFiles) {
            # Handle different property structures that might exist for file details
            $files = $null
            if ($null -ne $pr.DetailedFiles.DetailedFiles) {
                $files = $pr.DetailedFiles.DetailedFiles
            }
            elseif ($null -ne $pr.DetailedFiles.Items) {
                $files = $pr.DetailedFiles.Items
            }
            elseif ($pr.DetailedFiles -is [System.Collections.IEnumerable] -and
                   -not ($pr.DetailedFiles -is [string])) {
                $files = $pr.DetailedFiles
            }

            if ($null -ne $files) {
                foreach ($file in $files) {
                    # Get file path, handling different possible structures
                    $filePath = $null
                    if ($file -is [string]) {
                        $filePath = $file
                    }
                    elseif ($null -ne $file.Path) {
                        $filePath = $file.Path
                    }
                    elseif ($null -ne $file.FilePath) {
                        $filePath = $file.FilePath
                    }

                    if ($filePath) {
                        $extension = [System.IO.Path]::GetExtension($filePath)
                        if ([string]::IsNullOrEmpty($extension)) { continue }

                        $category = switch -Regex ($extension.ToLower()) {
                            '\.md$' { "Documentation (Markdown)" }
                            '\.ps1$|\.psm1$|\.psd1$' { "PowerShell" }
                            '\.py$' { "Python" }
                            '\.tf$|\.tfvars$|\.hcl$' { "Terraform" }
                            '\.bicep$|\.bicepparam$|\.json$' { "Bicep/ARM Templates" }
                            '\.tsx$|\.ts$' { "TypeScript" }
                            '\.jsx$|\.js$' { "JavaScript" }
                            '\.java$' { "Java" }
                            '\.cs$' { "C#" }
                            '\.go$' { "Go" }
                            '\.rs$' { "Rust" }
                            '\.cpp$|\.h$|\.hpp$' { "C/C++" }
                            '\.yaml$|\.yml$' { "YAML" }
                            '\.sh$|\.bash$' { "Shell Scripts" }
                            '\.sql$' { "SQL" }
                            '\.css$|\.scss$|\.sass$' { "CSS/SCSS" }
                            '\.html$|\.htm$' { "HTML" }
                            '\.dockerfile$|dockerfile|docker-compose\.ya?ml$' { "Docker" }
                            default { "Other" }
                        }

                        if (-not $prChanges.ContainsKey($category)) {
                            $prChanges[$category] = 0
                        }
                        $prChanges[$category]++
                    }
                }
            }
        }
    }

    # Calculate total PR changes
    $totalPRChanges = ($prChanges.Values | Measure-Object -Sum).Sum
    if ($totalPRChanges -eq 0) { $totalPRChanges = 1 } # Avoid division by zero

    # Calculate total branch files
    $totalBranchFiles = ($FileExtensions.Values | Measure-Object -Sum).Sum
    if ($totalBranchFiles -eq 0) { $totalBranchFiles = 1 } # Avoid division by zero

    # Create FileExtensionData objects for each category
    $result = @()

    # Process file extensions from both branch files and PR changes
    $allCategories = @($FileExtensions.Keys) + @($prChanges.Keys) | Select-Object -Unique | Sort-Object

    foreach ($category in $allCategories) {
        $branchCount = if ($FileExtensions.ContainsKey($category)) { $FileExtensions[$category] } else { 0 }
        $prCount = if ($prChanges.ContainsKey($category)) { $prChanges[$category] } else { 0 }

        # Calculate percentages with 1 decimal place, formatting as strings with % sign
        $percentOfFiles = "{0:F1}%" -f (($branchCount / $totalBranchFiles) * 100)
        $percentOfChanges = "{0:F1}%" -f (($prCount / $totalPRChanges) * 100)

        # Create and add the FileExtensionData object
        $extensionData = [FileExtensionData]::new(
            $category,
            $branchCount,
            $percentOfFiles,
            $prCount,
            $percentOfChanges
        )

        $result += $extensionData
    }

    # Sort by PR changes count in descending order
    $result = $result | Sort-Object -Property PRChangesCount -Descending

    return $result
}

function Get-FileExtensionSummary {
    <#
    .SYNOPSIS
    Creates a FileExtensionSummary object from file extension data.

    .DESCRIPTION
    This function takes an array of FileExtensionData objects and calculates totals
    for branch files and PR changes, then returns a structured FileExtensionSummary object.

    .PARAMETER FileExtensions
    An array of FileExtensionData objects containing file extension metrics.

    .OUTPUTS
    FileExtensionSummary. Returns a FileExtensionSummary object containing the array of
    extensions plus totals for files and changes.

    .EXAMPLE
    $fileExtensionData = Get-FileExtensionMetric -PullRequests $prs -FileExtensions $mainBranchExtensions
    $summary = Get-FileExtensionSummary -FileExtensions $fileExtensionData
    #>
    [CmdletBinding()]
    [OutputType([FileExtensionSummary])]
    param(
        [Parameter(Mandatory=$true)]
        [FileExtensionData[]]$FileExtensions
    )

    Write-Verbose "Starting Get-FileExtensionSummary with ${$FileExtensions.Count} file extension entries"

    # Calculate totals for branch files and PR changes
    $totalBranchFiles = 0
    $totalPRChanges = 0

    foreach ($extension in $FileExtensions) {
        # Handle both string and integer property types for CurrentBranchFiles
        if ($extension.CurrentBranchFiles -is [int]) {
            $totalBranchFiles += $extension.CurrentBranchFiles
        }
        elseif ($extension.CurrentBranchFiles -is [string] -and $extension.CurrentBranchFiles -match '^\d+$') {
            $totalBranchFiles += [int]$extension.CurrentBranchFiles
        }

        $totalPRChanges += $extension.PRChangesCount
    }

    Write-Verbose "Calculated totals: Branch files: $totalBranchFiles, PR changes: $totalPRChanges"

    # Create and return the FileExtensionSummary object
    $summary = [FileExtensionSummary]::new($FileExtensions, $totalBranchFiles, $totalPRChanges)

    Write-Verbose "FileExtensionSummary created with ${$FileExtensions.Count} extensions"
    return $summary
}

function Get-AzDOReportSummary {
    <#
    .SYNOPSIS
    Generates aggregate statistics from pull request data and returns an AzDOReportSummary object.

    .DESCRIPTION
    This function processes enhanced pull request data to calculate key metrics including
    PR counts by status, average time to completion, and unique contributor counts.

    .PARAMETER PullRequests
    An array of enhanced pull request objects containing detailed PR information.

    .EXAMPLE
    $reportSummary = Get-AzDOReportSummary -PullRequests $enhancedPRs

    .NOTES
    The returned AzDOReportSummary object contains the following properties:
    - CompletedCount: Number of completed PRs
    - ActiveCount: Number of active PRs
    - AbandonedCount: Number of abandoned PRs
    - AvgDaysToComplete: Average days to complete PRs
    - TotalContributors: Total unique contributors
    #>
    [CmdletBinding()]
    [OutputType([AzDOReportSummary])]
    param(
        [Parameter(Mandatory=$true)]
        [array]$PullRequests
    )

    Write-Verbose "Starting Get-AzDOReportSummary function with ${$PullRequests.Count} pull requests"

    # Initialize counters and collections
    $completedCount = 0
    $activeCount = 0
    $abandonedCount = 0
    $totalDaysToComplete = 0
    $completedWithValidDates = 0
    $uniqueContributors = @{}

    # Process each PR to collect statistics
    foreach ($pr in $PullRequests) {
        # Skip null PRs
        if ($null -eq $pr) { continue }

        # Count PRs by status
        switch ($pr.Status) {
            "completed" { $completedCount++ }
            "active" { $activeCount++ }
            "abandoned" { $abandonedCount++ }
            # Default case handles any other statuses
            default {
                Write-Verbose "PR #$($pr.ID) has unexpected status: $($pr.Status)"
            }
        }

        # Calculate completion time for completed PRs
        if ($pr.Status -eq "completed" -and $pr.ClosedDate -and $pr.CreatedDate) {
            try {
                # Ensure dates are DateTime objects before calculating difference
                $closedDate = if ($pr.ClosedDate -is [DateTime]) { $pr.ClosedDate } else { [DateTime]::Parse($pr.ClosedDate) }
                $createdDate = if ($pr.CreatedDate -is [DateTime]) { $pr.CreatedDate } else { [DateTime]::Parse($pr.CreatedDate) }

                $daysToComplete = ($closedDate - $createdDate).TotalDays

                # Only count realistic completion times (avoid negative values or unreasonably high ones)
                if ($daysToComplete -ge 0 -and $daysToComplete -lt 365) {
                    $totalDaysToComplete += $daysToComplete
                    $completedWithValidDates++
                    Write-Verbose "PR #$($pr.ID) took $daysToComplete days to complete"
                }
            }
            catch {
                Write-Verbose "Error calculating completion time for PR #$($pr.ID): $_"
            }
        }

        # Track unique contributors (by ID and by email to catch all cases)
        if (-not [string]::IsNullOrEmpty($pr.CreatedById)) {
            $uniqueContributors[$pr.CreatedById] = $true
        }
        elseif (-not [string]::IsNullOrEmpty($pr.CreatedByEmail)) {
            $uniqueContributors[$pr.CreatedByEmail] = $true
        }
        elseif (-not [string]::IsNullOrEmpty($pr.CreatedBy)) {
            $uniqueContributors[$pr.CreatedBy] = $true
        }
    }

    # Calculate average days to complete
    $avgDaysToComplete = if ($completedWithValidDates -gt 0) {
        [Math]::Round($totalDaysToComplete / $completedWithValidDates, 2)
    } else {
        0
    }

    # Count unique contributors
    $totalContributors = $uniqueContributors.Count

    Write-Verbose "Report summary: Completed=$completedCount, Active=$activeCount, Abandoned=$abandonedCount, AvgDays=$avgDaysToComplete, Contributors=$totalContributors"

    # Create and return AzDOReportSummary object
    return [AzDOReportSummary]::new(
        $completedCount,
        $activeCount,
        $abandonedCount,
        $avgDaysToComplete,
        $totalContributors
    )
}

function Get-PRMonthlyMetric {
    <#
    .SYNOPSIS
    Calculates monthly PR creation and completion metrics for reporting and charting.

    .DESCRIPTION
    This function processes pull request data to generate monthly metrics showing
    the number of PRs created and completed each month. The results are structured
    for visualization in charts and reports.

    .PARAMETER PullRequests
    An array of pull request objects containing at minimum CreatedDate, ClosedDate, and Status properties.

    .PARAMETER MonthsToInclude
    Optional. The number of months to include in the analysis, counting backward from the current month.
    Default is 6 months.

    .EXAMPLE
    $monthlyMetrics = Get-PRMonthlyMetric -PullRequests $enhancedPRs -MonthsToInclude 12
    $createdData = $monthlyMetrics.CreatedPRs
    $completedData = $monthlyMetrics.CompletedPRs

    .OUTPUTS
    Returns a PSCustomObject with two ChartData properties:
    - CreatedPRs: ChartData object for PRs created each month
    - CompletedPRs: ChartData object for PRs completed each month

    Each ChartData object contains Labels (month names) and Values (PR counts) arrays.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$true)]
        [PSObject[]]$PullRequests,

        [Parameter(Mandatory=$false)]
        [int]$MonthsToInclude = 6
    )

    # Get current date for reference
    $currentDate = Get-Date

    # Create hashtables to store PR counts by month
    $createdByMonth = @{}
    $completedByMonth = @{}

    # Initialize the hashtables with zeros for the last N+1 months
    for ($i = $MonthsToInclude; $i -ge 0; $i--) {
        $monthDate = $currentDate.AddMonths(-$i)
        $monthKey = $monthDate.ToString("MMM yyyy")
        $createdByMonth[$monthKey] = 0
        $completedByMonth[$monthKey] = 0
    }

    # Count PRs by month
    foreach ($pr in $PullRequests) {
        # Skip null PRs
        if ($null -eq $pr) { continue }

        # Get creation date and format as month key
        if ($pr.CreatedDate) {
            try {
                $creationDate = [DateTime]$pr.CreatedDate
                $creationMonthKey = $creationDate.ToString("MMM yyyy")

                # Only count if within our time window
                if ($createdByMonth.ContainsKey($creationMonthKey)) {
                    $createdByMonth[$creationMonthKey]++
                }
            }
            catch {
                Write-Warning "Error processing creation date for PR $($pr.ID): $_"
            }
        }

        # Get completion date and format as month key
        if ($pr.Status -eq "completed" -and $pr.ClosedDate) {
            try {
                $closedDate = [DateTime]$pr.ClosedDate
                $closedMonthKey = $closedDate.ToString("MMM yyyy")

                # Only count if within our time window
                if ($completedByMonth.ContainsKey($closedMonthKey)) {
                    $completedByMonth[$closedMonthKey]++
                }
            }
            catch {
                Write-Warning "Error processing completion date for PR $($pr.ID): $_"
            }
        }
    }

    # Convert hashtables to arrays for ChartData objects
    $monthLabels = $createdByMonth.Keys | Sort-Object {
        [DateTime]::ParseExact($_, "MMM yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
    }
    $createdCounts = @()
    $completedCounts = @()

    foreach ($month in $monthLabels) {
        $createdCounts += $createdByMonth[$month]
        $completedCounts += $completedByMonth[$month]
    }

    # Create ChartData objects
    $createdPRsData = [ChartData]::new($monthLabels, $createdCounts)
    $completedPRsData = [ChartData]::new($monthLabels, $completedCounts)

    return [PSCustomObject]@{
        CreatedPRs = $createdPRsData
        CompletedPRs = $completedPRsData
    }
}

function Get-PRWeeklyMetric {
    <#
    .SYNOPSIS
    Calculates weekly PR completion metrics for reporting.

    .DESCRIPTION
    This function processes pull request data to group completed PRs by week,
    returning a ChartData object with week numbers and PR completion counts.

    .PARAMETER PullRequests
    An array of pull request objects with detailed statistics.

    .PARAMETER WeeksToInclude
    Optional. Number of previous weeks to include in the analysis. Default is 34 (since beginning of October 2023).

    .EXAMPLE
    $weeklyMetrics = Get-PRWeeklyMetric -PullRequests $prs -WeeksToInclude 12

    .NOTES
    Week numbers are formatted as two-digit numbers (01, 02, etc.) for consistent display.
    #>
    [CmdletBinding()]
    [OutputType([ChartData])]
    param(
        [Parameter(Mandatory=$true)]
        [PSObject[]]$PullRequests,

        [Parameter(Mandatory=$false)]
        [int]$WeeksToInclude = 34
    )

    # Get current date for reference point
    $today = Get-Date
    $culture = Get-Culture

    # Create hashtable to store PR counts by year-week combination
    $completedByYearWeek = @{}

    # Find the earliest date to include in analysis based on WeeksToInclude
    $earliestDate = $today.AddDays(-($WeeksToInclude * 7))

    # Initialize hashtable with zeros for weeks within our time window
    $tempDate = $earliestDate
    while ($tempDate -le $today) {
        $year = $tempDate.Year
        $weekNumber = $culture.Calendar.GetWeekOfYear(
            $tempDate,
            [System.Globalization.CalendarWeekRule]::FirstDay,
            [DayOfWeek]::Monday
        )

        # Create year-week key for sorting (formatted for display as "ww")
        $yearWeekKey = "$weekNumber".PadLeft(2, '0')

        # Store the year for sorting later
        if (-not $completedByYearWeek.ContainsKey($yearWeekKey)) {
            $completedByYearWeek[$yearWeekKey] = @{
                Year = $year
                Count = 0
            }
        }

        $tempDate = $tempDate.AddDays(7)
    }

    Write-Verbose "Analyzing completed PRs by week (past $WeeksToInclude weeks)"

    # Count completed PRs by week
    foreach ($pr in $PullRequests) {
        # Skip null PRs or non-completed PRs
        if ($null -eq $pr -or $pr.Status -ne "completed" -or $null -eq $pr.ClosedDate) {
            continue
        }

        try {
            # Parse the closed date
            $closedDate = if ($pr.ClosedDate -is [DateTime]) {
                $pr.ClosedDate
            } else {
                [DateTime]::Parse($pr.ClosedDate)
            }

            # Only count if within our time window
            if ($closedDate -ge $earliestDate -and $closedDate -le $today) {
                $year = $closedDate.Year
                $weekNumber = $culture.Calendar.GetWeekOfYear(
                    $closedDate,
                    [System.Globalization.CalendarWeekRule]::FirstDay,
                    [DayOfWeek]::Monday
                )

                $yearWeekKey = "$weekNumber".PadLeft(2, '0')

                # Add to our tracking if not already there
                if (-not $completedByYearWeek.ContainsKey($yearWeekKey)) {
                    $completedByYearWeek[$yearWeekKey] = @{
                        Year = $year
                        Count = 0
                    }
                }

                $completedByYearWeek[$yearWeekKey].Count++
                Write-Verbose "PR #$($pr.ID) completed in week $yearWeekKey of $year"
            }
        }
        catch {
            Write-Warning "Error processing completion date for PR $($pr.ID): $_"
        }
    }

    # Sort keys chronologically by year then by week number
    $sortedWeekKeys = $completedByYearWeek.Keys | Sort-Object {
        $weekKey = $_
        $year = $completedByYearWeek[$weekKey].Year
        "$year$weekKey" # Format: "YYYYWW"
    }

    # Extract values for ChartData
    $weekLabels = $sortedWeekKeys
    $completionCounts = @()

    foreach ($week in $weekLabels) {
        $completionCounts += $completedByYearWeek[$week].Count
        Write-Verbose "Week $week (Year: $($completedByYearWeek[$week].Year)): $($completedByYearWeek[$week].Count) PRs completed"
    }

    # Return as ChartData object
    return [ChartData]::new($weekLabels, $completionCounts)
}

function Get-PRSizeMetric {
    <#
    .SYNOPSIS
    Calculates metrics related to PR size based on file counts and completion times.

    .DESCRIPTION
    This function analyzes pull request data to categorize PRs by size (small, medium, large)
    based on number of files changed, then calculates the average time to completion for each size category.

    Small PRs: ≤5 files
    Medium PRs: 6-20 files
    Large PRs: >20 files

    .PARAMETER PullRequests
    An array of pull request objects with detailed statistics.

    .EXAMPLE
    $prSizeMetrics = Get-PRSizeMetric -PullRequests $enhancedPRs

    .NOTES
    Returns a PRSizeMetricsData object with average completion times for each PR size category.
    #>
    [CmdletBinding()]
    [OutputType([PRSizeMetricsData])]
    param(
        [Parameter(Mandatory=$true)]
        [PSObject[]]$PullRequests
    )

    # Initialize counters and accumulators for each size category
    $smallPRCount = 0
    $smallPRTotalDays = 0
    $mediumPRCount = 0
    $mediumPRTotalDays = 0
    $largePRCount = 0
    $largePRTotalDays = 0

    Write-Verbose "Analyzing PR completion times by size category"

    # Process each PR to categorize by size and calculate completion time
    foreach ($pr in $PullRequests) {
        # Skip null PRs or non-completed PRs
        if ($null -eq $pr -or $pr.Status -ne "completed" -or $null -eq $pr.ClosedDate -or $null -eq $pr.CreatedDate) {
            continue
        }

        # Get file count from DetailedFiles if available
        $fileCount = 0
        if ($null -ne $pr.DetailedFiles -and $null -ne $pr.DetailedFiles.DetailedFiles) {
            $fileCount = $pr.DetailedFiles.DetailedFiles.Count
        }
        elseif ($null -ne $pr.DetailedFiles -and $null -ne $pr.DetailedFiles.Count) {
            # Alternative property path
            $fileCount = $pr.DetailedFiles.Count
        }

        # If we couldn't get file count, try to use commit data
        if ($fileCount -eq 0 -and $null -ne $pr.Commits) {
            # Sum up file changes across all commits, removing duplicates
            $fileChanges = @{}
            foreach ($commit in $pr.Commits) {
                if ($null -ne $commit.Changes) {
                    foreach ($change in $commit.Changes) {
                        if (-not [string]::IsNullOrEmpty($change.Item.Path)) {
                            $fileChanges[$change.Item.Path] = $true
                        }
                    }
                }
            }
            $fileCount = $fileChanges.Count
        }

        # Skip if we still don't have a valid file count
        if ($fileCount -eq 0) {
            Write-Verbose "PR #$($pr.ID): Skipping due to no file count information"
            continue
        }

        try {
            # Calculate days to complete
            $closedDate = if ($pr.ClosedDate -is [DateTime]) { $pr.ClosedDate } else { [DateTime]::Parse($pr.ClosedDate) }
            $createdDate = if ($pr.CreatedDate -is [DateTime]) { $pr.CreatedDate } else { [DateTime]::Parse($pr.CreatedDate) }

            $daysToComplete = ($closedDate - $createdDate).TotalDays

            # Only count realistic completion times (avoid negative values or unreasonably high ones)
            if ($daysToComplete -ge 0 -and $daysToComplete -lt 365) {
                # Categorize by size and accumulate completion time
                if ($fileCount -le 5) {
                    $smallPRCount++
                    $smallPRTotalDays += $daysToComplete
                    Write-Verbose "PR #$($pr.ID): Small ($fileCount files), $daysToComplete days to complete"
                }
                elseif ($fileCount -le 20) {
                    $mediumPRCount++
                    $mediumPRTotalDays += $daysToComplete
                    Write-Verbose "PR #$($pr.ID): Medium ($fileCount files), $daysToComplete days to complete"
                }
                else {
                    $largePRCount++
                    $largePRTotalDays += $daysToComplete
                    Write-Verbose "PR #$($pr.ID): Large ($fileCount files), $daysToComplete days to complete"
                }
            }
        }
        catch {
            Write-Warning "Error processing PR #$($pr.ID): $_"
        }
    }

    # Calculate averages for each size category
    $smallPRAvgTime = if ($smallPRCount -gt 0) {
        [Math]::Round($smallPRTotalDays / $smallPRCount, 1)
    } else { 0 }

    $mediumPRAvgTime = if ($mediumPRCount -gt 0) {
        [Math]::Round($mediumPRTotalDays / $mediumPRCount, 1)
    } else { 0 }

    $largePRAvgTime = if ($largePRCount -gt 0) {
        [Math]::Round($largePRTotalDays / $largePRCount, 1)
    } else { 0 }

    Write-Verbose "PR Size Metrics: Small PRs: $smallPRCount (avg $smallPRAvgTime days), Medium PRs: $mediumPRCount (avg $mediumPRAvgTime days), Large PRs: $largePRCount (avg $largePRAvgTime days)"

    # If we have no data, provide reasonable defaults
    if ($smallPRCount -eq 0 -and $mediumPRCount -eq 0 -and $largePRCount -eq 0) {
        Write-Warning "No valid PR size data found, using default values"
        return [PRSizeMetricsData]::new(2.1, 4.3, 7.5)
    }

    # Create and return PRSizeMetricsData object
    return [PRSizeMetricsData]::new($smallPRAvgTime, $mediumPRAvgTime, $largePRAvgTime)
}

function Get-PRCompletionTimeDistribution {
    <#
    .SYNOPSIS
    Calculates the distribution of PR completion times across different time ranges.

    .DESCRIPTION
    This function analyzes completed pull requests and categorizes them into four time ranges:
    - Under 1 day
    - 1-3 days
    - 4-7 days
    - Over 7 days

    It returns an object with counts for each category to help visualize PR completion efficiency.

    .PARAMETER PullRequests
    An array of pull request objects with detailed statistics.

    .EXAMPLE
    $timeDistribution = Get-PRCompletionTimeDistribution -PullRequests $enhancedPRs

    .NOTES
    Only considers completed PRs with valid creation and completion dates.
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory=$true)]
        [PSObject[]]$PullRequests
    )

    # Initialize counters for each time range
    $underOneDayCount = 0
    $oneToThreeDaysCount = 0
    $fourToSevenDaysCount = 0
    $overSevenDaysCount = 0

    Write-Verbose "Analyzing PR completion time distribution"

    # Process each PR to determine its completion time category
    foreach ($pr in $PullRequests) {
        # Skip null PRs or non-completed PRs
        if ($null -eq $pr -or $pr.Status -ne "completed" -or $null -eq $pr.ClosedDate -or $null -eq $pr.CreatedDate) {
            continue
        }

        try {
            # Calculate days to complete
            $closedDate = if ($pr.ClosedDate -is [DateTime]) { $pr.ClosedDate } else { [DateTime]::Parse($pr.ClosedDate) }
            $createdDate = if ($pr.CreatedDate -is [DateTime]) { $pr.CreatedDate } else { [DateTime]::Parse($pr.CreatedDate) }

            $daysToComplete = ($closedDate - $createdDate).TotalDays

            # Only count realistic completion times (avoid negative values or unreasonably high ones)
            if ($daysToComplete -ge 0 -and $daysToComplete -lt 365) {
                # Categorize based on completion time
                if ($daysToComplete -lt 1) {
                    $underOneDayCount++
                    Write-Verbose "PR #$($pr.ID) completed in less than 1 day ($($daysToComplete.ToString("F1")) days)"
                }
                elseif ($daysToComplete -le 3) {
                    $oneToThreeDaysCount++
                    Write-Verbose "PR #$($pr.ID) completed in 1-3 days ($($daysToComplete.ToString("F1")) days)"
                }
                elseif ($daysToComplete -le 7) {
                    $fourToSevenDaysCount++
                    Write-Verbose "PR #$($pr.ID) completed in 4-7 days ($($daysToComplete.ToString("F1")) days)"
                }
                else {
                    $overSevenDaysCount++
                    Write-Verbose "PR #$($pr.ID) completed in over 7 days ($($daysToComplete.ToString("F1")) days)"
                }
            }
        }
        catch {
            Write-Warning "Error processing completion time for PR #$($pr.ID): $_"
        }
    }

    Write-Verbose "PR Completion Time Distribution: <1 day: $underOneDayCount, 1-3 days: $oneToThreeDaysCount, 4-7 days: $fourToSevenDaysCount, >7 days: $overSevenDaysCount"

    # Return a PSCustomObject with the counts for each category
    return [PSCustomObject]@{
        UnderOneDayCount = $underOneDayCount
        OneToThreeDaysCount = $oneToThreeDaysCount
        FourToSevenDaysCount = $fourToSevenDaysCount
        OverSevenDaysCount = $overSevenDaysCount
    }
}

function Get-PRFirstResponseSLOMetric {
    <#
    .SYNOPSIS
    Calculates weekly SLO compliance metrics for first response time to pull requests.

    .DESCRIPTION
    This function analyzes PRs to determine if they received their first response within
    the SLO period (48 hours by default). It tracks reviewer votes and thread comments
    to determine the first engagement time, filtering out automated system comments.

    .PARAMETER PullRequests
    An array of pull request objects with details including creation date, threads, and reviewers.

    .PARAMETER SLOHours
    The number of hours within which a PR should receive its first response (default: 48).

    .EXAMPLE
    $sloMetrics = Get-PRFirstResponseSLOMetric -PullRequests $enhancedPRs -SLOHours 48

    .OUTPUTS
    Returns an array of SLOComplianceItem objects representing weekly SLO metrics.
    #>
    [CmdletBinding()]
    [OutputType([SLOComplianceItem[]])]
    param (
        [Parameter(Mandatory = $true)]
        [PSCustomObject[]]$PullRequests,

        [Parameter(Mandatory = $false)]
        [int]$SLOHours = 48
    )

    # Helper function to determine if a user is likely a bot/system account
    function Test-IsAutomatedAccount {
        [CmdletBinding()]
        [OutputType([bool])]
        param (
            [Parameter(Mandatory = $false)]
            [string]$DisplayName = "",

            [Parameter(Mandatory = $false)]
            [string]$EmailAddress = ""
        )

        # If both parameters are empty, cannot determine if it's a bot
        if ([string]::IsNullOrWhiteSpace($DisplayName) -and [string]::IsNullOrWhiteSpace($EmailAddress)) {
            return $false
        }

        # List of common keywords indicating a bot or automated service
        $botKeywords = @(
            "build service", "megalinter", "bot", "automation", "system", "azure pipelines",
            "github actions", "github\[bot\]", "azdo", "devops", "ci", "cd"
        )

        # Check if the display name contains bot keywords
        if (-not [string]::IsNullOrWhiteSpace($DisplayName)) {
            foreach ($keyword in $botKeywords) {
                if ($DisplayName -match $keyword) {
                    Write-Verbose "Identified automated account: $DisplayName"
                    return $true
                }
            }
        }

        # Check if email has typical bot patterns
        if (-not [string]::IsNullOrWhiteSpace($EmailAddress)) {
            if ($EmailAddress -match "noreply|donotreply|build|system|auto|service") {
                Write-Verbose "Identified automated account by email: $EmailAddress"
                return $true
            }
        }

        # Check for service principal name patterns
        if (-not [string]::IsNullOrWhiteSpace($DisplayName)) {
            if ($DisplayName -match "\(.*\)$" -and $DisplayName -match "service|agent|worker|runner") {
                Write-Verbose "Identified service account: $DisplayName"
                return $true
            }
        }

        return $false
    }

    # Initialize a hashtable to store weekly metrics
    $weeklyMetrics = @{}

    # Loop through all pull requests
    foreach ($pr in $PullRequests) {
        # Skip PRs without creation date
        if (-not $pr.CreatedDate) {
            Write-Verbose "Skipping PR #$($pr.ID) - Missing creation date"
            continue
        }

        # Convert string date to DateTime if needed
        $createdDate = $pr.CreatedDate
        if ($createdDate -is [string]) {
            $createdDate = [DateTime]::Parse($createdDate)
        }

        # Get the week number of the year
        $weekNumber = (Get-Culture).Calendar.GetWeekOfYear($createdDate, [System.Globalization.CalendarWeekRule]::FirstDay, [DayOfWeek]::Monday)
        $yearNumber = $createdDate.Year

        # Create week key for display (formatted as "ww")
        $weekKey = "$weekNumber".PadLeft(2, '0')

        Write-Verbose "PR #$($pr.ID) created in week $weekKey of $yearNumber"

        # Initialize week entry if it doesn't exist
        if (-not $weeklyMetrics.ContainsKey($weekKey)) {
            $weeklyMetrics[$weekKey] = @{
                WeekNumber = $weekNumber
                Year = $yearNumber
                Total = 0
                Compliant = 0
            }
        }

        # Increment total count for this week
        $weeklyMetrics[$weekKey].Total++

        # Find the earliest response time from reviewers or thread comments
        $earliestResponse = $null
        $earliestResponseSource = "None"

        # Check reviewer votes
        if ($pr.Reviewers -and $pr.Reviewers.Count -gt 0) {
            foreach ($reviewer in $pr.Reviewers) {
                if ($reviewer.VotedDate -and $reviewer.Vote -ne 0) { # 0 means no vote
                    $voteDate = $reviewer.VotedDate
                    if ($voteDate -is [string]) {
                        $voteDate = [DateTime]::Parse($voteDate)
                    }

                    if ($null -eq $earliestResponse -or $voteDate -lt $earliestResponse) {
                        $earliestResponse = $voteDate
                        $earliestResponseSource = "Vote by $($reviewer.DisplayName)"
                    }
                }
            }
        }

        # Check thread comments - with improved thread handling
        if ($pr.Threads -and $pr.Threads.Count -gt 0) {
            foreach ($thread in $pr.Threads) {
                # Check if thread has comments property
                if ($null -ne $thread.Comments) {
                    # Handle different possible structure of Comments property
                    $comments = if ($thread.Comments -is [array]) {
                        $thread.Comments
                    } elseif ($null -ne $thread.Comments.PSObject.Properties['value']) {
                        $thread.Comments.value
                    } else {
                        # Try to cast as array if it's a collection
                        @($thread.Comments)
                    }

                    foreach ($comment in $comments) {
                        if ($null -eq $comment) { continue }

                        # Skip system comments and PR author comments
                        $commentAuthorId = if ($null -ne $comment.author -and $null -ne $comment.author.id) {
                            $comment.author.id
                        } elseif ($null -ne $comment.Author -and $null -ne $comment.Author.Id) {
                            $comment.Author.Id
                        } else {
                            $null
                        }

                        # Skip comments by PR author
                        if ($commentAuthorId -eq $pr.CreatedById) {
                            continue
                        }

                        # Extract author display name - handle different property casing
                        $authorDisplayName = if ($null -ne $comment.author -and $null -ne $comment.author.displayName) {
                            $comment.author.displayName
                        } elseif ($null -ne $comment.Author -and $null -ne $comment.Author.DisplayName) {
                            $comment.Author.DisplayName
                        } elseif ($null -ne $comment.createdBy -and $null -ne $comment.createdBy.displayName) {
                            $comment.createdBy.displayName
                        }

                        # Extract author email - handle different property structures
                        $authorEmail = if ($null -ne $comment.author -and $null -ne $comment.author.uniqueName) {
                            $comment.author.uniqueName
                        } elseif ($null -ne $comment.Author -and $null -ne $comment.Author.UniqueName) {
                            $comment.Author.UniqueName
                        } elseif ($null -ne $comment.author -and $null -ne $comment.author.email) {
                            $comment.author.email
                        } else {
                            ""
                        }

                        # Skip comments from automated accounts/bots
                        if (Test-IsAutomatedAccount -DisplayName $authorDisplayName -EmailAddress $authorEmail) {
                            Write-Verbose "PR #$($pr.ID) - Skipping automated comment by $authorDisplayName"
                            continue
                        }

                        # Extract comment date - handle different property casing
                        $commentDate = if ($null -ne $comment.publishedDate) {
                            $comment.publishedDate
                        } elseif ($null -ne $comment.PublishedDate) {
                            $comment.PublishedDate
                        } elseif ($null -ne $comment.createdDate) {
                            $comment.createdDate
                        } else {
                            $null
                        }

                        # Skip if no valid date
                        if ($null -eq $commentDate) { continue }

                        # Convert string date to DateTime if needed
                        if ($commentDate -is [string]) {
                            $commentDate = [DateTime]::Parse($commentDate)
                        }

                        # Update earliest response if this is earlier
                        if ($null -eq $earliestResponse -or $commentDate -lt $earliestResponse) {
                            $earliestResponse = $commentDate
                            $earliestResponseSource = "Comment by $authorDisplayName"
                            Write-Verbose "PR #$($pr.ID) - Found comment by $authorDisplayName at $commentDate"
                        }
                    }
                }
            }
        }

        # If we found a response, check if it met the SLO
        if ($earliestResponse) {
            $responseTime = $earliestResponse - $createdDate
            if ($responseTime.TotalHours -le $SLOHours) {
                $weeklyMetrics[$weekKey].Compliant++
                Write-Verbose "PR #$($pr.ID) met SLO: Response in $($responseTime.TotalHours.ToString('F1')) hours via $earliestResponseSource"
            } else {
                Write-Verbose "PR #$($pr.ID) missed SLO: Response in $($responseTime.TotalHours.ToString('F1')) hours via $earliestResponseSource (target: $SLOHours hours)"
            }
        } else {
            Write-Verbose "PR #$($pr.ID) has no legitimate response yet"
        }
    }

    # Convert the hashtable to SLOComplianceItem array
    $result = @()

    # Sort weeks chronologically by year first, then by week number
    $sortedWeeks = $weeklyMetrics.Keys | Sort-Object {
        $weekKey = $_
        $year = $weeklyMetrics[$weekKey].Year
        "$year$weekKey" # Format: "YYYYWW"
    }

    foreach ($weekKey in $sortedWeeks) {
        $weekData = $weeklyMetrics[$weekKey]
        $total = $weekData.Total
        $compliant = $weekData.Compliant

        # Calculate percentage (avoid division by zero)
        $percentage = 0
        if ($total -gt 0) {
            $percentage = [Math]::Round(($compliant / $total) * 100, 1)
        }

        # Create SLOComplianceItem and add to result
        $result += [SLOComplianceItem]::new(
            $weekKey,
            $total,
            $compliant,
            $percentage
        )
    }

    Write-Verbose "Generated $($result.Count) weekly SLO metrics. Sample data: $($result[0].Week): $($result[0].CompliancePercentage)%"

    return $result
}

function Get-PRComplexityChartData {
    <#
    .SYNOPSIS
    Calculates PR complexity metrics over time for charting.

    .DESCRIPTION
    Analyzes pull request data to calculate monthly averages for:
    - Files changed per PR
    - Days to complete PRs
    - Files changed per day
    - Lines changed per day
    - Number of unique contributors

    .PARAMETER PullRequests
    Array of pull request objects with detailed information.

    .EXAMPLE
    $complexityChartData = Get-PRComplexityChartData -PullRequests $enhancedPRs
    #>
    [CmdletBinding()]
    [OutputType([PRComplexityChartData])]
    param(
        [Parameter(Mandatory = $true)]
        [Array]$PullRequests
    )

    Write-Verbose "Starting PR complexity chart data calculation with $($PullRequests.Count) PRs"

    # Initialize collections for monthly data
    $monthlyData = @{}

    # Process each PR to collect monthly data
    foreach ($pr in $PullRequests) {
        # Skip PRs that aren't completed
        if ($pr.Status -ne "completed" -or $null -eq $pr.ClosedDate) {
            continue
        }

        # Calculate the month-year for this PR (e.g., "Jan 2025")
        $createdDate = [DateTime]$pr.CreatedDate
        $closedDate = [DateTime]$pr.ClosedDate

        # Get the month this PR was closed in
        $monthYear = $closedDate.ToString("MMM yyyy")

        # Calculate days to complete (handle same-day completions)
        $daysToComplete = [Math]::Max(1, ($closedDate - $createdDate).TotalDays)

        # Get file change count (if available)
        $filesChanged = 0
        if ($null -ne $pr.DetailedFiles -and $null -ne $pr.DetailedFiles.DetailedFiles) {
            $filesChanged = $pr.DetailedFiles.DetailedFiles.Count
        }

        # Get line changes (additions + deletions) if available
        $linesChanged = 0
        if ($null -ne $pr.DetailedFiles) {
            if ($null -ne $pr.DetailedFiles.Additions -and $null -ne $pr.DetailedFiles.Deletions) {
                $linesChanged = $pr.DetailedFiles.Additions + $pr.DetailedFiles.Deletions
            }
        }

        # Initialize this month's data if it doesn't exist
        if (-not $monthlyData.ContainsKey($monthYear)) {
            $monthlyData[$monthYear] = @{
                FilesChanged = @()
                DaysToComplete = @()
                LinesChanged = @()  # New array for line changes
                Contributors = @{}  # Use hashtable as a set to track unique contributors
            }
        }

        # Add this PR's data to the month
        $monthlyData[$monthYear].FilesChanged += $filesChanged
        $monthlyData[$monthYear].DaysToComplete += $daysToComplete
        $monthlyData[$monthYear].LinesChanged += $linesChanged  # Store line changes

        # Add contributor to the set for this month
        $contributorId = $pr.CreatedById
        if ($null -ne $contributorId -and -not [String]::IsNullOrWhiteSpace($contributorId)) {
            $monthlyData[$monthYear].Contributors[$contributorId] = $true
        }
    }

    # Sort months chronologically by year first, then by month
    $sortedMonths = $monthlyData.Keys | Sort-Object {
        $monthYear = $_
        $dateParts = $monthYear -split ' '
        $monthName = $dateParts[0]
        $year = [int]$dateParts[1]

        # Get month number (1-12) for proper sorting
        $monthNumber = [DateTime]::ParseExact($monthName, "MMM", [System.Globalization.CultureInfo]::InvariantCulture).Month

        # Create sortable string "year.month" (e.g., "2024.10")
        "$year.$($monthNumber.ToString("00"))"
    }

    # Initialize arrays for chart data
    $months = @()
    $avgFilesChanged = @()
    $avgDaysToComplete = @()
    $filesPerDay = @()
    $linesPerDay = @()  # New array for lines changed per day
    $contributorCounts = @()

    # Calculate averages for each month
    foreach ($month in $sortedMonths) {
        $data = $monthlyData[$month]

        # Skip months with no completed PRs
        if ($data.FilesChanged.Count -eq 0) {
            continue
        }

        # Calculate averages
        $monthAvgFiles = ($data.FilesChanged | Measure-Object -Average).Average
        $monthAvgDays = ($data.DaysToComplete | Measure-Object -Average).Average
        $monthAvgLines = ($data.LinesChanged | Measure-Object -Average).Average

        # Calculate files per day (files/days ratio)
        $monthFilesPerDay = $monthAvgFiles / $monthAvgDays

        # Calculate lines per day (lines/days ratio)
        $monthLinesPerDay = $monthAvgLines / $monthAvgDays

        # Count unique contributors this month
        $monthContributorCount = $data.Contributors.Keys.Count

        # Add data to arrays
        $months += $month
        $avgFilesChanged += [Math]::Round($monthAvgFiles, 2)
        $avgDaysToComplete += [Math]::Round($monthAvgDays, 2)
        $filesPerDay += [Math]::Round($monthFilesPerDay, 2)
        $linesPerDay += [Math]::Round($monthLinesPerDay, 2)  # Add the lines per day to the constructor
        $contributorCounts += $monthContributorCount
    }

    # Create and return the chart data object
    $chartData = [PRComplexityChartData]::new(
        $months,
        $avgFilesChanged,
        $avgDaysToComplete,
        $filesPerDay,
        $linesPerDay,  # Add the lines per day to the constructor
        $contributorCounts
    )

    Write-Verbose "Generated PR complexity chart data for $($months.Count) months"
    return $chartData
}

function Get-ContributorReturnMetric {
    <#
    .SYNOPSIS
    Analyzes pull request data to identify new vs. returning contributors over time.

    .DESCRIPTION
    This function processes pull request data chronologically to track which contributors
    are new to the project versus which ones are returning each month. It helps visualize
    team growth and contribution patterns over time.

    .PARAMETER PullRequests
    An array of pull request objects with detailed information including author data.

    .PARAMETER MonthsToInclude
    Optional. The number of recent months to include in the analysis. Default is 7.

    .EXAMPLE
    $contributorMetrics = Get-ContributorReturnMetrics -PullRequests $enhancedPRs -MonthsToInclude 6

    .OUTPUTS
    Returns a ReturningContributorMetric object with month labels, new contributor counts,
    and returning contributor counts.
    #>
    [CmdletBinding()]
    [OutputType([ReturningContributorMetric])]
    param(
        [Parameter(Mandatory = $true)]
        [Array]$PullRequests,

        [Parameter(Mandatory = $false)]
        [int]$MonthsToInclude = 7
    )

    Write-Verbose "Starting contributor return metrics calculation with $($PullRequests.Count) PRs"

    # Initialize data structures
    $monthlyContributors = @{}  # Monthly contributor tracking
    $knownContributors = @{}    # Historical record of all contributors

    # Ensure PRs are sorted by creation date
    $sortedPRs = $PullRequests |
        Where-Object { $null -ne $_.CreatedDate } |
        Sort-Object {
            $date = if ($_.CreatedDate -is [DateTime]) { $_.CreatedDate } else { [DateTime]::Parse($_.CreatedDate) }
            return $date
        }

    Write-Verbose "Processing $($sortedPRs.Count) PRs with creation dates"

    # First pass: build a chronological history of contributors
    foreach ($pr in $sortedPRs) {
        # Skip PRs with missing author data
        if ($null -eq $pr.CreatedById -and [string]::IsNullOrEmpty($pr.CreatedByEmail) -and [string]::IsNullOrEmpty($pr.CreatedBy)) {
            continue
        }

        # Get the month-year for this PR
        $createdDate = if ($pr.CreatedDate -is [DateTime]) {
            $pr.CreatedDate
        } else {
            [DateTime]::Parse($pr.CreatedDate)
        }
        $monthYear = $createdDate.ToString("MMM yyyy")

        # Generate a unique contributor identifier (prefer ID, fall back to email, then name)
        $contributorId = if (-not [string]::IsNullOrEmpty($pr.CreatedById)) {
            $pr.CreatedById
        } elseif (-not [string]::IsNullOrEmpty($pr.CreatedByEmail)) {
            $pr.CreatedByEmail
        } else {
            $pr.CreatedBy
        }

        # Initialize this month's data if it doesn't exist
        if (-not $monthlyContributors.ContainsKey($monthYear)) {
            $monthlyContributors[$monthYear] = @{
                New = @{}        # New contributors this month (hash for uniqueness)
                Returning = @{}  # Returning contributors this month (hash for uniqueness)
            }
        }

        # Check if this contributor is new or returning
        if (-not $knownContributors.ContainsKey($contributorId)) {
            # This is a new contributor
            $monthlyContributors[$monthYear].New[$contributorId] = $true
            $knownContributors[$contributorId] = $createdDate  # Add to historical record
            Write-Verbose "New contributor $contributorId in $monthYear"
        } else {
            # This is a returning contributor
            $monthlyContributors[$monthYear].Returning[$contributorId] = $true
            Write-Verbose "Returning contributor $contributorId in $monthYear"
        }
    }

    # Get the most recent months (limited by MonthsToInclude)
    $allMonths = $monthlyContributors.Keys | Sort-Object {
        $monthYear = $_
        $dateParts = $monthYear -split ' '
        $monthName = $dateParts[0]
        $year = [int]$dateParts[1]

        # Get month number (1-12) for proper sorting
        $monthNumber = [DateTime]::ParseExact($monthName, "MMM", [System.Globalization.CultureInfo]::InvariantCulture).Month

        # Create sortable date "yyyy-MM" (e.g., "2024-10")
        "$year-$($monthNumber.ToString("00"))"
    }

    # Take the most recent months
    $recentMonths = if ($allMonths.Count -gt $MonthsToInclude) {
        $allMonths | Select-Object -Last $MonthsToInclude
    } else {
        $allMonths
    }

    # Create arrays for the result
    $monthLabels = @()
    $newContributors = @()
    $returningContributors = @()

    foreach ($month in $recentMonths) {
        $monthData = $monthlyContributors[$month]
        $newCount = $monthData.New.Count
        $returningCount = $monthData.Returning.Count

        $monthLabels += $month
        $newContributors += $newCount
        $returningContributors += $returningCount

        Write-Verbose "$($month): $newCount new, $returningCount returning contributors"
    }

    # Create and return the ReturningContributorMetric object
    $result = [ReturningContributorMetric]::new(
        $monthLabels,
        $newContributors,
        $returningContributors
    )

    Write-Verbose "Generated contributor return metrics for $($monthLabels.Count) months"
    return $result
}

function Get-ContributorMetricData {
    <#
    .SYNOPSIS
    Processes pull request data to generate metrics for each contributor.

    .DESCRIPTION
    This function analyzes pull request data to create a structured report of contributor metrics,
    including PR counts, completion rates, average completion time, file changes, and more.

    .PARAMETER PullRequests
    An array of pull request objects with detailed statistics and metrics.

    .EXAMPLE
    $contributorMetrics = Get-ContributorMetricData -PullRequests $enhancedPRs

    .OUTPUTS
    ContributorMetrics[] - An array of contributor metric objects.
    #>
    [CmdletBinding()]
    [OutputType([ContributorMetrics[]])]
    param (
        [Parameter(Mandatory=$true)]
        [object[]]$PullRequests
    )

    Write-Verbose "Analyzing contributor metrics from $($PullRequests.Count) pull requests"

    # Create a hashtable to store contributor data
    $contributorData = @{}

    # Process each PR and aggregate metrics by contributor
    foreach ($pr in $PullRequests) {
        # Skip null PRs, those without creator, or from build service account
        if ($null -eq $pr -or
            [string]::IsNullOrEmpty($pr.CreatedBy) -or
            $pr.CreatedBy -eq "edge-ai Build Service (ai-at-the-edge-flagship-accelerator)") {
            continue
        }

        $contributor = $pr.CreatedBy

        # Initialize contributor data if it doesn't exist
        if (-not $contributorData.ContainsKey($contributor)) {
            $contributorData[$contributor] = @{
                TotalPRs = 0
                CompletedPRs = 0
                AbandonedPRs = 0
                TotalCompletionDays = 0
                FilesChanged = 0
                LinesAdded = 0
                LinesDeleted = 0
                WorkItemsCount = 0
            }
        }

        # Increment total PRs
        $contributorData[$contributor].TotalPRs++

        # Track completion status
        if ($pr.Status -eq "completed") {
            $contributorData[$contributor].CompletedPRs++

            # Calculate completion time if data is available
            if ($pr.CreatedDate -and $pr.ClosedDate) {
                try {
                    $createdDate = [DateTime]::Parse($pr.CreatedDate)
                    $closedDate = [DateTime]::Parse($pr.ClosedDate)
                    $completionDays = ($closedDate - $createdDate).TotalDays
                    $contributorData[$contributor].TotalCompletionDays += $completionDays
                }
                catch {
                    Write-Verbose "Error calculating completion time for PR $($pr.ID): $_"
                }
            }

            # Process file changes, if available
            if ($pr.DetailedFiles) {
                $contributorData[$contributor].FilesChanged += $pr.DetailedFiles.filesChanged
                $contributorData[$contributor].LinesAdded += $pr.DetailedFiles.Additions
                $contributorData[$contributor].LinesDeleted += $pr.DetailedFiles.Deletions
            }
        }
        elseif ($pr.Status -eq "abandoned") {
            $contributorData[$contributor].AbandonedPRs++
        }

        # Count work items
        if ($pr.WorkItems -and $pr.WorkItems.Count -gt 0) {
            $contributorData[$contributor].WorkItemsCount += $pr.WorkItems.Count
        }
    }

    # Convert aggregated data into ContributorMetrics objects
    $result = @()
    foreach ($contributor in $contributorData.Keys) {
        $data = $contributorData[$contributor]

        # Calculate completion rate
        $completionRate = 0
        if ($data.TotalPRs -gt 0) {
            $completionRate = [math]::Round(($data.CompletedPRs / $data.TotalPRs) * 100, 1)
        }

        # Calculate average time to complete
        $avgTimeToComplete = 0
        if ($data.CompletedPRs -gt 0) {
            $avgTimeToComplete = [math]::Round($data.TotalCompletionDays / $data.CompletedPRs, 1)
        }

        # Create ContributorMetrics object
        $metrics = [ContributorMetrics]::new(
            $contributor,                  # Contributor name
            $data.TotalPRs,                # Total PRs
            $completionRate,               # Completion rate percentage
            $avgTimeToComplete,            # Average completion time (days)
            $data.FilesChanged,            # Total files changed
            $data.LinesAdded,              # Total lines added
            $data.LinesDeleted,            # Total lines deleted
            $data.WorkItemsCount           # Total work items closed
        )

        $result += $metrics
    }

    # Sort contributors by PR count (most active first)
    $result = $result | Sort-Object -Property PRs -Descending

    Write-Verbose "Generated metrics for $($result.Count) contributors"
    return $result
}

function Get-ReviewerMetricData {
    <#
    .SYNOPSIS
    Processes pull request data to extract reviewer metrics.

    .DESCRIPTION
    Analyzes pull request data to calculate reviewer metrics including approval counts,
    comment counts, engagement rates, and response times.

    .PARAMETER PullRequests
    Array of enhanced pull request objects containing detailed reviewer information.

    .EXAMPLE
    $reviewerMetrics = Get-ReviewerMetricData -PullRequests $enhancedPRs

    .OUTPUTS
    [ReviewerMetrics[]] Array of reviewer metrics objects
    #>
    [OutputType([ReviewerMetrics[]])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [Array]$PullRequests
    )

    Write-Verbose "Starting Get-ReviewerMetricData function"

    # Initialize hashtable to collect reviewer data
    $reviewerData = @{}

    # Process each PR
    foreach ($pr in $PullRequests) {
        # Skip null or invalid PRs
        if ($null -eq $pr -or $null -eq $pr.Reviewers) {
            Write-Verbose "Skipping PR with null data or no reviewers"
            continue
        }

        # Get PR creation date for response time calculations
        $prCreationDate = [DateTime]::Parse($pr.CreatedDate)
        Write-Verbose "Processing PR #$($pr.ID) created on $prCreationDate with $($pr.Reviewers.Count) reviewers"

        # Process each reviewer for this PR
        foreach ($reviewer in $pr.Reviewers) {
            # Skip system accounts or null reviewers
            if ($null -eq $reviewer -or $null -eq $reviewer.DisplayName) {
                continue
            }

            # Skip reviewers with square brackets in their names
            if ($reviewer.DisplayName -match "\[" -or $reviewer.DisplayName -match "\]") {
                Write-Verbose "Skipping reviewer with square brackets: $($reviewer.DisplayName)"
                continue
            }

            $reviewerName = $reviewer.DisplayName

            # Initialize reviewer entry if not exists
            if (-not $reviewerData.ContainsKey($reviewerName)) {
                $reviewerData[$reviewerName] = @{
                    Approvals = 0
                    Comments = 0
                    TotalResponseTimeHours = 0
                    ResponseTimesCount = 0
                    PRsReviewed = @()
                    PRsWithEngagement = 0
                }
                Write-Verbose "Added new reviewer to tracking: $reviewerName"
            }

            # Track this PR as reviewed
            if (-not $reviewerData[$reviewerName].PRsReviewed.Contains($pr.ID)) {
                $reviewerData[$reviewerName].PRsReviewed += $pr.ID
            }

            # Handle votes - checking all possible property paths and structures
            $hasVote = $false
            $voteValue = 0

            # Try direct Vote property (case-sensitive variations)
            if ($null -ne $reviewer.PSObject.Properties['Vote']) {
                $voteValue = $reviewer.Vote
                $hasVote = $true
                Write-Verbose "Found direct Vote property: $voteValue for $reviewerName on PR #$($pr.ID)"
            }
            elseif ($null -ne $reviewer.PSObject.Properties['vote']) {
                $voteValue = $reviewer.vote
                $hasVote = $true
                Write-Verbose "Found lowercase vote property: $voteValue for $reviewerName on PR #$($pr.ID)"
            }

            # Try deeper vote structure
            elseif ($null -ne $reviewer.PSObject.Properties['reviewerVote']) {
                $voteValue = $reviewer.reviewerVote
                $hasVote = $true
                Write-Verbose "Found reviewerVote property: $voteValue for $reviewerName on PR #$($pr.ID)"
            }

            # Also look for votes in system comments in Threads
            if (-not $hasVote -and $null -ne $pr.Threads) {
                foreach ($thread in $pr.Threads) {
                    if ($null -eq $thread -or $null -eq $thread.Comments) { continue }

                    # Look through comments for system vote comments
                    $comments = if ($thread.Comments -is [array]) { $thread.Comments } else { @($thread.Comments) }
                    foreach ($comment in $comments) {
                        if ($null -eq $comment) { continue }

                        # Check for system comments with vote information
                        if ($comment.CommentType -eq "system" -and
                            $comment.AuthorDisplayName -eq $reviewerName -and
                            $comment.Content -match "$([regex]::Escape($reviewerName)) voted (\d+)") {

                            $voteValue = [int]$Matches[1]
                            $hasVote = $true
                            Write-Verbose "Found system comment vote: $voteValue for $reviewerName on PR #$($pr.ID)"
                            break
                        }
                    }

                    if ($hasVote) { break }
                }
            }

            # Normalize vote values - Azure DevOps uses 10=approve, 5=approve with suggestions, 0=no vote, -5=waiting, -10=rejected
            if ($hasVote -and $voteValue -ne 0) {
                if ($voteValue -ge 5) {
                    $reviewerData[$reviewerName].Approvals++
                    $reviewerData[$reviewerName].PRsWithEngagement++
                    Write-Verbose "Counted approval for $reviewerName on PR #$($pr.ID) with vote value $voteValue"
                }
                elseif ($voteValue -ne 0) {
                    # Even non-approval votes count as engagement
                    $reviewerData[$reviewerName].PRsWithEngagement++
                    Write-Verbose "Counted non-approval vote engagement for $reviewerName on PR #$($pr.ID) with vote value $voteValue"
                }
            }

            # Enhanced thread and comment processing
            if ($null -ne $pr.Threads) {
                Write-Verbose "Processing $($pr.Threads.Count) threads for PR #$($pr.ID)"

                # Track if we found any comments for this reviewer in this PR
                $foundComments = $false

                foreach ($thread in $pr.Threads) {
                    # Skip null threads
                    if ($null -eq $thread) { continue }

                    # Extract comments using multiple methods to handle different API response formats
                    $comments = $null

                    # Try multiple ways to access comments array
                    if ($null -ne $thread.comments -and $thread.comments -is [Array]) {
                        $comments = $thread.comments
                        Write-Verbose "Found comments array (lowercase) with $($comments.Count) items"
                    }
                    elseif ($null -ne $thread.Comments -and $thread.Comments -is [Array]) {
                        $comments = $thread.Comments
                        Write-Verbose "Found Comments array (uppercase) with $($comments.Count) items"
                    }
                    # Handle case where comments is a property with a value collection
                    elseif ($null -ne $thread.PSObject.Properties['comments'] -and
                           $null -ne $thread.comments.PSObject.Properties['value']) {
                        $comments = $thread.comments.value
                        Write-Verbose "Found comments.value collection with $($comments.Count) items"
                    }
                    elseif ($null -ne $thread.Comments -and $null -ne $thread.Comments.PSObject.Properties['value']) {
                        $comments = $thread.Comments.value
                        Write-Verbose "Found Comments.value collection with $($comments.Count) items"
                    }
                    # Last resort - try to cast to array
                    elseif ($null -ne $thread.PSObject.Properties['comments']) {
                        try {
                            $comments = @($thread.comments)
                            Write-Verbose "Cast comments to array with $($comments.Count) items"
                        }
                        catch {
                            Write-Verbose "Failed to cast comments to array"
                        }
                    }
                    elseif ($null -ne $thread.PSObject.Properties['Comments']) {
                        try {
                            $comments = @($thread.Comments)
                            Write-Verbose "Cast Comments to array with $($comments.Count) items"
                        }
                        catch {
                            Write-Verbose "Failed to cast Comments to array"
                        }
                    }

                    # Process comments if we found any
                    if ($null -ne $comments -and $comments.Count -gt 0) {
                        Write-Verbose "Processing $($comments.Count) comments in thread for PR #$($pr.ID)"

                        foreach ($comment in $comments) {
                            if ($null -eq $comment) { continue }

                            # Get author name using various possible property paths
                            $authorName = $null

                            # Check if this is a properly typed AzDOPullRequestComment object
                            if ($comment.GetType().Name -eq 'AzDOPullRequestComment') {
                                # Use strongly typed properties directly
                                $authorName = $comment.AuthorDisplayName
                                $commentType = $comment.CommentType
                                $commentDate = $comment.CreatedDate
                            }
                            else {
                                # Handle as PSObject with dynamic properties (legacy/API raw data)
                                if ($null -ne $comment.PSObject.Properties['author'] -and $null -ne $comment.author.PSObject.Properties['displayName']) {
                                    $authorName = $comment.author.displayName
                                }
                                elseif ($null -ne $comment.PSObject.Properties['Author'] -and $null -ne $comment.Author.PSObject.Properties['DisplayName']) {
                                    $authorName = $comment.Author.DisplayName
                                }
                                elseif ($null -ne $comment.PSObject.Properties['createdBy'] -and $null -ne $comment.createdBy.PSObject.Properties['displayName']) {
                                    $authorName = $comment.createdBy.displayName
                                }
                                elseif ($null -ne $comment.PSObject.Properties['AuthorDisplayName']) {
                                    $authorName = $comment.AuthorDisplayName
                                }

                                # Get comment type - used to filter system comments
                                $commentType = if ($null -ne $comment.PSObject.Properties['CommentType']) {
                                    $comment.CommentType
                                } elseif ($null -ne $comment.PSObject.Properties['commentType']) {
                                    $comment.commentType
                                } else {
                                    ""
                                }

                                # Extract comment date for timing calculations
                                $commentDate = $null
                                if ($null -ne $comment.PSObject.Properties['publishedDate']) {
                                    $commentDate = $comment.publishedDate
                                }
                                elseif ($null -ne $comment.PSObject.Properties['PublishedDate']) {
                                    $commentDate = $comment.PublishedDate
                                }
                                elseif ($null -ne $comment.PSObject.Properties['createdDate']) {
                                    $commentDate = $comment.createdDate
                                }

                                # Convert string date to DateTime if needed
                                if ($commentDate -is [string]) {
                                    try {
                                        $commentDate = [DateTime]::Parse($commentDate)
                                    }
                                    catch {
                                        $commentDate = $null
                                        Write-Verbose "Failed to parse comment date"
                                    }
                                }
                            }

                            # Skip system comments - now applies consistent filtering
                            if ($commentType -eq "system") {
                                continue
                            }

                            # If we found a comment by this reviewer
                            if ($null -ne $authorName -and $authorName -eq $reviewerName) {
                                $reviewerData[$reviewerName].Comments++
                                $foundComments = $true
                                Write-Verbose "Found comment by $reviewerName on PR #$($pr.ID)"

                                # Calculate response time once per PR/reviewer if we have valid dates
                                if ($null -ne $commentDate -and $null -ne $prCreationDate) {
                                    try {
                                        $responseTime = $commentDate - $prCreationDate
                                        $reviewerData[$reviewerName].TotalResponseTimeHours += $responseTime.TotalHours
                                        $reviewerData[$reviewerName].ResponseTimesCount++
                                        Write-Verbose "Response time for $($reviewerName): $($responseTime.TotalHours) hours"

                                        # Only track one response time per PR/reviewer combination
                                        break
                                    }
                                    catch {
                                        Write-Warning "Error calculating response time for PR #$($pr.ID): $_"
                                    }
                                }
                            }
                        }
                    }
                }

                # If we found comments, mark as engaged
                if ($foundComments) {
                    $reviewerData[$reviewerName].PRsWithEngagement++
                    Write-Verbose "Marked PR #$($pr.ID) as having engagement from $reviewerName due to comments"
                }
            }
        }
    }

    # Create ReviewerMetrics objects
    $reviewerMetrics = @()

    Write-Verbose "Creating ReviewerMetrics objects for $($reviewerData.Keys.Count) reviewers"
    foreach ($reviewer in $reviewerData.Keys) {
        $data = $reviewerData[$reviewer]

        # Calculate metrics - with minimum default values to ensure non-zero quality scores
        $prsReviewedCount = $data.PRsReviewed.Count

        # Create ReviewerMetrics object
        $reviewerMetric = [ReviewerMetrics]::new(
            $reviewer,
            $data.Approvals,
            $data.Comments,
            $prsReviewedCount
        )

        $reviewerMetrics += $reviewerMetric
        Write-Verbose "Created metrics for $($reviewer): Reviewed $prsReviewedCount PRs"
    }

    # Sort by number of approvals (descending)
    $sortedReviewerMetrics = $reviewerMetrics | Sort-Object -Property Approvals -Descending

    Write-Verbose "Returning metrics for $($sortedReviewerMetrics.Count) reviewers"
    return $sortedReviewerMetrics
}

function Get-CopilotImpactMetric {
    <#
    .SYNOPSIS
    Analyzes pull request data to measure the impact of GitHub Copilot adoption.

    .DESCRIPTION
    This function compares pull request metrics before and after the GitHub Copilot
    adoption date to quantify the impact on development efficiency and quality.
    It measures changes in PR completion time, PR size, files changed, and other metrics.

    .PARAMETER PullRequests
    Array of pull request objects with detailed information.

    .PARAMETER AdoptionDate
    DateTime object representing when GitHub Copilot was adopted by the team.

    .EXAMPLE
    $copilotImpact = Get-CopilotImpactMetrics -PullRequests $enhancedPRs -AdoptionDate ([DateTime]::Parse("2023-06-01"))

    .OUTPUTS
    Returns a CopilotImpactData object with before/after metrics and percentage changes.
    #>
    [CmdletBinding()]
    [OutputType([CopilotImpactData])]
    param(
        [Parameter(Mandatory = $true)]
        [Array]$PullRequests,

        [Parameter(Mandatory = $true)]
        [DateTime]$AdoptionDate
    )

    Write-Verbose "Analyzing Copilot impact with adoption date: $($AdoptionDate.ToString('yyyy-MM-dd'))"

    # Initialize metrics containers
    $beforeMetrics = @{
        PRCount = 0
        CompletionDaysSum = 0
        FilesChangedSum = 0
        LinesChangedSum = 0
        CommentCountSum = 0
        ApprovalCountSum = 0
        RejectionCountSum = 0
    }

    $afterMetrics = @{
        PRCount = 0
        CompletionDaysSum = 0
        FilesChangedSum = 0
        LinesChangedSum = 0
        CommentCount = 0
        ApprovalCount = 0
        RejectionCount = 0
    }

    # Process each PR to separate before/after metrics
    foreach ($pr in $PullRequests) {
        # Skip PRs that aren't completed
        if ($pr.Status -ne "completed" -or $null -eq $pr.ClosedDate -or $null -eq $pr.CreatedDate) {
            continue
        }

        # Parse dates
        $createdDate = if ($pr.CreatedDate -is [DateTime]) {
            $pr.CreatedDate
        } else {
            [DateTime]::Parse($pr.CreatedDate)
        }

        $closedDate = if ($pr.ClosedDate -is [DateTime]) {
            $pr.ClosedDate
        } else {
            [DateTime]::Parse($pr.ClosedDate)
        }

        # Determine if PR was created before or after Copilot adoption
        $metrics = if ($createdDate -lt $AdoptionDate) {
            $beforeMetrics
        } else {
            $afterMetrics
        }

        # Increment PR count
        $metrics.PRCount++

        # Calculate and add completion time (days)
        $completionDays = ($closedDate - $createdDate).TotalDays
        if ($completionDays -ge 0 -and $completionDays -lt 365) {
            $metrics.CompletionDaysSum += $completionDays
        }

        # Get file changes
        $filesChanged = 0
        if ($null -ne $pr.DetailedFiles -and $null -ne $pr.DetailedFiles.DetailedFiles) {
            $filesChanged = $pr.DetailedFiles.DetailedFiles.Count
            $metrics.FilesChangedSum += $filesChanged
        }

        # Get lines changed
        $linesChanged = 0
        if ($null -ne $pr.DetailedFiles) {
            if ($null -ne $pr.DetailedFiles.Additions -and $null -ne $pr.DetailedFiles.Deletions) {
                $linesChanged = $pr.DetailedFiles.Additions + $pr.DetailedFiles.Deletions
                $metrics.LinesChangedSum += $linesChanged
            }
        }

        # Count comments
        $commentCount = 0
        if ($null -ne $pr.Threads) {
            foreach ($thread in $pr.Threads) {
                if ($null -eq $thread -or $null -eq $thread.Comments) { continue }

                # Extract comments using multiple methods to handle different API response formats
                $comments = $null
                if ($thread.Comments -is [Array]) {
                    $comments = $thread.Comments
                } elseif ($null -ne $thread.comments -and $thread.comments -is [Array]) {
                    $comments = $thread.comments
                } elseif ($null -ne $thread.Comments -and $null -ne $thread.Comments.value) {
                    $comments = $thread.Comments.value
                    Write-Verbose "Found Comments.value collection with $($comments.Count) items"
                }
                # Last resort - try to cast to array
                elseif ($null -ne $thread.PSObject.Properties['comments']) {
                    try {
                        $comments = @($thread.comments)
                        Write-Verbose "Cast comments to array with $($comments.Count) items"
                    }
                    catch {
                        Write-Verbose "Failed to cast comments to array"
                    }
                }
                elseif ($null -ne $thread.PSObject.Properties['Comments']) {
                    try {
                        $comments = @($thread.Comments)
                        Write-Verbose "Cast Comments to array with $($comments.Count) items"
                    }
                    catch {
                        Write-Verbose "Failed to cast Comments to array"
                    }
                }

                # Count non-system comments
                foreach ($comment in $comments) {
                    if ($null -eq $comment) { continue }

                    # Get comment type
                    $commentType = if ($null -ne $comment.PSObject.Properties['CommentType']) {
                        $comment.CommentType
                    } elseif ($null -ne $comment.PSObject.Properties['commentType']) {
                        $comment.commentType
                    } else {
                        ""
                    }

                    if ($commentType -ne "system") {
                        $commentCount++
                    }
                }
            }
            $metrics.CommentCountSum += $commentCount
        }

        # Count approvals and rejections
        if ($null -ne $pr.Reviewers) {
            foreach ($reviewer in $pr.Reviewers) {
                if ($null -eq $reviewer) { continue }

                # Get vote value (looking at all possible property names)
                $voteValue = 0
                if ($null -ne $reviewer.PSObject.Properties['Vote']) {
                    $voteValue = $reviewer.Vote
                }
                elseif ($null -ne $reviewer.PSObject.Properties['vote']) {
                    $voteValue = $reviewer.vote
                }
                elseif ($null -ne $reviewer.PSObject.Properties['reviewerVote']) {
                    $voteValue = $reviewer.reviewerVote
                }

                # Count vote types
                if ($voteValue -ge 5) {  # Azure DevOps: 10=approve, 5=approve with suggestions
                    $metrics.ApprovalCountSum++
                }
                elseif ($voteValue -le -5) {  # Azure DevOps: -5=waiting, -10=rejected
                    $metrics.RejectionCountSum++
                }
            }
        }
    }

    # Calculate averages and metrics
    $beforeAvgCompletionDays = if ($beforeMetrics.PRCount -gt 0) {
        $beforeMetrics.CompletionDaysSum / $beforeMetrics.PRCount
    } else { 0 }

    $afterAvgCompletionDays = if ($afterMetrics.PRCount -gt 0) {
        $afterMetrics.CompletionDaysSum / $afterMetrics.PRCount
    } else { 0 }

    $completionTimePercentChange = if ($beforeAvgCompletionDays -gt 0) {
        (($afterAvgCompletionDays - $beforeAvgCompletionDays) / $beforeAvgCompletionDays) * 100
    } else { 0 }

    $beforeAvgFilesChanged = if ($beforeMetrics.PRCount -gt 0) {
        $beforeMetrics.FilesChangedSum / $beforeMetrics.PRCount
    } else { 0 }

    $afterAvgFilesChanged = if ($afterMetrics.PRCount -gt 0) {
        $afterMetrics.FilesChangedSum / $afterMetrics.PRCount
    } else { 0 }

    $filesChangedPercentChange = if ($beforeAvgFilesChanged -gt 0) {
        (($afterAvgFilesChanged - $beforeAvgFilesChanged) / $beforeAvgFilesChanged) * 100
    } else { 0 }

    $beforeAvgLinesChanged = if ($beforeMetrics.PRCount -gt 0) {
        $beforeMetrics.LinesChangedSum / $beforeMetrics.PRCount
    } else { 0 }

    $afterAvgLinesChanged = if ($afterMetrics.PRCount -gt 0) {
        $afterMetrics.LinesChangedSum / $afterMetrics.PRCount
    } else { 0 }

    $linesChangedPercentChange = if ($beforeAvgLinesChanged -gt 0) {
        (($afterAvgLinesChanged - $beforeAvgLinesChanged) / $beforeAvgLinesChanged) * 100
    } else { 0 }

    $beforeAvgComments = if ($beforeMetrics.PRCount -gt 0) {
        $beforeMetrics.CommentCountSum / $beforeMetrics.PRCount
    } else { 0 }

    $afterAvgComments = if ($afterMetrics.PRCount -gt 0) {
        $afterMetrics.CommentCountSum / $afterMetrics.PRCount
    } else { 0 }

    $commentsPercentChange = if ($beforeAvgComments -gt 0) {
        (($afterAvgComments - $beforeAvgComments) / $beforeAvgComments) * 100
    } else { 0 }

    $beforeRejectionRate = if ($beforeMetrics.PRCount -gt 0) {
        ($beforeMetrics.RejectionCountSum / $beforeMetrics.PRCount) * 100
    } else { 0 }

    $afterRejectionRate = if ($afterMetrics.PRCount -gt 0) {
        ($afterMetrics.RejectionCountSum / $afterMetrics.PRCount) * 100
    } else { 0 }

    $rejectionRatePercentChange = if ($beforeRejectionRate -gt 0) {
        (($afterRejectionRate - $beforeRejectionRate) / $beforeRejectionRate) * 100
    } else { 0 }

    # Round percentage changes to 1 decimal place
    $completionTimePercentChange = [Math]::Round($completionTimePercentChange, 1)
    $filesChangedPercentChange = [Math]::Round($filesChangedPercentChange, 1)
    $linesChangedPercentChange = [Math]::Round($linesChangedPercentChange, 1)
    $commentsPercentChange = [Math]::Round($commentsPercentChange, 1)
    $rejectionRatePercentChange = [Math]::Round($rejectionRatePercentChange, 1)

    # Create CopilotImpactData object
    $result = [CopilotImpactData]::new(
        $beforeMetrics.PRCount,
        $afterMetrics.PRCount,
        [Math]::Round($beforeAvgCompletionDays, 1),
        [Math]::Round($afterAvgCompletionDays, 1),
        $completionTimePercentChange,
        [Math]::Round($beforeAvgFilesChanged, 1),
        [Math]::Round($afterAvgFilesChanged, 1),
        $filesChangedPercentChange,
        [Math]::Round($beforeAvgLinesChanged, 1),
        [Math]::Round($afterAvgLinesChanged, 1),
        $linesChangedPercentChange,
        [Math]::Round($beforeAvgComments, 1),
        [Math]::Round($afterAvgComments, 1),
        $commentsPercentChange,
        [Math]::Round($beforeRejectionRate, 1),
        [Math]::Round($afterRejectionRate, 1),
        $rejectionRatePercentChange
    )

    Write-Verbose "Copilot Impact: Completion time change: $completionTimePercentChange%, Files changed: $filesChangedPercentChange%"
    return $result
}

function Get-FocusAreaMetric {
    <#
    .SYNOPSIS
    Calculates focus area metrics from pull request data.

    .DESCRIPTION
    Analyzes pull requests to determine technical focus areas based on title, description,
    file extensions and detailed file data, then generates metrics for visualization.

    .PARAMETER PullRequests
    Array of pull request objects to analyze.

    .PARAMETER FileExtensions
    Array of FileExtensionData objects containing file extension metrics from the repository.

    .PARAMETER MonthsToInclude
    Maximum number of months to include in the trends analysis.

    .EXAMPLE
    $focusMetrics = Get-FocusAreaMetrics -PullRequests $prs -FileExtensions $fileExtData -MonthsToInclude 7
    #>
    [CmdletBinding()]
    [OutputType([FocusAreaMetrics])]
    param(
        [Parameter(Mandatory=$true)]
        [object[]]$PullRequests,

        [Parameter(Mandatory=$true)]
        [System.Collections.Hashtable]$FileExtensions,  # This needs a hashtable but you're passing FileExtensionData objects

        [Parameter(Mandatory=$false)]
        [int]$MonthsToInclude = 7
    )

    Write-Verbose "Starting Get-FocusAreaMetric with $($PullRequests.Count) PRs and $($FileExtensions.Count) file extension entries"

    # Create category collection - use the existing TechCategoryCollection class
    $categories = [TechCategoryCollection]::new()

    # Add file type categories from FileExtensionData
    $fileTypeToCategory = @{
        "Documentation (Markdown)" = "Documentation"
        "PowerShell" = "PowerShell"
        "Python" = "Python"
        "Terraform" = "Terraform"
        "Bicep/ARM Templates" = "Bicep/ARM"
        "TypeScript" = "JavaScript/TypeScript"
        "JavaScript" = "JavaScript/TypeScript"
        "YAML" = "DevOps/Config"
        "Shell Scripts" = "DevOps/Config"
        "Docker" = "DevOps/Config"
    }

    # Process FileExtensions to enrich our categorization knowledge
    Write-Verbose "Processing file extension data to enhance categorization"
    foreach ($ext in $FileExtensions) {
        # Map file types to tech categories if possible
        # Not all files in the repository have extensions. (e.g. license and docker files)
        if ($null -ne $ext.FileType -and $fileTypeToCategory.ContainsKey($ext.FileType)) {
            $categoryName = $fileTypeToCategory[$ext.FileType]
            Write-Verbose "Mapped file type $($ext.FileType) to category $categoryName with ${$ext.PRChangesCount} PR changes"
        }
    }

    # Initialize monthly data tracking
    $monthlyData = @{}

    # Process each PR
    foreach ($pr in $PullRequests) {
        # Skip if creation date is missing
        if ($null -eq $pr.CreatedDate) { continue }

        # Get the month-year for this PR
        $createdDate = if ($pr.CreatedDate -is [DateTime]) {
            $pr.CreatedDate
        } else {
            [DateTime]::Parse($pr.CreatedDate)
        }
        $monthYear = $createdDate.ToString("MMM yyyy")

        # Initialize month data if it doesn't exist yet
        if (-not $monthlyData.ContainsKey($monthYear)) {
            $monthlyData[$monthYear] = @{
                Categories = @{}
                TotalPRs = 0
            }
        }

        # Increment total PR count for this month
        $monthlyData[$monthYear].TotalPRs++

        # Combine text content for analysis
        $textToAnalyze = "$($pr.Title) $($pr.Description)" -replace $null, "" -replace "null", ""

        # Use the TechCategoryCollection to analyze and categorize each PR
        foreach ($category in $categories.Categories.Values) {
            if ($category.ContainsKeyword($textToAnalyze)) {
                # Initialize category counter if needed
                if (-not $monthlyData[$monthYear].Categories.ContainsKey($category.Name)) {
                    $monthlyData[$monthYear].Categories[$category.Name] = 0
                }
                # Increment category count for this month
                $monthlyData[$monthYear].Categories[$category.Name]++
                Write-Verbose "PR #$($pr.ID) in $monthYear matched category: $($category.Name)"
            }
        }

        # Analyze file types in this PR to enhance categorization
        if ($pr.DetailedFiles -and $pr.DetailedFiles.DetailedFiles) {
            foreach ($file in $pr.DetailedFiles.DetailedFiles) {
                $extension = [System.IO.Path]::GetExtension($file.Path).ToLower()

                # Map extension to category if possible
                $categoryName = $null

                # Use switch for common extensions
                switch -Regex ($extension) {
                    '\.md$' { $categoryName = "Documentation" }
                    '\.ps1$|\.psm1$|\.psd1$' { $categoryName = "PowerShell" }
                    '\.py$' { $categoryName = "Python" }
                    '\.tf$|\.tfvars$|\.hcl$' { $categoryName = "Terraform" }
                    '\.bicep$|\.bicepparam$|\.json$' { $categoryName = "Bicep/ARM" }
                    '\.tsx$|\.ts$|\.jsx$|\.js$' { $categoryName = "JavaScript/TypeScript" }
                    '\.yaml$|\.yml$' { $categoryName = "DevOps/Config" }
                    '\.sh$|\.bash$' { $categoryName = "DevOps/Config" }
                    '\.dockerfile$|dockerfile|docker-compose\.ya?ml$' { $categoryName = "DevOps/Config" }
                }

                if ($categoryName) {
                    # Initialize category counter if needed
                    if (-not $monthlyData[$monthYear].Categories.ContainsKey($categoryName)) {
                        $monthlyData[$monthYear].Categories[$categoryName] = 0
                    }
                    # Increment category count for this month
                    $monthlyData[$monthYear].Categories[$categoryName]++
                    Write-Verbose "PR #$($pr.ID) in $monthYear has file with extension $extension categorized as $categoryName"
                }
            }
        }
    }

    # Sort months chronologically
    $sortedMonths = $monthlyData.Keys | Sort-Object {
        [DateTime]::ParseExact($_, "MMM yyyy", [System.Globalization.CultureInfo]::InvariantCulture)
    }

    # Limit to most recent N months if needed
    if ($sortedMonths.Count -gt $MonthsToInclude) {
        $sortedMonths = $sortedMonths | Select-Object -Last $MonthsToInclude
        Write-Verbose "Limited to last $MonthsToInclude months of data"
    }

    # Find all unique categories across all months
    $allCategories = @{}
    foreach ($month in $sortedMonths) {
        foreach ($category in $monthlyData[$month].Categories.Keys) {
            $allCategories[$category] = $true
        }
    }
    $uniqueCategories = $allCategories.Keys | Sort-Object
    Write-Verbose "Found ${$uniqueCategories.Count} unique categories: $($uniqueCategories -join ', ')"

    # Calculate percentages for each category in each month
    $categoryValues = @{}
    foreach ($category in $uniqueCategories) {
        $categoryValues[$category] = @()

        foreach ($month in $sortedMonths) {
            $totalPRs = $monthlyData[$month].TotalPRs
            $categoryCount = 0
            if ($monthlyData[$month].Categories.ContainsKey($category)) {
                $categoryCount = $monthlyData[$month].Categories[$category]
            }

            # Calculate percentage (avoid division by zero)
            $percentage = 0
            if ($totalPRs -gt 0) {
                $percentage = [Math]::Round(($categoryCount / $totalPRs) * 100, 1)
            }

            $categoryValues[$category] += $percentage
        }
    }

    # Find top categories by average percentage
    $categoryAverages = @{}
    foreach ($category in $uniqueCategories) {
        $values = $categoryValues[$category]
        if ($values.Count -gt 0) {
            $categoryAverages[$category] = ($values | Measure-Object -Average).Average
        }
    }

    # Get top N categories by average percentage
    $topCategories = $categoryAverages.GetEnumerator() |
                     Sort-Object -Property Value -Descending |
                     Select-Object -First 7 -ExpandProperty Key
    Write-Verbose "Selected top categories: $($topCategories -join ', ')"

    # Get the color map for categories - we'll use the color from TechCategoryCollection
    $colorMap = @{}
    foreach ($category in $uniqueCategories) {
        $found = $false
        foreach ($techCategory in $categories.Categories.Values) {
            if ($techCategory.Name -eq $category) {
                $colorMap[$category] = $techCategory.Color
                $found = $true
                break
            }
        }

        # Use a default color if not found
        if (-not $found) {
            $colorMap[$category] = "#808080" # Default gray
        }
    }

    # Create proper .NET Dictionary objects instead of PowerShell hashtables
    # to avoid issues with special characters in keys
    $netCategoryValues = New-Object "System.Collections.Generic.Dictionary[string, double[]]"
    foreach ($category in $categoryValues.Keys) {
        $netCategoryValues[$category] = $categoryValues[$category]
    }

    $netColorMap = New-Object "System.Collections.Generic.Dictionary[string, string]"
    foreach ($category in $colorMap.Keys) {
        $netColorMap[$category] = $colorMap[$category]
    }

    # Create and return the FocusAreaMetrics object using the .NET Dictionary objects
    $result = [FocusAreaMetrics]::new(
        $sortedMonths,
        $topCategories,
        $netCategoryValues,
        $netColorMap
    )

    Write-Verbose "Created FocusAreaMetrics object with ${$sortedMonths.Count} months and ${$topCategories.Count} top categories"
    return $result
}

function Get-BacklogHierarchySankeyObject {
    <#
    .SYNOPSIS
    Creates a Sankey diagram object from a backlog hierarchy.

    .DESCRIPTION
    Takes an IndustryBacklogCollection object and converts it to a Sankey diagram object with nodes and links.

    .PARAMETER BacklogCollection
    The IndustryBacklogCollection object containing pillars, scenarios, capabilities, and features.

    .OUTPUTS
    IndustryBacklogSankey. An object with nodes and links for a Sankey diagram.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [IndustryBacklogCollection]$BacklogCollection
    )

    Write-Host "Starting Get-BacklogHierarchySankeyObject function with IndustryBacklogCollection"

    # Initialize Sankey object
    $sankeyData = [IndustryBacklogSankey]::new()

    # Add nodes for pillars, scenarios, capabilities, and features
    foreach ($pillar in $BacklogCollection.Pillars) {
        $nodeId = "P_$($pillar.Id)"
        $node = [SankeyNode]::new()
        $node.Id = $nodeId
        $node.Name = $pillar.Title
        $node.Type = "Pillar"
        $sankeyData.AddNode($node)
        Write-Host "Added Pillar node: $($pillar.Title) ($nodeId)"
    }

    foreach ($scenario in $BacklogCollection.Scenarios) {
        $nodeId = "S_$($scenario.Id)"
        $node = [SankeyNode]::new()
        $node.id = $nodeId
        $node.Name = $scenario.Title
        $node.Type = "Scenario"
        $sankeyData.AddNode($node)
        Write-Host "Added Scenario node: $($scenario.Title) ($nodeId)"
    }

    foreach ($capability in $BacklogCollection.Capabilities) {
        $nodeId = "C_$($capability.Id)"
        $node = [SankeyNode]::new()
        $node.Id = $nodeId
        $node.Name = $capability.Title
        $node.Type = "Capability"
        $sankeyData.AddNode($node)
        Write-Host "Added Capability node: $($capability.Title) ($nodeId)"
    }

    foreach ($feature in $BacklogCollection.Features) {
        $nodeId = "F_$($feature.Id)"
        $node = [SankeyNode]::new()
        $node.Id = $nodeId
        $node.Name = $feature.Title
        $node.Type = "Feature"
        $sankeyData.AddNode($node)
        Write-Host "Added Feature node: $($feature.Title) ($nodeId)"
    }

    # Local value to store total customers per scenario based on the count of tags
    # on the scenario object
    $totalCustomersPerScenario = @{}  # Initialize as an empty hashtable

    foreach ($scenario in $BacklogCollection.Scenarios) {
        if ($scenario.Tags -and $scenario.Tags.Count -gt 0) {
            Write-Host "Processing Scenario $($scenario.Id) with tags: $($scenario.Tags -join ', ')"
            # Add 1 customer for each tag in the scenario
            foreach ($tag in $scenario.Tags) {
                if ($totalCustomersPerScenario.ContainsKey($scenario.Id)) {
                    $totalCustomersPerScenario[$scenario.Id]++
                } else {
                    $totalCustomersPerScenario[$scenario.Id] = 1
                }
            }
        }
    }

    # Local value to store the total link count per capability
    $totalLinksPerCapability = @{}

    # Add links from Scenarios to Capabilities
    foreach ($capability in $BacklogCollection.Capabilities) {
        if ($capability.ScenarioList -and $capability.ScenarioList.Count -gt 0) {
            Write-Host "Processing Capability $($capability.Id) with scenarios: $($capability.ScenarioList -join ', ')"
            foreach ($scenarioName in $capability.ScenarioList) {
                Write-Host "Processing Scenario $scenarioName for Capability $($capability.Id)"
                # Ensure scenarioId is a simple ID, not a concatenated string
                foreach($scenario in $BacklogCollection.Scenarios) {
                    if ($scenario.Title -eq $scenarioName) {
                        $sourceNodeId = "S_$($scenario.Id)"
                        $targetNodeId = "C_$($capability.Id)"
                        $link = [SankeyLink]::new()
                        $link.Source = $sourceNodeId
                        $link.Target = $targetNodeId
                        $link.Value = $totalCustomersPerScenario[$scenario.Id]
                        $sankeyData.AddLink($link)
                        Write-Host "Added link: Scenario $scenarioId -> Capability $($capability.Id)"
                    }
                }
                # Add 1 link to the total count for this capability
                if ($totalLinksPerCapability.ContainsKey($capability.Id)) {
                    $totalLinksPerCapability[$capability.Id]++
                } else {
                    $totalLinksPerCapability[$capability.Id] = 1
                }
            }
        }
    }

    Write-Host "Total links per capability: $($totalLinksPerCapability | Out-String)"

    # Add links from Capabilities to Features
    foreach ($feature in $BacklogCollection.Features) {
        foreach($parentCapabilityId in $feature.ParentCapabilityId) {
            $sourceNodeId = "C_$($parentCapabilityId)"
            $targetNodeId = "F_$($feature.Id)"
            $link = [SankeyLink]::new()
            $link.Source = $sourceNodeId
            $link.Target = $targetNodeId
            $link.Value = $totalLinksPerCapability[$parentCapabilityId]
            $sankeyData.AddLink($link)
            Write-Host "Added link: Capability $($feature.ParentCapabilityId) -> Feature $($feature.Id)"
        }
    }

    # Output the Sankey data in JSON format for debugging
    $sankeyJson = $sankeyData | ConvertTo-Json -Depth 10
    Write-Host "--- Sankey Data (JSON) ---"
    Write-Host $sankeyJson
    Write-Host "--------------------------"

    Write-Host "Generated Sankey data with $($sankeyData.Nodes.Count) nodes and $($sankeyData.Links.Count) links"
    return $sankeyData
}

# Export all functions from this module
Export-ModuleMember -Function @(
    'Get-FileExtensionMetric',
    'Get-AzDOReportSummary',
    'Get-PRMonthlyMetric',
    'Get-PRWeeklyMetric',
    'Get-PRSizeMetric',
    'Get-PRCompletionTimeDistribution',
    'Get-PRFirstResponseSLOMetric',
    'Get-PRComplexityChartData',
    'Get-ContributorReturnMetric',
    'Get-ContributorMetricData',
    'Get-ReviewerMetricData',
    'Get-CopilotImpactMetric',
    'Get-FocusAreaMetric',
    'Get-FileExtensionSummary',
    'Get-BacklogHierarchySankeyObject'
)
