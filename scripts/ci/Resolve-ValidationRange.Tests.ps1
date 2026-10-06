#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    $ResolverPath = (Resolve-Path (Join-Path $PSScriptRoot 'Resolve-ValidationRange.ps1')).Path
    $Tokens = $null
    $Errors = $null
    $Ast = [System.Management.Automation.Language.Parser]::ParseFile(
        $ResolverPath, [ref]$Tokens, [ref]$Errors)
    $FunctionDefinitions = $Ast.FindAll(
        { param($Node) $Node -is [System.Management.Automation.Language.FunctionDefinitionAst] },
        $true)
    $FunctionScript = ($FunctionDefinitions | ForEach-Object { $_.Extent.Text }) -join "`n"
    . ([scriptblock]::Create($FunctionScript))

    $script:RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
    $script:AggregateWorkflowPath = Join-Path $script:RepoRoot '.github/workflows/pr-validation.yml'
    $script:AggregateWorkflow = Get-Content -Path $script:AggregateWorkflowPath -Raw

    function Get-WorkflowJobBlock {
        <#
        .SYNOPSIS
            Returns one job block from a workflow document.
        .OUTPUTS
            System.String
        #>
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Workflow,

            [Parameter(Mandatory = $true)]
            [string]$JobName
        )

        $EscapedJobName = [regex]::Escape($JobName)
        $Match = [regex]::Match(
            $Workflow,
            "(?ms)^  ${EscapedJobName}:\r?\n.*?(?=^  [A-Za-z0-9_-]+:\r?$|\z)"
        )
        return $Match.Value
    }
}

