#Requires -Version 7.0

<#
.SYNOPSIS
    Start unified development servers for documentation and progress tracking.

.DESCRIPTION
    Unified development server script that starts both:
    - Docsify documentation server (port 8080)
    - Express progress tracking server (port 3002)

.PARAMETER StartPage
    Specify starting page/route (e.g., 'learning/').

.PARAMETER DocsPort
    Port for the documentation server (default: 8080).

.PARAMETER ProgressPort
    Port for the Express progress server (default: 3002).

.EXAMPLE
    .\Serve-Docs.ps1
    Start both documentation and progress servers.

.EXAMPLE
    .\Serve-Docs.ps1 -StartPage "learning/"
    Start both servers and open browser to Learning section.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$StartPage = '',

    [Parameter(Mandatory = $false)]
    [int]$DocsPort = 8080,

    [Parameter(Mandatory = $false)]
    [int]$ProgressPort = 3002
)

$ErrorActionPreference = 'Stop'

# Configuration
$script:ServerJobs = @()
$script:ServerProcesses = @()
$script:docsifyProcess = $null

# Environment Detection
function Get-RuntimeEnvironment {
    # Cross-platform Windows detection
    if ($PSVersionTable.PSVersion.Major -ge 6) {
        # PowerShell Core - use Platform property
        $windowsDetected = $PSVersionTable.Platform -eq "Win32NT"
        $platformInfo = $PSVersionTable.Platform
    } else {
        # Windows PowerShell 5.1 - use OS environment variable
        $windowsDetected = $env:OS -eq "Windows_NT"
        $platformInfo = [System.Environment]::OSVersion.Platform
    }

    $environment = @{
        IsContainer = $false
        IsWindowsPlatform = $windowsDetected
        IsDevContainer = $false
        Platform = $platformInfo
        DetectedHost = "localhost"
    }    # Check for container indicators
    $containerIndicators = @(
        $env:CONTAINER,
        $env:DOCKER,
        $env:KUBERNETES_SERVICE_HOST,
        $env:CODESPACES,
        $env:REMOTE_CONTAINERS,
        $env:VSCODE_REMOTE_CONTAINERS_SESSION,
        $env:DEVCONTAINER
    )

    $environment.IsContainer = $null -ne ($containerIndicators | Where-Object { $_ })
    $environment.IsDevContainer = $env:REMOTE_CONTAINERS -or $env:VSCODE_REMOTE_CONTAINERS_SESSION -or $env:DEVCONTAINER

    # Determine appropriate host for health checks
    if ($environment.IsContainer -or $environment.IsDevContainer) {
        $environment.DetectedHost = "localhost"  # Use localhost for health checks even in containers
    } elseif ($environment.IsWindowsPlatform) {
        $environment.DetectedHost = "localhost"  # Windows local development
    } else {
        $environment.DetectedHost = "localhost"  # Default for Linux/macOS
    }

    return $environment
}

$script:RuntimeEnvironment = Get-RuntimeEnvironment

# Helper Functions
function Write-ServerLog {
    param(
        [string]$Message,
        [string]$Color = 'White',
        [string]$ServerName = $null
    )

    $timestamp = Get-Date -Format "HH:mm:ss"
    $prefix = if ($ServerName) { "[$ServerName]" } else { "" }
    $logMessage = "[$timestamp] $prefix $Message"

    Write-Host $logMessage -ForegroundColor $Color
}

function Test-DocsifyInstalled {
    # Check if docsify-cli is available locally
    $nodeModules = Join-Path $PWD "node_modules"
    $docsifyPath = Join-Path $nodeModules ".bin/docsify"

    if (Test-Path $docsifyPath) {
        Write-ServerLog "Found local docsify at: $docsifyPath" -Color Green
        return $true
    }

    # Fallback to global check
    try {
        $null = & docsify --version 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-ServerLog "Found global docsify" -Color Green
            return $true
        }
    } catch {
        Write-ServerLog "Docsify not found globally" -Color Yellow
    }

    Write-ServerLog "Docsify not found locally or globally" -Color Red
    return $false
}

function Install-LocalDependency {
    Write-ServerLog "Installing local dependencies..." -Color Yellow
    & npm install
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install local dependencies"
    }
    Write-ServerLog "Local dependencies installed successfully" -Color Green
}

