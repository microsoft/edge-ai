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
    [OutputType([System.IO.FileInfo])]
    param(
        [string]$Path = '.',
        [string[]]$Extension = @('.ps1', '.psm1', '.psd1'),
        [string[]]$ExcludePattern = @('node_modules', '.copilot-tracking', 'packages', '.git', 'lint-results')
    )

    $normalizedExtensions = $Extension | ForEach-Object {
        if ($_.StartsWith('.')) { $_ } else { ".$_" }
    }
    $excludedPathSegments = $ExcludePattern | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $rootPath = Resolve-Path -Path $Path -ErrorAction Stop
    $rootItem = Get-Item -LiteralPath $rootPath.ProviderPath

    if ($rootItem -is [System.IO.FileInfo]) {
        if ($normalizedExtensions -contains $rootItem.Extension) { return $rootItem }
        return
    }

    $directoriesToSearch = [System.Collections.Generic.Stack[System.IO.DirectoryInfo]]::new()
    $directoriesToSearch.Push($rootItem)

    while ($directoriesToSearch.Count -gt 0) {
        $currentDirectory = $directoriesToSearch.Pop()

        Get-ChildItem -LiteralPath $currentDirectory.FullName -Directory -Force -ErrorAction SilentlyContinue |
            Where-Object { $excludedPathSegments -notcontains $_.Name } |
            ForEach-Object { $directoriesToSearch.Push($_) }

        Get-ChildItem -LiteralPath $currentDirectory.FullName -File -Force -ErrorAction SilentlyContinue |
            Where-Object { $normalizedExtensions -contains $_.Extension }
        }
}

Export-ModuleMember -Function 'Get-ChangedFilesFromGit', 'Get-FilesRecursive'
