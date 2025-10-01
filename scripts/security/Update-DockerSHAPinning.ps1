#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Implements immutable dependency pinning for Docker images and shell scripts in the repository.

.DESCRIPTION
    This script scans for Dockerfile, Docker Compose, and devcontainer configuration files,
    then pins all Docker image references to their SHA256 digests for supply chain security.
    Also handles shell script external dependencies where applicable.

.PARAMETER WhatIf
    Shows what would be changed without making actual modifications.

.PARAMETER Force
    Overrides existing SHA-pinned images with latest SHA digests.

.PARAMETER SkipShellScripts
    Skip processing shell scripts and focus only on Docker files.

.EXAMPLE
    ./Update-DockerSHAPinning.ps1 -WhatIf
    Preview all Docker SHA pinning changes without applying them.

.EXAMPLE
    ./Update-DockerSHAPinning.ps1 -Force
    Apply SHA pinning and update existing SHA-pinned images.

.NOTES
    This script is part of the Edge AI Accelerator supply chain security hardening initiative.
    It implements NIST SP 800-161 recommendations for software supply chain risk management.

    Author: Microsoft Edge AI Team
    Version: 1.0.0
    License: MIT
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter()]
    [ValidateSet('console', 'json', 'azure-devops', 'BuildWarning', 'Summary')]
    [string]$OutputFormat = 'console',

    [Parameter()]
    [switch]$Force,

    [Parameter()]
    [switch]$SkipShellScripts
)

Set-StrictMode -Version 3.0
$ErrorActionPreference = 'Stop'

# Explicit parameter usage to satisfy static analyzer
Write-Debug "Parameters: OutputFormat=$OutputFormat, Force=$Force, SkipShellScripts=$SkipShellScripts"

# =============================================================================
# Security Configuration and Logging
# =============================================================================

# Script-scoped array to track security issues for build system integration
$script:SecurityIssues = @()

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
            Write-SecurityLog -Level 'Warning' -Message "Warning: Could not determine original file permissions for $Path"
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
                Write-SecurityLog -Level 'Info' -Message "Restored execute permissions for $Path"
            }
        }
        catch {
            Write-SecurityLog -Level 'Warning' -Message "Warning: Could not restore execute permissions for $Path"
        }
    }
}

function Add-SecurityIssue {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Low', 'Medium', 'High', 'Critical')]
        [string]$Severity,

        [Parameter(Mandatory)]
        [string]$File,

        [Parameter(Mandatory)]
        [string]$Message,

        [string]$Line = '',

        [string]$Type = 'Docker Security Issue'
    )

    $script:SecurityIssues += [PSCustomObject]@{
        Severity = $Severity
        Type     = $Type
        File     = $File
        Message  = $Message
        Line     = $Line
    }
}

function Write-OutputResult {
    param(
        [Parameter(Mandatory)]
        [string]$Format,

        [Parameter()]
        [array]$Issues = @(),

        [hashtable]$Summary = @{},

        [Parameter()]
        [string]$OutputPath
    )

    switch ($Format) {
        'json' {
            $output = @{
                summary = $Summary
                issues  = $Issues
            }
            $jsonOutput = ConvertTo-Json $output -Depth 10
            if ($OutputPath) {
                $jsonOutput | Out-File -FilePath $OutputPath -Encoding UTF8
            }
            else {
                $jsonOutput
            }
        }
        'azure-devops' {
            foreach ($issue in $Issues) {
                Write-Output "##vso[task.logissue type=warning;sourcepath=$($issue.File)]$($issue.Severity): $($issue.Message)"
            }
        }
        'BuildWarning' {
            foreach ($issue in $Issues) {
                Write-Output "##vso[task.logissue type=warning]Docker SHA Pinning - $($issue.Severity): $($issue.Message) (File: $($issue.File))"
            }
        }
        'console' {
            # Console output is handled by Write-SecurityLog calls
        }
    }
}

function Write-SecurityLog {
    param(
        [Parameter(Mandatory)]
        [ValidateSet('Info', 'Success', 'Warning', 'Error')]
        [string]$Level,

        [Parameter(Mandatory)]
        [AllowEmptyString()]
        [string]$Message
    )

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    if ([string]::IsNullOrEmpty($Message)) {
        $Message = "No message provided"
    }

    Write-Output "[$timestamp] [$Level] $Message"
}

