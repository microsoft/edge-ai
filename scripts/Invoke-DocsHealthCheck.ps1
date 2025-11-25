#Requires -Version 7.0

<#
.SYNOPSIS
    Perform health checks on deployed Docsify documentation site.

.DESCRIPTION
    Performs comprehensive health checks on deployed Docsify documentation site.
    Can be used in CI/CD pipelines or for monitoring deployed sites.

    The script validates site accessibility, Docsify configuration, URL replacement,
    navigation, assets, and search functionality.

.PARAMETER SiteUrl
    The base URL of the documentation site to check.

.PARAMETER Timeout
    Request timeout in seconds. Defaults to 10 seconds.

.PARAMETER OutputJson
    Output detailed results in JSON format.

.PARAMETER UserAgent
    Custom User-Agent string for requests. Defaults to 'EdgeAI-Docs-Health-Check/1.0'.

.EXAMPLE
    .\Invoke-DocsHealthCheck.ps1 -SiteUrl "https://microsoft.github.io/edge-ai"
    Performs health checks on the specified site.

.EXAMPLE
    .\Invoke-DocsHealthCheck.ps1 -SiteUrl "https://microsoft.github.io/edge-ai" -OutputJson
    Performs health checks and outputs detailed JSON results.

.EXAMPLE
    .\Invoke-DocsHealthCheck.ps1 -SiteUrl "http://localhost:3000" -Timeout 5
    Performs health checks on local development site with custom timeout.

.NOTES
    Exit codes:
    - 0: All checks passed
    - 1: One or more critical checks failed
    - 2: Invalid parameters or unexpected error
#>

# Suppress PSScriptAnalyzer false positives - these parameters are actually used
# Timeout is used in: Invoke-WebRequest -TimeoutSec $TimeoutSeconds (via $script:Timeout)
# UserAgent is used in: Invoke-WebRequest -UserAgent $RequestUserAgent (via $script:UserAgent)
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'Timeout')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'UserAgent')]
[CmdletBinding()]
param(
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$SiteUrl,

    [Parameter(Mandatory = $false)]
    [int]$Timeout = 10,

    [Parameter(Mandatory = $false)]
    [switch]$OutputJson,

    [Parameter(Mandatory = $false)]
    [string]$UserAgent = 'EdgeAI-Docs-Health-Check/1.0'
)

# Error handling
$ErrorActionPreference = 'Stop'

# Validate URL format
try {
    $null = [System.Uri]::new($SiteUrl)
} catch {
    Write-Error "❌ Error: Invalid URL format: $SiteUrl"
    exit 2
}

# Health check results structure
$script:Results = @{
    baseUrl = $SiteUrl
    timestamp = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ss.fffZ')
    checks = @()
    summary = @{
        passed = 0
        failed = 0
        warnings = 0
    }
}

function Invoke-WebRequestWithTimeout {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Uri,

        [Parameter(Mandatory = $false)]
        [int]$TimeoutSeconds = $script:Timeout,

        [Parameter(Mandatory = $false)]
        [string]$RequestUserAgent = $script:UserAgent
    )

    try {
        $response = Invoke-WebRequest -Uri $Uri -UserAgent $RequestUserAgent -TimeoutSec $TimeoutSeconds -ErrorAction Stop
        return @{
            StatusCode = $response.StatusCode
            Headers = $response.Headers
            Content = $response.Content
        }
    } catch {
        throw $_.Exception
    }
}

function Test-SiteAccessibility {
    param([string]$BaseUrl)

    try {
        $response = Invoke-WebRequestWithTimeout -Uri $BaseUrl

        if ($response.StatusCode -eq 200) {
            return @{
                passed = $true
                message = 'Site is accessible'
                severity = 'success'
            }
        } else {
            return @{
                passed = $false
                message = "HTTP $($response.StatusCode)"
                severity = 'error'
            }
        }
    } catch {
        return @{
            passed = $false
            message = "Error: $($_.Exception.Message)"
            severity = 'error'
        }
    }
}

