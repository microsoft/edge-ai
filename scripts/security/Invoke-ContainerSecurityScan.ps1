#!/usr/bin/env pwsh

<#
.SYNOPSIS
Container Security Scanning Script

.DESCRIPTION
This script provides comprehensive security scanning for built container images using Grype
for vulnerability detection. It integrates with the application build pipeline to scan
images immediately after they are built        # Execute Grype with timeout using local variable to avoid runspace issues
        & grype @grypeArgList
        $exitCode = $LASTEXITCODEiding SARIF output for CI/CD integration.

.FUNCTIONALITY
- Scans container images for vulnerabilities using Grype
- Generates SARIF reports compatible with GitHub Security tab and Azure DevOps
- Provides severity-based filtering and failure thresholds
- Supports multi-platform image scanning
- Integrates with build matrix data for automated scanning

.PARAMETER ImageName
Container image name to scan (required)

.PARAMETER ImageTag
Container image tag to scan (required)

.PARAMETER Registry
Container registry hosting the image (optional, defaults to local)

.PARAMETER OutputPath
Path to write SARIF report (optional, defaults to ./security-reports)

.PARAMETER FailOnSeverity
Fail build on vulnerabilities of this severity or higher (optional, defaults to 'high')

.PARAMETER ScanTimeout
Maximum time to wait for scan completion in seconds (optional, defaults to 300)

.PARAMETER VerboseLogging
Enable verbose logging for debugging (switch)

.PARAMETER DryRun
Show what would be scanned without executing (switch)

.EXAMPLE
./Invoke-ContainerSecurityScan.ps1 -ImageName "myapp/api" -ImageTag "build-123" -Registry "myregistry.azurecr.io"

.EXAMPLE
./Invoke-ContainerSecurityScan.ps1 -ImageName "myapp/api" -ImageTag "build-123" -FailOnSeverity "medium" -VerboseLogging
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [string]$ImageName,

    [Parameter(Mandatory = $true)]
    [string]$ImageTag,

    [Parameter(Mandatory = $false)]
    [string]$Registry = "local",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./security-reports",

    [Parameter(Mandatory = $false)]
    [ValidateSet('negligible', 'low', 'medium', 'high', 'critical')]
    [string]$FailOnSeverity = "high",

    [Parameter(Mandatory = $false)]
    [int]$ScanTimeout = 300,

    [Parameter(Mandatory = $false)]
    [switch]$VerboseLogging,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun,

    [Parameter(Mandatory = $false)]
    [switch]$Quiet
)

# Set strict mode and error handling
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

. "$PSScriptRoot/Ros2ExclusionHelper.ps1"

$script:QuietMode = [bool]$Quiet

# Initialize result tracking
$script:ScanResults = @()
$script:VulnerabilityCount = @{
    critical   = 0
    high       = 0
    medium     = 0
    low        = 0
    negligible = 0
}
$script:ScanSuccess = $false
$script:SeverityOrder = @('critical', 'high', 'medium', 'low', 'negligible', 'unknown')
$script:ThresholdFailureReasons = @()

$Ros2ImageExclusionPatterns = Get-Ros2ImageExclusionList

