function Get-ChangedFilesFromGit {
    <#
    .SYNOPSIS
    Returns changed files of specified extensions relative to a base branch.
    #>
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseOutputTypeCorrectly', '')]
    [CmdletBinding()]
    param(
        [string[]]$Extension = @('.ps1', '.psm1', '.psd1'),
        [string]$BaseBranch = 'origin/main'
    )

    $diffOutput = git diff --name-only --diff-filter=d "$BaseBranch...HEAD" 2>$null

    if (-not $diffOutput) { return @() }

    $changedFiles = $diffOutput | Where-Object {
        $ext = [System.IO.Path]::GetExtension($_)
        $Extension -contains $ext
    } | Where-Object { Test-Path $_ } | ForEach-Object { Resolve-Path $_ }

    return $changedFiles
}

function Get-FilesRecursive {
    <#
    .SYNOPSIS
    Returns all files matching specified extensions, excluding configured patterns.
    #>
    [CmdletBinding()]
    param(
        [string]$Path = '.',
        [string[]]$Extension = @('.ps1', '.psm1', '.psd1'),
        [string[]]$ExcludePattern = @('node_modules', '.copilot-tracking')
    )

    $includeGlobs = $Extension | ForEach-Object { "*$_" }

    Get-ChildItem -Path $Path -Recurse -File -Include $includeGlobs |
        Where-Object {
            $fullPath = $_.FullName
            -not ($ExcludePattern | Where-Object { $fullPath -match [regex]::Escape($_) })
        }
}

Export-ModuleMember -Function 'Get-ChangedFilesFromGit', 'Get-FilesRecursive'
