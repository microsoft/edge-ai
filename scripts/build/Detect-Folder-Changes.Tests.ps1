#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    $script:SutPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath 'Detect-Folder-Changes.ps1')).Path
    $tokens = $null
    $errors = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $script:SutPath, [ref]$tokens, [ref]$errors)
    $functionDefs = $ast.FindAll(
        { param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true)
    $functionScript = ($functionDefs | ForEach-Object { $_.Extent.Text }) -join "`n"
    . ([scriptblock]::Create($functionScript))
}

Describe 'Test-IsRustChangeFile' -Tag 'Unit' {
    It 'matches files under src/500-application/' {
        Test-IsRustChangeFile -Path 'src/500-application/503/media-capture-service/src/main.rs' | Should -BeTrue
    }

    It 'matches root Cargo.toml exactly' {
        Test-IsRustChangeFile -Path 'Cargo.toml' | Should -BeTrue
    }

    It 'matches root Cargo.lock exactly' {
        Test-IsRustChangeFile -Path 'Cargo.lock' | Should -BeTrue
    }

    It 'matches codecov.yml exactly' {
        Test-IsRustChangeFile -Path 'codecov.yml' | Should -BeTrue
    }

    It 'matches the rust-tests workflow' {
        Test-IsRustChangeFile -Path '.github/workflows/rust-tests.yml' | Should -BeTrue
    }

    It 'matches the pr-validation workflow' {
        Test-IsRustChangeFile -Path '.github/workflows/pr-validation.yml' | Should -BeTrue
    }

    It 'returns false for unrelated documentation' {
        Test-IsRustChangeFile -Path 'docs/readme.md' | Should -BeFalse
    }

    It 'returns false for terraform sources outside 500-application' {
        Test-IsRustChangeFile -Path 'src/020-iac/main.tf' | Should -BeFalse
    }

    It 'returns true for any nested Cargo.toml' {
        Test-IsRustChangeFile -Path 'crates/foo/Cargo.toml' | Should -BeTrue
    }

    It 'matches Rust sources under src/900-tools-utilities/' {
        Test-IsRustChangeFile -Path 'src/900-tools-utilities/901-video-tools/cli/video-to-gif/src/main.rs' | Should -BeTrue
    }

    It 'matches Cargo.toml under src/900-tools-utilities/' {
        Test-IsRustChangeFile -Path 'src/900-tools-utilities/901-video-tools/cli/video-to-gif/Cargo.toml' | Should -BeTrue
    }

    It 'returns false for markdown files containing .rs in the name' {
        Test-IsRustChangeFile -Path 'docs/example.rs.md' | Should -BeFalse
    }

    It 'returns false for text files referencing rs' {
        Test-IsRustChangeFile -Path 'notes/rs-overview.txt' | Should -BeFalse
    }

    It 'returns false for the matrix-folder-check workflow' {
        Test-IsRustChangeFile -Path '.github/workflows/matrix-folder-check.yml' | Should -BeFalse
    }

    It 'returns false for an empty path' {
        Test-IsRustChangeFile -Path '' | Should -BeFalse
    }
}

Describe 'Test-RustHasChange' -Tag 'Unit' {
    It 'returns false for $null input' {
        Test-RustHasChange -ChangedFiles $null | Should -BeFalse
    }

    It 'returns false for an empty array' {
        Test-RustHasChange -ChangedFiles @() | Should -BeFalse
    }

    It 'returns true when any file matches' {
        Test-RustHasChange -ChangedFiles @('docs/readme.md', 'Cargo.toml') | Should -BeTrue
    }

    It 'returns true when a src/500-application file is present' {
        Test-RustHasChange -ChangedFiles @('src/500-application/503/foo/src/lib.rs') | Should -BeTrue
    }

    It 'returns false when no file matches' {
        Test-RustHasChange -ChangedFiles @('docs/readme.md', 'src/020-iac/main.tf') | Should -BeFalse
    }
}

