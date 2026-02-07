# Validate-MarkdownFrontmatter.ps1
#
# Purpose: Validates frontmatter consistency across markdown files in the repository
# Author: Edge AI Team
# Created: 2025-06-17
#
# This script provides dedicated frontmatter validation functionality without the overhead
# of loading sidebar generation logic. It validates required fields, date formats, and
# content structure across different types of documentation.

param(
    [Parameter(Mandatory = $false)]
    [string[]]$Paths = @('docs', 'src', 'blueprints', 'learning', '.github'),

    [Parameter(Mandatory = $false)]
    [string[]]$Files = @(),

    [Parameter(Mandatory = $false)]
    [switch]$WarningsAsErrors,

    [Parameter(Mandatory = $false)]
    [switch]$ChangedFilesOnly,

    [Parameter(Mandatory = $false)]
    [string]$BaseBranch = "origin/main"
)

function Get-MarkdownFrontmatter {
    <#
    .SYNOPSIS
    Extracts YAML frontmatter from a markdown file.

    .DESCRIPTION
    Parses YAML frontmatter from the beginning of a markdown file and returns
    a structured object containing the frontmatter data and content.

    .PARAMETER FilePath
    Path to the markdown file to parse.

    .OUTPUTS
    Returns a hashtable with Frontmatter, FrontmatterEndIndex, and Content properties.
    #>    param(
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        Write-Warning "File not found: $FilePath"
        return $null
    }

    try {
        $content = Get-Content -Path $FilePath -Raw -Encoding UTF8

        # Check if file starts with YAML frontmatter
        if (-not $content.StartsWith("---")) {
            return $null
        }

        # Find the end of frontmatter
        $lines = $content -split "`n"
        $endIndex = -1

        for ($i = 1; $i -lt $lines.Count; $i++) {
            if ($lines[$i].Trim() -eq "---") {
                $endIndex = $i
                break
            }
        }

        if ($endIndex -eq -1) {
            Write-Warning "Malformed YAML frontmatter in: $FilePath"
            return $null
        }

        # Extract frontmatter lines
        $frontmatterLines = $lines[1..($endIndex - 1)]
        $frontmatter = @{}

        foreach ($line in $frontmatterLines) {
            if ($line.Trim() -eq "" -or $line.Trim().StartsWith("#")) {
                continue
            }

            if ($line -match "^([^:]+):\s*(.*)$") {
                $key = $matches[1].Trim()
                $value = $matches[2].Trim()

                # Handle array values (YAML arrays starting with -)
                if ($value.StartsWith("[") -and $value.EndsWith("]")) {
                    # Parse JSON-style array
                    try {
                        $frontmatter[$key] = $value | ConvertFrom-Json
                    }
                    catch {
                        $frontmatter[$key] = $value
                    }
                }
                else {
                    # Check if this is the start of a YAML array
                    if ($value.StartsWith("-") -or $value.Trim() -eq "") {
                        $arrayValues = @()
                        if ($value.StartsWith("-")) {
                            $arrayValues += $value.Substring(1).Trim()
                        }

                        # Look for additional array items
                        $j = $frontmatterLines.IndexOf($line) + 1
                        while ($j -lt $frontmatterLines.Count -and $frontmatterLines[$j].StartsWith("  -")) {
                            $arrayValues += $frontmatterLines[$j].Substring(3).Trim()
                            $j++
                        }

                        if ($arrayValues.Count -gt 0) {
                            $frontmatter[$key] = $arrayValues
                        }
                        else {
                            $frontmatter[$key] = $value
                        }
                    }
                    else {
                        # Remove quotes if present
                        if (($value.StartsWith('"') -and $value.EndsWith('"')) -or
                            ($value.StartsWith("'") -and $value.EndsWith("'"))) {
                            $value = $value.Substring(1, $value.Length - 2)
                        }
                        $frontmatter[$key] = $value
                    }
                }
            }
        }

        return @{
            Frontmatter         = $frontmatter
            FrontmatterEndIndex = $endIndex + 1
            Content             = ($lines[($endIndex + 1)..($lines.Count - 1)] -join "`n")
        }
    }
    catch {
        Write-Warning "Error parsing frontmatter in ${FilePath}: $($_.Exception.Message)"
        return $null
    }
}

