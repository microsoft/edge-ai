#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Executes OSSF Scorecard security assessment for supply chain monitoring.

.DESCRIPTION
    Cross-platform PowerShell script that runs OpenSSF Scorecard analysis to assess
    the security posture of the repository's supply chain dependencies and practices.
    Designed to work consistently across GitHub Actions and Azure DevOps pipelines.

.PARAMETER Repository
    The repository to analyze in format 'owner/repo'. Defaults to current repository.

.PARAMETER Token
    GitHub token for API access. Required for accessing private repositories and
    avoiding rate limits. Can be provided via parameter or GITHUB_TOKEN environment variable.

.PARAMETER Format
    Output format for scorecard results. Options: json, sarif, csv, markdown, table.
    Default is 'json' for programmatic processing.

.PARAMETER OutputPath
    Path where scorecard results should be saved. Defaults to 'scorecard-results.json'
    in the current directory.

.PARAMETER Branch
    Branch to analyze. Defaults to the default branch of the repository.

.PARAMETER Checks
    Comma-separated list of specific checks to run. If not specified, runs all checks.
    Available checks: Binary-Artifacts, Branch-Protection, CI-Tests, CII-Best-Practices,
    Code-Review, Contributors, Dangerous-Workflow, Dependency-Update-Tool, Fuzzing,
    License, Maintained, Packaging, Pinned-Dependencies, SAST, Security-Policy,
    Signed-Releases, Token-Permissions, Vulnerabilities, Webhooks.

.PARAMETER Verbose
    Enable verbose output for detailed scoring information.

.EXAMPLE
    ./Invoke-OSSFScorecard.ps1
    Run OSSF Scorecard with default settings for current repository.

.EXAMPLE
    ./Invoke-OSSFScorecard.ps1 -Repository "microsoft/edge-ai" -Token $env:GITHUB_TOKEN -Format "sarif"
    Run OSSF Scorecard for specific repository with SARIF output format.

.EXAMPLE
    ./Invoke-OSSFScorecard.ps1 -Checks "Pinned-Dependencies,Token-Permissions" -Verbose
    Run only specific security checks with verbose output.

.NOTES
    Requires:
    - PowerShell 7.0 or later for cross-platform compatibility
    - Internet connectivity for downloading OSSF Scorecard tool
    - GitHub token for repository access (public or private)

    Compatible with:
    - Windows PowerShell 5.1+ (limited cross-platform features)
    - PowerShell 7.x on Windows, Linux, macOS
    - GitHub Actions runners (ubuntu-latest, windows-latest, macos-latest)
    - Azure DevOps agents (Microsoft-hosted and self-hosted)

.LINK
    https://github.com/ossf/scorecard
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$Repository = "",

    [Parameter(Mandatory = $false)]
    [string]$Token = "",

    [Parameter(Mandatory = $false)]
    [string]$Format = 'json',

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = 'scorecard-results.json',

    [Parameter(Mandatory = $false)]
    [string]$Branch = "",

    [Parameter(Mandatory = $false)]
    [string]$Checks = "",

    [Parameter(Mandatory = $false)]
    [switch]$Verbose
)

# Set error action preference for consistent error handling
$ErrorActionPreference = 'Stop'

# Define OSSF Scorecard version for consistent dependency pinning
$ScorecardVersion = "v4.13.1"
$ScorecardUrl = "https://github.com/ossf/scorecard/releases/download/$ScorecardVersion"

function Write-SecurityLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet('Info', 'Warning', 'Error', 'Success')]
        [string]$Level = 'Info'
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Output "[$timestamp] [$Level] $Message"
}

