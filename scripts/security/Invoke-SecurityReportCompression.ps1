#!/usr/bin/env pwsh
<#
.SYNOPSIS
Compresses security scan reports and artifacts for optimal storage efficiency while maintaining accessibility.

.DESCRIPTION
This script compresses security scan results, SARIF reports, JUnit XML files, and related artifacts
to reduce storage overhead in CI/CD pipelines. It maintains file structure and metadata while
achieving optimal compression ratios for different file types.

.PARAMETER SecurityReportsPath
Path to the directory containing security scan reports to compress.

.PARAMETER OutputPath
Path where compressed artifacts should be saved. Defaults to 'compressed-security-reports'.

.PARAMETER CompressionLevel
Compression level (1-9). Higher values provide better compression but take longer.
Default: 9 (maximum compression for storage efficiency).

.PARAMETER PreservePaths
Whether to preserve the original directory structure in the compressed archive.
Default: $true.

.PARAMETER GenerateManifest
Whether to generate a manifest file listing all compressed artifacts and their metadata.
Default: $true.

.PARAMETER Verbose
Enable verbose output showing compression statistics and file details.

.EXAMPLE
./Invoke-SecurityReportCompression.ps1 -SecurityReportsPath "./security-reports" -Verbose

.EXAMPLE
./Invoke-SecurityReportCompression.ps1 -SecurityReportsPath "./security-reports" -OutputPath "./compressed" -CompressionLevel 6

.NOTES
- Designed for CI/CD environments with PowerShell Core support
- Optimizes storage efficiency while maintaining file accessibility
- Supports multiple compression algorithms based on file types
- Generates metadata for artifact tracking and compliance
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $true)]
    [ValidateScript({ Test-Path $_ -PathType Container })]
    [string]$SecurityReportsPath,

    [Parameter(Mandatory = $false)]
    [string]$OutputPath = "compressed-security-reports",

    [Parameter(Mandatory = $false)]
    [ValidateRange(1, 9)]
    [int]$CompressionLevel = 9,

    [Parameter(Mandatory = $false)]
    [bool]$PreservePaths = $true,

    [Parameter(Mandatory = $false)]
    [bool]$GenerateManifest = $true
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# Import required modules
if (-not (Get-Module -Name "Microsoft.PowerShell.Archive" -ListAvailable)) {
    Write-Error "Microsoft.PowerShell.Archive module is required but not available"
}

function Write-CompressionLog {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [ValidateSet("Info", "Warning", "Error", "Success")]
        [string]$Level = "Info"
    )

    $timestamp = Get-Date -Format "HH:mm:ss.fff"
    Write-Verbose "[$timestamp] [$Level] $Message"
}

function Get-OptimalCompressionMethod {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [int]$Level
    )

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()

    switch ($extension) {
        ".xml" { return @{ Method = "Deflate"; Level = $Level } }
        ".json" { return @{ Method = "Deflate"; Level = $Level } }
        ".sarif" { return @{ Method = "Deflate"; Level = $Level } }
        ".log" { return @{ Method = "Deflate"; Level = ([math]::Min($Level, 6)) } }
        ".txt" { return @{ Method = "Deflate"; Level = ([math]::Min($Level, 6)) } }
        default { return @{ Method = "Deflate"; Level = $Level } }
    }
}