function Convert-GrypeOutputToJson {
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputObject,

        [Parameter(Mandatory = $true)]
        [string]$ReportPath,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Normalizing Grype JSON output from $ReportPath" -Level Debug -VerboseLogging:$VerboseLogging

    if ([string]::IsNullOrWhiteSpace($InputObject)) {
        Write-SecurityError "Grype JSON report $ReportPath is empty"
    }

    $length = $InputObject.Length
    $position = 0
    $lastParseError = $null

    while ($position -lt $length) {
        $startChar = $InputObject[$position]

        if ($startChar -ne '{' -and $startChar -ne '[') {
            $position++
            continue
        }

        $stack = New-Object System.Collections.Generic.Stack[char]
        if ($startChar -eq '{') {
            $stack.Push('}')
        }
        else {
            $stack.Push(']')
        }

        $inString = $false
        $escapeNext = $false
        $endIndex = -1

        for ($i = $position + 1; $i -lt $length; $i++) {
            $char = $InputObject[$i]

            if ($escapeNext) {
                $escapeNext = $false
                continue
            }

            if ($inString) {
                if ($char -eq '\\') {
                    $escapeNext = $true
                    continue
                }

                if ($char -eq '"') {
                    $inString = $false
                }

                continue
            }

            if ($char -eq '"') {
                $inString = $true
                continue
            }

            if ($char -eq '{') {
                $stack.Push('}')
                continue
            }

            if ($char -eq '[') {
                $stack.Push(']')
                continue
            }

            if ($char -eq '}' -or $char -eq ']') {
                if ($stack.Count -eq 0) {
                    $endIndex = -1
                    break
                }

                $expected = $stack.Pop()

                if (($char -eq '}' -and $expected -ne '}') -or ($char -eq ']' -and $expected -ne ']')) {
                    $endIndex = -1
                    break
                }

                if ($stack.Count -eq 0) {
                    $endIndex = $i
                    break
                }

                continue
            }
        }

        if ($endIndex -ge $position) {
            $candidate = $InputObject.Substring($position, $endIndex - $position + 1).Trim()

            if (-not [string]::IsNullOrWhiteSpace($candidate)) {
                try {
                    $null = $candidate | ConvertFrom-Json -Depth 15 -ErrorAction Stop
                    return $candidate
                }
                catch {
                    $lastParseError = $_.Exception.Message
                    $position = $endIndex + 1
                    continue
                }
            }
        }

        if ($endIndex -ge $position) {
            $position = $endIndex + 1
        }
        else {
            $position++
        }
    }

    if ($lastParseError) {
        Write-SecurityError "Failed to parse JSON payload in Grype output ($ReportPath): $lastParseError"
    }

    Write-SecurityError "Unable to determine JSON boundaries in Grype output ($ReportPath)"
}

function Test-GrypeJsonContent {
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonContent,

        [Parameter(Mandatory = $true)]
        [string]$ReportPath,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Validating sanitized Grype JSON report: $ReportPath" -Level Debug -VerboseLogging:$VerboseLogging

    if ([string]::IsNullOrWhiteSpace($JsonContent)) {
        Write-SecurityError "Sanitized Grype JSON content is empty for report $ReportPath"
    }

    try {
        return $JsonContent | ConvertFrom-Json -Depth 15 -ErrorAction Stop
    }
    catch {
        Write-SecurityError "Failed to parse JSON content from ${ReportPath}: $($_.Exception.Message)"
    }
}

function Get-GrypeVulnerabilitySummary {
    param(
        [Parameter(Mandatory = $true)]
        [psobject]$ParsedJson,

        [Parameter(Mandatory = $false)]
        [string[]]$SeverityOrder = $script:SeverityOrder,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Summarizing Grype vulnerability data" -Level Debug -VerboseLogging:$VerboseLogging

    $counts = [ordered]@{}
    foreach ($severity in $SeverityOrder) {
        $counts[$severity.ToLower()] = 0
    }

    if ($ParsedJson.matches) {
        foreach ($match in $ParsedJson.matches) {
            $severity = $match.vulnerability.severity
            if ([string]::IsNullOrWhiteSpace($severity)) {
                continue
            }

            $normalizedSeverity = $severity.ToLower()
            if ($counts.Contains($normalizedSeverity)) {
                $counts[$normalizedSeverity]++
            }
        }
    }

    $total = ($counts.Values | Measure-Object -Sum).Sum
    $distribution = ($counts.Keys | ForEach-Object { "$_=$($counts[$_])" }) -join ', '
    Write-SecurityLog "Vulnerability distribution: $distribution" -Level Debug -VerboseLogging:$VerboseLogging

    return [PSCustomObject]@{
        total           = $total
        vulnerabilities = $counts
        matches         = if ($ParsedJson.matches) { $ParsedJson.matches } else { @() }
    }
}

function Write-SecurityLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Debug')]
        [string]$Level = 'Info',

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    $timestamp = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
    $logMessage = "[$timestamp] [SECURITY-$Level] $Message"

    switch ($Level) {
        'Info' { if (-not $script:QuietMode) { Write-Information $logMessage -InformationAction Continue } }
        'Warning' { Write-Warning $logMessage }
        'Error' { Write-Error $logMessage }
        'Debug' { if ($VerboseLogging -and -not $script:QuietMode) { Write-Information $logMessage -InformationAction Continue } }
    }
}