function Test-DocsifySetup {
    param([string]$BaseUrl)

    try {
        $response = Invoke-WebRequestWithTimeout -Uri $BaseUrl

        if ($response.Content -notmatch 'docsify') {
            return @{
                passed = $false
                message = 'Docsify not detected in page content'
                severity = 'error'
            }
        }

        if ($response.Content -notmatch '\$docsify') {
            return @{
                passed = $false
                message = 'Docsify configuration not found'
                severity = 'error'
            }
        }

        return @{
            passed = $true
            message = 'Docsify properly configured'
            severity = 'success'
        }
    } catch {
        return @{
            passed = $false
            message = "Error: $($_.Exception.Message)"
            severity = 'error'
        }
    }
}

function Test-UrlConfiguration {
    param([string]$BaseUrl)

    try {
        $response = Invoke-WebRequestWithTimeout -Uri $BaseUrl

        if ($response.Content -notmatch 'EDGE_AI_URL_CONFIG') {
            return @{
                passed = $false
                message = 'URL configuration not found'
                severity = 'error'
            }
        }

        if ($response.Content -notmatch 'docsify-url-config\.js') {
            return @{
                passed = $false
                message = 'URL configuration script not referenced'
                severity = 'error'
            }
        }

        return @{
            passed = $true
            message = 'URL configuration properly set up'
            severity = 'success'
        }
    } catch {
        return @{
            passed = $false
            message = "Error: $($_.Exception.Message)"
            severity = 'error'
        }
    }
}

function Test-SidebarNavigation {
    param([string]$BaseUrl)

    $sidebarUrl = "$BaseUrl/docs/_parts/_sidebar.md"

    try {
        $response = Invoke-WebRequestWithTimeout -Uri $sidebarUrl

        if ($response.StatusCode -ne 200) {
            return @{
                passed = $false
                message = "Sidebar not accessible: HTTP $($response.StatusCode)"
                severity = 'error'
            }
        }

        if ($response.Content -notmatch 'Getting Started' -and $response.Content -notmatch 'Project Planning') {
            return @{
                passed = $false
                message = 'Sidebar appears empty or malformed'
                severity = 'error'
            }
        }

        return @{
            passed = $true
            message = 'Sidebar navigation is accessible'
            severity = 'success'
        }
    } catch {
        return @{
            passed = $false
            message = "Error: $($_.Exception.Message)"
            severity = 'error'
        }
    }
}

function Test-AssetsAvailability {
    param([string]$BaseUrl)

    $assetUrl = "$BaseUrl/docs/assets/logo.png"

    try {
        $response = Invoke-WebRequestWithTimeout -Uri $assetUrl

        if ($response.StatusCode -ne 200) {
            return @{
                passed = $false
                message = "Assets not accessible: HTTP $($response.StatusCode)"
                severity = 'warning'
            }
        }

        return @{
            passed = $true
            message = 'Assets are accessible'
            severity = 'success'
        }
    } catch {
        return @{
            passed = $false
            message = "Assets not accessible: $($_.Exception.Message)"
            severity = 'warning'
        }
    }
}

function Test-SearchFunctionality {
    param([string]$BaseUrl)

    try {
        $response = Invoke-WebRequestWithTimeout -Uri $BaseUrl

        if ($response.Content -notmatch 'search\.min\.js') {
            return @{
                passed = $false
                message = 'Search plugin not found'
                severity = 'warning'
            }
        }

        return @{
            passed = $true
            message = 'Search functionality is configured'
            severity = 'success'
        }
    } catch {
        return @{
            passed = $false
            message = "Error: $($_.Exception.Message)"
            severity = 'warning'
        }
    }
}