function Compress-SecurityReportDirectory {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SourcePath,

        [Parameter(Mandatory = $true)]
        [string]$DestinationPath,

        [Parameter(Mandatory = $true)]
        [string]$ArchiveName,

        [Parameter(Mandatory = $true)]
        [int]$Level
    )

    try {
        Write-CompressionLog -Message "Compressing directory: $SourcePath" -Level "Info"

        $compressionStart = Get-Date

        # Create destination directory if it doesn't exist
        $destinationDir = Split-Path -Path $DestinationPath -Parent
        if (-not (Test-Path $destinationDir)) {
            New-Item -Path $destinationDir -ItemType Directory -Force | Out-Null
        }

        # Get compression parameters
        $compressionParams = @{
            Path             = $SourcePath
            DestinationPath  = $DestinationPath
            CompressionLevel = "Optimal"
        }

        if ($Level -ge 8) {
            $compressionParams.CompressionLevel = "Optimal"
        }
        elseif ($Level -ge 5) {
            $compressionParams.CompressionLevel = "Fastest"
        }
        else {
            $compressionParams.CompressionLevel = "NoCompression"
        }

        # Perform compression
        Compress-Archive @compressionParams -Force

        $compressionEnd = Get-Date
        $compressionDuration = ($compressionEnd - $compressionStart).TotalSeconds

        # Calculate compression statistics
        $originalSize = (Get-ChildItem -Path $SourcePath -Recurse -File | Measure-Object -Property Length -Sum).Sum
        $compressedSize = (Get-Item -Path $DestinationPath).Length
        $compressionRatio = if ($originalSize -gt 0) { 1 - ($compressedSize / $originalSize) } else { 0 }

        $stats = @{
            ArchiveName         = $ArchiveName
            OriginalSize        = $originalSize
            CompressedSize      = $compressedSize
            CompressionRatio    = $compressionRatio
            CompressionDuration = $compressionDuration
            CompressionLevel    = $Level
            FilePath            = $DestinationPath
        }

        Write-CompressionLog -Message "Compression completed: $([math]::Round($compressionRatio * 100, 2))% reduction" -Level "Success"
        return $stats
    }
    catch {
        Write-CompressionLog -Message "Compression failed: $($_.Exception.Message)" -Level "Error"
        throw
    }
}

function New-CompressionManifest {
    [CmdletBinding(SupportsShouldProcess)]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory = $true)]
        [array]$CompressionStats,

        [Parameter(Mandatory = $true)]
        [string]$ManifestPath,

        [Parameter(Mandatory = $true)]
        [int]$Level
    )

    try {
        Write-CompressionLog -Message "Generating compression manifest" -Level "Info"

        $manifest = @{
            GeneratedAt      = Get-Date -Format "yyyy-MM-ddTHH:mm:ss.fffZ"
            CompressionLevel = $Level
            TotalArchives    = $CompressionStats.Count
            Summary          = @{
                TotalOriginalSize       = ($CompressionStats | Measure-Object -Property OriginalSize -Sum).Sum
                TotalCompressedSize     = ($CompressionStats | Measure-Object -Property CompressedSize -Sum).Sum
                AverageCompressionRatio = if ($CompressionStats.Count -gt 0) {
                    ($CompressionStats | Measure-Object -Property CompressionRatio -Average).Average
                }
                else { 0 }
                TotalCompressionTime    = ($CompressionStats | Measure-Object -Property CompressionDuration -Sum).Sum
            }
            Archives         = $CompressionStats | ForEach-Object {
                @{
                    Name                = $_.ArchiveName
                    FilePath            = $_.FilePath
                    OriginalSizeMB      = [math]::Round($_.OriginalSize / 1MB, 2)
                    CompressedSizeMB    = [math]::Round($_.CompressedSize / 1MB, 2)
                    CompressionRatio    = [math]::Round($_.CompressionRatio, 4)
                    CompressionDuration = [math]::Round($_.CompressionDuration, 2)
                    CompressionLevel    = $Level
                }
            }
        }

        # Calculate overall compression efficiency
        $totalOriginal = $manifest.Summary.TotalOriginalSize
        $totalCompressed = $manifest.Summary.TotalCompressedSize
        $overallRatio = if ($totalOriginal -gt 0) { 1 - ($totalCompressed / $totalOriginal) } else { 0 }

        $manifest.Summary.OverallCompressionRatio = [math]::Round($overallRatio, 4)
        $manifest.Summary.SpaceSavedMB = [math]::Round(($totalOriginal - $totalCompressed) / 1MB, 2)

        # Write manifest to file
        if ($PSCmdlet.ShouldProcess($ManifestPath, "Create compression manifest")) {
            $manifest | ConvertTo-Json -Depth 10 | Set-Content -Path $ManifestPath -Encoding UTF8
        }

        Write-CompressionLog -Message "Manifest generated: $ManifestPath" -Level "Success"
        Write-CompressionLog -Message "Overall compression: $([math]::Round($overallRatio * 100, 2))% space reduction" -Level "Success"

        return $manifest
    }
    catch {
        Write-CompressionLog -Message "Manifest generation failed: $($_.Exception.Message)" -Level "Error"
        throw
    }
}

