#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.0

<#
.SYNOPSIS
    Runs Bicep validation for scoped or full repository inputs.
.DESCRIPTION
    Validates Bicep files with az bicep lint when available and falls back to
    az bicep build for Azure CLI versions that do not support lint.
.PARAMETER Platform
    Reporting platform for annotations and outputs.
.PARAMETER FullValidation
    Boolean string that selects full repository validation when true.
.PARAMETER BicepFoldersJson
    JSON object emitted by Detect-Folder-Changes.ps1 for scoped validation.
.PARAMETER ResultsDir
    Directory where command output artifacts are written.
.PARAMETER OutputFile
    Markdown summary output path.
.PARAMETER RepoRoot
    Repository root used to resolve relative folders and files.
.EXAMPLE
    ./scripts/build/Invoke-BicepLint.ps1 -Platform github -FullValidation true
.NOTES
    Used by .github/workflows/bicep-lint.yml.
#>

[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [ValidateSet('github', 'generic')]
    [string]$Platform = 'generic',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$FullValidation = 'true',

    [Parameter(Mandatory = $false)]
    [string]$BicepFoldersJson = '{}',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$ResultsDir = 'bicep-lint-results',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$OutputFile = 'bicep-lint-output.txt',

    [Parameter(Mandatory = $false)]
    [ValidateNotNullOrEmpty()]
    [string]$RepoRoot = (git rev-parse --show-toplevel 2>$null)
)

$ErrorActionPreference = 'Stop'

#region Functions
function ConvertTo-BicepRunnerBoolean {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Value
    )

    switch ($Value.ToLowerInvariant()) {
        'true' { return $true }
        'false' { return $false }
        default { throw "Expected boolean value, got: $Value" }
    }
}

function Resolve-BicepRepoRoot {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowEmptyString()]
        [string]$Path
    )

    if (-not [string]::IsNullOrWhiteSpace($Path)) {
        return [System.IO.Path]::GetFullPath($Path)
    }

    $gitRoot = git rev-parse --show-toplevel 2>$null
    if (-not [string]::IsNullOrWhiteSpace($gitRoot)) {
        return [System.IO.Path]::GetFullPath($gitRoot.Trim())
    }

    return (Get-Location).Path
}

function Test-ExcludedBicepPath {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RelativePath
    )

    $normalizedPath = $RelativePath -replace '\\', '/'
    return $normalizedPath -match '(^|/)(node_modules|\.copilot-tracking)(/|$)'
}

function ConvertTo-RepoRelativePath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [string]$Path
    )

    $fullPath = [System.IO.Path]::GetFullPath($Path)
    return [System.IO.Path]::GetRelativePath($RepoRoot, $fullPath) -replace '\\', '/'
}

function Get-BicepFolderPathFromJson {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$BicepFoldersJson = '{}'
    )

    if ([string]::IsNullOrWhiteSpace($BicepFoldersJson)) {
        return @()
    }

    try {
        $folderData = $BicepFoldersJson | ConvertFrom-Json
    }
    catch {
        throw "Failed to parse Bicep folders JSON: $($_.Exception.Message)"
    }

    if ($null -eq $folderData) {
        return @()
    }

    $folderPaths = [System.Collections.Generic.List[string]]::new()
    $entries = if ($folderData -is [array]) { $folderData } else { @($folderData.PSObject.Properties.Value) }

    foreach ($entry in $entries) {
        if ($null -eq $entry) {
            continue
        }

        $folderNameProperty = $entry.PSObject.Properties['folderName']
        if ($null -eq $folderNameProperty) {
            continue
        }

        foreach ($folderName in @($folderNameProperty.Value)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$folderName)) {
                $folderPaths.Add(([string]$folderName -replace '\\', '/'))
            }
        }
    }

    return @($folderPaths | Select-Object -Unique)
}

