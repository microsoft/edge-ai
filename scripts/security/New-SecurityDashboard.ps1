#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Aggregates and displays security monitoring dashboard for supply chain security.

.DESCRIPTION
    Cross-platform PowerShell script that creates a comprehensive security monitoring dashboard
    by aggregating results from OSSF Scorecard, dependency pinning analysis, StepSecurity,
    and other security tools. Provides unified visibility into supply chain security posture.

.PARAMETER DataPath
    Root path containing security monitoring data files. Defaults to current directory.

.PARAMETER OutputFormat
    Output format for dashboard. Options: html, json, markdown, console.
    Default is 'html' for interactive dashboard.

.PARAMETER OutputPath
    Path where dashboard should be saved. Defaults to 'security-dashboard.html'.

.PARAMETER RefreshInterval
    Auto-refresh interval in seconds for live dashboard. Only applies to HTML format.
    Default is 300 seconds (5 minutes). Set to 0 to disable auto-refresh.

.PARAMETER IncludeSources
    Comma-separated list of security data sources to include. Options: ossf-scorecard,
    dependency-pinning, step-security, vulnerability-scan, license-scan.
    Default is all available sources.

.PARAMETER ThemeMode
    Visual theme for HTML dashboard. Options: light, dark, auto.
    Default is 'auto' (follows system preference).

.PARAMETER HistoricalData
    Include historical trend analysis if available. Default is true.

.PARAMETER AlertThresholds
    JSON string defining alert thresholds for different metrics.
    Example: '{"scorecard":{"critical":5,"warning":7},"pinning":{"critical":80,"warning":90}}'

.EXAMPLE
    ./New-SecurityDashboard.ps1
    Generate HTML security dashboard with default settings.

.EXAMPLE
    ./New-SecurityDashboard.ps1 -OutputFormat "markdown" -DataPath "/workspace/security-reports"
    Generate markdown dashboard from specific data directory.

.EXAMPLE
    ./New-SecurityDashboard.ps1 -RefreshInterval 60 -ThemeMode "dark" -HistoricalData $false
    Generate live HTML dashboard with dark theme and no historical data.

.NOTES
    Requires:
    - PowerShell 7.0 or later for cross-platform compatibility
    - Security monitoring data files from other security scripts
    - Write permissions for output file generation

    Compatible with:
    - Windows PowerShell 5.1+ (limited cross-platform features)
    - PowerShell 7.x on Windows, Linux, macOS
    - GitHub Actions runners (ubuntu-latest, windows-latest, macos-latest)
    - Azure DevOps agents (Microsoft-hosted and self-hosted)

.LINK
    https://github.com/microsoft/edge-ai
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$DataPath = ".",

    [Parameter(Mandatory = $false)]
    [ValidateSet('html', 'json', 'markdown', 'console')]
    [string]$OutputFormat = 'html',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'security-dashboard.html',

    [Parameter(Mandatory = $false)]
    [int]$RefreshInterval = 300,

    [Parameter(Mandatory = $false)]
    [string]$IncludeSources = "ossf-scorecard,dependency-pinning",

    [Parameter(Mandatory = $false)]
    [ValidateSet('light', 'dark', 'auto')]
    [string]$ThemeMode = 'auto',

    [Parameter(Mandatory = $false)]
    [string]$AlertThresholds = '{"scorecard":{"critical":5,"warning":7},"pinning":{"critical":80,"warning":90},"vulnerabilities":{"critical":0,"warning":2}}'
)

# Set error action preference for consistent error handling
$ErrorActionPreference = 'Stop'

class SecurityMetric {
    [string]$Name
    [string]$Source
    [decimal]$Value
    [string]$Status  # Critical, Warning, Good, Unknown
    [string]$Description
    [datetime]$Timestamp
    [hashtable]$Metadata

    SecurityMetric() {
        $this.Metadata = @{}
        $this.Timestamp = Get-Date
    }
}

class SecurityDashboard {
    [string]$Title
    [datetime]$GeneratedAt
    [string]$OverallStatus
    [decimal]$OverallScore
    [SecurityMetric[]]$Metrics
    [hashtable]$Summary
    [hashtable]$Trends
    [hashtable]$Alerts
    [hashtable]$Configuration

    SecurityDashboard() {
        $this.Title = "Supply Chain Security Dashboard"
        $this.GeneratedAt = Get-Date
        $this.Metrics = @()
        $this.Summary = @{}
        $this.Trends = @{}
        $this.Alerts = @{}
        $this.Configuration = @{}
    }
}

