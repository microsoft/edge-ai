# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    $script:SutPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '../Validate-RustCrateRegistration.ps1')).Path
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:SutPath, [ref]$tokens, [ref]$errors)
    $functionDefs = $ast.FindAll(
        { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true)
    $functionScript = ($functionDefs | ForEach-Object { $_.Extent.Text }) -join "`n"
    . ([scriptblock]::Create($functionScript))

    $script:HasYaml = [bool](Get-Module -ListAvailable -Name 'powershell-yaml')
}

Describe 'Convert-GlobToRegex' -Tag 'Unit' {
    It 'translates ** to .*' {
        $regex = Convert-GlobToRegex -Glob 'src/500-application/503/**'
        'src/500-application/503/media-capture-service/Cargo.toml' | Should -Match $regex
    }

    It 'translates single * to non-slash segment' {
        $regex = Convert-GlobToRegex -Glob 'src/500-application/*/Cargo.toml'
        'src/500-application/503/Cargo.toml' | Should -Match $regex
        'src/500-application/503/sub/Cargo.toml' | Should -Not -Match $regex
    }

    It 'escapes regex special characters' {
        $regex = Convert-GlobToRegex -Glob 'foo.bar+baz'
        'foo.bar+baz' | Should -Match $regex
        'fooXbar+baz' | Should -Not -Match $regex
    }
}

Describe 'Test-MatrixCover' -Tag 'Unit' {
    It 'matches exact crate path' {
        Test-MatrixCover -Crate 'src/500-application/503' -MatrixEntries @('src/500-application/503') | Should -BeTrue
    }

    It 'matches crate that is a subdirectory of a matrix entry' {
        Test-MatrixCover -Crate 'src/500-application/507/ai-edge-inference-crate' `
            -MatrixEntries @('src/500-application/507') | Should -BeTrue
    }

    It 'returns false when no entry covers the crate' {
        Test-MatrixCover -Crate 'src/500-application/999' -MatrixEntries @('src/500-application/503') | Should -BeFalse
    }

    It 'returns false for empty matrix' {
        Test-MatrixCover -Crate 'src/500-application/503' -MatrixEntries @() | Should -BeFalse
    }
}

Describe 'Test-PathCoveredByGlob' -Tag 'Unit' {
    It 'matches a crate directory under a ** glob' {
        Test-PathCoveredByGlob -Path 'src/500-application/503/media-capture-service' `
            -Globs @('src/500-application/503/**') | Should -BeTrue
    }

    It 'matches the crate root itself when glob targets the crate' {
        Test-PathCoveredByGlob -Path 'src/500-application/507' `
            -Globs @('src/500-application/507/**') | Should -BeTrue
    }

    It 'returns false when no glob matches' {
        Test-PathCoveredByGlob -Path 'src/500-application/999' `
            -Globs @('src/500-application/503/**', 'src/500-application/507/**') | Should -BeFalse
    }

    It 'returns false for empty glob list' {
        Test-PathCoveredByGlob -Path 'src/500-application/503' -Globs @() | Should -BeFalse
    }
}

Describe 'Get-CrateDirectory' -Tag 'Unit' {
    It 'discovers Cargo.toml files containing a [package] section' {
        $appRoot = Join-Path $TestDrive 'src/500-application'
        $crateDir = Join-Path $appRoot '600/widget'
        New-Item -ItemType Directory -Path $crateDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $crateDir 'Cargo.toml') -Value "[package]`nname = `"widget`"`nversion = `"0.1.0`"`n"

        $crates = @(Get-CrateDirectory -ApplicationRoot $appRoot -RepoRootPath $TestDrive)
        $crates | Should -Contain 'src/500-application/600/widget'
    }

    It 'skips Cargo.toml under target/ directories' {
        $appRoot = Join-Path $TestDrive 'src/500-application'
        $targetDir = Join-Path $appRoot '601/app/target/debug/build/foo'
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $targetDir 'Cargo.toml') -Value "[package]`nname = `"foo`"`n"

        $crates = @(Get-CrateDirectory -ApplicationRoot $appRoot -RepoRootPath $TestDrive)
        $crates | Where-Object { $_ -match '/target/' } | Should -BeNullOrEmpty
    }

    It 'skips Cargo.toml lacking a [package] section (workspace manifests)' {
        $appRoot = Join-Path $TestDrive 'src/500-application'
        $wsDir = Join-Path $appRoot '602'
        New-Item -ItemType Directory -Path $wsDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $wsDir 'Cargo.toml') -Value "[workspace]`nmembers = [`"a`"]`n"

        $crates = @(Get-CrateDirectory -ApplicationRoot $appRoot -RepoRootPath $TestDrive)
        $crates | Should -Not -Contain 'src/500-application/602'
    }

    It 'returns empty array when application root does not exist' {
        $missing = Join-Path $TestDrive 'no-such-root'
        $crates = @(Get-CrateDirectory -ApplicationRoot $missing -RepoRootPath $TestDrive)
        $crates.Count | Should -Be 0
    }
}

