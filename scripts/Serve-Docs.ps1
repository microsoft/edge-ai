#Requires -Version 7.0

<#
.SYNOPSIS
    Start docsify documentation server.

.DESCRIPTION
    Simple script to serve docsify documentation with optional browser opening and start page.

.PARAMETER Open
    Open browser automatically after server starts.

.PARAMETER StartPage
    Specify starting page/route (e.g., 'praxisworx/').

.EXAMPLE
    .\Serve-Docs.ps1
    Start server on port 8080.

.EXAMPLE
    .\Serve-Docs.ps1 -Open -StartPage "praxisworx/"
    Start server and open browser to PraxisWorx section.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Open,

    [Parameter(Mandatory = $false)]
    [string]$StartPage = ''
)

$ErrorActionPreference = 'Stop'

try {
    # Change to workspace root
    $scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
    $workspaceRoot = Split-Path -Parent $scriptPath
    Set-Location $workspaceRoot

    # Check if index.html exists
    $indexFile = "index.html"
    if (-not (Test-Path $indexFile)) {
        Write-Host "❌ Index file not found: $indexFile" -ForegroundColor Red
        exit 1
    } else {
        Write-Host "✅ Index file found: $indexFile" -ForegroundColor Green
    }

    # Check if docsify is globally installed
    try {
        $null = & docsify --version 2>$null
        if ($LASTEXITCODE -ne 0) { throw }
    } catch {
        Write-Host "📦 Installing docsify-cli globally..." -ForegroundColor Yellow
        & npm install -g docsify-cli
        if ($LASTEXITCODE -ne 0) {
            throw "Failed to install docsify-cli globally"
        }
        Write-Host "✅ docsify-cli installed" -ForegroundColor Green
    }

    Write-Host "🚀 Starting docsify server on port 8080..." -ForegroundColor Green

    # Construct URLs for display
    $baseUrl = "http://localhost:8080"
    if ($StartPage) {
        $cleanStartPage = $StartPage.Trim('/').TrimStart('/')
        $fullUrl = "$baseUrl/#/$cleanStartPage"
        Write-Host "📖 Documentation will be available at: $fullUrl" -ForegroundColor Cyan
    } else {
        Write-Host "📖 Documentation will be available at: $baseUrl" -ForegroundColor Cyan
    }

    # Handle custom start page with browser opening
    if ($Open -and $StartPage) {
        $cleanStartPage = $StartPage.Trim('/').TrimStart('/')
        $url = "$baseUrl/#/$cleanStartPage"

        # Start docsify in background and open browser to specific page
        $docsifyJob = Start-Job -ScriptBlock { & docsify serve . --port 8080 }

        Write-Host "⏳ Waiting for server to start..." -ForegroundColor Yellow
        $waitCount = 0
        $maxWait = 30
        $serverStarted = $false

        while ($waitCount -lt $maxWait) {
            Start-Sleep 5
            $waitCount++

            $response = Invoke-WebRequest -Uri $baseUrl -UseBasicParsing -TimeoutSec 1 -ErrorAction SilentlyContinue
            if ($response -and $response.StatusCode -eq 200) {
                Write-Host "✅ Server is responding" -ForegroundColor Green
                $serverStarted = $true
                break
            }

            if ($waitCount % 5 -eq 0) {
                Write-Host "⏳ Still waiting... ($waitCount/${maxWait}s)" -ForegroundColor Yellow
            }
        }

        if (-not $serverStarted) {
            Write-Host "⚠️  Server seems slow to start, opening browser anyway..." -ForegroundColor Yellow
        }

        # Open browser to specific page
        Write-Host "🌐 Opening browser to: $url" -ForegroundColor Green
        Write-Host "💡 If page doesn't load immediately, wait 1-2 minutes for docsify to process all content" -ForegroundColor Cyan

        # Try multiple browser options
        $browserCommands = @(
            { & "$env:BROWSER" $url },
            { Start-Process $url },
            { & "code" "--new-window" $url }
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
            Write-Host "⚠️  Could not detect browser command. Please open manually: $url" -ForegroundColor Yellow
        }

        Write-Host "Press Ctrl+C to stop server" -ForegroundColor Yellow

        # Wait for user to stop
        try {
            while ($true) {
                Start-Sleep 1
                if ($docsifyJob.State -ne "Running") {
                    Write-Host "❌ Docsify server stopped unexpectedly" -ForegroundColor Red
                    break
                }
            }
        }
        finally {
            Get-Job | Stop-Job
            Get-Job | Remove-Job
        }

    } elseif ($Open) {
        # Standard open
        & docsify serve . --port 8080 --open
    } else {
        # No browser opening
        & docsify serve . --port 8080
    }
} catch {
    Write-Host "❌ Error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