function Test-FrontmatterValidation {
    <#
    .SYNOPSIS
    Validates frontmatter across all markdown files in specified paths.

    .DESCRIPTION
    Performs comprehensive frontmatter validation including required fields,
    date format validation, and content type-specific requirements.

    .PARAMETER Paths
    Array of paths to search for markdown files.

    .PARAMETER Files
    Array of specific file paths to validate (takes precedence over Paths).

    .PARAMETER WarningsAsErrors    Treat warnings as errors (fail validation on warnings).

    .OUTPUTS
    Returns validation results with errors and warnings.
    #>    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$Paths = @(),

        [Parameter(Mandatory = $false)]
        [AllowEmptyCollection()]
        [string[]]$Files = @(),

        [Parameter(Mandatory = $false)]
        [switch]$WarningsAsErrors,

        [Parameter(Mandatory = $false)]
        [switch]$ChangedFilesOnly,

        [Parameter(Mandatory = $false)]
        [string]$BaseBranch = "origin/main"
    )Write-Host "🔍 Validating frontmatter across markdown files..." -ForegroundColor Cyan    # Input validation and sanitization
    $errors = @()
    $warnings = @()

    # If ChangedFilesOnly is specified, get changed files from git
    if ($ChangedFilesOnly) {
        Write-Host "🔍 Detecting changed markdown files from git diff..." -ForegroundColor Cyan
        $gitChangedFiles = Get-ChangedMarkdownFileGroup -BaseBranch $BaseBranch
        if ($gitChangedFiles.Count -gt 0) {
            $Files = $gitChangedFiles
            Write-Host "Found $($Files.Count) changed markdown files to validate" -ForegroundColor Cyan
        }
        else {
            Write-Host "No changed markdown files found - validation complete" -ForegroundColor Green
            return @{
                Errors            = @()
                Warnings          = @()
                HasIssues         = $false
                TotalFilesChecked = 0
            }
        }
    }

    # Sanitize Files array - remove empty or null entries
    if ($Files.Count -gt 0) {
        $sanitizedFiles = @()
        foreach ($file in $Files) {
            if (-not [string]::IsNullOrEmpty($file)) {
                $sanitizedFiles += $file.Trim()
            }
            else {
                Write-Verbose "Filtering out empty file path from Files array"
            }
        }
        $Files = $sanitizedFiles
    }

    # Sanitize Paths array - remove empty or null entries
    if ($Paths.Count -gt 0) {
        $sanitizedPaths = @()
        foreach ($path in $Paths) {
            if (-not [string]::IsNullOrEmpty($path)) {
                $sanitizedPaths += $path.Trim()
            }
            else {
                Write-Verbose "Filtering out empty path from Paths array"
            }
        }
        $Paths = $sanitizedPaths
    }    # Ensure we have at least one valid input source
    if ($Files.Count -eq 0 -and $Paths.Count -eq 0) {
        $warnings += "No valid files or paths provided for validation"
        return @{
            Errors            = @()
            Warnings          = $warnings
            HasIssues         = $true
            TotalFilesChecked = 0
        }
    }

    # Get markdown files either from specific files or from paths
    $markdownFiles = @()

    if ($Files.Count -gt 0) {
        Write-Host "Validating specific files..." -ForegroundColor Cyan
        foreach ($file in $Files) {
            if (-not [string]::IsNullOrEmpty($file) -and (Test-Path $file -PathType Leaf)) {
                if ($file -like "*.md") {
                    $fileItem = Get-Item $file
                    if ($null -ne $fileItem -and -not [string]::IsNullOrEmpty($fileItem.FullName)) {
                        $markdownFiles += $fileItem
                        Write-Verbose "Added specific file: $file"
                    }
                }
                else {
                    Write-Verbose "Skipping non-markdown file: $file"
                }
            }
            else {
                Write-Warning "File not found or invalid: $file"
            }
        }
    }
    else {
        Write-Host "Searching for markdown files in specified paths..." -ForegroundColor Cyan
        foreach ($path in $Paths) {
            if (Test-Path $path) {
                # Use more specific filtering to avoid null entries
                $files = Get-ChildItem -Path $path -Filter '*.md' -Recurse -File -ErrorAction SilentlyContinue |
                    Where-Object {
                        $null -ne $_ -and
                        -not [string]::IsNullOrEmpty($_.FullName) -and
                        $_.PSIsContainer -eq $false
                    }
                if ($files) {
                    $markdownFiles += $files
                    Write-Verbose "Found $($files.Count) markdown files in $path"
                }
                else {
                    Write-Verbose "No markdown files found in $path"
                }
            }
            else {
                Write-Warning "Path not found: $path"
            }
        }
    }Write-Host "Found $($markdownFiles.Count) total markdown files to validate" -ForegroundColor Cyan

    foreach ($file in $markdownFiles) {
        # Skip null file objects or files with empty/null paths
        if ($null -eq $file -or [string]::IsNullOrEmpty($file.FullName)) {
            Write-Verbose "Skipping invalid file object or file with empty path"
            continue
        }

        Write-Verbose "Validating: $($file.FullName)"

        try {
            $frontmatter = Get-MarkdownFrontmatter -FilePath $file.FullName

            if ($frontmatter) {
                # Determine content type and required fields
                $isLearning = $file.DirectoryName -like "*learning*"
                $isGitHub = $file.DirectoryName -like "*.github*"
                $isAgent = $file.Name -like "*.agent.md"
                $isPrompt = $file.Name -like "*.prompt.md"
                $isInstruction = $file.Name -like "*.instructions.md"
                $isMainDoc = ($file.DirectoryName -like "*docs*" -or
                    $file.DirectoryName -like "*src*" -or
                    $file.DirectoryName -like "*blueprints*") -and
                -not $isGitHub -and -not $isLearning

                # Validate required fields for main documentation
                if ($isMainDoc) {
                    $requiredFields = @('title', 'description', 'author', 'ms.date', 'ms.topic')

                    foreach ($field in $requiredFields) {
                        if (-not $frontmatter.Frontmatter.ContainsKey($field)) {
                            $errors += "Missing required field '$field' in: $($file.FullName)"
                        }
                    }

                    # Validate date format (ISO 8601: YYYY-MM-DD)
                    if ($frontmatter.Frontmatter.ContainsKey('ms.date')) {
                        $date = $frontmatter.Frontmatter['ms.date']
                        if ($date -notmatch '^\d{4}-\d{2}-\d{2}$') {
                            $warnings += "Invalid date format in: $($file.FullName). Expected YYYY-MM-DD (ISO 8601), got: $date"
                        }
                    }

                    # Validate ms.topic values
                    if ($frontmatter.Frontmatter.ContainsKey('ms.topic')) {
                        $validTopics = @('concept', 'how-to', 'reference', 'tutorial', 'overview', 'architecture')
                        $topic = $frontmatter.Frontmatter['ms.topic']
                        if ($topic -notin $validTopics) {
                            $warnings += "Invalid ms.topic value '$topic' in: $($file.FullName). Valid values: $($validTopics -join ', ')"
                        }
                    }
                }
                # Validate Learning Platform content (more relaxed requirements)
                elseif ($isLearning) {
                    $suggestedFields = @('title', 'description')
                    foreach ($field in $suggestedFields) {
                        if (-not $frontmatter.Frontmatter.ContainsKey($field)) {
                            $warnings += "Suggested field '$field' missing in Learning Platform content: $($file.FullName)"
                        }
                    }
                }                # GitHub resources have different requirements
                elseif ($isGitHub) {
                    # Agent files (.agent.md) have specific frontmatter structure
                    if ($isAgent) {
                        # Agent files typically have description, tools, etc. but not standard doc fields
                        # Only warn if missing description as it's commonly used
                        if (-not $frontmatter.Frontmatter.ContainsKey('description')) {
                            $warnings += "Agent file missing 'description' field: $($file.FullName)"
                        }
                    }
                    # Instruction files (.instructions.md) have specific patterns
                    elseif ($isInstruction) {
                        # Instruction files should have 'applyTo' field for context-specific instructions
                        if (-not $frontmatter.Frontmatter.ContainsKey('applyTo')) {
                            $warnings += "Instruction file missing 'applyTo' field: $($file.FullName)"
                        }
                    }
                    # Prompt files (.prompt.md) are instructions/templates
                    elseif ($isPrompt) {
                        # Prompt files are typically instruction content, no specific frontmatter required
                        # These are generally freeform content
                    }
                    # Other GitHub files (templates, etc.)
                    elseif ($file.Name -like "*template*" -and -not $frontmatter.Frontmatter.ContainsKey('name')) {
                        $warnings += "GitHub template missing 'name' field: $($file.FullName)"
                    }
                }

                # Validate keywords array (applies to all content types)
                if ($frontmatter.Frontmatter.ContainsKey('keywords')) {
                    $keywords = $frontmatter.Frontmatter['keywords']
                    if ($keywords -isnot [array] -and $keywords -notmatch ',') {
                        $warnings += "Keywords should be an array in: $($file.FullName)"
                    }
                }
                # Validate estimated_reading_time if present
                if ($frontmatter.Frontmatter.ContainsKey('estimated_reading_time')) {
                    $readingTime = $frontmatter.Frontmatter['estimated_reading_time']
                    if ($readingTime -notmatch '^\d+$') {
                        $warnings += "Invalid estimated_reading_time format in: $($file.FullName). Should be a number."
                    }
                }
            }
            else {
                # Only warn for main docs, not for GitHub files, prompts, custom agents, or Learning Platform content
                $isLearningLocal = $file.DirectoryName -like "*learning*"
                $isGitHubLocal = $file.DirectoryName -like "*.github*"
                $isMainDocLocal = ($file.DirectoryName -like "*docs*" -or
                    $file.DirectoryName -like "*src*" -or
                    $file.DirectoryName -like "*blueprints*") -and
                -not $isGitHubLocal -and -not $isLearningLocal

                if ($isMainDocLocal) {
                    $warnings += "No frontmatter found in: $($file.FullName)"
                }
            }
        }
        catch {
            $errors += "Error processing file '$($file.FullName)': $($_.Exception.Message)"
            Write-Verbose "Error processing file '$($file.FullName)': $($_.Exception.Message)"
        }
    }

    # Output results
    $hasIssues = $false

    if ($warnings.Count -gt 0) {
        Write-Host "⚠️ Warnings found:" -ForegroundColor Yellow
        $warnings | ForEach-Object { Write-Host "  $_" -ForegroundColor Yellow }
        if ($WarningsAsErrors) {
            $hasIssues = $true
        }
    }

    if ($errors.Count -gt 0) {
        Write-Host "❌ Errors found:" -ForegroundColor Red
        $errors | ForEach-Object { Write-Host "  $_" -ForegroundColor Red }
        $hasIssues = $true
    }

    if (-not $hasIssues) {
        Write-Host "✅ Frontmatter validation completed successfully" -ForegroundColor Green
    }

    return @{
        Errors            = $errors
        Warnings          = $warnings
        HasIssues         = $hasIssues
        TotalFilesChecked = $markdownFiles.Count
    }
}

