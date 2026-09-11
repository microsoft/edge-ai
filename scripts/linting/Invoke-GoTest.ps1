#!/usr/bin/env pwsh
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT
#Requires -Version 7.0

<#
.SYNOPSIS
Runs static Go contract tests for the full single-node cluster blueprint.

.DESCRIPTION
Executes the Go contract tests that validate Terraform and Bicep output shape without requiring Azure authentication or deployments. The wrapper can optionally skip execution when the current change set does not affect the contract tests or their supporting workflow.

.PARAMETER RepoRoot
Repository root path. Defaults to the current working directory.

.PARAMETER BaseBranch
Base branch used when ChangedOnly is specified.

.PARAMETER ChangedOnly
Runs the contract tests only when relevant files have changed.

.PARAMETER ChangedFiles
Optional repo-relative changed file list used by tests or callers that already computed changes.

.PARAMETER CommandRunner
Optional command runner script block used by tests to avoid invoking external tools.

.EXAMPLE
./scripts/linting/Invoke-GoTest.ps1

.EXAMPLE
./scripts/linting/Invoke-GoTest.ps1 -ChangedOnly -BaseBranch origin/main

.NOTES
This script intentionally limits execution to static contract tests only.
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory = $false)]
    [string]$RepoRoot = (Get-Location).Path,

    [Parameter(Mandatory = $false)]
    [string]$BaseBranch = 'origin/main',

    [Parameter(Mandatory = $false)]
    [switch]$ChangedOnly,

    [Parameter(Mandatory = $false)]
    [string[]]$ChangedFiles,

    [Parameter(Mandatory = $false)]
    [scriptblock]$CommandRunner
)

$ErrorActionPreference = 'Stop'

$ciHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath '../ci/Modules/CIHelpers.psm1'
$lintingHelpersPath = Join-Path -Path $PSScriptRoot -ChildPath 'Modules/LintingHelpers.psm1'
Import-Module -Name $ciHelpersPath -Force
Import-Module -Name $lintingHelpersPath -Force

#region Functions
function Test-IsGoContractTestChangeFile {
    <#
    .SYNOPSIS
    Returns true when a path should trigger static Go contract tests.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [AllowEmptyString()]
        [string]$Path
    )

    return $Path -match '(^blueprints/full-single-node-cluster/(terraform|bicep)/|^blueprints/full-single-node-cluster/tests/([^/]+\.go|go\.(mod|sum))$|^src/900-tools-utilities/904-test-utilities/|^scripts/install-terraform-docs\.sh$|^scripts/linting/Invoke-GoTest\.ps1$|^scripts/tests/linting/Invoke-GoTest\.Tests\.ps1$|^\.github/workflows/(go-tests|matrix-folder-check|pr-validation)\.yml$|^scripts/build/Detect-Folder-Changes\.ps1$|^package(-lock)?\.json$)'
}

function Test-GoContractTestHasChange {
    <#
    .SYNOPSIS
    Returns true when any changed path should trigger static Go contract tests.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [string[]]$ChangedFiles
    )

    if ($null -eq $ChangedFiles -or $ChangedFiles.Count -eq 0) {
        return $false
    }

    foreach ($file in $ChangedFiles) {
        if (Test-IsGoContractTestChangeFile -Path $file) {
            return $true
        }
    }

    return $false
}

function Test-GoCommandAvailable {
    <#
    .SYNOPSIS
    Returns true when the Go CLI is available on PATH.
    #>
    [CmdletBinding()]
    [OutputType([bool])]
    param()

    return $null -ne (Get-Command -Name go -ErrorAction SilentlyContinue)
}

function Invoke-GoTestCommand {
    <#
    .SYNOPSIS
    Executes go with the supplied argument list.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $true)]
        [string[]]$Arguments
    )

    if (-not (Test-GoCommandAvailable)) {
        Write-Error "Go CLI was not found on PATH. Install Go or use the CI workflow with actions/setup-go."
        return 1
    }

    & go @Arguments
    return $LASTEXITCODE
}

function Invoke-GoTestCore {
    <#
    .SYNOPSIS
    Runs static Go contract tests when context and change gates allow execution.
    #>
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$RepoRoot = (Get-Location).Path,

        [Parameter(Mandatory = $false)]
        [string]$BaseBranch = 'origin/main',

        [Parameter(Mandatory = $false)]
        [switch]$ChangedOnly,

        [Parameter(Mandatory = $false)]
        [string[]]$ChangedFiles,

        [Parameter(Mandatory = $false)]
        [scriptblock]$CommandRunner
    )

    $resolvedRepoRoot = (Resolve-Path -Path $RepoRoot).Path
    $testPath = Join-Path -Path $resolvedRepoRoot -ChildPath 'blueprints/full-single-node-cluster/tests'
    $goModPath = Join-Path -Path $testPath -ChildPath 'go.mod'

    if (-not (Test-Path -Path $goModPath -PathType Leaf)) {
        Write-Error "Go contract test context was not found at '$goModPath'."
        return 1
    }

    $filesToEvaluate = $ChangedFiles
    if ($ChangedOnly -and $null -eq $filesToEvaluate) {
        Push-Location -Path $resolvedRepoRoot
        try {
            $filesToEvaluate = Get-ChangedFilesFromGit -Extension @('.go', '.mod', '.sum', '.tf', '.bicep', '.ps1', '.yml', '.yaml', '.json') -BaseBranch $BaseBranch |
                ForEach-Object {
                    $resolvedPath = (Resolve-Path -Path $_).Path
                    [System.IO.Path]::GetRelativePath($resolvedRepoRoot, $resolvedPath).Replace('\\', '/')
                }
        }
        finally {
            Pop-Location
        }
    }

    if ($ChangedOnly -and -not (Test-GoContractTestHasChange -ChangedFiles $filesToEvaluate)) {
        Write-Host 'No Go contract test relevant changes detected. Skipping static Go contract tests.'
        Set-CIOutput -Name 'goContractTestsRan' -Value 'false'
        Write-CIStepSummary -Content 'Static Go contract tests skipped because no relevant files changed.'
        return 0
    }

    $testFilter = '^(TestTerraformOutputsContract|TestBicepOutputsContract)$'
    $goArguments = @('test', '.', '-run', $testFilter)
    Write-Host "Running static Go contract tests in '$testPath'."
    Push-Location -Path $testPath
    try {
        $exitCode = if ($null -ne $CommandRunner) {
            & $CommandRunner -Arguments $goArguments
        }
        else {
            Invoke-GoTestCommand -Arguments $goArguments
        }
    }
    finally {
        Pop-Location
    }

    Set-CIOutput -Name 'goContractTestsRan' -Value 'true'
    Set-CIOutput -Name 'goContractTestsExitCode' -Value ([string]$exitCode)

    if ($exitCode -eq 0) {
        Write-CIStepSummary -Content 'Static Go contract tests completed successfully.'
    }
    else {
        Write-CIStepSummary -Content "Static Go contract tests failed with exit code $exitCode."
    }

    return $exitCode
}
#endregion

if ($MyInvocation.InvocationName -ne '.') {
    try {
        $exitCode = Invoke-GoTestCore -RepoRoot $RepoRoot -BaseBranch $BaseBranch -ChangedOnly:$ChangedOnly -ChangedFiles $ChangedFiles -CommandRunner $CommandRunner
        exit $exitCode
    }
    catch {
        Write-Error $_
        exit 1
    }
}
