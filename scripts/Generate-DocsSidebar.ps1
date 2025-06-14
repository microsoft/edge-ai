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

.PARAMETER DocsPath
    Path to the docs directory. Defaults to '../docs'

.PARAMETER SrcPath
    Path to the src directory. Defaults to '../src'

.PARAMETER SidebarFile
    Output sidebar file. Defaults to '_sidebar.md' in docs directory

.EXAMPLE
    .\Generate-DocsSidebar.ps1

.EXAMPLE
    .\Generate-DocsSidebar.ps1 -DocsPath "C:\project\docs" -SrcPath "C:\project\src" -Verbose
#>

# Suppress PSScriptAnalyzer false positives - these parameters are actually used
# SidebarFile is used in: $sidebarFilePath = Join-Path $resolvedDocsPath $SidebarFile
[Diagnostics.CodeAnalysis.SuppressMessage('PSReviewUnusedParameter', 'SidebarFile')]
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$DocsPath = '',

    [Parameter(Mandatory = $false)]
    [string]$SrcPath = '',

    [Parameter(Mandatory = $false)]
    [string]$SidebarFile = '_sidebar.md'
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
$ExcludeFiles = @('_sidebar.md', '_navbar.md', '_footer.md', '_404.md')
$PriorityFiles = @('index.md', 'overview.md', 'readme.md', 'introduction.md')

# Core Functions

