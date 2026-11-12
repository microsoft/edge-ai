#Requires -Modules Pester, powershell-yaml
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    Import-Module (Join-Path $PSScriptRoot 'modules/ApplicationBuilder.Helpers.psm1') -Force
    Import-Module (Join-Path $PSScriptRoot 'modules/ApplicationBuilder.Build.psm1') -Force
    $script:RepoRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../..'))
}

Describe 'Camera dashboard explicit build context' -Tag 'Unit' {
    BeforeEach {
        $script:Context = New-BuildContext `
            -AppPath (Join-Path $script:RepoRoot 'src/500-application/510-onvif-connector') `
            -AppName 'onvif-connector' -BuildId 'camera-test' -BuildEnv 'dev' -CommitSha '0123456'
        Get-ApplicationStructure -Context $script:Context
        $script:Dashboard = @($script:Context.Compose.ServiceMetadata |
                Where-Object Name -EQ 'camera-dashboard')
    }

    It 'reads the repository-root context and explicit Dockerfile from Compose' {
        $script:Dashboard | Should -HaveCount 1
        $script:Dashboard[0].BuildContextPath | Should -Be $script:RepoRoot
        $script:Dashboard[0].Dockerfile | Should -Be 'src/500-application/510-onvif-connector/services/camera-dashboard/Dockerfile'
    }

    It 'passes that context and Dockerfile through the generic docker build fallback' {
        Mock docker -ModuleName ApplicationBuilder.Build {
            $global:LASTEXITCODE = 0
        }

        Build-ServicesWithoutCompose -Context $script:Context -Services $script:Dashboard

        $script:Context.Build.Failed | Should -HaveCount 0
        $script:Context.Build.Successful | Should -Contain 'camera-dashboard'
        Should -Invoke docker -ModuleName ApplicationBuilder.Build -Times 1 -Exactly -ParameterFilter {
            $args[0] -eq 'build' -and
            $args[-1] -eq $script:RepoRoot -and
            $args[-3] -eq '-f' -and
            $args[-2] -eq (Join-Path $script:RepoRoot 'src/500-application/510-onvif-connector/services/camera-dashboard/Dockerfile')
        }
    }
}
