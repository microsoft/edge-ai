#Requires -Version 5.1

<#
.SYNOPSIS
    Enhanced three-tree navigation generator for Edge AI documentation.

.DESCRIPTION
    This PowerShell module enhances the Docsify sidebar generation by creating
    a three-tree navigation structure:

    1. Bicep Documentation Tree - Organized documentation for Bicep templates
    2. Terraform Documentation Tree - Organized documentation for Terraform modules
    3. README Documentation Tree - Documentation based on README.md files

    The module is designed to work with Generate-DocsSidebar.ps1 to produce
    a comprehensive navigation sidebar that follows best practices for documentation.

.PARAMETER None
    This script is imported as a module and doesn't accept direct parameters.

.EXAMPLE
    Import-Module ./Three-Tree-Enhancement.ps1

    # Then use its exported functions in your sidebar generation script
    $bicepTree = Get-BicepDocumentationTree -RootPath "./src"

.NOTES
    This module is part of the Edge AI documentation automation system.
    It's automatically invoked by the GitHub workflow during documentation build.
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# Script-wide variables
$script:debugMode = $false
$script:indentationChar = "  "

# Tree structure types
enum TreeType {
    Bicep
    Terraform
    Readme
}

# Enable advanced debugging information when -Verbose is used
if ($VerbosePreference -eq "Continue") {
    $script:debugMode = $true
    Write-Verbose "Three-Tree Enhancement module loaded in DEBUG mode"
}

#region Core Functions

function Get-TreeIndentation {
    <#
    .SYNOPSIS
        Returns proper indentation string based on depth level

    .DESCRIPTION
        Generates a string with the appropriate indentation for the tree structure
        based on the specified level depth.

    .PARAMETER Level
        The indentation level (zero-based)

    .EXAMPLE
        Get-TreeIndentation -Level 2
        # Returns four spaces (assuming indentationChar is two spaces)
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 100)]
        [int]$Level
    )

    return $script:indentationChar * $Level
}

function Get-DocumentTitle {
    <#
    .SYNOPSIS
        Extracts document title from frontmatter or content

    .DESCRIPTION
        Attempts to extract a title from a markdown document using the following precedence:
        1. Frontmatter "title" key (if present)
        2. First heading in the document
        3. Filename without extension as fallback

    .PARAMETER FilePath
        The path to the markdown file

    .EXAMPLE
        Get-DocumentTitle -FilePath "./docs/README.md"

    .EXAMPLE
        Get-ChildItem -Path "./docs" -Filter "*.md" | Get-DocumentTitle
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true, ValueFromPipelineByPropertyName = $true)]
        [ValidateNotNullOrEmpty()]
        [Alias("FullName")]
        [string]$FilePath
    )

    begin {
        # Initialize any variables needed across all pipeline executions
        $hasMarkdownFileCmd = Get-Command -Name Get-MarkdownFile -ErrorAction SilentlyContinue
    }

    process {
        # Check if function Get-MarkdownFile exists and file exists
        if ($hasMarkdownFileCmd -and
            (Test-Path -Path $FilePath -ErrorAction SilentlyContinue)) {
            $frontmatter = Get-MarkdownFile -FilePath $FilePath

            if ($null -ne $frontmatter -and
                $frontmatter.PSObject.Properties.Name -contains 'Frontmatter' -and
                $frontmatter.Frontmatter.ContainsKey("title")) {
                return $frontmatter.Frontmatter["title"]
            }
        }

        # Fall back to first heading or filename
        try {
            $content = Get-Content -Path $FilePath -ErrorAction Stop
            foreach ($line in $content) {
                if ($line -match '^#\s+(.+)') {
                    return $matches[1].Trim()
                }
            }
        }
        catch {
            Write-Verbose -Message "Failed to read content from $FilePath : $_"
        }

        # Final fallback to filename without extension
        return [System.IO.Path]::GetFileNameWithoutExtension($FilePath)
    }
}