function Test-LocalDependenciesReady {
    # Check if both Express and Docsify dependencies are installed locally
    $nodeModules = Join-Path $PWD "node_modules"
    $expressPath = Join-Path $nodeModules "express"
    $docsifyPath = Join-Path $nodeModules "docsify-cli"

    $expressExists = Test-Path $expressPath
    $docsifyExists = Test-Path $docsifyPath

    Write-ServerLog "Checking dependencies: Express=$expressExists, Docsify=$docsifyExists" -Color Yellow

    return $expressExists -and $docsifyExists
}

function Start-DocsifyServer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [int]$Port = 8080
    )

    if (-not $PSCmdlet.ShouldProcess("localhost:$Port", "Start Docsify server")) {
        return
    }

    Write-ServerLog "Starting Docsify server on port $Port..." -Color Blue -ServerName "Docsify"
    Write-ServerLog "Environment: Container=$($script:RuntimeEnvironment.IsContainer), Windows=$($script:RuntimeEnvironment.IsWindowsPlatform), DevContainer=$($script:RuntimeEnvironment.IsDevContainer)" -Color Yellow -ServerName "Docsify"

    # Determine the best way to start Docsify based on environment
    $docsifyCommand = $null
    $docsifyArgs = @()

    # Try different approaches based on environment
    $nodeModules = Join-Path $PWD "node_modules"
    $localDocsify = Join-Path $nodeModules ".bin/docsify"
    $localDocsifyCmd = Join-Path $nodeModules ".bin/docsify.cmd"

    if ($script:RuntimeEnvironment.IsWindowsPlatform -and -not $script:RuntimeEnvironment.IsDevContainer) {
        # Windows local development - try different approaches
        # On Windows, Start-Process needs the .cmd wrapper, not the .ps1 file

        # Check for global docsify.cmd using npm global directory
        # On Windows, we need the .cmd wrapper, not the .ps1 script
        $globalDocsifyCmd = $null

        # Get npm global prefix to find globally installed docsify-cli
        try {
            $npmGlobalPrefix = npm config get prefix 2>&1 | Where-Object { $_ -is [string] -and $_ -notlike "*error*" } | Select-Object -First 1
        } catch {
            $npmGlobalPrefix = $null
        }

        if ($npmGlobalPrefix) {
            $globalDocsifyCmd = Join-Path $npmGlobalPrefix "docsify.cmd"

            if (-not (Test-Path $globalDocsifyCmd)) {
                $globalDocsifyCmd = $null
            }
        }

        if ($globalDocsifyCmd -and (Test-Path $globalDocsifyCmd)) {
            Write-ServerLog "Using global docsify.cmd on Windows..." -Color Yellow -ServerName "Docsify"
            $docsifyCommand = $globalDocsifyCmd
            $docsifyArgs = @('serve', '.', '--port', $Port.ToString())
        } elseif (Test-Path $localDocsifyCmd) {
            Write-ServerLog "Using local docsify.cmd for Windows..." -Color Yellow -ServerName "Docsify"
            $docsifyCommand = $localDocsifyCmd
            $docsifyArgs = @('serve', '.', '--port', $Port.ToString())
        } else {
            Write-ServerLog "No .cmd wrapper found for docsify on Windows" -Color Red -ServerName "Docsify"
            Write-ServerLog "Checked: Global=$globalDocsifyCmd, Local=$localDocsifyCmd" -Color Red -ServerName "Docsify"
            throw "Cannot start docsify on Windows - .cmd wrapper not found. Try: npm install -g docsify-cli"
        }
    } elseif ($script:RuntimeEnvironment.IsContainer -or $script:RuntimeEnvironment.IsDevContainer) {
        # Container environment - use node directly
        if (Test-Path $localDocsify) {
            Write-ServerLog "Using local docsify binary in container..." -Color Yellow -ServerName "Docsify"
            $docsifyCommand = $localDocsify
            $docsifyArgs = @('serve', '.', '--port', $Port.ToString())
        } else {
            Write-ServerLog "Using npx in container..." -Color Yellow -ServerName "Docsify"
            $docsifyCommand = "npx"
            $docsifyArgs = @('docsify-cli', 'serve', '.', '--port', $Port.ToString())
        }
    } else {
        # Linux/macOS local development
        if (Test-Path $localDocsify) {
            Write-ServerLog "Using local docsify binary..." -Color Yellow -ServerName "Docsify"
            $docsifyCommand = $localDocsify
            $docsifyArgs = @('serve', '.', '--port', $Port.ToString())
        } elseif (Get-Command "docsify" -ErrorAction SilentlyContinue) {
            Write-ServerLog "Using global docsify..." -Color Yellow -ServerName "Docsify"
            $docsifyCommand = "docsify"
            $docsifyArgs = @('serve', '.', '--port', $Port.ToString())
        } else {
            Write-ServerLog "Using npx as fallback..." -Color Yellow -ServerName "Docsify"
            $docsifyCommand = "npx"
            $docsifyArgs = @('docsify-cli', 'serve', '.', '--port', $Port.ToString())
        }
    }

    Write-ServerLog "Command: $docsifyCommand $($docsifyArgs -join ' ')" -Color Yellow -ServerName "Docsify"

    try {
        $script:docsifyProcess = Start-Process -FilePath $docsifyCommand -ArgumentList $docsifyArgs -WorkingDirectory $PWD -NoNewWindow -PassThru
        Write-ServerLog "Docsify server started (Process ID: $($script:docsifyProcess.Id))" -Color Green -ServerName "Docsify"
        Write-ServerLog "Documentation available at: http://localhost:$Port" -Color Cyan -ServerName "Docsify"
    } catch {
        Write-ServerLog "Error starting Docsify: $($_.Exception.Message)" -Color Red -ServerName "Docsify"
        throw
    }

    return $script:docsifyProcess
}

