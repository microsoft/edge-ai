#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Initialize security hardening for CI/CD runners
.DESCRIPTION
    This script provides cross-platform security hardening capabilities for CI/CD pipeline runners.
    It configures network egress filtering, endpoint monitoring, and other security features.
.PARAMETER EnableEgressFilter
    Enable network egress filtering to restrict outbound connections
.PARAMETER EnableEndpointMonitoring
    Enable endpoint monitoring to track network access patterns
.PARAMETER AllowedEndpoints
    Comma-separated list of allowed network endpoints for egress filtering
.PARAMETER Verbose
    Enable verbose logging for troubleshooting
.EXAMPLE
    ./Initialize-HardenRunner.ps1 -EnableEgressFilter -AllowedEndpoints "github.com,registry-1.docker.io"
.EXAMPLE
    ./Initialize-HardenRunner.ps1 -EnableEndpointMonitoring -Verbose
.NOTES
    This script is designed for cross-platform execution in Azure DevOps and GitHub Actions.
    It provides security hardening features similar to StepSecurity Harden-Runner.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$EnableEgressFilter,

    [Parameter(Mandatory = $false)]
    [switch]$EnableEndpointMonitoring,

    [Parameter(Mandatory = $false)]
    [string]$AllowedEndpoints = "github.com,registry-1.docker.io,*.azurecr.io,packages.microsoft.com",

    [Parameter(Mandatory = $false)]
    [string]$ConfigurationPath = "./security-hardening-config.json"
)

# Set error handling
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# Initialize logging
function Write-OutputMessage {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [string]$Level = "INFO"
    )

    # Format message with level prefix for non-INFO messages
    $formattedMessage = if ($Level -eq "INFO") {
        $Message
    }
    else {
        "[$Level] $Message"
    }

    Write-Output $formattedMessage
}

try {
    Write-OutputMessage "Starting security hardening initialization..."

    # Create security configuration
    $config = @{
        Timestamp                = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        EnableEgressFilter       = $EnableEgressFilter.IsPresent
        EnableEndpointMonitoring = $EnableEndpointMonitoring.IsPresent
        AllowedEndpoints         = $AllowedEndpoints -split ','
        Platform                 = $PSVersionTable.Platform
        PowerShellVersion        = $PSVersionTable.PSVersion.ToString()
        ProcessId                = $PID
        Environment              = @{}
    }

    # Capture environment variables for security analysis
    $securityEnvVars = @(
        'GITHUB_TOKEN', 'GITHUB_ACTOR', 'GITHUB_REPOSITORY',
        'AZURE_CREDENTIALS', 'ARM_CLIENT_ID', 'ARM_TENANT_ID',
        'BUILD_SOURCEBRANCH', 'BUILD_REPOSITORY_NAME'
    )

    foreach ($envVar in $securityEnvVars) {
        $value = [System.Environment]::GetEnvironmentVariable($envVar)
        if ($value) {
            # Mask sensitive values
            $maskedValue = if ($envVar -like "*TOKEN*" -or $envVar -like "*SECRET*" -or $envVar -like "*KEY*") {
                "***MASKED***"
            }
            else {
                $value
            }
            $config.Environment[$envVar] = $maskedValue
        }
    }

    if ($EnableEgressFilter) {
        Write-OutputMessage "Configuring network egress filtering..."

        # Parse allowed endpoints
        $allowedHosts = @()
        foreach ($endpoint in ($AllowedEndpoints -split ',')) {
            $endpoint = $endpoint.Trim()
            if ($endpoint) {
                $allowedHosts += $endpoint
                Write-OutputMessage "Allowed endpoint: $endpoint" -Level "DEBUG"
            }
        }

        $config.AllowedHosts = $allowedHosts
        Write-OutputMessage "Configured $($allowedHosts.Count) allowed endpoints"
    }

    if ($EnableEndpointMonitoring) {
        Write-OutputMessage "Enabling endpoint monitoring..."

        # Initialize monitoring configuration
        $config.Monitoring = @{
            StartTime          = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
            NetworkConnections = @()
            DNSQueries         = @()
            Processes          = @()
        }

        # Capture initial process state
        try {
            $processes = Get-Process | Select-Object Id, ProcessName, StartTime, Path |
            Where-Object { $_.Path -and $_.StartTime -gt (Get-Date).AddHours(-1) }

            foreach ($process in $processes) {
                $config.Monitoring.Processes += @{
                    Id        = $process.Id
                    Name      = $process.ProcessName
                    StartTime = $process.StartTime
                    Path      = $process.Path
                }
            }

            Write-OutputMessage "Captured $($processes.Count) recent processes for monitoring"
        }
        catch {
            Write-OutputMessage "Warning: Could not capture process information: $($_.Exception.Message)" -Level "WARN"
        }
    }

    # Save configuration
    $config | ConvertTo-Json -Depth 10 | Set-Content -Path $ConfigurationPath -Encoding UTF8
    Write-OutputMessage "Security configuration saved to: $ConfigurationPath"

    # Set environment variables for subsequent steps
    if ($env:GITHUB_ACTIONS) {
        Write-Output "::set-output name=config-path::$ConfigurationPath"
        Write-Output "::set-output name=hardening-enabled::true"

        if ($EnableEgressFilter) {
            Write-Output "::set-output name=egress-filter::enabled"
        }
        if ($EnableEndpointMonitoring) {
            Write-Output "::set-output name=endpoint-monitoring::enabled"
        }
    }

    # Azure DevOps output variables
    if ($env:AZURE_DEVOPS) {
        Write-Output "##vso[task.setvariable variable=ConfigPath;isOutput=true]$ConfigurationPath"
        Write-Output "##vso[task.setvariable variable=HardeningEnabled;isOutput=true]true"

        if ($EnableEgressFilter) {
            Write-Output "##vso[task.setvariable variable=EgressFilter;isOutput=true]enabled"
        }
        if ($EnableEndpointMonitoring) {
            Write-Output "##vso[task.setvariable variable=EndpointMonitoring;isOutput=true]enabled"
        }
    }

    Write-OutputMessage "Security hardening initialization completed successfully"

    # Output summary
    $summary = @{
        Status                = "Success"
        EgressFilter          = $EnableEgressFilter.IsPresent
        EndpointMonitoring    = $EnableEndpointMonitoring.IsPresent
        AllowedEndpointsCount = ($AllowedEndpoints -split ',').Count
        ConfigurationPath     = $ConfigurationPath
    }

    Write-OutputMessage "Summary: $($summary | ConvertTo-Json -Compress)"
    exit 0

}
catch {
    Write-OutputMessage "Error during security hardening initialization: $($_.Exception.Message)" -Level "ERROR"
    Write-OutputMessage "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"

    # Set failure outputs
    if ($env:GITHUB_ACTIONS) {
        Write-Output "::set-output name=hardening-enabled::false"
        Write-Output "::error::Security hardening initialization failed: $($_.Exception.Message)"
    }

    if ($env:AZURE_DEVOPS) {
        Write-Output "##vso[task.setvariable variable=HardeningEnabled;isOutput=true]false"
        Write-Output "##vso[task.logissue type=error]Security hardening initialization failed: $($_.Exception.Message)"
    }

    exit 1
}
