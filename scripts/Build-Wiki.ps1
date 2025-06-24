#!/usr/bin/env pwsh

<#
.SYNOPSIS
    Build-Wiki.ps1 - Azure DevOps Wiki Builder for Edge AI Repository

.DESCRIPTION
    This PowerShell script builds an Azure DevOps Wiki structure from the repository's
    markdown documentation. It parses the navigation structure from docs/_sidebar.md
    and recreates the exact hierarchical folder structure in the wiki output, complete with
    .order files for proper navigation that matches the documentation sidebar.

.FUNCTIONALITY
    - Parses docs/_sidebar.md to extract complete 4-level navigation hierarchy
    - Creates wiki structure with proper directory hierarchy and .order files at every level
    - Copies and processes markdown files with comprehensive URL token replacement
    - Updates relative links to work correctly in the new wiki structure
    - Handles special content organization (blueprints, terraform, bicep, infrastructure code)
    - Generates Azure DevOps-compatible wiki structure with proper file naming conventions

.PARAMETERS
    None - The script uses predefined paths and settings from environment variables

.ENVIRONMENT VARIABLES
    - BUILD_REPOSITORY_URI: The Git repository URL (used for URL token replacement)
    - BUILD_REPOSITORY_NAME: The name of the repository (used for URL token replacement)
    - SYSTEM_TEAMFOUNDATIONCOLLECTIONURI: The Azure DevOps organization URL (used for URL token replacement)
    - SYSTEM_TEAMPROJECT: The name of the Azure DevOps project (used for URL token replacement)

.OUTPUTS
    Creates .wiki folder with complete hierarchical wiki structure including:
    - Root-level and nested .order files defining navigation sequence
    - Properly named folders and files following Azure DevOps Wiki conventions
    - Processed markdown files with updated URLs and relative links
    - Integrated blueprint documentation

.EXAMPLE
    ./Build-Wiki.ps1

    Builds the complete wiki structure with navigation that exactly matches docs/_sidebar.md

.NOTES
    This script is designed to be called directly from Azure DevOps pipelines using pwsh.
    It replaces the previous bash-based wiki-build.sh approach with comprehensive
    PowerShell-based processing that ensures the Azure DevOps Wiki navigation
    structure exactly matches the documentation sidebar hierarchy.

    Key Features:
    - Recursive sidebar parsing for complex navigation structures
    - Comprehensive .order file generation at all levels
    - Robust relative link updating with path mapping
    - Azure DevOps Wiki naming convention compliance
    - Preserved blueprint integration functionality

.LINK
    Azure DevOps Wiki Documentation: https://docs.microsoft.com/azure/devops/project/wiki/
#>

[CmdletBinding()]
param()

# Configuration
$WikiRepoFolder = ".wiki"
$SidebarFile = "docs/_sidebar.md"

# Ensure clean wiki directory
Write-Host "Setting up wiki directory..."
if (Test-Path $WikiRepoFolder) {
    Get-ChildItem $WikiRepoFolder -Exclude ".git" | Remove-Item -Recurse -Force
} else {
    New-Item -ItemType Directory -Path $WikiRepoFolder -Force | Out-Null
}

# Navigation structure to track hierarchy
class WikiNavItem {
    [string]$Title
    [string]$Path
    [string]$DestPath
    [int]$Level
    [bool]$IsFolder
    [bool]$HasContent
    [System.Collections.Generic.List[WikiNavItem]]$Children
    [WikiNavItem]$Parent

    WikiNavItem([string]$title, [string]$path, [int]$level) {
        $this.Title = $title
        $this.Path = $path
        $this.Level = $level
        $this.Children = [System.Collections.Generic.List[WikiNavItem]]::new()

        # Determine if this is a folder or content
        $this.HasContent = -not [string]::IsNullOrWhiteSpace($path)
        $this.IsFolder = $false  # Will be set to true if children are added
    }

    # Method to add a child and update folder status
    [void] AddChild([WikiNavItem]$child) {
        $this.Children.Add($child)
        $child.Parent = $this
        $this.IsFolder = $true  # This item becomes a folder when it has children
    }
}