Describe 'Test-IsGoContractTestChangeFile' -Tag 'Unit' {
    Context 'when evaluating Go contract-test trigger paths' {
        It 'Detects Go contract-test relevant files' {
            Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/tests/go.mod' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/tests/output_contract_test.go' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/terraform/outputs.tf' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/bicep/main.bicep' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'scripts/linting/Invoke-GoTest.ps1' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'scripts/tests/linting/Invoke-GoTest.Tests.ps1' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'src/900-tools-utilities/904-test-utilities/contract.go' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'src/900-tools-utilities/904-test-utilities/go.mod' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'scripts/install-terraform-docs.sh' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'scripts/build/Detect-Folder-Changes.ps1' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path '.github/workflows/go-tests.yml' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path '.github/workflows/matrix-folder-check.yml' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path '.github/workflows/pr-validation.yml' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'package.json' | Should -BeTrue
            Test-IsGoContractTestChangeFile -Path 'package-lock.json' | Should -BeTrue
        }

        It 'Ignores unrelated files' {
            Test-IsGoContractTestChangeFile -Path 'docs/readme.md' | Should -BeFalse
            Test-IsGoContractTestChangeFile -Path 'src/000-cloud/010-security-identity/terraform/main.tf' | Should -BeFalse
            Test-IsGoContractTestChangeFile -Path '.github/workflows/rust-tests.yml' | Should -BeFalse
            Test-IsGoContractTestChangeFile -Path 'Cargo.toml' | Should -BeFalse
            Test-IsGoContractTestChangeFile -Path 'blueprints/full-single-node-cluster/tests/start.sh' | Should -BeFalse
            Test-IsGoContractTestChangeFile -Path '' | Should -BeFalse
        }
    }
}

Describe 'Test-GoContractTestHasChange' -Tag 'Unit' {
    Context 'when evaluating changed file collections' {
        It 'Returns false for null or empty inputs' {
            Test-GoContractTestHasChange -ChangedFiles $null | Should -BeFalse
            Test-GoContractTestHasChange -ChangedFiles @() | Should -BeFalse
        }

        It 'Returns true when any file should trigger Go contract tests' {
            Test-GoContractTestHasChange -ChangedFiles @('docs/readme.md', 'blueprints/full-single-node-cluster/tests/go.mod') | Should -BeTrue
            Test-GoContractTestHasChange -ChangedFiles @('blueprints/full-single-node-cluster/terraform/outputs.tf') | Should -BeTrue
            Test-GoContractTestHasChange -ChangedFiles @('.github/workflows/go-tests.yml') | Should -BeTrue
            Test-GoContractTestHasChange -ChangedFiles @('docs/readme.md', 'src/900-tools-utilities/904-test-utilities/contract.go') | Should -BeTrue
            Test-GoContractTestHasChange -ChangedFiles @('docs/readme.md', 'scripts/install-terraform-docs.sh') | Should -BeTrue
        }

        It 'Returns false when no files should trigger Go contract tests' {
            Test-GoContractTestHasChange -ChangedFiles @('docs/readme.md', 'src/000-cloud/010-security-identity/terraform/main.tf') | Should -BeFalse
        }
    }
}

Describe 'Test-IsTerraformInstallChangeFile' -Tag 'Unit' {
    Context 'when evaluating Terraform module-test trigger paths' {
        It 'Detects Terraform source and variable files' {
            Test-IsTerraformInstallChangeFile -Path 'blueprints/full-single-node-cluster/terraform/outputs.tf' | Should -BeTrue
            Test-IsTerraformInstallChangeFile -Path 'src/000-cloud/010-security-identity/terraform/main.tf' | Should -BeTrue
            Test-IsTerraformInstallChangeFile -Path 'blueprints/full-single-node-cluster/terraform/test.tfvars' | Should -BeTrue
            Test-IsTerraformInstallChangeFile -Path 'blueprints/full-single-node-cluster/terraform/backend.hcl' | Should -BeTrue
        }

        It 'Ignores Go contract-test tooling and non-Terraform files' {
            Test-IsTerraformInstallChangeFile -Path 'blueprints/full-single-node-cluster/tests/output_contract_test.go' | Should -BeFalse
            Test-IsTerraformInstallChangeFile -Path 'blueprints/full-single-node-cluster/tests/go.mod' | Should -BeFalse
            Test-IsTerraformInstallChangeFile -Path 'scripts/linting/Invoke-GoTest.ps1' | Should -BeFalse
            Test-IsTerraformInstallChangeFile -Path 'src/900-tools-utilities/904-test-utilities/contract.go' | Should -BeFalse
            Test-IsTerraformInstallChangeFile -Path 'scripts/install-terraform-docs.sh' | Should -BeFalse
            Test-IsTerraformInstallChangeFile -Path '.github/workflows/go-tests.yml' | Should -BeFalse
            Test-IsTerraformInstallChangeFile -Path 'package.json' | Should -BeFalse
            Test-IsTerraformInstallChangeFile -Path '' | Should -BeFalse
        }
    }
}

