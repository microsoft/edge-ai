# AzDO-ReportGeneration.psm1
# Module for generating reports from Azure DevOps data

using module ./AzDO-ReportTypes.psm1

function Get-ReportSummary {
    <#
    .SYNOPSIS
    Generates a formatted summary of pull request statistics.

    .DESCRIPTION
    Takes an AzDOReportSummary object and formats it into a markdown-compatible
    summary section including counts and percentages for PR statuses.

    .PARAMETER Summary
    An AzDOReportSummary object containing the required statistics.

    .EXAMPLE
    $summary = [AzDOReportSummary]::new(120, 15, 5, 3.5, 25)
    $summaryText = Get-ReportSummary -Summary $summary
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [AzDOReportSummary]$Summary # Corrected type
    )

    Write-Verbose "Starting Get-ReportSummary function"
    Write-Verbose "Processing summary with completed: $($Summary.CompletedCount), active: $($Summary.ActiveCount), abandoned: $($Summary.AbandonedCount)"

    $totalPRs = $Summary.GetTotalPullRequests()
    $safeTotal = [Math]::Max(1, $totalPRs) # Prevent division by zero
    Write-Verbose "Total PRs: $totalPRs (Safe total: $safeTotal)"

    $completedPct = [Math]::Round(($Summary.CompletedCount / $safeTotal) * 100, 1)
    $activePct = [Math]::Round(($Summary.ActiveCount / $safeTotal) * 100, 1)
    $abandonedPct = [Math]::Round(($Summary.AbandonedCount / $safeTotal) * 100, 1)
    Write-Verbose "Calculated percentages - Completed: $completedPct%, Active: $activePct%, Abandoned: $abandonedPct%"

    $summaryText = @"
### Summary Statistics

- **Total Pull Requests**: $totalPRs
- **Completed**: $($Summary.CompletedCount) ($completedPct%)
- **Active**: $($Summary.ActiveCount) ($activePct%)
- **Abandoned**: $($Summary.AbandonedCount) ($abandonedPct%)
- **Average Days to Complete**: $($Summary.AvgDaysToComplete)
- **Total Contributors**: $($Summary.TotalContributors)
"@

    Write-Verbose "Completed Get-ReportSummary function"
    return $summaryText
}

function Get-PRMetricsByInterval {
    <#
    .SYNOPSIS
    Generates a formatted report section with charts showing PR metrics by different time intervals.

    .DESCRIPTION
    This function takes PR metrics data and formats it into a series of charts showing
    monthly activity, weekly completion trends, PR size impact on completion time, and
    overall PR completion time distribution.

    .PARAMETER MetricsData
    A PRMetricsIntervalData object containing the required metrics information.

    .EXAMPLE
    $metrics = [PRMetricsIntervalData]::new($createdPRs, $completedPRs, $weeklyMetrics, $sizeMetrics, 10, 25, 15, 5)
    $reportSection = Get-PRMetricsByInterval -MetricsData $metrics
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [PRMetricsIntervalData]$MetricsData # Corrected type
    )

    Write-Verbose "Starting Get-PRMetricsByInterval function"

    # Get required data from the metrics object
    $createdPRs = $MetricsData.CreatedPRs
    $completedPRs = $MetricsData.CompletedPRs
    $WeeklyCompletionMetrics = $MetricsData.WeeklyCompletionMetrics
    $PRSizeMetrics = $MetricsData.PRSizeMetrics
    $underOneDay = $MetricsData.UnderOneDayCount
    $oneToThreeDays = $MetricsData.OneToThreeDaysCount
    $fourToSevenDays = $MetricsData.FourToSevenDaysCount
    $overSevenDays = $MetricsData.OverSevenDaysCount

    Write-Verbose "Extracted metric intervals: Under 1 Day: $underOneDay, 1-3 Days: $oneToThreeDays, 4-7 Days: $fourToSevenDays, Over 7 Days: $overSevenDays"

    # Calculate the min and max values for the PR size chart with padding
    $sizeChartValues = @($PRSizeMetrics.SmallPRAvgTime, $PRSizeMetrics.MediumPRAvgTime, $PRSizeMetrics.LargePRAvgTime)
    $sizeChartMin = [Math]::Max(0, ($sizeChartValues | Measure-Object -Minimum).Minimum - 1)
    $sizeChartMax = ($sizeChartValues | Measure-Object -Maximum).Maximum + 1
    Write-Verbose "Size chart range calculated: Min=$sizeChartMin, Max=$sizeChartMax"

    Write-Verbose "Building monthly PR activity chart"
    # Create the formatted report string
    $reportContent = @"
## Monthly Pull Request Activity

The following chart shows the trend of PRs created and completed each month.

