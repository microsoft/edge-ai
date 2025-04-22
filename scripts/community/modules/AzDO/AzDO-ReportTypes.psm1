# AzDO-ReportTypes.psm1
# Type definitions for Azure DevOps report generation

# Class to represent focus area chart data for reporting
class FocusAreaMetrics{
    [string[]]$Labels
    [string[]]$Areas
    [System.Collections.Generic.Dictionary[string,double[]]]$Values
    [System.Collections.Generic.Dictionary[string,string]]$ColorMap

    FocusAreaMetrics() {
        # Default constructor
        $this.Labels = @()
        $this.Areas = @()
        $this.Values = [System.Collections.Generic.Dictionary[string,double[]]]::new()
        $this.ColorMap = [System.Collections.Generic.Dictionary[string,string]]::new()
    }

    FocusAreaMetrics([string[]]$labels, [string[]]$areas,
                       [System.Collections.Generic.Dictionary[string,double[]]]$values,
                       [System.Collections.Generic.Dictionary[string,string]]$colorMap) {
        $this.Labels = $labels
        $this.Areas = $areas
        $this.Values = $values
        $this.ColorMap = $colorMap
    }
}

# Class to represent file extension data for reporting
class FileExtensionData {
    [string]$FileType
    [object]$CurrentBranchFiles  # Could be int or string (for "N/A")
    [string]$PercentOfFiles
    [int]$PRChangesCount
    [string]$PercentOfChanges

    FileExtensionData() {
        # Default constructor
    }

    FileExtensionData([string]$fileType, [object]$currentBranchFiles, [string]$percentOfFiles, [int]$prChangesCount, [string]$percentOfChanges) {
        $this.FileType = $fileType
        $this.CurrentBranchFiles = $currentBranchFiles
        $this.PercentOfFiles = $percentOfFiles
        $this.PRChangesCount = $prChangesCount
        $this.PercentOfChanges = $percentOfChanges
    }
}

# Class to represent a collection of file extension data with summary information
class FileExtensionSummary {
    [FileExtensionData[]]$Extensions
    [int]$TotalBranchFiles
    [int]$TotalPRChanges

    FileExtensionSummary() {
        $this.Extensions = @()
        $this.TotalBranchFiles = 0
        $this.TotalPRChanges = 0
    }

    FileExtensionSummary([FileExtensionData[]]$extensions, [int]$totalBranchFiles, [int]$totalPRChanges) {
        $this.Extensions = $extensions
        $this.TotalBranchFiles = $totalBranchFiles
        $this.TotalPRChanges = $totalPRChanges
    }
}

# Class to represent report summary statistics
class AzDOReportSummary {
    [int]$CompletedCount
    [int]$ActiveCount
    [int]$AbandonedCount
    [double]$AvgDaysToComplete
    [int]$TotalContributors

    AzDOReportSummary() {
        # Default constructor
        $this.CompletedCount = 0
        $this.ActiveCount = 0
        $this.AbandonedCount = 0
        $this.AvgDaysToComplete = 0
        $this.TotalContributors = 0
    }

    AzDOReportSummary([int]$completed, [int]$active, [int]$abandoned, [double]$avgDays, [int]$contributors) {
        $this.CompletedCount = $completed
        $this.ActiveCount = $active
        $this.AbandonedCount = $abandoned
        $this.AvgDaysToComplete = $avgDays
        $this.TotalContributors = $contributors
    }

    [int] GetTotalPullRequests() {
        return $this.CompletedCount + $this.ActiveCount + $this.AbandonedCount
    }
}

# Chart data for PR activity charts
class ChartData {
    [string[]]$Labels
    [object[]]$Values  # Using object[] to allow various numeric types

    ChartData() {
        # Default constructor
        $this.Labels = @()
        $this.Values = @()
    }

    ChartData([string[]]$labels, [object[]]$values) {
        $this.Labels = $labels
        $this.Values = $values
    }
}

# Metrics about PR sizes and their completion times
class PRSizeMetricsData {
    [double]$SmallPRAvgTime
    [double]$MediumPRAvgTime
    [double]$LargePRAvgTime

    PRSizeMetricsData() {
        # Default constructor
        $this.SmallPRAvgTime = 0
        $this.MediumPRAvgTime = 0
        $this.LargePRAvgTime = 0
    }

