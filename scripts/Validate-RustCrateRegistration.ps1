# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
<#
.SYNOPSIS
    Validates that every Rust crate under src/500-application is either fully registered
    for CI/Codecov coverage or explicitly opted out.

.DESCRIPTION
    Enforces .github/instructions/rust-crate-registration.instructions.md by checking
    each discovered crate against:
      1. .github/workflows/rust-tests.yml jobs.coverage.strategy.matrix.crate
      2. .github/workflows/rust-tests.yml on.pull_request.paths AND on.push.paths
      3. codecov.yml flags.rust.paths
    OR coverage by a codecov.yml ignore glob.

    Writes a JSON report and exits non-zero on gaps.

.PARAMETER RepoRoot
    Repository root. Defaults to the parent of this script's directory.

.PARAMETER OutputPath
    Directory to write the JSON report. Defaults to "$RepoRoot/logs".

.EXAMPLE
    ./scripts/Validate-RustCrateRegistration.ps1
#>

#Requires -Version 7.0
#Requires -Modules powershell-yaml

[CmdletBinding()]
param(
    [string]$RepoRoot,
    [string]$OutputPath
)

function Install-YamlModuleIfNeeded {
    [CmdletBinding()]
    param()
    if (-not (Get-Module -ListAvailable -Name 'powershell-yaml')) {
        Install-Module -Name 'powershell-yaml' -Force -Scope CurrentUser -AllowClobber -ErrorAction Stop | Out-Null
    }
    Import-Module 'powershell-yaml' -ErrorAction Stop
}

function Get-CrateDirectory {
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory)] [string]$ApplicationRoot,
        [Parameter(Mandatory)] [string]$RepoRootPath
    )
    if (-not (Test-Path -LiteralPath $ApplicationRoot)) {
        return [string[]]@()
    }
    $cargoFiles = Get-ChildItem -LiteralPath $ApplicationRoot -Recurse -File -Filter 'Cargo.toml' -ErrorAction SilentlyContinue |
        Where-Object { $_.FullName -notmatch '[\\/]target[\\/]' }
    $crates = [System.Collections.Generic.List[string]]::new()
    foreach ($file in $cargoFiles) {
        $content = Get-Content -LiteralPath $file.FullName -Raw -ErrorAction SilentlyContinue
        if (-not $content) { continue }
        if ($content -notmatch '(?ms)^\s*\[package\]\s*$') { continue }
        $rel = [System.IO.Path]::GetRelativePath($RepoRootPath, $file.Directory.FullName)
        $crates.Add(($rel -replace '\\', '/'))
    }
    return [string[]]($crates | Sort-Object -Unique)
}

function Convert-GlobToRegex {
    [CmdletBinding()]
    [OutputType([string])]
    param([Parameter(Mandatory)] [string]$Glob)
    $normalized = $Glob -replace '\\', '/'
    $sb = [System.Text.StringBuilder]::new()
    $i = 0
    while ($i -lt $normalized.Length) {
        $c = $normalized[$i]
        if ($c -eq '*' -and ($i + 1) -lt $normalized.Length -and $normalized[$i + 1] -eq '*') {
            [void]$sb.Append('.*')
            $i += 2
            if ($i -lt $normalized.Length -and $normalized[$i] -eq '/') { $i++ }
        }
        elseif ($c -eq '*') {
            [void]$sb.Append('[^/]*')
            $i++
        }
        elseif ($c -eq '?') {
            [void]$sb.Append('[^/]')
            $i++
        }
        elseif ('.+()|^$[]{}\'.Contains([string]$c)) {
            [void]$sb.Append('\').Append($c)
            $i++
        }
        else {
            [void]$sb.Append($c)
            $i++
        }
    }
    return ('^' + $sb.ToString() + '$')
}

function Test-PathCoveredByGlob {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [string]$Path,
        [string[]]$Globs
    )
    if (-not $Globs -or $Globs.Count -eq 0) { return $false }
    $candidate = $Path -replace '\\', '/'
    foreach ($glob in $Globs) {
        if ([string]::IsNullOrWhiteSpace($glob)) { continue }
        $regex = Convert-GlobToRegex -Glob $glob
        if ($candidate -match $regex) { return $true }
        # also match any descendant file under the crate directory
        if (($candidate + '/anything.rs') -match $regex) { return $true }
    }
    return $false
}