function Write-SecurityLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        'Info' { 'White' }
        'Warning' { 'Yellow' }
        'Error' { 'Red' }
        'Success' { 'Green' }
    }

    Write-Output "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Find-SecurityDataFile {
    <#
    .SYNOPSIS
    Discovers available security monitoring data files.
    #>
    param(
        [string]$SearchPath,
        [string[]]$Sources
    )

    $dataFiles = @{}

    # Define expected file patterns for different security tools
    $filePatterns = @{
        'ossf-scorecard'     = @('scorecard-results.json', '*scorecard*.json', '*ossf*.json')
        'dependency-pinning' = @('dependency-pinning-report.json', '*pinning*.json', '*dependency*.json')
        'step-security'      = @('step-security-report.json', '*step-security*.json', '*harden-runner*.json')
        'vulnerability-scan' = @('vulnerability-report.json', '*vuln*.json', '*security-scan*.json')
        'license-scan'       = @('license-report.json', '*license*.json', '*compliance*.json')
    }

    foreach ($source in $Sources) {
        if ($filePatterns.ContainsKey($source)) {
            $patterns = $filePatterns[$source]
            $foundFiles = @()

            foreach ($pattern in $patterns) {
                $searchPattern = Join-Path $SearchPath $pattern
                $files = Get-ChildItem -Path $searchPattern -Recurse -File -ErrorAction SilentlyContinue
                $foundFiles += $files
            }

            # Take the most recent file for each source
            if ($foundFiles) {
                $latestFile = $foundFiles | Sort-Object LastWriteTime -Descending | Select-Object -First 1
                $dataFiles[$source] = $latestFile.FullName
                Write-SecurityLog "Found $source data: $($latestFile.Name)" -Level Success
            }
            else {
                Write-SecurityLog "No data files found for $source" -Level Warning
            }
        }
    }

    return $dataFiles
}

function Import-OSSFScorecardData {
    <#
    .SYNOPSIS
    Imports and processes OSSF Scorecard data.
    #>
    param([string]$FilePath)

    try {
        $data = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        $metrics = @()

        # Overall score metric
        $scoreMetric = [SecurityMetric]::new()
        $scoreMetric.Name = "OSSF Scorecard Score"
        $scoreMetric.Source = "ossf-scorecard"
        $scoreMetric.Value = [decimal]$data.score
        $scoreMetric.Status = if ($data.score -ge 8) { 'Good' } elseif ($data.score -ge 6) { 'Warning' } else { 'Critical' }
        $scoreMetric.Description = "Overall OpenSSF Scorecard security assessment"
        $scoreMetric.Metadata['version'] = $data.scorecard.version
        $scoreMetric.Metadata['repository'] = $data.repo.name
        $scoreMetric.Metadata['commit'] = $data.repo.commit
        $metrics += $scoreMetric

        # Individual check metrics
        foreach ($check in $data.checks) {
            $checkMetric = [SecurityMetric]::new()
            $checkMetric.Name = $check.name
            $checkMetric.Source = "ossf-scorecard"
            $checkMetric.Value = [decimal]$check.score
            $checkMetric.Status = if ($check.score -eq 10) { 'Good' } elseif ($check.score -ge 7) { 'Warning' } else { 'Critical' }
            $checkMetric.Description = $check.reason
            $checkMetric.Metadata['documentation'] = $check.documentation.url
            $metrics += $checkMetric
        }

        return $metrics
    }
    catch {
        Write-SecurityLog "Error importing OSSF Scorecard data: $($_.Exception.Message)" -Level Error
        return @()
    }
}

