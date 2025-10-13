<#
.SYNOPSIS
Security gate enforcement for C.PARAMETER Environment
Environment name for configuration overrides (development, production, etc.).

.PARAMETER EnableVerboseLogging
Enable verbose logging for debugging security gate logic.

.EXAMPLE
# Run security gate with default settings
.\Invoke-SecurityGate.ps1

.EXAMPLE
# Run with custom thresholds for production
.\Invoke-SecurityGate.ps1 -VulnerabilityThreshold 'medium' -MaxCriticalVulnerabilities 0 -MaxHighVulnerabilities 0

.EXAMPLE
# Run with lenient settings for development
.\Invoke-SecurityGate.ps1 -VulnerabilityThreshold 'low' -MaxCriticalVulnerabilities 5 -MaxHighVulnerabilities 20 -FailOnDependencyVulnerabilities:$falseth configurable thresholds and automated policy enforcement.

.DESCRIPTION
This script enforces security policies by analyzing security scan results from multiple sources:
- Grype vulnerability scanner (container images and source code)
- Checkov infrastructure as code security scanner
- Language-specific dependency audits (dotnet, cargo audit, npm audit, pip-audit)
- MegaLinter security findings

The script provides configurable thresholds and can fail builds when security policies are violated.

.PARAMETER SecurityResultsPath
Path to directory containing security scan results. Default is "./security-reports".

.PARAMETER VulnerabilityThreshold
Maximum severity level for vulnerabilities that will pass the security gate.
Options: critical, high, medium, low, negligible. Default is 'critical'.

.PARAMETER MaxCriticalVulnerabilities
Maximum number of critical vulnerabilities allowed. Default is 0.

.PARAMETER MaxHighVulnerabilities
Maximum number of high vulnerabilities allowed. Default is 5.

.PARAMETER MaxMediumVulnerabilities
Maximum number of medium vulnerabilities allowed. Default is 20.

.PARAMETER EnforceIaCSecurity
Whether to enforce Infrastructure as Code security policies. Default is true.

.PARAMETER FailOnDependencyVulnerabilities
Whether to fail the build on dependency vulnerabilities. Default is false (warning only).

.PARAMETER OutputFormat
Output format for reports: sarif, json, junit, console. Default is 'junit'.

.PARAMETER ExitOnFailure
Whether to exit with non-zero code when security gate fails. Default is true.

.PARAMETER ConfigFile
Path to security gate configuration file. Default is "./.security-gate.yml".

.PARAMETER Environment
Environment name for configuration overrides (development, production, etc.).

.PARAMETER Verbose
Enable verbose logging for debugging security gate logic.

.EXAMPLE
# Run security gate with default settings
.\Invoke-SecurityGate.ps1

.EXAMPLE
# Run with custom thresholds for production
.\Invoke-SecurityGate.ps1 -VulnerabilityThreshold 'medium' -MaxCriticalVulnerabilities 0 -MaxHighVulnerabilities 0

.EXAMPLE
# Run with lenient settings for development
.\Invoke-SecurityGate.ps1 -VulnerabilityThreshold 'low' -MaxCriticalVulnerabilities 5 -MaxHighVulnerabilities 20 -FailOnDependencyVulnerabilities:$false

.OUTPUTS
Returns security gate results object and writes JUnit XML report file.
#>

param(
    [Parameter(Mandatory = $false)]
    [string]$SecurityResultsPath = "./security-reports",

    [Parameter(Mandatory = $false)]
    [ValidateSet('critical', 'high', 'medium', 'low', 'negligible')]
    [string]$VulnerabilityThreshold = 'critical',

    [Parameter(Mandatory = $false)]
    [int]$MaxCriticalVulnerabilities = 0,

    [Parameter(Mandatory = $false)]
    [int]$MaxHighVulnerabilities = 5,

    [Parameter(Mandatory = $false)]
    [int]$MaxMediumVulnerabilities = 20,

    [Parameter(Mandatory = $false)]
    [bool]$EnforceIaCSecurity = $true,

    [Parameter(Mandatory = $false)]
    [bool]$FailOnDependencyVulnerabilities = $false,

    [Parameter(Mandatory = $false)]
    [ValidateSet('sarif', 'json', 'junit', 'console')]
    [string]$OutputFormat = 'junit',

    [Parameter(Mandatory = $false)]
    [bool]$ExitOnFailure = $true,

    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = "./.security-gate.yml",

    [Parameter(Mandatory = $false)]
    [string]$Environment = "",

    [Parameter(Mandatory = $false)]
    [switch]$EnableVerboseLogging
)

