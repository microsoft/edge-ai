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

Describe 'Camera onboarding application dependency' -Tag 'Unit' {
    BeforeAll {
        $script:CameraStructure = @{
            'onvif-connector' = @{ directory = '510-onvif-connector' }
            'media-connector' = @{ directory = '508-media-connector' }
        }
    }

    It 'selects the dashboard application for a shared CLI-only change' {
        $result = Get-ApplicationChange `
            -ChangedFiles @('src/100-edge/111-assets/scripts/camera_onboarding.py') `
            -ApplicationStructure $script:CameraStructure `
            -ApplicationRelativePath 'src/500-application'

        $result.Keys | Should -HaveCount 1
        $result['onvif-connector'].directory | Should -Be 'src/500-application/510-onvif-connector'
    }

    It 'selects the dashboard for shared CLI tests and Windows separators' {
        $result = Get-ApplicationChange `
            -ChangedFiles @('src\100-edge\111-assets\scripts\tests\test_camera_onboarding.py') `
            -ApplicationStructure $script:CameraStructure `
            -ApplicationRelativePath 'src/500-application'

        $result.Keys | Should -Contain 'onvif-connector'
    }

    It 'does not select applications for unrelated asset scripts' {
        $result = Get-ApplicationChange `
            -ChangedFiles @('src/100-edge/111-assets/scripts/onvif-ptz-check.sh') `
            -ApplicationStructure $script:CameraStructure `
            -ApplicationRelativePath 'src/500-application'

        $result.Count | Should -Be 0
    }

    It 'preserves direct application changes and deduplicates dependencies' {
        $result = Get-ApplicationChange `
            -ChangedFiles @(
                'src/100-edge/111-assets/scripts/camera_onboarding.py',
                'src/500-application/510-onvif-connector/services/camera-dashboard/src/app.py',
                'src/500-application/508-media-connector/README.md'
            ) `
            -ApplicationStructure $script:CameraStructure `
            -ApplicationRelativePath 'src/500-application'

        $result.Keys | Should -HaveCount 2
        $result.Keys | Should -Contain 'media-connector'
    }

    It 'runs camera qualification in the selected application build job' {
        $workflow = Get-Content -Raw (Join-Path $PSScriptRoot '../../.github/workflows/application-matrix-builds.yml')
        $workflow | Should -Match "if: matrix.applicationName == 'onvif-connector'"
        $workflow | Should -Match 'python -m pytest -q'
        $workflow | Should -Match 'src/100-edge/111-assets/scripts/tests'
        $workflow | Should -Match 'services/camera-dashboard/tests'
    }
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
        @(Get-FilePathData -Paths @('blueprints/full-multi-node-cluster/bicep/main.bicep')) |
            Should -Contain 'blueprints/full-multi-node-cluster'
    }

    It 'excludes shared blueprint modules from scoped folder output' {
        @(Get-FilePathData -Paths @('blueprints/modules/core/types.bicep')) | Should -BeNullOrEmpty
    }
}

Describe 'Get-DependentBicepBlueprintPath' -Tag 'Unit' {
    BeforeEach {
        $script:RepoRoot = Join-Path $TestDrive 'repo'
        $script:BlueprintRoot = Join-Path $script:RepoRoot 'blueprints'
        $dependentBlueprint = Join-Path $script:BlueprintRoot 'full-multi-node-cluster/bicep'
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

        $result | Should -Contain 'blueprints/full-multi-node-cluster'
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

        $result | Should -Contain 'blueprints/full-multi-node-cluster'
        $result | Should -HaveCount 1
    }
}