function Import-DependencyPinningData {
    <#
    .SYNOPSIS
    Imports and processes dependency pinning compliance data.
    #>
    param([string]$FilePath)

    try {
        $data = Get-Content -Path $FilePath -Raw | ConvertFrom-Json
        $metrics = @()

        # Overall compliance score
        $complianceMetric = [SecurityMetric]::new()
        $complianceMetric.Name = "Dependency Pinning Compliance"
        $complianceMetric.Source = "dependency-pinning"
        $complianceMetric.Value = [decimal]$data.ComplianceScore
        $complianceMetric.Status = if ($data.ComplianceScore -ge 95) { 'Good' } elseif ($data.ComplianceScore -ge 85) { 'Warning' } else { 'Critical' }
        $complianceMetric.Description = "Percentage of dependencies properly pinned to immutable references"
        $complianceMetric.Metadata['totalDependencies'] = $data.TotalDependencies
        $complianceMetric.Metadata['unpinnedDependencies'] = $data.UnpinnedDependencies
        $complianceMetric.Metadata['scannedFiles'] = $data.ScannedFiles
        $metrics += $complianceMetric

        # Metrics by dependency type
        foreach ($typeKey in $data.Summary.PSObject.Properties.Name) {
            $typeData = $data.Summary.$typeKey
            $typeMetric = [SecurityMetric]::new()
            $typeMetric.Name = "Pinning Compliance - $typeKey"
            $typeMetric.Source = "dependency-pinning"
            $typeMetric.Value = if ($typeData.Total -gt 0) {
                [decimal](($typeData.Total - $typeData.High - $typeData.Medium) / $typeData.Total * 100)
            }
            else { 100 }
            $typeMetric.Status = if ($typeMetric.Value -ge 95) { 'Good' } elseif ($typeMetric.Value -ge 85) { 'Warning' } else { 'Critical' }
            $typeMetric.Description = "Pinning compliance for $typeKey dependencies"
            $typeMetric.Metadata['total'] = $typeData.Total
            $typeMetric.Metadata['violations'] = $typeData.High + $typeData.Medium
            $metrics += $typeMetric
        }

        return $metrics
    }
    catch {
        Write-SecurityLog "Error importing dependency pinning data: $($_.Exception.Message)" -Level Error
        return @()
    }
}





function Get-SecurityDashboardData {
    [CmdletBinding()]
    <#
    .SYNOPSIS
    Aggregates all security metrics into a dashboard data structure.
    #>
    param(
        [hashtable]$DataFiles,
        [string[]]$Sources,
        [hashtable]$Thresholds
    )

    $dashboard = [SecurityDashboard]::new()
    $allMetrics = @()

    # Import data from available sources
    foreach ($source in $Sources) {
        if ($DataFiles.ContainsKey($source)) {
            Write-SecurityLog "Processing $source data..." -Level Info

            switch ($source) {
                'ossf-scorecard' { $allMetrics += Import-OSSFScorecardData -FilePath $DataFiles[$source] }
                'dependency-pinning' { $allMetrics += Import-DependencyPinningData -FilePath $DataFiles[$source] }
                default {
                    Write-SecurityLog "Data import for source '$source' is not supported" -Level Warning
                }
            }
        }
    }

    $dashboard.Metrics = $allMetrics

    # Calculate overall status and score
    if ($allMetrics.Count -gt 0) {
        $criticalCount = ($allMetrics | Where-Object { $_.Status -eq 'Critical' }).Count
        $warningCount = ($allMetrics | Where-Object { $_.Status -eq 'Warning' }).Count

        $dashboard.OverallStatus = if ($criticalCount -gt 0) { 'Critical' }
        elseif ($warningCount -gt 0) { 'Warning' }
        else { 'Good' }

        # Calculate weighted overall score
        $totalScore = ($allMetrics | Measure-Object -Property Value -Average).Average
        $dashboard.OverallScore = [math]::Round($totalScore, 2)
    }
    else {
        $dashboard.OverallStatus = 'Unknown'
        $dashboard.OverallScore = 0
    }

    # Generate summary statistics
    $dashboard.Summary = @{
        TotalMetrics   = $allMetrics.Count
        CriticalIssues = ($allMetrics | Where-Object { $_.Status -eq 'Critical' }).Count
        WarningIssues  = ($allMetrics | Where-Object { $_.Status -eq 'Warning' }).Count
        GoodMetrics    = ($allMetrics | Where-Object { $_.Status -eq 'Good' }).Count
        DataSources    = $Sources.Count
        LastUpdate     = $dashboard.GeneratedAt
    }

    # Store configuration
    $dashboard.Configuration = @{
        IncludedSources   = $Sources
        AlertThresholds   = $Thresholds
        HistoricalEnabled = $HistoricalData
        RefreshInterval   = $RefreshInterval
    }

    return $dashboard
}

