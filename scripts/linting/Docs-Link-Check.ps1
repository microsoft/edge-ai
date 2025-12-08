<#
.SYNOPSIS
    Repository-aware wrapper for markdown-link-check.

.DESCRIPTION
    Runs markdown-link-check with the repo-specific configuration for validating
    markdown links across documentation files. Uses replacement patterns in the
    configuration file to handle root-relative paths and ensure links resolve
    correctly for both Docsify navigation and GitHub file browsing.

.PARAMETER Path
    One or more files or directories to scan. Directories are searched
    recursively for Markdown files. Defaults to the Docsify navigation sources.

.PARAMETER ConfigPath
    Path to the shared markdown-link-check configuration file.

.PARAMETER Quiet
    Suppress non-error output from markdown-link-check.

.EXAMPLE
    # Validate default Docsify navigation files
    ./Docs-Link-Check.ps1

.EXAMPLE
    # Validate custom documentation folder with verbose output
    ./Docs-Link-Check.ps1 -Path docs/getting-started -Quiet:$false

.EXAMPLE
    # Validate specific markdown file
    ./Docs-Link-Check.ps1 -Path README.md
    #>

[CmdletBinding()]
param(
    [string[]]$Path = @(
        "docs/_sidebar.md",
        "docs/_parts/docs-sidebar.md"
    ),

    [string]$ConfigPath = (Join-Path -Path $PSScriptRoot -ChildPath 'markdown-link-check.config.json'),

    [switch]$Quiet
)
<#
.SYNOPSIS
    Resolves Markdown files to validate from provided path arguments.

.DESCRIPTION
    Accepts files or directories, expanding directories to all Markdown files
    discovered recursively, and returns a sorted, unique list of absolute file
    paths for downstream validation.

.PARAMETER InputPath
    Files or directories that may contain Markdown content.

.OUTPUTS
    System.String[]
#>
function Get-MarkdownTarget {
    param(
        [string[]]$InputPath
    )

    $targets = @()

    foreach ($item in $InputPath) {
        if ([string]::IsNullOrWhiteSpace($item)) {
            continue
        }

        $resolved = Resolve-Path -LiteralPath $item -ErrorAction SilentlyContinue
        if (-not $resolved) {
            Write-Warning "Unable to resolve path: $item"
            continue
        }

        foreach ($resolvedPath in $resolved) {
            if (Test-Path -LiteralPath $resolvedPath -PathType Container) {
                $targets += Get-ChildItem -LiteralPath $resolvedPath -Recurse -Include *.md | Where-Object { -not $_.PSIsContainer } | Select-Object -ExpandProperty FullName
            }
            else {
                $targets += $resolvedPath.ProviderPath
            }
        }
    }

    return ($targets | Sort-Object -Unique)
}

$scriptRootParent = Split-Path -Path $PSScriptRoot -Parent
$repoRootPath = Split-Path -Path $scriptRootParent -Parent
$repoRoot = Resolve-Path -LiteralPath $repoRootPath
$config = Resolve-Path -LiteralPath $ConfigPath -ErrorAction Stop
$filesToCheck = Get-MarkdownTarget -InputPath $Path

if (-not $filesToCheck -or $filesToCheck.Count -eq 0) {
    Write-Error 'No markdown files were found to validate.'
    exit 1
}

$cli = Join-Path -Path $repoRoot.Path -ChildPath 'node_modules/.bin/markdown-link-check'
if ($IsWindows) {
    $cli += '.cmd'
}

if (-not (Test-Path -LiteralPath $cli)) {
    Write-Error 'markdown-link-check is not installed. Run "npm install --save-dev markdown-link-check" first.'
    exit 1
}

$baseArguments = @('-c', $config.Path)
if ($Quiet) {
    $baseArguments += '-q'
}

$failedFiles = @()

Push-Location $repoRoot.Path
try {
    foreach ($file in $filesToCheck) {
        $absolute = Resolve-Path -LiteralPath $file
        $relative = [System.IO.Path]::GetRelativePath($repoRoot.Path, $absolute)
        Write-Output "Checking $relative"

        $commandArgs = $baseArguments + @($relative)
        & $cli @commandArgs
        $exitCode = $LASTEXITCODE

        if ($exitCode -ne 0) {
            $failedFiles += $relative
        }
    }

    if ($failedFiles.Count -gt 0) {
        Write-Error ("markdown-link-check reported failures for: {0}" -f ($failedFiles -join ', '))
        exit 1
    }

    Write-Output 'markdown-link-check completed successfully.'
}
finally {
    Pop-Location
}
