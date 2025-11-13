#!/usr/bin/env pwsh

<#
.SYNOPSIS
Builds Docker applications with comprehensive validation, security scanning, and provenance generation.

.DESCRIPTION
Orchestrates complete Docker application build workflow including parameter validation,
dependency checking, multi-language vulnerability auditing, Docker Compose detection,
service structure analysis, build execution, container security scanning, SLSA provenance
bundle generation, and structured JSON output. Supports dry-run mode for command preview
without execution.

Features:
- Automatic detection of docker-compose files and service directories
- Multi-language dependency vulnerability scanning (.NET, Rust, Node.js, Python)
- Docker image builds with consistent naming and labeling conventions
- Optional container security scanning with configurable severity thresholds
- SLSA provenance bundle generation for supply chain security
- Support for multiple container registries with authentication
- Comprehensive build logging and structured output
- Dry-run mode for build validation without execution

.PARAMETER AppPath
Path to the application directory containing docker-compose.yml or Dockerfile(s).

.PARAMETER AppName
Name of the application used for image tagging and build identification.

.PARAMETER Registry
Container registry URL for image storage. Defaults to 'local' for local-only builds.

.PARAMETER BuildId
Unique build identifier used for image tags and provenance tracking.

.PARAMETER BuildEnv
Build environment designation (dev, staging, prod) for environment-specific configurations.

.PARAMETER CommitSha
Git commit SHA hash for build traceability and provenance metadata.

.PARAMETER BaseImageTag
Base image tag for multi-stage builds. Defaults to BuildId if not specified.

.PARAMETER DockerBuildArgs
Additional Docker build arguments as JSON string. Supports key-value pairs and special flags.

.PARAMETER PushImages
Switch to enable pushing built images to the configured registry.

.PARAMETER EnableSecurityScan
Switch to enable container security scanning using external vulnerability scanners.

.PARAMETER SecurityThreshold
Minimum severity threshold for security scan failures. Valid values: negligible, low, medium, high, critical. Default: medium.

.PARAMETER GenerateSlsa
Switch to enable SLSA provenance bundle generation for supply chain attestation.

.PARAMETER VerboseLogging
Switch to enable verbose debug logging output.

.PARAMETER DryRun
Switch to preview build commands without executing them.

.EXAMPLE
./Application-Builder.ps1 -AppPath src/500-application/501-sample-app -AppName sample-app -BuildId build-123 -BuildEnv dev -CommitSha abc123

.EXAMPLE
# Build and push with all features
./Application-Builder.ps1 -AppPath src/500-application/501-sample-app -AppName sample-app -Registry myregistry.azurecr.io -BuildId build-123 -BuildEnv prod -CommitSha abc123 -PushImages -GenerateSlsa -EnableSecurityScan -SecurityThreshold high

Builds application with basic configuration for development environment.

.EXAMPLE
./application-builder.ps1 -AppPath src/500-application/501-sample-app -AppName sample-app -Registry myregistry.azurecr.io -BuildId build-123 -BuildEnv prod -CommitSha abc123 -PushImages -GenerateSlsa -EnableSecurityScan -SecurityThreshold high

Builds application with full production pipeline including security scanning, SLSA provenance, and registry push.

.NOTES
Version: 1.0
Requires: PowerShell 7+, Docker, and appropriate language toolchains for dependency auditing.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$AppPath,

    [Parameter(Mandatory = $true)]
    [string]$AppName,

    [Parameter(Mandatory = $false)]
    [string]$Registry = "local",

    [Parameter(Mandatory = $true)]
    [string]$BuildId,

    [Parameter(Mandatory = $true)]
    [string]$BuildEnv,

    [Parameter(Mandatory = $true)]
    [string]$CommitSha,

    [Parameter(Mandatory = $false)]
    [string]$BaseImageTag,

    [Parameter(Mandatory = $false)]
    [string]$DockerBuildArgs,

    [Parameter(Mandatory = $false)]
    [switch]$PushImages,

    [Parameter(Mandatory = $false)]
    [switch]$GenerateSlsa,

    [Parameter(Mandatory = $false)]
    [switch]$EnableSecurityScan,

    [Parameter(Mandatory = $false)]
    [ValidateSet('negligible', 'low', 'medium', 'high', 'critical')]
    [string]$SecurityThreshold = 'medium',

    [Parameter(Mandatory = $false)]
    [switch]$VerboseLogging,

    [Parameter(Mandatory = $false)]
    [switch]$DryRun
)