function Export-HTMLDashboard {
    <#
    .SYNOPSIS
    Exports dashboard as interactive HTML.
    #>
    param(
        [SecurityDashboard]$Dashboard,
        [string]$OutputPath,
        [string]$Theme,
        [int]$RefreshInterval
    )

    $html = @"
<!DOCTYPE html>
<html lang="en" data-theme="$Theme">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>$($Dashboard.Title)</title>
    <style>
        :root[data-theme="light"] {
            --bg-color: #ffffff;
            --text-color: #333333;
            --card-bg: #f8f9fa;
            --border-color: #dee2e6;
            --success-color: #28a745;
            --warning-color: #ffc107;
            --danger-color: #dc3545;
        }

        :root[data-theme="dark"] {
            --bg-color: #1a1a1a;
            --text-color: #ffffff;
            --card-bg: #2d2d2d;
            --border-color: #404040;
            --success-color: #28a745;
            --warning-color: #ffc107;
            --danger-color: #dc3545;
        }

        @media (prefers-color-scheme: dark) {
            :root[data-theme="auto"] {
                --bg-color: #1a1a1a;
                --text-color: #ffffff;
                --card-bg: #2d2d2d;
                --border-color: #404040;
                --success-color: #28a745;
                --warning-color: #ffc107;
                --danger-color: #dc3545;
            }
        }

        @media (prefers-color-scheme: light) {
            :root[data-theme="auto"] {
                --bg-color: #ffffff;
                --text-color: #333333;
                --card-bg: #f8f9fa;
                --border-color: #dee2e6;
                --success-color: #28a745;
                --warning-color: #ffc107;
                --danger-color: #dc3545;
            }
        }

        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background-color: var(--bg-color);
            color: var(--text-color);
            line-height: 1.6;
            padding: 20px;
        }

        .dashboard-header {
            text-align: center;
            margin-bottom: 30px;
            padding: 20px;
            background: var(--card-bg);
            border-radius: 10px;
            border: 1px solid var(--border-color);
        }

        .overall-status {
            font-size: 1.2em;
            font-weight: bold;
            padding: 10px 20px;
            border-radius: 25px;
            display: inline-block;
            margin: 10px;
        }

        .status-good { background-color: var(--success-color); color: white; }
        .status-warning { background-color: var(--warning-color); color: black; }
        .status-critical { background-color: var(--danger-color); color: white; }

        .metrics-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }

        .metric-card {
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 20px;
            transition: transform 0.2s;
        }

        .metric-card:hover {
            transform: translateY(-5px);
        }

        .metric-name {
            font-weight: bold;
            font-size: 1.1em;
            margin-bottom: 10px;
        }

        .metric-value {
            font-size: 2em;
            font-weight: bold;
            margin: 10px 0;
        }

        .metric-description {
            color: #666;
            font-size: 0.9em;
        }

        .metric-source {
            font-size: 0.8em;
            color: #888;
            margin-top: 10px;
        }

        .summary-stats {
            background: var(--card-bg);
            border: 1px solid var(--border-color);
            border-radius: 10px;
            padding: 20px;
            margin-top: 30px;
        }

        .stats-grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(150px, 1fr));
            gap: 15px;
            text-align: center;
        }

        .stat-item {
            padding: 10px;
        }

        .stat-number {
            font-size: 1.5em;
            font-weight: bold;
        }

        .last-updated {
            text-align: center;
            color: #888;
            font-size: 0.9em;
            margin-top: 20px;
        }

        .refresh-indicator {
            position: fixed;
            top: 20px;
            right: 20px;
            background: var(--card-bg);
            padding: 10px;
            border-radius: 5px;
            border: 1px solid var(--border-color);
        }

        @keyframes pulse {
            0%, 100% { opacity: 1; }
            50% { opacity: 0.5; }
        }

        .refreshing {
            animation: pulse 1s infinite;
        }
    </style>
</head>
<body>
    <div class="dashboard-header">
        <h1>$($Dashboard.Title)</h1>
        <div class="overall-status status-$(($Dashboard.OverallStatus).ToLower())">
            Status: $($Dashboard.OverallStatus)
        </div>
        <div style="margin-top: 10px;">
            <strong>Overall Score: $($Dashboard.OverallScore)/10</strong>
        </div>
    </div>

    <div class="metrics-grid">