function Write-SecurityInfo {
    param([string]$Message)
    if (-not $script:QuietMode) {
        Write-Information "[ SECURITY ]: $Message" -InformationAction Continue
    }
}

function Write-SecurityWarn {
    param([string]$Message)
    if (-not $script:QuietMode) {
        Write-Warning "[ SECURITY ]: $Message"
    }
}

function Write-SecurityError {
    param([string]$Message)
    Write-Error "[ SECURITY ]: $Message" -ErrorAction Stop
}

function Test-Ros2ImageExclusion {
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Patterns,

        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Mandatory = $true)]
        [string]$FullImageName,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    foreach ($pattern in $Patterns) {
        if ($ImageName -like $pattern -or $FullImageName -like $pattern) {
            Write-SecurityLog "Matched ROS2 exclusion pattern '$pattern' for $FullImageName" -Level Debug -VerboseLogging:$VerboseLogging
            return $true
        }
    }

    return $false
}

function Test-SecurityDependency {
    param(
        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Validating security scanning dependencies" -Level Debug -VerboseLogging:$VerboseLogging

    # Check for Grype
    try {
        $null = Get-Command "grype" -ErrorAction Stop
        $grypeVersion = & grype version 2>$null
        Write-SecurityLog "Grype found: $grypeVersion" -Level Debug -VerboseLogging:$VerboseLogging
    }
    catch {
        throw "Grype is required but not available. Install from: https://github.com/anchore/grype"
    }

    # Check for Docker (to verify image exists)
    try {
        $null = Get-Command "docker" -ErrorAction Stop
        Write-SecurityLog "Docker found: $(docker --version)" -Level Debug -VerboseLogging:$VerboseLogging
    }
    catch {
        throw "Docker is required to verify image availability"
    }

    Write-SecurityLog "Security dependency validation completed" -Level Debug -VerboseLogging:$VerboseLogging
}

function Test-SecurityParameter {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Mandatory = $true)]
        [string]$ImageTag,

        [Parameter(Mandatory = $false)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Validating security scan parameters" -Level Debug -VerboseLogging:$VerboseLogging

    # Validate required parameters
    $requiredParams = @{
        'ImageName' = $ImageName
        'ImageTag'  = $ImageTag
    }

    foreach ($param in $requiredParams.GetEnumerator()) {
        if ([string]::IsNullOrWhiteSpace($param.Value)) {
            Write-SecurityError "$($param.Key) cannot be empty"
        }
    }

    # Validate output path
    if (-not (Test-Path $OutputPath -IsValid)) {
        Write-SecurityError "Invalid output path: $OutputPath"
    }

    Write-SecurityLog "Parameter validation completed successfully" -Level Debug -VerboseLogging:$VerboseLogging
}

function Initialize-SecurityReportDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Initializing security report directory: $OutputPath" -Level Debug -VerboseLogging:$VerboseLogging

    if ($DryRun) {
        Write-SecurityInfo "DRY RUN: Would create directory $OutputPath"
        return
    }

    # Create output directory if it doesn't exist
    if (-not (Test-Path $OutputPath)) {
        New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        Write-SecurityLog "Created security report directory: $OutputPath" -Level Debug -VerboseLogging:$VerboseLogging
    }

    # Verify directory is writable
    $testFile = Join-Path $OutputPath "test-write.tmp"
    try {
        "test" | Out-File -FilePath $testFile -Force
        Remove-Item $testFile -Force
        Write-SecurityLog "Security report directory is writable" -Level Debug -VerboseLogging:$VerboseLogging
    }
    catch {
        Write-SecurityError "Cannot write to security report directory: $OutputPath"
    }
}

