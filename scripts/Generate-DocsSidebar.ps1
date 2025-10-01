#Requires -Version 5.1

<#
.SYNOPSIS
    Generate enhanced Docsify sidebar with Infrastructure Code documentation from src directory.

.DESCRIPTION
    This PowerShell script generates an enhanced Docsify sidebar with the following sections:
    - Enhanced main documentation with README.md ordering
    - Infrastructure Code section with Terraform documentation
    - Infrastructure Code section with Bicep documentation
    - Component Overview with cross-references

    Supports both single comprehensive sidebar generation and section-specific sidebar generation
    for multi-section navigation architecture.

.PARAMETER DocsPath
    Path to the docs directory. Defaults to '../docs'

.PARAMETER SrcPath
    Path to the src directory. Defaults to '../src'

.PARAMETER SidebarFile
    Output sidebar file. Defaults to '_sidebar.md' in docs directory

.PARAMETER Section
    Generate sidebar for specific section only. Valid values: 'all', 'docs', 'praxisworx', 'blueprints', 'infrastructure'
    When set to 'all' (default), generates comprehensive sidebar with all sections.
    When set to specific section, generates section-specific sidebar in docs/_parts/ folder.

.PARAMETER AllSections
    Generate all section-specific sidebars at once. Creates separate sidebar files for each section
    in the docs/_parts/ folder, plus the main comprehensive sidebar.

.EXAMPLE
    .\Generate-DocsSidebar.ps1

.EXAMPLE
    .\Generate-DocsSidebar.ps1 -DocsPath "C:\project\docs" -SrcPath "C:\project\src" -Verbose

.EXAMPLE
    .\Generate-DocsSidebar.ps1 -Section "docs"

.EXAMPLE
    .\Generate-DocsSidebar.ps1 -AllSections
#>

# Suppress PSScriptAnalyzer false positives - these parameters are actually used
# SidebarFile is used in: $sidebarFilePath = Join-Path $resolvedDocsPath $SidebarFile
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'SidebarFile')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'Section')]
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'AllSections')]
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DocsPath = '',

    [Parameter(Mandatory = $false)]
    [string]$SrcPath = '',

    [Parameter(Mandatory = $false)]
    [string]$SidebarFile = '_sidebar.md',

    [Parameter(Mandatory = $false)]
    [ValidateSet('all', 'docs', 'praxisworx', 'blueprints', 'infrastructure', 'home', 'copilot')]
    [string]$Section = 'all',

    [Parameter(Mandatory = $false)]
    [switch]$AllSections
)

# Auto-detect paths based on current directory
$currentDir = Get-Location
if ([string]::IsNullOrEmpty($DocsPath)) {
    if (Test-Path (Join-Path $currentDir "scripts")) {
        # Running from workspace root
        $DocsPath = './docs'
        $SrcPath = './src'
        Write-Verbose "Detected workspace root, using paths: docs='$DocsPath', src='$SrcPath'"
    } elseif (Test-Path (Join-Path $currentDir "../docs")) {
        # Running from scripts directory
        $DocsPath = '../docs'
        $SrcPath = '../src'
        Write-Verbose "Detected scripts directory, using paths: docs='$DocsPath', src='$SrcPath'"
    } else {
        # Default fallback
        $DocsPath = './docs'
        $SrcPath = './src'
        Write-Verbose "Using default paths: docs='$DocsPath', src='$SrcPath'"
    }
}

if ([string]::IsNullOrEmpty($SrcPath)) {
    if (Test-Path (Join-Path $currentDir "scripts")) {
        $SrcPath = './src'
    } else {
        $SrcPath = '../src'
    }
}

# Configuration
$ExcludeDirs = @('.git', 'node_modules', 'assets', 'media')
$ExcludeFiles = @('_sidebar.md', '_navbar.md', '_footer.md', '_404.md', 'coming-soon.md')
$PriorityFiles = @('index.md', 'overview.md', 'readme.md', 'introduction.md')

# Define the desired order for kata categories (used by multiple functions)
$KataOrder = @(
    'ai-assisted-engineering',
    'task-planning',
    'adr-creation',
    'prompt-engineering',
    'edge-deployment',
    'troubleshooting'
)

# Core Functions

function Get-MarkdownFile {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path $FilePath)) {
        # Only warn for unexpected file types, not directory scanning
        if ($FilePath -match '\.(md|txt|yml|yaml)$') {
            Write-Warning "File not found: $FilePath"
        } else {
            Write-Verbose "Directory not found (expected during scanning): $FilePath"
        }
        return $null
    }

    if (Test-Path $FilePath -PathType Container) {
        Write-Verbose "Skipping directory when reading markdown metadata: $FilePath"
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
                        } else {
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
            Frontmatter = $frontmatter
            FrontmatterEndIndex = $endIndex + 1
            Content = ($lines[($endIndex + 1)..($lines.Count - 1)] -join "`n")
        }
    }
    catch {
        Write-Warning "Error parsing frontmatter in ${FilePath}: $($_.Exception.Message)"
        return $null
    }
}

function Get-MarkdownFileList {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Path
    )    if (-not (Test-Path $Path)) {
        Write-Verbose "Path not found (expected during scanning): $Path"
        return @()
    }

    try {
        Get-ChildItem -Path $Path -Recurse -Filter "*.md" | Where-Object {
            $excludeFile = $false
            foreach ($exclude in $ExcludeFiles) {
                if ($_.Name -eq $exclude) {
                    $excludeFile = $true
                    break
                }
            }

            $excludeDir = $false
            foreach ($exclude in $ExcludeDirs) {
                # Use exact path segment matching instead of wildcard to avoid excluding .github when trying to exclude .git
                $pathSegments = $_.DirectoryName -split [IO.Path]::DirectorySeparatorChar
                if ($pathSegments -contains $exclude) {
                    $excludeDir = $true
                    break
                }
            }

            return -not ($excludeFile -or $excludeDir)
        }
    }
    catch {
        Write-Warning "Error reading files from $Path : $($_.Exception.Message)"
        return @()
    }
}

function Get-DisplayName {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    # Try to get title from frontmatter first
    $markdownFile = Get-MarkdownFile -FilePath $FilePath
    if ($markdownFile -and $markdownFile.Frontmatter -and $markdownFile.Frontmatter.ContainsKey('title')) {
        $title = $markdownFile.Frontmatter['title']
        if (-not [string]::IsNullOrWhiteSpace($title)) {
            return $title.Trim()
        }
    }

    # Fallback to generated display name
    $fileName = [System.IO.Path]::GetFileNameWithoutExtension($FilePath)

    # Remove numbered prefixes like 000-, 001-, 010-, etc.
    $cleanName = $fileName -replace '^\d{3,4}-', ''

    # Convert kebab-case and snake_case to Title Case
    $words = $cleanName -split '[-_]'
    $titleCase = ($words | ForEach-Object {
        (Get-Culture).TextInfo.ToTitleCase($_.ToLower())
    }) -join ' '

    return $titleCase
}

function Get-DocsifyRelativePath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$FilePath,
        [Parameter(Mandatory = $false)]
        [string]$RootPath
    )

    if ([string]::IsNullOrWhiteSpace($RootPath)) {
        $candidateDocsPath = [System.IO.Path]::GetFullPath([System.IO.Path]::Combine($PSScriptRoot, '..', 'docs'))

        if (-not (Test-Path -Path $candidateDocsPath)) {
            throw "RootPath not provided and default docs directory not found at '$candidateDocsPath'."
        }

        $RootPath = (Resolve-Path -Path $candidateDocsPath -ErrorAction Stop).Path
        Write-Verbose "RootPath not supplied; defaulting to $RootPath"
    }

    try {
        # For Docsify served from root, we need paths relative to the root directory
        $resolvedFile = Resolve-Path $FilePath -ErrorAction Stop
        $resolvedRoot = Resolve-Path $RootPath -ErrorAction Stop

        # Convert to relative path from root
        $relativePath = [System.IO.Path]::GetRelativePath($resolvedRoot, $resolvedFile)

        # Convert backslashes to forward slashes for web compatibility
        return $relativePath -replace '\\', '/'
    }
    catch {
        Write-Warning "Error creating Docsify relative path for $FilePath : $($_.Exception.Message)"
        return $FilePath
    }
}

function Convert-ToDocsifyHashRoute {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    if ([string]::IsNullOrWhiteSpace($RelativePath)) {
        return $RelativePath
    }

    $normalizedPath = $RelativePath -replace '\\', '/'
    $normalizedPath = $normalizedPath -replace '^\./', ''
    $normalizedPath = $normalizedPath -replace '^/+', ''
    $normalizedPath = $normalizedPath -replace '^(docs/)+', 'docs/'

    if ($normalizedPath.StartsWith('#/')) {
        return $normalizedPath
    }

    return "#/$normalizedPath"
}

function Get-ReadmeOrder {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ReadmePath
    )

    if (-not (Test-Path $ReadmePath)) {
        return @()
    }

    try {
        $content = Get-Content -Path $ReadmePath -Raw
        $order = @()

        # Look for markdown links in README content
        $linkPattern = '\[([^\]]+)\]\(([^)]+)\)'
        $linkMatches = [regex]::Matches($content, $linkPattern)

        foreach ($match in $linkMatches) {
            $title = $match.Groups[1].Value.Trim()
            $link = $match.Groups[2].Value.Trim()

            # Only include relative markdown links that are in the current directory
            # Exclude: URLs, absolute paths, parent directory paths
            if ($link -match '\.md$' -and $link -notmatch '^https?://' -and $link -notmatch '^/' -and -not $link.Contains('../')) {
                $cleanLink = $link -replace '^\./', '' -replace '^/', ''
                $order += @{
                    Title = $title
                    Link = $cleanLink
                    FileName = [System.IO.Path]::GetFileNameWithoutExtension($cleanLink)
                }
            }
        }

        if ($order.Count -gt 0) {
            Write-Verbose "📖 Found $($order.Count) navigation links in $(Split-Path $ReadmePath -Leaf)"
        }

        return $order
    }
    catch {
        Write-Warning "Error parsing README order from $ReadmePath : $($_.Exception.Message)"
        return @()
    }
}