function Get-ChangedMarkdownFileGroup {
    <#
    .SYNOPSIS
    Gets list of changed markdown files from git diff.

    .DESCRIPTION
    Uses git diff to identify changed markdown files, with fallback strategies for different scenarios.

    .PARAMETER BaseBranch
    The base branch to compare against (default: origin/main).

    .OUTPUTS
    Returns array of file paths for changed markdown files.
    #>
    param(
        [Parameter(Mandatory = $false)]
        [string]$BaseBranch = "origin/main"
    )

    $changedMarkdownFiles = @()

    try {
        # Try to get changed files from the merge base
        $changedFiles = git diff --name-only $(git merge-base HEAD $BaseBranch) HEAD 2>$null
        if ($LASTEXITCODE -ne 0) {
            Write-Verbose "Merge base failed, trying HEAD~1"
            # Fallback to comparing with HEAD~1 if merge-base fails
            $changedFiles = git diff --name-only HEAD~1 HEAD 2>$null
            if ($LASTEXITCODE -ne 0) {
                Write-Verbose "HEAD~1 failed, trying staged/unstaged files"
                # Last fallback - get staged and unstaged files
                $changedFiles = git diff --name-only HEAD 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Warning "Unable to determine changed files from git"
                    return @()
                }
            }
        }

        # Filter for markdown files that exist and are not empty
        $changedMarkdownFiles = $changedFiles | Where-Object {
            -not [string]::IsNullOrEmpty($_) -and
            $_ -match '\.md$' -and
            (Test-Path $_ -PathType Leaf)
        }

        Write-Verbose "Found $($changedMarkdownFiles.Count) changed markdown files from git diff"
        $changedMarkdownFiles | ForEach-Object { Write-Verbose "  Changed: $_" }

        return $changedMarkdownFiles
    }
    catch {
        Write-Warning "Error getting changed files from git: $($_.Exception.Message)"
        return @()
    }
}

# Main execution
if ($MyInvocation.InvocationName -ne '.') {
    if ($ChangedFilesOnly) {
        $result = Test-FrontmatterValidation -ChangedFilesOnly -BaseBranch $BaseBranch -WarningsAsErrors:$WarningsAsErrors
    }
    elseif ($Files.Count -gt 0) {
        $result = Test-FrontmatterValidation -Files $Files -WarningsAsErrors:$WarningsAsErrors
    }
    else {
        $result = Test-FrontmatterValidation -Paths $Paths -WarningsAsErrors:$WarningsAsErrors
    }

    if ($result.HasIssues) {
        exit 1
    }
    else {
        Write-Host "✅ All frontmatter validation checks passed!" -ForegroundColor Green
        exit 0
    }
}