function ConvertFrom-SidebarNavigation {
    <#
    .SYNOPSIS
        Converts the docs/_sidebar.md file to extract navigation structure for Azure DevOps Wiki
    .DESCRIPTION
        Handles all sidebar patterns including:
        - Section headers without links (create folders)
        - Content pages with links
        - Nested hierarchies up to 4 levels
        - Preserves original navigation order
    .OUTPUTS
        Returns the root navigation items with hierarchical structure
    #>

    if (-not (Test-Path $SidebarFile)) {
        throw "Sidebar file not found: $SidebarFile"
    }

    Write-Host "Parsing sidebar navigation from $SidebarFile..."

    $content = Get-Content $SidebarFile -Raw
    $lines = $content -split "`n"
    $rootItems = [System.Collections.Generic.List[WikiNavItem]]::new()
    $stack = [System.Collections.Generic.Stack[WikiNavItem]]::new()

    foreach ($line in $lines) {
        # Skip comments, empty lines, and generated timestamps
        if ($line.Trim().StartsWith('<!--') -or $line.Trim() -eq '' -or $line.Trim().StartsWith('<!-- Generated')) {
            continue
        }

        # Parse markdown list items - handle all patterns
        if ($line -match '^(\s*)[-\*]\s+(.+)$') {
            $indent = $matches[1].Length
            $level = [Math]::Floor($indent / 2)
            $content = $matches[2].Trim()

            # Extract title and path
            $title = ""
            $path = ""

            # Handle different formats:
            # [Title](path) - Regular link (content page)
            # **[Title](path)** - Bold link (content page)
            # **Title** - Bold heading (section header, no link)
            # Title - Plain text (section header, no link)
            if ($content -match '^\*\*\[([^\]]+)\]\(([^)]+)\)\*\*$') {
                # **[Title](path)** - Bold link
                $title = $matches[1]
                $path = $matches[2]
            } elseif ($content -match '^\[([^\]]+)\]\(([^)]+)\)$') {
                # [Title](path) - Regular link
                $title = $matches[1]
                $path = $matches[2]
            } elseif ($content -match '^\*\*([^*]+)\*\*$') {
                # **Title** - Bold section header (no link)
                $title = $matches[1]
                $path = ""
            } else {
                # Plain text - Section header (no link)
                $title = $content
                $path = ""
            }

            if ($title) {
                $navItem = [WikiNavItem]::new($title, $path, $level)

                # Find parent based on level and manage the stack
                while ($stack.Count -gt 0 -and $stack.Peek().Level -ge $level) {
                    $stack.Pop() | Out-Null
                }

                if ($stack.Count -gt 0) {
                    $parent = $stack.Peek()
                    $parent.AddChild($navItem)
                } else {
                    $rootItems.Add($navItem)
                }

                $stack.Push($navItem)
            }
        }
    }

    Write-Host "Parsed $($rootItems.Count) root navigation items with $(($rootItems | ForEach-Object { Get-NavItemCount $_ }) | Measure-Object -Sum).Sum total items"
    return $rootItems
}

function Get-NavItemCount {
    <#
    .SYNOPSIS
        Recursively counts navigation items for reporting
    #>
    param([WikiNavItem]$Item)

    $count = 1
    foreach ($child in $Item.Children) {
        $count += Get-NavItemCount $child
    }
    return $count
}

function Get-SafeFileName {
    <#
    .SYNOPSIS
        Converts a title to a safe filename for Azure DevOps Wiki pages
    .DESCRIPTION
        Ensures compliance with Azure DevOps Wiki naming conventions:
        - Converts spaces to hyphens
        - Normalizes to lowercase for consistent folder naming
        - Removes invalid characters
        - Prevents case sensitivity conflicts
        - Limits length appropriately
    #>
    param([string]$Title)

    if ([string]::IsNullOrWhiteSpace($Title)) {
        return "unnamed"
    }

    # Remove leading/trailing whitespace
    $safe = $Title.Trim()

    # Replace spaces with hyphens
    $safe = $safe -replace '\s+', '-'

    # Convert to lowercase for consistent folder naming
    $safe = $safe.ToLowerInvariant()

    # Remove invalid characters for Azure DevOps Wiki, keeping allowed special chars
    # Allowed: colon, brackets, asterisk, question mark, pipe, hyphen, quotes
    $safe = $safe -replace '[^\w\-:><*?|"'']', ''

    # Remove multiple consecutive hyphens
    $safe = $safe -replace '-+', '-'

    # Remove leading/trailing hyphens and periods
    $safe = $safe -replace '^[-\.]+|[-\.]+$', ''

    # Ensure we have something left
    if ([string]::IsNullOrWhiteSpace($safe)) {
        $safe = "unnamed"
    }

    # Limit length to ensure full path stays under 235 characters
    if ($safe.Length -gt 100) {
        $safe = $safe.Substring(0, 100).TrimEnd('-')
    }

    return $safe
}

