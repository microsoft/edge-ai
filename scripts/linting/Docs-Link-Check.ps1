<#
.SYNOPSIS
    Repository-aware wrapper for markdown-link-check.

.DESCRIPTION
    Runs markdown-link-check with the repo-specific configuration that normalizes
    Docsify hash-route navigation (e.g. #/docs/...) into real file paths so the
    validator succeeds while the published docs continue to use hash routing.
    This preserves Docsify behaviour at runtime and keeps GitHub/Azure DevOps
    browsing workable, with link validation handling the trade-off.

.PARAMETER Path
    One or more files or directories to scan. Directories are searched
    recursively for Markdown files. Defaults to the Docsify navigation sources.

.PARAMETER ConfigPath
    Path to the shared markdown-link-check configuration file.

.PARAMETER Quiet
    Suppress non-error output from markdown-link-check.

.EXAMPLE
    # Validate Docsify navigation files with hash-route normalization
    ./Docs-Link-Check.ps1

.EXAMPLE
    # Validate custom documentation folder with verbose output
    ./Docs-Link-Check.ps1 -Path docs/getting-started -Quiet:$false
    #>

[CmdletBinding()]
param(
    [string[]]$Path = @(
        "docs/_sidebar.md",
        "docs/_navbar.md",
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
<#
.SYNOPSIS
    Builds a normalized relative prefix between two paths.

.DESCRIPTION
    Computes the relative path from a source directory to a destination and
    enforces forward-slash separators with a trailing slash when required to
    produce consistent link prefixes.

.PARAMETER FromPath
    The directory from which the relative path should be calculated.

.PARAMETER ToPath
    The target path that should be expressed relative to the source.

.OUTPUTS
    System.String
#>
function Get-RelativePrefix {
    param(
        [string]$FromPath,
        [string]$ToPath
    )

    $relative = [System.IO.Path]::GetRelativePath($FromPath, $ToPath)
    if ([string]::IsNullOrWhiteSpace($relative) -or $relative -eq '.') {
        return ''
    }

    $normalized = $relative -replace '\\', '/'
    if (-not $normalized.EndsWith('/')) {
        $normalized += '/'
    }

    return $normalized
}
<#
.SYNOPSIS
    Converts Docsify hash-route anchors into file-based links.

.DESCRIPTION
    Replaces Docsify hash-route anchors (e.g. #/docs/...) with paths that
    resolve on disk, enabling markdown-link-check to validate content without
    altering the original files.

.PARAMETER Content
    Markdown content potentially containing Docsify hash-route anchors.

.PARAMETER DocsPrefix
    Relative prefix inserted when rewriting #/docs/ links.

.PARAMETER RootPrefix
    Relative prefix inserted when rewriting root-level hash routes.

.OUTPUTS
    System.String
#>
function Convert-DocsifyLink {
    param(
        [string]$Content,
        [string]$DocsPrefix,
        [string]$RootPrefix
    )

    $updatedContent = $Content

    $docsMatches = [System.Text.RegularExpressions.Regex]::Matches($updatedContent, '#/docs/([^\s)"]+)')
    foreach ($match in $docsMatches) {
        $replacement = '{0}{1}' -f $DocsPrefix, $match.Groups[1].Value
        $updatedContent = $updatedContent.Replace($match.Value, $replacement)
    }

    $rootMatches = [System.Text.RegularExpressions.Regex]::Matches($updatedContent, '#/([^\s)"]+)')
    foreach ($match in $rootMatches) {
        $replacement = '{0}{1}' -f $RootPrefix, $match.Groups[1].Value
        $updatedContent = $updatedContent.Replace($match.Value, $replacement)
    }

    return $updatedContent
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

        $fileDirectory = Split-Path -Path $absolute.Path -Parent
        $docsPrefix = Get-RelativePrefix -FromPath $fileDirectory -ToPath (Join-Path -Path $repoRoot.Path -ChildPath 'docs')
        $rootPrefix = Get-RelativePrefix -FromPath $fileDirectory -ToPath $repoRoot.Path
        $originalContent = Get-Content -LiteralPath $absolute.Path -Raw
        $sanitizedContent = Convert-DocsifyLink -Content $originalContent -DocsPrefix $docsPrefix -RootPrefix $rootPrefix

        $tempPath = $null
        $pathForCli = $relative

        if ($sanitizedContent -ne $originalContent) {
            $tempFileName = '.mcl-{0}-{1}' -f ([System.Guid]::NewGuid().ToString('N')), [System.IO.Path]::GetFileName($absolute.Path)
            $tempPath = Join-Path -Path $fileDirectory -ChildPath $tempFileName
            [System.IO.File]::WriteAllText($tempPath, $sanitizedContent, [System.Text.Encoding]::UTF8)
            $pathForCli = [System.IO.Path]::GetRelativePath($repoRoot.Path, $tempPath)
        }

        try {
            $commandArgs = $baseArguments + @($pathForCli)
            & $cli @commandArgs
            $exitCode = $LASTEXITCODE

            if ($exitCode -ne 0) {
                $failedFiles += $relative
            }
        }
        finally {
            if ($tempPath) {
                Remove-Item -LiteralPath $tempPath -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
finally {
    Pop-Location
}

if ($failedFiles.Count -gt 0) {
    Write-Error ("markdown-link-check reported failures for: {0}" -f ($failedFiles -join ', '))
    exit 1
}

Write-Output 'markdown-link-check completed successfully.'