function Get-SortOrderFromFilename {
    <#
    .SYNOPSIS
        Extracts numeric sort order from filename pattern like 000-component-name

    .DESCRIPTION
        Parses filenames or directory names that follow the pattern "000-name-format"
        and extracts the numeric prefix for sorting purposes.

    .PARAMETER FileName
        The filename or directory name to analyze

    .EXAMPLE
        Get-SortOrderFromFilename -FileName "010-security-identity"
        # Returns 10

    .EXAMPLE
        "010-security-identity", "020-networking" | Get-SortOrderFromFilename
        # Returns 10, 20
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param (
        [Parameter(Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$FileName
    )

    process {
        if ($FileName -match '^(\d{3})-') {
            return [int]$matches[1]
        }

        return 999 # Default high value for items without sort order
    }
}

function Format-NavigationItem {
    <#
    .SYNOPSIS
        Formats a navigation item for the sidebar

    .DESCRIPTION
        Creates a properly formatted Markdown navigation item with the correct
        indentation level for inclusion in the documentation sidebar.

    .PARAMETER Title
        The title text to display for the navigation item

    .PARAMETER Path
        The relative path to the document

    .PARAMETER Level
        The indentation level for the item

    .EXAMPLE
        Format-NavigationItem -Title "Security" -Path "docs/security.md" -Level 2
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Title,

        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$Path,

        [Parameter(Mandatory = $true)]
        [ValidateRange(0, 10)]
        [int]$Level
    )

    $indentation = Get-TreeIndentation -Level $Level
    return "$indentation- [$Title]($Path)"
}

#endregion

#region Tree Building Functions

function Get-BicepDocumentationTree {
    <#
    .SYNOPSIS
        Builds the Bicep documentation navigation tree

    .DESCRIPTION
        Scans the specified root path for Bicep documentation and organizes it
        into a hierarchical navigation tree based on component structure.

    .PARAMETER RootPath
        The root directory to search for Bicep documentation

    .PARAMETER BaseLevel
        The base indentation level for the tree (default: 0)

    .EXAMPLE
        Get-BicepDocumentationTree -RootPath "./src" -BaseLevel 1
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RootPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$BaseLevel = 0
    )

    $tree = @()

    # Find all Bicep documentation
    $bicepPaths = Get-ChildItem -Path $RootPath -Recurse -Include "*.md" -ErrorAction SilentlyContinue |
                  Where-Object {
                      $_.FullName -like "*bicep*" -and
                      $_.Name -notmatch "_(\w+)\.md$" -and
                      $_.FullName -notlike "*node_modules*"
                  }

    if ($bicepPaths.Count -eq 0) {
        Write-Verbose "No Bicep documentation found in $RootPath"
        return [string[]]$tree
    }

    # Group by component folders (e.g., 000-cloud/010-security-identity/bicep)
    $bicepComponents = $bicepPaths | ForEach-Object {
        $relPath = $_.FullName.Replace($RootPath, "").TrimStart("/\")
        $pathSegments = $relPath.Split("/\".ToCharArray(), [StringSplitOptions]::RemoveEmptyEntries)

        # Try to extract component path details
        $component = $null
        $grouping = $null
        $bicepIndex = [array]::IndexOf($pathSegments, "bicep")

        if ($bicepIndex -gt 0) {
            $component = $pathSegments[$bicepIndex - 1]
            if ($bicepIndex -gt 1) {
                $grouping = $pathSegments[$bicepIndex - 2]
            }
        }

        [PSCustomObject]@{
            FilePath = $_.FullName
            RelativePath = $relPath
            Grouping = $grouping
            Component = $component
            Title = Get-DocumentTitle -FilePath $_.FullName
            SortOrder = Get-SortOrderFromFilename -FileName $(if ($component) { $component } else { $_.Name })
        }
    }

    # Group by grouping and component
    $groupedComponents = $bicepComponents | Group-Object -Property Grouping

    # Sort groupings by numeric prefix in name
    $sortedGroupings = $groupedComponents | Sort-Object -Property {
        Get-SortOrderFromFilename -FileName $_.Name
    }

    # Generate tree
    $tree += "# Bicep Infrastructure"
    foreach ($grouping in $sortedGroupings) {
        $groupName = $grouping.Name
        if ([string]::IsNullOrEmpty($groupName)) {
            $groupName = "General Documentation"
        }

        # Find a representative component to extract grouping name if possible
        $firstComponent = $grouping.Group | Select-Object -First 1
        if ($firstComponent -and $firstComponent.Grouping -match '\d{3}-(.+)') {
            $groupName = $matches[1].Replace("-", " ").Trim()
            $groupName = (Get-Culture).TextInfo.ToTitleCase($groupName)
        }

        $tree += "$(Get-TreeIndentation -Level $($BaseLevel+1))- $groupName"

        $sortedComponents = $grouping.Group | Sort-Object -Property SortOrder

        foreach ($component in $sortedComponents) {
            $pathForLink = $component.RelativePath.Replace("\", "/")
            $linkTitle = $component.Title

            # Extract component name from pattern if available
            if ($component.Component -match '\d{3}-(.+)') {
                $componentName = $matches[1].Replace("-", " ").Trim()
                $componentName = (Get-Culture).TextInfo.ToTitleCase($componentName)
                $linkTitle = $componentName
            }

            $tree += Format-NavigationItem -Title $linkTitle -Path $pathForLink -Level ($BaseLevel+2)
        }
    }

    return [string[]]$tree
}

function Get-TerraformDocumentationTree {
    <#
    .SYNOPSIS
        Builds the Terraform documentation navigation tree

    .DESCRIPTION
        Scans the specified root path for Terraform documentation and organizes it
        into a hierarchical navigation tree based on component structure.

    .PARAMETER RootPath
        The root directory to search for Terraform documentation

    .PARAMETER BaseLevel
        The base indentation level for the tree (default: 0)

    .EXAMPLE
        Get-TerraformDocumentationTree -RootPath "./src" -BaseLevel 1
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RootPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$BaseLevel = 0
    )

    $tree = @()

    # Find all Terraform documentation
    $tfPaths = Get-ChildItem -Path $RootPath -Recurse -Include "*.md" -ErrorAction SilentlyContinue |
               Where-Object {
                   $_.FullName -like "*terraform*" -and
                   $_.Name -notmatch "_(\w+)\.md$" -and
                   $_.FullName -notlike "*node_modules*"
               }

    if ($tfPaths.Count -eq 0) {
        Write-Verbose "No Terraform documentation found in $RootPath"
        return [string[]]$tree
    }

    # Group by component folders (e.g., 000-cloud/010-security-identity/terraform)
    $tfComponents = $tfPaths | ForEach-Object {
        $relPath = $_.FullName.Replace($RootPath, "").TrimStart("/\")
        $pathSegments = $relPath.Split("/\".ToCharArray(), [StringSplitOptions]::RemoveEmptyEntries)

        # Try to extract component path details
        $component = $null
        $grouping = $null
        $tfIndex = [array]::IndexOf($pathSegments, "terraform")

        if ($tfIndex -gt 0) {
            $component = $pathSegments[$tfIndex - 1]
            if ($tfIndex -gt 1) {
                $grouping = $pathSegments[$tfIndex - 2]
            }
        }

        [PSCustomObject]@{
            FilePath = $_.FullName
            RelativePath = $relPath
            Grouping = $grouping
            Component = $component
            Title = Get-DocumentTitle -FilePath $_.FullName
            SortOrder = Get-SortOrderFromFilename -FileName $(if ($component) { $component } else { $_.Name })
        }
    }

    # Group by grouping and component
    $groupedComponents = $tfComponents | Group-Object -Property Grouping

    # Sort groupings by numeric prefix in name
    $sortedGroupings = $groupedComponents | Sort-Object -Property {
        Get-SortOrderFromFilename -FileName $_.Name
    }

    # Generate tree
    $tree += "# Terraform Infrastructure"
    foreach ($grouping in $sortedGroupings) {
        $groupName = $grouping.Name
        if ([string]::IsNullOrEmpty($groupName)) {
            $groupName = "General Documentation"
        }

        # Find a representative component to extract grouping name if possible
        $firstComponent = $grouping.Group | Select-Object -First 1
        if ($firstComponent -and $firstComponent.Grouping -match '\d{3}-(.+)') {
            $groupName = $matches[1].Replace("-", " ").Trim()
            $groupName = (Get-Culture).TextInfo.ToTitleCase($groupName)
        }

        $tree += "$(Get-TreeIndentation -Level $($BaseLevel+1))- $groupName"

        $sortedComponents = $grouping.Group | Sort-Object -Property SortOrder

        foreach ($component in $sortedComponents) {
            $pathForLink = $component.RelativePath.Replace("\", "/")
            $linkTitle = $component.Title

            # Extract component name from pattern if available
            if ($component.Component -match '\d{3}-(.+)') {
                $componentName = $matches[1].Replace("-", " ").Trim()
                $componentName = (Get-Culture).TextInfo.ToTitleCase($componentName)
                $linkTitle = $componentName
            }

            $tree += Format-NavigationItem -Title $linkTitle -Path $pathForLink -Level ($BaseLevel+2)
        }
    }

    return [string[]]$tree
}

function Get-ReadmeDocumentationTree {
    <#
    .SYNOPSIS
        Builds the README documentation navigation tree from README.md files

    .DESCRIPTION
        Scans the specified root path for README.md files and organizes them
        into a hierarchical navigation tree, prioritizing components that follow
        the numeric prefix naming convention.

    .PARAMETER RootPath
        The root directory to search for README.md files

    .PARAMETER BaseLevel
        The base indentation level for the tree (default: 0)

    .EXAMPLE
        Get-ReadmeDocumentationTree -RootPath "./src" -BaseLevel 1
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$RootPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$BaseLevel = 0
    )

    $tree = @()

    # Find all README.md files (case insensitive)
    $readmePaths = Get-ChildItem -Path $RootPath -Recurse -ErrorAction SilentlyContinue |
                  Where-Object {
                      $_.Name -match "^readme\.md$" -and
                      $_.FullName -notlike "*node_modules*"
                  }

    if ($readmePaths.Count -eq 0) {
        Write-Verbose "No README.md files found in $RootPath"
        return [string[]]$tree
    }

    # Process README files
    $readmeDocs = $readmePaths | ForEach-Object {
        $relPath = $_.FullName.Replace($RootPath, "").TrimStart("/\")
        $pathSegments = $relPath.Split("/\".ToCharArray(), [StringSplitOptions]::RemoveEmptyEntries)
        $pathDepth = $pathSegments.Count - 1 # Subtract 1 for filename itself

        [PSCustomObject]@{
            FilePath = $_.FullName
            RelativePath = $relPath
            ParentFolder = Split-Path -Parent $relPath
            Depth = $pathDepth
            Title = Get-DocumentTitle -FilePath $_.FullName
            SortOrder = Get-SortOrderFromFilename -FileName $(Split-Path -Parent $relPath)
        }
    }

    # Generate tree - start with components with numeric prefix sorting
    $tree += "# Component Documentation"

    # Get top-level components first (depth typically 1 or 2)
    $topLevelComponents = $readmeDocs | Where-Object { $_.ParentFolder -match '^\d{3}-' -or $_.ParentFolder -match '[\/\\]\d{3}-' }

    # Group by parent directory
    $groupedByParent = $topLevelComponents | Group-Object -Property {
        $parent = $_.ParentFolder
        if ($parent -match '(^\d{3}-[^\/\\]+|[\/\\]\d{3}-[^\/\\]+)') {
            return $matches[1].TrimStart("/\")
        }
        return $parent
    }

    # Sort groups by the numeric prefix
    $sortedGroups = $groupedByParent | Sort-Object -Property {
        if ($_.Name -match '^\d{3}-') {
            return [int]($_.Name.Substring(0, 3))
        }
        return 999
    }

    foreach ($group in $sortedGroups) {
        $groupName = $group.Name

        # Try to make the group name more readable
        if ($groupName -match '\d{3}-(.+)') {
            $groupName = $matches[1].Replace("-", " ").Trim()
            $groupName = (Get-Culture).TextInfo.ToTitleCase($groupName)
        }

        # Add group to tree
        $tree += "$(Get-TreeIndentation -Level $($BaseLevel+1))- $groupName"

        $sortedDocs = $group.Group | Sort-Object -Property SortOrder, RelativePath

        foreach ($doc in $sortedDocs) {
            $pathForLink = $doc.RelativePath.Replace("\", "/")
            $tree += Format-NavigationItem -Title $doc.Title -Path $pathForLink -Level ($BaseLevel+2)
        }
    }

    # Add other READMEs that don't follow the numbered pattern
    $otherReadmes = $readmeDocs | Where-Object {
        $_.ParentFolder -notmatch '^\d{3}-' -and $_.ParentFolder -notmatch '[\/\\]\d{3}-'
    }

    if ($otherReadmes.Count -gt 0) {
        $tree += "$(Get-TreeIndentation -Level $($BaseLevel+1))- Other Documentation"

        $sortedOthers = $otherReadmes | Sort-Object -Property Depth, RelativePath

        foreach ($doc in $sortedOthers) {
            $pathForLink = $doc.RelativePath.Replace("\", "/")
            $level = [Math]::Min($doc.Depth + $BaseLevel + 2, $BaseLevel + 3) # Cap the indentation level
            $tree += Format-NavigationItem -Title $doc.Title -Path $pathForLink -Level $level
        }
    }

    return [string[]]$tree
}

function Get-BlueprintsDocumentationTree {
    <#
    .SYNOPSIS
        Builds the Blueprints documentation navigation tree

    .DESCRIPTION
        Scans the specified blueprints path for documentation files and organizes them
        into a hierarchical navigation tree based on blueprint and framework structure.

    .PARAMETER BlueprintsPath
        The root directory containing blueprint documentation

    .PARAMETER BaseLevel
        The base indentation level for the tree (default: 0)

    .EXAMPLE
        Get-BlueprintsDocumentationTree -BlueprintsPath "./blueprints" -BaseLevel 1
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $true)]
        [ValidateNotNullOrEmpty()]
        [string]$BlueprintsPath,

        [Parameter(Mandatory = $false)]
        [ValidateRange(0, 10)]
        [int]$BaseLevel = 0
    )

    $tree = @()

    if (-not (Test-Path $BlueprintsPath)) {
        Write-Verbose "Blueprints path not found: $BlueprintsPath"
        return [string[]]$tree
    }

    # Find all markdown files in Blueprints folder
    $blueprintDocs = Get-ChildItem -Path $BlueprintsPath -Recurse -Include "*.md" -ErrorAction SilentlyContinue |
                     Where-Object { $_.FullName -notlike "*node_modules*" }

    if ($blueprintDocs.Count -eq 0) {
        Write-Verbose "No Blueprint documentation found in $BlueprintsPath"
        return [string[]]$tree
    }

    # Process blueprint files
    $blueprintItems = $blueprintDocs | ForEach-Object {
        $relPath = $_.FullName.Replace($BlueprintsPath, "").TrimStart("/\")
        $fullRelPath = "blueprints/" + $relPath
        $pathSegments = $relPath.Split("/\".ToCharArray(), [StringSplitOptions]::RemoveEmptyEntries)

        $blueprint = $null
        $framework = $null

        if ($pathSegments.Count -gt 0) {
            $blueprint = $pathSegments[0]
            if ($pathSegments.Count -gt 1) {
                $framework = $pathSegments[1]
            }
        }

        [PSCustomObject]@{
            FilePath = $_.FullName
            RelativePath = $fullRelPath
            Blueprint = $blueprint
            Framework = $framework
            Title = Get-DocumentTitle -FilePath $_.FullName
            IsReadme = $_.Name -match "^readme\.md$"
        }
    }

    # Group by blueprint
    $groupedBlueprints = $blueprintItems | Group-Object -Property Blueprint

    # Add Blueprints section to tree
    $tree += "# Blueprints"

    foreach ($blueprint in $groupedBlueprints) {
        $blueprintName = $blueprint.Name

        # Make blueprint name more readable
        $readableName = $blueprintName.Replace("-", " ").Trim()
        $readableName = (Get-Culture).TextInfo.ToTitleCase($readableName)

        # Add blueprint to tree
        $tree += "$(Get-TreeIndentation -Level $($BaseLevel+1))- $readableName"

        # Get README first if available
        $readme = $blueprint.Group | Where-Object { $_.IsReadme -eq $true } | Select-Object -First 1
        if ($readme) {
            $pathForLink = $readme.RelativePath.Replace("\", "/")
            $tree += Format-NavigationItem -Title "Overview" -Path $pathForLink -Level ($BaseLevel+2)
        }

        # Group by framework
        $byFramework = $blueprint.Group | Where-Object { -not $_.IsReadme } | Group-Object -Property Framework

        foreach ($framework in $byFramework) {
            if (-not [string]::IsNullOrEmpty($framework.Name)) {
                $frameworkName = $framework.Name.Replace("-", " ").Trim()
                $frameworkName = (Get-Culture).TextInfo.ToTitleCase($frameworkName)
                $tree += "$(Get-TreeIndentation -Level $($BaseLevel+2))- $frameworkName"
                $startLevel = $BaseLevel + 3
            } else {
                $startLevel = $BaseLevel + 2
            }

            $frameworkDocs = $framework.Group | Sort-Object -Property RelativePath

            foreach ($doc in $frameworkDocs) {
                $pathForLink = $doc.RelativePath.Replace("\", "/")
                $tree += Format-NavigationItem -Title $doc.Title -Path $pathForLink -Level $startLevel
            }
        }
    }

    return $tree
}

function Merge-DocumentationTree {
    <#
    .SYNOPSIS
        Merges multiple documentation trees into a single navigation structure

    .DESCRIPTION
        Combines documentation trees from different sources into a unified navigation
        structure with proper section headings and organization.

    .PARAMETER MainDocs
        Array of strings representing the main documentation navigation items

    .PARAMETER BicepDocs
        Array of strings representing the Bicep documentation navigation items

    .PARAMETER TerraformDocs
        Array of strings representing the Terraform documentation navigation items

    .PARAMETER ReadmeDocs
        Array of strings representing the README documentation navigation items

    .PARAMETER BlueprintDocs
        Array of strings representing the Blueprint documentation navigation items

    .EXAMPLE
        $merged = Merge-DocumentationTree -BicepDocs $bicepTree -TerraformDocs $terraformTree
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param (
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$MainDocs,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$BicepDocs,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$TerraformDocs,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$ReadmeDocs,

        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [string[]]$BlueprintDocs
    )

    $mergedTree = @()

    # Add main documentation first (if provided)
    if ($MainDocs -and $MainDocs.Count -gt 0) {
        $mergedTree += $MainDocs
        $mergedTree += "" # Empty line for separation
    }

    # Add README documentation (if provided)
    if ($ReadmeDocs -and $ReadmeDocs.Count -gt 0) {
        $mergedTree += $ReadmeDocs
        $mergedTree += "" # Empty line for separation
    }

    # Add Blueprint documentation (if provided)
    if ($BlueprintDocs -and $BlueprintDocs.Count -gt 0) {
        $mergedTree += $BlueprintDocs
        $mergedTree += "" # Empty line for separation
    }

    # Add infrastructure documentation (Bicep and Terraform)
    if (($BicepDocs -and $BicepDocs.Count -gt 0) -or ($TerraformDocs -and $TerraformDocs.Count -gt 0)) {
        $mergedTree += "# Infrastructure as Code"

        if ($BicepDocs -and $BicepDocs.Count -gt 0) {
            foreach ($line in $BicepDocs) {
                if ($line -match '^#\s+') {
                    # Skip the heading as we've already added our own
                    continue
                }
                $mergedTree += $line
            }
        }

        $mergedTree += "" # Empty line for separation

        if ($TerraformDocs -and $TerraformDocs.Count -gt 0) {
            foreach ($line in $TerraformDocs) {
                if ($line -match '^#\s+') {
                    # Skip the heading as we've already added our own
                    continue
                }
                $mergedTree += $line
            }
        }
    }

    return [string[]]$mergedTree
}

#endregion

# Export functions for use in Generate-DocsSidebar.ps1
# Only use Export-ModuleMember if we're in a module context
if ($null -ne $MyInvocation.ScriptName -and $MyInvocation.ScriptName -ne '') {
    # We're being dot-sourced or run directly
    Write-Verbose "Running in script context, not exporting members explicitly"
} else {
    # We're being imported as a module
    Export-ModuleMember -Function @(
        'Get-BicepDocumentationTree',
        'Get-TerraformDocumentationTree',
        'Get-ReadmeDocumentationTree',
        'Get-BlueprintsDocumentationTree',
        'Merge-DocumentationTree'
    )
}

Write-Verbose "Three-Tree-Enhancement module loaded successfully"