# Import ApplicationBuilder modules
$ModulePath = Join-Path $PSScriptRoot "modules"
Import-Module (Join-Path $ModulePath "ApplicationBuilder.Helpers.psm1") -Force
Import-Module (Join-Path $ModulePath "ApplicationBuilder.Compose.psm1") -Force
Import-Module (Join-Path $ModulePath "ApplicationBuilder.Build.psm1") -Force
Import-Module (Join-Path $ModulePath "ApplicationBuilder.DependencyAudit.psm1") -Force

# Phase 1: Environment Setup
# Set strict mode and error handling
Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"
$PSDefaultParameterValues['*:ErrorAction'] = 'Stop'

# Normalize build metadata for Docker tag compatibility
$originalBuildId = $BuildId
$BuildId = ConvertTo-DockerTagValue -Source $BuildId -Fallback "build"
Test-DockerTagValue -Value $BuildId -Name "BuildId"
if ($BuildId -ne $originalBuildId) {
    Write-BuildDebug "Normalized BuildId from '$originalBuildId' to '$BuildId'"
}

$originalBuildEnv = $BuildEnv
$BuildEnv = ConvertTo-DockerTagValue -Source $BuildEnv -Fallback "environment"
Test-DockerTagValue -Value $BuildEnv -Name "BuildEnv"
if ($BuildEnv -ne $originalBuildEnv) {
    Write-BuildDebug "Normalized BuildEnv from '$originalBuildEnv' to '$BuildEnv'"
}

if ([string]::IsNullOrWhiteSpace($BaseImageTag)) {
    $BaseImageTag = $BuildId
}
else {
    $originalBaseImageTag = $BaseImageTag
    $BaseImageTag = ConvertTo-DockerTagValue -Source $BaseImageTag -Fallback $BuildId
    Test-DockerTagValue -Value $BaseImageTag -Name "BaseImageTag"
    if ($BaseImageTag -ne $originalBaseImageTag) {
        Write-BuildDebug "Normalized BaseImageTag from '$originalBaseImageTag' to '$BaseImageTag'"
    }
}

# Configure environment variables
$env:BASE_IMAGE_TAG = $BaseImageTag
$env:DOCKER_BUILDKIT = if ($env:DOCKER_BUILDKIT) { $env:DOCKER_BUILDKIT } else { "1" }
$env:DOCKER_CLI_EXPERIMENTAL = if ($env:DOCKER_CLI_EXPERIMENTAL) { $env:DOCKER_CLI_EXPERIMENTAL } else { "enabled" }

# Enable verbose logging if requested
if ($VerboseLogging) {
    $VerbosePreference = 'Continue'
}

####
# Main script execution
####