function Start-ExpressServer {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [int]$Port = 3002
    )

    if (-not $PSCmdlet.ShouldProcess("localhost:$Port", "Start Express server")) {
        return
    }

    Write-ServerLog "Starting Express server on port $Port..." -Color Blue -ServerName "Express"

    $appPath = Join-Path $PWD "docs/_server/app.js"

    if (-not (Test-Path $appPath)) {
        throw "Express server app not found: $appPath"
    }

    # Use $using: scope modifier to reference outer scope variables in Start-Job
    $job = Start-Job -ScriptBlock {
        Set-Location $using:PWD
        & node $using:appPath
    }

    $script:ServerJobs += $job

    Write-ServerLog "Express server started (Job ID: $($job.Id))" -Color Green -ServerName "Express"
    Write-ServerLog "Progress API available at: http://localhost:$Port" -Color Cyan -ServerName "Express"

    return $job
}

function Wait-ForServerStartup {
    param(
        [string]$Url,
        [int]$TimeoutSeconds = 30,
        [string]$ServerName = "Server"
    )

    Write-ServerLog "Waiting for $ServerName to start..." -Color Yellow -ServerName $ServerName

    $timeout = (Get-Date).AddSeconds($TimeoutSeconds)
    $serverStarted = $false

    while ((Get-Date) -lt $timeout) {
        try {
            $response = Invoke-WebRequest -Uri $Url -UseBasicParsing -TimeoutSec 1 -ErrorAction SilentlyContinue
            if ($response -and $response.StatusCode -eq 200) {
                # For Docsify, also check if the content has loaded (not just showing "Loading documentation...")
                if ($ServerName -eq "Docsify") {
                    if ($response.Content -and $response.Content.Length -gt 5000) {
                        Write-ServerLog "$ServerName is responding with content" -Color Green -ServerName $ServerName
                        $serverStarted = $true
                        break
                    } else {
                        Write-ServerLog "Docsify responding but content still loading..." -Color Yellow -ServerName $ServerName
                    }
                } else {
                    Write-ServerLog "$ServerName is responding" -Color Green -ServerName $ServerName
                    $serverStarted = $true
                    break
                }
            }
        } catch {
            # Server not ready yet, continue waiting
            Write-ServerLog "Waiting for $ServerName to respond..." -Color Yellow -ServerName $ServerName
        }

        Start-Sleep 5
    }

    if (-not $serverStarted) {
        Write-ServerLog "$ServerName startup timeout, but continuing..." -Color Yellow -ServerName $ServerName
    }

    return $serverStarted
}