function Get-BicepValidationFile {
    [CmdletBinding()]
    [OutputType([object[]])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$RepoRoot,

        [Parameter(Mandatory = $true)]
        [bool]$FullValidation,

        [Parameter(Mandatory = $false)]
        [string]$BicepFoldersJson = '{}',

        [Parameter(Mandatory = $false)]
        [ValidateSet('github', 'generic')]
        [string]$Platform = 'generic'
    )

    $resolvedRepoRoot = Resolve-BicepRepoRoot -Path $RepoRoot
    $filePaths = [System.Collections.Generic.List[string]]::new()

    if ($FullValidation) {
        $candidateFiles = Get-ChildItem -Path $resolvedRepoRoot -Filter '*.bicep' -File -Recurse -ErrorAction SilentlyContinue
    }
    else {
        $candidateFiles = @()
        foreach ($folderPath in Get-BicepFolderPathFromJson -BicepFoldersJson $BicepFoldersJson) {
            $resolvedFolderPath = if ([System.IO.Path]::IsPathRooted($folderPath)) {
                $folderPath
            }
            else {
                Join-Path $resolvedRepoRoot $folderPath
            }

            if (-not (Test-Path -Path $resolvedFolderPath -PathType Container)) {
                Write-BicepWarning -Platform $Platform -Message "Bicep folder does not exist: $folderPath"
                continue
            }

            $candidateFiles += Get-ChildItem -Path $resolvedFolderPath -Filter '*.bicep' -File -Recurse -ErrorAction SilentlyContinue
        }
    }

    foreach ($candidateFile in $candidateFiles) {
        $relativePath = ConvertTo-RepoRelativePath -RepoRoot $resolvedRepoRoot -Path $candidateFile.FullName
        if (-not (Test-ExcludedBicepPath -RelativePath $relativePath)) {
            $filePaths.Add($relativePath)
        }
    }

    return @($filePaths | Select-Object -Unique | Sort-Object)
}

function Test-BicepLintSupport {
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    $null = & az bicep lint --help 2>$null
    return $LASTEXITCODE -eq 0
}

function Get-BicepValidationCommand {
    [CmdletBinding()]
    [OutputType([string])]
    param()

    if (Test-BicepLintSupport) {
        return 'lint'
    }

    return 'build'
}

function Write-BicepWarning {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('github', 'generic')]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    if ($Platform -eq 'github') {
        Write-Output "::warning::$Message"
        return
    }

    Write-Warning $Message
}

function Write-BicepFailure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('github', 'generic')]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    if ($Platform -eq 'github') {
        Write-Output "::error file=$FilePath::Bicep $CommandName failed for $FilePath"
        return
    }

    Write-Error -ErrorAction Continue "Bicep $CommandName failed for $FilePath"
}

function Start-BicepLogGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('github', 'generic')]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not $PSCmdlet.ShouldProcess($FilePath, 'Start Bicep log group')) {
        return
    }

    if ($Platform -eq 'github') {
        Write-Output "::group::Validating: $FilePath"
        return
    }

    Write-Host "Validating: $FilePath"
}

function Stop-BicepLogGroup {
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('github', 'generic')]
        [string]$Platform
    )

    if (-not $PSCmdlet.ShouldProcess($Platform, 'Stop Bicep log group')) {
        return
    }

    if ($Platform -eq 'github') {
        Write-Output '::endgroup::'
    }
}

function Invoke-BicepFileValidation {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('lint', 'build')]
        [string]$CommandName,

        [Parameter(Mandatory = $true)]
        [string]$FilePath,

        [Parameter(Mandatory = $true)]
        [string]$ResultsFile
    )

    if ($CommandName -eq 'lint') {
        $commandOutput = & az bicep lint --file $FilePath 2>&1
    }
    else {
        $commandOutput = & az bicep build --file $FilePath --stdout 2>&1
    }

    $exitCode = $LASTEXITCODE
    if ($commandOutput) {
        $commandOutput | Add-Content -Path $ResultsFile -Encoding UTF8
        if ($exitCode -ne 0) {
            $commandOutput | ForEach-Object { Write-Output $_ }
        }
    }

    return $exitCode -eq 0
}

function Write-BicepSummary {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [int]$FilesChecked,

        [Parameter(Mandatory = $true)]
        [int]$Failures,

        [Parameter(Mandatory = $true)]
        [AllowEmptyCollection()]
        [string[]]$FailedFiles,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile
    )

    $summaryLines = [System.Collections.Generic.List[string]]::new()
    $summaryLines.Add('## Bicep Lint Results')
    $summaryLines.Add('')
    $summaryLines.Add("- **Files checked:** $FilesChecked")
    $summaryLines.Add("- **Failures:** $Failures")

    if ($Failures -gt 0) {
        $summaryLines.Add('')
        $summaryLines.Add('### Failed files')
        foreach ($failedFile in $FailedFiles) {
            $summaryLines.Add("- $failedFile")
        }
    }

    $summary = $summaryLines -join [Environment]::NewLine
    $summary | Set-Content -Path $OutputFile -Encoding UTF8
    return $summary
}