"@

    # Add metric cards
    foreach ($metric in $Dashboard.Metrics) {
        $statusClass = ($metric.Status).ToLower()
        $html += @"
        <div class="metric-card">
            <div class="metric-name">$($metric.Name)</div>
            <div class="metric-value status-$statusClass">$($metric.Value)</div>
            <div class="metric-description">$($metric.Description)</div>
            <div class="metric-source">Source: $($metric.Source)</div>
        </div>
"@
    }

    # Add summary statistics
    $html += @"
    </div>

    <div class="summary-stats">
        <h2>Summary Statistics</h2>
        <div class="stats-grid">
            <div class="stat-item">
                <div class="stat-number status-good">$($Dashboard.Summary.GoodMetrics)</div>
                <div>Good</div>
            </div>
            <div class="stat-item">
                <div class="stat-number status-warning">$($Dashboard.Summary.WarningIssues)</div>
                <div>Warnings</div>
            </div>
            <div class="stat-item">
                <div class="stat-number status-critical">$($Dashboard.Summary.CriticalIssues)</div>
                <div>Critical</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">$($Dashboard.Summary.TotalMetrics)</div>
                <div>Total Metrics</div>
            </div>
            <div class="stat-item">
                <div class="stat-number">$($Dashboard.Summary.DataSources)</div>
                <div>Data Sources</div>
            </div>
        </div>
    </div>

    <div class="last-updated">
        Last Updated: $($Dashboard.GeneratedAt.ToString('yyyy-MM-dd HH:mm:ss'))
    </div>
"@

    # Add auto-refresh if enabled
    if ($RefreshInterval -gt 0) {
        $html += @"

    <div class="refresh-indicator" id="refreshIndicator">
        Next refresh in: <span id="countdown">$RefreshInterval</span>s
    </div>

    <script>
        let refreshTimer = $RefreshInterval;
        let countdownInterval;

        function startCountdown() {
            const countdownElement = document.getElementById('countdown');
            const refreshIndicator = document.getElementById('refreshIndicator');

            countdownInterval = setInterval(() => {
                refreshTimer--;
                countdownElement.textContent = refreshTimer;

                if (refreshTimer <= 0) {
                    clearInterval(countdownInterval);
                    refreshIndicator.classList.add('refreshing');
                    refreshIndicator.innerHTML = 'Refreshing...';
                    window.location.reload();
                }
            }, 1000);
        }

        // Start countdown on page load
        startCountdown();
    </script>
"@
    }

    $html += @"
</body>
</html>
"@

    $html | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-SecurityLog "HTML dashboard exported to: $OutputPath" -Level Success
}

function Export-MarkdownDashboard {
    <#
    .SYNOPSIS
    Exports dashboard as markdown report.
    #>
    param(
        [SecurityDashboard]$Dashboard,
        [string]$OutputPath
    )

    $markdown = @"
# $($Dashboard.Title)

**Generated:** $($Dashboard.GeneratedAt.ToString('yyyy-MM-dd HH:mm:ss'))
**Overall Status:** $($Dashboard.OverallStatus)
**Overall Score:** $($Dashboard.OverallScore)/10

## Summary

| Metric | Count |
|--------|--------|
| Total Metrics | $($Dashboard.Summary.TotalMetrics) |
| Good Status | $($Dashboard.Summary.GoodMetrics) |
| Warning Issues | $($Dashboard.Summary.WarningIssues) |
| Critical Issues | $($Dashboard.Summary.CriticalIssues) |
| Data Sources | $($Dashboard.Summary.DataSources) |

## Security Metrics

| Name | Value | Status | Source | Description |
|------|-------|--------|--------|-------------|
"@

    foreach ($metric in $Dashboard.Metrics) {
        $markdown += "| $($metric.Name) | $($metric.Value) | $($metric.Status) | $($metric.Source) | $($metric.Description) |`n"
    }

    $markdown += @"

## Configuration

- **Included Sources:** $($Dashboard.Configuration.IncludedSources -join ', ')
- **Historical Data:** $($Dashboard.Configuration.HistoricalEnabled)
- **Auto-Refresh:** $(if ($Dashboard.Configuration.RefreshInterval -gt 0) { "$($Dashboard.Configuration.RefreshInterval) seconds" } else { "Disabled" })

---
*Dashboard generated by Edge AI Security Monitoring*
"@

    $markdown | Out-File -FilePath $OutputPath -Encoding UTF8
    Write-SecurityLog "Markdown dashboard exported to: $OutputPath" -Level Success
}