function Get-SortedMarkdownFile {
    param(
        [Parameter(Mandatory = $true)]
        [array]$Files,
        [Parameter(Mandatory = $false)]
        [array]$ReadmeOrder = @()
    )

    if ($ReadmeOrder.Count -gt 0) {
        for ($i = 0; $i -lt $ReadmeOrder.Count; $i++) {
            # Processing readme order for debug if needed
        }
    }

    $sorted = $Files | Sort-Object {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($_.Name).ToLower()

        # Priority 1: Files with priority names (index, overview, etc.) - but index files should be handled separately
        $priorityIndex = -1
        for ($i = 0; $i -lt $PriorityFiles.Count; $i++) {
            $priorityFile = $PriorityFiles[$i] -replace '\.md$', ''
            if ($fileName -eq $priorityFile) {
                $priorityIndex = $i
                break
            }
        }
        if ($priorityIndex -ge 0) {
            Write-Host "DEBUG: $fileName matched priority file, sort key: 0000$priorityIndex" -ForegroundColor Yellow
            return "0000$priorityIndex"
        }

        # Priority 2: Files in README/index.md order (this is the key change)
        if ($ReadmeOrder.Count -gt 0) {
            $orderIndex = -1
            for ($i = 0; $i -lt $ReadmeOrder.Count; $i++) {
                $readmeFile = $ReadmeOrder[$i].FileName.ToLower()
                $readmeLink = $ReadmeOrder[$i].Link.ToLower()

                Write-Host "DEBUG: Comparing '$fileName' with readme entry '$readmeFile'" -ForegroundColor Gray

                # Use exact matching first
                if ($fileName -eq $readmeFile) {
                    $orderIndex = $i
                    Write-Host "DEBUG: ✅ EXACT MATCH found! $fileName == $readmeFile at index $i" -ForegroundColor Green
                    break
                }

                # Check if filename matches the link target exactly (without extension)
                $linkFileName = [System.IO.Path]::GetFileNameWithoutExtension($readmeLink).ToLower()
                if ($fileName -eq $linkFileName) {
                    $orderIndex = $i
                    Write-Host "DEBUG: ✅ LINK MATCH found! $fileName == $linkFileName (from link: $readmeLink) at index $i" -ForegroundColor Green
                    break
                }
            }
            if ($orderIndex -ge 0) {
                $sortKey = "001$(($orderIndex + 100).ToString().PadLeft(3, '0'))"
                Write-Host "DEBUG: $fileName from README order, sort key: $sortKey" -ForegroundColor Yellow
                return $sortKey
            } else {
                Write-Host "DEBUG: $fileName not found in README order" -ForegroundColor Red
            }
        }

        # Priority 3: Files with numbered prefixes
        if ($fileName -match '^(\d{3,4})-') {
            Write-Host "DEBUG: $fileName has numbered prefix, sort key: 002$($Matches[1])" -ForegroundColor Yellow
            return "002$($Matches[1])"
        }

        # Priority 4: Alphabetical order
        Write-Host "DEBUG: $fileName using alphabetical sort, sort key: 999$fileName" -ForegroundColor Yellow
        return "999$fileName"
    }

    return $sorted
}

function Build-MainSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DocsPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Verbose "Generating main documentation sidebar for root-level files: $DocsPath"

    # Only get root-level markdown files, excluding subdirectories and special files
    $specialFileNames = @("accessibility.md", "contributions.md", "tags.md")
    $rootFiles = Get-ChildItem -Path $DocsPath -Filter "*.md" | Where-Object {
        $excludeFile = $false

        # Check if it's in the exclude list
        foreach ($exclude in $ExcludeFiles) {
            if ($_.Name -eq $exclude) {
                $excludeFile = $true
                break
            }
        }

        # Check if it's a special file that should be handled separately
        foreach ($specialFile in $specialFileNames) {
            if ($_.Name -eq $specialFile) {
                $excludeFile = $true
                break
            }
        }

        return -not $excludeFile
    }

    if ($rootFiles.Count -eq 0) {
        Write-Warning "No root-level markdown files found in docs directory: $DocsPath"
        return ""
    }

    Write-Host "Found $($rootFiles.Count) root-level markdown files" -ForegroundColor Green

    # Debug: Show all files found
    Write-Host "Root-level files found:" -ForegroundColor Yellow
    foreach ($file in $rootFiles) {
        $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
        Write-Host "  $relativePath" -ForegroundColor Cyan
    }

    # Get README order if it exists
    $readmePath = Join-Path $DocsPath "README.md"
    $readmeOrder = Get-ReadmeOrder -ReadmePath $readmePath

    $sidebar = ""

    # Separate root level files into index/readme and others
    $indexFile = $null
    $otherRootFiles = @()

    foreach ($file in $rootFiles) {
        $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name).ToLower()
        if ($fileName -eq 'index' -or $fileName -eq 'readme') {
            $indexFile = $file
            Write-Verbose "Found index/readme file: $($file.Name)"
        } else {
            $otherRootFiles += $file
            Write-Verbose "Found other root file: $($file.Name)"
        }
    }

    # Add index/readme file at the top if it exists
    if ($indexFile) {
        $displayName = Get-DisplayName -FilePath $indexFile.FullName
        $relativePath = Get-DocsifyRelativePath -FilePath $indexFile.FullName -RootPath $RootPath
        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
        $sidebar += "- [$displayName]($docsifyLink)`n"
        Write-Verbose "Added index file at top: $displayName"
    }

    # Add other root level files
    if ($otherRootFiles.Count -gt 0) {
        Write-Verbose "Adding $($otherRootFiles.Count) other root files"
        $sortedOtherRootFiles = Get-SortedMarkdownFile -Files $otherRootFiles -ReadmeOrder $readmeOrder
        foreach ($file in $sortedOtherRootFiles) {
            $displayName = Get-DisplayName -FilePath $file.FullName
            $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
            $sidebar += "- [$displayName]($docsifyLink)`n"
            Write-Verbose "Added root file: $displayName"
        }
    }

    return $sidebar
}

function Build-HierarchicalSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [hashtable]$Hierarchy,
        [Parameter(Mandatory = $true)]
        [string]$DocsPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $false)]
        [array]$ReadmeOrder = @(),
        [Parameter(Mandatory = $false)]
        [int]$Level = 0
    )

    $sidebar = ""
    $indent = "  " * $Level

    # Sort directories by name, with prioritized ones first
    $sortedDirs = $Hierarchy.Keys | Sort-Object {
        $name = $_

        # Priority handling for numbered prefixes
        if ($name -match '^(\d{3,4})-') {
            return "000$($Matches[1])"
        }

        # Priority for common section names
        $prioritySections = @('getting-started', 'overview', 'introduction', 'build-cicd')
        $priorityIndex = $prioritySections.IndexOf($name.ToLower())
        if ($priorityIndex -ge 0) {
            return "001$(($priorityIndex + 100).ToString().PadLeft(3, '0'))"
        }

        return "999$name"
    }

    foreach ($dirName in $sortedDirs) {
        $dirData = $Hierarchy[$dirName]
        $displayName = Get-DisplayName -FilePath $dirName

        Write-Verbose "Level $Level - Processing directory '$dirName' (Files: $($dirData.Files.Count), Subdirs: $($dirData.Subdirs.Keys.Count))"

        # Find index.md or README.md file in this directory for section ordering
        $indexFile = $null
        $otherFiles = @()

        foreach ($file in $dirData.Files) {
            $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file.Name).ToLower()
            if ($fileName -eq 'index' -or $fileName -eq 'readme') {
                $indexFile = $file
            } else {
                $otherFiles += $file
            }
        }

        # Get ordering from the folder's index.md file
        $folderReadmeOrder = @()
        if ($indexFile) {
            $folderReadmeOrder = Get-ReadmeOrder -ReadmePath $indexFile.FullName
        }

        # Add section header for directories that contain files or subdirectories
        if ($dirData.Files.Count -gt 0 -or $dirData.Subdirs.Keys.Count -gt 0) {
            # If there's an index file, use it as the section title link, otherwise just plain header
            if ($indexFile) {
                $relativePath = Get-DocsifyRelativePath -FilePath $indexFile.FullName -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "$indent- [$displayName]($docsifyLink)`n"
            } else {
                $sidebar += "$indent- $displayName`n"
            }
        }

        # Add other files in the section (excluding the index file which is now the header)
        if ($otherFiles.Count -gt 0) {
            $sortedFiles = Get-SortedMarkdownFile -Files $otherFiles -ReadmeOrder $folderReadmeOrder

            foreach ($file in $sortedFiles) {
                $fileDisplayName = Get-DisplayName -FilePath $file.FullName
                $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath

                # Indent files under section headers
                $fileIndent = $indent + "  "
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "$fileIndent- [$fileDisplayName]($docsifyLink)`n"
                Write-Verbose "Level $Level - Added file '$fileDisplayName'"
            }
        }

        # Recursively add subdirectories with increased indentation
        if ($dirData.Subdirs.Keys.Count -gt 0) {
            Write-Verbose "Level $Level - Recursing into $($dirData.Subdirs.Keys.Count) subdirectories: $($dirData.Subdirs.Keys -join ', ')"
            $sidebar += Build-HierarchicalSidebar -Hierarchy $dirData.Subdirs -DocsPath $DocsPath -RootPath $RootPath -ReadmeOrder $ReadmeOrder -Level ($Level + 1)
        }
    }

    return $sidebar
}

function Build-TerraformSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SrcPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Verbose "Generating Terraform documentation sidebar"

    $terraformDirs = Get-ChildItem -Path $SrcPath -Recurse -Directory | Where-Object {
        $_.Name -eq "terraform"
    }

    if ($terraformDirs.Count -eq 0) {
        Write-Warning "No Terraform directories found in: $SrcPath"
        return ""
    }

    $sidebar = ""

    foreach ($dir in $terraformDirs | Sort-Object FullName) {
        $readmeFile = Join-Path $dir.FullName "README.md"
        if (Test-Path $readmeFile) {
            $componentName = Split-Path (Split-Path $dir.FullName -Parent) -Leaf
            $displayName = Get-DisplayName -FilePath $componentName
            $relativePath = Get-DocsifyRelativePath -FilePath $readmeFile -RootPath $RootPath
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
            $sidebar += "  - [$displayName]($docsifyLink)`n"

            # Check for terraform/modules subdirectory
            $modulesDir = Join-Path $dir.FullName "modules"
            if (Test-Path $modulesDir -PathType Container) {
                Write-Verbose "Found terraform modules directory: $modulesDir"
                $sidebar += Add-TerraformModulesSidebar -ModulesPath $modulesDir -RootPath $RootPath -IndentLevel 2
            }
        }
    }

    return $sidebar
}

function Add-TerraformModulesSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulesPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [int]$IndentLevel
    )

    $modulesSidebar = ""
    $moduleContent = ""
    $indent = "  " * $IndentLevel

    # Scan for individual module subdirectories
    $moduleSubdirs = Get-ChildItem -Path $ModulesPath -Directory | Sort-Object Name

    if ($moduleSubdirs.Count -gt 0) {
        foreach ($moduleDir in $moduleSubdirs) {
            $moduleReadme = Join-Path $moduleDir.FullName "README.md"
            if (Test-Path $moduleReadme) {
                $moduleName = $moduleDir.Name
                $moduleDisplayName = Get-DisplayName -FilePath $moduleName
                $moduleRelativePath = Get-DocsifyRelativePath -FilePath $moduleReadme -RootPath $RootPath
                $moduleLink = Convert-ToDocsifyHashRoute -RelativePath $moduleRelativePath
                $moduleContent += "$indent- [$moduleDisplayName]($moduleLink)`n"
            }
        }
    }

    # Add module content directly without header
    if ($moduleContent -ne "") {
        $modulesSidebar += $moduleContent
    }

    return $modulesSidebar
}

function Build-BicepSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SrcPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Verbose "Generating Bicep documentation sidebar"

    $bicepDirs = Get-ChildItem -Path $SrcPath -Recurse -Directory | Where-Object {
        $_.Name -eq "bicep"
    }

    if ($bicepDirs.Count -eq 0) {
        Write-Warning "No Bicep directories found in: $SrcPath"
        return ""
    }

    $sidebar = ""

    foreach ($dir in $bicepDirs | Sort-Object FullName) {
        $readmeFile = Join-Path $dir.FullName "README.md"
        if (Test-Path $readmeFile) {
            $componentName = Split-Path (Split-Path $dir.FullName -Parent) -Leaf
            $displayName = Get-DisplayName -FilePath $componentName
            $relativePath = Get-DocsifyRelativePath -FilePath $readmeFile -RootPath $RootPath
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
            $sidebar += "  - [$displayName]($docsifyLink)`n"

            # Check for bicep/modules subdirectory
            $modulesDir = Join-Path $dir.FullName "modules"
            if (Test-Path $modulesDir -PathType Container) {
                Write-Verbose "Found bicep modules directory: $modulesDir"
                $sidebar += Add-BicepModulesSidebar -ModulesPath $modulesDir -RootPath $RootPath -IndentLevel 2
            }
        }
    }

    return $sidebar
}