$ErrorActionPreference = "Stop"

# Initialize global variables
$script:SecurityFindings = @()
$script:SecurityGateResults = @{
    Passed             = $true
    TotalFindings      = 0
    CriticalFindings   = 0
    HighFindings       = 0
    MediumFindings     = 0
    LowFindings        = 0
    NegligibleFindings = 0
    IaCFindings        = 0
    DependencyFindings = 0
    ContainerFindings  = 0
    FailureReasons     = @()
    Summary            = @{}
}

####
# Configuration functions
####

function Get-SecurityConfiguration {
    param(
        [string]$ConfigPath,
        [string]$EnvironmentName,
        [string]$VulnerabilityThreshold,
        [int]$MaxCriticalVulnerabilities,
        [int]$MaxHighVulnerabilities,
        [int]$MaxMediumVulnerabilities,
        [bool]$EnforceIaCSecurity,
        [bool]$FailOnDependencyVulnerabilities,
        [string]$OutputFormat
    )

    Write-SecurityDebug "Loading security configuration from: $ConfigPath"

    $config = @{
        VulnerabilityThreshold          = $VulnerabilityThreshold
        MaxCriticalVulnerabilities      = $MaxCriticalVulnerabilities
        MaxHighVulnerabilities          = $MaxHighVulnerabilities
        MaxMediumVulnerabilities        = $MaxMediumVulnerabilities
        EnforceIaCSecurity              = $EnforceIaCSecurity
        FailOnDependencyVulnerabilities = $FailOnDependencyVulnerabilities
        OutputFormat                    = $OutputFormat
    }

    # Load configuration file if it exists
    if (Test-Path $ConfigPath) {
        try {
            # Install powershell-yaml module if not available
            if (-not (Get-Module -ListAvailable -Name powershell-yaml)) {
                Write-SecurityDebug "Installing powershell-yaml module for config parsing"
                Install-Module -Name powershell-yaml -Scope CurrentUser -Force -AllowClobber
            }

            Import-Module powershell-yaml
            $yamlContent = Get-Content $ConfigPath -Raw
            $yamlConfig = ConvertFrom-Yaml $yamlContent

            # Apply base configuration
            if ($yamlConfig.vulnerability) {
                if ($yamlConfig.vulnerability.threshold) { $config.VulnerabilityThreshold = $yamlConfig.vulnerability.threshold }
                if ($null -ne $yamlConfig.vulnerability.max_critical) { $config.MaxCriticalVulnerabilities = $yamlConfig.vulnerability.max_critical }
                if ($null -ne $yamlConfig.vulnerability.max_high) { $config.MaxHighVulnerabilities = $yamlConfig.vulnerability.max_high }
                if ($null -ne $yamlConfig.vulnerability.max_medium) { $config.MaxMediumVulnerabilities = $yamlConfig.vulnerability.max_medium }
            }

            if ($yamlConfig.iac) {
                if ($null -ne $yamlConfig.iac.enforce) { $config.EnforceIaCSecurity = $yamlConfig.iac.enforce }
            }

            if ($yamlConfig.dependencies) {
                if ($null -ne $yamlConfig.dependencies.fail_on_vulnerabilities) { $config.FailOnDependencyVulnerabilities = $yamlConfig.dependencies.fail_on_vulnerabilities }
            }

            if ($yamlConfig.reporting) {
                if ($yamlConfig.reporting.format) { $config.OutputFormat = $yamlConfig.reporting.format }
            }

            # Apply environment-specific overrides
            if ($EnvironmentName -and $yamlConfig.environments -and $yamlConfig.environments.$EnvironmentName) {
                $envConfig = $yamlConfig.environments.$EnvironmentName

                if ($envConfig.vulnerability) {
                    if ($envConfig.vulnerability.threshold) { $config.VulnerabilityThreshold = $envConfig.vulnerability.threshold }
                    if ($null -ne $envConfig.vulnerability.max_critical) { $config.MaxCriticalVulnerabilities = $envConfig.vulnerability.max_critical }
                    if ($null -ne $envConfig.vulnerability.max_high) { $config.MaxHighVulnerabilities = $envConfig.vulnerability.max_high }
                    if ($null -ne $envConfig.vulnerability.max_medium) { $config.MaxMediumVulnerabilities = $envConfig.vulnerability.max_medium }
                }

                if ($envConfig.iac) {
                    if ($null -ne $envConfig.iac.enforce) { $config.EnforceIaCSecurity = $envConfig.iac.enforce }
                }

                if ($envConfig.dependencies) {
                    if ($null -ne $envConfig.dependencies.fail_on_vulnerabilities) { $config.FailOnDependencyVulnerabilities = $envConfig.dependencies.fail_on_vulnerabilities }
                }
            }

            Write-SecurityDebug "Configuration loaded successfully with environment: $EnvironmentName"
        }
        catch {
            Write-SecurityWarn "Failed to load configuration file $ConfigPath, using defaults: $_"
        }
    }
    else {
        Write-SecurityDebug "Configuration file not found, using command-line parameters"
    }

    return $config
}