function Invoke-HealthCheck {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [scriptblock]$TestFunction
    )

    Write-Host "⚡ Running: $Name..." -ForegroundColor Yellow

    $stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

    try {
        $result = & $TestFunction $Url
        $stopwatch.Stop()

        $checkResult = @{
            name = $Name
            url = $Url
            passed = $result.passed
            message = $result.message
            severity = $result.severity
            duration = $stopwatch.ElapsedMilliseconds
        }

        $script:Results.checks += $checkResult

        $icon = switch ($result.severity) {
            'success' { '✅' }
            'warning' { '⚠️' }
            default { '❌' }
        }

        $status = switch ($result.severity) {
            'success' { 'PASSED' }
            'warning' { 'WARNING' }
            default { 'FAILED' }
        }

        Write-Host "   $icon $status`: $($result.message)" -ForegroundColor White

        switch ($result.severity) {
            'success' { $script:Results.summary.passed++ }
            'warning' { $script:Results.summary.warnings++ }
            default { $script:Results.summary.failed++ }
        }

    } catch {
        $stopwatch.Stop()

        $checkResult = @{
            name = $Name
            url = $Url
            passed = $false
            message = "Error: $($_.Exception.Message)"
            severity = 'error'
            duration = $stopwatch.ElapsedMilliseconds
        }

        $script:Results.checks += $checkResult
        $script:Results.summary.failed++

        Write-Host "   ❌ FAILED: $($_.Exception.Message)" -ForegroundColor Red
    }
}

function Write-HealthSummary {
    Write-Host '' -ForegroundColor White
    Write-Host '📊 Health Check Summary:' -ForegroundColor Cyan
    Write-Host "   ✅ Passed: $($script:Results.summary.passed)" -ForegroundColor Green
    Write-Host "   ⚠️  Warnings: $($script:Results.summary.warnings)" -ForegroundColor Yellow
    Write-Host "   ❌ Failed: $($script:Results.summary.failed)" -ForegroundColor Red
    Write-Host "   📈 Total: $($script:Results.checks.Count)" -ForegroundColor White

    $overallHealth = if ($script:Results.summary.failed -eq 0) {
        if ($script:Results.summary.warnings -eq 0) { 'HEALTHY' } else { 'HEALTHY (with warnings)' }
    } else {
        'UNHEALTHY'
    }

    $icon = if ($script:Results.summary.failed -eq 0) {
        if ($script:Results.summary.warnings -eq 0) { '🟢' } else { '🟡' }
    } else {
        '🔴'
    }

    Write-Host "   $icon Overall Status: $overallHealth" -ForegroundColor White

    return ($script:Results.summary.failed -eq 0)
}

try {
    Write-Host "🔍 Performing health checks for: $SiteUrl" -ForegroundColor Cyan
    Write-Host "⏰ Timestamp: $($script:Results.timestamp)" -ForegroundColor Gray
    Write-Host '' -ForegroundColor White

    # Define and run health checks
    $healthChecks = @(
        @{ Name = 'Site Accessibility'; TestFunction = { param($url) Test-SiteAccessibility $url } },
        @{ Name = 'Docsify Setup'; TestFunction = { param($url) Test-DocsifySetup $url } },
        @{ Name = 'URL Configuration'; TestFunction = { param($url) Test-UrlConfiguration $url } },
        @{ Name = 'Sidebar Navigation'; TestFunction = { param($url) Test-SidebarNavigation $url } },
        @{ Name = 'Assets Availability'; TestFunction = { param($url) Test-AssetsAvailability $url } },
        @{ Name = 'Search Functionality'; TestFunction = { param($url) Test-SearchFunctionality $url } }
    )

    foreach ($check in $healthChecks) {
        Invoke-HealthCheck -Name $check.Name -Url $SiteUrl -TestFunction $check.TestFunction
    }

    # Print summary and determine exit code
    $isHealthy = Write-HealthSummary

    # Output JSON results if requested
    if ($OutputJson) {
        Write-Host '' -ForegroundColor White
        Write-Host '📄 JSON Results:' -ForegroundColor Cyan
        $jsonOutput = $script:Results | ConvertTo-Json -Depth 10
        Write-Output $jsonOutput
    }

    # Exit with appropriate code
    if ($isHealthy) {
        exit 0
    } else {
        exit 1
    }

} catch {
    Write-Error "❌ Unexpected error: $($_.Exception.Message)"
    exit 2
}