function Write-GitHubBicepOutput {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$FilesChecked,

        [Parameter(Mandatory = $true)]
        [int]$Failures,

        [Parameter(Mandatory = $true)]
        [string]$Summary
    )

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_OUTPUT)) {
        "files-checked=$FilesChecked" | Add-Content -Path $env:GITHUB_OUTPUT -Encoding UTF8
        "failures=$Failures" | Add-Content -Path $env:GITHUB_OUTPUT -Encoding UTF8
    }

    if (-not [string]::IsNullOrWhiteSpace($env:GITHUB_STEP_SUMMARY)) {
        $Summary | Add-Content -Path $env:GITHUB_STEP_SUMMARY -Encoding UTF8
    }
}

function Invoke-BicepLint {
    [CmdletBinding()]
    [OutputType([pscustomobject])]
    param(
        [Parameter(Mandatory = $true)]
        [ValidateSet('github', 'generic')]
        [string]$Platform,

        [Parameter(Mandatory = $true)]
        [string]$FullValidation,

        [Parameter(Mandatory = $false)]
        [string]$BicepFoldersJson = '{}',

        [Parameter(Mandatory = $true)]
        [string]$ResultsDir,

        [Parameter(Mandatory = $true)]
        [string]$OutputFile,

        [Parameter(Mandatory = $true)]
        [string]$RepoRoot
    )

    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "'az' command is required but not installed"
    }

    $resolvedRepoRoot = Resolve-BicepRepoRoot -Path $RepoRoot
    $fullValidationEnabled = ConvertTo-BicepRunnerBoolean -Value $FullValidation
    $bicepFiles = @(Get-BicepValidationFile -RepoRoot $resolvedRepoRoot -FullValidation $fullValidationEnabled -BicepFoldersJson $BicepFoldersJson -Platform $Platform)
    $validationCommand = Get-BicepValidationCommand
    $failedFiles = [System.Collections.Generic.List[string]]::new()
    $filesChecked = 0

    New-Item -ItemType Directory -Path $ResultsDir -Force | Out-Null
    $resultsFile = Join-Path $ResultsDir "bicep-$validationCommand-results.txt"

    Write-Host "Bicep validation mode: $fullValidationEnabled"
    Write-Host "Bicep command: az bicep $validationCommand --file"

    if ($bicepFiles.Count -eq 0) {
        Write-Host 'No Bicep files found to validate'
    }

    Push-Location $resolvedRepoRoot
    try {
        foreach ($bicepFile in $bicepFiles) {
            $filesChecked++
            Start-BicepLogGroup -Platform $Platform -FilePath $bicepFile
            $passed = Invoke-BicepFileValidation -CommandName $validationCommand -FilePath $bicepFile -ResultsFile $resultsFile

            if (-not $passed) {
                $failedFiles.Add($bicepFile)
                Write-BicepFailure -Platform $Platform -FilePath $bicepFile -CommandName $validationCommand
            }

            Stop-BicepLogGroup -Platform $Platform
        }
    }
    finally {
        Pop-Location
    }

    $summary = Write-BicepSummary -FilesChecked $filesChecked -Failures $failedFiles.Count -FailedFiles @($failedFiles) -OutputFile $OutputFile

    if ($Platform -eq 'github') {
        Write-GitHubBicepOutput -FilesChecked $filesChecked -Failures $failedFiles.Count -Summary $summary
    }

    return [PSCustomObject]@{
        FilesChecked = $filesChecked
        Failures     = $failedFiles.Count
        FailedFiles  = @($failedFiles)
        Command      = $validationCommand
    }
}
#endregion Functions

#region Main Execution
if ($MyInvocation.InvocationName -ne '.') {
    try {
        $result = Invoke-BicepLint `
            -Platform $Platform `
            -FullValidation $FullValidation `
            -BicepFoldersJson $BicepFoldersJson `
            -ResultsDir $ResultsDir `
            -OutputFile $OutputFile `
            -RepoRoot (Resolve-BicepRepoRoot -Path $RepoRoot)

        if ($Platform -eq 'generic' -and $result.Failures -gt 0) {
            exit 1
        }

        exit 0
    }
    catch {
        Write-Error -ErrorAction Continue "Invoke-BicepLint failed: $($_.Exception.Message)"
        exit 1
    }
}
#endregion Main Execution