####
# Logging functions
####

function Write-SecurityLog {
    param([string]$Message)
    Write-Information "[SECURITY-GATE]: $Message" -InformationAction Continue
}

function Write-SecurityWarn {
    param([string]$Message)
    Write-Warning "[SECURITY-GATE]: $Message"
}

function Write-SecurityError {
    param([string]$Message)
    Write-Error "[SECURITY-GATE]: $Message"
}

function Write-SecurityDebug {
    param([string]$Message)
    Write-Verbose "[DEBUG]: $Message"
}

####
# Security scan result parsers
####

function Get-GrypeScanResult {
    param([string]$ResultsPath)

    Write-SecurityDebug "Parsing Grype vulnerability scan results"

    $grypeScanResult = @()
    $grypePaths = @(
        "$ResultsPath/grype-*.json",
        "$ResultsPath/**/grype-*.json"
    )

    foreach ($pathPattern in $grypePaths) {
        $grypeFiles = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue
        foreach ($file in $grypeFiles) {
            try {
                Write-SecurityDebug "Processing Grype file: $($file.FullName)"
                $grypeData = Get-Content $file.FullName | ConvertFrom-Json

                if ($grypeData.matches) {
                    foreach ($match in $grypeData.matches) {
                        $grypeScanResult += [PSCustomObject]@{
                            Type            = "Vulnerability"
                            Source          = "Grype"
                            Severity        = $match.vulnerability.severity
                            PackageName     = $match.artifact.name
                            PackageVersion  = $match.vulnerability.fix.versions -join ", "
                            VulnerabilityId = $match.vulnerability.id
                            Description     = $match.vulnerability.description
                            Target          = $match.artifact.type
                        }
                    }
                }
            }
            catch {
                Write-SecurityWarn "Failed to parse Grype file $($file.FullName): $_"
            }
        }
    }

    Write-SecurityDebug "Found $($grypeScanResult.Count) Grype vulnerability findings"
    return $grypeScanResult
}

