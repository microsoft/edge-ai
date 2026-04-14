#Requires -Version 7.0

<#
.SYNOPSIS
    Start development server for documentation.

.DESCRIPTION
    Development server script that starts:
    - Docsify documentation server (port 8080)

.PARAMETER StartPage
    Specify starting page/route (e.g., 'getting-started/').

.PARAMETER DocsPort
    Port for the documentation server (default: 8080).

.EXAMPLE
    .\Serve-Docs.ps1
    Start the documentation server.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$StartPage = '',

    [Parameter(Mandatory = $false)]
    [int]$DocsPort = 8080
)

$ErrorActionPreference = 'Stop'

# Configuration
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
    # Check if Docsify dependency is installed locally
    $nodeModules = Join-Path $PWD "node_modules"
    $docsifyPath = Join-Path $nodeModules "docsify-cli"

    $docsifyExists = Test-Path $docsifyPath

    Write-ServerLog "Checking dependencies: Docsify=$docsifyExists" -Color Yellow

    return $docsifyExists
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

    if (-not $PSCmdlet.ShouldProcess("Server", "Stop server")) {
        return
    }

    Write-ServerLog "Shutting down server..." -Color Yellow

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

    Write-ServerLog "Server stopped" -Color Green
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

    Write-ServerLog "Starting development server..." -Color Green

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

    Write-ServerLog "Starting docsify server..." -Color Blue
    try {
        Start-DocsifyServer -Port $DocsPort
        Wait-ForServerStartup -Url "http://localhost:$DocsPort" -ServerName "Docsify"
    } catch {
        Write-ServerLog "Error starting Docsify server: $($_.Exception.Message)" -Color Red
        throw
    }

    Write-ServerLog "Server started successfully!" -Color Green

    # Show environment-appropriate URLs
    $docsUrl = "http://$($script:RuntimeEnvironment.DetectedHost):$DocsPort"

    Write-ServerLog "Documentation: $docsUrl" -Color Cyan
    Write-ServerLog "" -Color White

    if ($script:RuntimeEnvironment.IsContainer -or $script:RuntimeEnvironment.IsDevContainer) {
        Write-ServerLog "Container/Remote URLs:" -Color Yellow
        Write-ServerLog "Documentation: http://0.0.0.0:$DocsPort" -Color Cyan
    } else {
        Write-ServerLog "Local URLs:" -Color Yellow
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

    Write-ServerLog "Press Ctrl+C to stop the server" -Color Yellow

    # Keep the script running and monitor jobs and processes
    try {
        while ($true) {
            Start-Sleep 5

            # Check if Docsify process has exited
            if ($script:docsifyProcess -and $script:docsifyProcess.HasExited) {
                Write-ServerLog "Docsify process has exited!" -Color Red
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