function Add-BicepModulesSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$ModulesPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath,
        [Parameter(Mandatory = $true)]
        [int]$IndentLevel
    )

    $modulesSidebar = ""
    $moduleContent = ""
    $indent = "  " * $IndentLevel

    # Check for .bicep files that would cause 404 errors in Docsify (silently skip them)
    $bicepFiles = Get-ChildItem -Path $ModulesPath -Filter "*.bicep" -File
    if ($bicepFiles.Count -gt 0) {
        foreach ($bicepFile in $bicepFiles) {
            Write-Verbose "Skipping direct link to bicep file: $($bicepFile.Name)"
        }
    }

    # Scan for subdirectories with README.md files (proper documentation approach)
    $moduleSubdirs = Get-ChildItem -Path $ModulesPath -Directory | Sort-Object Name

    if ($moduleSubdirs.Count -gt 0) {
        foreach ($moduleDir in $moduleSubdirs) {
            $moduleReadme = Join-Path $moduleDir.FullName "README.md"
            if (Test-Path $moduleReadme) {
                $moduleName = $moduleDir.Name
                $moduleDisplayName = Get-DisplayName -FilePath $moduleName
                $moduleRelativePath = Get-DocsifyRelativePath -FilePath $moduleReadme -RootPath $RootPath
                $moduleLink = Convert-ToDocsifyHashRoute -RelativePath $moduleRelativePath
                $moduleContent += "$indent- [$moduleDisplayName]($moduleLink)`n"
            } else {
                Write-Verbose "Module directory $($moduleDir.Name) found but no README.md exists for documentation"
            }
        }
    }

    # Add module content only if we have valid documentation
    if ($moduleContent -ne "") {
        $modulesSidebar += $moduleContent
    } else {
        Write-Verbose "No documentable modules found in $ModulesPath (modules need README.md files)"
    }

    return $modulesSidebar
}

function Build-ComponentsSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SrcPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Verbose "Generating Components overview sidebar"

    # Auto-discover all component README files in src directory
    # Find all README.md files but exclude terraform/ and bicep/ subdirectories
    $allReadmeFiles = Get-ChildItem -Path $SrcPath -Filter "README.md" -Recurse | Where-Object {
        $relativePath = $_.FullName -replace [regex]::Escape($SrcPath), ''
        $relativePath = $relativePath.TrimStart('\', '/') -replace '\\', '/'

        # Exclude terraform and bicep subdirectories
        $relativePath -notmatch '/terraform/' -and $relativePath -notmatch '/bicep/' -and
        # Exclude ci directories
        $relativePath -notmatch '/ci/'
    }

    $sidebar = ""
    $foundComponents = 0

    # Sort README files by their path for consistent ordering
    $sortedReadmeFiles = $allReadmeFiles | Sort-Object {
        $relativePath = $_.FullName -replace [regex]::Escape($SrcPath), ''
        $relativePath = $relativePath.TrimStart('\', '/') -replace '\\', '/'

        # Root README.md comes first
        if ($relativePath -eq "README.md") { return "000" }

        # Then numbered components (000-cloud, 100-edge, etc.)
        if ($relativePath -match '^(\d{3})-') { return "001$($Matches[1])" }

        # Then numbered sub-components (010-security, 020-observability, etc.)
        if ($relativePath -match '/(\d{3})-[^/]+/README\.md$') { return "002$($Matches[1])" }

        # Then other components alphabetically
        return "999$relativePath"
    }

    foreach ($readmeFile in $sortedReadmeFiles) {
        $relativePath = $readmeFile.FullName -replace [regex]::Escape($SrcPath), ''
        $relativePath = $relativePath.TrimStart('\', '/') -replace '\\', '/'

        # Generate display name from the path
        $displayName = ""
        if ($relativePath -eq "README.md") {
            $displayName = "Source Code Overview"
        } else {
            # Extract component name from path and create display name
            $pathParts = $relativePath -split '/'
            if ($pathParts.Count -ge 2) {
                $componentName = $pathParts[-2]  # Get parent directory name
                $displayName = Get-DisplayName -FilePath $componentName
            } else {
                $displayName = Get-DisplayName -FilePath ([System.IO.Path]::GetFileNameWithoutExtension($relativePath))
            }
        }

        $docsifyPath = Get-DocsifyRelativePath -FilePath $readmeFile.FullName -RootPath $RootPath
        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $docsifyPath
        $sidebar += "  - [$displayName]($docsifyLink)`n"
        $foundComponents++
        Write-Verbose "Auto-discovered component: $displayName at $relativePath"
    }

    if ($foundComponents -eq 0) {
        Write-Warning "No component README files found in: $SrcPath"
        return ""
    }

    Write-Host "Added $foundComponents component README files to sidebar" -ForegroundColor Green

    return $sidebar
}

function Build-DynamicDocsSection {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DocsPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Host "📁 Generating dynamic documentation sections..." -ForegroundColor Yellow

    $dynamicSections = ""

    # Get all directories under docs (excluding special ones)
    $excludeDirectories = @('assets', 'media', '.git')
    $docsDirectories = Get-ChildItem -Path $DocsPath -Directory | Where-Object {
        $_.Name -notin $excludeDirectories
    } | Sort-Object {
        $name = $_.Name

        # Priority for numbered prefixes
        if ($name -match '^(\d{3})-') {
            return "000$($Matches[1])"
        }

        # Priority for common section names
        $prioritySections = @('getting-started', 'build-cicd', 'contributing', 'observability', 'project-planning')
        $priorityIndex = $prioritySections.IndexOf($name.ToLower())
        if ($priorityIndex -ge 0) {
            return "001$(($priorityIndex + 100).ToString().PadLeft(3, '0'))"
        }

        return "999$name"
    }

    foreach ($directory in $docsDirectories) {
        $displayName = Get-DisplayName -FilePath $directory.Name
        Write-Host "� Processing docs section: $displayName" -ForegroundColor Cyan

        $dynamicSections += "- $displayName`n"
        $dynamicSections += Build-ComponentsSidebar -SrcPath $directory.FullName -RootPath $rootPath
        $dynamicSections += Build-BicepSidebar -SrcPath $directory.FullName -RootPath $rootPath
        $dynamicSections += Build-TerraformSidebar -SrcPath $directory.FullName -RootPath $rootPath
    }

    return $dynamicSections
}

function Build-SpecialFilesSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$DocsPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Host "📄 Adding special documentation files..." -ForegroundColor Yellow

    $specialSidebar = ""
    $specialFiles = @(
        @{ Name = "accessibility.md"; DisplayName = "Accessibility" },
        @{ Name = "contributions.md"; DisplayName = "Contributions" },
        @{ Name = "tags.md"; DisplayName = "Tags" }
    )

    foreach ($specialFile in $specialFiles) {
        $filePath = Join-Path $DocsPath $specialFile.Name
        if (Test-Path $filePath) {
            $relativePath = Get-DocsifyRelativePath -FilePath $filePath -RootPath $RootPath
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
            $specialSidebar += "- [$($specialFile.DisplayName)]($docsifyLink)`n"
            Write-Verbose "Added special file: $($specialFile.DisplayName)"
        }
    }

    return $specialSidebar
}

function Build-PraxisWorxSectionSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SectionPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Host "📚 Processing PraxisWorx section with custom ordering..." -ForegroundColor Cyan

    $sidebar = ""

    if (-not (Test-Path $SectionPath)) {
        Write-Verbose "Section path not found: $SectionPath"
        return $sidebar
    }

    # Get markdown files directly in the section root (excluding index/readme)
    $rootFiles = Get-ChildItem -Path $SectionPath -Filter "*.md" | Where-Object {
        $_.Name -notmatch '^(index|readme)\.md$'
    } | Sort-Object Name

    foreach ($file in $rootFiles) {
        $displayName = Get-DisplayName -FilePath $file.FullName
        $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
        $sidebar += "  - [$displayName]($docsifyLink)`n"
    }

    # Define the desired order for PraxisWorx sections
    $praxisWorxOrder = @(
        'getting-started',
        'katas',
        'training-labs',
        'shared'
    )

    # Process subdirectories with custom PraxisWorx ordering
    $subdirectories = Get-ChildItem -Path $SectionPath -Directory

    # Sort subdirectories according to PraxisWorx order, with fallback to alphabetical
    $sortedSubdirs = $subdirectories | Sort-Object {
        $dirName = $_.Name.ToLower()
        $index = $praxisWorxOrder.IndexOf($dirName)
        if ($index -ge 0) {
            $index
        } else {
            1000 + $_.Name  # Fallback to alphabetical for unlisted directories
        }
    }

    foreach ($subdir in $sortedSubdirs) {
        $subdirDisplayName = Get-DisplayName -FilePath $subdir.Name

        # Check if subdirectory has README.md to use as section header
        $readmeFile = Get-ChildItem -Path $subdir.FullName -Filter "README.md" -ErrorAction SilentlyContinue
        if ($readmeFile) {
            # Use README.md as linked section header
            $relativePath = Get-DocsifyRelativePath -FilePath $readmeFile.FullName -RootPath $RootPath
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
            $sidebar += "  - [$subdirDisplayName]($docsifyLink)`n"
        } else {
            # Use plain text section header
            $sidebar += "  - $subdirDisplayName`n"
        }

        # Get files in this subdirectory (non-recursive, single level)
        $subdirFiles = Get-ChildItem -Path $subdir.FullName -Filter "*.md" | Where-Object {
            $_.Name -notmatch '^(index|readme)\.md$'
        } | Sort-Object Name

        foreach ($file in $subdirFiles) {
            $fileDisplayName = Get-DisplayName -FilePath $file.FullName
            $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
            $sidebar += "    - [$fileDisplayName]($docsifyLink)`n"
        }

        # Process nested subdirectories (for deeper hierarchy)
        # Apply custom ordering for kata categories when in 'katas' directory
        $nestedSubdirs = if ($subdir.Name.ToLower() -eq 'katas') {
            Get-ChildItem -Path $subdir.FullName -Directory | Sort-Object {
                $dirName = $_.Name.ToLower()
                $index = $KataOrder.IndexOf($dirName)
                if ($index -ge 0) {
                    $index
                } else {
                    1000 + $_.Name  # Fallback to alphabetical for unlisted kata categories
                }
            }
        } else {
            Get-ChildItem -Path $subdir.FullName -Directory | Sort-Object Name
        }
        foreach ($nestedSubdir in $nestedSubdirs) {
            $nestedSubdirDisplayName = Get-DisplayName -FilePath $nestedSubdir.Name

            # Check if nested subdirectory has README.md
            $nestedReadmeFile = Get-ChildItem -Path $nestedSubdir.FullName -Filter "README.md" -ErrorAction SilentlyContinue
            if ($nestedReadmeFile) {
                $relativePath = Get-DocsifyRelativePath -FilePath $nestedReadmeFile.FullName -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "    - [$nestedSubdirDisplayName]($docsifyLink)`n"
            } else {
                $sidebar += "    - $nestedSubdirDisplayName`n"
            }

            # Get files in nested subdirectory
            $nestedFiles = Get-ChildItem -Path $nestedSubdir.FullName -Filter "*.md" | Where-Object {
                $_.Name -notmatch '^(index|readme)\.md$'
            } | Sort-Object Name

            foreach ($file in $nestedFiles) {
                $fileDisplayName = Get-DisplayName -FilePath $file.FullName
                $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "      - [$fileDisplayName]($docsifyLink)`n"
            }
        }
    }

    return $sidebar
}

