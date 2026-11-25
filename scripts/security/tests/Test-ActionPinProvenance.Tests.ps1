#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    . (Join-Path $PSScriptRoot '../Test-ActionPinProvenance.ps1')
    Mock Write-Host {}
    Mock Write-Host {} -ModuleName WorkflowScanHelpers
    Mock Write-Warning {}
    Mock Start-Sleep {}

    $script:FixtureRoot = Join-Path $PSScriptRoot 'fixtures/workflow-scans/provenance'
    $script:A = 'a' * 40
    $script:B = 'b' * 40
    $script:C = 'c' * 40
    $script:D = 'd' * 40
    $script:OctoTags = @(
        "$($script:A)`trefs/tags/v1"
        "$($script:A)`trefs/tags/v1.2.3"
        "$($script:B)`trefs/tags/v2.0.0"
        "$($script:C)`trefs/tags/v2.0.0^{}"
    )
}

Describe 'Get-ActionReference' -Tag 'Unit' {
    BeforeAll {
        $script:References = @(Get-ActionReference -Path (Join-Path $script:FixtureRoot 'pins.yml') -RelativePath '.github/workflows/pins.yml')
    }

    It 'skips local and docker references' {
        $script:References | Where-Object { $_.Target -like './*' -or $_.Target -like 'docker:*' } | Should -BeNullOrEmpty
        $script:References | Should -HaveCount 11
    }

    It 'resolves subpath actions and reusable workflows to their repository' {
        ($script:References | Where-Object Target -EQ 'octo/tool/sub/path').Repository | Should -Be 'octo/tool'
        ($script:References | Where-Object Target -EQ 'octo/tool/.github/workflows/build.yml').Repository | Should -Be 'octo/tool'
    }
}

Describe 'Get-UpstreamTagSet' -Tag 'Unit' {
    It 'maps lightweight tags to commits and peels annotated tags' {
        Mock Invoke-GitLsRemote { $script:OctoTags }
        $set = Get-UpstreamTagSet -Repository 'octo/tool' -MaxAttempts 3 -RetryDelaySeconds 1
        $set.Tags['v1.2.3'] | Should -Be $script:A
        $set.Tags['v2.0.0'] | Should -Be $script:C
        $set.TagObjects[$script:B] | Should -Be 'v2.0.0'
    }

    It 'retries a failed read and then succeeds' {
        $script:Calls = 0
        Mock Invoke-GitLsRemote {
            $script:Calls++
            if ($script:Calls -eq 1) { throw 'transient' }
            $script:OctoTags
        }
        Get-UpstreamTagSet -Repository 'octo/tool' -MaxAttempts 3 -RetryDelaySeconds 1 | Should -Not -BeNullOrEmpty
        Should -Invoke Invoke-GitLsRemote -Times 2 -Exactly
    }

    It 'returns null after 3 failed attempts' {
        Mock Invoke-GitLsRemote { throw 'unavailable' }
        Get-UpstreamTagSet -Repository 'octo/tool' -MaxAttempts 3 -RetryDelaySeconds 1 | Should -BeNullOrEmpty
        Should -Invoke Invoke-GitLsRemote -Times 3 -Exactly
        Should -Invoke Start-Sleep -Times 2 -Exactly
    }
}

Describe 'Invoke-ActionPinProvenanceScan' -Tag 'Unit' {
    BeforeAll {
        Mock Invoke-GitLsRemote { $script:OctoTags } -ParameterFilter { $Repository -eq 'octo/tool' }
        Mock Invoke-GitLsRemote { throw 'repository unavailable' } -ParameterFilter { $Repository -eq 'other/down' }

        $root = Join-Path $TestDrive 'repo'
        New-Item -ItemType Directory -Path (Join-Path $root '.github/workflows'), (Join-Path $root '.github/actions/setup') -Force | Out-Null
        Copy-Item -Path (Join-Path $script:FixtureRoot 'pins.yml') -Destination (Join-Path $root '.github/workflows/pins.yml')
        Copy-Item -Path (Join-Path $script:FixtureRoot 'action.yml') -Destination (Join-Path $root '.github/actions/setup/action.yml')

        $script:Sarif = Join-Path $TestDrive 'provenance.sarif'
        $script:Findings = @(Invoke-ActionPinProvenanceScan -RepoRoot $root -OutputPath $script:Sarif -MaxAttempts 3 -RetryDelaySeconds 1)
        $script:Lines = Get-Content -Path (Join-Path $script:FixtureRoot 'pins.yml')
    }

    It 'reports <Step> as <Rule>' -ForEach @(
        @{ Step = 'Release tag without v'; Rule = 'action-pin/comment-not-release' }
        @{ Step = 'Moving alias that matches'; Rule = 'action-pin/comment-not-release' }
        @{ Step = 'Mismatched release tag'; Rule = 'action-pin/comment-mismatch' }
        @{ Step = 'Missing comment'; Rule = 'action-pin/comment-missing' }
        @{ Step = 'Annotated tag object'; Rule = 'action-pin/tag-object' }
        @{ Step = 'Untagged commit'; Rule = 'action-pin/untagged-commit' }
        @{ Step = 'Unpinned ref'; Rule = 'action-pin/not-sha-pinned' }
        @{ Step = 'Unreadable upstream'; Rule = 'action-pin/upstream-unavailable' }
    ) {
        $usesLine = [array]::IndexOf($script:Lines, ($script:Lines | Where-Object { $_.Trim() -eq "- name: $Step" })) + 2
        $finding = @($script:Findings | Where-Object { $_.Path -eq '.github/workflows/pins.yml' -and $_.Line -eq $usesLine })
        $finding | Should -HaveCount 1
        $finding[0].RuleId | Should -Be $Rule
    }

    It 'passes exact tags, peeled annotated tags, subpaths, and reusable workflows' {
        @($script:Findings | Where-Object Path -EQ '.github/workflows/pins.yml') | Should -HaveCount 8
    }

    It 'scans composite actions' {
        $finding = @($script:Findings | Where-Object Path -EQ '.github/actions/setup/action.yml')
        $finding | Should -HaveCount 1
        $finding[0].RuleId | Should -Be 'action-pin/comment-mismatch'
    }

    It 'reads each repository once' {
        Should -Invoke Invoke-GitLsRemote -Times 1 -Exactly -Scope Describe -ParameterFilter { $Repository -eq 'octo/tool' }
    }

    It 'writes SARIF with the provenance tool name' {
        $sarif = Get-Content -Path $script:Sarif -Raw | ConvertFrom-Json
        $sarif.runs[0].tool.driver.name | Should -Be 'Test-ActionPinProvenance'
        @($sarif.runs[0].results) | Should -HaveCount 9
    }
}
