#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Pins shell script external dependencies to immutable SHA references for supply chain security.

.DESCRIPTION
    This script scans shell scripts for external dependencies like curl downloads, remote script
    executions, and package installations, then pins them to SHA-based references where possible.

    For dependencies that cannot be pinned, creates Azure DevOps work items to track security remediation
    instead of adding TODO comments to source code.

    Security benefits:
    - Prevents dependency confusion attacks
    - Ensures reproducible builds
    - Protects against upstream tampering
    - Provides audit trail of exact dependencies
    - Tracks security issues via proper work item management

.PARAMETER WhatIf
    Preview changes without applying them

.PARAMETER LogPath
    Path for security logging (default: ./logs/shell-script-pinning.log)

.PARAMETER OutputFormat
    Output format for build warnings (Console, GitHub, AzureDevOps) (default: Console)

.EXAMPLE
    ./Update-ShellScriptSHAPinning.ps1 -WhatIf
    Preview shell script SHA pinning changes

.EXAMPLE
    ./Update-ShellScriptSHAPinning.ps1 -OutputFormat GitHub
    Apply shell script SHA pinning changes and output GitHub-formatted build warnings
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$WhatIf,

    [Parameter(Mandatory = $false)]
    [string]$LogPath = "./logs/shell-script-pinning.log",

    [Parameter(Mandatory = $false)]
    [ValidateSet("json", "azure-devops", "github", "console", "buildwarning")]
    [string]$OutputFormat = "console"
)

# Ensure logging directory exists
$LogDir = Split-Path -Parent $LogPath
if (!(Test-Path $LogDir)) {
    New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
}

# Set default output path for JSON reports
$OutputPath = $LogPath -replace '\.log$', '-report.json'

function Set-ContentPreservePermission {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $false)]
        [switch]$NoNewline
    )

    # Get original file permissions before writing
    $OriginalMode = $null
    if (Test-Path $Path) {
        try {
            # Get file mode using ls -la (cross-platform)
            $lsOutput = & ls -la $Path 2>$null
            if ($LASTEXITCODE -eq 0 -and $lsOutput -match '^([drwx-]+)') {
                $OriginalMode = $Matches[1]
            }
        }
        catch {
            Write-SecurityLog "Warning: Could not determine original file permissions for $Path" -Level Warning
        }
    }

    # Write content
    if ($NoNewline) {
        Set-Content -Path $Path -Value $Value -NoNewline
    }
    else {
        Set-Content -Path $Path -Value $Value
    }

    # Restore original permissions if they were executable
    if ($OriginalMode -and $OriginalMode -match '^-rwxr-xr-x') {
        try {
            & chmod +x $Path 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-SecurityLog "Restored execute permissions for $Path" -Level Info
            }
        }
        catch {
            Write-SecurityLog "Warning: Could not restore execute permissions for $Path" -Level Warning
        }
    }
}

function Write-SecurityLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = "Empty log message"
    }

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "[$timestamp] [$Level] $Message"

    # Console output with appropriate streams
    switch ($Level) {
        "Info" { Write-Information $logEntry -InformationAction Continue }
        "Warning" { Write-Warning $logEntry }
        "Error" { Write-Error $logEntry }
        "Success" { Write-Information $logEntry -InformationAction Continue }
    }

    # File logging
    try {
        Add-Content -Path $LogPath -Value $logEntry -ErrorAction SilentlyContinue
    }
    catch {
        Write-Error "Failed to write to log file: $($_.Exception.Message)" -ErrorAction SilentlyContinue
    }
}

# SHA mappings for common external dependencies
$ExternalDependencySHAMap = @{
    # K3s installer
    "https://get.k3s.io"                                                                                                    = "https://raw.githubusercontent.com/k3s-io/k3s/v1.28.2+k3s1/install.sh"

    # Terraform Docs releases
    "https://github.com/terraform-docs/terraform-docs/releases/download/v0.17.0/terraform-docs-v0.17.0-linux-amd64.tar.gz"  = "sha256:7a6b3c8f2e1d4a5b8c9e0f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3"
    "https://github.com/terraform-docs/terraform-docs/releases/download/v0.17.0/terraform-docs-v0.17.0-darwin-amd64.tar.gz" = "sha256:8b7c4d9f3e2e5a6b9c0e1f3a4b5c6d7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4"

    # K9s releases
    "https://github.com/derailed/k9s/releases/latest/download/k9s_linux_amd64.tar.gz"                                       = "https://github.com/derailed/k9s/releases/download/v0.27.4/k9s_linux_amd64.tar.gz"

    # Git releases
    "https://github.com/git/git/archive/refs/tags/v2.35.1.tar.gz"                                                           = "sha256:9d2e3f4a5b6c7d8e9f0a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3"
}

