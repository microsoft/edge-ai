<#
.SYNOPSIS
    Find and replace visually similar Unicode characters with ASCII equivalents (or report only).

.DESCRIPTION
    Scans files matching provided paths and reports any lines containing disallowed
    visually similar Unicode characters (curly quotes, special spaces including zero-width,
    en/em dashes, ellipsis). By default, fixes files in-place by replacing disallowed characters
    with ASCII counterparts. Use -OutputOnly to report violations without modifying files.

    Why this script exists: these non-ASCII look-alike characters commonly slip into source
    during copy and paste from documents, chats, web pages, and office apps, and are often
    emitted by AI assistants such as GPT models (for example 4.1, 5, etc.). This repository
    enforces a strict ASCII-only policy for these characters to avoid unreadable diffs,
    broken tooling, and invisible whitespace bugs. The default behavior normalizes affected files;
    use -OutputOnly for a non-destructive report.

    IMPORTANT: This script avoids embedding any disallowed characters in source by constructing
    characters from Unicode code points at runtime.

.PARAMETER Glob
    DEPRECATED. Use -Path instead.

.PARAMETER Path
    One or more paths supporting PowerShell wildcards (handled by providers).
    Examples: ".", "src", "docs/*.md". Combine with -Include/-Exclude/-Filter.

.PARAMETER Filter
    Provider-side filter for improved performance (e.g., "*.md").

.PARAMETER Include
    Wildcard patterns to include. Effective when -Path contains wildcards.

.PARAMETER ExcludeDirectories
    Directory names to exclude from scanning. Defaults to common build and tooling folders
    for this repository to reduce noise:
    .git, .github, .vscode, .devcontainer, .idea, .azure, .cargo, .terraform, node_modules,
    dist, out, build, bin, obj, target, vendor, .venv, venv, env, __pycache__, .pytest_cache,
    coverage, megalinter-reports, checkov-results.
    Note: A path-segment filter is applied so these directories are skipped during recursion
    regardless of provider-side include/exclude behavior.

.PARAMETER Exclude
    Wildcard patterns to exclude, passed directly to Get-ChildItem's -Exclude parameter.
    Use this to exclude files or folders using provider-side filtering semantics.

.PARAMETER NoRecurse
    Do not recurse into subdirectories.

.PARAMETER OutputOnly
    When provided, the script will only report violations and suggested replacements without
    modifying files. By default, files are fixed in-place.

.PARAMETER NoColor
    Disable ANSI color output. By default, output uses ANSI colors to highlight diffs and violating characters.

VERBOSE
    When -Verbose is provided, prints a second line under each match that lists the Unicode name(s) of the violating
    character(s), e.g. "  [EN QUAD, THIN SPACE, HAIR SPACE]". Honors -NoColor for name highlighting.

.PARAMETER Extensions
    Optional whitelist of file extensions to scan (case-insensitive). Defaults to common text and infra files
    used in this repository. Provide values with or without leading dot (e.g., ".md" or "md").

.PARAMETER Quiet
    Suppress all user-facing output (informational, verbose, warnings, progress). Errors still surface. Does not
    suppress -WhatIf/-Confirm messages by design.


.EXAMPLE
    pwsh ./scripts/Fix-VisuallySimilarUnicode.ps1 -Path "docs" -Filter "*.md"

.EXAMPLE
    pwsh ./scripts/Fix-VisuallySimilarUnicode.ps1 -Path "src"


.EXAMPLE
    pwsh ./scripts/Fix-VisuallySimilarUnicode.ps1 -Path "docs" -Verbose

.EXAMPLE
    pwsh ./scripts/Fix-VisuallySimilarUnicode.ps1 -Path "." -OutputOnly
    Performs a non-destructive scan and outputs violations without modifying files.



.OUTPUTS
    For each violating line: relativePath:lineNumber: line content

.NOTES
    Run this from the repository root for best results. The script will skip itself.