function Get-FullImageName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Registry,

        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Mandatory = $true)]
        [string]$ImageTag,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Building full image name" -Level Debug -VerboseLogging:$VerboseLogging

    $fullImageName = if ($Registry -eq "local") {
        "local/${ImageName}:${ImageTag}"
    }
    else {
        "${Registry}/${ImageName}:${ImageTag}"
    }

    Write-SecurityLog "Full image name: $fullImageName" -Level Debug -VerboseLogging:$VerboseLogging
    return $fullImageName
}

function Test-DockerImagePresence {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ImageReference,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Checking Docker image tag: $ImageReference" -Level Debug -VerboseLogging:$VerboseLogging
    $null = & docker image inspect $ImageReference 2>$null
    return ($LASTEXITCODE -eq 0)
}

function Test-ImageAvailability {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullImageName,

        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Mandatory = $true)]
        [string]$ImageTag,

        [Parameter(Mandatory = $true)]
        [string]$Registry,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Verifying image availability: $FullImageName" -Level Debug -VerboseLogging:$VerboseLogging

    if ($DryRun) {
        Write-SecurityInfo "DRY RUN: Would verify image $FullImageName"
        return $true
    }

    if (Test-DockerImagePresence -ImageReference $FullImageName -VerboseLogging:$VerboseLogging) {
        Write-SecurityLog "Image verified: $FullImageName" -Level Debug -VerboseLogging:$VerboseLogging
        return $true
    }

    if ($Registry -eq 'local') {
        $dockerIoImage = "docker.io/$FullImageName"
        Write-SecurityLog "Checking for Docker Buildx prefixed image: $dockerIoImage" -Level Debug -VerboseLogging:$VerboseLogging

        if (Test-DockerImagePresence -ImageReference $dockerIoImage -VerboseLogging:$VerboseLogging) {
            Write-SecurityLog "Found image with docker.io prefix: $dockerIoImage" -Level Debug -VerboseLogging:$VerboseLogging

            if ($DryRun) {
                Write-SecurityInfo "DRY RUN: Would retag $dockerIoImage as $FullImageName"
                return $true
            }

            & docker tag $dockerIoImage $FullImageName 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-SecurityLog "Retagged $dockerIoImage as $FullImageName for scanner compatibility" -Level Debug -VerboseLogging:$VerboseLogging
                return $true
            }

            Write-SecurityWarn "Failed to retag docker.io prefixed image: $dockerIoImage"
        }
    }

    if ($Registry -ne 'local') {
        Write-SecurityWarn "Image not found locally, attempting to pull: $FullImageName"

        & docker pull $FullImageName 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-SecurityLog "Image pulled successfully: $FullImageName" -Level Debug -VerboseLogging:$VerboseLogging
            return $true
        }

        Write-SecurityError "Cannot access image: $FullImageName"
        return $false
    }

    $fallbackTags = @()
    $serviceTag = ($ImageName -split '[\/]' | Select-Object -Last 1)
    if (-not [string]::IsNullOrWhiteSpace($serviceTag)) {
        $fallbackTags += "${serviceTag}:${ImageTag}"
        $fallbackTags += "${serviceTag}:latest"
        $fallbackTags += "${serviceTag}:local"
    }

    $fallbackTags += $ImageTag

    foreach ($candidateTag in $fallbackTags | Select-Object -Unique) {
        if (Test-DockerImagePresence -ImageReference $candidateTag -VerboseLogging:$VerboseLogging) {
            Write-SecurityLog "Found local image tag '$candidateTag' for $FullImageName" -Level Debug -VerboseLogging:$VerboseLogging

            $tagReady = $true
            if ($candidateTag -ne $FullImageName) {
                if ($DryRun) {
                    Write-SecurityInfo "DRY RUN: Would retag $candidateTag as $FullImageName"
                }
                else {
                    & docker tag $candidateTag $FullImageName 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        $tagReady = $false
                        Write-SecurityWarn "Failed to retag $candidateTag as $FullImageName"
                    }
                    else {
                        Write-SecurityLog "Retagged $candidateTag as $FullImageName" -Level Debug -VerboseLogging:$VerboseLogging
                    }
                }
            }

            if ($tagReady) {
                return $true
            }
        }
    }

    $checkedTags = ($fallbackTags | Select-Object -Unique) -join ', '
    Write-SecurityError "Cannot access image: $FullImageName (checked: $checkedTags)"
    return $false
}