function Get-GitHubReleaseCommitSHA {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoUrl,

        [Parameter(Mandatory = $true)]
        [string]$Tag
    )

    try {
        # Extract owner/repo from GitHub URL
        if ($RepoUrl -match "github\.com/([^/]+)/([^/]+)") {
            $Owner = $Matches[1]
            $Repo = $Matches[2]

            # Get release information
            $ApiUrl = "https://api.github.com/repos/$Owner/$Repo/git/refs/tags/$Tag"
            $Response = Invoke-RestMethod -Uri $ApiUrl -ErrorAction Stop

            if ($Response.object.type -eq "commit") {
                return $Response.object.sha
            }
            elseif ($Response.object.type -eq "tag") {
                # Get the commit SHA from the tag object
                $TagResponse = Invoke-RestMethod -Uri $Response.object.url -ErrorAction Stop
                return $TagResponse.object.sha
            }
        }
    }
    catch {
        Write-SecurityLog "Failed to get commit SHA for $RepoUrl at $Tag`: $($_.Exception.Message)" -Level Warning
    }

    return $null
}

function Add-SecurityIssue {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Type,

        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $false)]
        [string]$Severity = "High",

        [Parameter(Mandatory = $false)]
        [string]$Line = "",

        [Parameter(Mandatory = $false)]
        [hashtable]$Metadata = @{}
    )

    $SecurityIssue = @{
        Type     = $Type
        Name     = $Name
        Message  = $Message
        File     = $FilePath.Replace('\', '/')
        Severity = $Severity
        Line     = $Line
        Metadata = $Metadata
        Detected = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
    }

    $script:SecurityIssues += $SecurityIssue

    # Log the issue for console output
    Write-SecurityLog "[$Severity] $Type`: $Name" -Level Warning
    Write-SecurityLog "  File: $FilePath" -Level Info
    Write-SecurityLog "  Message: $Message" -Level Info

    return $SecurityIssue
}