    PRSizeMetricsData([double]$smallTime, [double]$mediumTime, [double]$largeTime) {
        $this.SmallPRAvgTime = $smallTime
        $this.MediumPRAvgTime = $mediumTime
        $this.LargePRAvgTime = $largeTime
    }
}

class PRMetricsIntervalData {
    [ChartData]$CreatedPRs
    [ChartData]$CompletedPRs
    [ChartData]$WeeklyCompletionMetrics
    [PRSizeMetricsData]$PRSizeMetrics
    [int]$UnderOneDayCount
    [int]$OneToThreeDaysCount
    [int]$FourToSevenDaysCount
    [int]$OverSevenDaysCount

    PRMetricsIntervalData() {
        # Default constructor
    }

    PRMetricsIntervalData(
        [ChartData]$createdPRs,
        [ChartData]$completedPRs,
        [ChartData]$weeklyCompletionMetrics,
        [PRSizeMetricsData]$prSizeMetrics,
        [int]$underOneDayCount,
        [int]$oneToThreeDaysCount,
        [int]$fourToSevenDaysCount,
        [int]$overSevenDaysCount
    ) {
        $this.CreatedPRs = $createdPRs
        $this.CompletedPRs = $completedPRs
        $this.WeeklyCompletionMetrics = $weeklyCompletionMetrics
        $this.PRSizeMetrics = $prSizeMetrics
        $this.UnderOneDayCount = $underOneDayCount
        $this.OneToThreeDaysCount = $oneToThreeDaysCount
        $this.FourToSevenDaysCount = $fourToSevenDaysCount
        $this.OverSevenDaysCount = $overSevenDaysCount
    }
}

# Class to represent SLO compliance data for each time period (typically weekly)
class SLOComplianceItem {
    [string]$Week
    [int]$Total
    [int]$MetSLO
    [double]$CompliancePercentage

    # Default constructor
    SLOComplianceItem() {
        $this.Week = "Unknown"
        $this.Total = 0
        $this.MetSLO = 0
        $this.CompliancePercentage = 0.0
    }

    # Constructor with all properties
    SLOComplianceItem([string]$week, [int]$total, [int]$metSLO, [double]$compliancePercentage) {
        $this.Week = $week
        $this.Total = $total
        $this.MetSLO = $metSLO
        $this.CompliancePercentage = $compliancePercentage
    }

    # New constructor including ClosedPRCount
    SLOComplianceItem([string]$week, [int]$total, [int]$metSLO, [double]$compliancePercentage, [int]$closedPRCount) {
        $this.Week = $week
        $this.Total = $total
        $this.MetSLO = $metSLO
        $this.CompliancePercentage = $compliancePercentage
    }
}

# Class to represent Copilot impact metrics data for reporting
class CopilotImpactData {
    [int]$BeforePRCount
    [int]$AfterPRCount
    [double]$BeforeAvgCompletionDays
    [double]$AfterAvgCompletionDays
    [double]$CompletionTimePercentChange
    [double]$BeforeAvgFilesChanged
    [double]$AfterAvgFilesChanged
    [double]$FilesChangedPercentChange
    [double]$BeforeAvgLinesChanged
    [double]$AfterAvgLinesChanged
    [double]$LinesChangedPercentChange
    [double]$BeforeAvgComments
    [double]$AfterAvgComments
    [double]$CommentsPercentChange
    [double]$BeforeRejectionRate
    [double]$AfterRejectionRate
    [double]$RejectionRatePercentChange

    CopilotImpactData(
        [int]$beforePRCount,
        [int]$afterPRCount,
        [double]$beforeAvgCompletionDays,
        [double]$afterAvgCompletionDays,
        [double]$completionTimePercentChange,
        [double]$beforeAvgFilesChanged,
        [double]$afterAvgFilesChanged,
        [double]$filesChangedPercentChange,
        [double]$beforeAvgLinesChanged,
        [double]$afterAvgLinesChanged,
        [double]$linesChangedPercentChange,
        [double]$beforeAvgComments,
        [double]$afterAvgComments,
        [double]$commentsPercentChange,
        [double]$beforeRejectionRate,
        [double]$afterRejectionRate,
        [double]$rejectionRatePercentChange
    ) {
        $this.BeforePRCount = $beforePRCount
        $this.AfterPRCount = $afterPRCount
        $this.BeforeAvgCompletionDays = $beforeAvgCompletionDays
        $this.AfterAvgCompletionDays = $afterAvgCompletionDays
        $this.CompletionTimePercentChange = $completionTimePercentChange
        $this.BeforeAvgFilesChanged = $beforeAvgFilesChanged
        $this.AfterAvgFilesChanged = $afterAvgFilesChanged
        $this.FilesChangedPercentChange = $filesChangedPercentChange
        $this.BeforeAvgLinesChanged = $beforeAvgLinesChanged
        $this.AfterAvgLinesChanged = $afterAvgLinesChanged
        $this.LinesChangedPercentChange = $linesChangedPercentChange
        $this.BeforeAvgComments = $beforeAvgComments
        $this.AfterAvgComments = $afterAvgComments
        $this.CommentsPercentChange = $commentsPercentChange
        $this.BeforeRejectionRate = $beforeRejectionRate
        $this.AfterRejectionRate = $afterRejectionRate
        $this.RejectionRatePercentChange = $rejectionRatePercentChange
    }
}