$(Get-MermaidChart -type "xychart-beta" -title "Monthly PR Activity Trends" -content @"
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#FF6384, #36A2EB"}}}}%%
    x-axis [$(($createdPRs.Labels | ForEach-Object { "`"$_`"" }) -join ', ')]
    y-axis "Number of PRs"
    line "Created PRs" [$(($createdPRs.Values) -join ', ')]
    line "Completed PRs" [$(($completedPRs.Values) -join ', ')]
"@)

### PR Activity Chart Legend

| PR Type | Color |
|---------|-------|
| Created PRs | <span style='color:#FF6384'>■■■■</span> |
| Completed PRs | <span style='color:#36A2EB'>■■■■</span> |

## Weekly Completed Pull Requests

This chart shows PR completion trends by week (Monday-Friday work weeks).

$(
    # Limit to last 26 weeks of data
    $weeksToShow = 28
    $totalWeeks = $WeeklyCompletionMetrics.Labels.Count
    $startIndex = [Math]::Max(0, $totalWeeks - $weeksToShow)

    # Get the limited subset of labels and values
    $limitedLabels = $WeeklyCompletionMetrics.Labels[$startIndex..($totalWeeks-1)]
    $limitedValues = $WeeklyCompletionMetrics.Values[$startIndex..($totalWeeks-1)]

    Write-Verbose "Showing weekly metrics for last $weeksToShow weeks (from $($limitedLabels[0]) to $($limitedLabels[-1]))"

    Get-MermaidChart -type "xychart-beta" -title "Weekly PR Completion Activity (Last 26 Weeks)" -content @"
    x-axis [$(($limitedLabels | ForEach-Object { "`"$_`"" }) -join ', ')]
    y-axis "Number of PRs"
    bar [$(($limitedValues) -join ', ')]
"@)

## PR Completion Time by Size

The size of a PR significantly impacts how long it takes to review and merge.

$(Get-MermaidChart -type "xychart-beta" -title "Average Days to Complete by PR Size" -content @"
    x-axis ["Small (≤5 files)", "Medium (6-20 files)", "Large (>20 files)"]
    y-axis "Days" $sizeChartMin --> $sizeChartMax
    bar [$($PRSizeMetrics.SmallPRAvgTime), $($PRSizeMetrics.MediumPRAvgTime), $($PRSizeMetrics.LargePRAvgTime)]
"@)

## PR Completion Time Distribution

$(Get-MermaidChart -type "pie showData" -title "PR Completion Time Distribution" -content @"
    "Under 1 Day" : $underOneDay
    "1-3 Days" : $oneToThreeDays
    "4-7 Days" : $fourToSevenDays
    "Over 7 Days" : $overSevenDays
"@)
"@

    Write-Verbose "Completed Get-PRMetricsByInterval function"
    return $reportContent
}

function Get-SLOComplianceTableContent {
    <#
    .SYNOPSIS
    Generates a formatted markdown table displaying SLO compliance data.

    .DESCRIPTION
    Takes an array of SLOComplianceItem objects and formats them into a markdown table
    showing weekly SLO compliance data including total PRs, PRs meeting SLO, and compliance percentages.
    Also creates a chart showing the compliance percentage over time and PRs closed per week.

    .PARAMETER SLOComplianceData
    An array of SLOComplianceItem objects, each containing Week, Total, MetSLO, CompliancePercentage, and ClosedPRCount properties.

    .PARAMETER SLOHours
    The number of hours for the SLO window. Defaults to 48 hours.

    .PARAMETER WeeklyCompletionMetrics
    Optional ChartData object containing weekly PR completion metrics to incorporate into the chart.

    .EXAMPLE
    $sloData = @([SLOComplianceItem]::new("Week 1", 10, 8, 80, 12), [SLOComplianceItem]::new("Week 2", 15, 12, 80, 18))
    $tableContent = Get-SLOComplianceTableContent -SLOComplianceData $sloData -SLOHours 72
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [SLOComplianceItem[]]$SLOComplianceData, # Corrected type

        [Parameter(Mandatory=$false)]
        [int]$SLOHours = 48,

        [Parameter(Mandatory=$false)]
        [ChartData]$WeeklyCompletionMetrics # Corrected type
    )

    Write-Verbose "Starting Get-SLOComplianceTableContent function with $($SLOComplianceData.Count) items"

    # Extract labels and compliance values from SLOComplianceData for the chart
    $labels = @()
    $complianceValues = @()
    $closedPRValues = @()

    foreach ($item in $SLOComplianceData) {
        $weekLabel = $item.Week
        $labels += $weekLabel
        $complianceValues += $item.CompliancePercentage

        # Look up the corresponding value from WeeklyCompletionMetrics
        $weekIndex = [array]::IndexOf($WeeklyCompletionMetrics.Labels, $weekLabel)
        if ($weekIndex -ge 0) {
            $closedPRValues += $WeeklyCompletionMetrics.Values[$weekIndex]
            Write-Verbose "Found matching week $($weekLabel): $($WeeklyCompletionMetrics.Values[$weekIndex]) PRs"
        } else {
            $closedPRValues += 0
            Write-Verbose "No matching week found for $weekLabel, using 0"
        }

        Write-Verbose "Processing SLO week $weekLabel, Total PRs: $($item.Total), Met SLO: $($item.MetSLO), Compliance: $($item.CompliancePercentage)%"
    }
    Write-Host "SLO compliance PR data: $($closedPRValues -join ', ')"
    # Format the labels for the chart
    $formattedLabels = $labels | ForEach-Object { "`"$_`"" } | Join-String -Separator ", "

    # Calculate maximum PR count for scaling
    $maxClosedPRs = ($closedPRValues | Measure-Object -Maximum).Maximum

    # Scale the closed PR values to 0-100 range for better visualization
    $scaledClosedPRValues = @()
    if ($maxClosedPRs -gt 0) {
        $scaledClosedPRValues = $closedPRValues | ForEach-Object {
            [Math]::Round(($_ / $maxClosedPRs) * 100, 1)
        }
    } else {
        $scaledClosedPRValues = $closedPRValues
    }

    Write-Verbose "Building SLO compliance chart with SLO window of $SLOHours hours"

    # Create the chart with both compliance percentage and scaled PR count
    $chartInit = @"
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "#4BC0C0, #FF6384"}}}}%%
"@

    $tableContent = @"
## SLO Compliance Trend

The following chart shows the trend of SLO compliance percentage over time ($SLOHours hour response window) and the number of PRs closed each week:

$(Get-MermaidChart -type "xychart-beta" -title "Weekly SLO Compliance and PR Closure" -init $chartInit -content @"
    x-axis [$formattedLabels]
    y-axis "Percentage" 0 --> 100
    line [$($complianceValues -join ", ")]
    bar [$($scaledClosedPRValues -join ", ")]
"@
)

### Chart Legend

| Metric | Description | Color |
|--------|-------------|-------|
| SLO Compliance % | Percentage of PRs meeting the $SLOHours hour response window | <span style='color:#4BC0C0'>■■■■</span> |
| PRs Closed | Total number of PRs closed in each week (scaled to percentage of maximum: $maxClosedPRs) | <span style='color:#FF6384'>■■■■</span> |
"@

    return $tableContent
}

function Get-ContributorSummary {
    <#
    .SYNOPSIS
    Generates a markdown summary of contributor statistics.

    .DESCRIPTION
    This function creates a concise summary of contributor metrics including
    new vs returning contributors, most active contributors, and overall contribution trends.

    .PARAMETER Contributors
    An array of ContributorMetrics objects containing contributor data.

    .PARAMETER ContributorReturnMetrics
    A ReturningContributorMetric object containing contributor return metrics data.

    .PARAMETER MonthsToShow
    Optional. Number of months to include in the summary. Default is 3.

    .EXAMPLE
    $summary = Get-ContributorSummary -Contributors $contributorMetrics -ContributorReturnMetrics $returnMetrics

    .NOTES
    This function provides a concise overview of the contributor landscape.
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [ContributorMetrics[]]$Contributors, # Corrected type

        [Parameter(Mandatory=$true)]
        [ReturningContributorMetric]$ContributorReturnMetrics, # Corrected type

        [Parameter(Mandatory=$true)]
        [ReviewerMetrics[]]$ReviewerMetrics, # Corrected type

        [Parameter(Mandatory=$false)]
        [int]$MonthsToShow = 3
    )

    Write-Verbose "Starting Get-ContributorSummary function with $MonthsToShow months to show"

    # Filter contributors to only those active in the recent time period
    $recentContributors = [System.Collections.Generic.HashSet[string]]::new()
    # Fix: Use MonthLabels property instead of Months
    $recentMonths = [Math]::Min($MonthsToShow, $ContributorReturnMetrics.MonthLabels.Count)
    $recentMonthNames = @()

    # Get the most recent months
    # Fix: Use MonthLabels property instead of Months
    for ($i = $ContributorReturnMetrics.MonthLabels.Count - $recentMonths;
         $i -lt $ContributorReturnMetrics.MonthLabels.Count;
         $i++) {
        if ($i -ge 0) {
            $recentMonthNames += $ContributorReturnMetrics.MonthLabels[$i]
        }
    }

    # Filter contributors by their last activity date
    foreach ($contrib in $Contributors) {
        # Assume active in recent months if they've contributed
        $recentContributors.Add($contrib.Contributor) | Out-Null
    }

    $totalUniqueContributors = $recentContributors.Count
    Write-Verbose "Found $totalUniqueContributors unique contributors in the last $recentMonths months"

    # Continue calculating new vs returning counts for percentage calculations
    $totalNewRecent = 0
    $totalReturningRecent = 0
    Write-Verbose "Analyzing last $recentMonths months of contributor data"

    for ($i = $ContributorReturnMetrics.NewContributors.Count - $recentMonths;
         $i -lt $ContributorReturnMetrics.NewContributors.Count;
         $i++) {
        if ($i -ge 0) {
            $totalNewRecent += $ContributorReturnMetrics.NewContributors[$i]
            $totalReturningRecent += $ContributorReturnMetrics.ReturningContributors[$i]
            Write-Verbose "Month index $($i): New: $($ContributorReturnMetrics.NewContributors[$i]), Returning: $($ContributorReturnMetrics.ReturningContributors[$i])"
        }
    }

    $totalRecentContributors = $totalNewRecent + $totalReturningRecent
    $newContributorPercent = if ($totalRecentContributors -gt 0) {
        [Math]::Round(($totalNewRecent / $totalRecentContributors) * 100, 1)
    } else { 0 }
    Write-Verbose "Total recent contributors: $totalRecentContributors (New: $totalNewRecent, $newContributorPercent%)"

    Write-Verbose "Building contributor trend chart"
    # Generate the markdown content
    $markdown = @"
## Contributor Summary

Over the past $recentMonths months:

- **Total Unique Contributors**: $totalUniqueContributors
- **New Contributors**: $totalNewRecent ($newContributorPercent%)
- **Returning Contributors**: $totalReturningRecent ($([Math]::Round(100 - $newContributorPercent, 1))%)

### Contributors

<!-- cspell:disable -->
| Contributor | PRs | Files Changed | Lines Added | Lines Deleted | Work Items Closed |
|-------------|-----|--------------|-------------|--------------|------------------|
$(
    # Get top contributors from the array, sorted alphabetically by name
    $topContributors = $Contributors | Sort-Object -Property Contributor | Select-Object -First 30
    $contributorRows = @()

    foreach ($contributor in $topContributors) {
        # Create a formatted row for each contributor (without Completion Rate and Avg Time)
        $contributorRows += "| $($contributor.Contributor) | $($contributor.PRs) | $($contributor.FilesChanged) | $($contributor.LinesAdded) | $($contributor.LinesDeleted) | $($contributor.WorkItemsClosed) |"
    }

    Write-Verbose "30 contributors extracted from array"
    $contributorRows -join "`n"
)

## Reviewers

| Reviewer | Approvals | Comments |
|----------|-----------|----------|
$(
    # Get top reviewers sorted by Reviewer name alphabetically, excluding those with 0 approvals
    $topReviewers = $ReviewerMetrics | Where-Object { $_.Approvals -gt 0 } | Sort-Object -Property Reviewer | Select-Object -First 20
    $reviewerRows = @()

    foreach ($reviewer in $topReviewers) {
        # Create a formatted row for each reviewer (without the Tagged in Reviews column)
        $reviewerRows += "| $($reviewer.Reviewer) | $($reviewer.Approvals) | $($reviewer.Comments) |"
    }

    Write-Verbose "Reviewers extracted from array"
    $reviewerRows -join "`n"
)

<!-- cspell:enable -->

## Contributor Trends

The contributor retention rate (returning vs. new) suggests a $(if ($newContributorPercent -gt 20) { "growing, but potentially less stable" } else { "stable, experienced" }) contributor base.

This chart shows the pattern of new vs. returning contributors over time:

$(Get-MermaidChart -type "xychart-beta" -title "Contributor Trends: New vs. Returning" -content @"
    x-axis [$(($ContributorReturnMetrics.MonthLabels | ForEach-Object { "`"$_`"" }) -join ", ")]
    y-axis "Number of Contributors"
    line [$(($ContributorReturnMetrics.NewContributors) -join ", ")]
    line [$(($ContributorReturnMetrics.ReturningContributors) -join ", ")]
"@
)

### Contributor Chart Legend

| Contributor Type | Color |
|------------------|-------|
| New Contributors | <span style='color:#4287f5'>■■■■</span> |
| Returning Contributors | <span style='color:#42f5a7'>■■■■</span> |
"@

    Write-Verbose "Completed Get-ContributorSummary function"
    return $markdown
}

function Format-FileExtensionTable {
    <#
    .SYNOPSIS
    Formats a file extension summary into a markdown table.

    .DESCRIPTION
    This function takes a FileExtensionSummary object and formats it
    into a markdown table for reporting. The function only handles rendering
    the data and does not perform any calculations.

    .PARAMETER Summary
    A FileExtensionSummary object containing extension data and totals.

    .EXAMPLE
    $extensions = @(
        [FileExtensionData]::new("JavaScript/TypeScript", 120, "60.0%", 45, "75.0%"),
        [FileExtensionData]::new("Python", 80, "40.0%", 15, "25.0%")
    )
    $summary = [FileExtensionSummary]::new($extensions, 200, 60)
    $table = Format-FileExtensionTable -Summary $summary
    #>
    [OutputType([string])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [FileExtensionSummary]$Summary # Corrected type
    )

    Write-Verbose "Starting Format-FileExtensionTable function with $($Summary.Extensions.Count) extensions"

    # Create the table header
    $table = @"
## File Types

| File Type | Current Branch Files | % of Files | PR Changes Count | % of Changes |
|-----------|---------------------|------------|------------------|--------------|
"@

    # Add each extension to the table
    foreach ($ext in $Summary.Extensions) {
        $table += "`n| $($ext.FileType) | $($ext.CurrentBranchFiles) | $($ext.PercentOfFiles) | $($ext.PRChangesCount) | $($ext.PercentOfChanges) |"
        Write-Verbose "Added file type row: $($ext.FileType), Files: $($ext.CurrentBranchFiles), Changes: $($ext.PRChangesCount)"
    }

    # Add totals row
    $table += "`n| **Total** | **$($Summary.TotalBranchFiles)** | **100%** | **$($Summary.TotalPRChanges)** | **100%** |"
    Write-Verbose "Added totals row: Files: $($Summary.TotalBranchFiles), Changes: $($Summary.TotalPRChanges)"

    Write-Verbose "Completed Format-FileExtensionTable function"
    return $table
}

function Get-FocusAreaSection {
    <#
    .SYNOPSIS
    Creates a complete markdown section for focus area trends with chart and legend.

    .DESCRIPTION
    Generates a formatted markdown section including heading, explanatory text,
    and a Mermaid chart showing how different focus areas (like CI/CD, Documentation, etc.)
    have trended over time as a percentage of total PRs. The chart uses a logarithmic
    y-axis scale to better visualize areas with both small and large percentages.

    .PARAMETER FocusAreaMetrics
    The FocusAreaMetrics object containing month labels, focus areas, values and color mapping.

    .EXAMPLE
    # Basic usage with data from FocusAreaMetrics class
    $focusSection = Get-FocusAreaSection FocusAreaMetrics $focusAreaData
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [FocusAreaMetrics]$FocusAreaMetrics # Corrected type
    )

    Write-Verbose "Starting Get-FocusAreaSection function with $($FocusAreaMetrics.Areas.Count) focus areas"

    # Define color palette for the chart - use the colors from the ColorMap in the order of FocusAreaMetrics.Areas
    $areaColors = @()
    foreach ($area in $FocusAreaMetrics.Areas) {
        # Removed null check - assume colors exist in ColorMap
        $areaColors += $FocusAreaMetrics.ColorMap[$area]
        Write-Verbose "Using color $($FocusAreaMetrics.ColorMap[$area]) for area: $area"
    }
    $colorPalette = $areaColors -join ", "
    Write-Verbose "Color palette: $colorPalette"

    # Build the Mermaid chart init directive with proper format
    $chartInit = @"
%%{init: {"themeVariables": {"xyChart": {"plotColorPalette": "$colorPalette"}}}}%%
"@

    # Build the Mermaid chart content
    $chartContent = @"
    x-axis [$(($FocusAreaMetrics.Labels | ForEach-Object { "`"$_`"" }) | Join-String -Separator ", ")]
    y-axis "Percentage of PRs (log scale)" 1 --> 100
    $(
        foreach ($area in $FocusAreaMetrics.Areas) {
            $logValues = $FocusAreaMetrics.Values[$area] | ForEach-Object { if ($_ -eq 0) { 0.1 } else { $_ } }
            Write-Verbose "Area: $area, Values: $($logValues -join ', ')"
            "    line `"$area`" [$($logValues -join ", ")]"
        }
    )
"@

    Write-Verbose "Building focus area chart with Mermaid"
    # Use the Get-MermaidChart function instead of manually creating the chart
    $mermaidChart = Get-MermaidChart -type "xychart-beta" -title "Focus Area Trends Over Time (% of monthly PRs)" -content $chartContent -init $chartInit

    # Add legend for the chart - exactly two columns for focus areas
    $focusAreaChartLegend = @"
### Focus Area Chart Legend

| Focus Area | Color | Focus Area | Color |
|------------|-------|------------|-------|
$(
    # Create pairs of areas for the two-column format
    $areas = $FocusAreaMetrics.Areas
    $rows = for ($i = 0; $i -lt [Math]::Ceiling($areas.Count / 2); $i++) {
        $area1 = $areas[$i]
        $area2 = if ($i + [Math]::Floor($areas.Count / 2) + ($areas.Count % 2) -lt $areas.Count) {
            $areas[$i + [Math]::Floor($areas.Count / 2) + ($areas.Count % 2)]
        } else { $null }

        $color1 = $FocusAreaMetrics.ColorMap[$area1]

        $line = "| $area1 | <span style='color:$color1'>■■■■</span> |"

        if ($area2) {
            $color2 = $FocusAreaMetrics.ColorMap[$area2]
            $line += " $area2 | <span style='color:$color2'>■■■■</span> |"
        } else {
            $line += " | |"
        }

        $line
    }
    $rows -join "`n"
)
"@

    # Create the complete markdown section
    $markdown = @"
## Focus Area Trends

The xy-chart below tracks how development focus areas have evolved over time in the project:

$mermaidChart

$focusAreaChartLegend
"@

    Write-Verbose "Completed Get-FocusAreaSection function"
    return $markdown
}

function Get-MermaidChart {
    <#
    .SYNOPSIS
    Creates a formatted Mermaid chart string for rendering in Markdown.

    .DESCRIPTION
    Generates a properly formatted Mermaid chart string that can be rendered in Markdown documents.
    This function supports various chart types like pie charts, flow charts, and xy charts with
    customizable titles and initialization directives.

    .PARAMETER type
    The Mermaid chart type (e.g., 'pie', 'flowchart', 'xychart-beta')

    .PARAMETER title
    The title for the chart.

    .PARAMETER content
    The content of the Mermaid chart (nodes, connections, data points, etc.).

    .PARAMETER init
    Optional initialization directives for the Mermaid chart. Used for custom styling.

    .OUTPUTS
    System.String. Returns a properly formatted Mermaid chart as a markdown code block.

    .EXAMPLE
    $chart = Get-MermaidChart -type "pie" -title "PR Distribution" -content @"
        "Active" : 15
        "Completed" : 120
        "Abandoned" : 5
    "@

    .NOTES
    The returned string includes triple backtick markers for markdown rendering.
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param (
        [string]$type,
        [string]$title,
        [string]$content,
        [string]$init = ""
    )

    Write-Verbose "Creating Mermaid chart of type: $type with title: $title"

    # Triple backtick for code blocks
    $tripleBacktick = '```'

    # --- Start Change ---
    # Conditionally add title based on chart type
    $titleLine = ""
    if ($type -ne "sankey-beta") {
        $titleLine = "    title `"$title`""
    } else {
        Write-Verbose "Sankey-beta chart type detected, omitting title line."
        # Optionally, add title as a comment if needed for context, though Mermaid won't render it.
        # $titleLine = "    %% Title: $title"
    }

    # Build the chart string
    return @"
$tripleBacktick mermaid
$init
$type
$titleLine
$content
$tripleBacktick
"@
}

function Get-CopilotImpactSection {
    <#
    .SYNOPSIS
    Generates formatted markdown showing the impact of GitHub Copilot adoption.

    .DESCRIPTION
    This function takes CopilotImpactData and formats it into readable markdown
    that shows the before/after metrics of GitHub Copilot adoption.

    .PARAMETER ImpactData
    A CopilotImpactData object containing metrics before and after Copilot adoption.

    .PARAMETER AdoptionDate
    Optional. The date when GitHub Copilot was adopted. If not provided, uses the date from ImpactData.

    .PARAMETER ComplexityChartData
    Optional. A PRComplexityChartData object to include a PR complexity chart in the report.

    .EXAMPLE
    $impactData = [CopilotImpactData]::new(...)
    $chartData = [PRComplexityChartData]::new(...)
    $section = Get-CopilotImpactSection -ImpactData $impactData -ComplexityChartData $chartData

    .NOTES
    This function focuses solely on formatting the metrics into readable markdown,
    with no calculations performed.
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [CopilotImpactData]$ImpactData,

        [Parameter(Mandatory=$false)]
        [DateTime]$AdoptionDate,

        [Parameter(Mandatory=$false)]
        [PRComplexityChartData]$ComplexityChartData = $null
    )

    Write-Verbose "Starting Get-CopilotImpactSection function"

    # Use the provided adoption date or get it from the data
    if ($null -eq $AdoptionDate) {
        $AdoptionDate = $ImpactData.CopilotAdoptionDate
    }
    Write-Verbose "Copilot adoption date: $($AdoptionDate.ToString('yyyy-MM-dd'))"

    # Additional note about Copilot's impact - calculate files per day metrics on the fly
    $beforeFilesPerDay = $ImpactData.BeforeAvgFilesChanged / [Math]::Max(1, $ImpactData.BeforeAvgCompletionDays)
    $afterFilesPerDay = $ImpactData.AfterAvgFilesChanged / [Math]::Max(1, $ImpactData.AfterAvgCompletionDays)
    $filesPerDayPctChange = [Math]::Round((($afterFilesPerDay / [Math]::Max(0.1, $beforeFilesPerDay)) - 1) * 100, 1)

    $timeToCompletePctChange = $ImpactData.CompletionTimePercentChange
    $timeToCompleteDirection = if ($timeToCompletePctChange -lt 0) { "decreased" } else { "increased" }
    $productivityDirection = if ($filesPerDayPctChange -gt 0) { "increased" } else { "decreased" }
    Write-Verbose "Completion time $timeToCompleteDirection by $([Math]::Abs($timeToCompletePctChange))%, productivity $productivityDirection by $([Math]::Abs($filesPerDayPctChange))%"

    Write-Verbose "Generating PR complexity chart with $($ComplexityChartData.TimeLabels.Count) time periods"

    # Define color mapping for the chart lines
    $metricColors = @{
        "Avg Files Changed"    = "#4BC0C0" # Teal
        "Avg Days to Complete" = "#FF6384" # Red
        "Avg Files/Day"        = "#36A2EB" # Blue
        "Avg Lines/Day"        = "#9966FF" # Purple
        "Total Contributors"   = "#FFCE56" # Yellow
    }

    # Format the month labels for the x-axis
    $monthLabels = ($ComplexityChartData.TimeLabels | ForEach-Object { "`"$_`"" }) -join ", "
    Write-Verbose "Chart x-axis labels: $monthLabels"

    # Store the maximum values for the legend - using raw values directly instead of rolling averages
    $filesChangedMax = ($ComplexityChartData.FilesChangedValues | Measure-Object -Maximum).Maximum
    $completionDaysMax = ($ComplexityChartData.CompletionDaysValues | Measure-Object -Maximum).Maximum
    $filesPerDayMax = ($ComplexityChartData.FilesPerDayValues | Measure-Object -Maximum).Maximum
    $linesPerDayMax = ($ComplexityChartData.LinesPerDayValues | Measure-Object -Maximum).Maximum
    $contributorCountMax = ($ComplexityChartData.ContributorCountValues | Measure-Object -Maximum).Maximum

    # Use meaningful scaling factors to make different metrics visible on the same chart
    $filesChangedScaleFactor = 5      # Multiply by 5 to make visible changes
    $completionDaysScaleFactor = 25   # Multiply by 25 to make days more visible
    $filesPerDayScaleFactor = 15      # Multiply by 15 for good visibility
    $linesPerDayScaleFactor = 0.4     # Scale down lines/day which can be very large
    $contributorCountScaleFactor = 8  # Multiply by 8 to make contributor count visible

    # Apply scaling factors to raw values
    $scaledFilesChanged = $ComplexityChartData.FilesChangedValues | ForEach-Object {
        [Math]::Round($_ * $filesChangedScaleFactor, 1)
    }

    $scaledCompletionDays = $ComplexityChartData.CompletionDaysValues | ForEach-Object {
        [Math]::Round($_ * $completionDaysScaleFactor, 1)
    }

    $scaledFilesPerDay = $ComplexityChartData.FilesPerDayValues | ForEach-Object {
        [Math]::Round($_ * $filesPerDayScaleFactor, 1)
    }

    $scaledLinesPerDay = $ComplexityChartData.LinesPerDayValues | ForEach-Object {
        [Math]::Round($_ * $linesPerDayScaleFactor, 1)
    }

    $scaledContributorCount = $ComplexityChartData.ContributorCountValues | ForEach-Object {
        [Math]::Round($_ * $contributorCountScaleFactor, 1)
    }

    # Create a comma-separated string of color values with NO quotes
    $colorPalette = "$($metricColors['Avg Files Changed']), $($metricColors['Avg Days to Complete']), $($metricColors['Avg Files/Day']), $($metricColors['Avg Lines/Day']), $($metricColors['Total Contributors'])"

    # The correct format for the chart init directive with double quotes
    $chartInit = "%%{init: {`"themeVariables`": {`"xyChart`": {`"plotColorPalette`": `"$colorPalette`"}}}}%%"

    # Determine a reasonable Y-axis limit based on the maximum scaled value
    $allScaledValues = $scaledFilesChanged + $scaledCompletionDays + $scaledFilesPerDay + $scaledLinesPerDay + $scaledContributorCount
    $yAxisMax = [Math]::Ceiling(($allScaledValues | Measure-Object -Maximum).Maximum * 1.1) # Add 10% padding

    # Generate the chart content with scaled values
    $chartContent = @"
x-axis [$monthLabels]
y-axis "Value (scaled)" 0 --> $yAxisMax
line "Avg Files Changed" [$(($scaledFilesChanged) -join ', ')]
line "Avg Days to Complete" [$(($scaledCompletionDays) -join ', ')]
line "Avg Files/Day" [$(($scaledFilesPerDay) -join ', ')]
line "Avg Lines/Day" [$(($scaledLinesPerDay) -join ', ')]
line "Total Contributors" [$(($scaledContributorCount) -join ', ')]
"@

    # Get the mermaid chart first - store as separate string
    $mermaidChart = Get-MermaidChart -type "xychart-beta" -title "PR Complexity and Contributors" -content $chartContent -init $chartInit

    # Create legend text with actual values and scaling factors
    $legendText = @"


### PR Complexity Chart Legend

| Metric | Description | Actual Value Range | Scaling Factor |
|--------|-------------|-------------------|----------------|
| <span style='color:$($metricColors['Avg Files Changed'])'>■■■■</span> Avg Files Changed | Average number of files modified per PR | $([Math]::Round(($ComplexityChartData.FilesChangedValues | Measure-Object -Minimum).Minimum, 1))-$([Math]::Round($filesChangedMax, 1)) files | ×$filesChangedScaleFactor |
| <span style='color:$($metricColors['Avg Days to Complete'])'>■■■■</span> Avg Days to Complete | Average time (in days) taken to complete PRs | $([Math]::Round(($ComplexityChartData.CompletionDaysValues | Measure-Object -Minimum).Minimum, 1))-$([Math]::Round($completionDaysMax, 1)) days | ×$completionDaysScaleFactor |
| <span style='color:$($metricColors['Avg Files/Day'])'>■■■■</span> Avg Files/Day | Productivity metric (files changed divided by days to complete) | $([Math]::Round(($ComplexityChartData.FilesPerDayValues | Measure-Object -Minimum).Minimum, 1))-$([Math]::Round($filesPerDayMax, 1)) files/day | ×$filesPerDayScaleFactor |
| <span style='color:$($metricColors['Avg Lines/Day'])'>■■■■</span> Avg Lines/Day | Productivity metric (lines changed divided by days to complete) | $([Math]::Round(($ComplexityChartData.LinesPerDayValues | Measure-Object -Minimum).Minimum, 1))-$([Math]::Round($linesPerDayMax, 1)) lines/day | ×$linesPerDayScaleFactor |
| <span style='color:$($metricColors['Total Contributors'])'>■■■■</span> Total Contributors | Count of unique contributors (new + returning) per month | $([Math]::Round(($ComplexityChartData.ContributorCountValues | Measure-Object -Minimum).Minimum, 1))-$([Math]::Round($contributorCountMax, 1)) contributors | ×$contributorCountScaleFactor |

*Note: Scaling factors are applied to make different metrics comparable on the same chart.*
"@

    # Explicitly construct the chart section using string concatenation
    $complexityChartSection = $mermaidChart + $legendText


    Write-Verbose "Building Copilot impact metrics table"
    # Return the complete markdown section as a single string
    $markdown = @"
## GitHub Copilot Impact

The following chart shows PR complexity metrics over time:

$complexityChartSection

The following metrics show GitHub Copilot's impact on development productivity:

### Copilot Impact Metrics (% Change)

| Metric | Before Copilot | After Copilot | % Change |
|--------|---------------|--------------|----------|
| Files Changed per PR | $([Math]::Round($ImpactData.BeforeAvgFilesChanged, 1)) | $([Math]::Round($ImpactData.AfterAvgFilesChanged, 1)) | $($ImpactData.FilesChangedPercentChange)% |
| Lines Changed per PR | $([Math]::Round($ImpactData.BeforeAvgLinesChanged, 1)) | $([Math]::Round($ImpactData.AfterAvgLinesChanged, 1)) | $($ImpactData.LinesChangedPercentChange)% |
| Days to Complete PR | $([Math]::Round($ImpactData.BeforeAvgCompletionDays, 1)) | $([Math]::Round($ImpactData.AfterAvgCompletionDays, 1)) | $($ImpactData.CompletionTimePercentChange)% |
| Files Changed per Day | $([Math]::Round($beforeFilesPerDay, 1)) | $([Math]::Round($afterFilesPerDay, 1)) | $($filesPerDayPctChange)% |

**Note**: GitHub Copilot was introduced on $($AdoptionDate.ToString("MMMM d, yyyy")). PR completion time has $timeToCompleteDirection by $([Math]::Abs($timeToCompletePctChange))% since Copilot adoption, while developer productivity (measured by files changed per day) has $productivityDirection by $([Math]::Abs($filesPerDayPctChange))%.
"@
    Write-Verbose "Completed Get-CopilotImpactSection function"
    return $markdown
}

function Get-ReportFooter {
    <#
    .SYNOPSIS
    Generates a standardized footer for Azure DevOps reports.

    .DESCRIPTION
    Creates a consistent footer section for reports that includes generation date
    and basic statistics about the analyzed pull requests.

    .PARAMETER CompletedCount
    Number of completed pull requests.

    .PARAMETER ActiveCount
    Number of active pull requests.

    .PARAMETER AbandonedCount
    Number of abandoned pull requests.

    .PARAMETER Project
    The name of the Azure DevOps project.

    .EXAMPLE
    $footer = Get-ReportFooter -CompletedCount 120 -ActiveCount 15 -AbandonedCount 5 -Project "MyProject"
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [int]$CompletedCount,

        [Parameter(Mandatory=$true)]
        [int]$ActiveCount,

        [Parameter(Mandatory=$true)]
        [int]$AbandonedCount,

        [Parameter(Mandatory=$false)]
        [string]$Project = "this"
    )

    Write-Verbose "Starting Get-ReportFooter for project: $Project with $CompletedCount completed, $ActiveCount active, $AbandonedCount abandoned PRs"

    $totalPRs = $CompletedCount + $ActiveCount + $AbandonedCount
    Write-Verbose "Total PRs: $totalPRs"

    $footer = @"
## Report Generation

This report was generated on $(Get-Date -Format "yyyy-MM-dd") using data from all $totalPRs pull requests in the $Project project.
"@

    Write-Verbose "Completed Get-ReportFooter function"
    return $footer
}

function Get-ReportHeader {
    <#
    .SYNOPSIS
    Generates a standardized header for Azure DevOps reports.

    .DESCRIPTION
    Creates a consistent header section for reports that includes the title
    and basic information about the project and organization.

    .PARAMETER ReportTitle
    The title for the report.

    .PARAMETER Project
    The name of the Azure DevOps project.

    .PARAMETER Organization
    The name of the Azure DevOps organization.

    .EXAMPLE
    $header = Get-ReportHeader -ReportTitle "Monthly PR Analysis" -Project "MyProject" -Organization "MyOrg"
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]$ReportTitle,

        [Parameter(Mandatory=$true)]
        [string]$Project,

        [Parameter(Mandatory=$true)]
        [string]$Organization
    )

    Write-Verbose "Starting Get-ReportHeader for report: '$ReportTitle', project: $Project, organization: $Organization"

    $header = @"
<!-- markdownlint-disable MD033 -->
# $ReportTitle

## Overview

This analysis covers pull request activity for the $Project project in the $Organization organization.
"@

    Write-Verbose "Completed Get-ReportHeader function"
    return $header
}

function Get-IndustryBacklogSankeySection {
    <#
    .SYNOPSIS
    Creates a markdown section with a Mermaid Sankey diagram showing industry pillars, scenarios, capabilities, and features.

    .DESCRIPTION
    Generates a formatted markdown section with a Mermaid Sankey diagram visualizing the flow from
    industry pillars through scenarios and capabilities to backlog features using the simple CSV format.

    .PARAMETER SankeyData
    An object containing Nodes and Links arrays for the Sankey diagram.

    .EXAMPLE
    $sankeyData = Get-BacklogHierarchySankeyObject -BacklogCollection $collection
    $sankeySection = Get-IndustryBacklogSankeySection -SankeyData $sankeyData
    #>
    [OutputType([System.String])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [IndustryBacklogSankey]$SankeyData
    )

    Write-Host "Starting Get-IndustryBacklogSankeySection function with $($SankeyData.Links.Count) links"

    # Create a lookup for node names based on ID - no need to check for nulls
    $nodeNameLookup = @{}
    foreach ($node in $SankeyData.Nodes) {
        $nodeNameLookup[$node.Id] = $node.Name
        Write-Verbose "Added node to lookup: ID=$($node.Id), Name=$($node.Name), Type=$($node.Type)"
    }

    # Generate link data lines with proper format for Mermaid Sankey
    $linkDataLines = @()
    foreach ($link in $SankeyData.Links) {
        Write-Host "Processing link: Source=$($link.Source), Target=$($link.Target), Value=$($link.Value)"
        # Get source and target node names from lookup
        $sourceName = $nodeNameLookup[$link.Source]
        $targetName = $nodeNameLookup[$link.Target]

        # Handle special characters and quotes in names
        $sourceName = $sourceName -replace '"', '\"'
        $targetName = $targetName -replace '"', '\"'

        # Format as required by Mermaid sankey-beta: Source,Target,Value
        # Node names with spaces or special characters must be in quotes
        if ($sourceName -match '\s' -or $sourceName -match '[,"]') {
            $sourceName = """$sourceName"""
        }
        if ($targetName -match '\s' -or $targetName -match '[,"]') {
            $targetName = """$targetName"""
        }

        # Add formatted line with quoted names and value
        $linkDataLines += "$sourceName,$targetName,$($link.Value)"

        Write-Verbose "Added link: $sourceName -> $targetName ($($link.Value))"
    }

    # Define the triple backtick variable
    $tripleBacktick = '```'

    # Create the Mermaid block with proper formatting using the variable
    # Add HTML div wrapper with style attribute to control width
    $mermaidBlock = @"
$tripleBacktick mermaid

---
config:
  sankey:
    showValues: false
    width: 1200
    height: 1400
---
sankey-beta

$($linkDataLines -join "`n")
$tripleBacktick
"@

    # Create the complete markdown section
    $markdown = @"
## Industry Backlog Visualization

The following Sankey diagram visualizes the flow from scenarios through capabilities to specific backlog features.

Scenarios are weighted by the number of industry customers requiring them, and capabilities are weighted by the number of scenarios they support.

| | **Scenarios** | **Capabilities** | **Features** | |
|:-:|:------------------------------------------:|:--------------------------------------------:|:------------------------------------------:|:-:|
|   | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; | &emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp;&emsp; |   |

$mermaidBlock

*Note: Link widths represent the strength of relationships between connected items. The diagram shows the complex relationships between scenarios, capabilities, and features in the product backlog.*
"@

    Write-Verbose "Completed Get-IndustryBacklogSankeySection function"
    return $markdown
}

# Export all functions from this module in a single statement
Write-Verbose "Exporting AzDO-ReportGeneration module functions"
Export-ModuleMember -Function @(
    'Get-ReportSummary',
    'Get-PRMetricsByInterval',
    'Get-SLOComplianceTableContent',
    'Get-ContributorSummary',
    'Format-FileExtensionTable',
    'Get-FocusAreaSection',
    'Get-CopilotImpactSection',
    'Get-MermaidChart', # Keep exporting if needed elsewhere
    'Get-ReportFooter',
    'Get-ReportHeader',
    'Get-IndustryBacklogSankeySection'
)