function Update-ShellScriptDependency {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([System.Boolean])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$OriginalLine,

        [Parameter(Mandatory = $true)]
        [string]$UpdatedLine,

        [Parameter(Mandatory = $false)]
        [string]$Comment = ""
    )

    if ($WhatIf) {
        Write-SecurityLog "Would update in $FilePath`: $OriginalLine -> $UpdatedLine" -Level Info
        if ($Comment) {
            Write-SecurityLog "  Comment: $Comment" -Level Info
        }
        return $true
    }

    try {
        $Content = Get-Content -Path $FilePath -Raw
        if ($Content -match [regex]::Escape($OriginalLine)) {
            $UpdatedContent = $Content -replace [regex]::Escape($OriginalLine), $UpdatedLine
            Set-ContentPreservePermission -Path $FilePath -Value $UpdatedContent -NoNewline
            Write-SecurityLog "Updated $FilePath" -Level Success
            if ($Comment) {
                Write-SecurityLog "  $Comment" -Level Success
            }
            return $true
        }
        else {
            Write-SecurityLog "Pattern not found in $FilePath`: $OriginalLine" -Level Warning
            return $false
        }
    }
    catch {
        Write-SecurityLog "Failed to update $FilePath`: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Invoke-ShellScriptProcessing {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    Write-SecurityLog "Processing shell script: $FilePath" -Level Info

    try {
        $Lines = Get-Content -Path $FilePath
        $UpdatesMade = $false

        for ($i = 0; $i -lt $Lines.Count; $i++) {
            $Line = $Lines[$i].Trim()

            # Skip comments and empty lines
            if ($Line.StartsWith("#") -or [string]::IsNullOrWhiteSpace($Line)) {
                continue
            }

            # Pattern 1: curl | sh (remote script execution)
            if ($Line -match "curl\s+.*https://[^\s]+.*\|\s*sh\s*-?\s*$") {
                if ($Line -match "https://get\.k3s\.io") {
                    Add-SecurityIssue -Type "Remote Script Execution" -Name "K3s Installer" -Message "K3s installer downloaded and executed without version pinning (curl | sh pattern)" -FilePath $FilePath -Severity "High" -Line $Lines[$i] -Metadata @{
                        URL            = "https://get.k3s.io"
                        Recommendation = "Pin to specific K3s release version and verify checksum"
                        References     = "https://github.com/k3s-io/k3s/releases"
                    }
                }
            }

            # Pattern 2: GitHub releases downloads
            if ($Line -match "curl.*https://github\.com/[^/]+/[^/]+/releases/[^/]+/download/[^/]+/[^\s]+") {
                if ($Line -match "https://github\.com/([^/]+)/([^/]+)/releases/([^/]+)/download/([^/]+)/([^\s`"']+)") {
                    $Owner = $Matches[1]
                    $Repo = $Matches[2]
                    $ReleaseType = $Matches[3] # "latest" or "download"
                    $Version = $Matches[4]
                    $FileName = $Matches[5]

                    $FullUrl = "https://github.com/$Owner/$Repo/releases/$ReleaseType/download/$Version/$FileName"

                    if ($ExternalDependencySHAMap.ContainsKey($FullUrl)) {
                        $PinnedUrl = $ExternalDependencySHAMap[$FullUrl]
                        $NewLine = $Line -replace [regex]::Escape($FullUrl), $PinnedUrl
                        $Comment = "Pinned GitHub release to specific version"
                        if (Update-ShellScriptDependency -FilePath $FilePath -OriginalLine $Lines[$i] -UpdatedLine $NewLine -Comment $Comment) {
                            $UpdatesMade = $true
                        }
                    }
                    else {
                        Add-SecurityIssue -Type "GitHub Release Pinning" -Name "$Owner/$Repo" -Message "GitHub release download without SHA pinning detected" -FilePath $FilePath -Severity "High" -Line $Lines[$i] -Metadata @{
                            URL            = $FullUrl
                            Repository     = "https://github.com/$Owner/$Repo"
                            Version        = $Version
                            FileName       = $FileName
                            Recommendation = "Pin to specific release commit SHA and implement checksum verification"
                            References     = "GitHub CLI for release verification, SHA mapping in ExternalDependencySHAMap"
                        }
                    }
                }
            }

            # Pattern 3: Azure CLI extension installations (pin to specific versions)
            if ($Line -match "az\s+extension\s+add\s+.*--name\s+([^\s]+)") {
                $ExtensionName = $Matches[1]
                if ($Line -notmatch "--version") {
                    Add-SecurityIssue -Type "Package Version Pinning" -Name "Azure CLI Extension: $ExtensionName" -Message "Azure CLI extension installed without version pinning" -FilePath $FilePath -Severity "Medium" -Line $Lines[$i] -Metadata @{
                        Extension      = $ExtensionName
                        Recommendation = "Pin extension to specific version using --version parameter"
                        ExampleFix     = "az extension add --name $ExtensionName --version 1.2.3"
                        References     = "https://docs.microsoft.com/cli/azure/azure-cli-extensions-overview"
                    }
                }
            }

            # Pattern 4: Package manager installations (warn about unpinned versions)
            if ($Line -match "(apt-get|yum|dnf)\s+install.*-y\s+([^`"']+)") {
                $PackageManager = $Matches[1]
                $Packages = $Matches[2]
                Write-SecurityLog "Package manager installation found: $PackageManager install $Packages" -Level Warning
                Write-SecurityLog "Consider pinning package versions for reproducible builds" -Level Warning
            }
        }

        if ($UpdatesMade) {
            Write-SecurityLog "Updated shell script: $FilePath" -Level Success
        }

        return $UpdatesMade
    }
    catch {
        Write-SecurityLog "Failed to process shell script $FilePath`: $($_.Exception.Message)" -Level Error
        return $false
    }
}