function Invoke-GrypeScan {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FullImageName,

        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Mandatory = $true)]
        [string]$ImageTag,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $false)]
        [int]$ScanTimeout,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Starting Grype vulnerability scan for: $FullImageName" -VerboseLogging:$VerboseLogging

    # Generate report file names
    $timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
    $reportBaseName = "${ImageName}-${ImageTag}-${timestamp}"
    $sarifReport = Join-Path $OutputPath "${reportBaseName}.sarif"
    $jsonReport = Join-Path $OutputPath "${reportBaseName}.json"
    $tableReport = Join-Path $OutputPath "${reportBaseName}.txt"

    if ($DryRun) {
        Write-SecurityInfo "DRY RUN: Would scan $FullImageName"
        Write-SecurityInfo "DRY RUN: Would generate reports: $sarifReport, $jsonReport, $tableReport"
        return @{
            success         = $true
            sarifReport     = $sarifReport
            jsonReport      = $jsonReport
            tableReport     = $tableReport
            vulnerabilities = @{
                critical   = 0
                high       = 0
                medium     = 0
                low        = 0
                negligible = 0
            }
        }
    }

    try {
        Write-SecurityInfo "Scanning image: $FullImageName"
        Write-SecurityInfo "Timeout: $ScanTimeout seconds"

        # Run Grype scan with JSON output for processing
        $grypeArgList = @(
            $FullImageName
            "--output", "json"
            "--file", $jsonReport
        )

        Write-SecurityLog "Executing: grype $($grypeArgList -join ' ')" -Level Debug -VerboseLogging:$VerboseLogging

        # Execute Grype scan
        & grype @grypeArgList 2>&1 | Tee-Object -Variable grypeOutput | Out-Null
        $exitCode = $LASTEXITCODE

        # Log Grype output for debugging silent failures
        if ($VerboseLogging) {
            Write-SecurityLog "Grype raw output: $grypeOutput" -Level Debug -VerboseLogging:$VerboseLogging
        }

        # Grype returns non-zero when vulnerabilities are found, which is expected behavior
        # Don't treat this as a scan failure - we'll evaluate the threshold later
        Write-SecurityLog "Grype completed with exit code: $exitCode" -Level Debug -VerboseLogging:$VerboseLogging

        # Verify the JSON report was created
        if (-not (Test-Path $jsonReport)) {
            Write-SecurityError "Grype did not generate expected JSON report at: $jsonReport"
            Write-SecurityError "Grype exit code was: $exitCode"
            if ($grypeOutput) {
                Write-SecurityError "Grype output: $grypeOutput"
            }
            throw "Grype scan failed to produce JSON output. This may indicate an image format issue, scanner incompatibility, or silent Grype failure. Image: $FullImageName"
        }

        # Generate additional report formats
        Write-SecurityLog "Generating additional report formats" -Level Debug -VerboseLogging:$VerboseLogging

        # SARIF format for CI/CD integration
        & grype $FullImageName --output sarif --file $sarifReport 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-SecurityWarn "Failed to generate SARIF report"
        }

        # Table format for human readability
        & grype $FullImageName --output table --file $tableReport 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-SecurityWarn "Failed to generate table report"
        }

        # Parse JSON results for vulnerability counts
        $vulnerabilityCounts = Get-VulnerabilityCount -JsonReport $jsonReport -VerboseLogging:$VerboseLogging

        Write-SecurityInfo "Vulnerability scan completed"
        Write-SecurityInfo "Reports generated: SARIF=$sarifReport, JSON=$jsonReport, TABLE=$tableReport"

        return @{
            success         = $true
            sarifReport     = $sarifReport
            jsonReport      = $jsonReport
            tableReport     = $tableReport
            vulnerabilities = $vulnerabilityCounts
        }
    }
    catch {
        Write-SecurityError "Grype scan failed: $_"
        return @{
            success         = $false
            error           = $_.Exception.Message
            vulnerabilities = @{
                critical   = 0
                high       = 0
                medium     = 0
                low        = 0
                negligible = 0
            }
        }
    }
}