function Get-CheckovScanResult {
    param([string]$ResultsPath)

    Write-SecurityDebug "Parsing Checkov IaC security scan results"

    $checkovScanResult = @()
    $checkovPaths = @(
        "$ResultsPath/checkov-*.json",
        "$ResultsPath/**/checkov-*.json",
        "$ResultsPath/code-analysis.xml"
    )

    foreach ($pathPattern in $checkovPaths) {
        $checkovFiles = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue
        foreach ($file in $checkovFiles) {
            try {
                Write-SecurityDebug "Processing Checkov file: $($file.FullName)"

                if ($file.Extension -eq ".xml") {
                    # Parse JUnit XML format
                    [xml]$checkovXml = Get-Content $file.FullName
                    foreach ($testCase in $checkovXml.testsuites.testsuite.testcase) {
                        if ($testCase.failure) {
                            $checkovScanResult += [PSCustomObject]@{
                                Type        = "IaC Security"
                                Source      = "Checkov"
                                Severity    = "High"  # Default severity for Checkov findings
                                Rule        = $testCase.name
                                File        = $testCase.classname
                                Description = $testCase.failure.message
                                Target      = "Infrastructure"
                            }
                        }
                    }
                }
                else {
                    # Parse JSON format
                    $checkovData = Get-Content $file.FullName | ConvertFrom-Json

                    if ($checkovData.results) {
                        foreach ($result in $checkovData.results.failed_checks) {
                            $checkovScanResult += [PSCustomObject]@{
                                Type        = "IaC Security"
                                Source      = "Checkov"
                                Severity    = if ($result.severity) { $result.severity } else { "Medium" }
                                Rule        = $result.check_name
                                File        = $result.file_path
                                Description = $result.guideline
                                Target      = "Infrastructure"
                            }
                        }
                    }
                }
            }
            catch {
                Write-SecurityWarn "Failed to parse Checkov file $($file.FullName): $_"
            }
        }
    }

    Write-SecurityDebug "Found $($checkovScanResult.Count) Checkov IaC security findings"
    return $checkovScanResult
}

function Get-DependencyAuditResult {
    param([string]$ResultsPath)

    Write-SecurityDebug "Parsing dependency audit results"

    $dependencyAuditResult = @()
    $auditPaths = @(
        "$ResultsPath/dependency-audit-*.json",
        "$ResultsPath/**/dependency-audit-*.json"
    )

    foreach ($pathPattern in $auditPaths) {
        $auditFiles = Get-ChildItem -Path $pathPattern -ErrorAction SilentlyContinue
        foreach ($file in $auditFiles) {
            try {
                Write-SecurityDebug "Processing dependency audit file: $($file.FullName)"
                $auditData = Get-Content $file.FullName | ConvertFrom-Json

                if ($auditData.results) {
                    foreach ($result in $auditData.results) {
                        if ($result.Status -in @("VULNERABLE", "ERROR")) {
                            $severity = if ($result.Status -eq "ERROR") { "Critical" } else { "High" }

                            $dependencyAuditResult += [PSCustomObject]@{
                                Type     = "Dependency Vulnerability"
                                Source   = "Dependency Audit"
                                Severity = $severity
                                Status   = $result.Status
                                Language = $result.Language
                                Details  = $result.Details
                                Target   = "Dependencies"
                            }
                        }
                    }
                }
            }
            catch {
                Write-SecurityWarn "Failed to parse dependency audit file $($file.FullName): $_"
            }
        }
    }

    Write-SecurityDebug "Found $($dependencyAuditResult.Count) dependency vulnerability findings"
    return $dependencyAuditResult
}

####
# Security gate evaluation functions
####

function Get-SeverityScore {
    param([string]$Severity)

    switch ($Severity.ToLower()) {
        'critical' { return 5 }
        'high' { return 4 }
        'medium' { return 3 }
        'low' { return 2 }
        'negligible' { return 1 }
        default { return 3 }  # Default to medium if unknown
    }
}

