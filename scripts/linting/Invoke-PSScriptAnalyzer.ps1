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
    Install-Module -Name PSScriptAnalyzer -RequiredVersion '1.23.0' -Force -Scope CurrentUser -AllowClobber
}
Import-Module PSScriptAnalyzer -Force

function Get-AnalyzerFilePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [object]$File
    )

    if ($File -is [System.IO.FileSystemInfo]) {
        return $File.FullName
    }

    if ($File.PSObject.Properties['ProviderPath']) {
        return [string]$File.ProviderPath
    }

    if ($File.PSObject.Properties['Path']) {
        return [string]$File.Path
    }

    return [string]$File
}

function Invoke-AnalyzerForFile {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [object]$File,

        [Parameter(Mandatory = $true)]
        [string]$SettingsPath
    )

    $filePath = Get-AnalyzerFilePath -File $File

    try {
        return @(Invoke-ScriptAnalyzer -Path $filePath -Settings $SettingsPath -ErrorAction Stop)
    } catch {
        $pathError = $_
        try {
            $scriptDefinition = Get-Content -LiteralPath $filePath -Raw
            $results = @(Invoke-ScriptAnalyzer -ScriptDefinition $scriptDefinition -Settings $SettingsPath -ErrorAction Stop)

            foreach ($result in $results) {
                if ([string]::IsNullOrWhiteSpace($result.ScriptPath)) {
                    $result | Add-Member -NotePropertyName 'ScriptPath' -NotePropertyValue $filePath -Force
                }
            }

            return $results
        } catch {
            throw $pathError
        }
    }
}

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
$crashedFiles = @()
foreach ($file in $files) {
    try {
        $results = Invoke-AnalyzerForFile -File $file -SettingsPath $SettingsPath
        $allResults += $results
    } catch {
        $crashedFiles += $file
        Write-Warning "PSScriptAnalyzer internal error on file '$file': $($_.Exception.Message)"
    }
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
$crashCount = @($crashedFiles).Count

$summary = @"
## PSScriptAnalyzer Results

| Severity | Count |
|----------|-------|
| Error | $errorCount |
| Warning | $warningCount |
| Information | $infoCount |
| Analyzer internal errors | $crashCount |
| **Total** | **$($allResults.Count)** |

Files scanned: $($files.Count)
"@

Write-CIStepSummary $summary
Set-CIOutput -Name 'has-findings' -Value (($allResults.Count -gt 0 -or $crashCount -gt 0).ToString().ToLower())

if ($crashCount -gt 0 -and -not $SoftFail) {
    Write-Host "PSScriptAnalyzer failed to analyze $crashCount file(s)."
    exit 1
}

if ($allResults.Count -gt 0 -and -not $SoftFail) {
    Write-Host "Found $($allResults.Count) issue(s)."
    exit 1
}