function Open-BrowserToPage {
    param(
        [string]$Url,
        [string]$ServerName = "Server"
    )

    Write-ServerLog "Opening browser to: $Url" -Color Green -ServerName $ServerName

    # Try multiple browser options
    $browserCommands = @(
        { & "$env:BROWSER" $Url },
        { Start-Process $Url },
        { & "code" "--new-window" $Url }
    )

    $browserOpened = $false
    foreach ($browserCmd in $browserCommands) {
        try {
            & $browserCmd
            $browserOpened = $true
            break
        } catch {
            continue
        }
    }

    if (-not $browserOpened) {
        Write-ServerLog "Could not detect browser command. Please open manually: $Url" -Color Yellow -ServerName $ServerName
    }
}

function Stop-AllServer {
    [CmdletBinding(SupportsShouldProcess)]
    param()

    if (-not $PSCmdlet.ShouldProcess("All servers", "Stop servers")) {
        return
    }

    Write-ServerLog "Shutting down all servers..." -Color Yellow    # Stop all jobs (Express server)
    if ($script:ServerJobs) {
        $script:ServerJobs | ForEach-Object {
            if ($_.State -eq "Running") {
                Stop-Job $_ -ErrorAction SilentlyContinue
            }
            Remove-Job $_ -ErrorAction SilentlyContinue
        }
    }

    # Stop Docsify process
    if ($script:docsifyProcess -and !$script:docsifyProcess.HasExited) {
        try {
            $script:docsifyProcess.Kill()
            Write-ServerLog "Killed Docsify process: $($script:docsifyProcess.Id)" -Color Yellow
        } catch {
            Write-ServerLog "Warning: Could not kill Docsify process: $_" -Color Yellow
        }
    }

    # Stop any remaining processes
    if ($script:ServerProcesses) {
        $script:ServerProcesses | ForEach-Object {
            if (-not $_.HasExited) {
                $_.Kill()
            }
        }
    }

    Write-ServerLog "All servers stopped" -Color Green
    $script:ServerJobs = @()
    $script:ServerProcesses = @()
}

function Register-ShutdownHandler {
    # Register Ctrl+C handler
    try {
        $null = [Console]::CancelKeyPress
        [Console]::CancelKeyPress.Add({
            param($senderObject, $cancelEventArgs)
            $null = $senderObject  # Suppress unused parameter warning
            $cancelEventArgs.Cancel = $true
            Stop-AllServer
            exit 0
        })
    } catch {
        Write-ServerLog "Could not register shutdown handler: $($_.Exception.Message)" -Color Yellow
    }
}