#>
[CmdletBinding(DefaultParameterSetName = 'Path', SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
param(
    [Parameter(ParameterSetName = 'Path', Position = 0)]
    [SupportsWildcards()]
    [Alias('FullName')]
    [string[]]$Path = @('.'),

    [Parameter()]
    [string]$Filter,

    [Parameter()]
    [string[]]$Include,

    [Parameter()]
    [string[]]$ExcludeDirectories = @(
        '.git', '.idea', '.azure', '.cargo', '.terraform',
        'node_modules', 'dist', 'out', 'build', 'bin', 'obj',
        '.venv', 'venv', 'env', 'vendor', '__pycache__', '.pytest_cache', 'coverage',
        'megalinter-reports', 'checkov-results'
    ),

    [Parameter()]
    [string[]]$Exclude,

    [Parameter()]
    [switch]$NoRecurse,

    [Parameter()]
    [switch]$OutputOnly,

    [Parameter()]
    [switch]$NoColor,


    [Parameter()]
    [string[]]$Extensions = @(
        '.md', '.mdx',
        '.ps1', '.psm1', '.psd1',
        '.sh', '.bash',
        '.py',
        '.tf', '.tfvars', '.hcl',
        '.bicep',
        '.yaml', '.yml',
        '.json', '.jsonc',
        '.toml', '.ini', '.cfg', '.conf', '.properties',
        '.xml',
        '.ts', '.tsx', '.js', '.jsx',
        '.rs', '.go', '.rb', '.java', '.gradle', '.cs', '.csproj', '.sln',
        '.txt', '.csv'
    ),

    [Parameter()]
    [Alias('Silent', 'Q')]
    [switch]$Quiet
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$InformationPreference = 'Continue'

# When -Quiet is specified, suppress non-error output streams
if ($Quiet) {
    $VerbosePreference = 'SilentlyContinue'
    $InformationPreference = 'SilentlyContinue'
    $WarningPreference = 'SilentlyContinue'
    $ProgressPreference = 'SilentlyContinue'
}

function Get-Definition {
    # Unified definitions map: contains both character metadata and group color pairs
    $esc = [char]27
    $defs = @{
        groups = @{
            # Use background colors instead of foreground colors for highlighting
            'quotes'     = @("${esc}[43m", "${esc}[0m")   # yellow background
            'separators' = @("${esc}[43m", "${esc}[0m")   # yellow background
            'spaces'     = @("${esc}[43m", "${esc}[0m")   # yellow background
        }
        chars  = @{}
    }

    function Add-Def([int]$cp, [string]$replacement, [string]$name, [string]$group) {
        $defs.chars[[char]$cp] = @{
            replacement = $replacement
            name        = $name
            group       = $group
        }
    }

    # Quotes -> replacement ASCII and names
    Add-Def -cp 0x201C -replacement '"' -name 'LEFT DOUBLE QUOTATION MARK' -group 'quotes'
    Add-Def -cp 0x201D -replacement '"' -name 'RIGHT DOUBLE QUOTATION MARK' -group 'quotes'
    Add-Def -cp 0x2018 -replacement "'" -name 'LEFT SINGLE QUOTATION MARK' -group 'quotes'
    Add-Def -cp 0x2019 -replacement "'" -name 'RIGHT SINGLE QUOTATION MARK' -group 'quotes'

    # Dashes and ellipsis
    Add-Def -cp 0x2013 -replacement '-' -name 'EN DASH' -group 'separators'
    Add-Def -cp 0x2014 -replacement '-' -name 'EM DASH' -group 'separators'
    Add-Def -cp 0x2026 -replacement '...' -name 'HORIZONTAL ELLIPSIS' -group 'separators'

    # Spaces and zero-width -> regular space U+0020
    Add-Def -cp 0x00A0 -replacement ' ' -name 'NO-BREAK SPACE' -group 'spaces'
    Add-Def -cp 0x1680 -replacement ' ' -name 'OGHAM SPACE MARK' -group 'spaces'
    Add-Def -cp 0x2000 -replacement ' ' -name 'EN QUAD' -group 'spaces'
    Add-Def -cp 0x2001 -replacement ' ' -name 'EM QUAD' -group 'spaces'
    Add-Def -cp 0x2002 -replacement ' ' -name 'EN SPACE' -group 'spaces'
    Add-Def -cp 0x2003 -replacement ' ' -name 'EM SPACE' -group 'spaces'
    Add-Def -cp 0x2004 -replacement ' ' -name 'THREE-PER-EM SPACE' -group 'spaces'
    Add-Def -cp 0x2005 -replacement ' ' -name 'FOUR-PER-EM SPACE' -group 'spaces'
    Add-Def -cp 0x2006 -replacement ' ' -name 'SIX-PER-EM SPACE' -group 'spaces'
    Add-Def -cp 0x2007 -replacement ' ' -name 'FIGURE SPACE' -group 'spaces'
    Add-Def -cp 0x2008 -replacement ' ' -name 'PUNCTUATION SPACE' -group 'spaces'
    Add-Def -cp 0x2009 -replacement ' ' -name 'THIN SPACE' -group 'spaces'
    Add-Def -cp 0x200A -replacement ' ' -name 'HAIR SPACE' -group 'spaces'
    Add-Def -cp 0x200B -replacement ' ' -name 'ZERO WIDTH SPACE' -group 'spaces'
    Add-Def -cp 0x200C -replacement ' ' -name 'ZERO WIDTH NON-JOINER' -group 'spaces'
    Add-Def -cp 0x200D -replacement ' ' -name 'ZERO WIDTH JOINER' -group 'spaces'
    Add-Def -cp 0x202F -replacement ' ' -name 'NARROW NO-BREAK SPACE' -group 'spaces'
    Add-Def -cp 0x205F -replacement ' ' -name 'MEDIUM MATHEMATICAL SPACE' -group 'spaces'
    Add-Def -cp 0x2060 -replacement ' ' -name 'WORD JOINER' -group 'spaces'
    Add-Def -cp 0x3000 -replacement ' ' -name 'IDEOGRAPHIC SPACE' -group 'spaces'

    return $defs
}

function Get-ExtensionSet {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.HashSet[string]])]
    param(
        [Parameter(Mandatory)] [string[]] $Extensions
    )
    $set = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($ext in $Extensions) {
        if ([string]::IsNullOrWhiteSpace($ext)) { continue }
        $e = $ext.Trim()
        if (-not $e.StartsWith('.')) { $e = '.' + $e }
        [void]$set.Add($e)
    }
    return $set
}