function Test-MatrixCover {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)] [string]$Crate,
        [string[]]$MatrixEntries
    )
    if (-not $MatrixEntries) { return $false }
    $cratePath = $Crate -replace '\\', '/'
    foreach ($entry in $MatrixEntries) {
        if ([string]::IsNullOrWhiteSpace($entry)) { continue }
        $normalized = ($entry -replace '\\', '/').TrimEnd('/')
        if ($cratePath -eq $normalized) { return $true }
        if ($cratePath.StartsWith($normalized + '/')) { return $true }
    }
    return $false
}

function Get-RustTestsConfig {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$WorkflowPath)
    if (-not (Test-Path -LiteralPath $WorkflowPath)) {
        throw "rust-tests.yml not found at: $WorkflowPath"
    }
    $raw = Get-Content -LiteralPath $WorkflowPath -Raw
    $doc = ConvertFrom-Yaml -Yaml $raw
    # PowerShell-Yaml maps the YAML key "on" to either "on" or boolean True depending on version.
    $onSection = $null
    foreach ($key in @('on', $true, 'True')) {
        if ($doc.Contains($key)) { $onSection = $doc[$key]; break }
    }
    $pullPaths = @()
    $pushPaths = @()
    if ($onSection) {
        if ($onSection['pull_request'] -and $onSection['pull_request']['paths']) {
            $pullPaths = @($onSection['pull_request']['paths'])
        }
        if ($onSection['push'] -and $onSection['push']['paths']) {
            $pushPaths = @($onSection['push']['paths'])
        }
    }
    $matrix = @()
    if ($doc['jobs'] -and $doc['jobs']['coverage'] -and $doc['jobs']['coverage']['strategy'] `
            -and $doc['jobs']['coverage']['strategy']['matrix'] `
            -and $doc['jobs']['coverage']['strategy']['matrix']['crate']) {
        $matrix = @($doc['jobs']['coverage']['strategy']['matrix']['crate'])
    }
    return [pscustomobject]@{
        PullRequestPaths = $pullPaths
        PushPaths        = $pushPaths
        MatrixCrates     = $matrix
    }
}

function Get-CodecovConfig {
    [CmdletBinding()]
    param([Parameter(Mandatory)] [string]$CodecovPath)
    if (-not (Test-Path -LiteralPath $CodecovPath)) {
        throw "codecov.yml not found at: $CodecovPath"
    }
    $raw = Get-Content -LiteralPath $CodecovPath -Raw
    $doc = ConvertFrom-Yaml -Yaml $raw
    $rustPaths = @()
    if ($doc['flags'] -and $doc['flags']['rust'] -and $doc['flags']['rust']['paths']) {
        $rustPaths = @($doc['flags']['rust']['paths'])
    }
    $ignore = @()
    if ($doc['ignore']) { $ignore = @($doc['ignore']) }
    return [pscustomobject]@{
        RustFlagPaths = $rustPaths
        Ignore        = $ignore
    }
}