function Export-ConsoleDashboard {
    <#
    .SYNOPSIS
    Displays dashboard in console format.
    #>
    param([SecurityDashboard]$Dashboard)

    # Console display with colors
    Write-Output ""
    Write-Output "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Output "               $($Dashboard.Title)" -ForegroundColor White
    Write-Output "═══════════════════════════════════════════════════════════" -ForegroundColor Cyan
    Write-Output ""

    # Overall status
    $statusColor = switch ($Dashboard.OverallStatus) {
        'Good' { 'Green' }
        'Warning' { 'Yellow' }
        'Critical' { 'Red' }
        default { 'White' }
    }

    Write-Output "Overall Status: " -NoNewline
    Write-Output $Dashboard.OverallStatus -ForegroundColor $statusColor
    Write-Output "Overall Score:  $($Dashboard.OverallScore)/10"
    Write-Output "Generated:      $($Dashboard.GeneratedAt.ToString('yyyy-MM-dd HH:mm:ss'))"
    Write-Output ""

    # Summary
    Write-Output "Summary:" -ForegroundColor White
    Write-Output "  Good Metrics:     " -NoNewline; Write-Output $Dashboard.Summary.GoodMetrics -ForegroundColor Green
    Write-Output "  Warning Issues:   " -NoNewline; Write-Output $Dashboard.Summary.WarningIssues -ForegroundColor Yellow
    Write-Output "  Critical Issues:  " -NoNewline; Write-Output $Dashboard.Summary.CriticalIssues -ForegroundColor Red
    Write-Output "  Total Metrics:    $($Dashboard.Summary.TotalMetrics)"
    Write-Output ""

    # Metrics
    Write-Output "Security Metrics:" -ForegroundColor White
    foreach ($metric in $Dashboard.Metrics) {
        $metricColor = switch ($metric.Status) {
            'Good' { 'Green' }
            'Warning' { 'Yellow' }
            'Critical' { 'Red' }
            default { 'White' }
        }

        Write-Output "  $($metric.Name): " -NoNewline
        Write-Output "$($metric.Value) " -ForegroundColor $metricColor -NoNewline
        Write-Output "($($metric.Status)) - $($metric.Source)"
    }

    Write-Output ""
}

# Main execution
try {
    Write-SecurityLog "Generating security monitoring dashboard..." -Level Info
    Write-SecurityLog "PowerShell Version: $($PSVersionTable.PSVersion)" -Level Info
    Write-SecurityLog "Platform: $($PSVersionTable.Platform)" -Level Info

    # Parse parameters
    $sourcesToInclude = $IncludeSources.Split(',') | ForEach-Object { $_.Trim() }
    $alertThresholds = $AlertThresholds | ConvertFrom-Json

    Write-SecurityLog "Data path: $DataPath" -Level Info
    Write-SecurityLog "Output format: $OutputFormat" -Level Info
    Write-SecurityLog "Include sources: $($sourcesToInclude -join ', ')" -Level Info

    # Discover security data files
    $dataFiles = Find-SecurityDataFile -SearchPath $DataPath -Sources $sourcesToInclude

    if ($dataFiles.Count -eq 0) {
        Write-SecurityLog "No security data files found in $DataPath" -Level Warning
        Write-SecurityLog "Ensure security monitoring scripts have been executed and data files are available" -Level Warning
    }

    # Generate dashboard data
    $dashboard = Get-SecurityDashboardData -DataFiles $dataFiles -Sources $sourcesToInclude -Thresholds $alertThresholds

    # Export dashboard in requested format
    switch ($OutputFormat.ToLower()) {
        'html' {
            Export-HTMLDashboard -Dashboard $dashboard -OutputPath $OutputPath -Theme $ThemeMode -RefreshInterval $RefreshInterval
        }
        'markdown' {
            Export-MarkdownDashboard -Dashboard $dashboard -OutputPath $OutputPath
        }
        'json' {
            $dashboard | ConvertTo-Json -Depth 10 | Out-File -FilePath $OutputPath -Encoding UTF8
            Write-SecurityLog "JSON dashboard exported to: $OutputPath" -Level Success
        }
        'console' {
            Export-ConsoleDashboard -Dashboard $dashboard
        }
    }

    # Display summary
    Write-SecurityLog "Dashboard generation completed successfully!" -Level Success
    Write-SecurityLog "Overall Status: $($dashboard.OverallStatus)" -Level Info
    Write-SecurityLog "Overall Score: $($dashboard.OverallScore)/10" -Level Info
    Write-SecurityLog "Metrics Processed: $($dashboard.Summary.TotalMetrics)" -Level Info

    if ($dashboard.Summary.CriticalIssues -gt 0) {
        Write-SecurityLog "$($dashboard.Summary.CriticalIssues) critical security issues require immediate attention" -Level Warning
    }

}
catch {
    Write-SecurityLog "Dashboard generation failed: $($_.Exception.Message)" -Level Error
    Write-SecurityLog "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