function Build-WikiStructure {
    <#
    .SYNOPSIS
        Builds the Azure DevOps Wiki directory structure and .order files based on navigation
    .DESCRIPTION
        Creates proper folder hierarchy for section headers, generates .order files at every level,
        handles README.md files correctly, and ensures proper file placement and naming
    #>
    param(
        [System.Collections.Generic.List[WikiNavItem]]$NavItems,
        [string]$BasePath = $WikiRepoFolder
    )

    $orderItems = @()

    Write-Host "Building wiki structure in: $BasePath"

    foreach ($navItem in $NavItems) {
        $hasChildren = $navItem.Children.Count -gt 0
        $hasContent = $navItem.HasContent

        if ($hasChildren) {
            # This item needs a folder (either because it has children or is a section header)
            $folderName = Get-SafeFileName $navItem.Title
            $folderPath = Join-Path $BasePath $folderName

            # Create the folder
            if (-not (Test-Path $folderPath)) {
                New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
                Write-Host "  Created folder: $folderName"
            }

            # Add folder to order list
            $orderItems += $folderName

            # If this item has content (like a README.md), copy it as index.md in the folder
            if ($hasContent) {
                $sourcePath = $navItem.Path

                if (Test-Path $sourcePath) {
                    $destPath = Join-Path $folderPath "index.md"
                    Copy-Item $sourcePath $destPath -Force
                    Write-Host "    Copied content as index: $sourcePath -> $destPath"
                    $navItem.DestPath = $destPath
                } else {
                    Write-Warning "    Source file not found: $sourcePath"
                }
            }

            # Recursively process children
            if ($navItem.Children.Count -gt 0) {
                Build-WikiStructure -NavItems $navItem.Children -BasePath $folderPath
            }

        } elseif ($hasContent) {
            # This is a standalone content page (no children)
            $sourcePath = $navItem.Path

            if (Test-Path $sourcePath) {
                # Determine destination filename
                $fileName = Split-Path $sourcePath -Leaf
                $destFileName = $fileName

                # Handle README.md files - convert to descriptive name based on parent folder
                if ($fileName -eq "README.md") {
                    $parentDir = Split-Path (Split-Path $sourcePath -Parent) -Leaf
                    $destFileName = "$(Get-SafeFileName $parentDir).md"
                }

                $destPath = Join-Path $BasePath $destFileName
                Copy-Item $sourcePath $destPath -Force
                Write-Host "  Copied file: $fileName -> $destFileName"
                $navItem.DestPath = $destPath

                # Add to order list (without .md extension)
                $orderName = [System.IO.Path]::GetFileNameWithoutExtension($destFileName)
                $orderItems += $orderName
            } else {
                Write-Warning "  Source file not found: $sourcePath"
            }
        } else {
            # This is a section header with no content and no children - create empty folder
            $folderName = Get-SafeFileName $navItem.Title
            $folderPath = Join-Path $BasePath $folderName

            if (-not (Test-Path $folderPath)) {
                New-Item -ItemType Directory -Path $folderPath -Force | Out-Null
                Write-Host "  Created empty section folder: $folderName"
            }

            $orderItems += $folderName
        }
    }

    # Create .order file for this level
    if ($orderItems.Count -gt 0) {
        $orderPath = Join-Path $BasePath ".order"
        $orderItems | Out-File $orderPath -Encoding UTF8
        Write-Host "  Created .order file with $($orderItems.Count) items: $(Split-Path $orderPath -Parent)"

        # Debug: Show order file contents
        Write-Host "    Order: $($orderItems -join ', ')" -ForegroundColor Gray
    }
}

function New-UrlConfiguration {
    <#
    .SYNOPSIS
        Generates URL configuration for Azure DevOps Wiki using environment variables
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param()

    Write-Host "Generating Azure DevOps Wiki URL configuration..."

    # Extract organization name from SYSTEM_TEAMFOUNDATIONCOLLECTIONURI
    $orgName = ""
    # cspell:ignore SYSTEM_TEAMFOUNDATIONCOLLECTIONURI orgName
    if ($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI) {
        $orgName = ($env:SYSTEM_TEAMFOUNDATIONCOLLECTIONURI -replace 'https://dev\.azure\.com/', '') -replace '/$', ''
    }

    $urlConfig = @{
        azdo = @{
            REPO_URL = $env:BUILD_REPOSITORY_URI
            REPO_BASE_URL = "$($env:BUILD_REPOSITORY_URI)?path="
            DOCS_BASE_URL = "https://dev.azure.com/$orgName/$($env:SYSTEM_TEAMPROJECT)/_wiki/wikis/$($env:BUILD_REPOSITORY_NAME)"
            CLONE_URL = $env:BUILD_REPOSITORY_URI
            NEW_ISSUE_URL = "https://dev.azure.com/$orgName/$($env:SYSTEM_TEAMPROJECT)/_workitems/create/Issue"
            ISSUES_URL = "https://dev.azure.com/$orgName/$($env:SYSTEM_TEAMPROJECT)/_workitems"
            DISCUSSIONS_URL = "https://dev.azure.com/$orgName/$($env:SYSTEM_TEAMPROJECT)/_boards/queries"
            LICENSE_URL = "$($env:BUILD_REPOSITORY_URI)?path=/LICENSE"
        }
    }

    # Create url-config.json
    $configPath = "scripts/url-config.json"
    if ($PSCmdlet.ShouldProcess($configPath, "Create URL configuration file")) {
        $urlConfig | ConvertTo-Json -Depth 3 | Out-File $configPath -Encoding UTF8
        Write-Host "Generated URL configuration: $configPath"
    }

    return $urlConfig.azdo
}

