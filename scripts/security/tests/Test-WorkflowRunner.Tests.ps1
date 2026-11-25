#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    $script:ScriptPath = (Resolve-Path (Join-Path $PSScriptRoot '../Test-WorkflowRunner.ps1')).Path
    . $script:ScriptPath
    Mock Write-Host {}
    Mock Write-Host {} -ModuleName WorkflowScanHelpers
    $script:FixtureRoot = Join-Path $PSScriptRoot 'fixtures/workflow-scans/runner'

    function script:New-FixtureRepo {
        param([string[]]$Fixture, [string]$ExtraContent)
        $root = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        $workflows = Join-Path $root '.github/workflows'
        New-Item -ItemType Directory -Path $workflows -Force | Out-Null
        foreach ($name in $Fixture) {
            Copy-Item -Path (Join-Path $script:FixtureRoot $name) -Destination $workflows
        }
        if ($ExtraContent) {
            Set-Content -Path (Join-Path $workflows 'extra.yml') -Value $ExtraContent
        }
        return $root
    }

    function script:Invoke-Scanner {
        param([string]$Root)
        $sarif = Join-Path $TestDrive ("{0}.sarif" -f [guid]::NewGuid())
        & pwsh -NoProfile -File $script:ScriptPath -RepoRoot $Root -OutputPath $sarif *> $null
        return [pscustomobject]@{ ExitCode = $LASTEXITCODE; Sarif = $sarif }
    }
}

Describe 'Get-WorkflowRunnerFinding' -Tag 'Unit' {
    BeforeAll {
        $path = Join-Path $script:FixtureRoot 'runners.yml'
        $script:Findings = @(Get-WorkflowRunnerFinding -Path $path -RelativePath '.github/workflows/runners.yml')
        $script:Lines = Get-Content -Path $path
    }

    It 'reports the <Job> job at its runs-on line' -ForEach @(
        @{ Job = 'floating'; Text = 'runs-on: ubuntu-latest' }
        @{ Job = 'windows'; Text = 'runs-on: windows-latest' }
        @{ Job = 'self-hosted'; Text = 'runs-on: [self-hosted, linux]' }
        @{ Job = 'expression'; Text = 'runs-on: ${{ matrix.os }}' }
    ) {
        $finding = $script:Findings | Where-Object { $_.Message -like "Job '$Job' *" }
        $finding | Should -HaveCount 1
        $script:Lines[$finding.Line - 1].Trim() | Should -Be $Text
    }

    It 'reports a job without runs-on at its key line' {
        $finding = $script:Findings | Where-Object { $_.Message -like "Job 'missing' *" }
        $script:Lines[$finding.Line - 1].Trim() | Should -Be 'missing:'
    }

    It 'does not report dated labels or reusable workflow calls' {
        $script:Findings | Should -HaveCount 5
        foreach ($job in 'dated', 'dated-arm', 'reusable') {
            $script:Findings | Where-Object { $_.Message -like "Job '$job' *" } | Should -BeNullOrEmpty
        }
    }
}

Describe 'Test-WorkflowRunner.ps1 exit codes and SARIF' -Tag 'Unit' {
    It 'exits 0 and writes an empty run when every job is dated' {
        $result = Invoke-Scanner -Root (New-FixtureRepo -Fixture 'dated.yml')
        $result.ExitCode | Should -Be 0
        $sarif = Get-Content -Path $result.Sarif -Raw | ConvertFrom-Json
        $sarif.runs[0].tool.driver.name | Should -Be 'Test-WorkflowRunner'
        @($sarif.runs[0].results) | Should -HaveCount 0
    }

    It 'exits 1 and writes repository-relative locations for findings' {
        $result = Invoke-Scanner -Root (New-FixtureRepo -Fixture 'runners.yml', 'dated.yml')
        $result.ExitCode | Should -Be 1
        $results = (Get-Content -Path $result.Sarif -Raw | ConvertFrom-Json).runs[0].results
        $results | Should -HaveCount 5
        $results[0].ruleId | Should -Be 'workflow-runner/undated-label'
        $results[0].locations[0].physicalLocation.artifactLocation.uri | Should -Be '.github/workflows/runners.yml'
    }

    It 'exits 2 when a workflow cannot be parsed' {
        $result = Invoke-Scanner -Root (New-FixtureRepo -Fixture 'dated.yml' -ExtraContent "jobs:`n  bad: [unclosed")
        $result.ExitCode | Should -Be 2
    }
}