try {
    # Change to workspace root
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptPath
    Set-Location $workspaceRoot

    Write-ServerLog "Starting development servers..." -Color Green

    # Debug: Show environment detection results
    Write-ServerLog "Environment Detection Results:" -Color Cyan
    Write-ServerLog "  Platform: $($script:RuntimeEnvironment.Platform)" -Color White
    Write-ServerLog "  IsWindows: $($script:RuntimeEnvironment.IsWindowsPlatform)" -Color White
    Write-ServerLog "  IsContainer: $($script:RuntimeEnvironment.IsContainer)" -Color White
    Write-ServerLog "  IsDevContainer: $($script:RuntimeEnvironment.IsDevContainer)" -Color White
    Write-ServerLog "  DetectedHost: $($script:RuntimeEnvironment.DetectedHost)" -Color White
    Write-ServerLog "  PowerShell Version: $($PSVersionTable.PSVersion)" -Color White

    # Check and install local dependencies if needed
    if (-not (Test-LocalDependenciesReady)) {
        Install-LocalDependency
    }

    # Check prerequisites
    # Check if index.html exists
    $indexFile = "index.html"
    if (-not (Test-Path $indexFile)) {
        Write-ServerLog "Index file not found: $indexFile" -Color Red
        exit 1
    } else {
        Write-ServerLog "Index file found: $indexFile" -Color Green
    }

    # Check if docsify is available
    if (-not (Test-DocsifyInstalled)) {
        Write-ServerLog "Docsify not found. Please run 'npm install' to install dependencies." -Color Red
        exit 1
    }

    # Register shutdown handler
    Register-ShutdownHandler

    Write-ServerLog "About to start servers..." -Color Green

    # Start both servers
    Write-ServerLog "Starting progress server first..." -Color Blue
    try {
        Start-ExpressServer -Port $ProgressPort
        $healthCheckUrl = "http://$($script:RuntimeEnvironment.DetectedHost):$ProgressPort/health"
        Write-ServerLog "Using health check URL: $healthCheckUrl" -Color Yellow -ServerName "Express"
        Wait-ForServerStartup -Url $healthCheckUrl -ServerName "Express"
    } catch {
        Write-ServerLog "Error starting Express server: $($_.Exception.Message)" -Color Red
        throw
    }

    Write-ServerLog "Starting docsify server..." -Color Blue
    try {
        Start-DocsifyServer -Port $DocsPort
        Wait-ForServerStartup -Url "http://localhost:$DocsPort" -ServerName "Docsify"
    } catch {
        Write-ServerLog "Error starting Docsify server: $($_.Exception.Message)" -Color Red
        throw
    }

    Write-ServerLog "All servers started successfully!" -Color Green

    # Show environment-appropriate URLs
    $progressUrl = "http://$($script:RuntimeEnvironment.DetectedHost):$ProgressPort"
    $docsUrl = "http://$($script:RuntimeEnvironment.DetectedHost):$DocsPort"

    Write-ServerLog "Progress API Health: $progressUrl/health" -Color Cyan
    Write-ServerLog "Documentation: $docsUrl" -Color Cyan
    Write-ServerLog "Training: $docsUrl/#/learning/README" -Color Cyan
    Write-ServerLog "" -Color White

    if ($script:RuntimeEnvironment.IsContainer -or $script:RuntimeEnvironment.IsDevContainer) {
        Write-ServerLog "Container/Remote URLs:" -Color Yellow
        Write-ServerLog "Progress API: http://0.0.0.0:$ProgressPort" -Color Cyan
        Write-ServerLog "Documentation: http://0.0.0.0:$DocsPort" -Color Cyan
    } else {
        Write-ServerLog "Local URLs:" -Color Yellow
        Write-ServerLog "Progress API: $progressUrl" -Color Cyan
        Write-ServerLog "Documentation: $docsUrl" -Color Cyan
    }

    # Auto-open browser to documentation site
    if ($StartPage) {
        $cleanStartPage = $StartPage.Trim('/').TrimStart('/')
        $url = "http://localhost:$DocsPort/#/$cleanStartPage"
    } else {
        $url = "http://localhost:$DocsPort"
    }

    Write-ServerLog "Opening browser to: $url" -Color Green
    Start-Sleep 5  # Give servers more time to fully initialize, especially for JavaScript loading
    Open-BrowserToPage -Url $url -ServerName "Documentation"

    Write-ServerLog "Press Ctrl+C to stop all servers" -Color Yellow

    # Keep the script running and monitor jobs and processes
    try {
        while ($true) {
            Start-Sleep 5

            # Check if any jobs have failed
            $failedJobs = $script:ServerJobs | Where-Object { $_.State -eq "Failed" }
            if ($failedJobs) {
                Write-ServerLog "One or more servers failed!" -Color Red
                $failedJobs | ForEach-Object {
                    Write-ServerLog "Job $($_.Id) failed: $($_.ChildJobs[0].JobStateInfo.Reason)" -Color Red
                }
                break
            }

            # Check if Docsify process has exited
            if ($script:docsifyProcess -and $script:docsifyProcess.HasExited) {
                Write-ServerLog "Docsify process has exited!" -Color Red
                break
            }

            # Check if all jobs completed (shouldn't happen for servers)
            $runningJobs = $script:ServerJobs | Where-Object { $_.State -eq "Running" }
            $docsifyRunning = $script:docsifyProcess -and !$script:docsifyProcess.HasExited

            if ($runningJobs.Count -eq 0 -and -not $docsifyRunning) {
                Write-ServerLog "All servers stopped unexpectedly" -Color Red
                break
            }
        }
    } finally {
        Stop-AllServer
    }

} catch {
    Write-ServerLog "Error: $($_.Exception.Message)" -Color Red
    Stop-AllServer
    exit 1
}