Describe 'Test-CrateRegistration' -Tag 'Unit' {
    BeforeAll {
        $script:RustOk = [pscustomobject]@{
            PullRequestPaths = @('src/500-application/503/**')
            PushPaths        = @('src/500-application/503/**')
            MatrixCrates     = @('src/500-application/503')
        }
        $script:CodecovOk = [pscustomobject]@{
            RustFlagPaths = @('src/500-application/503/**')
            Ignore        = @()
        }
    }

    It 'returns opted-out when crate is covered by a codecov ignore glob' {
        $codecov = [pscustomobject]@{
            RustFlagPaths = @()
            Ignore        = @('src/500-application/501/**')
        }
        $rust = [pscustomobject]@{ PullRequestPaths = @(); PushPaths = @(); MatrixCrates = @() }
        $result = Test-CrateRegistration -Crate 'src/500-application/501/sender' -RustTests $rust -Codecov $codecov
        $result.Status | Should -Be 'opted-out'
        $result.Missing.Count | Should -Be 0
    }

    It 'returns registered when matrix, both paths, and rust flag paths cover the crate' {
        $result = Test-CrateRegistration -Crate 'src/500-application/503' -RustTests $script:RustOk -Codecov $script:CodecovOk
        $result.Status | Should -Be 'registered'
        $result.Missing.Count | Should -Be 0
    }

    It 'returns unregistered with matrix and codecov entries when path filters are absent (reusable workflow)' {
        $rust = [pscustomobject]@{ PullRequestPaths = @(); PushPaths = @(); MatrixCrates = @() }
        $codecov = [pscustomobject]@{ RustFlagPaths = @(); Ignore = @() }
        $result = Test-CrateRegistration -Crate 'src/500-application/999' -RustTests $rust -Codecov $codecov
        $result.Status | Should -Be 'unregistered'
        $result.Missing | Should -Contain 'rust-tests.yml jobs.coverage.strategy.matrix.crate'
        $result.Missing | Should -Contain 'codecov.yml flags.rust.paths'
        $result.Missing | Should -Not -Contain 'rust-tests.yml on.pull_request.paths'
        $result.Missing | Should -Not -Contain 'rust-tests.yml on.push.paths'
    }

    It 'returns unregistered with path entries when path filters exist but do not cover the crate' {
        $rust = [pscustomobject]@{
            PullRequestPaths = @('src/500-application/503/**')
            PushPaths        = @('src/500-application/503/**')
            MatrixCrates     = @()
        }
        $codecov = [pscustomobject]@{ RustFlagPaths = @(); Ignore = @() }
        $result = Test-CrateRegistration -Crate 'src/500-application/999' -RustTests $rust -Codecov $codecov
        $result.Status | Should -Be 'unregistered'
        $result.Missing | Should -Contain 'rust-tests.yml on.pull_request.paths'
        $result.Missing | Should -Contain 'rust-tests.yml on.push.paths'
    }

    It 'returns unregistered listing only the missing piece when matrix is the gap' {
        $rust = [pscustomobject]@{
            PullRequestPaths = @('src/500-application/503/**')
            PushPaths        = @('src/500-application/503/**')
            MatrixCrates     = @()
        }
        $result = Test-CrateRegistration -Crate 'src/500-application/503' -RustTests $rust -Codecov $script:CodecovOk
        $result.Status | Should -Be 'unregistered'
        $result.Missing | Should -Be @('rust-tests.yml jobs.coverage.strategy.matrix.crate')
    }
}