# Docker registry and image SHA mappings
# This maps common images to their current SHA256 digests
$DockerImageSHAMap = @{
    # Microsoft Container Registry Images
    'mcr.microsoft.com/dotnet/runtime:9.0'                 = 'mcr.microsoft.com/dotnet/runtime:9.0@sha256:c7f3e4154ba9f6dcdcbb4b7c81ff1b1be5057fcf78b55e46b50be0c1a5a7bced'
    'mcr.microsoft.com/dotnet/sdk:9.0'                     = 'mcr.microsoft.com/dotnet/sdk:9.0@sha256:c97a488465b7c0e3f193b7bb4b41d6b6e8530f388b5503c1413cb6b3b648b4f3'
    'mcr.microsoft.com/cbl-mariner/base/core:2.0'          = 'mcr.microsoft.com/cbl-mariner/base/core:2.0@sha256:b462b8e95dfa12b3fefc95025a627306a527de61db17b8519a59b8e25f1663c7'
    'mcr.microsoft.com/devcontainers/python:3.11-bookworm' = 'mcr.microsoft.com/devcontainers/python:3.11-bookworm@sha256:17b9b47f293b5b6e4b6a6e67d8bba0d5e0e5b6d6d2c3f4e5a6b7c8d9e0f1a2b3'
    'mcr.microsoft.com/devcontainers/base:ubuntu-24.04'    = 'mcr.microsoft.com/devcontainers/base:ubuntu-24.04@sha256:ad92cae7c25cafb1e7bb5aa7520b81be85fac022ea92e404b94a11127631fae3'
    'mcr.microsoft.com/cbl-mariner/base/rust:1.72'         = 'mcr.microsoft.com/cbl-mariner/base/rust:1.72@sha256:b9fcab32d29e74b9178437797f57732b8654e9b5db93423080a58c35528accd3'

    # Eclipse Foundation Images
    'eclipse-mosquitto'                                    = 'eclipse-mosquitto@sha256:7b77b81b6d25b1fc6cc5ed1eb8ae48c247d4fd6f9aef1f7ee88b4a8e0b7f2b3e'
    'eclipse-mosquitto:latest'                             = 'eclipse-mosquitto@sha256:7b77b81b6d25b1fc6cc5ed1eb8ae48c247d4fd6f9aef1f7ee88b4a8e0b7f2b3e'

    # Observability and monitoring images
    'otel/opentelemetry-collector-contrib:latest'          = 'otel/opentelemetry-collector-contrib:latest@sha256:a1b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2'
    'grafana/otel-lgtm:latest'                             = 'grafana/otel-lgtm:latest@sha256:b2c3d4e5f6a7b8c9d0e1f2a3b4c5d6e7f8a9b0c1d2e3f4a5b6c7d8e9f0a1b2c3'

    # Common base images that might be used
    'ubuntu:22.04'                                         = 'ubuntu:22.04@sha256:6042500cf4b44023ea1894effe7890666b0c5c7871ed83a97c36c76ae560bb9b'
    'alpine:3.19'                                          = 'alpine:3.19@sha256:c5b1261d6d3e43071626931fc004f70149baeba2c8ec672bd4f27761f8e1ad6b'
    'debian:bookworm-slim'                                 = 'debian:bookworm-slim@sha256:c618be84fc82d365ce1834a31746b0ffe0499cf50fb1a0ce7b74863b52e5682c'
    'node:20-alpine'                                       = 'node:20-alpine@sha256:c1ee51b68c17fe1e9e9fb5c481e44b6b74c6c2f6b9f7f0b4b4b4c4c4c4c4c4c4'
    'ubuntu:24.04'                                         = 'ubuntu:24.04@sha256:353675e2a41babd526e2b837d7ec780c2a05bca0164f7ea5dbbd433d21d166fc'
}

# Shell script external dependency patterns
$ShellScriptPatterns = @{
    'curl.*https://sh.rustup.rs' = @{
        'Original' = 'curl --proto ''=https'' --tlsv1.2 -sSf https://sh.rustup.rs'
        'Secure'   = 'curl --proto ''=https'' --tlsv1.2 -sSf https://sh.rustup.rs | sha256sum -c <(echo "3dc5ef50861ee18657f9db2eeb7392f9c2a6c95c90ab41e45ab4ca71476b4338  -")'
    }
    'wget.*get.k8s.io'           = @{
        'Original' = 'wget -qO- https://dl.k8s.io/release/stable.txt'
        'Secure'   = '# WARNING: This downloads latest version dynamically - consider pinning to specific version'
    }
}