function Invoke-SecurityReportCompression {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [string]$SecurityReportsPath,

        [Parameter(Mandatory = $true)]
        [string]$OutputPath,

        [Parameter(Mandatory = $true)]
        [int]$CompressionLevel,

        [Parameter(Mandatory = $true)]
        [bool]$PreservePaths,

        [Parameter(Mandatory = $true)]
        [bool]$GenerateManifest
    )

    try {
        Write-CompressionLog -Message "Starting security report compression" -Level "Info"
        Write-CompressionLog -Message "Source: $SecurityReportsPath" -Level "Info"
        Write-CompressionLog -Message "Output: $OutputPath" -Level "Info"
        Write-CompressionLog -Message "Compression Level: $CompressionLevel" -Level "Info"

        # Validate input directory
        if (-not (Test-Path $SecurityReportsPath -PathType Container)) {
            throw "Security reports path does not exist or is not a directory: $SecurityReportsPath"
        }

        # Create output directory
        if (-not (Test-Path $OutputPath)) {
            New-Item -Path $OutputPath -ItemType Directory -Force | Out-Null
            Write-CompressionLog -Message "Created output directory: $OutputPath" -Level "Info"
        }

        # Get all subdirectories and files to compress
        $itemsToCompress = @()

        # Compress directories separately for optimal organization
        $directories = Get-ChildItem -Path $SecurityReportsPath -Directory -ErrorAction SilentlyContinue
        foreach ($dir in $directories) {
            $itemName = if ($PreservePaths) { $dir.Name } else { "security-reports-$($dir.Name)" }
            $itemsToCompress += @{
                Type = "Directory"
                Path = $dir.FullName
                Name = $itemName
            }
        }

        # If no subdirectories, compress the entire directory
        $directoryCount = ($directories | Measure-Object).Count
        if ($directoryCount -eq 0) {
            $itemName = if ($PreservePaths) { "security-reports" } else { "security-reports-all" }
            $itemsToCompress += @{
                Type = "Directory"
                Path = $SecurityReportsPath
                Name = $itemName
            }
        }

        Write-CompressionLog -Message "Found $($itemsToCompress.Count) items to compress" -Level "Info"

        $compressionStats = @()
        $totalStart = Get-Date

        foreach ($item in $itemsToCompress) {
            $archiveName = "$($item.Name).zip"
            $archivePath = Join-Path -Path $OutputPath -ChildPath $archiveName

            Write-CompressionLog -Message "Processing: $($item.Name)" -Level "Info"

            $stats = Compress-SecurityReportDirectory -SourcePath $item.Path -DestinationPath $archivePath -ArchiveName $archiveName -Level $CompressionLevel
            $compressionStats += $stats
        }

        $totalEnd = Get-Date
        $totalDuration = ($totalEnd - $totalStart).TotalSeconds

        Write-CompressionLog -Message "Compression completed in $([math]::Round($totalDuration, 2)) seconds" -Level "Success"

        # Generate manifest if requested
        if ($GenerateManifest) {
            $manifestPath = Join-Path -Path $OutputPath -ChildPath "compression-manifest.json"
            $manifest = New-CompressionManifest -CompressionStats $compressionStats -ManifestPath $manifestPath -Level $CompressionLevel

            # Output summary statistics
            Write-CompressionLog -Message "=== Compression Summary ===" -Level "Info"
            Write-CompressionLog -Message "Total Archives: $($manifest.TotalArchives)" -Level "Info"
            Write-CompressionLog -Message "Original Size: $([math]::Round($manifest.Summary.TotalOriginalSize / 1MB, 2)) MB" -Level "Info"
            Write-CompressionLog -Message "Compressed Size: $([math]::Round($manifest.Summary.TotalCompressedSize / 1MB, 2)) MB" -Level "Info"
            Write-CompressionLog -Message "Space Saved: $($manifest.Summary.SpaceSavedMB) MB" -Level "Success"
            Write-CompressionLog -Message "Compression Ratio: $([math]::Round($manifest.Summary.OverallCompressionRatio * 100, 2))%" -Level "Success"
        }

        Write-CompressionLog -Message "Security report compression completed successfully" -Level "Success"
        return $compressionStats
    }
    catch {
        Write-CompressionLog -Message "Security report compression failed: $($_.Exception.Message)" -Level "Error"
        throw
    }
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-SecurityReportCompression -SecurityReportsPath $SecurityReportsPath -OutputPath $OutputPath -CompressionLevel $CompressionLevel -PreservePaths $PreservePaths -GenerateManifest $GenerateManifest
}