Describe 'Invoke-Validation end-to-end' -Tag 'Unit' -Skip:(-not $script:HasYaml) {
    It 'returns 0 and writes a JSON report when every crate is registered' {
        $repoRoot = Join-Path $TestDrive 'repo-clean'
        $crateDir = Join-Path $repoRoot 'src/500-application/503/media-capture-service'
        New-Item -ItemType Directory -Path $crateDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $crateDir 'Cargo.toml') -Value "[package]`nname = `"x`"`n"

        $workflowDir = Join-Path $repoRoot '.github/workflows'
        New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
        $workflow = @'
name: rust-tests
on:
  pull_request:
    paths:
      - 'src/500-application/503/**'
  push:
    paths:
      - 'src/500-application/503/**'
jobs:
  coverage:
    strategy:
      matrix:
        crate:
          - 'src/500-application/503'
'@
        Set-Content -LiteralPath (Join-Path $workflowDir 'rust-tests.yml') -Value $workflow

        $codecov = @'
flags:
  rust:
    paths:
      - 'src/500-application/503/**'
ignore:
  - 'target/**'
'@
        Set-Content -LiteralPath (Join-Path $repoRoot 'codecov.yml') -Value $codecov

        $reportDir = Join-Path $repoRoot 'test-results'
        $exit = Invoke-Validation -RepoRootPath $repoRoot -ReportPath $reportDir
        $exit | Should -Be 0

        $reportFile = Join-Path $reportDir 'rust-crate-registration-report.json'
        Test-Path -LiteralPath $reportFile | Should -BeTrue
        $report = Get-Content -LiteralPath $reportFile -Raw | ConvertFrom-Json
        $report.unregistered | Should -Be 0
        $report.registered | Should -Be 1
    }

    It 'returns 1 and records gaps when a crate is missing from coverage configuration' {
        $repoRoot = Join-Path $TestDrive 'repo-gap'
        $crateDir = Join-Path $repoRoot 'src/500-application/999/orphan'
        New-Item -ItemType Directory -Path $crateDir -Force | Out-Null
        Set-Content -LiteralPath (Join-Path $crateDir 'Cargo.toml') -Value "[package]`nname = `"orphan`"`n"

        $workflowDir = Join-Path $repoRoot '.github/workflows'
        New-Item -ItemType Directory -Path $workflowDir -Force | Out-Null
        $workflow = @'
name: rust-tests
on:
  pull_request:
    paths:
      - 'src/500-application/503/**'
  push:
    paths:
      - 'src/500-application/503/**'
jobs:
  coverage:
    strategy:
      matrix:
        crate:
          - 'src/500-application/503'
'@
        Set-Content -LiteralPath (Join-Path $workflowDir 'rust-tests.yml') -Value $workflow

        $codecov = @'
flags:
  rust:
    paths:
      - 'src/500-application/503/**'
ignore:
  - 'target/**'
'@
        Set-Content -LiteralPath (Join-Path $repoRoot 'codecov.yml') -Value $codecov

        $reportDir = Join-Path $repoRoot 'test-results'
        $exit = Invoke-Validation -RepoRootPath $repoRoot -ReportPath $reportDir
        $exit | Should -Be 1

        $report = Get-Content -LiteralPath (Join-Path $reportDir 'rust-crate-registration-report.json') -Raw | ConvertFrom-Json
        $report.unregistered | Should -Be 1
        $orphan = $report.results | Where-Object { $_.Crate -eq 'src/500-application/999/orphan' }
        $orphan.Status | Should -Be 'unregistered'
        $orphan.Missing | Should -Contain 'rust-tests.yml jobs.coverage.strategy.matrix.crate'
    }
}
