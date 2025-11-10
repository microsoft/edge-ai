<#
.SYNOPSIS
    Strips complex JavaScript features from Docsify build for GitHub Pages compatibility

.DESCRIPTION
    This script modifies the built Docsify documentation to ensure compatibility with GitHub Pages
    static hosting by removing ES6 modules, server-dependent features, and complex interactive
    elements while preserving essential Docsify functionality and CSS styling.

.PARAMETER BuildPath
    Path to the built site directory (default: ./_site)

.PARAMETER BackupOriginal
    Whether to create a backup of the original index.html (default: $true)

.EXAMPLE
    .\Strip-GHPagesJS.ps1
    Strips JavaScript from the default build directory

.EXAMPLE
    .\Strip-GHPagesJS.ps1 -BuildPath "./dist" -BackupOriginal $false
    Strips JavaScript from custom build directory without creating backup

.NOTES
    This script supports the GitHub Pages deployment workflow by ensuring that only
    documentation-focused static content is deployed, removing features that require
    server-side support or advanced module loading capabilities.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$BuildPath = "./_site",

    [Parameter(Mandatory = $false)]
    [bool]$BackupOriginal = $true
)

# Ensure we're in the right directory context
$ErrorActionPreference = "Stop"

Write-Host "🔧 Stripping complex JavaScript features for GitHub Pages compatibility..." -ForegroundColor Cyan

$indexPath = Join-Path $BuildPath "index.html"
$backupPath = Join-Path $BuildPath "index.html.backup"

# Validate input
if (-not (Test-Path $BuildPath)) {
    Write-Error "Build directory not found: $BuildPath"
    exit 1
}

if (-not (Test-Path $indexPath)) {
    Write-Error "index.html not found in build output: $indexPath"
    exit 1
}

# Create backup if requested
if ($BackupOriginal) {
    Copy-Item $indexPath $backupPath
    Write-Host "[SUCCESS] Created backup of index.html" -ForegroundColor Green
}

# Read the HTML content
try {
    $content = Get-Content $indexPath -Raw -Encoding UTF8
    $charCount = $content.Length
    Write-Host "[INFO] Read index.html content $charCount characters" -ForegroundColor Gray
} catch {
    Write-Error "Failed to read index.html: $_"
    exit 1
}

# Strip ES6 modules - remove script tags with type="module"
$originalLength = $content.Length
$content = $content -replace "<script type=`"module`" src=`"[^`"]*`"></script>", ""
$modulesRemoved = $originalLength -ne $content.Length
if ($modulesRemoved) {
    Write-Host "[STRIP] ES6 module script tags: Removed" -ForegroundColor Yellow
} else {
    Write-Host "[STRIP] ES6 module script tags: None found" -ForegroundColor Gray
}

# Remove the entire ES6 modules section between HTML comments
$beforeSectionRemoval = $content.Length
$content = $content -replace "(?s)<!-- KATA TRACKER SYSTEM - ES6 MODULES -->.*?(?=<!-- DOCSIFY PLUGINS `& ENHANCEMENTS -->)", ""
$sectionRemoved = $beforeSectionRemoval -ne $content.Length
if ($sectionRemoved) {
    Write-Host "[STRIP] ES6 modules section: Removed" -ForegroundColor Yellow
} else {
    Write-Host "[STRIP] ES6 modules section: None found" -ForegroundColor Gray
}

# Remove complex interactive features that require server-side support
$beforeTrackerRemoval = $content.Length
$content = $content -replace ".*learning-progress-tracker-plugin\.js.*`r?`n?", ""
$trackerRemoved = $beforeTrackerRemoval -ne $content.Length
if ($trackerRemoved) {
    Write-Host "[STRIP] Progress tracker references: Removed" -ForegroundColor Yellow
} else {
    Write-Host "[STRIP] Progress tracker references: None found" -ForegroundColor Gray
}

# Write the modified content back
try {
    Set-Content $indexPath $content -NoNewline -Encoding UTF8
    Write-Host "[SUCCESS] Updated index.html with stripped content" -ForegroundColor Green
} catch {
    Write-Error "Failed to write modified index.html: $_"
    exit 1
}

# Remove server-dependent JavaScript files
$filesToRemove = @(
    "docs/assets/js/main.js",
    "docs/assets/js/modules/*",
    "docs/assets/js/features/progress-tracker*",
    "docs/assets/js/features/kata-*"
)

$totalRemoved = 0
foreach ($pattern in $filesToRemove) {
    $fullPattern = Join-Path $BuildPath $pattern
    try {
        $files = Get-ChildItem $fullPattern -ErrorAction SilentlyContinue
        if ($files) {
            $files | Remove-Item -Force
            $totalRemoved += $files.Count
            Write-Host "[REMOVE] Removed $($files.Count) files matching: $pattern" -ForegroundColor Yellow
        }
    } catch {
        Write-Warning "Could not remove files matching $pattern : $($_.Exception.Message)"
    }
}

if ($totalRemoved -eq 0) {
    Write-Host "[INFO] No server-dependent JavaScript files found to remove" -ForegroundColor Gray
}

# Validation
Write-Host ""
Write-Host "[VALIDATE] Validating JavaScript stripping..." -ForegroundColor Cyan

try {
    $finalContent = Get-Content $indexPath -Raw -Encoding UTF8

    # Check for remaining ES6 modules
    if ($finalContent -match "type=`"module`"") {
        Write-Host "[WARNING] Some ES6 modules may still be present" -ForegroundColor Yellow
    } else {
        Write-Host "[SUCCESS] ES6 modules successfully removed" -ForegroundColor Green
    }

    # Check for progress tracker references
    if ($finalContent -match "learning-progress-tracker") {
        Write-Host "[WARNING] Progress tracker references may still be present" -ForegroundColor Yellow
    } else {
        Write-Host "[SUCCESS] Progress tracker references successfully removed" -ForegroundColor Green
    }

    # File size comparison
    if ($BackupOriginal -and (Test-Path $backupPath)) {
        $originalSize = (Get-Item $backupPath).Length
        $newSize = (Get-Item $indexPath).Length
        $reduction = $originalSize - $newSize
        $reductionPercent = [math]::Round(($reduction / $originalSize) * 100, 1)

        Write-Host "[STATS] File size comparison:" -ForegroundColor Cyan
        Write-Host "   Original: $originalSize bytes" -ForegroundColor Gray
        Write-Host "   Stripped: $newSize bytes" -ForegroundColor Gray
        if ($reduction -gt 0) {
            Write-Host "   Reduction: $reduction bytes ($reductionPercent%)" -ForegroundColor Green
        } else {
            Write-Host "   Reduction: $reduction bytes ($reductionPercent%)" -ForegroundColor Gray
        }
    }

} catch {
    Write-Warning "Could not validate final content: $_"
}

Write-Host ""
Write-Host "[COMPLETE] JavaScript stripping completed for GitHub Pages compatibility" -ForegroundColor Green
Write-Host "Ready for static hosting deployment!" -ForegroundColor Cyan

