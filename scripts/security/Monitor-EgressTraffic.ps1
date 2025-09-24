#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Monitor network egress traffic for CI/CD security analysis
.DESCRIPTION
    This script monitors outbound network connections from CI/CD pipeline runners
    to detect potential supply chain attacks and unauthorized network access.
.PARAMETER AllowedEndpoints
    Comma-separated list of allowed network endpoints for comparison
.PARAMETER OutputPath
    Path to save the egress monitoring results
.PARAMETER MonitoringDuration
    Duration in seconds to monitor network traffic (default: 300)
.PARAMETER Verbose
    Enable verbose logging for troubleshooting
.EXAMPLE
    ./Monitor-EgressTraffic.ps1 -AllowedEndpoints "github.com,docker.io" -OutputPath "./egress-results.json"
.EXAMPLE
    ./Monitor-EgressTraffic.ps1 -MonitoringDuration 600 -Verbose
.NOTES
    This script provides network monitoring capabilities for security analysis.
    It works on Windows, Linux, and macOS platforms using PowerShell Core.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$AllowedEndpoints = "github.com,registry-1.docker.io,*.azurecr.io,packages.microsoft.com",

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "./egress-monitoring.json",

    [Parameter(Mandatory = $false)]
    [int]$MonitoringDuration = 300,

    [Parameter(Mandatory = $false)]
    [string]$ConfigurationPath = "./security-hardening-config.json"
)

# Set error handling
$ErrorActionPreference = 'Continue'
$ProgressPreference = 'SilentlyContinue'

# Initialize logging
$logPrefix = "[EGRESS-MONITOR]"
function Write-LogMessage {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "$timestamp $logPrefix [$Level] $Message"
}

