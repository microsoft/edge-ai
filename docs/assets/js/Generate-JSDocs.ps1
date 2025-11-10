#Requires -Version 5.1

<#
.SYNOPSIS
    Generates JSDoc API documentation from JavaScript source files.

.DESCRIPTION
    This PowerShell script generates comprehensive JSDoc documentation for the JavaScript
    codebase, with validation and error checking.

.PARAMETER DocsDir
    Output directory for generated documentation. Default: './docs/api'

.PARAMETER ConfigFile
    JSDoc configuration file path. Default: './.jsdoc.json'

.PARAMETER SourceDir
    Source directory to scan for JavaScript files. Default: '.'

.PARAMETER Force
    Force regeneration by removing existing output directory first.

.EXAMPLE
    .\Generate-JSDocs.ps1

.EXAMPLE
    .\Generate-JSDocs.ps1 -DocsDir "./output/docs" -Force

.EXAMPLE
    .\Generate-JSDocs.ps1 -ConfigFile "./custom-jsdoc.json" -Verbose
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [Parameter(Mandatory = $false)]
    [string]$DocsDir = './docs/api',

    [Parameter(Mandatory = $false)]
    [string]$ConfigFile = './.jsdoc.json',

    [Parameter(Mandatory = $false)]
    [string]$SourceDir = '.',

    [Parameter(Mandatory = $false)]
    [switch]$Force
)

#region Helper Functions

# Ensure script parameters are used to avoid PowerShell analyzer warnings
$script:UseDocsDir = $DocsDir
$script:UseConfigFile = $ConfigFile
$script:UseSourceDir = $SourceDir
$script:UseForce = $Force