function Build-DocsSectionSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SectionPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath    )

    Write-Host "📚 Processing docs section: $(Split-Path $SectionPath -Leaf)" -ForegroundColor Cyan

    $sidebar = ""

    if (-not (Test-Path $SectionPath)) {
        Write-Verbose "Section path not found: $SectionPath"
        return $sidebar
    }

    # Get markdown files directly in the section root (excluding index/readme)
    $rootFiles = Get-ChildItem -Path $SectionPath -Filter "*.md" | Where-Object {
        $_.Name -notmatch '^(index|readme)\.md$'
    } | Sort-Object Name

    foreach ($file in $rootFiles) {
        $displayName = Get-DisplayName -FilePath $file.FullName
        $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
        $sidebar += "  - [$displayName]($docsifyLink)`n"
    }

    # Process subdirectories and create proper nested structure
    $subdirectories = Get-ChildItem -Path $SectionPath -Directory | Sort-Object Name
    foreach ($subdir in $subdirectories) {
        $subdirDisplayName = Get-DisplayName -FilePath $subdir.Name

        # Check if subdirectory has README.md to use as section header
        $readmeFile = Get-ChildItem -Path $subdir.FullName -Filter "README.md" -ErrorAction SilentlyContinue
        if ($readmeFile) {
            # Use README.md as linked section header
            $relativePath = Get-DocsifyRelativePath -FilePath $readmeFile.FullName -RootPath $RootPath
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
            $sidebar += "  - [$subdirDisplayName]($docsifyLink)`n"
        } else {
            # Use plain text section header
            $sidebar += "  - $subdirDisplayName`n"
        }

        # Get files in this subdirectory (non-recursive, single level)
        $subdirFiles = Get-ChildItem -Path $subdir.FullName -Filter "*.md" | Where-Object {
            $_.Name -notmatch '^(index|readme)\.md$'
        } | Sort-Object Name

        foreach ($file in $subdirFiles) {
            $fileDisplayName = Get-DisplayName -FilePath $file.FullName
            $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
            $sidebar += "    - [$fileDisplayName]($docsifyLink)`n"
        }

        # Process nested subdirectories (for deeper hierarchy)
        # Apply custom ordering for kata categories when in 'katas' directory
        $nestedSubdirs = if ($subdir.Name.ToLower() -eq 'katas') {
            Get-ChildItem -Path $subdir.FullName -Directory | Sort-Object {
                $dirName = $_.Name.ToLower()
                $index = $KataOrder.IndexOf($dirName)
                if ($index -ge 0) {
                    $index
                } else {
                    1000 + $_.Name  # Fallback to alphabetical for unlisted kata categories
                }
            }
        } else {
            Get-ChildItem -Path $subdir.FullName -Directory | Sort-Object Name
        }
        foreach ($nestedSubdir in $nestedSubdirs) {
            $nestedSubdirDisplayName = Get-DisplayName -FilePath $nestedSubdir.Name

            # Check if nested subdirectory has README.md
            $nestedReadmeFile = Get-ChildItem -Path $nestedSubdir.FullName -Filter "README.md" -ErrorAction SilentlyContinue
            if ($nestedReadmeFile) {
                $relativePath = Get-DocsifyRelativePath -FilePath $nestedReadmeFile.FullName -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "    - [$nestedSubdirDisplayName]($docsifyLink)`n"
            } else {
                $sidebar += "    - $nestedSubdirDisplayName`n"
            }

            # Get files in nested subdirectory
            $nestedFiles = Get-ChildItem -Path $nestedSubdir.FullName -Filter "*.md" | Where-Object {
                $_.Name -notmatch '^(index|readme)\.md$'
            } | Sort-Object Name

            foreach ($file in $nestedFiles) {
                $fileDisplayName = Get-DisplayName -FilePath $file.FullName
                $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "      - [$fileDisplayName]($docsifyLink)`n"
            }
        }
    }

    return $sidebar
}

function Build-GitHubResourcesSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Host "🔗 Generating GitHub Copilot Resources section..." -ForegroundColor Yellow

    $githubPath = Join-Path $RootPath ".github"
    $sidebar = ""

    if (-not (Test-Path $githubPath)) {
        Write-Verbose "GitHub directory not found: $githubPath"
        return $sidebar
    }

    # Check for .github index file
    $githubIndex = Join-Path $githubPath "README.md"
    if (Test-Path $githubIndex) {
        $relativePath = Get-DocsifyRelativePath -FilePath $githubIndex -RootPath $RootPath
        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
        $sidebar += "- [GitHub Copilot Resources]($docsifyLink)`n"
    } else {
        $sidebar += "- GitHub Copilot Resources`n"
    }

    # Process GitHub subdirectories in logical order with proper subsections
    # Exclude 'workflows' and 'ISSUE_TEMPLATE' from the sidebar generation
    $githubSubdirs = @('prompts', 'chatmodes', 'instructions')

    foreach ($subdirName in $githubSubdirs) {
        $subdirPath = Join-Path $githubPath $subdirName
        if (Test-Path $subdirPath) {
            $subdirDisplayName = switch ($subdirName) {
                'prompts' { 'AI Prompts' }
                'chatmodes' { 'Chat Modes' }
                'instructions' { 'Instructions' }
                default { Get-DisplayName -FilePath $subdirName }
            }

            # Check if subdirectory has README.md
            $readmeFile = Get-ChildItem -Path $subdirPath -Filter "README.md" -ErrorAction SilentlyContinue
            if ($readmeFile) {
                $relativePath = Get-DocsifyRelativePath -FilePath $readmeFile.FullName -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "  - [$subdirDisplayName]($docsifyLink)`n"
            } else {
                $sidebar += "  - $subdirDisplayName`n"
            }

            # Get markdown files in this subdirectory
            $subdirFiles = Get-ChildItem -Path $subdirPath -Filter "*.md" | Where-Object {
                $_.Name -notmatch '^(index|readme)\.md$'
            } | Sort-Object Name

            foreach ($file in $subdirFiles) {
                $fileDisplayName = Get-DisplayName -FilePath $file.FullName
                # Handle special file extensions - clean up the display names
                $fileDisplayName = $fileDisplayName -replace '\.Prompt$', '' -replace '\.Chatmode$', '' -replace '\.Instructions$', ''
                $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "    - [$fileDisplayName]($docsifyLink)`n"
            }
        }
    }

    # Add any root-level .github files (excluding README.md) with proper subsection
    $githubRootFiles = Get-ChildItem -Path $githubPath -Filter "*.md" | Where-Object {
        $_.Name -notmatch '^(index|readme)\.md$'
    } | Sort-Object Name

    if ($githubRootFiles.Count -gt 0) {
        $sidebar += "  - General Resources`n"
        foreach ($file in $githubRootFiles) {
            $fileDisplayName = Get-DisplayName -FilePath $file.FullName
            $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
            $sidebar += "    - [$fileDisplayName]($docsifyLink)`n"
        }
    }

    return $sidebar
}

function Build-CopilotGuidesSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Host "🤖 Generating Copilot Guides section..." -ForegroundColor Yellow

    $copilotPath = Join-Path $RootPath "copilot"
    $sidebar = ""

    if (-not (Test-Path $copilotPath)) {
        Write-Verbose "Copilot directory not found: $copilotPath"
        return $sidebar
    }

    # Check for copilot index file
    $copilotIndex = Join-Path $copilotPath "README.md"
    if (Test-Path $copilotIndex) {
        $relativePath = Get-DocsifyRelativePath -FilePath $copilotIndex -RootPath $RootPath
        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
        $sidebar += "- [Copilot Guides]($docsifyLink)`n"
    } else {
        $sidebar += "- Copilot Guides`n"
    }

    # Process root-level copilot files first
    $copilotRootFiles = Get-ChildItem -Path $copilotPath -Filter "*.md" | Where-Object {
        $_.Name -notmatch '^(index|readme)\.md$'
    } | Sort-Object Name

    foreach ($file in $copilotRootFiles) {
        $fileDisplayName = Get-DisplayName -FilePath $file.FullName
        $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
        $sidebar += "  - [$fileDisplayName]($docsifyLink)`n"
    }

    # Process framework subdirectories in logical order
    $frameworkOrder = @('bash', 'bicep', 'csharp', 'terraform')

    foreach ($frameworkName in $frameworkOrder) {
        $frameworkPath = Join-Path $copilotPath $frameworkName
        if (Test-Path $frameworkPath) {
            $frameworkDisplayName = switch ($frameworkName) {
                'bash' { 'Bash/Shell' }
                'bicep' { 'Bicep' }
                'csharp' { 'C#/.NET' }
                'terraform' { 'Terraform' }
                default { (Get-Culture).TextInfo.ToTitleCase($frameworkName) }
            }

            # Check if framework directory has README.md
            $readmeFile = Get-ChildItem -Path $frameworkPath -Filter "README.md" -ErrorAction SilentlyContinue
            if ($readmeFile) {
                $relativePath = Get-DocsifyRelativePath -FilePath $readmeFile.FullName -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "  - [$frameworkDisplayName]($docsifyLink)`n"
            } else {
                $sidebar += "  - $frameworkDisplayName`n"
            }

            # Get markdown files in this framework directory
            $frameworkFiles = Get-ChildItem -Path $frameworkPath -Filter "*.md" | Where-Object {
                $_.Name -notmatch '^(index|readme)\.md$'
            } | Sort-Object Name

            foreach ($file in $frameworkFiles) {
                $fileDisplayName = Get-DisplayName -FilePath $file.FullName
                $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebar += "    - [$fileDisplayName]($docsifyLink)`n"
            }
        }
    }

    return $sidebar
}