function Get-OSSFScorecard {
    <#
    .SYNOPSIS
    Downloads and installs OSSF Scorecard tool with checksum verification.
    #>

    Write-Output "Downloading OSSF Scorecard $ScorecardVersion..."

    # Determine platform-specific binary
    $os = if ($IsWindows -or $env:OS -eq 'Windows_NT') { 'windows' }
    elseif ($IsLinux) { 'linux' }
    elseif ($IsMacOS) { 'darwin' }
    else { 'linux' }  # Default to linux for unknown platforms

    $arch = if ([System.Environment]::Is64BitOperatingSystem) { 'amd64' } else { '386' }
    $extension = if ($os -eq 'windows') { '.exe' } else { '' }

    $binaryName = "scorecard-$os-$arch$extension"
    $downloadUrl = "$ScorecardUrl/$binaryName"
    $checksumUrl = "$downloadUrl.sha256"

    # Create temporary directory for downloads
    $tempDir = Join-Path $env:TEMP "ossf-scorecard-$(Get-Random)"
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null

    try {
        # Download binary and checksum
        $binaryPath = Join-Path $tempDir $binaryName
        $checksumPath = Join-Path $tempDir "$binaryName.sha256"

        Write-Output "Downloading from: $downloadUrl" -Level Info
        Invoke-WebRequest -Uri $downloadUrl -OutFile $binaryPath -UseBasicParsing

        Write-Output "Downloading checksum from: $checksumUrl" -Level Info
        Invoke-WebRequest -Uri $checksumUrl -OutFile $checksumPath -UseBasicParsing

        # Verify checksum
        $expectedChecksum = (Get-Content $checksumPath).Split(' ')[0]
        $actualChecksum = (Get-FileHash -Path $binaryPath -Algorithm SHA256).Hash.ToLower()

        if ($expectedChecksum -ne $actualChecksum) {
            throw "Checksum verification failed! Expected: $expectedChecksum, Got: $actualChecksum"
        }

        Write-Output "Checksum verification passed: $expectedChecksum" -Level Success

        # Make executable on Unix-like systems
        if ($os -ne 'windows') {
            chmod +x $binaryPath
        }

        # Copy to a location in PATH or return path for direct execution
        $targetPath = Join-Path $PWD "scorecard$extension"
        Copy-Item -Path $binaryPath -Destination $targetPath -Force

        # Make executable on Unix-like systems
        if ($os -ne 'windows') {
            chmod +x $targetPath
        }

        Write-Output "OSSF Scorecard installed to: $targetPath" -Level Success
        return $targetPath

    }
    finally {
        # Cleanup temporary directory
        if (Test-Path $tempDir) {
            Remove-Item -Path $tempDir -Recurse -Force
        }
    }
}

function Initialize-GitHubToken {
    <#
    .SYNOPSIS
    Initializes GitHub token from parameter or environment variables.
    #>

    if ([string]::IsNullOrWhiteSpace($Token)) {
        # Try common environment variables
        $Token = $env:GITHUB_TOKEN
        if ([string]::IsNullOrWhiteSpace($Token)) {
            $Token = $env:GH_TOKEN
        }
        if ([string]::IsNullOrWhiteSpace($Token)) {
            Write-Output "No GitHub token provided. Analysis may be limited for private repositories." -Level Warning
            return $null
        }
    }

    Write-Output "GitHub token configured for API access" -Level Success
    return $Token
}

function Get-RepositoryInfo {
    <#
    .SYNOPSIS
    Determines repository information from current context or parameters.
    #>

    if ([string]::IsNullOrWhiteSpace($Repository)) {
        # Try to detect from git remote
        try {
            $gitRemote = git remote get-url origin 2>$null
            if ($gitRemote) {
                if ($gitRemote -match 'github\.com[:/]([^/]+/[^/.]+)') {
                    $Repository = $matches[1]
                    Write-Output "Detected repository from git remote: $Repository" -Level Info
                }
                else {
                    Write-Output "Could not parse GitHub repository from git remote: $gitRemote" -Level Warning
                }
            }
        }
        catch {
            Write-Output "Could not detect repository from git remote" -Level Warning
        }

        # Fallback to environment variables (common in CI/CD)
        if ([string]::IsNullOrWhiteSpace($Repository)) {
            $Repository = $env:GITHUB_REPOSITORY
        }

        if ([string]::IsNullOrWhiteSpace($Repository)) {
            throw "Repository not specified and could not be auto-detected. Please provide -Repository parameter."
        }
    }

    Write-Output "Analyzing repository: $Repository" -Level Info
    return $Repository
}

