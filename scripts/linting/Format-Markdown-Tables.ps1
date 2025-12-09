<#
.SYNOPSIS
    Wrapper script for markdown-table-formatter with exclusion support.

.DESCRIPTION
    Discovers markdown files with exclusion patterns and passes them to markdown-table-formatter.
    Provides control over which folders to exclude while formatting tables.

.PARAMETER Check
    Check only mode - exits with code 1 if formatting is needed without modifying files.

.PARAMETER Exclude
    Array of folder patterns to exclude from formatting.
    Default: @('node_modules', '.git', '.vscode', '.devcontainer', 'venv', '.github/instructions', '.github/prompts', '.copilot-tracking')

.PARAMETER Include
    Array of folder patterns to explicitly include (overrides default exclusions).
    Default: @()

.PARAMETER Verbose
    Enable verbose output showing files being processed.

.EXAMPLE
    .\Format-Markdown-Tables.ps1
    Format all markdown tables in non-excluded directories.

.EXAMPLE
    .\Format-Markdown-Tables.ps1 -Check
    Check if any markdown tables need formatting without modifying files.

.EXAMPLE
    .\Format-Markdown-Tables.ps1 -Exclude @('node_modules', 'test')
    Format tables excluding only node_modules and test folders.

.EXAMPLE
    .\Format-Markdown-Tables.ps1 -Verbose
    Format tables with verbose output showing each file processed.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [switch]$Check,

    [Parameter(Mandatory = $false)]
    [string[]]$Exclude = @(
        'node_modules',
        '.git',
        'venv',
        '.copilot-tracking'
    ),

    [Parameter(Mandatory = $false)]
    [string[]]$Include = @(),

    [Parameter(Mandatory = $false)]
    [switch]$VerboseOutput
)

$ErrorActionPreference = 'Stop'

# Get repository root (current directory)
$RepoRoot = Get-Location

# Discover all markdown files
Write-Host "Discovering markdown files..." -ForegroundColor Cyan
$AllMarkdownFiles = Get-ChildItem -Path $RepoRoot -Filter "*.md" -Recurse -File -ErrorAction SilentlyContinue

if ($AllMarkdownFiles.Count -eq 0) {
    Write-Host "No markdown files found." -ForegroundColor Yellow
    exit 0
}

Write-Host "Found $($AllMarkdownFiles.Count) total markdown files" -ForegroundColor Cyan

# Filter out excluded paths
$FilteredFiles = $AllMarkdownFiles | Where-Object {
    $filePath = $_.FullName.Replace($RepoRoot.Path, '').TrimStart('\', '/')
    $shouldExclude = $false

    # Check if file is in an excluded folder
    foreach ($excludePattern in $Exclude) {
        $normalizedPattern = $excludePattern.Replace('/', '\')
        if ($filePath -like "*\$normalizedPattern\*" -or $filePath -like "$normalizedPattern\*") {
            $shouldExclude = $true
            break
        }
    }

    # Check if file is explicitly included (overrides exclusion)
    if ($shouldExclude -and $Include.Count -gt 0) {
        foreach ($includePattern in $Include) {
            $normalizedPattern = $includePattern.Replace('/', '\')
            if ($filePath -like "*\$normalizedPattern\*" -or $filePath -like "$normalizedPattern\*") {
                $shouldExclude = $false
                break
            }
        }
    }

    -not $shouldExclude
}

if ($FilteredFiles.Count -eq 0) {
    Write-Host "No markdown files to process after applying exclusion filters." -ForegroundColor Yellow
    exit 0
}

Write-Host "Processing $($FilteredFiles.Count) markdown files after exclusions" -ForegroundColor Cyan

# Execute markdown-table-formatter
Write-Host "Running markdown-table-formatter..." -ForegroundColor Cyan

# Find the markdown-table-formatter CLI
$formatterPath = if ($IsWindows) {
    Join-Path $RepoRoot "node_modules\.bin\markdown-table-formatter.cmd"
}
else {
    Join-Path $RepoRoot "node_modules/.bin/markdown-table-formatter"
}

if (-not (Test-Path $formatterPath)) {
    Write-Error "markdown-table-formatter not found. Run 'npm install' first."
    exit 1
}

# Build base arguments
$baseArgs = @()
if ($Check) {
    $baseArgs += '--check'
}
if ($VerboseOutput) {
    $baseArgs += '--verbose'
}

# Process files in batches to avoid command line length limits
$batchSize = 50
$totalFiles = $FilteredFiles.Count
$processedFiles = 0
$exitCode = 0

for ($i = 0; $i -lt $totalFiles; $i += $batchSize) {
    $batch = $FilteredFiles[$i..[Math]::Min($i + $batchSize - 1, $totalFiles - 1)]
    $batchPaths = $batch | ForEach-Object { $_.FullName }

    $processedFiles += $batch.Count
    Write-Host "Processing batch: $processedFiles / $totalFiles files" -ForegroundColor Gray

    $formatterArgs = $baseArgs + $batchPaths
    & $formatterPath $formatterArgs

    # If any batch fails in check mode, capture the failure
    if ($LASTEXITCODE -ne 0) {
        $exitCode = $LASTEXITCODE
    }
}

Write-Host "Completed processing $totalFiles files" -ForegroundColor Cyan

# Exit with failure code if any batch failed
exit $exitCode
