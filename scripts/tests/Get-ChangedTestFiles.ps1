[CmdletBinding()]
param(
    [string]$BaseBranch = 'origin/main',
    [string[]]$TestPattern = @('*.Tests.ps1', '*.tests.ps1')
)

$ErrorActionPreference = 'Stop'

$diffOutput = git diff --name-only --diff-filter=d "$BaseBranch...HEAD" 2>$null

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