function Write-LogInfo {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-LogWarn {
    param([string]$Message)
    Write-Host "[WARN] $Message" -ForegroundColor Yellow
}

function Write-LogError {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

function Test-JSDocInstalled {
    <#
    .SYNOPSIS
        Checks if JSDoc to Markdown is installed and available in PATH.
    #>
    try {
        $null = Get-Command jsdoc2md -ErrorAction Stop
        return $true
    }
    catch {
        Write-LogError "jsdoc-to-markdown is not installed. Please install it using:"
        Write-LogError "  npm install -g jsdoc-to-markdown"
        return $false
    }
}

function New-OutputDirectory {
    <#
    .SYNOPSIS
        Creates the output directory for documentation.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param([string]$Path)

    if ($script:UseForce -and (Test-Path $Path)) {
        if ($PSCmdlet.ShouldProcess($Path, "Remove existing output directory")) {
            Write-LogInfo "Removing existing output directory: $Path"
            Remove-Item -Path $Path -Recurse -Force
        }
    }

    if (-not (Test-Path $Path)) {
        if ($PSCmdlet.ShouldProcess($Path, "Create output directory")) {
            Write-LogInfo "Creating output directory: $Path"
            $null = New-Item -Path $Path -ItemType Directory -Force
        }
    }
}

function Invoke-JSDocGeneration {
    <#
    .SYNOPSIS
        Generates JSDoc documentation in Markdown format using jsdoc-to-markdown.
    #>
    param(
        [string]$OutputPath,
        [string]$SourcePath
    )

    Write-LogInfo "Generating JSDoc documentation in Markdown format..."

    try {
        # Get all JavaScript files recursively from the source directory
        Write-Host "Finding JavaScript files in: $SourcePath" -ForegroundColor Cyan
        $jsFiles = Get-ChildItem -Path $SourcePath -Recurse -File -Include "*.js" |
        Where-Object {
            $_.Name -notlike "*.min.js" -and
            $_.FullName -notlike "*/tests/*" -and
            $_.FullName -notlike "*/docs/api/*" -and
            $_.FullName -notlike "**/node_modules/**"
        }

        Write-Host "Found $($jsFiles.Count) JavaScript files to document." -ForegroundColor Green

        if ($jsFiles.Count -eq 0) {
            Write-LogWarn "No JavaScript files found in source directory: $SourcePath"
            return
        }

        # Create main API documentation file paths
        $apiDocPath = Join-Path $OutputPath "api.md"
        $readmePath = Join-Path $OutputPath "README.md"

        # Generate documentation by processing files in smaller batches
        Write-LogInfo "Processing JavaScript files in batches to avoid command line length limits..."

        $allMarkdownContent = @()
        $batchSize = 10
        $batches = [Math]::Ceiling($jsFiles.Count / $batchSize)

        for ($i = 0; $i -lt $batches; $i++) {
            $start = $i * $batchSize
            $end = [Math]::Min($start + $batchSize - 1, $jsFiles.Count - 1)
            $batch = $jsFiles[$start..$end]

            Write-Host "Processing batch $($i + 1) of $batches ($($batch.Count) files)..." -ForegroundColor Cyan

            $batchFiles = $batch | ForEach-Object { $_.FullName }

            try {
                $batchContent = & jsdoc2md $batchFiles --no-cache 2>&1 | Out-String
                if ($batchContent -and $batchContent.Trim()) {
                    $allMarkdownContent += $batchContent
                    Write-Host "  ✓ Batch $($i + 1) completed successfully" -ForegroundColor Green
                }
                else {
                    Write-Host "  ⚠ Batch $($i + 1) produced no content" -ForegroundColor Yellow
                }
            }
            catch {
                Write-LogWarn "Batch $($i + 1) failed: $($_.Exception.Message)"
            }
        }

        # Combine all markdown content
        $markdownContent = $allMarkdownContent -join "`n`n"

        # Create the main API documentation file
        if ($markdownContent -and $markdownContent.Trim()) {
            $frontmatter = @"
---
title: JavaScript API Documentation
description: Comprehensive API documentation for the Edge AI learning system JavaScript components
author: Edge AI Team
ms.date: $(Get-Date -Format 'yyyy-MM-dd')
ms.topic: api-documentation
estimated_reading_time: 15
keywords:
  - javascript api
  - jsdoc
  - documentation
  - components
  - modules
  - classes
  - functions
---

# JavaScript API Documentation

This documentation provides comprehensive API reference for all JavaScript components in the Edge AI learning system.

"@

            $fullContent = $frontmatter + "`n" + $markdownContent + "`n`n" + @"

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
"@

            Set-Content -Path $apiDocPath -Value $fullContent -Encoding UTF8
            Write-LogInfo "Created main API documentation: $apiDocPath"

            # Also create a README.md for the api directory
            $readmeContent = @"
---
title: API Documentation
description: JavaScript API documentation directory for the Edge AI learning system
author: Edge AI Team
ms.date: $(Get-Date -Format 'yyyy-MM-dd')
ms.topic: api-overview
estimated_reading_time: 2
keywords:
  - api documentation
  - javascript
  - overview
---

# API Documentation

This directory contains the generated API documentation for the JavaScript components of the Edge AI learning system.

## Documentation Files

- [**api.md**](api.md) - Complete API reference for all JavaScript modules, classes, and functions

## About This Documentation

This documentation is automatically generated from JSDoc comments in the source code using jsdoc-to-markdown, ensuring it stays up-to-date with the latest code changes.

## Navigation

Use the sidebar navigation to browse through different sections of the API documentation, or refer to the comprehensive [API reference](api.md) for detailed information about all available components.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
"@

            Set-Content -Path $readmePath -Value $readmeContent -Encoding UTF8
            Write-LogInfo "Created API documentation README: $readmePath"
        }
        else {
            Write-LogError "No markdown content was generated"
            throw "Markdown generation failed"
        }
    }
    catch {
        Write-LogError "Failed to generate documentation: $($_.Exception.Message)"
        throw
    }
}

function Test-GeneratedDocumentation {
    <#
    .SYNOPSIS
        Validates the generated Markdown documentation output.
    #>
    param([string]$OutputPath)

    if (-not (Test-Path $OutputPath)) {
        Write-LogError "Documentation generation failed - output directory does not exist"
        return $false
    }

    $markdownFiles = Get-ChildItem -Path $OutputPath -Filter "*.md" -Recurse
    if ($markdownFiles.Count -eq 0) {
        Write-LogError "Documentation generation failed - no Markdown files generated"
        return $false
    }

    Write-LogInfo "Documentation generated successfully in: $OutputPath"
    Write-LogInfo "Generated $($markdownFiles.Count) Markdown documentation files"

    $apiPath = Join-Path $OutputPath "api.md"
    if (Test-Path $apiPath) {
        Write-LogInfo "Main API documentation file created: $apiPath"
    }
    else {
        Write-LogWarn "No api.md found in output directory"
    }

    $readmePath = Join-Path $OutputPath "README.md"
    if (Test-Path $readmePath) {
        Write-LogInfo "API directory README created: $readmePath"
    }

    return $true
}

#endregion

#region Main Execution

function Invoke-Main {
    <#
    .SYNOPSIS
        Main execution function for JSDoc documentation generation.
    #>
    try {
        Write-LogInfo "Starting JSDoc documentation generation..."

        # Validate JSDoc installation
        if (-not (Test-JSDocInstalled)) {
            exit 1
        }

        # Create output directory
        New-OutputDirectory -Path $script:UseDocsDir

        # Generate documentation
        Invoke-JSDocGeneration -OutputPath $script:UseDocsDir -SourcePath $script:UseSourceDir

        # Validate generated output
        if (-not (Test-GeneratedDocumentation -OutputPath $script:UseDocsDir)) {
            exit 1
        }

        Write-LogInfo "JSDoc documentation generation completed successfully!"
        Write-LogInfo "View the documentation at $($script:UseDocsDir)/api.md or through Docsify"
    }
    catch {
        Write-LogError "Documentation generation failed: $($_.Exception.Message)"
        if ($_.Exception.InnerException) {
            Write-LogError "Inner exception: $($_.Exception.InnerException.Message)"
        }
        exit 1
    }
}

# Execute main function if script is run directly
if ($MyInvocation.InvocationName -ne '.') {
    Invoke-Main
}

#endregion