function Get-MarkdownFile {
    param(
        [Parameter(Mandatory = $true)]
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
    )

    if (-not (Test-Path $Path)) {
        Write-Warning "Path not found: $Path"
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
                if ($_.DirectoryName -like "*$exclude*") {
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
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

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
        $sidebar += "- [$displayName]($relativePath)`n"
        Write-Verbose "Added index file at top: $displayName"
    }

    # Add other root level files
    if ($otherRootFiles.Count -gt 0) {
        Write-Verbose "Adding $($otherRootFiles.Count) other root files"
        $sortedOtherRootFiles = Get-SortedMarkdownFile -Files $otherRootFiles -ReadmeOrder $readmeOrder
        foreach ($file in $sortedOtherRootFiles) {
            $displayName = Get-DisplayName -FilePath $file.FullName
            $relativePath = Get-DocsifyRelativePath -FilePath $file.FullName -RootPath $RootPath
            $sidebar += "- [$displayName]($relativePath)`n"
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
                $sidebar += "$indent- [$displayName]($relativePath)`n"
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
                $sidebar += "$fileIndent- [$fileDisplayName]($relativePath)`n"
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

    $sidebar = "  - Terraform Documentation`n"

    foreach ($dir in $terraformDirs | Sort-Object FullName) {
        $readmeFile = Join-Path $dir.FullName "README.md"
        if (Test-Path $readmeFile) {
            $componentName = Split-Path (Split-Path $dir.FullName -Parent) -Leaf
            $displayName = Get-DisplayName -FilePath $componentName
            $relativePath = Get-DocsifyRelativePath -FilePath $readmeFile -RootPath $RootPath
            $sidebar += "    - [$displayName]($relativePath)`n"

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
                $moduleContent += "$indent  - [$moduleDisplayName]($moduleRelativePath)`n"
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

    $sidebar = "  - Bicep Documentation`n"

    foreach ($dir in $bicepDirs | Sort-Object FullName) {
        $readmeFile = Join-Path $dir.FullName "README.md"
        if (Test-Path $readmeFile) {
            $componentName = Split-Path (Split-Path $dir.FullName -Parent) -Leaf
            $displayName = Get-DisplayName -FilePath $componentName
            $relativePath = Get-DocsifyRelativePath -FilePath $readmeFile -RootPath $RootPath
            $sidebar += "    - [$displayName]($relativePath)`n"

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

    # Check for .bicep files that would cause 404 errors in Docsify
    $bicepFiles = Get-ChildItem -Path $ModulesPath -Filter "*.bicep" -File
    if ($bicepFiles.Count -gt 0) {
        Write-Warning "Found $($bicepFiles.Count) .bicep files in $ModulesPath that cannot be directly linked in Docsify documentation."
        Write-Warning "Bicep files should be documented through README.md files or converted to markdown documentation."
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
                $moduleContent += "$indent  - [$moduleDisplayName]($moduleRelativePath)`n"
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

    $sidebar = "  - Component Overview`n"
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
        $sidebar += "    - [$displayName]($docsifyPath)`n"
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
            $specialSidebar += "- [$($specialFile.DisplayName)]($relativePath)`n"
            Write-Verbose "Added special file: $($specialFile.DisplayName)"
        }
    }

    return $specialSidebar
}

function Build-DocsSectionSidebar {
    param(
        [Parameter(Mandatory = $true)]
        [string]$SectionPath,
        [Parameter(Mandatory = $true)]
        [string]$RootPath
    )

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
        $sidebar += "  - [$displayName]($relativePath)`n"
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
            $sidebar += "  - [$subdirDisplayName]($relativePath)`n"
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
            $sidebar += "    - [$fileDisplayName]($relativePath)`n"
        }

        # Process nested subdirectories (for deeper hierarchy)
        $nestedSubdirs = Get-ChildItem -Path $subdir.FullName -Directory | Sort-Object Name
        foreach ($nestedSubdir in $nestedSubdirs) {
            $nestedSubdirDisplayName = Get-DisplayName -FilePath $nestedSubdir.Name

            # Check if nested subdirectory has README.md
            $nestedReadmeFile = Get-ChildItem -Path $nestedSubdir.FullName -Filter "README.md" -ErrorAction SilentlyContinue
            if ($nestedReadmeFile) {
                $relativePath = Get-DocsifyRelativePath -FilePath $nestedReadmeFile.FullName -RootPath $RootPath
                $sidebar += "    - [$nestedSubdirDisplayName]($relativePath)`n"
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
                $sidebar += "      - [$fileDisplayName]($relativePath)`n"
            }
        }
    }

    return $sidebar
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

    Write-Host "`n📝 Generating enhanced sidebar with README ordering..." -ForegroundColor Yellow

    try {
        # Get root path for Docsify-compatible path generation (absolute path)
        $rootPath = Split-Path $resolvedDocsPath -Parent

        # Generate main documentation sidebar (only for root-level docs files)
        $mainSidebar = Build-MainSidebar -DocsPath $resolvedDocsPath -RootPath $rootPath

        # Generate infrastructure sections
        $infrastructureSidebar = ""
        if ($resolvedSrcPath) {
            Write-Host "📁 Generating Infrastructure Code sections..." -ForegroundColor Yellow

            $infrastructureSidebar += "- Infrastructure Code`n"
            $infrastructureSidebar += Build-ComponentsSidebar -SrcPath $resolvedSrcPath -RootPath $rootPath
            $infrastructureSidebar += Build-BicepSidebar -SrcPath $resolvedSrcPath -RootPath $rootPath
            $infrastructureSidebar += Build-TerraformSidebar -SrcPath $resolvedSrcPath -RootPath $rootPath
        }

        # Generate Getting Started section
        $gettingStartedPath = Join-Path $resolvedDocsPath "getting-started"
        $gettingStartedSidebar = ""
        if (Test-Path $gettingStartedPath) {
            Write-Host "🚀 Generating Getting Started section..." -ForegroundColor Yellow
            $gettingStartedSidebar += "- Getting Started`n"
            $gettingStartedSidebar += Build-DocsSectionSidebar -SectionPath $gettingStartedPath -RootPath $rootPath
        }

        # Generate Build CI/CD section
        $buildCicdPath = Join-Path $docsPath "build-cicd"
        $buildCicdSidebar = ""
        if (Test-Path $buildCicdPath) {
            Write-Host "🔧 Generating Build CI/CD section..." -ForegroundColor Yellow
            $buildCicdSidebar += "- Build CI/CD`n"
            $buildCicdSidebar += Build-DocsSectionSidebar -SectionPath $buildCicdPath -RootPath $rootPath
        }

        # Generate Contributing section
        $contributingPath = Join-Path $docsPath "contributing"
        $contributingSidebar = ""
        if (Test-Path $contributingPath) {
            Write-Host "🤝 Generating Contributing section..." -ForegroundColor Yellow
            $contributingSidebar += "- Contributing`n"
            $contributingSidebar += Build-DocsSectionSidebar -SectionPath $contributingPath -RootPath $rootPath
        }

        # Generate Project Planning section
        $projectPlanningPath = Join-Path $docsPath "project-planning"
        $projectPlanningSidebar = ""
        if (Test-Path $projectPlanningPath) {
            Write-Host "📋 Generating Project Planning section..." -ForegroundColor Yellow
            $projectPlanningSidebar += "- Project Planning`n"
            $projectPlanningSidebar += Build-DocsSectionSidebar -SectionPath $projectPlanningPath -RootPath $rootPath
        }

        # Generate Observability section
        $observabilityPath = Join-Path $docsPath "observability"
        $observabilitySidebar = ""
        if (Test-Path $observabilityPath) {
            Write-Host "📊 Generating Observability section..." -ForegroundColor Yellow
            $observabilitySidebar += "- Observability`n"
            $observabilitySidebar += Build-DocsSectionSidebar -SectionPath $observabilityPath -RootPath $rootPath
        }

        # Generate Solution ADR Library section
        $solutionAdrPath = Join-Path $docsPath "solution-adr-library"
        $solutionAdrSidebar = ""
        if (Test-Path $solutionAdrPath) {
            Write-Host "📚 Generating Solution ADR Library section..." -ForegroundColor Yellow
            $solutionAdrSidebar += "- Solution ADR Library`n"
            $solutionAdrSidebar += Build-DocsSectionSidebar -SectionPath $solutionAdrPath -RootPath $rootPath
        }

        # Generate Solution Security Plan Library section
        $solutionSecurityPath = Join-Path $docsPath "solution-security-plan-library"
        $solutionSecuritySidebar = ""
        if (Test-Path $solutionSecurityPath) {
            Write-Host "🔒 Generating Solution Security Plan Library section..." -ForegroundColor Yellow
            $solutionSecuritySidebar += "- Solution Security Plan Library`n"
            $solutionSecuritySidebar += Build-DocsSectionSidebar -SectionPath $solutionSecurityPath -RootPath $rootPath
        }

        # Generate Solution Technology Paper Library section
        $solutionTechPath = Join-Path $docsPath "solution-technology-paper-library"
        $solutionTechSidebar = ""
        if (Test-Path $solutionTechPath) {
            Write-Host "🔬 Generating Solution Technology Paper Library section..." -ForegroundColor Yellow
            $solutionTechSidebar += "- Solution Technology Paper Library`n"
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

            $blueprintsSidebar += "- Blueprints`n"
            $blueprintsSidebar += Build-ComponentsSidebar -SrcPath $blueprintsPath -RootPath $rootPath
            $blueprintsSidebar += Build-BicepSidebar -SrcPath $blueprintsPath -RootPath $rootPath
            $blueprintsSidebar += Build-TerraformSidebar -SrcPath $blueprintsPath -RootPath $rootPath
        }

        # Generate special files section
        $specialFilesSidebar = Build-SpecialFilesSidebar -DocsPath $resolvedDocsPath -RootPath $rootPath

        # Combine all sections with proper spacing
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss UTC"
        $allSections = @()

        # Add each non-empty section
        if ($mainSidebar.Trim()) { $allSections += $mainSidebar.TrimEnd() }

        if ($gettingStartedSidebar.Trim()) { $allSections += $gettingStartedSidebar.TrimEnd() }
        if ($projectPlanningSidebar.Trim()) { $allSections += $projectPlanningSidebar.TrimEnd() }
        if ($blueprintsSidebar.Trim()) { $allSections += $blueprintsSidebar.TrimEnd() }

        if ($contributingSidebar.Trim()) { $allSections += $contributingSidebar.TrimEnd() }

        if ($solutionAdrSidebar.Trim()) { $allSections += $solutionAdrSidebar.TrimEnd() }
        if ($solutionSecuritySidebar.Trim()) { $allSections += $solutionSecuritySidebar.TrimEnd() }
        if ($solutionTechSidebar.Trim()) { $allSections += $solutionTechSidebar.TrimEnd() }

        # if ($templatesSidebar.Trim()) { $allSections += $templatesSidebar.TrimEnd() }

        if ($infrastructureSidebar.Trim()) { $allSections += $infrastructureSidebar.TrimEnd() }

        if ($observabilitySidebar.Trim()) { $allSections += $observabilitySidebar.TrimEnd() }
        if ($buildCicdSidebar.Trim()) { $allSections += $buildCicdSidebar.TrimEnd() }

        if ($specialFilesSidebar.Trim()) { $allSections += $specialFilesSidebar.TrimEnd() }

        $sidebarContent = @"
<!-- markdownlint-disable MD041 -->
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

    }
    catch {
        Write-Error "Error generating sidebar: $($_.Exception.Message)"
        Write-Error "Stack trace: $($_.ScriptStackTrace)"
        exit 1
    }
}

# Main execution
Main