Describe 'Get-BicepFullValidationReason' -Tag 'Unit' {
    It 'returns bicepconfig for root Bicep configuration changes' {
        @(Get-BicepFullValidationReason -Files @('bicepconfig.json')) | Should -Contain 'bicepconfig'
    }

    It 'returns shared-blueprint-modules for shared blueprint module changes' {
        @(Get-BicepFullValidationReason -Files @('blueprints/modules/core/main.bicep')) |
            Should -Contain 'shared-blueprint-modules'
    }

    It 'returns no reason for unrelated Bicep workflow template changes' {
        @(Get-BicepFullValidationReason -Files @('.azdo/templates/bicep-lint-template.yml')) | Should -BeNullOrEmpty
    }
}

Describe 'Get-FilePathData for Bicep paths' -Tag 'Unit' {
    It 'returns the component folder for changed source Bicep files' {
        @(Get-FilePathData -Paths @('src/000-cloud/000-resource-group/bicep/main.bicep')) |
            Should -Contain 'src/000-cloud/000-resource-group'
    }

    It 'returns the blueprint folder for changed blueprint Bicep files' {
        @(Get-FilePathData -Paths @('blueprints/full-single-node-cluster/bicep/main.bicep')) |
            Should -Contain 'blueprints/full-single-node-cluster'
    }

    It 'excludes shared blueprint modules from scoped folder output' {
        @(Get-FilePathData -Paths @('blueprints/modules/core/types.bicep')) | Should -BeNullOrEmpty
    }
}

Describe 'Get-DependentBicepBlueprintPath' -Tag 'Unit' {
    BeforeEach {
        $script:RepoRoot = Join-Path $TestDrive 'repo'
        $script:BlueprintRoot = Join-Path $script:RepoRoot 'blueprints'
        $dependentBlueprint = Join-Path $script:BlueprintRoot 'full-single-node-cluster/bicep'
        $unrelatedBlueprint = Join-Path $script:BlueprintRoot 'fabric/bicep'

        New-Item -ItemType Directory -Path $dependentBlueprint, $unrelatedBlueprint -Force | Out-Null

        @"
module rg '../../../src/000-cloud/000-resource-group/bicep/main.bicep' = {
  name: 'resourceGroup'
}
"@ | Set-Content -Path (Join-Path $dependentBlueprint 'main.bicep')

        @"
module fabric '../../../src/000-cloud/031-fabric/bicep/main.bicep' = {
  name: 'fabric'
}
"@ | Set-Content -Path (Join-Path $unrelatedBlueprint 'main.bicep')
    }

    It 'returns blueprints that reference a changed Bicep component' {
        $result = @(Get-DependentBicepBlueprintPath `
                -ChangedPaths @('src/000-cloud/000-resource-group') `
                -BlueprintRoot $script:BlueprintRoot)

        $result | Should -Contain 'blueprints/full-single-node-cluster'
        $result | Should -Not -Contain 'blueprints/fabric'
        $result | Should -HaveCount 1
    }

    It 'deduplicates dependent blueprints for repeated component paths' {
        $result = @(Get-DependentBicepBlueprintPath `
                -ChangedPaths @(
                    'src/000-cloud/000-resource-group',
                    'src/000-cloud/000-resource-group/bicep' `
                ) `
                -BlueprintRoot $script:BlueprintRoot)

        $result | Should -Contain 'blueprints/full-single-node-cluster'
        $result | Should -HaveCount 1
    }
}