try {
    Write-BuildLog "Starting application build process"
    Write-BuildLog "Application: $AppName"
    Write-BuildLog "Path: $AppPath"
    Write-BuildLog "Registry: $Registry"
    Write-BuildLog "Build ID: $BuildId"
    Write-BuildLog "Environment: $BuildEnv"

    Write-BuildLog "Commit SHA: $CommitSha"

    # Store original directory
    $originalDir = Get-Location

    # Parse Docker build arguments if provided
    $parsedBuildArgs = $null
    if (-not [string]::IsNullOrWhiteSpace($DockerBuildArgs)) {
        try {
            $parsedBuildArgs = $DockerBuildArgs | ConvertFrom-Json
            Write-BuildDebug "Parsed Docker build arguments: $($parsedBuildArgs | ConvertTo-Json -Compress)"
        }
        catch {
            Write-Warn "Failed to parse DockerBuildArgs as JSON, treating as string: $_"
            $parsedBuildArgs = $DockerBuildArgs
        }
    }

    # Phase 2: Build Context Creation and Parameter Validation
    # Create build context
    Write-BuildDebug "Creating build context"
    $context = New-BuildContext `
        -AppPath $AppPath `
        -AppName $AppName `
        -Registry $Registry `
        -BuildId $BuildId `
        -BuildEnv $BuildEnv `
        -CommitSha $CommitSha `
        -BaseImageTag $BaseImageTag `
        -DockerBuildArgs $parsedBuildArgs `
        -PushImages:$PushImages `
        -DryRun:$DryRun

    if ($null -eq $context) {
        throw "Failed to create build context"
    }

    # Validate required parameters
    Write-BuildDebug "Validating parameters"
    Test-Parameter -Context $context

    # Check dependencies
    Write-BuildDebug "Checking dependencies"
    Test-Dependency -Context $context

    # Configure Cargo registry source based on pipeline environment
    Initialize-RustRegistryConfiguration -Context $context

    # Generate Cargo.lock files for Rust projects with private registry dependencies
    # Only regenerate in CI/CD pipelines when private registries (aio-sdks) are detected
    # This ensures lock files with public registry references work locally while supporting
    # pipeline registry flipping for private dependencies
    $cargoToml = Join-Path $context.App.Path "Cargo.toml"
    if (Test-Path $cargoToml) {
        $tomlContent = Get-Content -Path $cargoToml -Raw
        $usesPrivateRegistry = $tomlContent -match 'registry\s*=\s*[''"]aio-sdks[''"]'

        # Detect CI/CD pipeline environment (Azure DevOps, GitHub Actions, etc.)
        $isPipeline = ($env:TF_BUILD -eq 'True') -or ($env:GITHUB_ACTIONS -eq 'true') -or ($env:CI -eq 'true')

        if ($usesPrivateRegistry -and $isPipeline) {
            Write-BuildLog "Private registry (aio-sdks) detected - regenerating Cargo.lock for CI/CD environment"
            $cargoExecutable = Get-Command -Name 'cargo' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
            if ($cargoExecutable) {
                try {
                    Push-Location -Path $context.App.Path
                    $lockOutput = & $cargoExecutable generate-lockfile 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-BuildLog "Cargo.lock regenerated successfully with private registry configuration"
                    }
                    else {
                        Write-Warn "Failed to regenerate Cargo.lock: $($lockOutput -join "`n")"
                    }
                }
                catch {
                    Write-Warn "Error regenerating Cargo.lock: $_"
                }
                finally {
                    Pop-Location
                }
            }
            else {
                Write-Warn "cargo CLI not available; skipping Cargo.lock regeneration"
            }
        }
        elseif (-not (Test-Path (Join-Path $context.App.Path "Cargo.lock"))) {
            Write-BuildLog "No Cargo.lock found - generating for dependency audit"
            $cargoExecutable = Get-Command -Name 'cargo' -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Source
            if ($cargoExecutable) {
                try {
                    Push-Location -Path $context.App.Path
                    $lockOutput = & $cargoExecutable generate-lockfile 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-BuildLog "Cargo.lock generated successfully"
                    }
                    else {
                        Write-Warn "Failed to generate Cargo.lock: $($lockOutput -join "`n")"
                    }
                }
                catch {
                    Write-Warn "Error generating Cargo.lock: $_"
                }
                finally {
                    Pop-Location
                }
            }
            else {
                Write-Warn "cargo CLI not available; skipping Cargo.lock generation"
            }
        }
        else {
            Write-BuildLog "Using committed Cargo.lock for dependency audit"
        }
    }

    # Phase 3: Dependency Audit (Multi-language Vulnerability Scanning)
    # Run dependency audit for security vulnerabilities
    Write-BuildLog "Running dependency audit"
    $auditPassed = Test-DependencyAudit -Context $context
    if (-not $auditPassed) {
        Write-Error "Dependency audit failed - build aborted due to vulnerabilities or errors"
        Write-Error "Review audit results above for security issues that must be resolved"
        exit 1
    }

    # Phase 4: Docker Compose Detection
    # Initialize Docker Compose detection
    Write-BuildDebug "Initializing Compose detection"
    Test-ComposeRequirement -Context $context

    # Phase 5: Application Structure Analysis
    # Detect application structure
    Write-BuildLog "Detecting application structure"
    Get-ApplicationStructure -Context $context

    # Check if component is marked as non-buildable (dev-only with .nobuild marker)
    if (-not $context.Compose.Available -and $context.Compose.DetectedServices.Count -eq 0) {
        $noBuildMarker = Join-Path -Path $context.App.Path -ChildPath ".nobuild"
        if (Test-Path -LiteralPath $noBuildMarker) {
            Write-BuildLog "Skipping build phases for non-buildable component"
            Write-BuildLog "Generating build output"
            $output = Get-BuildOutput -Context $context
            Write-Output $output
            exit 0
        }
    }

    # Phase 6: Build Orchestration (Compose or Individual)
    # Build all services
    Write-BuildLog "Building services"
    Build-AllService -Context $context -DryRun:$DryRun

    # Phase 7: Container Security Scanning
    # Run security scans on successful builds
    if ($EnableSecurityScan) {
        Write-BuildLog "Running security scans"
        Invoke-SecurityScan -Context $context -Threshold $SecurityThreshold
    }

    # Phase 8: SLSA Provenance Generation
    # Generate SLSA bundle
    if ($GenerateSlsa) {
        Write-BuildLog "Generating SLSA bundle"
        New-SlsaBundle -Context $context
    }

    # Phase 9: Build Summary and Result Aggregation
    # Generate and return final output
    Write-BuildLog "Generating build output"
    $output = Get-BuildOutput -Context $context
    Write-FailureSummary -Context $context

    # Phase 10: Output Generation and Exit Handling
    $failedCount = $context.Build.Failed.Count
    $securityFailedCount = $context.Security.Failed

    # Distinguish between tool failures and actual security policy violations
    $securityFindingCount = ($context.Security.Results | Where-Object {
            -not $_.thresholdPassed -and -not ($_.PSObject.Properties['toolFailure'] -and $_.toolFailure)
        } | Measure-Object).Count

    $toolFailureCount = ($context.Security.Results | Where-Object {
            $_.PSObject.Properties['toolFailure'] -and $_.toolFailure -eq $true
        } | Measure-Object).Count

    if ($failedCount -eq 0 -and $securityFailedCount -eq 0) {
        $exitCode = 0
        $finalMessage = "All services built successfully and security scans passed"
    }
    elseif ($failedCount -gt 0) {
        $exitCode = 1
        $finalMessage = "Some services failed to build (failed: $failedCount)"
    }
    elseif ($securityFindingCount -gt 0) {
        # Only fail on actual security findings that violate policy
        $exitCode = 1
        $finalMessage = "Security Gate policy violations detected (findings above threshold: $securityFindingCount)"
    }
    elseif ($toolFailureCount -gt 0) {
        # Fail build on scanner tool failures - security tools must succeed
        $exitCode = 1
        $finalMessage = "Security scanner tool failures detected: $toolFailureCount (must resolve before deployment)"
        Write-Error "❌ Security scanning tools failed - build blocked. Review logs for diagnostic details."
    }
    else {
        $exitCode = 0
        $finalMessage = "All services built successfully and security scans passed"
    }

    Write-BuildLog $finalMessage

    # Return to original directory prior to emitting structured output
    Set-Location $originalDir

    # Emit results as structured JSON only after all logging
    $outputJson = $output | ConvertTo-Json -Depth 10
    Write-Output $outputJson
    exit $exitCode
}
catch {
    $errorRecord = $_
    Write-BuildError "Script execution failed: $errorRecord"
    exit 1
}