function Build-SectionSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SectionName,
        [Parameter(Mandatory = $true)]
        [string]$DocsPath,
        [Parameter(Mandatory = $true)]
        [string]$SrcPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

    Write-Host "📝 Generating $SectionName section sidebar..." -ForegroundColor Yellow

    $sidebarContent = ""

    switch ($SectionName.ToLower()) {
        'docs' {
            # Documentation section sidebar
            Write-Host "🚀 Processing Documentation section..." -ForegroundColor Cyan

            # Main documentation section
            $mainSidebar = Build-MainSidebar -DocsPath $DocsPath -RootPath $RootPath

            # Getting Started section
            $gettingStartedPath = Join-Path $DocsPath "getting-started"
            $gettingStartedSidebar = ""
            if (Test-Path $gettingStartedPath) {
                $gettingStartedIndex = Join-Path $gettingStartedPath "index.md"
                $gettingStartedReadme = Join-Path $gettingStartedPath "README.md"
                if (Test-Path $gettingStartedIndex) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $gettingStartedIndex -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $gettingStartedSidebar += "- [Getting Started]($docsifyLink)`n"
                } elseif (Test-Path $gettingStartedReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $gettingStartedReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $gettingStartedSidebar += "- [Getting Started]($docsifyLink)`n"
                } else {
                    $gettingStartedSidebar += "- Getting Started`n"
                }
                $gettingStartedSidebar += Build-DocsSectionSidebar -SectionPath $gettingStartedPath -RootPath $RootPath
            }

            # Project Planning section
            $projectPlanningPath = Join-Path $DocsPath "project-planning"
            $projectPlanningSidebar = ""
            if (Test-Path $projectPlanningPath) {
                $projectPlanningReadme = Join-Path $projectPlanningPath "README.md"
                if (Test-Path $projectPlanningReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $projectPlanningReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $projectPlanningSidebar += "- [Project Planning]($docsifyLink)`n"
                } else {
                    $projectPlanningSidebar += "- Project Planning`n"
                }
                $projectPlanningSidebar += Build-DocsSectionSidebar -SectionPath $projectPlanningPath -RootPath $RootPath
            }

            # Contributing section
            $contributingPath = Join-Path $DocsPath "contributing"
            $contributingSidebar = ""
            if (Test-Path $contributingPath) {
                $contributingIndex = Join-Path $contributingPath "index.md"
                if (Test-Path $contributingIndex) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $contributingIndex -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $contributingSidebar += "- [Contributing]($docsifyLink)`n"
                } else {
                    $contributingSidebar += "- Contributing`n"
                }
                $contributingSidebar += Build-DocsSectionSidebar -SectionPath $contributingPath -RootPath $RootPath
            }

            # Solution libraries
            $solutionAdrPath = Join-Path $DocsPath "solution-adr-library"
            $solutionAdrSidebar = ""
            if (Test-Path $solutionAdrPath) {
                $solutionAdrReadme = Join-Path $solutionAdrPath "README.md"
                if (Test-Path $solutionAdrReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $solutionAdrReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $solutionAdrSidebar += "- [Solution ADR Library]($docsifyLink)`n"
                } else {
                    $solutionAdrSidebar += "- Solution ADR Library`n"
                }
                $solutionAdrSidebar += Build-DocsSectionSidebar -SectionPath $solutionAdrPath -RootPath $RootPath
            }

            $solutionSecurityPath = Join-Path $DocsPath "solution-security-plan-library"
            $solutionSecuritySidebar = ""
            if (Test-Path $solutionSecurityPath) {
                $solutionSecurityReadme = Join-Path $solutionSecurityPath "README.md"
                if (Test-Path $solutionSecurityReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $solutionSecurityReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $solutionSecuritySidebar += "- [Solution Security Plan Library]($docsifyLink)`n"
                } else {
                    $solutionSecuritySidebar += "- Solution Security Plan Library`n"
                }
                $solutionSecuritySidebar += Build-DocsSectionSidebar -SectionPath $solutionSecurityPath -RootPath $RootPath
            }

            $solutionTechPath = Join-Path $DocsPath "solution-technology-paper-library"
            $solutionTechSidebar = ""
            if (Test-Path $solutionTechPath) {
                $solutionTechReadme = Join-Path $solutionTechPath "README.md"
                if (Test-Path $solutionTechReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $solutionTechReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $solutionTechSidebar += "- [Solution Technology Paper Library]($docsifyLink)`n"
                } else {
                    $solutionTechSidebar += "- Solution Technology Paper Library`n"
                }
                $solutionTechSidebar += Build-DocsSectionSidebar -SectionPath $solutionTechPath -RootPath $RootPath
            }

            # Observability and Build CI/CD sections
            $observabilityPath = Join-Path $DocsPath "observability"
            $observabilitySidebar = ""
            if (Test-Path $observabilityPath) {
                $observabilityIndex = Join-Path $observabilityPath "index.md"
                if (Test-Path $observabilityIndex) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $observabilityIndex -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $observabilitySidebar += "- [Observability]($docsifyLink)`n"
                } else {
                    $observabilitySidebar += "- Observability`n"
                }
                $observabilitySidebar += Build-DocsSectionSidebar -SectionPath $observabilityPath -RootPath $RootPath
            }

            $buildCicdPath = Join-Path $DocsPath "build-cicd"
            $buildCicdSidebar = ""
            if (Test-Path $buildCicdPath) {
                $buildCicdIndex = Join-Path $buildCicdPath "index.md"
                if (Test-Path $buildCicdIndex) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $buildCicdIndex -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $buildCicdSidebar += "- [Build CI/CD]($docsifyLink)`n"
                } else {
                    $buildCicdSidebar += "- Build CI/CD`n"
                }
                $buildCicdSidebar += Build-DocsSectionSidebar -SectionPath $buildCicdPath -RootPath $RootPath
            }

            # GitHub Resources and Copilot Guides
            $githubResourcesSidebar = Build-GitHubResourcesSidebar -RootPath $RootPath
            $copilotGuidesSidebar = Build-CopilotGuidesSidebar -RootPath $RootPath

            # Special files
            $specialFilesSidebar = Build-SpecialFilesSidebar -DocsPath $DocsPath -RootPath $RootPath

            # Combine sections
            $allSections = @()
            if ($mainSidebar.Trim()) { $allSections += $mainSidebar.TrimEnd() }
            if ($gettingStartedSidebar.Trim()) { $allSections += $gettingStartedSidebar.TrimEnd() }
            if ($projectPlanningSidebar.Trim()) { $allSections += $projectPlanningSidebar.TrimEnd() }
            if ($contributingSidebar.Trim()) { $allSections += $contributingSidebar.TrimEnd() }
            if ($solutionAdrSidebar.Trim()) { $allSections += $solutionAdrSidebar.TrimEnd() }
            if ($solutionSecuritySidebar.Trim()) { $allSections += $solutionSecuritySidebar.TrimEnd() }
            if ($solutionTechSidebar.Trim()) { $allSections += $solutionTechSidebar.TrimEnd() }
            if ($observabilitySidebar.Trim()) { $allSections += $observabilitySidebar.TrimEnd() }
            if ($buildCicdSidebar.Trim()) { $allSections += $buildCicdSidebar.TrimEnd() }
            if ($githubResourcesSidebar.Trim()) { $allSections += $githubResourcesSidebar.TrimEnd() }
            if ($copilotGuidesSidebar.Trim()) { $allSections += $copilotGuidesSidebar.TrimEnd() }
            if ($specialFilesSidebar.Trim()) { $allSections += $specialFilesSidebar.TrimEnd() }

            $sidebarContent = $allSections -join "`n`n"
        }

        'praxisworx' {
            # PraxisWorx section sidebar
            Write-Host "🎓 Processing PraxisWorx section..." -ForegroundColor Cyan
            $praxisWorxPath = Join-Path $RootPath "praxisworx"
            if (Test-Path $praxisWorxPath) {
                $praxisWorxReadme = Join-Path $praxisWorxPath "README.md"
                if (Test-Path $praxisWorxReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $praxisWorxReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "- [PraxisWorx Overview]($docsifyLink)`n"
                } else {
                    $sidebarContent += "- PraxisWorx Overview`n"
                }
                $sidebarContent += Build-PraxisWorxSectionSidebar -SectionPath $praxisWorxPath -RootPath $RootPath

                # Add focused GitHub Resources and Copilot Guides for PraxisWorx
                $sidebarContent += "`n- GitHub Copilot Resources`n"
                $sidebarContent += "  - AI Prompts`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/prompts/adr-create.prompt.md"
                $sidebarContent += "    - [Adr Create]($docsifyLink)`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/prompts/edge-ai-project-planning.prompt.md"
                $sidebarContent += "    - [Edge Ai Project Planning]($docsifyLink)`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/prompts/task-planner.prompt.md"
                $sidebarContent += "    - [Task Planner]($docsifyLink)`n"
                $sidebarContent += "  - Chat Modes`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/chatmodes/praxisworx-kata-coach.chatmode.md"
                $sidebarContent += "    - [Praxisworx Kata Coach]($docsifyLink)`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/chatmodes/praxisworx-lab-coach.chatmode.md"
                $sidebarContent += "    - [Praxisworx Lab Coach]($docsifyLink)`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/chatmodes/task-planner.chatmode.md"
                $sidebarContent += "    - [Task Planner]($docsifyLink)`n"
                $sidebarContent += "- Copilot Guides`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../copilot/getting-started.md"
                $sidebarContent += "  - [Getting Started]($docsifyLink)`n"
                $sidebarContent += "  - Bash/Shell`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../copilot/bash/bash.md"
                $sidebarContent += "    - [Bash]($docsifyLink)`n"
            }
        }

        'blueprints' {
            # Blueprints section sidebar
            Write-Host "📋 Processing Blueprints section..." -ForegroundColor Cyan
            $blueprintsPath = Join-Path $RootPath "blueprints"
            if (Test-Path $blueprintsPath) {
                $blueprintsReadme = Join-Path $blueprintsPath "README.md"
                if (Test-Path $blueprintsReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $blueprintsReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "- [Blueprints Overview]($docsifyLink)`n"
                } else {
                    $sidebarContent += "- Blueprints Overview`n"
                }

                $sidebarContent += "`n- Blueprint Components`n"
                $sidebarContent += "  - Component Overview`n"
                $sidebarContent += Build-ComponentsSidebar -SrcPath $blueprintsPath -RootPath $RootPath
                $sidebarContent += "`n- Bicep Blueprints`n"
                $sidebarContent += "  - Bicep Documentation`n"
                $sidebarContent += Build-BicepSidebar -SrcPath $blueprintsPath -RootPath $RootPath
                $sidebarContent += "`n- Terraform Blueprints`n"
                $sidebarContent += "  - Terraform Documentation`n"
                $sidebarContent += Build-TerraformSidebar -SrcPath $blueprintsPath -RootPath $RootPath

                # Add focused GitHub Resources and Copilot Guides for Blueprints
                $sidebarContent += "`n- GitHub Copilot Resources`n"
                $sidebarContent += "  - AI Prompts`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/prompts/deploy.prompt.md"
                $sidebarContent += "    - [Deploy]($docsifyLink)`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/prompts/getting-started.prompt.md"
                $sidebarContent += "    - [Getting Started]($docsifyLink)`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/prompts/terraform-from-blueprint.prompt.md"
                $sidebarContent += "    - [Terraform From Blueprint]($docsifyLink)`n"
                $sidebarContent += "  - Instructions`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/instructions/bicep.instructions.md"
                $sidebarContent += "    - [Bicep]($docsifyLink)`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../.github/instructions/terraform.instructions.md"
                $sidebarContent += "    - [Terraform]($docsifyLink)`n"
                $sidebarContent += "- Copilot Guides`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../copilot/deploy.md"
                $sidebarContent += "  - [Deploy]($docsifyLink)`n"
                $sidebarContent += "  - Bicep`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../copilot/bicep/bicep-standards.md"
                $sidebarContent += "    - [Bicep Standards]($docsifyLink)`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../copilot/bicep/bicep.md"
                $sidebarContent += "    - [Bicep]($docsifyLink)`n"
                $sidebarContent += "  - Terraform`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../copilot/terraform/terraform-standards.md"
                $sidebarContent += "    - [Terraform Standards]($docsifyLink)`n"
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "../copilot/terraform/terraform.md"
                $sidebarContent += "    - [Terraform]($docsifyLink)`n"
            }
        }

        'infrastructure' {
            # Infrastructure section sidebar
            Write-Host "🏗️ Processing Infrastructure section..." -ForegroundColor Cyan
            if ($SrcPath -and (Test-Path $SrcPath)) {
                # Infrastructure overview
                $srcReadme = Join-Path $SrcPath "README.md"
                if (Test-Path $srcReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $srcReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "- [Infrastructure Overview]($docsifyLink)`n`n"
                } else {
                    $sidebarContent += "- Infrastructure Overview`n`n"
                }

                # Use dynamic component discovery for clean, consistent structure
                Write-Verbose "Using dynamic component discovery for infrastructure sidebar..."

                # Get all component groups dynamically
                $componentGroups = Get-ChildItem -Path $SrcPath -Directory | Where-Object {
                    $_.Name -match '^\d{3}-' -or $_.Name -match '^\d{4}-'
                } | Sort-Object Name

                foreach ($group in $componentGroups) {
                    $groupDisplayName = Get-DisplayName -FilePath $group.Name
                    $groupReadme = Join-Path $group.FullName "README.md"

                    if (Test-Path $groupReadme) {
                        $groupRelativePath = Get-DocsifyRelativePath -FilePath $groupReadme -RootPath $RootPath
                        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $groupRelativePath
                        $sidebarContent += "- [$groupDisplayName]($docsifyLink)`n"
                    } else {
                        $sidebarContent += "- $groupDisplayName`n"
                    }

                    # Get components within this group
                    $components = Get-ChildItem -Path $group.FullName -Directory | Where-Object {
                        $_.Name -match '^\d{3}-' -and (Test-Path (Join-Path $_.FullName "README.md"))
                    } | Sort-Object Name

                    foreach ($component in $components) {
                        $componentDisplayName = Get-DisplayName -FilePath $component.Name
                        $componentReadme = Join-Path $component.FullName "README.md"
                        $componentRelativePath = Get-DocsifyRelativePath -FilePath $componentReadme -RootPath $RootPath
                        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $componentRelativePath
                        $sidebarContent += "  - [$componentDisplayName]($docsifyLink)`n"
                    }
                    $sidebarContent += "`n"
                }

                # Add other top-level components not in numbered groups
                $otherComponents = Get-ChildItem -Path $SrcPath -Directory | Where-Object {
                    $_.Name -notmatch '^\d{3}-' -and $_.Name -notmatch '^\d{4}-' -and
                    (Test-Path (Join-Path $_.FullName "README.md"))
                } | Sort-Object Name

                if ($otherComponents.Count -gt 0) {
                    $sidebarContent += "- Supporting Infrastructure`n"
                    foreach ($component in $otherComponents) {
                        $componentDisplayName = Get-DisplayName -FilePath $component.Name
                        $componentReadme = Join-Path $component.FullName "README.md"
                        $componentRelativePath = Get-DocsifyRelativePath -FilePath $componentReadme -RootPath $RootPath
                        $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $componentRelativePath
                        $sidebarContent += "  - [$componentDisplayName]($docsifyLink)`n"
                    }
                }
            } else {
                Write-Warning "Infrastructure section requested but src directory not found: $SrcPath"
                return ""
            }
        }

        'home' {
            # Home section sidebar - clean and focused navigation
            Write-Host "🏠 Processing Home section..." -ForegroundColor Cyan

            # Welcome/Overview
            $docsIndex = Join-Path $DocsPath "index.md"
            if (Test-Path $docsIndex) {
                $relativePath = Get-DocsifyRelativePath -FilePath $docsIndex -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebarContent += "- [🏠 Welcome]($docsifyLink)`n"
            }

            # Quick Start Links
            $sidebarContent += "`n- 🚀 Quick Start`n"
            $gettingStartedPath = Join-Path $DocsPath "getting-started"
            if (Test-Path $gettingStartedPath) {
                $gettingStartedIndex = Join-Path $gettingStartedPath "index.md"
                if (Test-Path $gettingStartedIndex) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $gettingStartedIndex -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Getting Started]($docsifyLink)`n"
                }
            }

            # Navigation to major sections
            $sidebarContent += "`n- 📚 Explore Documentation`n"
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "docs/index"
            $sidebarContent += "  - [Documentation Hub]($docsifyLink)`n"
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "praxisworx/README"
            $sidebarContent += "  - [Learning (PraxisWorx)]($docsifyLink)`n"
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "blueprints/README"
            $sidebarContent += "  - [Blueprints]($docsifyLink)`n"
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "src/README"
            $sidebarContent += "  - [Infrastructure Code]($docsifyLink)`n"

            # Quick access to common resources
            $sidebarContent += "`n- 🛠️ Developer Resources`n"
            $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath "copilot/README"
            $sidebarContent += "  - [Copilot Guides]($docsifyLink)`n"
            $contributingPath = Join-Path $DocsPath "contributing"
            if (Test-Path $contributingPath) {
                $contributingIndex = Join-Path $contributingPath "index.md"
                if (Test-Path $contributingIndex) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $contributingIndex -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Contributing Guide]($docsifyLink)`n"
                }
            }
        }

        'copilot' {
            # Copilot Resources section sidebar - comprehensive GitHub Copilot resources
            Write-Host "🤖 Processing Copilot Resources section..." -ForegroundColor Cyan

            # Copilot Guides Overview
            $copilotPath = Join-Path $RootPath "copilot"
            if (Test-Path $copilotPath) {
                $copilotReadme = Join-Path $copilotPath "README.md"
                if (Test-Path $copilotReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $copilotReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "- [🤖 Copilot Overview]($docsifyLink)`n"
                } else {
                    $sidebarContent += "- 🤖 Copilot Overview`n"
                }
            }

            # Getting Started
            $copilotGettingStarted = Join-Path $RootPath "copilot/getting-started.md"
            if (Test-Path $copilotGettingStarted) {
                $relativePath = Get-DocsifyRelativePath -FilePath $copilotGettingStarted -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebarContent += "- [🚀 Getting Started]($docsifyLink)`n"
            }

            # Copilot Instructions
            $copilotInstructions = Join-Path $RootPath ".github/copilot-instructions.md"
            if (Test-Path $copilotInstructions) {
                $relativePath = Get-DocsifyRelativePath -FilePath $copilotInstructions -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebarContent += "- [📋 Copilot Instructions]($docsifyLink)`n"
            }

            # Technology-specific guides
            $sidebarContent += "`n- 💻 Technology Guides`n"

            # Bash/Shell guides
            $bashPath = Join-Path $RootPath "copilot/bash"
            if (Test-Path $bashPath) {
                $bashReadme = Join-Path $bashPath "README.md"
                $bashMd = Join-Path $bashPath "bash.md"
                if (Test-Path $bashReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $bashReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Bash/Shell]($docsifyLink)`n"
                } elseif (Test-Path $bashMd) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $bashMd -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Bash/Shell]($docsifyLink)`n"
                }
            }

            # Bicep guides
            $bicepPath = Join-Path $RootPath "copilot/bicep"
            if (Test-Path $bicepPath) {
                $bicepReadme = Join-Path $bicepPath "README.md"
                $bicepMd = Join-Path $bicepPath "bicep.md"
                if (Test-Path $bicepReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $bicepReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Bicep]($docsifyLink)`n"
                } elseif (Test-Path $bicepMd) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $bicepMd -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Bicep]($docsifyLink)`n"
                }
            }

            # C# guides
            $csharpPath = Join-Path $RootPath "copilot/csharp"
            if (Test-Path $csharpPath) {
                $csharpReadme = Join-Path $csharpPath "README.md"
                $csharpMd = Join-Path $csharpPath "csharp.md"
                if (Test-Path $csharpReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $csharpReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [C#/.NET]($docsifyLink)`n"
                } elseif (Test-Path $csharpMd) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $csharpMd -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [C#/.NET]($docsifyLink)`n"
                }
            }

            # Terraform guides
            $terraformPath = Join-Path $RootPath "copilot/terraform"
            if (Test-Path $terraformPath) {
                $terraformReadme = Join-Path $terraformPath "README.md"
                $terraformMd = Join-Path $terraformPath "terraform.md"
                if (Test-Path $terraformReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $terraformReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Terraform]($docsifyLink)`n"
                } elseif (Test-Path $terraformMd) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $terraformMd -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Terraform]($docsifyLink)`n"
                }
            }

            # Python guide
            $pythonScriptPath = Join-Path $RootPath "copilot/python-script.md"
            if (Test-Path $pythonScriptPath) {
                $relativePath = Get-DocsifyRelativePath -FilePath $pythonScriptPath -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebarContent += "  - [Python]($docsifyLink)`n"
            }

            # Special guides
            $deployPath = Join-Path $RootPath "copilot/deploy.md"
            if (Test-Path $deployPath) {
                $relativePath = Get-DocsifyRelativePath -FilePath $deployPath -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebarContent += "  - [Deploy Guide]($docsifyLink)`n"
            }

            $testsPath = Join-Path $RootPath "copilot/csharp-tests.md"
            if (Test-Path $testsPath) {
                $relativePath = Get-DocsifyRelativePath -FilePath $testsPath -RootPath $RootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $sidebarContent += "  - [C# Testing Guide]($docsifyLink)`n"
            }

            # GitHub-specific resources
            $sidebarContent += "`n- 🔧 GitHub Resources`n"

            # Chat Modes
            $chatModesPath = Join-Path $RootPath ".github/chatmodes"
            if (Test-Path $chatModesPath) {
                $chatModesReadme = Join-Path $chatModesPath "README.md"
                if (Test-Path $chatModesReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $chatModesReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Chat Modes]($docsifyLink)`n"
                }
            }

            # Instructions
            $instructionsPath = Join-Path $RootPath ".github/instructions"
            if (Test-Path $instructionsPath) {
                $instructionsReadme = Join-Path $instructionsPath "README.md"
                if (Test-Path $instructionsReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $instructionsReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [Instructions]($docsifyLink)`n"
                }
            }

            # Prompts
            $promptsPath = Join-Path $RootPath ".github/prompts"
            if (Test-Path $promptsPath) {
                $promptsReadme = Join-Path $promptsPath "README.md"
                if (Test-Path $promptsReadme) {
                    $relativePath = Get-DocsifyRelativePath -FilePath $promptsReadme -RootPath $RootPath
                    $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                    $sidebarContent += "  - [AI Prompts]($docsifyLink)`n"
                }
            }
        }

        default {
            Write-Error "Unknown section: $SectionName"
            return ""
        }
    }

    return $sidebarContent
}