function Get-VulnerabilityCount {
    param(
        [Parameter(Mandatory = $true)]
        [string]$JsonReport,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Parsing vulnerability counts from JSON report" -Level Debug -VerboseLogging:$VerboseLogging

    try {
        if (-not (Test-Path $JsonReport)) {
            Write-SecurityWarn "JSON report not found: $JsonReport"
            return @{
                critical   = 0
                high       = 0
                medium     = 0
                low        = 0
                negligible = 0
            }
        }

        $rawContent = Get-Content -Path $JsonReport -Raw
        $sanitizedJson = Convert-GrypeOutputToJson -InputObject $rawContent -ReportPath $JsonReport -VerboseLogging:$VerboseLogging
        $parsedJson = Test-GrypeJsonContent -JsonContent $sanitizedJson -ReportPath $JsonReport -VerboseLogging:$VerboseLogging
        $summary = Get-GrypeVulnerabilitySummary -ParsedJson $parsedJson -VerboseLogging:$VerboseLogging

        Set-Content -Path $JsonReport -Value $sanitizedJson -Encoding utf8NoBOM -Force

        Write-SecurityLog "Vulnerability counts: Critical=$($summary.vulnerabilities.critical), High=$($summary.vulnerabilities.high), Medium=$($summary.vulnerabilities.medium), Low=$($summary.vulnerabilities.low), Negligible=$($summary.vulnerabilities.negligible)" -Level Debug -VerboseLogging:$VerboseLogging
        return $summary.vulnerabilities
    }
    catch {
        Write-SecurityWarn "Failed to parse JSON report: $_"
    }

    return @{
        critical   = 0
        high       = 0
        medium     = 0
        low        = 0
        negligible = 0
    }
}

function Test-SecurityThreshold {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$VulnerabilityCounts,

        [Parameter(Mandatory = $true)]
        [string]$FailOnSeverity,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Evaluating security threshold: $FailOnSeverity" -Level Debug -VerboseLogging:$VerboseLogging

    # Define severity levels in order
    $severityLevels = @('critical', 'high', 'medium', 'low', 'negligible')
    $failThresholdIndex = $severityLevels.IndexOf($FailOnSeverity.ToLower())

    if ($failThresholdIndex -eq -1) {
        Write-SecurityError "Invalid severity level: $FailOnSeverity"
    }

    # Check if any vulnerability at or above threshold exists
    $shouldFail = $false
    $failureReasons = @()
    $script:ThresholdFailureReasons = @()

    for ($i = 0; $i -le $failThresholdIndex; $i++) {
        $severity = $severityLevels[$i]
        if ($VulnerabilityCounts[$severity] -gt 0) {
            $shouldFail = $true
            $failureReasons += "$($VulnerabilityCounts[$severity]) $severity vulnerabilities"
        }
    }

    if ($shouldFail) {
        $reasonText = $failureReasons -join ', '
        Write-SecurityWarn "Security threshold exceeded - $reasonText (threshold: $FailOnSeverity)"
        $script:ThresholdFailureReasons = $failureReasons
        return $false
    }
    else {
        Write-SecurityInfo "Security threshold check passed (threshold: $FailOnSeverity)"
        $script:ThresholdFailureReasons = @()
        return $true
    }
}

function Get-SecuritySummary {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$ScanResult,

        [Parameter(Mandatory = $true)]
        [string]$FullImageName,

        [Parameter(Mandatory = $true)]
        [string]$ImageName,

        [Parameter(Mandatory = $true)]
        [string]$ImageTag,

        [Parameter(Mandatory = $true)]
        [string]$Registry,

        [Parameter(Mandatory = $true)]
        [string]$FailOnSeverity,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Generating security scan summary" -Level Debug -VerboseLogging:$VerboseLogging

    $summary = [PSCustomObject]@{
        image                = $FullImageName
        imageName            = $ImageName
        imageTag             = $ImageTag
        registry             = $Registry
        timestamp            = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        scanSuccess          = $ScanResult.success
        failOnSeverity       = $FailOnSeverity
        vulnerabilities      = $ScanResult.vulnerabilities
        totalVulnerabilities = ($ScanResult.vulnerabilities.Values | Measure-Object -Sum).Sum
        reports              = @{
            sarif = if ($ScanResult.sarifReport) { $ScanResult.sarifReport } else { $null }
            json  = if ($ScanResult.jsonReport) { $ScanResult.jsonReport } else { $null }
            table = if ($ScanResult.tableReport) { $ScanResult.tableReport } else { $null }
        }
        thresholdPassed      = $null
        thresholdReasons     = @()
    }

    # Set script-level variables
    $script:ScanResults = $summary
    $script:VulnerabilityCount = $ScanResult.vulnerabilities
    $script:ScanSuccess = $ScanResult.success

    return $summary
}

function Get-SecurityOutput {
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Summary,

        [Parameter(Mandatory = $true)]
        [string]$FailOnSeverity,

        [Parameter(Mandatory = $false)]
        [switch]$VerboseLogging
    )

    Write-SecurityLog "Generating final security output" -Level Debug -VerboseLogging:$VerboseLogging

    $jsonOutput = $Summary | ConvertTo-Json -Depth 10

    if (-not $script:QuietMode) {
        Write-SecurityInfo "=== Security Scan Summary ==="
        Write-SecurityInfo "Image: $($Summary.image)"
        Write-SecurityInfo "Scan Success: $($Summary.scanSuccess)"
        Write-SecurityInfo "Total Vulnerabilities: $($Summary.totalVulnerabilities)"
        Write-SecurityInfo "Critical: $($Summary.vulnerabilities.critical)"
        Write-SecurityInfo "High: $($Summary.vulnerabilities.high)"
        Write-SecurityInfo "Medium: $($Summary.vulnerabilities.medium)"
        Write-SecurityInfo "Low: $($Summary.vulnerabilities.low)"
        Write-SecurityInfo "Negligible: $($Summary.vulnerabilities.negligible)"
        Write-SecurityInfo "Threshold ($FailOnSeverity): $($Summary.thresholdPassed)"

        if ($Summary.reports.sarif) {
            Write-SecurityInfo "SARIF Report: $($Summary.reports.sarif)"
        }
        if ($Summary.reports.json) {
            Write-SecurityInfo "JSON Report: $($Summary.reports.json)"
        }
        if ($Summary.reports.table) {
            Write-SecurityInfo "Table Report: $($Summary.reports.table)"
        }
    }

    return $jsonOutput
}