# Class to represent PR complexity chart data for reporting
class PRComplexityChartData {
    [string[]]$TimeLabels
    [double[]]$FilesChangedValues
    [double[]]$CompletionDaysValues
    [double[]]$FilesPerDayValues
    [double[]]$LinesPerDayValues  # New property for lines changed per day
    [int[]]$ContributorCountValues

    PRComplexityChartData() {
        # Default constructor
        $this.TimeLabels = @()
        $this.FilesChangedValues = @()
        $this.CompletionDaysValues = @()
        $this.FilesPerDayValues = @()
        $this.LinesPerDayValues = @()  # Initialize the new property
        $this.ContributorCountValues = @()
    }

    PRComplexityChartData(
        [string[]]$timeLabels,
        [double[]]$filesChangedValues,
        [double[]]$completionDaysValues,
        [double[]]$filesPerDayValues,
        [double[]]$linesPerDayValues,  # Add parameter for new property
        [int[]]$contributorCountValues
    ) {
        $this.TimeLabels = $timeLabels
        $this.FilesChangedValues = $filesChangedValues
        $this.CompletionDaysValues = $completionDaysValues
        $this.FilesPerDayValues = $filesPerDayValues
        $this.LinesPerDayValues = $linesPerDayValues  # Assign the new property
        $this.ContributorCountValues = $contributorCountValues
    }
}

# Class to represent individual contributor metrics
class ContributorMetrics {
    [string]$Contributor
    [int]$PRs
    [double]$CompletionRate
    [double]$AvgTimeToComplete
    [int]$FilesChanged
    [int]$LinesAdded
    [int]$LinesDeleted
    [int]$WorkItemsClosed

    # Default constructor
    ContributorMetrics() {
        $this.Contributor = ""
        $this.PRs = 0
        $this.CompletionRate = 0.0
        $this.AvgTimeToComplete = 0.0
        $this.FilesChanged = 0
        $this.LinesAdded = 0
        $this.LinesDeleted = 0
        $this.WorkItemsClosed = 0
    }

    # Constructor with all properties
    ContributorMetrics(
        [string]$contributor,
        [int]$prs,
        [double]$completionRate,
        [double]$avgTimeToComplete,
        [int]$filesChanged,
        [int]$linesAdded,
        [int]$linesDeleted,
        [int]$workItemsClosed
    ) {
        $this.Contributor = $contributor
        $this.PRs = $prs
        $this.CompletionRate = $completionRate
        $this.AvgTimeToComplete = $avgTimeToComplete
        $this.FilesChanged = $filesChanged
        $this.LinesAdded = $linesAdded
        $this.LinesDeleted = $linesDeleted
        $this.WorkItemsClosed = $workItemsClosed
    }
}

class TechCategory {
    [string]$Name
    [string]$Color
    [string[]]$Keywords
    [int]$Count

    TechCategory([string]$name, [string]$color, [string[]]$keywords) {
        $this.Name = $name
        $this.Color = $color
        $this.Keywords = $keywords
        $this.Count = 0
    }

    [bool]ContainsKeyword([string]$text) {
        foreach ($keyword in $this.Keywords) {
            if ($text -match $keyword) {
                return $true
            }
        }
        return $false
    }

    IncrementCount() {
        $this.Count++
    }

    Reset() {
        $this.Count = 0
    }
}

class TechCategoryCollection {
    [System.Collections.Hashtable]$Categories