Describe 'Resolve-ValidationRange' -Tag 'Unit' {
    BeforeEach {
        Mock Test-GitCommit { $true }
        Mock Test-GitAncestor { $true }
        Mock Test-GitDiffable { $true }
    }

    It 'returns a range for a proven pull-request merge revision' {
        $Result = Resolve-ValidationRange `
            -EventName 'pull_request' `
            -ExpectedHeadSha 'merge-sha' `
            -CheckedOutHeadSha 'merge-sha' `
            -PullRequestBaseSha 'base-sha' `
            -PullRequestHeadSha 'pr-head-sha'

        $Result.Mode | Should -Be 'range'
        $Result.BaseSha | Should -Be 'base-sha'
        $Result.HeadSha | Should -Be 'merge-sha'
    }

    It 'returns a range for a proven merge-group revision' {
        $Result = Resolve-ValidationRange `
            -EventName 'merge_group' `
            -ExpectedHeadSha 'group-sha' `
            -CheckedOutHeadSha 'group-sha' `
            -MergeGroupBaseSha 'base-sha' `
            -MergeGroupHeadSha 'group-sha'

        $Result.Mode | Should -Be 'range'
        $Result.BaseSha | Should -Be 'base-sha'
        $Result.HeadSha | Should -Be 'group-sha'
    }

    It 'returns full validation for <Scenario>' -ForEach @(
        @{
            Scenario = 'a missing base'
            Parameters = @{ EventName = 'merge_group'; MergeGroupBaseSha = ''; MergeGroupHeadSha = 'group-sha' }
        }
        @{
            Scenario = 'equal base and head commits'
            Parameters = @{ EventName = 'merge_group'; MergeGroupBaseSha = 'group-sha'; MergeGroupHeadSha = 'group-sha' }
        }
        @{
            Scenario = 'a payload head mismatch'
            Parameters = @{ EventName = 'merge_group'; MergeGroupBaseSha = 'base-sha'; MergeGroupHeadSha = 'other-sha' }
        }
        @{
            Scenario = 'an unsupported event'
            Parameters = @{ EventName = 'schedule' }
        }
    ) {
        $InvocationParameters = @{
            ExpectedHeadSha   = 'group-sha'
            CheckedOutHeadSha = 'group-sha'
        }
        $Parameters.GetEnumerator() | ForEach-Object {
            $InvocationParameters[$_.Key] = $_.Value
        }

        $Result = Resolve-ValidationRange @InvocationParameters

        $Result.Mode | Should -Be 'full'
        $Result.BaseSha | Should -BeNullOrEmpty
        $Result.HeadSha | Should -Be 'group-sha'
    }

    It 'returns full validation when a commit is malformed or unavailable' {
        Mock Test-GitCommit { $false }

        $Result = Resolve-ValidationRange `
            -EventName 'merge_group' `
            -ExpectedHeadSha 'group-sha' `
            -CheckedOutHeadSha 'group-sha' `
            -MergeGroupBaseSha 'malformed' `
            -MergeGroupHeadSha 'group-sha'

        $Result.Mode | Should -Be 'full'
    }

    It 'returns full validation when the base is not an ancestor' {
        Mock Test-GitAncestor { $false }

        $Result = Resolve-ValidationRange `
            -EventName 'merge_group' `
            -ExpectedHeadSha 'group-sha' `
            -CheckedOutHeadSha 'group-sha' `
            -MergeGroupBaseSha 'base-sha' `
            -MergeGroupHeadSha 'group-sha'

        $Result.Mode | Should -Be 'full'
    }

    It 'returns full validation when the commits are not diffable' {
        Mock Test-GitDiffable { $false }

        $Result = Resolve-ValidationRange `
            -EventName 'merge_group' `
            -ExpectedHeadSha 'group-sha' `
            -CheckedOutHeadSha 'group-sha' `
            -MergeGroupBaseSha 'base-sha' `
            -MergeGroupHeadSha 'group-sha'

        $Result.Mode | Should -Be 'full'
    }

    It 'fails when the checked-out revision differs from the event revision' {
        {
            Resolve-ValidationRange `
                -EventName 'merge_group' `
                -ExpectedHeadSha 'event-sha' `
                -CheckedOutHeadSha 'checkout-sha' `
                -MergeGroupBaseSha 'base-sha' `
                -MergeGroupHeadSha 'event-sha'
        } | Should -Throw '*does not match event SHA*'
    }

    It 'propagates Git infrastructure failures' {
        Mock Test-GitAncestor { throw 'Git ancestry failure' }

        {
            Resolve-ValidationRange `
                -EventName 'merge_group' `
                -ExpectedHeadSha 'group-sha' `
                -CheckedOutHeadSha 'group-sha' `
                -MergeGroupBaseSha 'base-sha' `
                -MergeGroupHeadSha 'group-sha'
        } | Should -Throw '*Git ancestry failure*'
    }
}

Describe 'PR validation merge-group contract' -Tag 'Unit' {
    It 'retains the merge-group trigger for main' {
        $script:AggregateWorkflow | Should -Match '(?ms)^  merge_group:\r?\n    branches:\r?\n      - main\r?\n    types: \[checks_requested\]'
    }

    It 'checks out and resolves the immutable event revision' {
        $ResolverJob = Get-WorkflowJobBlock -Workflow $script:AggregateWorkflow -JobName 'resolve-validation-range'

        $ResolverJob | Should -Match 'ref: \$\{\{ github\.sha \}\}'
        $ResolverJob | Should -Match 'fetch-depth: 0'
        $ResolverJob | Should -Match 'persist-credentials: false'
        $ResolverJob | Should -Match 'Resolve-ValidationRange\.ps1'
    }

    It 'passes the resolver contract to matrix discovery' {
        $MatrixJob = Get-WorkflowJobBlock -Workflow $script:AggregateWorkflow -JobName 'matrix-changes'

        $MatrixJob | Should -Match 'changeMode: \$\{\{ needs\.resolve-validation-range\.outputs\.mode \}\}'
        $MatrixJob | Should -Match 'baseSha: \$\{\{ needs\.resolve-validation-range\.outputs\.base-sha \}\}'
        $MatrixJob | Should -Match 'headSha: \$\{\{ needs\.resolve-validation-range\.outputs\.head-sha \}\}'
    }

    It 'keeps credentialed jobs outside merge-group execution' -ForEach @(
        'dependency-scan'
        'rust-clippy'
        'rust-tests'
        'fuzz'
        'terraform-module-tests'
    ) {
        $Job = Get-WorkflowJobBlock -Workflow $script:AggregateWorkflow -JobName $_

        $Job | Should -Match "if: .*github\.event_name != 'merge_group'"
    }

    It 'keeps merge-group Rust and fuzz callers credential free' -ForEach @(
        'rust-clippy-merge-group'
        'rust-tests-merge-group'
        'fuzz-merge-group'
    ) {
        $Job = Get-WorkflowJobBlock -Workflow $script:AggregateWorkflow -JobName $_

        $Job | Should -Match "if: .*github\.event_name == 'merge_group'"
        $Job | Should -Match '(?ms)permissions:\r?\n      contents: read'
        $Job | Should -Not -Match 'secrets:'
        $Job | Should -Not -Match 'id-token:'
        $Job | Should -Not -Match 'packages:'
    }

    It 'includes permission enforcement in the required aggregate gate' {
        $GateJob = Get-WorkflowJobBlock -Workflow $script:AggregateWorkflow -JobName 'pr-validation-gate'

        $GateJob | Should -Match '(?m)^      - permissions-scan$'
    }

    It 'disables persisted checkout credentials in trust-boundary workflows' -ForEach @(
        '.github/workflows/pr-validation.yml'
        '.github/workflows/rust-tests.yml'
        '.github/workflows/fuzz-pr.yml'
        '.github/workflows/docs-automation.yml'
        '.github/workflows/docs-check-terraform.yml'
        '.github/workflows/docs-check-bicep.yml'
        '.github/workflows/aio-version-checker.yml'
        '.github/workflows/resource-provider-pwsh-tests.yml'
        '.github/workflows/application-matrix-builds.yml'
        '.github/workflows/matrix-folder-check.yml'
        '.github/workflows/rust-clippy.yml'
        '.github/workflows/dep-audit.yml'
        '.github/workflows/variable-compliance-terraform.yml'
    ) {
        $Workflow = Get-Content -Path (Join-Path $script:RepoRoot $_) -Raw
        $CheckoutBlocks = [regex]::Matches(
            $Workflow,
            '(?ms)^\s+- name:.*?\r?\n\s+uses: actions/checkout@.*?(?=^\s+- name:|\z)'
        )

        foreach ($CheckoutBlock in $CheckoutBlocks) {
            $CheckoutBlock.Value | Should -Match 'persist-credentials: false'
        }
    }
}
