[CmdletBinding()]
param(
    [string]$BaseBranch = 'origin/main',
    [ValidateSet('branch', 'range')]
    [string]$ChangeMode = 'branch',
    [string]$BaseSha = '',
    [string]$HeadSha = '',
    [string[]]$TestPattern = @('*.Tests.ps1', '*.tests.ps1')
)

$ErrorActionPreference = 'Stop'

if ($ChangeMode -eq 'range') {
    if ([string]::IsNullOrWhiteSpace($BaseSha) -or [string]::IsNullOrWhiteSpace($HeadSha)) {
        throw 'Range mode requires both BaseSha and HeadSha.'
    }
    $diffOutput = git diff --name-only --diff-filter=d $BaseSha $HeadSha
}
else {
    $diffOutput = git diff --name-only --diff-filter=d "$BaseBranch...HEAD"
}

if ($LASTEXITCODE -ne 0) {
    throw "Failed to resolve changed tests using '$ChangeMode' mode."
}

if (-not $diffOutput) {
    Write-Verbose 'No changes detected from base branch.'
    return @()
}

$testFiles = $diffOutput | Where-Object {
    $fileName = Split-Path $_ -Leaf
    $TestPattern | Where-Object { $fileName -like $_ }
} | Where-Object { Test-Path $_ } | ForEach-Object { Resolve-Path $_ }

Write-Host "Found $($testFiles.Count) changed test file(s)."
return $testFiles