function Update-NavbarMarkdown {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory = $true)]
        [string]$NavbarPath
    )

    if (-not (Test-Path $NavbarPath)) {
        Write-Host "⚠️ Navbar file not found: $NavbarPath" -ForegroundColor Yellow
        return
    }

    $originalContent = Get-Content -Path $NavbarPath -Raw
    if ($null -eq $originalContent) {
        Write-Host "⚠️ Navbar file is empty: $NavbarPath" -ForegroundColor Yellow
        return
    }

    $content = $originalContent -replace "\r", ""
    $content = $content -replace "(`n){3,}", "`n`n"

    $lines = $content -split "`n"
    $modified = $false

    $linesList = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in $lines) {
        $linesList.Add($line)
    }

    for ($i = $linesList.Count - 1; $i -ge 0; $i--) {
        if ($linesList[$i].Trim() -match '^<!--\s*markdownlint-enable\s+') {
            $linesList.RemoveAt($i)
            $modified = $true
        }
    }

    if ($linesList.Count -eq 0 -or $linesList[0].Trim() -ne "<!-- markdownlint-disable MD041 -->") {
        $linesList.Insert(0, "<!-- markdownlint-disable MD041 -->")
        $modified = $true
    }

    if ($linesList.Count -lt 2 -or $linesList[1].Trim() -ne "<!-- markdownlint-disable MD051 -->") {
        $linesList.Insert(1, "<!-- markdownlint-disable MD051 -->")
        $modified = $true
    }

    if ($linesList.Count -lt 3 -or -not [string]::IsNullOrWhiteSpace($linesList[2])) {
        $linesList.Insert(2, "")
        $modified = $true
    }

    while ($linesList.Count -gt 0 -and [string]::IsNullOrWhiteSpace($linesList[$linesList.Count - 1])) {
        $linesList.RemoveAt($linesList.Count - 1)
        $modified = $true
    }

    $normalizedLines = New-Object 'System.Collections.Generic.List[string]'
    $previousBlank = $false
    foreach ($line in $linesList) {
        $isBlank = [string]::IsNullOrWhiteSpace($line)
        if ($isBlank -and $previousBlank) {
            $modified = $true
            continue
        }
        $normalizedLines.Add($line)
        $previousBlank = $isBlank
    }

    $updatedContent = ($normalizedLines -join "`n").TrimEnd() + "`n"

    $normalizedOriginal = ($originalContent -replace "\r", "").TrimEnd() + "`n"

    if ($modified -or $updatedContent -ne $normalizedOriginal) {
        if ($PSCmdlet.ShouldProcess($NavbarPath, 'Update navbar lint directives')) {
            Set-Content -Path $NavbarPath -Value $updatedContent -Encoding UTF8 -NoNewline
            Write-Host "✅ Navbar lint directives updated: $NavbarPath" -ForegroundColor Green
        }
    } else {
        Write-Host "ℹ️ Navbar lint directives already up to date: $NavbarPath" -ForegroundColor Gray
    }
}