function Test-CrateRegistration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)] [string]$Crate,
        [Parameter(Mandatory)] [pscustomobject]$RustTests,
        [Parameter(Mandatory)] [pscustomobject]$Codecov
    )
    $ignored = Test-PathCoveredByGlob -Path $Crate -Globs $Codecov.Ignore
    if ($ignored) {
        return [pscustomobject]@{
            Crate    = $Crate
            Status   = 'opted-out'
            Missing  = @()
        }
    }
    $missing = @()
    if (-not (Test-MatrixCover -Crate $Crate -MatrixEntries $RustTests.MatrixCrates)) {
        $missing += 'rust-tests.yml jobs.coverage.strategy.matrix.crate'
    }
    # Path filters are optional. When rust-tests.yml is workflow_call-only (reusable workflow),
    # pull_request/push paths are not declared; matrix-crate coverage + codecov flags are authoritative.
    if ($RustTests.PullRequestPaths.Count -gt 0 -and -not (Test-PathCoveredByGlob -Path $Crate -Globs $RustTests.PullRequestPaths)) {
        $missing += 'rust-tests.yml on.pull_request.paths'
    }
    if ($RustTests.PushPaths.Count -gt 0 -and -not (Test-PathCoveredByGlob -Path $Crate -Globs $RustTests.PushPaths)) {
        $missing += 'rust-tests.yml on.push.paths'
    }
    if (-not (Test-PathCoveredByGlob -Path $Crate -Globs $Codecov.RustFlagPaths)) {
        $missing += 'codecov.yml flags.rust.paths'
    }
    return [pscustomobject]@{
        Crate   = $Crate
        Status  = if ($missing.Count -eq 0) { 'registered' } else { 'unregistered' }
        Missing = $missing
    }
}

function Invoke-Validation {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)] [string]$RepoRootPath,
        [Parameter(Mandatory)] [string]$ReportPath
    )
    Install-YamlModuleIfNeeded
    $appRoot = Join-Path -Path $RepoRootPath -ChildPath 'src/500-application'
    $crates = Get-CrateDirectory -ApplicationRoot $appRoot -RepoRootPath $RepoRootPath
    $rustTests = Get-RustTestsConfig -WorkflowPath (Join-Path $RepoRootPath '.github/workflows/rust-tests.yml')
    $codecov = Get-CodecovConfig -CodecovPath (Join-Path $RepoRootPath 'codecov.yml')

    $results = @()
    foreach ($crate in $crates) {
        $results += Test-CrateRegistration -Crate $crate -RustTests $rustTests -Codecov $codecov
    }

    $unregistered = @($results | Where-Object { $_.Status -eq 'unregistered' })
    $report = [pscustomobject]@{
        timestamp        = (Get-Date).ToString('o')
        repoRoot         = $RepoRootPath
        cratesDiscovered = $crates.Count
        registered       = @($results | Where-Object { $_.Status -eq 'registered' }).Count
        optedOut         = @($results | Where-Object { $_.Status -eq 'opted-out' }).Count
        unregistered     = $unregistered.Count
        results          = $results
    }

    $reportDir = $ReportPath
    if (-not (Test-Path -LiteralPath $reportDir)) {
        New-Item -ItemType Directory -Path $reportDir -Force | Out-Null
    }
    $reportFile = Join-Path -Path $reportDir -ChildPath 'rust-crate-registration-report.json'
    $report | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $reportFile -Encoding utf8

    if ($unregistered.Count -gt 0) {
        Write-Host "Rust crate registration check FAILED. $($unregistered.Count) crate(s) unregistered:" -ForegroundColor Red
        foreach ($item in $unregistered) {
            Write-Host "  - $($item.Crate)" -ForegroundColor Red
            foreach ($miss in $item.Missing) {
                Write-Host "      missing: $miss" -ForegroundColor Yellow
            }
        }
        Write-Host "Report: $reportFile"
        return 1
    }

    Write-Host "Rust crate registration check passed. $($crates.Count) crate(s) inspected." -ForegroundColor Green
    Write-Host "Report: $reportFile"
    return 0
}

if ($MyInvocation.InvocationName -ne '.') {
    if (-not $RepoRoot) {
        $RepoRoot = Split-Path -Parent $PSScriptRoot
        if (-not $RepoRoot) { $RepoRoot = (Get-Location).Path }
    }
    if (-not $OutputPath) {
        $OutputPath = Join-Path -Path $RepoRoot -ChildPath 'logs'
    }
    $exitCode = Invoke-Validation -RepoRootPath $RepoRoot -ReportPath $OutputPath
    exit $exitCode
}