####
# Main script execution
####

try {
    Write-SecurityLog "Starting container security scan" -VerboseLogging:$VerboseLogging

    # Validate inputs and dependencies
    Test-SecurityParameter -ImageName $ImageName -ImageTag $ImageTag -OutputPath $OutputPath -VerboseLogging:$VerboseLogging
    Test-SecurityDependency -VerboseLogging:$VerboseLogging

    # Initialize output directory
    Initialize-SecurityReportDirectory -OutputPath $OutputPath -DryRun:$DryRun -VerboseLogging:$VerboseLogging

    # Build full image name
    $fullImageName = Get-FullImageName -Registry $Registry -ImageName $ImageName -ImageTag $ImageTag -VerboseLogging:$VerboseLogging

    # Skip ROS2 rolling tag images that cannot be pinned
    if ($Ros2ImageExclusionPatterns.Count -gt 0) {
        $skipRos2Image = Test-Ros2ImageExclusion -Patterns $Ros2ImageExclusionPatterns -ImageName $ImageName -FullImageName $fullImageName -VerboseLogging:$VerboseLogging
        if ($skipRos2Image) {
            Write-SecurityInfo "Skipping ROS2 rolling-tag image: $fullImageName"

            # Return success JSON with skipped status instead of silent exit
            $skippedSummary = @{
                success          = $true
                skipped          = $true
                skipReason       = "ROS2 rolling-tag image excluded from scanning"
                image            = $fullImageName
                vulnerabilities  = @{
                    critical   = 0
                    high       = 0
                    medium     = 0
                    low        = 0
                    negligible = 0
                    unknown    = 0
                }
                thresholdPassed  = $true
                thresholdReasons = @()
            }

            # Output JSON for caller to parse
            Write-Output ($skippedSummary | ConvertTo-Json -Depth 10 -Compress)
            exit 0
        }
    }

    # Verify image exists
    $imageAvailable = Test-ImageAvailability -FullImageName $fullImageName -ImageName $ImageName -ImageTag $ImageTag -Registry $Registry -DryRun:$DryRun -VerboseLogging:$VerboseLogging
    if (-not $imageAvailable) {
        Write-SecurityError "Image not available for scanning: $fullImageName"
    }

    # Perform security scan
    $scanResult = Invoke-GrypeScan -FullImageName $fullImageName -ImageName $ImageName -ImageTag $ImageTag -OutputPath $OutputPath -ScanTimeout $ScanTimeout -DryRun:$DryRun -VerboseLogging:$VerboseLogging

    # Generate summary
    $summary = Get-SecuritySummary -ScanResult $scanResult -FullImageName $fullImageName -ImageName $ImageName -ImageTag $ImageTag -Registry $Registry -FailOnSeverity $FailOnSeverity -VerboseLogging:$VerboseLogging

    # Check security threshold
    $thresholdPassed = Test-SecurityThreshold -VulnerabilityCounts $scanResult.vulnerabilities -FailOnSeverity $FailOnSeverity -VerboseLogging:$VerboseLogging
    $summary.thresholdPassed = $thresholdPassed
    $summary.thresholdReasons = $script:ThresholdFailureReasons

    # Generate and output final results
    $jsonOutput = Get-SecurityOutput -Summary $summary -FailOnSeverity $FailOnSeverity -VerboseLogging:$VerboseLogging

    # Write JSON to output stream for caller to parse
    Write-Output $jsonOutput

    # Exit with appropriate code
    if ($scanResult.success -and $thresholdPassed) {
        Write-SecurityLog "Security scan completed successfully" -VerboseLogging:$VerboseLogging
        exit 0
    }
    else {
        Write-SecurityLog "Security scan failed or threshold exceeded" -VerboseLogging:$VerboseLogging
        exit 1
    }
}
catch {
    # Extract clean error message
    $errorMessage = if ($_.Exception.Message) {
        $_.Exception.Message
    }
    else {
        $_.ToString()
    }

    # Remove redundant "[ SECURITY ]:" prefix if present
    $errorMessage = $errorMessage -replace '^\s*\[\s*SECURITY\s*\]\s*:\s*', ''

    # Build error response JSON
    $fullImageName = if ($Registry -ne "local") { "$Registry/$ImageName`:$ImageTag" } else { "$ImageName`:$ImageTag" }
    $errorSummary = @{
        success          = $false
        error            = "Security scan failed: $errorMessage"
        image            = $fullImageName
        vulnerabilities  = @{
            critical   = 0
            high       = 0
            medium     = 0
            low        = 0
            negligible = 0
            unknown    = 0
        }
        thresholdPassed  = $false
        thresholdReasons = @("Scanner execution failed: $errorMessage")
    }

    # Output JSON for caller to parse
    Write-Output ($errorSummary | ConvertTo-Json -Depth 10 -Compress)

    # Log error if not in quiet mode
    if (-not $script:QuietMode) {
        Write-Error "[ SECURITY ]: Security scan failed: $errorMessage" -ErrorAction Continue
    }
    exit 1
}