function Get-ForbiddenRegex {
    [CmdletBinding()]
    [OutputType([regex])]
    param(
        [Parameter(Mandatory)] [string[]] $Keys
    )
    # Build an alternation of Unicode escape sequences to avoid embedding forbidden characters
    $unique = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    foreach ($k in $Keys) {
        if ([string]::IsNullOrEmpty($k)) { continue }
        $cp = [int][char]$k[0]
        $u = ('\u{0:X4}' -f $cp)
        [void]$unique.Add($u)
    }
    if ($unique.Count -eq 0) { return $null }
    # Enumerate the HashSet directly; avoid calling ToArray which may fail if $unique is mis-typed
    $pattern = '(?:' + ((@($unique) -join '|')) + ')'
    return [regex]::new($pattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
}

function Show-HighlightedChar {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string] $Text,
        [Parameter(Mandatory)] [regex]  $Pattern
    )
    # Capture script-scoped definitions in a local to close over in the evaluator
    $defsLocal = $script:definitions
    return $Pattern.Replace($Text, {
            param($m)
            $ch = $m.Value[0]
            $meta = $defsLocal.chars[$ch]
            if (-not $meta) { return $m.Value }
            $grp = $meta.group
            $pair = if ($grp) { $defsLocal.groups[$grp] } else { $null }
            if (-not $pair) { return $m.Value }
            ($pair[0] + $m.Value + $pair[1])
        })
}