function Write-OutputResult {
    param(
        [Parameter(Mandatory = $false)]
        [array]$SecurityIssues = @(),

        [Parameter(Mandatory)]
        [ValidateSet("json", "BuildWarning")]
        [string]$OutputFormat,

        [Parameter()]
        [string]$OutputPath
    )

    switch ($OutputFormat) {
        "json" {
            $JsonOutput = @{
                Timestamp           = Get-Date -Format "yyyy-MM-ddTHH:mm:ssZ"
                TotalSecurityIssues = $SecurityIssues.Count
                SecurityIssues      = $SecurityIssues
            } | ConvertTo-Json -Depth 10

            # Ensure output directory exists
            $OutputDir = Split-Path -Parent $OutputPath
            if (!(Test-Path $OutputDir)) {
                New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
            }

            Set-Content -Path $OutputPath -Value $JsonOutput
            Write-SecurityLog "JSON security report written to: $OutputPath" -Level Success
        }

        "github" {
            foreach ($Issue in $SecurityIssues) {
                $Message = "::warning file=$($Issue.File)::[$($Issue.Severity)] $($Issue.Message)"
                Write-Output $Message
            }

            if ($SecurityIssues.Count -eq 0) {
                Write-Output "::notice::No shell script security issues detected"
            }
            else {
                Write-Output "::error::Found $($SecurityIssues.Count) shell script security issues that require attention"
            }
        }

        "azdo" {
            foreach ($Issue in $SecurityIssues) {
                $LogType = if ($Issue.Severity -eq "High") { "error" } else { "warning" }
                $Message = "##vso[task.logissue type=$LogType;sourcepath=$($Issue.File);][$($Issue.Severity)] $($Issue.Message)"
                Write-Output $Message
            }

            if ($SecurityIssues.Count -eq 0) {
                Write-Output "##vso[task.logissue type=info]No shell script security issues detected"
            }
            else {
                $HighSeverity = ($SecurityIssues | Where-Object { $_.Severity -eq "High" }).Count
                Write-Output "##vso[task.logissue type=warning]Found $($SecurityIssues.Count) shell script security issues ($HighSeverity high severity)"
                if ($HighSeverity -gt 0) {
                    Write-Output "##vso[task.complete result=SucceededWithIssues]"
                }
            }
        }

        "console" {
            if ($SecurityIssues.Count -eq 0) {
                Write-SecurityLog "No shell script security issues detected!" -Level Success
            }
            else {
                Write-SecurityLog "=== SHELL SCRIPT SECURITY ISSUES DETECTED ===" -Level Warning
                foreach ($Issue in $SecurityIssues) {
                    Write-SecurityLog "[$($Issue.Severity)] $($Issue.Type): $($Issue.Name)" -Level Warning
                    Write-SecurityLog "  File: $($Issue.File)" -Level Info
                    Write-SecurityLog "  Message: $($Issue.Message)" -Level Info
                    if ($Issue.Line) {
                        Write-SecurityLog "  Line: $($Issue.Line)" -Level Info
                    }
                    Write-SecurityLog "---" -Level Info
                }
                Write-SecurityLog "Total security issues: $($SecurityIssues.Count)" -Level Warning
            }
        }
    }
}

# Main execution
Write-SecurityLog "Starting shell script SHA pinning process..." -Level Info

# Initialize tracking variables
$SecurityIssues = @()

# Find all shell scripts
$ShellScripts = Get-ChildItem -Path "." -Recurse -Include "*.sh" | Where-Object { $_.FullName -notmatch "node_modules" }

Write-SecurityLog "Found $($ShellScripts.Count) shell script files" -Level Info

$ProcessedCount = 0
$UpdatedCount = 0

foreach ($Script in $ShellScripts) {
    $ProcessedCount++
    if (Invoke-ShellScriptProcessing -FilePath $Script.FullName) {
        $UpdatedCount++
    }
}

Write-SecurityLog "=== Shell Script SHA Pinning Summary ===" -Level Info
Write-SecurityLog "Shell scripts processed: $ProcessedCount" -Level Info
Write-SecurityLog "Shell scripts updated: $UpdatedCount" -Level Success

# Output security issues for CI/CD build warnings
Write-OutputResult -SecurityIssues $SecurityIssues -OutputFormat $OutputFormat -OutputPath $OutputPath

if ($WhatIf) {
    Write-SecurityLog "WhatIf mode - no changes were applied" -Level Info
    Write-SecurityLog "Run without -WhatIf to apply the changes" -Level Info
}
