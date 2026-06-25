#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    . (Join-Path $PSScriptRoot 'Invoke-BicepLint.ps1')
}

Describe 'ConvertTo-BicepRunnerBoolean' -Tag 'Unit' {
    It 'returns true for true values' {
        ConvertTo-BicepRunnerBoolean -Value 'true' | Should -BeTrue
    }

    It 'returns false for false values' {
        ConvertTo-BicepRunnerBoolean -Value 'FALSE' | Should -BeFalse
    }

    It 'throws for invalid values' {
        { ConvertTo-BicepRunnerBoolean -Value 'maybe' } | Should -Throw -ExpectedMessage '*Expected boolean value*'
    }
}

Describe 'Get-BicepFolderPathFromJson' -Tag 'Unit' {
    It 'returns folderName values from detector JSON' {
        $json = @{
            'src/000-cloud/010-security-identity/bicep' = @{
                folderName = 'src/000-cloud/010-security-identity/bicep'
            }
            'blueprints/full-multi-node-cluster/bicep' = @{
                folderName = 'blueprints/full-multi-node-cluster/bicep'
            }
        } | ConvertTo-Json -Depth 4 -Compress

        $result = @(Get-BicepFolderPathFromJson -BicepFoldersJson $json)

        $result | Should -Contain 'src/000-cloud/010-security-identity/bicep'
        $result | Should -Contain 'blueprints/full-multi-node-cluster/bicep'
        $result | Should -HaveCount 2
    }

    It 'deduplicates folderName arrays' {
        $json = @{
            folders = @{
                folderName = @('src/a/bicep', 'src/a/bicep', 'blueprints/b/bicep')
            }
        } | ConvertTo-Json -Depth 5 -Compress

        $result = @(Get-BicepFolderPathFromJson -BicepFoldersJson $json)

        $result | Should -Contain 'src/a/bicep'
        $result | Should -Contain 'blueprints/b/bicep'
        $result | Should -HaveCount 2
    }

    It 'throws for invalid JSON' {
        { Get-BicepFolderPathFromJson -BicepFoldersJson '{not-json}' } |
            Should -Throw -ExpectedMessage '*Failed to parse Bicep folders JSON*'
    }
}

Describe 'Get-BicepValidationFile' -Tag 'Unit' {
    BeforeEach {
        $script:RepoRoot = Join-Path $TestDrive 'repo'
        New-Item -ItemType Directory -Path $script:RepoRoot -Force | Out-Null

        $componentFolder = Join-Path $script:RepoRoot 'src/000-cloud/010-security-identity/bicep'
        $blueprintFolder = Join-Path $script:RepoRoot 'blueprints/full-multi-node-cluster/bicep'
        $nodeFolder = Join-Path $script:RepoRoot 'node_modules/package/bicep'
        $trackingFolder = Join-Path $script:RepoRoot '.copilot-tracking/generated/bicep'

        New-Item -ItemType Directory -Path $componentFolder, $blueprintFolder, $nodeFolder, $trackingFolder -Force | Out-Null
        'param name string' | Set-Content -Path (Join-Path $componentFolder 'main.bicep')
        'param location string' | Set-Content -Path (Join-Path $blueprintFolder 'main.bicep')
        'param ignored string' | Set-Content -Path (Join-Path $nodeFolder 'ignored.bicep')
        'param ignored string' | Set-Content -Path (Join-Path $trackingFolder 'ignored.bicep')
    }

    It 'finds all repository Bicep files for full validation and excludes ignored paths' {
        $result = @(Get-BicepValidationFile -RepoRoot $script:RepoRoot -FullValidation $true)

        $result | Should -Contain 'src/000-cloud/010-security-identity/bicep/main.bicep'
        $result | Should -Contain 'blueprints/full-multi-node-cluster/bicep/main.bicep'
        $result | Should -Not -Contain 'node_modules/package/bicep/ignored.bicep'
        $result | Should -Not -Contain '.copilot-tracking/generated/bicep/ignored.bicep'
        $result | Should -HaveCount 2
    }

    It 'finds files only under scoped detector folders' {
        $json = @{
            component = @{ folderName = 'src/000-cloud/010-security-identity/bicep' }
        } | ConvertTo-Json -Depth 4 -Compress

        $result = @(Get-BicepValidationFile -RepoRoot $script:RepoRoot -FullValidation $false -BicepFoldersJson $json)

        $result | Should -Contain 'src/000-cloud/010-security-identity/bicep/main.bicep'
        $result | Should -Not -Contain 'blueprints/full-multi-node-cluster/bicep/main.bicep'
        $result | Should -HaveCount 1
    }

    It 'emits a GitHub annotation for missing folders when Platform is github' {
        $json = @{
            missing = @{ folderName = 'src/does-not-exist/bicep' }
        } | ConvertTo-Json -Depth 4 -Compress

        $output = Get-BicepValidationFile -RepoRoot $script:RepoRoot -FullValidation $false -BicepFoldersJson $json -Platform 'github'

        $output | Should -Contain '::warning::Bicep folder does not exist: src/does-not-exist/bicep'
    }

    It 'does not emit a GitHub annotation for missing folders when Platform is generic' {
        $json = @{
            missing = @{ folderName = 'src/does-not-exist/bicep' }
        } | ConvertTo-Json -Depth 4 -Compress

        $output = Get-BicepValidationFile -RepoRoot $script:RepoRoot -FullValidation $false -BicepFoldersJson $json -Platform 'generic' -WarningAction SilentlyContinue

        $output | Should -Not -Contain '::warning::Bicep folder does not exist: src/does-not-exist/bicep'
    }
}

Describe 'Get-BicepValidationCommand' -Tag 'Unit' {
    It 'uses lint when Azure CLI supports Bicep lint' {
        Mock Test-BicepLintSupport { return $true }

        Get-BicepValidationCommand | Should -Be 'lint'
    }

    It 'uses build when Azure CLI does not support Bicep lint' {
        Mock Test-BicepLintSupport { return $false }

        Get-BicepValidationCommand | Should -Be 'build'
    }
}

Describe 'Write-BicepSummary' -Tag 'Unit' {
    It 'writes a markdown summary with zero failures' {
        $outputFile = Join-Path $TestDrive 'summary-success.md'

        $summary = Write-BicepSummary `
            -FilesChecked 2 `
            -Failures 0 `
            -FailedFiles @() `
            -OutputFile $outputFile

        $summary | Should -Match 'Files checked:.+2'
        $summary | Should -Match 'Failures:.+0'
        $summary | Should -Not -Match 'Failed files'
        Get-Content -Path $outputFile -Raw | Should -Match '## Bicep Lint Results'
    }

    It 'writes a markdown summary with failed files' {
        $outputFile = Join-Path $TestDrive 'summary.md'

        $summary = Write-BicepSummary `
            -FilesChecked 2 `
            -Failures 1 `
            -FailedFiles @('src/app/bicep/main.bicep') `
            -OutputFile $outputFile

        $summary | Should -Match 'Files checked:.+2'
        $summary | Should -Match 'Failures:.+1'
        $summary | Should -Match 'src/app/bicep/main.bicep'
        Get-Content -Path $outputFile -Raw | Should -Match '## Bicep Lint Results'
    }
}