function Test-VulnerabilityThreshold {
    param(
        [array]$Findings,
        [string]$Threshold,
        [int]$MaxCritical,
        [int]$MaxHigh,
        [int]$MaxMedium
    )

    Write-SecurityDebug "Evaluating vulnerability thresholds"

    $thresholdScore = Get-SeverityScore -Severity $Threshold
    $failureReasons = @()

    # Count findings by severity
    $criticalCount = ($Findings | Where-Object { (Get-SeverityScore $_.Severity) -eq 5 }).Count
    $highCount = ($Findings | Where-Object { (Get-SeverityScore $_.Severity) -eq 4 }).Count
    $mediumCount = ($Findings | Where-Object { (Get-SeverityScore $_.Severity) -eq 3 }).Count

    # Update global counters
    $script:SecurityGateResults.CriticalFindings = $criticalCount
    $script:SecurityGateResults.HighFindings = $highCount
    $script:SecurityGateResults.MediumFindings = $mediumCount

    # Check against thresholds
    if ($criticalCount -gt $MaxCritical) {
        $failureReasons += "Critical vulnerabilities ($criticalCount) exceed maximum allowed ($MaxCritical)"
    }

    if ($highCount -gt $MaxHigh) {
        $failureReasons += "High vulnerabilities ($highCount) exceed maximum allowed ($MaxHigh)"
    }

    if ($mediumCount -gt $MaxMedium) {
        $failureReasons += "Medium vulnerabilities ($mediumCount) exceed maximum allowed ($MaxMedium)"
    }

    # Check for findings above threshold
    $aboveThresholdFindings = $Findings | Where-Object { (Get-SeverityScore $_.Severity) -gt $thresholdScore }
    if ($aboveThresholdFindings.Count -gt 0) {
        $failureReasons += "Found $($aboveThresholdFindings.Count) vulnerabilities above threshold ($Threshold)"
    }

    return $failureReasons
}

function Invoke-SecurityGateEvaluation {
    param(
        [string]$SecurityResultsPath,
        [string]$VulnerabilityThreshold,
        [int]$MaxCriticalVulnerabilities,
        [int]$MaxHighVulnerabilities,
        [int]$MaxMediumVulnerabilities,
        [bool]$EnforceIaCSecurity,
        [bool]$FailOnDependencyVulnerabilities
    )

    Write-SecurityLog "Evaluating security gate policies"

    # Collect all security findings
    $allFindings = @()

    # Parse Grype vulnerability results
    $gryteFindings = Get-GrypeScanResult -ResultsPath $SecurityResultsPath
    $allFindings += $gryteFindings
    $script:SecurityGateResults.ContainerFindings = $gryteFindings.Count

    # Parse Checkov IaC security results
    if ($EnforceIaCSecurity) {
        $checkovFindings = Get-CheckovScanResult -ResultsPath $SecurityResultsPath
        $allFindings += $checkovFindings
        $script:SecurityGateResults.IaCFindings = $checkovFindings.Count
    }

    # Parse dependency audit results
    $dependencyFindings = Get-DependencyAuditResult -ResultsPath $SecurityResultsPath
    $allFindings += $dependencyFindings
    $script:SecurityGateResults.DependencyFindings = $dependencyFindings.Count

    # Update global findings
    $script:SecurityFindings = $allFindings
    $script:SecurityGateResults.TotalFindings = $allFindings.Count

    Write-SecurityLog "Total security findings: $($allFindings.Count)"
    Write-SecurityLog "Container vulnerabilities: $($script:SecurityGateResults.ContainerFindings)"
    Write-SecurityLog "IaC security findings: $($script:SecurityGateResults.IaCFindings)"
    Write-SecurityLog "Dependency vulnerabilities: $($script:SecurityGateResults.DependencyFindings)"

    # Evaluate vulnerability thresholds
    $vulnerabilityFindings = $allFindings | Where-Object { $_.Type -eq "Vulnerability" }
    $thresholdFailures = Test-VulnerabilityThreshold -Findings $vulnerabilityFindings -Threshold $VulnerabilityThreshold -MaxCritical $MaxCriticalVulnerabilities -MaxHigh $MaxHighVulnerabilities -MaxMedium $MaxMediumVulnerabilities

    # Evaluate IaC security policies
    if ($EnforceIaCSecurity) {
        $iacFindings = $allFindings | Where-Object { $_.Type -eq "IaC Security" }
        if ($iacFindings.Count -gt 0) {
            $script:SecurityGateResults.FailureReasons += "Found $($iacFindings.Count) Infrastructure as Code security violations"
        }
    }

    # Evaluate dependency vulnerabilities
    $depFindings = $allFindings | Where-Object { $_.Type -eq "Dependency Vulnerability" }
    if ($FailOnDependencyVulnerabilities -and $depFindings.Count -gt 0) {
        $script:SecurityGateResults.FailureReasons += "Found $($depFindings.Count) dependency vulnerabilities (fail-on-dependency enabled)"
    }

    # Add threshold failures
    $script:SecurityGateResults.FailureReasons += $thresholdFailures

    # Determine overall pass/fail status
    $script:SecurityGateResults.Passed = ($script:SecurityGateResults.FailureReasons.Count -eq 0)

    return $script:SecurityGateResults
}