function Update-UrlToken {
    <#
    .SYNOPSIS
        Replaces URL tokens in all wiki markdown files
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([hashtable]$UrlMappings)

    Write-Host "Replacing URL tokens in wiki documentation..."

    $markdownFiles = Get-ChildItem $WikiRepoFolder -Filter "*.md" -Recurse

    foreach ($file in $markdownFiles) {
        $content = Get-Content $file.FullName -Raw
        $modified = $false

        foreach ($token in $UrlMappings.Keys) {
            $tokenPattern = "{{{$token}}}"
            if ($content -match [regex]::Escape($tokenPattern)) {
                $content = $content -replace [regex]::Escape($tokenPattern), $UrlMappings[$token]
                $modified = $true
                Write-Host "  Replaced $tokenPattern in $($file.Name)"
            }
        }

        if ($modified -and $PSCmdlet.ShouldProcess($file.FullName, "Update URL tokens")) {
            $content | Out-File $file.FullName -Encoding UTF8 -NoNewline
        }
    }

    Write-Host "URL token replacement completed."
}

function Copy-BlueprintReadme {
    param (
        [string]$SourceDir,
        [string]$WikiDir
    )

    Write-Host "Copying blueprint README files..." -ForegroundColor Cyan

    # Find all blueprint README files
    $blueprintPath = Join-Path $SourceDir "blueprints"
    $infrastructureCodePath = Join-Path $WikiDir "infrastructure-code"
    $blueprintDocPath = Join-Path $WikiDir "blueprint-documentation"

    if (Test-Path $blueprintPath) {
        # Get all blueprint subdirectories that contain README.md
        $blueprintDirs = Get-ChildItem -Path $blueprintPath -Directory

        # Copy main blueprint README files to infrastructure-code (existing functionality)
        foreach ($blueprintDir in $blueprintDirs) {
            $readmePath = Join-Path $blueprintDir.FullName "README.md"
            if (Test-Path $readmePath) {
                # Extract blueprint name and sanitize for filename
                $blueprintName = $blueprintDir.Name
                $targetFileName = "$blueprintName.md"
                $targetPath = Join-Path $infrastructureCodePath $targetFileName

                Write-Host "  Copying main blueprint README: $blueprintName" -ForegroundColor Gray

                # Ensure target directory exists
                $targetDir = Split-Path $targetPath -Parent
                if (!(Test-Path $targetDir)) {
                    New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
                }

                # Copy the file
                $content = Get-Content $readmePath -Raw -Encoding UTF8
                Set-Content -Path $targetPath -Value $content -Encoding UTF8

                Write-Host "    → infrastructure-code/$targetFileName" -ForegroundColor DarkGray
            }
        }

        # Copy terraform-specific README files to blueprint-documentation/terraform-blueprints
        $terraformBlueprintsPath = Join-Path $blueprintDocPath "terraform-blueprints"
        if (!(Test-Path $terraformBlueprintsPath)) {
            New-Item -ItemType Directory -Path $terraformBlueprintsPath -Force | Out-Null
        }

        $terraformFiles = @()
        foreach ($blueprintDir in $blueprintDirs) {
            $terraformReadmePath = Join-Path -Path $blueprintDir.FullName -ChildPath "terraform/README.md"
            if (Test-Path $terraformReadmePath) {
                $blueprintName = $blueprintDir.Name
                $targetFileName = "$blueprintName.md"
                $targetPath = Join-Path $terraformBlueprintsPath $targetFileName

                Write-Host "  Copying terraform blueprint README: $blueprintName" -ForegroundColor Gray

                # Copy the file
                $content = Get-Content $terraformReadmePath -Raw -Encoding UTF8
                Set-Content -Path $targetPath -Value $content -Encoding UTF8

                $terraformFiles += $blueprintName
                Write-Host "    → blueprint-documentation/terraform-blueprints/$targetFileName" -ForegroundColor DarkGray
            }
        }

        # Copy bicep-specific README files to blueprint-documentation/bicep-blueprints
        $bicepBlueprintsPath = Join-Path $blueprintDocPath "bicep-blueprints"
        if (!(Test-Path $bicepBlueprintsPath)) {
            New-Item -ItemType Directory -Path $bicepBlueprintsPath -Force | Out-Null
        }

        $bicepFiles = @()
        foreach ($blueprintDir in $blueprintDirs) {
            $bicepReadmePath = Join-Path -Path $blueprintDir.FullName -ChildPath "bicep/README.md"
            if (Test-Path $bicepReadmePath) {
                $blueprintName = $blueprintDir.Name
                $targetFileName = "$blueprintName.md"
                $targetPath = Join-Path $bicepBlueprintsPath $targetFileName

                Write-Host "  Copying bicep blueprint README: $blueprintName" -ForegroundColor Gray

                # Copy the file
                $content = Get-Content $bicepReadmePath -Raw -Encoding UTF8
                Set-Content -Path $targetPath -Value $content -Encoding UTF8

                $bicepFiles += $blueprintName
                Write-Host "    → blueprint-documentation/bicep-blueprints/$targetFileName" -ForegroundColor DarkGray
            }
        }

        # Update .order file for infrastructure-code (existing functionality)
        $orderFile = Join-Path $infrastructureCodePath ".order"
        if (Test-Path $orderFile) {
            $orderContent = Get-Content $orderFile -Encoding UTF8
            $blueprintFiles = Get-ChildItem -Path $infrastructureCodePath -Name "*.md" | Where-Object {
                $_ -match "^(full-|minimum-|only-|partial-|fabric)"
            } | Sort-Object

            # Add blueprint files to order if not already present
            $updatedOrder = @()
            $updatedOrder += $orderContent
            foreach ($file in $blueprintFiles) {
                $fileName = [System.IO.Path]::GetFileNameWithoutExtension($file)
                if ($fileName -notin $orderContent) {
                    $updatedOrder += $fileName
                }
            }

            Set-Content -Path $orderFile -Value $updatedOrder -Encoding UTF8
            Write-Host "  Updated infrastructure-code/.order file with blueprint READMEs" -ForegroundColor Gray
        }

        # Update .order file for terraform-blueprints
        if ($terraformFiles.Count -gt 0) {
            $terraformOrderFile = Join-Path $terraformBlueprintsPath ".order"
            $sortedTerraformFiles = $terraformFiles | Sort-Object
            Set-Content -Path $terraformOrderFile -Value $sortedTerraformFiles -Encoding UTF8
            Write-Host "  Updated blueprint-documentation/terraform-blueprints/.order file" -ForegroundColor Gray
        }

        # Update .order file for bicep-blueprints
        if ($bicepFiles.Count -gt 0) {
            $bicepOrderFile = Join-Path $bicepBlueprintsPath ".order"
            $sortedBicepFiles = $bicepFiles | Sort-Object
            Set-Content -Path $bicepOrderFile -Value $sortedBicepFiles -Encoding UTF8
            Write-Host "  Updated blueprint-documentation/bicep-blueprints/.order file" -ForegroundColor Gray
        }

    } else {
        Write-Host "  Blueprint directory not found: $blueprintPath" -ForegroundColor Yellow
    }
}