try {
    Write-LogMessage "Starting egress traffic monitoring..."
    Write-LogMessage "Monitoring duration: $MonitoringDuration seconds"
    Write-LogMessage "Output path: $OutputPath"

    # Initialize monitoring results
    $results = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        MonitoringDuration = $MonitoringDuration
        AllowedEndpoints = $AllowedEndpoints -split ','
        Platform = $PSVersionTable.Platform
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        NetworkConnections = @()
        DNSQueries = @()
        ProcessActivity = @()
        SecurityViolations = @()
        Summary = @{}
    }

    # Load existing configuration if available
    if (Test-Path $ConfigurationPath) {
        try {
            $config = Get-Content $ConfigurationPath | ConvertFrom-Json
            Write-LogMessage "Loaded existing security configuration"
            $results.HardeningConfig = $config
        }
        catch {
            Write-LogMessage "Warning: Could not load security configuration: $($_.Exception.Message)" -Level "WARN"
        }
    }

    $monitoringStart = Get-Date
    $monitoringEnd = $monitoringStart.AddSeconds($MonitoringDuration)

    Write-LogMessage "Monitoring network activity from $($monitoringStart.ToString('HH:mm:ss')) to $($monitoringEnd.ToString('HH:mm:ss'))"

    # Function to check if endpoint is allowed
    function Test-AllowedEndpoint {
        param([string]$Endpoint)

        foreach ($allowed in ($AllowedEndpoints -split ',')) {
            $allowed = $allowed.Trim()
            if ($allowed -like "*") {
                # Wildcard matching
                $pattern = $allowed -replace '\*', '.*'
                if ($Endpoint -match $pattern) {
                    return $true
                }
            }
            elseif ($Endpoint -eq $allowed -or $Endpoint -like "*.$allowed") {
                return $true
            }
        }
        return $false
    }

    # Monitor network connections
    $connectionCount = 0
    $violationCount = 0

    while ((Get-Date) -lt $monitoringEnd) {
        try {
            # Get network connections (cross-platform approach)
            $connections = @()

            if ($IsLinux -or $IsMacOS) {
                # Use netstat on Linux/macOS
                try {
                    $netstatOutput = & netstat -an 2>/dev/null
                    if ($netstatOutput) {
                        foreach ($line in $netstatOutput) {
                            if ($line -match '(\d+\.\d+\.\d+\.\d+):(\d+)\s+(\d+\.\d+\.\d+\.\d+):(\d+)\s+(\w+)') {
                                $connections += @{
                                    LocalAddress = $matches[1]
                                    LocalPort = $matches[2]
                                    RemoteAddress = $matches[3]
                                    RemotePort = $matches[4]
                                    State = $matches[5]
                                    Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                                }
                            }
                        }
                    }
                }
                catch {
                    Write-LogMessage "Warning: netstat command failed: $($_.Exception.Message)" -Level "WARN"
                }
            }
            elseif ($IsWindows) {
                # Use Get-NetTCPConnection on Windows
                try {
                    $tcpConnections = Get-NetTCPConnection -State Established -ErrorAction SilentlyContinue
                    foreach ($conn in $tcpConnections) {
                        $connections += @{
                            LocalAddress = $conn.LocalAddress
                            LocalPort = $conn.LocalPort
                            RemoteAddress = $conn.RemoteAddress
                            RemotePort = $conn.RemotePort
                            State = $conn.State
                            ProcessId = $conn.OwningProcess
                            Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                        }
                    }
                }
                catch {
                    Write-LogMessage "Warning: Get-NetTCPConnection failed: $($_.Exception.Message)" -Level "WARN"
                }
            }

            # Process connections and check for violations
            foreach ($connection in $connections) {
                $connectionCount++

                # Skip local connections
                if ($connection.RemoteAddress -match '^(127\.|10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.)' -or
                    $connection.RemoteAddress -eq "::1") {
                    continue
                }

                # Resolve hostname if possible
                $hostname = $connection.RemoteAddress
                try {
                    $resolved = [System.Net.Dns]::GetHostEntry($connection.RemoteAddress)
                    if ($resolved.HostName) {
                        $hostname = $resolved.HostName
                    }
                }
                catch {
                    # DNS resolution failed, use IP address
                    Write-LogMessage "DNS resolution failed for $($connection.RemoteAddress): $($_.Exception.Message)" -Level "DEBUG"
                }

                # Check if endpoint is allowed
                $isAllowed = Test-AllowedEndpoint -Endpoint $hostname

                $connectionInfo = @{
                    RemoteAddress = $connection.RemoteAddress
                    RemotePort = $connection.RemotePort
                    Hostname = $hostname
                    IsAllowed = $isAllowed
                    Timestamp = $connection.Timestamp
                    ProcessId = $connection.ProcessId
                }

                $results.NetworkConnections += $connectionInfo

                if (-not $isAllowed) {
                    $violationCount++
                    $violation = @{
                        Type = "UnauthorizedNetworkAccess"
                        Description = "Connection to unauthorized endpoint: $hostname ($($connection.RemoteAddress):$($connection.RemotePort))"
                        RemoteAddress = $connection.RemoteAddress
                        RemotePort = $connection.RemotePort
                        Hostname = $hostname
                        Timestamp = $connection.Timestamp
                        ProcessId = $connection.ProcessId
                        Severity = "Medium"
                    }
                    $results.SecurityViolations += $violation

                    Write-LogMessage "Security violation: Unauthorized connection to $hostname" -Level "WARN"
                }
            }

            # Get running processes
            try {
                $processes = Get-Process | Where-Object {
                    $_.StartTime -and $_.StartTime -gt $monitoringStart.AddMinutes(-5)
                } | Select-Object Id, ProcessName, StartTime, Path

                foreach ($process in $processes) {
                    $results.ProcessActivity += @{
                        Id = $process.Id
                        Name = $process.ProcessName
                        StartTime = $process.StartTime
                        Path = $process.Path
                        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                    }
                }
            }
            catch {
                Write-LogMessage "Warning: Could not get process information: $($_.Exception.Message)" -Level "WARN"
            }

        }
        catch {
            Write-LogMessage "Error during monitoring cycle: $($_.Exception.Message)" -Level "ERROR"
        }

        # Sleep between monitoring cycles
        Start-Sleep -Seconds 10
    }

    # Generate summary
    $results.Summary = @{
        TotalConnections = $connectionCount
        UniqueEndpoints = ($results.NetworkConnections | Group-Object RemoteAddress).Count
        SecurityViolations = $violationCount
        AllowedConnections = ($results.NetworkConnections | Where-Object { $_.IsAllowed }).Count
        UnauthorizedConnections = ($results.NetworkConnections | Where-Object { -not $_.IsAllowed }).Count
        MonitoringDurationActual = [math]::Round(((Get-Date) - $monitoringStart).TotalSeconds, 2)
        ComplianceScore = if ($connectionCount -gt 0) {
            [math]::Round((($connectionCount - $violationCount) / $connectionCount) * 100, 2)
        } else {
            100
        }
    }

    # Save results
    $results | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
    Write-LogMessage "Egress monitoring results saved to: $OutputPath"

    # Output summary
    Write-LogMessage "Monitoring completed successfully"
    Write-LogMessage "Total connections: $($results.Summary.TotalConnections)"
    Write-LogMessage "Security violations: $($results.Summary.SecurityViolations)"
    Write-LogMessage "Compliance score: $($results.Summary.ComplianceScore)%"

    # Set CI/CD outputs
    if ($env:GITHUB_ACTIONS) {
        Write-Output "::set-output name=compliance-score::$($results.Summary.ComplianceScore)"
        Write-Output "::set-output name=violations::$($results.Summary.SecurityViolations)"
        Write-Output "::set-output name=total-connections::$($results.Summary.TotalConnections)"

        if ($results.Summary.SecurityViolations -gt 0) {
            Write-Output "::warning::Detected $($results.Summary.SecurityViolations) security violations in network traffic"
        }
    }

    if ($env:AZURE_DEVOPS) {
        Write-Output "##vso[task.setvariable variable=ComplianceScore;isOutput=true]$($results.Summary.ComplianceScore)"
        Write-Output "##vso[task.setvariable variable=SecurityViolations;isOutput=true]$($results.Summary.SecurityViolations)"
        Write-Output "##vso[task.setvariable variable=TotalConnections;isOutput=true]$($results.Summary.TotalConnections)"

        if ($results.Summary.SecurityViolations -gt 0) {
            Write-Output "##vso[task.logissue type=warning]Detected $($results.Summary.SecurityViolations) security violations in network traffic"
        }
    }

    exit 0

}
catch {
    Write-LogMessage "Error during egress monitoring: $($_.Exception.Message)" -Level "ERROR"
    Write-LogMessage "Stack trace: $($_.ScriptStackTrace)" -Level "ERROR"

    # Create minimal error results
    $errorResults = @{
        Timestamp = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
        Status = "Error"
        Error = $_.Exception.Message
        Summary = @{
            TotalConnections = 0
            SecurityViolations = 0
            ComplianceScore = 0
        }
    }

    $errorResults | ConvertTo-Json -Depth 5 | Set-Content -Path $OutputPath -Encoding UTF8

    if ($env:GITHUB_ACTIONS) {
        Write-Output "::error::Egress monitoring failed: $($_.Exception.Message)"
    }

    if ($env:AZURE_DEVOPS) {
        Write-Output "##vso[task.logissue type=error]Egress monitoring failed: $($_.Exception.Message)"
    }

    exit 1
}