    TechCategoryCollection() {
        $this.Categories = @{}

        # Initialize with all standard categories
        $this.AddCategory("Documentation", "#36A2EB", "(doc|readme|wiki|guide|tutorial|explanation|markdown|md)")
        $this.AddCategory("Bug Fixes", "#4BC0C0", "(fix|bug|issue|problem|error|crash|exception|fault)")
        $this.AddCategory("Features", "#9966FF", "(feature|enhancement|implement|add|new)")
        $this.AddCategory("CI/CD", "#FF6384", "(ci|cd|pipeline|action|build|test|automate|devops)")
        $this.AddCategory("Refactoring", "#8B8000", "(refactor|clean|improve|simplify|restructure|reorg)")
        $this.AddCategory("Terraform", "#FF9F40", "(terraform|tf\.|hcl|tfvars)")
        $this.AddCategory("Bicep/ARM", "#C9CBCF", "(bicep|arm template|bicepparam|azuredeploy)")
        $this.AddCategory("PowerShell", "#7AC142", "(powershell|ps1|psd1|psm1)")
        $this.AddCategory("Python", "#3775A9", "(python|py|\.py)")
        $this.AddCategory("IoT Operations", "#F58220", "(iot|operations|mqtt|broker|akri|sensor)")
        $this.AddCategory("Kubernetes", "#326CE5", "(kubernetes|k8s|k3s|helm|cncf|cluster)")
        $this.AddCategory("Security", "#EE0000", "(security|auth|permission|vulnerability|secure)")
        $this.AddCategory("Other/Unknown", "#808080", "(other|misc|unknown)")
    }

    [void]AddCategory([string]$name, [string]$color, [string]$keywordPattern) {
        $keywords = @($keywordPattern)
        $this.Categories[$name] = [TechCategory]::new($name, $color, $keywords)
    }

    [void]CategorizeText([string]$text) {
        $text = $text.ToLower()
        $foundMatch = $false

        foreach ($category in $this.Categories.Values) {
            if ($category.ContainsKeyword($text)) {
                $category.IncrementCount()
                $foundMatch = $true
                # Don't return here - one text can match multiple categories
            }
        }

        # If no categories matched, increment Other/Unknown
        if (-not $foundMatch -and $this.Categories.ContainsKey("Other/Unknown")) {
            $this.Categories["Other/Unknown"].IncrementCount()
        }
    }

    [void]ResetAllCounts() {
        foreach ($category in $this.Categories.Values) {
            $category.Reset()
        }
    }

    [hashtable]ToHashtable() {
        $result = @{}
        foreach ($category in $this.Categories.Values) {
            $result[$category.Name] = $category.Count
        }
        return $result
    }

    [hashtable]GetColorMap() {
        $result = @{}
        foreach ($category in $this.Categories.Values) {
            $result[$category.Name] = $category.Color
        }
        return $result
    }

    [TechCategory[]]GetNonEmptyCategories() {
        return @($this.Categories.Values | Where-Object { $_.Count -gt 0 } | Sort-Object -Property Count -Descending)
    }
}

# Class to represent contributor return metrics over time
class ReturningContributorMetric {
    [string[]]$MonthLabels
    [int[]]$NewContributors
    [int[]]$ReturningContributors

    # Default constructor
    ReturningContributorMetric() {
        $this.MonthLabels = @()
        $this.NewContributors = @()
        $this.ReturningContributors = @()
    }

    # Constructor with parameters
    ReturningContributorMetric(
        [string[]]$monthLabels,
        [int[]]$newContributors,
        [int[]]$returningContributors
    ) {
        $this.MonthLabels = $monthLabels
        $this.NewContributors = $newContributors
        $this.ReturningContributors = $returningContributors
    }
}

# Class to represent reviewer metrics for reporting
class ReviewerMetrics {
    [string]$Reviewer
    [int]$Approvals
    [int]$Comments
    [int]$PRsReviewed

    # Default constructor
    ReviewerMetrics() {
        $this.Reviewer = ""
        $this.Approvals = 0
        $this.Comments = 0
        $this.PRsReviewed = 0
    }

    # Constructor with all properties
    ReviewerMetrics(
        [string]$reviewer,
        [int]$approvals,
        [int]$comments,
        [int]$prsReviewed
    ) {
        $this.Reviewer = $reviewer
        $this.Approvals = $approvals
        $this.Comments = $comments
        $this.PRsReviewed = $prsReviewed
    }
}

Export-ModuleMember -Variable *