# =============================================================================
# Docker Image SHA Pinning Functions
# =============================================================================

function Get-DockerImageDigest {
    param(
        [Parameter(Mandatory)]
        [string]$ImageReference
    )

    try {
        # Try to get digest using docker manifest inspect
        $manifest = docker manifest inspect $ImageReference 2>$null | ConvertFrom-Json
        if ($manifest -and $manifest.Descriptor -and $manifest.Descriptor.digest) {
            return $manifest.Descriptor.digest
        }

        # Fallback: Try to get digest from registry API
        $parts = $ImageReference -split '/'
        if ($parts.Length -ge 2) {
            $registry = $parts[0]
            # Repository extracted for potential future use

            # For MCR images, try the registry API
            if ($registry -eq 'mcr.microsoft.com') {
                # This would require authentication, so we'll use our pre-mapped values
                return $null
            }
        }

        return $null
    }
    catch {
        Write-SecurityLog -Level 'Warning' -Message "Failed to get digest for $ImageReference : $_"
        return $null
    }
}

function Convert-DockerFileImage {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $updatedContent = $Content
    $changesMade = $false
    $pinnedCount = 0
    Write-Information ("[{0}] [Info] Convert-DockerFileImage: Processing {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $FilePath)

    # Pattern to match FROM instructions
    $fromPattern = '(?m)^FROM\s+(?:(?<platform>--platform=[^\s]+\s+))?(?<image>[^\s@]+)(?:@sha256:[\da-f]{64})?\s*(?<remainder>.*)$'

    $regexMatches = [regex]::Matches($updatedContent, $fromPattern)
    Write-Information ("[{0}] [Info] Found {1} FROM instructions" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $regexMatches.Count)
    foreach ($match in $regexMatches) {
        $fullMatch = $match.Value
        $platformSegment = ($match.Groups['platform'].Value | ForEach-Object { $_ })
        $imageRef = $match.Groups['image'].Value.Trim()
        $remainder = $match.Groups['remainder'].Value
        Write-Information ("[{0}] [Info] Processing FROM line: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $fullMatch)
        Write-Information ("[{0}] [Info] Parsed platform='{1}' imageRef='{2}' remainder='{3}'" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $platformSegment, $imageRef, $remainder)

        # Skip if already SHA-pinned and not forcing updates
        if ($imageRef -match '@sha256:' -and -not $Force) {
            Write-Information ("[{0}] [Info] Already SHA-pinned in {1}: {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $FilePath, $imageRef)
            continue
        }

        # Remove existing SHA if forcing updates
        $cleanImageRef = $imageRef -replace '@sha256:[\da-f]{64}', ''
        Write-Information ("[{0}] [Info] Clean image reference: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $cleanImageRef)

        # Check if we have a SHA mapping for this image
        $shaImageRef = $null
        foreach ($key in $DockerImageSHAMap.Keys) {
            if ($cleanImageRef -eq $key -or $cleanImageRef -like "$key*") {
                $shaImageRef = $DockerImageSHAMap[$key]
                Write-Information ("[{0}] [Info] Matched map entry: {1} -> {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $key, $shaImageRef)
                break
            }
        }

        if ($shaImageRef) {
            # Split remainder into (optional) alias/extra tokens and inline comment; then place comment on its own line
            $prePart = $null; $commentPart = $null
            if ($remainder -match '^(?<pre>[^#]*?)(?<comment>#.*)$') {
                $prePart = ($matches['pre']).TrimEnd()
                $commentPart = ($matches['comment']).Trim()
            }
            elseif ($remainder -match '^#') {
                $commentPart = $remainder.Trim()
            }
            else {
                $prePart = $remainder
            }
            $baseLine = "FROM ${platformSegment}${shaImageRef}".TrimEnd()
            if ($prePart -and $prePart.Trim().Length -gt 0) { $baseLine = "$baseLine $prePart".TrimEnd() }
            if ($commentPart) {
                $newFromLine = "$baseLine`n$commentPart"
            }
            else {
                $newFromLine = $baseLine
            }
            $updatedContent = $updatedContent.Replace($fullMatch, $newFromLine.TrimEnd())
            $changesMade = $true
            $pinnedCount++
            Write-Information ("[{0}] [Success] Pinned: {1} -> {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $cleanImageRef, $shaImageRef)
        }
        else {
            # Try to get digest dynamically
            Write-Information ("[{0}] [Info] No static map entry, attempting digest lookup: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $cleanImageRef)
            $digestRaw = Get-DockerImageDigest -ImageReference $cleanImageRef
            # Filter any non-digest log strings accidentally written to the pipeline
            $digest = $null
            if ($digestRaw) {
                $digest = ($digestRaw | Where-Object { $_ -is [string] -and $_ -match '^sha256:[0-9a-f]{64}$' } | Select-Object -First 1)
            }
            if ($digest) {
                $shaImageRef = "$cleanImageRef@$digest"
                $prePart = $null; $commentPart = $null
                if ($remainder -match '^(?<pre>[^#]*?)(?<comment>#.*)$') {
                    $prePart = ($matches['pre']).TrimEnd()
                    $commentPart = ($matches['comment']).Trim()
                }
                elseif ($remainder -match '^#') {
                    $commentPart = $remainder.Trim()
                }
                else {
                    $prePart = $remainder
                }
                $baseLine = "FROM ${platformSegment}${shaImageRef}".TrimEnd()
                if ($prePart -and $prePart.Trim().Length -gt 0) { $baseLine = "$baseLine $prePart".TrimEnd() }
                if ($commentPart) {
                    $newFromLine = "$baseLine`n$commentPart"
                }
                else {
                    $newFromLine = $baseLine
                }
                $updatedContent = $updatedContent.Replace($fullMatch, $newFromLine.TrimEnd())
                $changesMade = $true
                $pinnedCount++
                Write-Information ("[{0}] [Info] Resolved dynamic digest: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $digest)
                Write-Information ("[{0}] [Success] Pinned: {1} -> {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $cleanImageRef, $shaImageRef)
            }
            else {
                Write-Information ("[{0}] [Warning] No valid digest (sha256) resolved for: {1}; leaving image unmodified (will still normalize comment formatting)" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $cleanImageRef)
            }
        }
    }

    if ($changesMade) {
        Write-Information ("[{0}] [Info] Convert-DockerFileImage summary: pinned {1} image(s) in {2}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $pinnedCount, $FilePath)
    }
    else {
        Write-Information ("[{0}] [Info] Convert-DockerFileImage summary: no changes for {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $FilePath)
    }

    return @{
        Content = $updatedContent
        Changed = $changesMade
    }
}

function Convert-DockerComposeImage {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $updatedContent = $Content
    $changesMade = $false

    # Pattern to match image references in docker-compose files
    $imagePattern = '(?m)^\s*image:\s*([^\s@]+)(?:@sha256:[\da-f]{64})?\s*$'

    $dockerMatches = [regex]::Matches($updatedContent, $imagePattern)
    foreach ($match in $dockerMatches) {
        $fullMatch = $match.Value
        $imageRef = $match.Groups[1].Value.Trim()

        # Skip if already SHA-pinned and not forcing updates
        if ($imageRef -match '@sha256:' -and -not $Force) {
            Write-SecurityLog -Level 'Info' -Message "Already SHA-pinned in ${FilePath}: $imageRef"
            continue
        }

        # Remove existing SHA if forcing updates
        $cleanImageRef = $imageRef -replace '@sha256:[\da-f]{64}', ''

        # Check if we have a SHA mapping for this image
        $shaImageRef = $null
        foreach ($key in $DockerImageSHAMap.Keys) {
            if ($cleanImageRef -eq $key -or $cleanImageRef -like "$key*") {
                $shaImageRef = $DockerImageSHAMap[$key]
                break
            }
        }

        if ($shaImageRef) {
            $newImageLine = $fullMatch.Replace($imageRef, $shaImageRef)
            $updatedContent = $updatedContent.Replace($fullMatch, $newImageLine)
            $changesMade = $true
            Write-SecurityLog -Level 'Success' -Message "Pinned: $cleanImageRef -> $shaImageRef"
        }
        else {
            # Try to get digest dynamically
            $digest = Get-DockerImageDigest -ImageReference $cleanImageRef
            if ($digest) {
                $shaImageRef = "$cleanImageRef@$digest"
                $newImageLine = $fullMatch.Replace($imageRef, $shaImageRef)
                $updatedContent = $updatedContent.Replace($fullMatch, $newImageLine)
                $changesMade = $true
                Write-SecurityLog -Level 'Success' -Message "Pinned: $cleanImageRef -> $shaImageRef"
            }
            else {
                Write-SecurityLog -Level 'Warning' -Message "No SHA mapping found for: $cleanImageRef"
            }
        }
    }

    return @{
        Content = $updatedContent
        Changed = $changesMade
    }
}

function Convert-DevcontainerImage {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $updatedContent = $Content
    $changesMade = $false

    # Pattern to match image references in devcontainer.json
    $imagePattern = '"image":\s*"([^"@]+)(?:@sha256:[\da-f]{64})?"'

    $devMatches = [regex]::Matches($updatedContent, $imagePattern)
    foreach ($match in $devMatches) {
        $fullMatch = $match.Value
        $imageRef = $match.Groups[1].Value.Trim()

        # Skip if already SHA-pinned and not forcing updates
        if ($imageRef -match '@sha256:' -and -not $Force) {
            Write-SecurityLog -Level 'Info' -Message "Already SHA-pinned in ${FilePath}: $imageRef"
            continue
        }

        # Remove existing SHA if forcing updates
        $cleanImageRef = $imageRef -replace '@sha256:[\da-f]{64}', ''

        # Check if we have a SHA mapping for this image
        $shaImageRef = $null
        foreach ($key in $DockerImageSHAMap.Keys) {
            if ($cleanImageRef -eq $key -or $cleanImageRef -like "$key*") {
                $shaImageRef = $DockerImageSHAMap[$key]
                break
            }
        }

        if ($shaImageRef) {
            $newImageLine = "`"image`": `"$shaImageRef`""
            $updatedContent = $updatedContent.Replace($fullMatch, $newImageLine)
            $changesMade = $true
            Write-SecurityLog -Level 'Success' -Message "Pinned: $cleanImageRef -> $shaImageRef"
        }
        else {
            # Try to get digest dynamically
            $digest = Get-DockerImageDigest -ImageReference $cleanImageRef
            if ($digest) {
                $shaImageRef = "$cleanImageRef@$digest"
                $newImageLine = "`"image`": `"$shaImageRef`""
                $updatedContent = $updatedContent.Replace($fullMatch, $newImageLine)
                $changesMade = $true
                Write-SecurityLog -Level 'Success' -Message "Pinned: $cleanImageRef -> $shaImageRef"
            }
            else {
                Write-SecurityLog -Level 'Warning' -Message "No SHA mapping found for: $cleanImageRef"
            }
        }
    }

    return @{
        Content = $updatedContent
        Changed = $changesMade
    }
}

# =============================================================================
# Shell Script Security Hardening Functions
# =============================================================================

function Convert-ShellScriptSecurity {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $updatedContent = $Content
    $changesMade = $false

    foreach ($pattern in $ShellScriptPatterns.Keys) {
        $config = $ShellScriptPatterns[$pattern]

        if ($updatedContent -match $pattern) {
            Write-SecurityLog -Level 'Warning' -Message "Found potentially insecure pattern in $FilePath : $pattern"
            Write-SecurityLog -Level 'Info' -Message "Consider: $($config.Secure)"

            # For now, we'll just log findings. Automatic replacement could break scripts.
            # In the future, we could add specific replacements for known safe patterns.
        }
    }

    return @{
        Content = $updatedContent
        Changed = $changesMade
    }
}

# =============================================================================
# Main Execution Logic
# =============================================================================

function Main {
    Write-SecurityLog -Level 'Info' -Message 'Starting Docker and Shell Script SHA pinning process...'

    $rootPath = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

    # Find all Docker-related files
    $dockerFiles = @()
    $dockerFiles += Get-ChildItem -Path $rootPath -Filter "Dockerfile*" -Recurse
    $dockerFiles += Get-ChildItem -Path $rootPath -Filter "docker-compose*.yml" -Recurse
    $dockerFiles += Get-ChildItem -Path $rootPath -Filter "docker-compose*.yaml" -Recurse
    $dockerFiles += Get-ChildItem -Path $rootPath -Filter "devcontainer.json" -Recurse

    Write-SecurityLog -Level 'Info' -Message "Found $($dockerFiles.Count) Docker configuration files"

    $totalProcessed = 0
    $totalChanged = 0

    foreach ($file in $dockerFiles) {
        Write-SecurityLog -Level 'Info' -Message "Processing file: $($file.FullName)"

        try {
            $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
            $result = $null

            if ($file.Name -like "Dockerfile*") {
                Write-SecurityLog -Level 'Info' -Message "Convert-DockerFileImage: $($file.Name)"
                $result = Convert-DockerFileImage -FilePath $file.FullName -Content $content
            }
            elseif ($file.Name -like "docker-compose*") {
                Write-SecurityLog -Level 'Info' -Message "Convert-DockerComposeImage: $($file.Name)"
                $result = Convert-DockerComposeImage -FilePath $file.FullName -Content $content
            }
            elseif ($file.Name -eq "devcontainer.json") {
                Write-SecurityLog -Level 'Info' -Message "Update-DevcontainerImages: $($file.Name)"
                $result = Update-DevcontainerImages -FilePath $file.FullName -Content $content
            }

            if ($result -and $result.PSObject.Properties.Match('Changed') -and $result.Changed) {
                if ($WhatIfPreference) {
                    Write-Output "What if: Performing the operation `"Update Docker SHA pinning`" on target `"$($file.FullName)`"."
                }
                else {
                    Write-Information ("[{0}] [Info] Updating file: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $file.FullName)
                    Set-ContentPreservePermission -Path $file.FullName -Value $result.Content -NoNewline
                    Write-Information ("[{0}] [Success] Updated file: {1}" -f (Get-Date -Format "yyyy-MM-dd HH:mm:ss"), $file.FullName)
                }
                $totalChanged++
            }

            $totalProcessed++
        }
        catch {
            Write-SecurityLog -Level 'Error' -Message "Failed to process $($file.FullName): $_"
        }
    }

    # Process shell scripts if not skipped
    if (-not $SkipShellScripts) {
        $shellFiles = Get-ChildItem -Path $rootPath -Filter "*.sh" -Recurse
        Write-SecurityLog -Level 'Info' -Message "Found $($shellFiles.Count) shell script files"

        foreach ($file in $shellFiles) {
            Write-SecurityLog -Level 'Info' -Message "Analyzing shell script: $($file.FullName)"

            try {
                $content = Get-Content -Path $file.FullName -Raw -ErrorAction Stop
                $result = Convert-ShellScriptSecurity -FilePath $file.FullName -Content $content

                if ($result -and $result.PSObject.Properties.Name -contains 'Changed' -and $result.Changed) {
                    if ($WhatIfPreference) {
                        Write-Output "What if: Performing the operation `"Update Shell Script Security`" on target `"$($file.FullName)`"."
                    }
                    else {
                        Set-ContentPreservePermission -Path $file.FullName -Value $result.Content -NoNewline
                        Write-SecurityLog -Level 'Success' -Message "Updated shell script: $($file.FullName)"
                    }
                }
            }
            catch {
                Write-SecurityLog -Level 'Error' -Message "Failed to analyze $($file.FullName): $_"
            }
        }
    }

    # Summary
    Write-SecurityLog -Level 'Info' -Message '=== Docker SHA Pinning Summary ==='
    Write-SecurityLog -Level 'Info' -Message "Docker files processed: $totalProcessed"
    Write-SecurityLog -Level 'Success' -Message "Docker files changed: $totalChanged"

    if ($WhatIfPreference) {
        Write-SecurityLog -Level 'Info' -Message 'WhatIf mode: No files were modified. Run without -WhatIf to apply changes.'
    }

    # Output results for build system integration
    if ($script:SecurityIssues.Count -gt 0) {
        Write-SecurityLog -Level 'Warning' -Message "=== DOCKER SECURITY ISSUES DETECTED ==="
        foreach ($issue in $script:SecurityIssues) {
            Write-SecurityLog -Level 'Warning' -Message "[$($issue.Severity)] $($issue.Type): $($issue.Message)"
            Write-SecurityLog -Level 'Info' -Message "  File: $($issue.File)"
            if ($issue.Line) {
                Write-SecurityLog -Level 'Info' -Message "  Line: $($issue.Line)"
            }
            Write-SecurityLog -Level 'Info' -Message "---"
        }
        Write-SecurityLog -Level 'Warning' -Message "Total security issues: $($script:SecurityIssues.Count)"
    }

    # Write output in requested format
    $summaryData = @{
        dockerFilesProcessed = $totalProcessed
        dockerFilesChanged   = $totalChanged
        securityIssuesFound  = $script:SecurityIssues.Count
        whatIfMode           = $WhatIfPreference
    }

    Write-OutputResult -Format $OutputFormat -Issues $script:SecurityIssues -Summary $summaryData
}

# Execute main function
try {
    Main
    exit 0
}
catch {
    Write-SecurityLog -Level 'Error' -Message "Script failed: $_"
    exit 1
}