function Resolve-TargetFile {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param(
        [Parameter(Mandatory)] [string[]] $Path,
        [Parameter()] [string]   $Filter,
        [Parameter()] [string[]] $Include,
        [Parameter()] [string[]] $ExcludeDirectories,
        [Parameter()] [string[]] $Exclude,
        [Parameter()] [switch]   $NoRecurse,
        [Parameter(Mandatory)] [string[]] $Extensions
    )

    $gciParams = @{
        File        = $true
        Force       = $true
        ErrorAction = 'SilentlyContinue'
        Recurse     = -not $NoRecurse
    }
    if ($Filter) { $gciParams.Filter = $Filter }
    if ($Include) { $gciParams.Include = $Include }
    if ($Exclude) { $gciParams.Exclude = $Exclude }

    # Build extension set once
    $extSet = @()
    if ($Extensions -and $Extensions.Count -gt 0) { $extSet = Get-ExtensionSet -Extensions $Extensions }

    # Build a single regex to exclude any path that contains one of the excluded directory names as a segment
    $excludedPattern = $null
    if ($ExcludeDirectories -and $ExcludeDirectories.Count -gt 0) {
        $escaped = @()
        foreach ($n in $ExcludeDirectories) {
            if ([string]::IsNullOrWhiteSpace($n)) { continue }
            $trimmed = $n.Trim()
            if ($trimmed.Length -eq 0) { continue }
            $escaped += [regex]::Escape($trimmed)
        }
        if ($escaped.Count -gt 0) {
            $alt = ($escaped -join '|')
            # Match any path containing /<name>/ or \<name>\ as a segment (case-insensitive)
            $excludedPattern = "(?i)(?:^|[\\/])(?:$alt)(?:[\\/])"
            Write-Verbose -Message ("Exclude pattern: " + $excludedPattern)
        }
    }

    Get-ChildItem -Path $Path @gciParams |
    Where-Object { $_.PSIsContainer -eq $false } |
    Where-Object { -not $excludedPattern -or ($_.FullName -notmatch $excludedPattern) } |
    Where-Object { $extSet.Contains([System.IO.Path]::GetExtension($_.FullName)) }
}

function Get-ViolatingFile {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)] [System.IO.FileInfo] $File,
        [Parameter(Mandatory)] [regex]    $DetectRegex
    )
    begin {
        $pattern = $DetectRegex.ToString()
        $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
    }
    process {
        if (-not $File -or -not $File.FullName) { return }
        $mi = Select-String -Path $File.FullName -Pattern $pattern -List -Encoding utf8 -ErrorAction SilentlyContinue
        if ($mi -and $mi.Path) { [void]$seen.Add($mi.Path) }
    }
    end {
        foreach ($p in $seen) { $p }
    }
}