function Main {
    Write-Host "�🚀 Enhanced Docsify Sidebar Generator" -ForegroundColor Cyan
    Write-Host "=====================================" -ForegroundColor Cyan

    # Resolve paths to absolute paths
    try {
        $resolvedDocsPath = (Resolve-Path $DocsPath -ErrorAction Stop).Path
    } catch {
        Write-Error "Docs directory not found: $DocsPath"
        exit 1
    }

    try {
        $resolvedSrcPath = (Resolve-Path $SrcPath -ErrorAction Stop).Path
    } catch {
        # If src path doesn't exist, infrastructure section will be disabled
        Write-Warning "Src directory not found: $SrcPath. Infrastructure section will be disabled."
        $resolvedSrcPath = $null
    }

    # Use parameters explicitly to ensure PSScriptAnalyzer recognizes them as used
    $sidebarFilePath = Join-Path $resolvedDocsPath $SidebarFile

    Write-Host "Current working directory: $(Get-Location)" -ForegroundColor Gray
    Write-Host "Docs directory path: $resolvedDocsPath" -ForegroundColor Gray
    if ($resolvedSrcPath) {
        Write-Host "Src directory path: $resolvedSrcPath" -ForegroundColor Gray
    }
    Write-Host "Sidebar file path: $sidebarFilePath" -ForegroundColor Gray
    Write-Host "Section: $Section" -ForegroundColor Gray

    try {
        # Get root path for Docsify-compatible path generation (absolute path)
        $rootPath = Split-Path $resolvedDocsPath -Parent

        # Handle generating all section-specific sidebars
        if ($AllSections) {
            Write-Host "`n🔄 Generating all section-specific sidebars..." -ForegroundColor Magenta

            # Determine output directory for sections in _parts folder
            $partsDir = Join-Path $resolvedDocsPath "_parts"
            if (-not (Test-Path $partsDir)) {
                New-Item -ItemType Directory -Path $partsDir -Force | Out-Null
                Write-Host "Created directory: $partsDir" -ForegroundColor Green
            }

            # Generate sidebars for all sections
            $sections = @('docs', 'praxisworx', 'blueprints', 'infrastructure', 'home', 'copilot')
            $successCount = 0

            foreach ($sectionName in $sections) {
                Write-Host "`n📝 Generating section-specific sidebar for: $sectionName" -ForegroundColor Yellow

                $sectionSidebarPath = Join-Path $partsDir "$sectionName-sidebar.md"
                Write-Host "Section-specific sidebar file path: $sectionSidebarPath" -ForegroundColor Gray

                # Generate section-specific sidebar
                $sectionSidebar = Build-SectionSidebar -SectionName $sectionName -DocsPath $resolvedDocsPath -SrcPath $resolvedSrcPath -RootPath $rootPath

                if ($sectionSidebar) {
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
                    $sidebarContent = @"
<!-- markdownlint-disable MD041 -->
<!-- markdownlint-disable MD051 -->
<!-- $sectionName Section Sidebar -->
<!-- Generated on: $timestamp -->

$sectionSidebar
"@

                    # Ensure content ends with exactly one newline
                    $sidebarContent = $sidebarContent.TrimEnd() + "`n"

                    # Write sidebar file
                    Set-Content -Path $sectionSidebarPath -Value $sidebarContent -Encoding UTF8 -NoNewline

                    Write-Host "✅ Section-specific sidebar generated: $sectionSidebarPath" -ForegroundColor Green
                    $successCount++
                } else {
                    Write-Warning "Failed to generate section-specific sidebar for: $sectionName"
                }
            }

            Write-Host "`n🎉 Completed generating all section-specific sidebars!" -ForegroundColor Magenta
            Write-Host "📊 Successfully generated: $successCount of $($sections.Count) sidebars" -ForegroundColor Green

            # Also generate the main sidebar (all sections combined)
            Write-Host "`n📝 Also generating main sidebar (all sections combined)..." -ForegroundColor Yellow
        }

        # Handle section-specific sidebar generation
        elseif ($Section -ne 'all') {
            Write-Host "`n📝 Generating section-specific sidebar for: $Section" -ForegroundColor Yellow

            # Determine output file path for section in _parts folder
            $partsDir = Join-Path $resolvedDocsPath "_parts"
            if (-not (Test-Path $partsDir)) {
                New-Item -ItemType Directory -Path $partsDir -Force | Out-Null
                Write-Host "Created directory: $partsDir" -ForegroundColor Green
            }

            $sidebarFilePath = Join-Path $partsDir "$Section-sidebar.md"
            Write-Host "Section-specific sidebar file path: $sidebarFilePath" -ForegroundColor Gray

            # Generate section-specific sidebar
            $sectionSidebar = Build-SectionSidebar -SectionName $Section -DocsPath $resolvedDocsPath -SrcPath $resolvedSrcPath -RootPath $rootPath

            if ($sectionSidebar) {
                $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
                $sidebarContent = @"
<!-- markdownlint-disable MD041 -->
<!-- markdownlint-disable MD051 -->
<!-- $Section Section Sidebar -->
<!-- Generated on: $timestamp -->

$sectionSidebar
"@

                # Ensure content ends with exactly one newline
                $sidebarContent = $sidebarContent.TrimEnd() + "`n"

                # Write sidebar file
                Set-Content -Path $sidebarFilePath -Value $sidebarContent -Encoding UTF8 -NoNewline

                Write-Host "`n✅ Section-specific sidebar generated: $sidebarFilePath" -ForegroundColor Green
                Write-Host "📋 Section: $Section" -ForegroundColor Green
                return
            } else {
                Write-Error "Failed to generate section-specific sidebar for: $Section"
                exit 1
            }
        }

        Write-Host "`n📝 Generating complete sidebar with README ordering..." -ForegroundColor Yellow
        $rootPath = Split-Path $resolvedDocsPath -Parent

        # Generate main documentation sidebar (only for root-level docs files)
        $mainSidebar = Build-MainSidebar -DocsPath $resolvedDocsPath -RootPath $rootPath

        # Generate infrastructure sections
        $infrastructureSidebar = ""
        if ($resolvedSrcPath) {
            Write-Host "📁 Generating Infrastructure Code sections..." -ForegroundColor Yellow
            # Check for README.md in src
            $srcReadme = Join-Path $resolvedSrcPath "README.md"
            if (Test-Path $srcReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $srcReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $infrastructureSidebar += "- [Infrastructure Code]($docsifyLink)`n"
            } else {
                $infrastructureSidebar += "- Infrastructure Code`n"
            }
            $infrastructureSidebar += Build-ComponentsSidebar -SrcPath $resolvedSrcPath -RootPath $rootPath
            $infrastructureSidebar += Build-BicepSidebar -SrcPath $resolvedSrcPath -RootPath $rootPath
            $infrastructureSidebar += Build-TerraformSidebar -SrcPath $resolvedSrcPath -RootPath $rootPath
        }

        # Generate Getting Started section
        $gettingStartedPath = Join-Path $resolvedDocsPath "getting-started"
        $gettingStartedSidebar = ""
        if (Test-Path $gettingStartedPath) {
            Write-Host "🚀 Generating Getting Started section..." -ForegroundColor Yellow
            # Check for index.md or README.md
            $gettingStartedIndex = Join-Path $gettingStartedPath "index.md"
            $gettingStartedReadme = Join-Path $gettingStartedPath "README.md"
            if (Test-Path $gettingStartedIndex) {
                $relativePath = Get-DocsifyRelativePath -FilePath $gettingStartedIndex -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $gettingStartedSidebar += "- [Getting Started]($docsifyLink)`n"
            } elseif (Test-Path $gettingStartedReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $gettingStartedReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $gettingStartedSidebar += "- [Getting Started]($docsifyLink)`n"
            } else {
                $gettingStartedSidebar += "- Getting Started`n"
            }
            $gettingStartedSidebar += Build-DocsSectionSidebar -SectionPath $gettingStartedPath -RootPath $rootPath
        }

        # Generate PraxisWorx section
        $praxisWorxPath = Join-Path $rootPath "praxisworx"
        $praxisWorxSidebar = ""
        if (Test-Path $praxisWorxPath) {
            Write-Host "🎓 Generating PraxisWorx section..." -ForegroundColor Yellow
            $praxisWorxReadme = Join-Path $praxisWorxPath "README.md"
            if (Test-Path $praxisWorxReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $praxisWorxReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $praxisWorxSidebar += "- [PraxisWorx]($docsifyLink)`n"
            } else {
                $praxisWorxSidebar += "- PraxisWorx`n"
            }
            $praxisWorxSidebar += Build-PraxisWorxSectionSidebar -SectionPath $praxisWorxPath -RootPath $rootPath
        }

        # Generate Build CI/CD section
        $buildCicdPath = Join-Path $docsPath "build-cicd"
        $buildCicdSidebar = ""
        if (Test-Path $buildCicdPath) {
            Write-Host "🔧 Generating Build CI/CD section..." -ForegroundColor Yellow
            # Check for index.md or README.md
            $buildCicdIndex = Join-Path $buildCicdPath "index.md"
            $buildCicdReadme = Join-Path $buildCicdPath "README.md"
            if (Test-Path $buildCicdIndex) {
                $relativePath = Get-DocsifyRelativePath -FilePath $buildCicdIndex -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $buildCicdSidebar += "- [Build CI/CD]($docsifyLink)`n"
            } elseif (Test-Path $buildCicdReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $buildCicdReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $buildCicdSidebar += "- [Build CI/CD]($docsifyLink)`n"
            } else {
                $buildCicdSidebar += "- Build CI/CD`n"
            }
            $buildCicdSidebar += Build-DocsSectionSidebar -SectionPath $buildCicdPath -RootPath $rootPath
        }

        # Generate Contributing section
        $contributingPath = Join-Path $docsPath "contributing"
        $contributingSidebar = ""
        if (Test-Path $contributingPath) {
            Write-Host "🤝 Generating Contributing section..." -ForegroundColor Yellow
            # Check for index.md or README.md
            $contributingIndex = Join-Path $contributingPath "index.md"
            $contributingReadme = Join-Path $contributingPath "README.md"
            if (Test-Path $contributingIndex) {
                $relativePath = Get-DocsifyRelativePath -FilePath $contributingIndex -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $contributingSidebar += "- [Contributing]($docsifyLink)`n"
            } elseif (Test-Path $contributingReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $contributingReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $contributingSidebar += "- [Contributing]($docsifyLink)`n"
            } else {
                $contributingSidebar += "- Contributing`n"
            }
            $contributingSidebar += Build-DocsSectionSidebar -SectionPath $contributingPath -RootPath $rootPath
        }

        # Generate Project Planning section
        $projectPlanningPath = Join-Path $docsPath "project-planning"
        $projectPlanningSidebar = ""
        if (Test-Path $projectPlanningPath) {
            Write-Host "📋 Generating Project Planning section..." -ForegroundColor Yellow
            # Check for index.md or README.md
            $projectPlanningIndex = Join-Path $projectPlanningPath "index.md"
            $projectPlanningReadme = Join-Path $projectPlanningPath "README.md"
            if (Test-Path $projectPlanningIndex) {
                $relativePath = Get-DocsifyRelativePath -FilePath $projectPlanningIndex -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $projectPlanningSidebar += "- [Project Planning]($docsifyLink)`n"
            } elseif (Test-Path $projectPlanningReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $projectPlanningReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $projectPlanningSidebar += "- [Project Planning]($docsifyLink)`n"
            } else {
                $projectPlanningSidebar += "- Project Planning`n"
            }
            $projectPlanningSidebar += Build-DocsSectionSidebar -SectionPath $projectPlanningPath -RootPath $rootPath
        }

        # Generate Observability section
        $observabilityPath = Join-Path $docsPath "observability"
        $observabilitySidebar = ""
        if (Test-Path $observabilityPath) {
            Write-Host "📊 Generating Observability section..." -ForegroundColor Yellow
            # Check for index.md or README.md
            $observabilityIndex = Join-Path $observabilityPath "index.md"
            $observabilityReadme = Join-Path $observabilityPath "README.md"
            if (Test-Path $observabilityIndex) {
                $relativePath = Get-DocsifyRelativePath -FilePath $observabilityIndex -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $observabilitySidebar += "- [Observability]($docsifyLink)`n"
            } elseif (Test-Path $observabilityReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $observabilityReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $observabilitySidebar += "- [Observability]($docsifyLink)`n"
            } else {
                $observabilitySidebar += "- Observability`n"
            }
            $observabilitySidebar += Build-DocsSectionSidebar -SectionPath $observabilityPath -RootPath $rootPath
        }

        # Generate Solution ADR Library section
        $solutionAdrPath = Join-Path $docsPath "solution-adr-library"
        $solutionAdrSidebar = ""
        if (Test-Path $solutionAdrPath) {
            Write-Host "📚 Generating Solution ADR Library section..." -ForegroundColor Yellow
            # Check for index.md or README.md
            $solutionAdrIndex = Join-Path $solutionAdrPath "index.md"
            $solutionAdrReadme = Join-Path $solutionAdrPath "README.md"
            if (Test-Path $solutionAdrIndex) {
                $relativePath = Get-DocsifyRelativePath -FilePath $solutionAdrIndex -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $solutionAdrSidebar += "- [Solution ADR Library]($docsifyLink)`n"
            } elseif (Test-Path $solutionAdrReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $solutionAdrReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $solutionAdrSidebar += "- [Solution ADR Library]($docsifyLink)`n"
            } else {
                $solutionAdrSidebar += "- Solution ADR Library`n"
            }
            $solutionAdrSidebar += Build-DocsSectionSidebar -SectionPath $solutionAdrPath -RootPath $rootPath
        }

        # Generate Solution Security Plan Library section
        $solutionSecurityPath = Join-Path $docsPath "solution-security-plan-library"
        $solutionSecuritySidebar = ""
        if (Test-Path $solutionSecurityPath) {
            Write-Host "🔒 Generating Solution Security Plan Library section..." -ForegroundColor Yellow
            # Check for index.md or README.md
            $solutionSecurityIndex = Join-Path $solutionSecurityPath "index.md"
            $solutionSecurityReadme = Join-Path $solutionSecurityPath "README.md"
            if (Test-Path $solutionSecurityIndex) {
                $relativePath = Get-DocsifyRelativePath -FilePath $solutionSecurityIndex -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $solutionSecuritySidebar += "- [Solution Security Plan Library]($docsifyLink)`n"
            } elseif (Test-Path $solutionSecurityReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $solutionSecurityReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $solutionSecuritySidebar += "- [Solution Security Plan Library]($docsifyLink)`n"
            } else {
                $solutionSecuritySidebar += "- Solution Security Plan Library`n"
            }
            $solutionSecuritySidebar += Build-DocsSectionSidebar -SectionPath $solutionSecurityPath -RootPath $rootPath
        }

        # Generate Solution Technology Paper Library section
        $solutionTechPath = Join-Path $docsPath "solution-technology-paper-library"
        $solutionTechSidebar = ""
        if (Test-Path $solutionTechPath) {
            Write-Host "🔬 Generating Solution Technology Paper Library section..." -ForegroundColor Yellow
            # Check for index.md or README.md
            $solutionTechIndex = Join-Path $solutionTechPath "index.md"
            $solutionTechReadme = Join-Path $solutionTechPath "README.md"
            if (Test-Path $solutionTechIndex) {
                $relativePath = Get-DocsifyRelativePath -FilePath $solutionTechIndex -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $solutionTechSidebar += "- [Solution Technology Paper Library]($docsifyLink)`n"
            } elseif (Test-Path $solutionTechReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $solutionTechReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $solutionTechSidebar += "- [Solution Technology Paper Library]($docsifyLink)`n"
            } else {
                $solutionTechSidebar += "- Solution Technology Paper Library`n"
            }
            $solutionTechSidebar += Build-DocsSectionSidebar -SectionPath $solutionTechPath -RootPath $rootPath
        }

        # Generate Templates section
        $templatesPath = Join-Path $docsPath "templates"
        $templatesSidebar = ""
        if (Test-Path $templatesPath) {
            Write-Host "📄 Generating Templates section..." -ForegroundColor Yellow
            $templatesSidebar += "- Templates`n"
            $templatesSidebar += Build-DocsSectionSidebar -SectionPath $templatesPath -RootPath $rootPath
        }

        # Generate blueprints section if blueprints directory exists
        $blueprintsPath = Join-Path $rootPath "blueprints"
        $blueprintsSidebar = ""
        if (Test-Path $blueprintsPath) {
            Write-Host "📋 Generating Blueprints sections..." -ForegroundColor Yellow
            # Check for README.md in blueprints
            $blueprintsReadme = Join-Path $blueprintsPath "README.md"
            if (Test-Path $blueprintsReadme) {
                $relativePath = Get-DocsifyRelativePath -FilePath $blueprintsReadme -RootPath $rootPath
                $docsifyLink = Convert-ToDocsifyHashRoute -RelativePath $relativePath
                $blueprintsSidebar += "- [Blueprints]($docsifyLink)`n"
            } else {
                $blueprintsSidebar += "- Blueprints`n"
            }
            $blueprintsSidebar += Build-ComponentsSidebar -SrcPath $blueprintsPath -RootPath $rootPath
            $blueprintsSidebar += Build-BicepSidebar -SrcPath $blueprintsPath -RootPath $rootPath
            $blueprintsSidebar += Build-TerraformSidebar -SrcPath $blueprintsPath -RootPath $rootPath
        }

        # Generate special files section
        $specialFilesSidebar = Build-SpecialFilesSidebar -DocsPath $resolvedDocsPath -RootPath $rootPath

        # Generate GitHub Resources section
        $githubResourcesSidebar = Build-GitHubResourcesSidebar -RootPath $rootPath

        # Generate Copilot Guides section
        $copilotGuidesSidebar = Build-CopilotGuidesSidebar -RootPath $rootPath

        # Combine all sections with proper spacing
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        $allSections = @()

        # Add each non-empty section
        if ($mainSidebar.Trim()) { $allSections += $mainSidebar.TrimEnd() }

        if ($gettingStartedSidebar.Trim()) { $allSections += $gettingStartedSidebar.TrimEnd() }
        if ($praxisWorxSidebar.Trim()) { $allSections += $praxisWorxSidebar.TrimEnd() }
        if ($projectPlanningSidebar.Trim()) { $allSections += $projectPlanningSidebar.TrimEnd() }
        if ($blueprintsSidebar.Trim()) { $allSections += $blueprintsSidebar.TrimEnd() }

        if ($contributingSidebar.Trim()) { $allSections += $contributingSidebar.TrimEnd() }

        if ($solutionAdrSidebar.Trim()) { $allSections += $solutionAdrSidebar.TrimEnd() }
        if ($solutionSecuritySidebar.Trim()) { $allSections += $solutionSecuritySidebar.TrimEnd() }
        if ($solutionTechSidebar.Trim()) { $allSections += $solutionTechSidebar.TrimEnd() }

        # if ($templatesSidebar.Trim()) { $allSections += $templatesSidebar.TrimEnd() }

        if ($githubResourcesSidebar.Trim()) { $allSections += $githubResourcesSidebar.TrimEnd() }

        if ($infrastructureSidebar.Trim()) { $allSections += $infrastructureSidebar.TrimEnd() }

        if ($observabilitySidebar.Trim()) { $allSections += $observabilitySidebar.TrimEnd() }
        if ($buildCicdSidebar.Trim()) { $allSections += $buildCicdSidebar.TrimEnd() }

        if ($specialFilesSidebar.Trim()) { $allSections += $specialFilesSidebar.TrimEnd() }

        if ($copilotGuidesSidebar.Trim()) { $allSections += $copilotGuidesSidebar.TrimEnd() }

    $sidebarContent = @"
<!-- markdownlint-disable MD041 -->
<!-- markdownlint-disable MD051 -->
<!-- Generated on: $timestamp -->

$($allSections -join "`n`n")
"@

        # Ensure content ends with exactly one newline
        $sidebarContent = $sidebarContent.TrimEnd() + "`n"

        # Write sidebar file
        Set-Content -Path $sidebarFilePath -Value $sidebarContent -Encoding UTF8 -NoNewline

        Write-Host "`n✅ Enhanced sidebar generated: $sidebarFilePath" -ForegroundColor Green
        Write-Host "📋 Features enabled:" -ForegroundColor Green
        Write-Host "  • README.md/index.md-based ordering" -ForegroundColor Gray
        Write-Host "  • Overview/index files prioritized" -ForegroundColor Gray
        Write-Host "  • Numbered prefix handling (000-, 001-, etc.)" -ForegroundColor Gray
        Write-Host "  • Directory-first organization" -ForegroundColor Gray
        Write-Host "  • Flexible title matching" -ForegroundColor Gray
        Write-Host "  • Dynamic docs sections with multi-framework support" -ForegroundColor Gray
        Write-Host "  • Special files (accessibility, contributions, tags)" -ForegroundColor Gray
        if ($enableInfrastructure) {
            Write-Host "  • Infrastructure Code documentation sections" -ForegroundColor Gray
            Write-Host "  • Component cross-references" -ForegroundColor Gray
        }

        $navbarPath = Join-Path $resolvedDocsPath "_navbar.md"
        Update-NavbarMarkdown -NavbarPath $navbarPath

    }
    catch {
        Write-Error "Error generating sidebar: $($_.Exception.Message)"
        Write-Error "Stack trace: $($_.ScriptStackTrace)"
        exit 1
    }
}

# Main execution
Main
