#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    $repoRoot = (Resolve-Path -Path (Join-Path -Path $PSScriptRoot -ChildPath '../../..')).Path
    $scriptPath = Join-Path -Path $repoRoot -ChildPath 'scripts/linting/Invoke-GoTest.ps1'
    . $scriptPath
}

Describe 'Test-IsGoContractTestChangeFile' -Tag 'Unit' {
    It 'returns true for Go contract test paths' {
        Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/tests/outputs_contract_test.go' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/tests/go.mod' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/terraform/outputs.tf' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/bicep/outputs.bicep' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path '.github/workflows/go-tests.yml' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path '.github/workflows/pr-validation.yml' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path 'scripts/linting/Invoke-GoTest.ps1' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path 'src/900-tools-utilities/904-test-utilities/contract.go' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path 'src/900-tools-utilities/904-test-utilities/go.mod' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path 'scripts/install-terraform-docs.sh' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path 'package.json' | Should -BeTrue
        Test-IsGoContractTestChangeFile -Path 'package-lock.json' | Should -BeTrue
    }

    It 'returns false for unrelated paths' {
        Test-IsGoContractTestChangeFile -Path 'docs/README.md' | Should -BeFalse
        Test-IsGoContractTestChangeFile -Path 'src/000-cloud/000-resource-group/terraform/main.tf' | Should -BeFalse
        Test-IsGoContractTestChangeFile -Path '.github/workflows/rust-tests.yml' | Should -BeFalse
        Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/tests/start.sh' | Should -BeFalse
    }
}

Describe 'Test-GoContractTestHasChange' -Tag 'Unit' {
    It 'returns true when any changed file is relevant' {
        Test-GoContractTestHasChange -ChangedFiles @(
            'docs/README.md',
            'blueprints/full-single-node-cluster/tests/outputs_contract_test.go'
        ) | Should -BeTrue
    }

    It 'returns true when shared test-utility helper changes' {
        Test-GoContractTestHasChange -ChangedFiles @(
            'docs/README.md',
            'src/900-tools-utilities/904-test-utilities/contract.go'
        ) | Should -BeTrue
    }

    It 'returns true when terraform-docs installer changes' {
        Test-GoContractTestHasChange -ChangedFiles @(
            'docs/README.md',
            'scripts/install-terraform-docs.sh'
        ) | Should -BeTrue
    }

    It 'returns false when no changed files are relevant' {
        Test-GoContractTestHasChange -ChangedFiles @(
            'docs/README.md',
            'src/000-cloud/000-resource-group/terraform/main.tf'
        ) | Should -BeFalse
    }

    It 'returns false when changed files are empty or null' {
        Test-GoContractTestHasChange -ChangedFiles @() | Should -BeFalse
        Test-GoContractTestHasChange -ChangedFiles $null | Should -BeFalse
    }
}

Describe 'Invoke-GoTestCore' -Tag 'Unit' {
    BeforeEach {
        $testRepo = Join-Path -Path $TestDrive -ChildPath 'repo'
        $contractTestPath = Join-Path -Path $testRepo -ChildPath 'blueprints/full-single-node-cluster/tests'
        New-Item -Path $contractTestPath -ItemType Directory -Force | Out-Null
        Set-Content -Path (Join-Path -Path $contractTestPath -ChildPath 'go.mod') -Value 'module test' -Encoding utf8

        Mock Set-CIOutput { }
        Mock Write-CIStepSummary { }
    }

    It 'constructs the static-only Go test command' {
        $capturedArguments = $null
        $runner = {
            param([string[]]$Arguments)
            $script:capturedArguments = $Arguments
            return 0
        }

        $exitCode = Invoke-GoTestCore -RepoRoot $testRepo -CommandRunner $runner

        $exitCode | Should -Be 0
        $script:capturedArguments | Should -Be @('test', '.', '-run', '^(TestTerraformOutputsContract|TestBicepOutputsContract)$')
        Should -Invoke Set-CIOutput -ParameterFilter { $Name -eq 'goContractTestsRan' -and $Value -eq 'true' } -Times 1 -Exactly
    }

    It 'returns a clear failure when Go is unavailable' {
        Mock Get-Command { return $null } -ParameterFilter { $Name -eq 'go' }
        Mock Write-Error { }

        Invoke-GoTestCommand -Arguments @('test', '.') | Should -Be 1
        Should -Invoke Write-Error -ParameterFilter { $Message -match 'Go CLI was not found on PATH' } -Times 1 -Exactly
    }

    It 'runs from the Go contract test directory' {
        $observedLocation = $null
        $runner = {
            param([string[]]$Arguments)
            $null = $Arguments
            $script:observedLocation = (Get-Location).Path
            return 0
        }

        Invoke-GoTestCore -RepoRoot $testRepo -CommandRunner $runner | Should -Be 0

        $script:observedLocation | Should -Be (Join-Path -Path $testRepo -ChildPath 'blueprints/full-single-node-cluster/tests')
    }

    It 'propagates Go test failure exit codes' {
        $runner = {
            param([string[]]$Arguments)
            $null = $Arguments
            return 7
        }

        Invoke-GoTestCore -RepoRoot $testRepo -CommandRunner $runner | Should -Be 7
        Should -Invoke Set-CIOutput -ParameterFilter { $Name -eq 'goContractTestsExitCode' -and $Value -eq '7' } -Times 1 -Exactly
    }

    It 'returns failure when the Go contract test context is missing' {
        $missingRepo = Join-Path -Path $TestDrive -ChildPath 'missing-repo'
        New-Item -Path $missingRepo -ItemType Directory -Force | Out-Null
        $runner = {
            param([string[]]$Arguments)
            $null = $Arguments
            throw 'go should not be invoked'
        }

        { Invoke-GoTestCore -RepoRoot $missingRepo -CommandRunner $runner } | Should -Throw
    }

    It 'runs when changed-file gating detects relevant changes' {
        $script:invoked = $false
        $runner = {
            param([string[]]$Arguments)
            $null = $Arguments
            $script:invoked = $true
            return 0
        }

        Invoke-GoTestCore -RepoRoot $testRepo -ChangedOnly -ChangedFiles @('blueprints/full-single-node-cluster/tests/go.mod') -CommandRunner $runner | Should -Be 0

        $script:invoked | Should -BeTrue
        Should -Invoke Set-CIOutput -ParameterFilter { $Name -eq 'goContractTestsRan' -and $Value -eq 'true' } -Times 1 -Exactly
    }

    It 'skips when changed-file gating finds no relevant changes' {
        $script:invoked = $false
        $runner = {
            param([string[]]$Arguments)
            $null = $Arguments
            $script:invoked = $true
            return 0
        }

        Invoke-GoTestCore -RepoRoot $testRepo -ChangedOnly -ChangedFiles @('docs/README.md') -CommandRunner $runner | Should -Be 0

        $script:invoked | Should -BeFalse
        Should -Invoke Set-CIOutput -ParameterFilter { $Name -eq 'goContractTestsRan' -and $Value -eq 'false' } -Times 1 -Exactly
    }
}