####
# Output generation functions
####

function New-JUnitSecurityReport {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$GateResults,
        [Parameter(Mandatory = $true)]
        [string]$SecurityResultsPath
    )

    if ($PSCmdlet.ShouldProcess($SecurityResultsPath, "Create JUnit security report")) {
        Write-SecurityDebug "Generating JUnit XML security report"

        $timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ss"
        $testSuiteName = "SecurityGate"
        $totalTests = 1
        $failures = if ($GateResults.Passed) { 0 } else { 1 }

        $junitXml = @"
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Security Gate Results" tests="$totalTests" failures="$failures" timestamp="$timestamp">
    <testsuite name="$testSuiteName" tests="$totalTests" failures="$failures" timestamp="$timestamp">
        <testcase name="SecurityGateEvaluation" classname="SecurityGate">
"@

        if (-not $GateResults.Passed) {
            $failureMessage = $GateResults.FailureReasons -join "; "
            $junitXml += @"

            <failure type="SecurityViolation" message="Security gate failed">
$failureMessage

Summary:
- Total Findings: $($GateResults.TotalFindings)
- Critical: $($GateResults.CriticalFindings)
- High: $($GateResults.HighFindings)
- Medium: $($GateResults.MediumFindings)
- IaC: $($GateResults.IaCFindings)
- Dependencies: $($GateResults.DependencyFindings)
- Containers: $($GateResults.ContainerFindings)
            </failure>
"@
        }

        $junitXml += @"

        </testcase>
    </testsuite>
</testsuites>
"@

        $reportFile = Join-Path $SecurityResultsPath "security-gate-results.xml"
        $junitXml | Set-Content -Path $reportFile -Encoding UTF8

        Write-SecurityLog "JUnit security report written to: $reportFile"
        return $reportFile
    }
}

function Write-ConsoleSecurityReport {
    param(
        [PSCustomObject]$GateResults,
        [string]$VulnerabilityThreshold,
        [int]$MaxCriticalVulnerabilities,
        [int]$MaxHighVulnerabilities,
        [int]$MaxMediumVulnerabilities,
        [bool]$EnforceIaCSecurity,
        [bool]$FailOnDependencyVulnerabilities
    )

    Write-Information ""
    Write-Information "=== SECURITY GATE RESULTS ===" -InformationAction Continue
    Write-Information ""

    if ($GateResults.Passed) {
        Write-Information "✅ SECURITY GATE: PASSED" -InformationAction Continue
    }
    else {
        Write-Information "❌ SECURITY GATE: FAILED" -InformationAction Continue
    }

    Write-Information ""
    Write-Information "Security Findings Summary:" -InformationAction Continue
    Write-Information "  Total Findings: $($GateResults.TotalFindings)" -InformationAction Continue
    Write-Information "  Critical: $($GateResults.CriticalFindings)" -InformationAction Continue
    Write-Information "  High: $($GateResults.HighFindings)" -InformationAction Continue
    Write-Information "  Medium: $($GateResults.MediumFindings)" -InformationAction Continue
    Write-Information ""
    Write-Information "Security Source Breakdown:" -InformationAction Continue
    Write-Information "  Container Vulnerabilities: $($GateResults.ContainerFindings)" -InformationAction Continue
    Write-Information "  IaC Security Issues: $($GateResults.IaCFindings)" -InformationAction Continue
    Write-Information "  Dependency Vulnerabilities: $($GateResults.DependencyFindings)" -InformationAction Continue
    Write-Information ""

    if ($GateResults.FailureReasons.Count -gt 0) {
        Write-Information "Failure Reasons:" -InformationAction Continue
        foreach ($reason in $GateResults.FailureReasons) {
            Write-Information "  - $reason" -InformationAction Continue
        }
        Write-Information ""
    }

    Write-Information "Security Gate Configuration:" -InformationAction Continue
    Write-Information "  Vulnerability Threshold: $VulnerabilityThreshold" -InformationAction Continue
    Write-Information "  Max Critical: $MaxCriticalVulnerabilities" -InformationAction Continue
    Write-Information "  Max High: $MaxHighVulnerabilities" -InformationAction Continue
    Write-Information "  Max Medium: $MaxMediumVulnerabilities" -InformationAction Continue
    Write-Information "  Enforce IaC Security: $EnforceIaCSecurity" -InformationAction Continue
    Write-Information "  Fail on Dependencies: $FailOnDependencyVulnerabilities" -InformationAction Continue
    Write-Information ""
}

