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

    $FrontmatterPath = Join-Path $script:RepoRoot 'scripts/Validate-MarkdownFrontmatter.ps1'
    $FrontmatterTokens = $null
    $FrontmatterErrors = $null
    $FrontmatterAst = [System.Management.Automation.Language.Parser]::ParseFile(
        $FrontmatterPath, [ref]$FrontmatterTokens, [ref]$FrontmatterErrors)
    $FrontmatterFunction = $FrontmatterAst.FindAll(
        {
            param($Node)
            $Node -is [System.Management.Automation.Language.FunctionDefinitionAst] -and
            $Node.Name -eq 'Resolve-FrontmatterValidationSelection'
        },
        $true)
    . ([scriptblock]::Create($FrontmatterFunction.Extent.Text))

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

    It 'returns full validation when the pull-request source head is <Scenario>' -ForEach @(
        @{ Scenario = 'missing'; PullRequestHeadSha = '' }
        @{ Scenario = 'whitespace'; PullRequestHeadSha = '   ' }
    ) {
        $Result = Resolve-ValidationRange `
            -EventName 'pull_request' `
            -ExpectedHeadSha 'merge-sha' `
            -CheckedOutHeadSha 'merge-sha' `
            -PullRequestBaseSha 'base-sha' `
            -PullRequestHeadSha $PullRequestHeadSha

        $Result.Mode | Should -Be 'full'
        $Result.BaseSha | Should -BeNullOrEmpty
        $Result.HeadSha | Should -Be 'merge-sha'
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

Describe 'Resolve-ValidationRange entry point' -Tag 'Unit' {
    It 'exits successfully after emitting a changed range contract' {
        $OutputFile = Join-Path $TestDrive 'range-output.txt'
        $HeadSha = (& git -C $script:RepoRoot rev-parse HEAD).Trim()
        $BaseSha = (& git -C $script:RepoRoot rev-parse HEAD^).Trim()

        & pwsh -NoProfile -File $ResolverPath `
            -EventName merge_group `
            -ExpectedHeadSha $HeadSha `
            -MergeGroupBaseSha $BaseSha `
            -MergeGroupHeadSha $HeadSha `
            -OutputFile $OutputFile

        $LASTEXITCODE | Should -Be 0
        Get-Content -Path $OutputFile -Raw | Should -Match '(?m)^mode=range\r?$'
    }

    It 'exits successfully after emitting a full fallback contract' {
        $OutputFile = Join-Path $TestDrive 'full-output.txt'
        $HeadSha = (& git -C $script:RepoRoot rev-parse HEAD).Trim()

        & pwsh -NoProfile -File $ResolverPath `
            -EventName merge_group `
            -ExpectedHeadSha $HeadSha `
            -MergeGroupBaseSha ('0' * 40) `
            -MergeGroupHeadSha $HeadSha `
            -OutputFile $OutputFile

        $LASTEXITCODE | Should -Be 0
        Get-Content -Path $OutputFile -Raw | Should -Match '(?m)^mode=full\r?$'
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

    It 'passes the resolver contract to documentation validation' {
        $DocsJob = Get-WorkflowJobBlock -Workflow $script:AggregateWorkflow -JobName 'docs-automation'
        $DocsWorkflow = Get-Content -Path (
            Join-Path $script:RepoRoot '.github/workflows/docs-automation.yml') -Raw

        $DocsJob | Should -Match 'needs: \[resolve-validation-range\]'
        $DocsJob | Should -Match 'changeMode: \$\{\{ needs\.resolve-validation-range\.outputs\.mode \}\}'
        $DocsJob | Should -Match 'baseSha: \$\{\{ needs\.resolve-validation-range\.outputs\.base-sha \}\}'
        $DocsJob | Should -Match 'headSha: \$\{\{ needs\.resolve-validation-range\.outputs\.head-sha \}\}'
        $DocsWorkflow | Should -Match "CHANGE_MODE: \$\{\{ inputs\.changeMode \|\| 'branch' \}\}"
        $DocsWorkflow | Should -Match '\$env:CHANGE_MODE -eq ''full'''
        $DocsWorkflow | Should -Match '\$env:CHANGE_MODE -eq ''range'''
        $DocsWorkflow | Should -Match '\$frontmatterArgs\[''ChangeMode''\]'
        $DocsWorkflow | Should -Match '\$frontmatterArgs\[''BaseSha''\]'
        $DocsWorkflow | Should -Match '\$frontmatterArgs\[''HeadSha''\]'
    }

    It 'selects all configured paths for documentation full fallback' {
        $Selection = Resolve-FrontmatterValidationSelection `
            -ChangeMode full `
            -Paths @('docs', 'src', 'blueprints') `
            -BaseBranch 'origin/moving-base' `
            -BaseSha 'unused-base' `
            -HeadSha 'unused-head'

        $Selection.Skip | Should -BeFalse
        $Selection.Parameters.Paths | Should -Be @('docs', 'src', 'blueprints')
        $Selection.Parameters.ContainsKey('ChangedFilesOnly') | Should -BeFalse
        $Selection.Parameters.ContainsKey('BaseBranch') | Should -BeFalse
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

    It 'uses read-only reusable workflows for merge-group Rust and fuzz validation' {
        $RustJob = Get-WorkflowJobBlock -Workflow $script:AggregateWorkflow -JobName 'rust-tests-merge-group'
        $FuzzJob = Get-WorkflowJobBlock -Workflow $script:AggregateWorkflow -JobName 'fuzz-merge-group'
        $RustWorkflow = Get-Content -Path (
            Join-Path $script:RepoRoot '.github/workflows/rust-tests-read-only.yml') -Raw
        $FuzzWorkflow = Get-Content -Path (
            Join-Path $script:RepoRoot '.github/workflows/fuzz-pr-read-only.yml') -Raw

        $RustJob | Should -Match 'uses: \./\.github/workflows/rust-tests-read-only\.yml'
        $FuzzJob | Should -Match 'uses: \./\.github/workflows/fuzz-pr-read-only\.yml'
        $FuzzJob | Should -Match '(?ms)permissions:\r?\n      contents: read\r?\n      actions: read'
        $RustWorkflow | Should -Not -Match '(?m)^\s+(id-token|packages|security-events|attestations): write\r?$'
        $FuzzWorkflow | Should -Not -Match '(?m)^\s+(id-token|packages|security-events|attestations): write\r?$'
    }

    It 'keeps application validation read only' {
        $ApplicationJob = Get-WorkflowJobBlock `
            -Workflow $script:AggregateWorkflow `
            -JobName 'application-matrix-builds'
        $ApplicationWorkflow = Get-Content -Path (
            Join-Path $script:RepoRoot '.github/workflows/application-matrix-builds.yml') -Raw

        $ApplicationJob | Should -Match '(?ms)permissions:\r?\n      contents: read'
        $ApplicationJob | Should -Not -Match '(?m)^\s+(id-token|packages|security-events|attestations): write\r?$'
        $ApplicationWorkflow | Should -Not -Match '(?m)^\s+(id-token|packages|security-events|attestations): write\r?$'
        $ApplicationWorkflow | Should -Not -Match 'github/codeql-action/upload-sarif@'
    }

    It 'includes permission enforcement in the required aggregate gate' {
        $GateJob = Get-WorkflowJobBlock -Workflow $script:AggregateWorkflow -JobName 'pr-validation-gate'

        $GateJob | Should -Match '(?m)^      - permissions-scan\r?$'
    }

    It 'disables persisted checkout credentials in trust-boundary workflows' -ForEach @(
        '.github/workflows/pr-validation.yml'
        '.github/workflows/rust-tests.yml'
        '.github/workflows/rust-tests-read-only.yml'
        '.github/workflows/fuzz-pr.yml'
        '.github/workflows/fuzz-pr-read-only.yml'
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