function Update-RelativeLink {
    <#
    .SYNOPSIS
        Updates relative links in markdown files to work with the new wiki folder structure
    .DESCRIPTION
        Processes all markdown files to fix relative links that may have broken due to
        files being moved into new folder structures based on the navigation hierarchy
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [System.Collections.Generic.List[WikiNavItem]]$AllNavItems
    )

    Write-Host "Updating relative links for new wiki structure..."

    # Create a mapping of original paths to new wiki paths
    $pathMapping = @{}

    function Build-PathMapping {
        param([System.Collections.Generic.List[WikiNavItem]]$NavItems, [string]$BasePath = "")

        foreach ($navItem in $NavItems) {
            if ($navItem.HasContent -and $navItem.DestPath) {
                # Map original path to new wiki path relative to wiki root
                $originalRelativePath = $navItem.Path -replace "^docs/", ""
                $wikiRelativePath = $navItem.DestPath -replace [regex]::Escape($WikiRepoFolder + "\"), ""
                $pathMapping[$originalRelativePath] = $wikiRelativePath

                Write-Host "  Mapped: $originalRelativePath -> $wikiRelativePath" -ForegroundColor Gray
            }

            if ($navItem.Children.Count -gt 0) {
                Build-PathMapping -NavItems $navItem.Children -BasePath $BasePath
            }
        }
    }

    # Build the path mapping
    Build-PathMapping -NavItems $AllNavItems

    # Process all markdown files in the wiki
    $markdownFiles = Get-ChildItem $WikiRepoFolder -Filter "*.md" -Recurse

    foreach ($file in $markdownFiles) {
        $content = Get-Content $file.FullName -Raw
        $modified = $false
        $fileDir = Split-Path $file.FullName -Parent
        $fileRelativeDir = $fileDir -replace [regex]::Escape($WikiRepoFolder + "\"), ""

        # Find markdown links [text](path)
        $linkPattern = '\[([^\]]*)\]\(([^)]+)\)'
        $linkMatches = [regex]::Matches($content, $linkPattern)

        foreach ($match in $linkMatches) {
            $linkPath = $match.Groups[2].Value

            # Skip external links (http/https)
            if ($linkPath -match '^https?://') {
                continue
            }

            # Skip anchor links
            if ($linkPath -match '^#') {
                continue
            }

            # Handle relative links to other docs
            if ($linkPath -match '\.md$' -and -not ($linkPath -match '^/')) {
                # This is a relative link to another markdown file
                $originalPath = $linkPath

                # If the link starts with ../ or ./, resolve it relative to the original docs structure
                if ($linkPath -match '^\.\.?/') {
                    # For now, let's normalize these by removing the relative indicators
                    # and checking if we have the target in our path mapping
                    $cleanPath = $linkPath -replace '^\.\.?/', ''

                    if ($pathMapping.ContainsKey($cleanPath)) {
                        $newPath = $pathMapping[$cleanPath]

                        # Calculate relative path from current file to target file
                        $relativePath = Get-RelativePath -From $fileRelativeDir -To (Split-Path $newPath -Parent)
                        $fileName = Split-Path $newPath -Leaf

                        if ($relativePath) {
                            $updatedLink = "$relativePath/$fileName"
                        } else {
                            $updatedLink = $fileName
                        }

                        $content = $content -replace [regex]::Escape("($originalPath)"), "($updatedLink)"
                        $modified = $true
                        Write-Host "    Updated link in $($file.Name): $originalPath -> $updatedLink" -ForegroundColor Yellow
                    }
                }
            }
        }

        if ($modified) {
            $content | Out-File $file.FullName -Encoding UTF8 -NoNewline
        }
    }

    Write-Host "Relative link updates completed."
}

function Get-RelativePath {
    <#
    .SYNOPSIS
        Calculate relative path from one directory to another
    #>
    param([string]$From, [string]$To)

    if ([string]::IsNullOrEmpty($From) -or [string]::IsNullOrEmpty($To)) {
        return $To
    }

    $fromParts = $From -split '[/\\]' | Where-Object { $_ }
    $toParts = $To -split '[/\\]' | Where-Object { $_ }

    # Find common base
    $commonLength = 0
    for ($i = 0; $i -lt [Math]::Min($fromParts.Length, $toParts.Length); $i++) {
        if ($fromParts[$i] -eq $toParts[$i]) {
            $commonLength++
        } else {
            break
        }
    }

    # Calculate how many levels to go up
    $upLevels = $fromParts.Length - $commonLength
    $relativeParts = @()

    for ($i = 0; $i -lt $upLevels; $i++) {
        $relativeParts += ".."
    }

    # Add the remaining parts of the target path
    for ($i = $commonLength; $i -lt $toParts.Length; $i++) {
        $relativeParts += $toParts[$i]
    }

    if ($relativeParts.Length -eq 0) {
        return ""
    }

    return ($relativeParts -join "/")
}

function Build-StandaloneContent {
    <#
    .SYNOPSIS
        Discovers and processes standalone content from new folders not covered by sidebar navigation
    .DESCRIPTION
        Processes content from:
        - .github/prompts/ (AI prompt files)
        - .github/chatmodes/ (Chat mode configurations)
        - .github/instructions/ (Instruction files)
        - copilot/ (AI assistant guides and conventions)
        - praxisworx/ (Training and learning content)
    .PARAMETER WikiDir
        The target wiki directory where content should be copied
    #>
    param([string]$WikiDir)

    Write-Host "Processing standalone content from new folders..." -ForegroundColor Cyan

    # Define standalone content folders to process
    $standaloneContent = @{
        "copilot" = @{
            SourcePath = "copilot"
            WikiSection = "copilot-guides"
            DisplayName = "Copilot Guides"
            Description = "AI assistant instructions and development conventions"
        }
        "praxisworx" = @{
            SourcePath = "praxisworx"
            WikiSection = "praxisworx"
            DisplayName = "PraxisWorx"
            Description = "Training materials and learning resources"
        }
        "github-prompts" = @{
            SourcePath = ".github/prompts"
            WikiSection = "github-resources"
            DisplayName = "GitHub Resources"
            Description = "AI prompts, chat modes, and instructions"
        }
        "github-chatmodes" = @{
            SourcePath = ".github/chatmodes"
            WikiSection = "github-resources"
            DisplayName = "Chat Modes"
            Description = "AI chat mode configurations"
        }
        "github-instructions" = @{
            SourcePath = ".github/instructions"
            WikiSection = "github-resources"
            DisplayName = "Instructions"
            Description = "Development and contribution instructions"
        }
    }

    # Process each standalone content area
    foreach ($contentKey in $standaloneContent.Keys) {
        $config = $standaloneContent[$contentKey]
        $sourcePath = $config.SourcePath
        $wikiSection = $config.WikiSection
        $displayName = $config.DisplayName

        if (Test-Path $sourcePath) {
            Write-Host "  Processing $displayName from $sourcePath..." -ForegroundColor Gray

            # Create or ensure wiki section directory exists
            $wikiSectionPath = Join-Path $WikiDir $wikiSection
            if (-not (Test-Path $wikiSectionPath)) {
                New-Item -ItemType Directory -Path $wikiSectionPath -Force | Out-Null
                Write-Host "    Created wiki section: $wikiSection" -ForegroundColor DarkGray
            }

            # Process content based on folder structure
            Copy-StandaloneFolder -SourcePath $sourcePath -DestPath $wikiSectionPath -ContentKey $contentKey -Config $config
        } else {
            Write-Host "  Skipping $displayName - source folder not found: $sourcePath" -ForegroundColor Yellow
        }
    }

    # Create master .order file for standalone sections
    New-StandaloneSectionsOrder -WikiDir $WikiDir -ContentConfig $standaloneContent
}

function Copy-StandaloneFolder {
    <#
    .SYNOPSIS
        Copies content from a standalone folder to the wiki structure
    .DESCRIPTION
        Handles various content types and maintains folder structure while creating appropriate .order files
    #>
    param(
        [string]$SourcePath,
        [string]$DestPath,
        [string]$ContentKey,
        [hashtable]$Config
    )

    $orderItems = @()

    # Get all markdown files in the source directory
    $markdownFiles = Get-ChildItem -Path $SourcePath -Filter "*.md" -Recurse
    $subDirectories = Get-ChildItem -Path $SourcePath -Directory

    # Process subdirectories first
    foreach ($subDir in $subDirectories) {
        $subDirName = Get-SafeFileName $subDir.Name
        $subDirDestPath = Join-Path $DestPath $subDirName

        if (-not (Test-Path $subDirDestPath)) {
            New-Item -ItemType Directory -Path $subDirDestPath -Force | Out-Null
        }

        # Recursively copy subdirectory content
        Copy-StandaloneFolder -SourcePath $subDir.FullName -DestPath $subDirDestPath -ContentKey "$ContentKey-$subDirName" -Config $Config
        $orderItems += $subDirName

        Write-Host "    Processed subdirectory: $($subDir.Name)" -ForegroundColor DarkGray
    }

    # Process markdown files in current directory
    $rootFiles = $markdownFiles | Where-Object { $_.Directory.FullName -eq (Resolve-Path $SourcePath).Path }

    foreach ($file in $rootFiles) {
        $fileName = $file.Name
        $destFileName = $fileName

        # Handle special naming for certain file types
        if ($fileName -eq "README.md") {
            $parentDirName = Split-Path $SourcePath -Leaf
            $destFileName = "$(Get-SafeFileName $parentDirName)-overview.md"
        }

        $destFilePath = Join-Path $DestPath $destFileName
        Copy-Item -Path $file.FullName -Destination $destFilePath -Force

        # Add to order (without .md extension)
        $orderName = [System.IO.Path]::GetFileNameWithoutExtension($destFileName)
        $orderItems += $orderName

        Write-Host "    Copied: $fileName -> $destFileName" -ForegroundColor DarkGray
    }

    # Create .order file for this directory level
    if ($orderItems.Count -gt 0) {
        $orderPath = Join-Path $DestPath ".order"
        $orderItems | Out-File $orderPath -Encoding UTF8
        Write-Host "    Created .order file with $($orderItems.Count) items in $DestPath" -ForegroundColor DarkGray
    }
}

function New-StandaloneSectionsOrder {
    <#
    .SYNOPSIS
        Creates or updates the root .order file to include standalone content sections
    .DESCRIPTION
        Ensures that standalone content sections are properly ordered in the wiki navigation
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [string]$WikiDir,
        [hashtable]$ContentConfig
    )

    $rootOrderPath = Join-Path $WikiDir ".order"
    $existingOrder = @()

    # Read existing order if it exists
    if (Test-Path $rootOrderPath) {
        $existingOrder = Get-Content $rootOrderPath | Where-Object { $_.Trim() -ne '' }
    }

    # Add standalone sections that exist
    $sectionsToAdd = @()
    foreach ($contentKey in $ContentConfig.Keys) {
        $config = $ContentConfig[$contentKey]
        $wikiSection = $config.WikiSection
        $wikiSectionPath = Join-Path $WikiDir $wikiSection

        if ((Test-Path $wikiSectionPath) -and ($wikiSection -notin $existingOrder) -and ($wikiSection -notin $sectionsToAdd)) {
            $sectionsToAdd += $wikiSection
        }
    }

    if ($sectionsToAdd.Count -gt 0 -and $PSCmdlet.ShouldProcess($rootOrderPath, "Update root .order file with standalone sections")) {
        $newOrder = $existingOrder + $sectionsToAdd
        $newOrder | Out-File $rootOrderPath -Encoding UTF8
        Write-Host "  Updated root .order file with standalone sections: $($sectionsToAdd -join ', ')" -ForegroundColor Green
    }
}