####
# Main execution
####

function Main {
    param(
        [string]$SecurityResultsPath,
        [string]$VulnerabilityThreshold,
        [int]$MaxCriticalVulnerabilities,
        [int]$MaxHighVulnerabilities,
        [int]$MaxMediumVulnerabilities,
        [bool]$EnforceIaCSecurity,
        [bool]$FailOnDependencyVulnerabilities,
        [string]$OutputFormat,
        [bool]$ExitOnFailure,
        [string]$ConfigFile,
        [string]$Environment,
        [bool]$EnableVerboseLogging
    )

    try {
        # Set verbose preference if specified
        if ($EnableVerboseLogging) {
            $VerbosePreference = 'Continue'
        }

        Write-SecurityLog "Starting security gate evaluation"
        Write-SecurityLog "Security results path: $SecurityResultsPath"
        Write-SecurityLog "Configuration file: $ConfigFile"
        Write-SecurityLog "Environment: $(if ($Environment) { $Environment } else { 'default' })"        # Load configuration
        $config = Get-SecurityConfiguration -ConfigPath $ConfigFile -EnvironmentName $Environment -VulnerabilityThreshold $VulnerabilityThreshold -MaxCriticalVulnerabilities $MaxCriticalVulnerabilities -MaxHighVulnerabilities $MaxHighVulnerabilities -MaxMediumVulnerabilities $MaxMediumVulnerabilities -EnforceIaCSecurity $EnforceIaCSecurity -FailOnDependencyVulnerabilities $FailOnDependencyVulnerabilities -OutputFormat $OutputFormat

        # Update effective configuration values
        $EffectiveVulnerabilityThreshold = $config.VulnerabilityThreshold
        $EffectiveMaxCriticalVulnerabilities = $config.MaxCriticalVulnerabilities
        $EffectiveMaxHighVulnerabilities = $config.MaxHighVulnerabilities
        $EffectiveMaxMediumVulnerabilities = $config.MaxMediumVulnerabilities
        $EffectiveEnforceIaCSecurity = $config.EnforceIaCSecurity
        $EffectiveFailOnDependencyVulnerabilities = $config.FailOnDependencyVulnerabilities
        $EffectiveOutputFormat = $config.OutputFormat

        Write-SecurityLog "Effective vulnerability threshold: $EffectiveVulnerabilityThreshold"
        Write-SecurityLog "Max vulnerabilities - Critical: $EffectiveMaxCriticalVulnerabilities, High: $EffectiveMaxHighVulnerabilities, Medium: $EffectiveMaxMediumVulnerabilities"

        # Ensure results directory exists
        if (-not (Test-Path $SecurityResultsPath)) {
            Write-SecurityWarn "Security results path does not exist: $SecurityResultsPath"
            Write-SecurityWarn "Creating directory and continuing with empty results"
            New-Item -Path $SecurityResultsPath -ItemType Directory -Force | Out-Null
        }

        # Run security gate evaluation
        $gateResults = Invoke-SecurityGateEvaluation -SecurityResultsPath $SecurityResultsPath -VulnerabilityThreshold $EffectiveVulnerabilityThreshold -MaxCriticalVulnerabilities $EffectiveMaxCriticalVulnerabilities -MaxHighVulnerabilities $EffectiveMaxHighVulnerabilities -MaxMediumVulnerabilities $EffectiveMaxMediumVulnerabilities -EnforceIaCSecurity $EffectiveEnforceIaCSecurity -FailOnDependencyVulnerabilities $EffectiveFailOnDependencyVulnerabilities

        # Generate output based on format
        switch ($EffectiveOutputFormat) {
            'junit' {
                $reportFile = New-JUnitSecurityReport -GateResults $gateResults -SecurityResultsPath $SecurityResultsPath
                Write-SecurityLog "JUnit report generated: $reportFile"
            }
            'json' {
                $jsonReport = $gateResults | ConvertTo-Json -Depth 10
                $reportFile = Join-Path $SecurityResultsPath "security-gate-results.json"
                $jsonReport | Set-Content -Path $reportFile -Encoding UTF8
                Write-SecurityLog "JSON report generated: $reportFile"
            }
            'sarif' {
                Write-SecurityWarn "SARIF output format not yet implemented, using JSON"
                $jsonReport = $gateResults | ConvertTo-Json -Depth 10
                $reportFile = Join-Path $SecurityResultsPath "security-gate-results.json"
                $jsonReport | Set-Content -Path $reportFile -Encoding UTF8
            }
            'console' {
                Write-ConsoleSecurityReport -GateResults $gateResults -VulnerabilityThreshold $EffectiveVulnerabilityThreshold -MaxCriticalVulnerabilities $EffectiveMaxCriticalVulnerabilities -MaxHighVulnerabilities $EffectiveMaxHighVulnerabilities -MaxMediumVulnerabilities $EffectiveMaxMediumVulnerabilities -EnforceIaCSecurity $EffectiveEnforceIaCSecurity -FailOnDependencyVulnerabilities $EffectiveFailOnDependencyVulnerabilities
            }
        }

        # Always show console summary
        Write-ConsoleSecurityReport -GateResults $gateResults -VulnerabilityThreshold $EffectiveVulnerabilityThreshold -MaxCriticalVulnerabilities $EffectiveMaxCriticalVulnerabilities -MaxHighVulnerabilities $EffectiveMaxHighVulnerabilities -MaxMediumVulnerabilities $EffectiveMaxMediumVulnerabilities -EnforceIaCSecurity $EffectiveEnforceIaCSecurity -FailOnDependencyVulnerabilities $EffectiveFailOnDependencyVulnerabilities

        # Return results object
        $gateResults

        # Exit with appropriate code
        if (-not $gateResults.Passed -and $ExitOnFailure) {
            Write-SecurityError "Security gate failed - exiting with code 1"
            exit 1
        }
        elseif (-not $gateResults.Passed) {
            Write-SecurityWarn "Security gate failed but ExitOnFailure is false - continuing"
        }
        else {
            Write-SecurityLog "Security gate passed successfully"
            exit 0
        }
    }
    catch {
        Write-SecurityError "Security gate evaluation failed: $($_.Exception.Message)"
        Write-SecurityError "Stack trace: $($_.ScriptStackTrace)"

        if ($ExitOnFailure) {
            exit 1
        }
        else {
            throw
        }
    }
}

# Execute main function with all parameters
Main -SecurityResultsPath $SecurityResultsPath -VulnerabilityThreshold $VulnerabilityThreshold -MaxCriticalVulnerabilities $MaxCriticalVulnerabilities -MaxHighVulnerabilities $MaxHighVulnerabilities -MaxMediumVulnerabilities $MaxMediumVulnerabilities -EnforceIaCSecurity $EnforceIaCSecurity -FailOnDependencyVulnerabilities $FailOnDependencyVulnerabilities -OutputFormat $OutputFormat -ExitOnFailure $ExitOnFailure -ConfigFile $ConfigFile -Environment $Environment -EnableVerboseLogging $EnableVerboseLogging
