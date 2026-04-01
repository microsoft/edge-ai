[CmdletBinding()]
param(
    [switch]$ChangedOnly,
    [switch]$SoftFail,
    [string]$SettingsPath = (Join-Path $PSScriptRoot '../../PSScriptAnalyzerSettings.psd1'),
    [string]$OutputPath = './lint-results'
)

$ErrorActionPreference = 'Stop'

Import-Module (Join-Path $PSScriptRoot '../ci/Modules/CIHelpers.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'Modules/LintingHelpers.psm1') -Force

if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Install-Module -Name PSScriptAnalyzer -RequiredVersion '1.22.0' -Force -Scope CurrentUser -AllowClobber
}
Import-Module PSScriptAnalyzer -Force

if ($ChangedOnly) {
    $files = Get-ChangedFilesFromGit -Extension @('.ps1', '.psm1', '.psd1')
    if ($files.Count -eq 0) {
        Write-Host 'No changed PowerShell files found.'
        Write-CIStepSummary '## PSScriptAnalyzer Results\n\nNo changed PowerShell files to scan.'
        Set-CIOutput -Name 'has-findings' -Value 'false'
        exit 0
    }
} else {
    $files = Get-FilesRecursive -Extension @('.ps1', '.psm1', '.psd1')
}

Write-Host "Scanning $($files.Count) file(s)..."

$allResults = @()
foreach ($file in $files) {
    $results = Invoke-ScriptAnalyzer -Path $file -Settings $SettingsPath -ReportSummary
    $allResults += $results
}

if (-not (Test-Path $OutputPath)) {
    New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
}

$allResults | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $OutputPath 'psscriptanalyzer-results.json')

foreach ($result in $allResults) {
    $type = switch ($result.Severity) {
        'Error'       { 'Error' }
        'Warning'     { 'Warning' }
        'Information' { 'Notice' }
        default       { 'Notice' }
    }
    Write-CIAnnotation -Level $type -Message "$($result.RuleName): $($result.Message)" `
        -File $result.ScriptPath -Line $result.Line -Column $result.Column
}

$errorCount = ($allResults | Where-Object Severity -eq 'Error').Count
$warningCount = ($allResults | Where-Object Severity -eq 'Warning').Count
$infoCount = ($allResults | Where-Object Severity -eq 'Information').Count

$summary = @"
## PSScriptAnalyzer Results

| Severity | Count |
|----------|-------|
| Error | $errorCount |
| Warning | $warningCount |
| Information | $infoCount |
| **Total** | **$($allResults.Count)** |

Files scanned: $($files.Count)
"@

Write-CIStepSummary $summary
Set-CIOutput -Name 'has-findings' -Value ($allResults.Count -gt 0).ToString().ToLower()

if ($allResults.Count -gt 0 -and -not $SoftFail) {
    Write-Host "Found $($allResults.Count) issue(s)."
    exit 1
}