function Invoke-ScorecardAnalysis {
    <#
    .SYNOPSIS
    Executes OSSF Scorecard analysis with specified parameters.
    #>
    param(
        [string]$ScorecardPath,
        [string]$RepoToAnalyze,
        [string]$GitHubToken
    )

    # Build scorecard command arguments
    $commandArgs = @('--repo', $RepoToAnalyze, '--format', $Format)

    # Add optional parameters
    if (![string]::IsNullOrWhiteSpace($Branch)) {
        $commandArgs += @('--commit', $Branch)
    }

    if (![string]::IsNullOrWhiteSpace($Checks)) {
        $commandArgs += @('--checks', $Checks)
    }

    if ($Verbose) {
        $commandArgs += '--verbosity', 'debug'
    }

    # Set GitHub token environment variable for scorecard
    if (![string]::IsNullOrWhiteSpace($GitHubToken)) {
        $env:GITHUB_AUTH_TOKEN = $GitHubToken
    }

    Write-SecurityLog "Executing OSSF Scorecard analysis..." -Level Info
    Write-SecurityLog "Command: $ScorecardPath $($commandArgs -join ' ')" -Level Info

    try {
        # Execute scorecard and capture output
        $result = & $ScorecardPath $commandArgs

        if ($LASTEXITCODE -ne 0) {
            throw "OSSF Scorecard execution failed with exit code: $LASTEXITCODE"
        }

        # Save results to file
        $result | Out-File -FilePath $OutputPath -Encoding UTF8
        Write-Output "Scorecard results saved to: $OutputPath" -Level Success

        # Display summary for immediate feedback
        if ($Format -eq 'json') {
            try {
                $jsonResult = $result | ConvertFrom-Json
                Write-Output "Repository Score: $($jsonResult.score)/10" -Level Info
                Write-Output "Scorecard Version: $($jsonResult.scorecard.version)" -Level Info
                Write-Output "Analysis Date: $($jsonResult.date)" -Level Info

                # Show check results summary
                Write-Output "Security Check Results:" -Level Info
                foreach ($check in $jsonResult.checks) {
                    $status = if ($check.score -eq 10) { "✓" } elseif ($check.score -ge 7) { "⚠" } else { "✗" }
                    Write-Output "  $status $($check.name): $($check.score)/10" -Level Info
                }
            }
            catch {
                Write-Output "Could not parse JSON results for summary display" -Level Warning
            }
        }

        return $result

    }
    catch {
        Write-Output "Error during OSSF Scorecard execution: $($_.Exception.Message)" -Level Error
        throw
    }
    finally {
        # Clean up environment variables
        if ($env:GITHUB_AUTH_TOKEN) {
            Remove-Item -Path 'env:GITHUB_AUTH_TOKEN' -ErrorAction SilentlyContinue
        }
    }
}

function Export-ScorecardArtifact {
    <#
    .SYNOPSIS
    Exports scorecard results as CI/CD artifacts for both GitHub Actions and Azure DevOps.
    #>
    param(
        [string]$ResultsPath
    )

    if (!(Test-Path $ResultsPath)) {
        Write-Output "Results file not found: $ResultsPath" -Level Warning
        return
    }

    Write-Output "Preparing scorecard artifacts for CI/CD systems..." -Level Info

    # GitHub Actions artifact export
    if ($env:GITHUB_ACTIONS -eq 'true') {
        Write-Output "Detected GitHub Actions environment - setting up artifacts" -Level Info

        # Set output for GitHub Actions
        if ($env:GITHUB_OUTPUT) {
            "scorecard-results=$ResultsPath" | Out-File -FilePath $env:GITHUB_OUTPUT -Append -Encoding UTF8
        }

        # Create artifact directory structure expected by actions/upload-artifact@v4
        $artifactDir = Join-Path $PWD "scorecard-artifacts"
        New-Item -ItemType Directory -Path $artifactDir -Force | Out-Null
        Copy-Item -Path $ResultsPath -Destination $artifactDir -Force

        Write-Output "##[group]Scorecard Results Summary" -Level Info
        Get-Content $ResultsPath | Write-Output
        Write-Output "##[endgroup]" -Level Info
    }

    # Azure DevOps artifact export
    if ($env:TF_BUILD -eq 'True' -or $env:AZURE_PIPELINES -eq 'True') {
        Write-Output "Detected Azure DevOps environment - setting up artifacts" -Level Info

        # Set Azure DevOps variables
        Write-Output "##vso[task.setvariable variable=scorecardResults;isOutput=true]$ResultsPath"

        # Upload artifact
        Write-Output "##vso[artifact.upload containerfolder=scorecard-results;artifactname=scorecard-results]$ResultsPath"

        # Display results in build log
        Write-Output "##[section]OSSF Scorecard Results"
        Get-Content $ResultsPath | Write-Output
    }

    Write-Output "Scorecard artifacts prepared for CI/CD consumption" -Level Success
}

# Main execution
try {
    Write-Output "Starting OSSF Scorecard security analysis..." -Level Info
    Write-Output "PowerShell Version: $($PSVersionTable.PSVersion)" -Level Info
    Write-Output "Platform: $($PSVersionTable.Platform)" -Level Info

    # Initialize components
    $githubToken = Initialize-GitHubToken
    $repository = Get-RepositoryInfo

    # Download and install OSSF Scorecard
    $scorecardPath = Get-OSSFScorecard

    # Execute analysis
    Invoke-ScorecardAnalysis -ScorecardPath $scorecardPath -RepoToAnalyze $repository -GitHubToken $Token -Format $Format -Branch $Branch -Checks $Checks -Verbose:$Verbose

    # Export artifacts for CI/CD
    Export-ScorecardArtifact -ResultsPath $OutputPath

    Write-Output "OSSF Scorecard analysis completed successfully!" -Level Success

}
catch {
    Write-Output "OSSF Scorecard analysis failed: $($_.Exception.Message)" -Level Error
    Write-Output "Stack trace: $($_.ScriptStackTrace)" -Level Error
    exit 1
}
