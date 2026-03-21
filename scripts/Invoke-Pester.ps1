[CmdletBinding()]
param(
    [switch]$CI,
    [switch]$ChangedOnly,
    [switch]$CodeCoverage,
    [string]$ConfigPath = (Join-Path $PSScriptRoot 'tests/pester.config.ps1'),
    [string]$OutputPath = './test-results',
    [string[]]$Path
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot 'ci/Modules/CIHelpers.psm1') -Force

$pesterModule = Get-Module -ListAvailable -Name Pester |
    Sort-Object Version -Descending |
    Select-Object -First 1

if (-not $pesterModule -or $pesterModule.Version -lt [version]'5.0.0') {
    Install-Module -Name Pester -Force -Scope CurrentUser -SkipPublisherCheck -MinimumVersion '5.4.0'
}

Import-Module Pester -MinimumVersion '5.4.0' -Force

$configParams = @{}
if ($CI) { $configParams['CI'] = $true }
if ($CodeCoverage) { $configParams['CodeCoverage'] = $true }
if ($Path) { $configParams['Path'] = $Path }
$configParams['OutputPath'] = $OutputPath

$config = & $ConfigPath @configParams

if ($ChangedOnly) {
    $changedTests = & (Join-Path $PSScriptRoot 'tests/Get-ChangedTestFiles.ps1')
    if ($changedTests.Count -eq 0) {
        Write-Host 'No changed test files found.'
        Write-CIStepSummary "## Pester Test Results`n`nNo changed test files to run."
        Set-CIOutput -Name 'test-result' -Value 'passed'
        Set-CIOutput -Name 'test-count' -Value '0'
        Set-CIOutput -Name 'fail-count' -Value '0'
        exit 0
    }
    $config.Run.Path = $changedTests
}

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$result = Invoke-Pester -Configuration $config

function Get-FailedTest {
    param([object]$Container)
    $failures = @()
    foreach ($block in $Container.Blocks) {
        foreach ($test in $block.Tests) {
            if ($test.Result -eq 'Failed') {
                $failures += @{
                    Name  = $test.ExpandedName
                    Error = $test.ErrorRecord.Exception.Message
                    File  = $test.ScriptBlock.File
                    Line  = $test.ScriptBlock.StartPosition.StartLine
                }
            }
        }
        if ($block.Blocks.Count -gt 0) {
            $failures += Get-FailedTest -Container $block
        }
    }
    return $failures
}

$allFailures = @()
foreach ($container in $result.Containers) {
    $allFailures += Get-FailedTest -Container $container
}

$result | Select-Object TotalCount, PassedCount, FailedCount, SkippedCount, Duration |
    ConvertTo-Json | Set-Content (Join-Path $OutputPath 'test-summary.json')

if ($allFailures.Count -gt 0) {
    $allFailures | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputPath 'test-failures.json')
    foreach ($failure in $allFailures) {
        Write-CIAnnotation -Level 'Error' -Message "Test failed: $($failure.Name) — $($failure.Error)" `
            -File $failure.File -Line $failure.Line
    }
}

$summary = @"
## Pester Test Results

| Metric | Value |
|--------|-------|
| Total | $($result.TotalCount) |
| Passed | $($result.PassedCount) |
| Failed | $($result.FailedCount) |
| Skipped | $($result.SkippedCount) |
| Duration | $($result.Duration) |
"@

Write-CIStepSummary $summary

Set-CIOutput -Name 'test-result' -Value $(if ($result.FailedCount -eq 0) { 'passed' } else { 'failed' })
Set-CIOutput -Name 'test-count' -Value $result.TotalCount.ToString()
Set-CIOutput -Name 'fail-count' -Value $result.FailedCount.ToString()

if ($CI -and $result.FailedCount -gt 0) {
    exit 1
}