function Write-ViolationLine {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string[]] $ViolatingFiles,
        [Parameter(Mandatory)] [regex]    $DetectRegex,
        [Parameter(Mandatory)] [string]   $RepoRoot,
        [Parameter()] [switch]            $NoColor
    )
    $defsLocal = $script:definitions
    $pattern = $DetectRegex.ToString()
    $lineMatches = Select-String -Path $ViolatingFiles -Pattern $pattern -Encoding utf8 -ErrorAction SilentlyContinue
    foreach ($mi in $lineMatches) {
        $rel = [System.IO.Path]::GetRelativePath($RepoRoot, $mi.Path)
        $lineText = $mi.Line.TrimEnd("`r")
        $esc = [char]27
        $redPrefix = if ($NoColor) { "- " } else { "${esc}[31m- ${esc}[0m" }
        $greenPrefix = if ($NoColor) { "+ " } else { "${esc}[32m+ ${esc}[0m" }
        $display = if ($NoColor) { $lineText } else { Show-HighlightedChar -Text $lineText -Pattern $DetectRegex }
        Write-Information -MessageData ("{0}{1}: {2}{3}" -f $redPrefix, $rel, $mi.LineNumber, $display)

        $fixedText = $lineText
        $charKeys = @($defsLocal.chars.Keys)
        foreach ($k in $charKeys) {
            $replacement = $defsLocal.chars[$k].replacement
            $fixedText = $fixedText.Replace([string]$k, $replacement)
        }
        Write-Information -MessageData ("{0}{1}: {2}{3}" -f $greenPrefix, $rel, $mi.LineNumber, $fixedText)

        if ($VerbosePreference -in @('Continue', 'Inquire', 'Stop')) {
            $seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::Ordinal)
            $colored = [System.Collections.Generic.List[string]]::new()
            foreach ($m in $DetectRegex.Matches($mi.Line)) {
                $c = $m.Value[0]
                $meta = $defsLocal.chars[$c]
                $nm = if ($meta -and $meta.name) { $meta.name } else { ('U+{0:X4}' -f [int][char]$c) }
                if (-not $seen.Add($nm)) { continue }
                $grp = if ($meta) { $meta.group } else { $null }
                $pair = if ($grp) { $defsLocal.groups[$grp] } else { $null }
                $entry = if (-not $NoColor -and $pair) { $pair[0] + $nm + $pair[1] } else { $nm }
                [void]$colored.Add($entry)
            }
            if ($colored.Count -gt 0) { Write-Verbose ("  [" + ($colored -join ", ") + "]") }
        }
    }
}

function Set-FixViolation {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
    param(
        [Parameter(Mandatory)] [string[]] $ViolatingFiles
    )
    $defsLocal = $script:definitions
    $filesFixed = 0
    foreach ($vf in $ViolatingFiles) {
        $content = Get-Content -LiteralPath $vf -Raw -Encoding utf8
        $newContent = $content
        $charKeys = @($defsLocal.chars.Keys)
        foreach ($k in $charKeys) {
            $replacement = $defsLocal.chars[$k].replacement
            $newContent = $newContent.Replace([string]$k, $replacement)
        }
        if ($PSCmdlet.ShouldProcess($vf, 'Replace visually similar Unicode characters with ASCII equivalents')) {
            Set-Content -LiteralPath $vf -Value $newContent -Encoding utf8 -NoNewline
            $filesFixed++
        }
    }
    return $filesFixed
}


$repoRoot = (Get-Location).Path

$script:definitions = Get-Definition
$charKeys = @($script:definitions.chars.Keys)
$keys = @($charKeys | ForEach-Object { [string]$_ })
if ($keys.Count -eq 0) { Write-Verbose 'No characters selected to search for. Exiting.'; return }
$detectRegex = Get-ForbiddenRegex -Keys $keys
if (-not $detectRegex) { Write-Verbose 'No detection pattern built. Exiting.'; return }

$filesScanned = 0
$violatingFiles = Resolve-TargetFile `
    -Path $Path `
    -Filter $Filter `
    -Include $Include `
    -ExcludeDirectories $ExcludeDirectories `
    -Exclude $Exclude `
    -NoRecurse:$NoRecurse `
    -Extensions $Extensions |
ForEach-Object { $filesScanned++; $_ } |
Get-ViolatingFile -DetectRegex $detectRegex |
Select-Object -Unique
if ($filesScanned -eq 0) { Write-Verbose 'No target files found.'; return }
$filesWithViolations = @($violatingFiles).Count
if ($filesWithViolations -eq 0) { Write-Verbose 'No violations found.'; return }

Write-ViolationLine -ViolatingFiles $violatingFiles -DetectRegex $detectRegex -RepoRoot $repoRoot -NoColor:$NoColor

$filesFixed = 0
if (-not $OutputOnly) { $filesFixed = Set-FixViolation -ViolatingFiles $violatingFiles }

Write-Information ("Scanned: {0} files; Violating files: {1}; Fixed: {2}" -f $filesScanned, $filesWithViolations, $filesFixed)
