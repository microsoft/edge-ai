#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    . (Join-Path $PSScriptRoot '../Install-PSModules.ps1')

    $script:ManifestPath = Join-Path $TestDrive 'ps-module-versions.json'
    @{
        modules = @{
            'powershell-yaml' = @{ version = '0.4.12'; purpose = 'test' }
            'Other-Module'    = @{ version = '1.0.0'; purpose = 'test' }
        }
    } | ConvertTo-Json -Depth 5 | Set-Content -Path $script:ManifestPath -Encoding utf8
}

Describe 'Get-PinnedModuleSet' -Tag 'Unit' {
    It 'returns every manifest module when no names are requested' {
        $set = Get-PinnedModuleSet -ManifestPath $script:ManifestPath
        $set.Name | Should -Contain 'powershell-yaml'
        $set.Name | Should -Contain 'Other-Module'
    }

    It 'returns only the requested modules' {
        $set = @(Get-PinnedModuleSet -ManifestPath $script:ManifestPath -Name 'powershell-yaml')
        $set | Should -HaveCount 1
        $set[0].Version | Should -Be '0.4.12'
    }

    It 'throws for a module missing from the manifest' {
        { Get-PinnedModuleSet -ManifestPath $script:ManifestPath -Name 'Not-Pinned' } | Should -Throw '*Not-Pinned*'
    }
}

Describe 'Install-PinnedModule' -Tag 'Unit' {
    BeforeAll {
        Mock Write-Host {}
        Mock Write-Warning {}
        Mock Start-Sleep {}
        Mock Import-Module {}
    }

    Context 'when the exact version is already installed' {
        BeforeAll {
            Mock Get-Module { [pscustomobject]@{ Name = 'powershell-yaml'; Version = [version]'0.4.12' } } -ParameterFilter { $ListAvailable }
            Mock Install-PSResource {}
        }

        It 'imports without installing' {
            Install-PinnedModule -Name 'powershell-yaml' -Version '0.4.12' -MaxAttempts 3 -InitialDelaySeconds 1
            Should -Invoke Install-PSResource -Times 0 -Exactly
            Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter { $RequiredVersion -eq '0.4.12' }
        }
    }

    Context 'when only another version is installed and the first install fails' {
        BeforeAll {
            Mock Get-Module { [pscustomobject]@{ Name = 'powershell-yaml'; Version = [version]'0.4.7' } } -ParameterFilter { $ListAvailable }
            $script:InstallCalls = 0
            Mock Install-PSResource {
                $script:InstallCalls++
                if ($script:InstallCalls -eq 1) { throw 'transient gallery failure' }
            }
        }

        It 'retries, installs the pinned version, and imports it' {
            Install-PinnedModule -Name 'powershell-yaml' -Version '0.4.12' -MaxAttempts 3 -InitialDelaySeconds 1
            Should -Invoke Install-PSResource -Times 2 -Exactly -ParameterFilter { $Version -eq '0.4.12' }
            Should -Invoke Start-Sleep -Times 1 -Exactly
            Should -Invoke Import-Module -Times 1 -Exactly -ParameterFilter { $RequiredVersion -eq '0.4.12' }
        }
    }

    Context 'when every install attempt fails' {
        BeforeAll {
            Mock Get-Module { } -ParameterFilter { $ListAvailable }
            Mock Install-PSResource { throw 'gallery unavailable' }
        }

        It 'throws after the maximum attempts without importing' {
            { Install-PinnedModule -Name 'powershell-yaml' -Version '0.4.12' -MaxAttempts 3 -InitialDelaySeconds 1 } |
                Should -Throw '*after 3 attempts*'
            Should -Invoke Install-PSResource -Times 3 -Exactly
            Should -Invoke Start-Sleep -Times 2 -Exactly
            Should -Invoke Import-Module -Times 0 -Exactly
        }
    }

    Context 'when the pinned version cannot be imported' {
        BeforeAll {
            Mock Get-Module { [pscustomobject]@{ Name = 'powershell-yaml'; Version = [version]'0.4.12' } } -ParameterFilter { $ListAvailable }
            Mock Import-Module { throw 'version not found' }
        }

        It 'throws an import failure' {
            { Install-PinnedModule -Name 'powershell-yaml' -Version '0.4.12' -MaxAttempts 3 -InitialDelaySeconds 1 } |
                Should -Throw '*Failed to import powershell-yaml 0.4.12*'
        }
    }
}