# Function to update relative links in standalone content
function Update-StandaloneRelativeLink {
    <#
    .SYNOPSIS
        Updates relative links in standalone content to work within the wiki structure
    .DESCRIPTION
        Handles link updates for content that was moved from original locations to wiki sections
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$WikiDir)

    Write-Host "Updating relative links in standalone content..." -ForegroundColor Cyan

    # Define path mappings for standalone content
    $pathMappings = @{
        "copilot/" = "copilot-guides/"
        "praxisworx/" = "praxisworx/"
        ".github/prompts/" = "github-resources/"
        ".github/chatmodes/" = "github-resources/"
        ".github/instructions/" = "github-resources/"
    }

    # Get all markdown files in standalone sections
    $standaloneFiles = @()
    foreach ($mapping in $pathMappings.Values) {
        $sectionPath = Join-Path $WikiDir $mapping
        if (Test-Path $sectionPath) {
            $standaloneFiles += Get-ChildItem -Path $sectionPath -Filter "*.md" -Recurse
        }
    }

    foreach ($file in $standaloneFiles) {
        $content = Get-Content $file.FullName -Raw
        $modified = $false

        # Update relative links that reference the original source locations
        foreach ($originalPath in $pathMappings.Keys) {
            $newPath = $pathMappings[$originalPath]
            $pattern = "(\]\(\.\.?\/$originalPath)"

            if ($content -match $pattern) {
                $content = $content -replace $pattern, "](../$newPath"
                $modified = $true
                Write-Host "    Updated link in $($file.Name): ../$originalPath -> ../$newPath" -ForegroundColor Yellow
            }
        }

        if ($modified -and $PSCmdlet.ShouldProcess($file.FullName, "Update relative links")) {
            $content | Out-File $file.FullName -Encoding UTF8 -NoNewline
        }
    }

    Write-Host "Standalone content link updates completed." -ForegroundColor Green
}

# Main execution
try {
    Write-Host "Starting Azure DevOps Wiki build process..."

    # Parse navigation structure
    $navItems = ConvertFrom-SidebarNavigation

    # Build wiki structure based on navigation
    Write-Host "Building wiki structure based on sidebar navigation..."
    Build-WikiStructure -NavItems $navItems

    # Copy standalone content (follows blueprint pattern)
    Write-Host "Copying standalone content from new folders..."
    Build-StandaloneContent -WikiDir $WikiRepoFolder

    # Update relative links to work with new folder structure
    Write-Host "Updating relative links for new wiki structure..."
    Update-RelativeLink -AllNavItems $navItems

    # Generate URL configuration and replace tokens
    $urlMappings = New-UrlConfiguration
    Update-UrlToken -UrlMappings $urlMappings

    # Copy blueprint README files to Infrastructure Code section
    Copy-BlueprintReadme -SourceDir "." -WikiDir $WikiRepoFolder

    Write-Host "Wiki build completed successfully!"
    Write-Host "Wiki structure created in: $WikiRepoFolder"

} catch {
    Write-Error "Wiki build failed: $($_.Exception.Message)"
    Write-Error $_.Exception.StackTrace
    exit 1
}
