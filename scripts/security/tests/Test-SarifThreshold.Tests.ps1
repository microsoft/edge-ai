#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    $script:ScriptPath = (Resolve-Path (Join-Path $PSScriptRoot '../Test-SarifThreshold.ps1')).Path
    . $script:ScriptPath
    $script:SarifRoot = Join-Path $PSScriptRoot 'fixtures/workflow-scans/sarif'

    function script:New-ExceptionsFile {
        param([object[]]$Entries)
        $path = Join-Path $TestDrive ("{0}.json" -f [guid]::NewGuid())
        @{ exceptions = @($Entries) } | ConvertTo-Json -Depth 5 | Set-Content -Path $path -Encoding utf8
        return $path
    }

    function script:Invoke-Gate {
        param([string[]]$Sarif, [string]$Exceptions)
        $argList = @('-NoProfile', '-File', $script:ScriptPath, '-SarifPath') + ($Sarif -join ',') + @('-ExceptionsPath', $Exceptions)
        & pwsh @argList *> $null
        return $LASTEXITCODE
    }

    $script:Pin = @{ tool = 'Test-ActionPinProvenance'; rule = 'action-pin/comment-not-release'; path = '.github/workflows/fuzz.yml'; count = 2; reason = 'Publisher has no vX.Y.Z release.' }
    $script:Mismatch = @{ tool = 'Test-ActionPinProvenance'; rule = 'action-pin/comment-mismatch'; path = '.github/workflows/ci.yml'; count = 1; reason = 'test' }
}

Describe 'Test-SarifThreshold evaluation' -Tag 'Unit' {
    BeforeAll {
        $script:Findings = Read-SarifResult -Path (Join-Path $script:SarifRoot 'findings.sarif')
    }

    It 'normalizes paths so ./ prefixes group with plain paths' {
        @($script:Findings.Results | Where-Object Path -EQ '.github/workflows/fuzz.yml') | Should -HaveCount 2
    }

    It 'passes a valid run with no results' {
        $clean = Read-SarifResult -Path (Join-Path $script:SarifRoot 'clean.sarif')
        (Test-SarifThreshold -Results $clean.Results -AnalyzedTools $clean.Tools -Exceptions @()).Passed | Should -BeTrue
    }

    It 'fails on unexcused results regardless of level or inline suppression' {
        $evaluation = Test-SarifThreshold -Results $script:Findings.Results -AnalyzedTools $script:Findings.Tools -Exceptions @()
        $evaluation.Passed | Should -BeFalse
        $evaluation.Unexcused | Should -HaveCount 2
    }

    It 'excuses a group only when tool, rule, path, and count all match' {
        $exceptions = Read-ScanException -Path (New-ExceptionsFile -Entries @($script:Pin, $script:Mismatch))
        $evaluation = Test-SarifThreshold -Results $script:Findings.Results -AnalyzedTools $script:Findings.Tools -Exceptions $exceptions
        $evaluation.Passed | Should -BeTrue
        $evaluation.Excused | Should -HaveCount 2
    }

    It 'fails when an exception count differs from the group size' {
        $short = $script:Pin.Clone(); $short.count = 1
        $exceptions = Read-ScanException -Path (New-ExceptionsFile -Entries @($short, $script:Mismatch))
        $evaluation = Test-SarifThreshold -Results $script:Findings.Results -AnalyzedTools $script:Findings.Tools -Exceptions $exceptions
        $evaluation.Passed | Should -BeFalse
        $evaluation.Mismatched | Should -HaveCount 1
    }

    It 'fails on a stale exception for an analyzed tool' {
        $stale = $script:Pin.Clone(); $stale.path = '.github/workflows/gone.yml'
        $exceptions = Read-ScanException -Path (New-ExceptionsFile -Entries @($script:Pin, $script:Mismatch, $stale))
        $evaluation = Test-SarifThreshold -Results $script:Findings.Results -AnalyzedTools $script:Findings.Tools -Exceptions $exceptions
        $evaluation.Passed | Should -BeFalse
        $evaluation.Stale | Should -HaveCount 1
    }

    It 'ignores exceptions for tools that did not run' {
        $other = @{ tool = 'Test-WorkflowRunner'; rule = 'workflow-runner/undated-label'; path = '.github/workflows/x.yml'; count = 1; reason = 'test' }
        $exceptions = Read-ScanException -Path (New-ExceptionsFile -Entries @($script:Pin, $script:Mismatch, $other))
        $evaluation = Test-SarifThreshold -Results $script:Findings.Results -AnalyzedTools $script:Findings.Tools -Exceptions $exceptions
        $evaluation.Passed | Should -BeTrue
    }
}

Describe 'Test-SarifThreshold input validation' -Tag 'Unit' {
    It 'rejects <Name>' -ForEach @(
        @{ Name = 'a missing field'; Entry = @{ tool = 't'; rule = 'r'; path = 'p'; count = 1 } }
        @{ Name = 'an unknown field'; Entry = @{ tool = 't'; rule = 'r'; path = 'p'; count = 1; reason = 'x'; expires = '2027-01-01' } }
        @{ Name = 'a zero count'; Entry = @{ tool = 't'; rule = 'r'; path = 'p'; count = 0; reason = 'x' } }
        @{ Name = 'a string count'; Entry = @{ tool = 't'; rule = 'r'; path = 'p'; count = '1'; reason = 'x' } }
        @{ Name = 'an upstream-unavailable exception'; Entry = @{ tool = 'Test-ActionPinProvenance'; rule = 'action-pin/upstream-unavailable'; path = 'p'; count = 1; reason = 'x' } }
    ) {
        { Read-ScanException -Path (New-ExceptionsFile -Entries @($Entry)) } | Should -Throw
    }

    It 'rejects duplicate exceptions for the same group' {
        { Read-ScanException -Path (New-ExceptionsFile -Entries @($script:Pin, $script:Pin)) } | Should -Throw '*Duplicate*'
    }

    It 'rejects <Name> SARIF' -ForEach @(
        @{ Name = 'run-less'; File = 'runless.sarif' }
        @{ Name = 'unreadable'; File = 'unreadable.sarif' }
        @{ Name = 'missing'; File = 'does-not-exist.sarif' }
    ) {
        { Read-SarifResult -Path (Join-Path $script:SarifRoot $File) } | Should -Throw
    }
}

Describe 'Test-SarifThreshold exit codes' -Tag 'Unit' {
    It 'exits <Expected> for <Name>' -ForEach @(
        @{ Name = 'a clean run'; Sarif = 'clean.sarif'; Entries = @(); Expected = 0 }
        @{ Name = 'unexcused results'; Sarif = 'findings.sarif'; Entries = @(); Expected = 1 }
        @{ Name = 'run-less SARIF'; Sarif = 'runless.sarif'; Entries = @(); Expected = 2 }
    ) {
        $exceptions = New-ExceptionsFile -Entries $Entries
        Invoke-Gate -Sarif (Join-Path $script:SarifRoot $Sarif) -Exceptions $exceptions | Should -Be $Expected
    }

    It 'exits 0 when every result is excused' {
        $exceptions = New-ExceptionsFile -Entries @($script:Pin, $script:Mismatch)
        Invoke-Gate -Sarif (Join-Path $script:SarifRoot 'findings.sarif') -Exceptions $exceptions | Should -Be 0
    }

    It 'exits 2 for a malformed exceptions file' {
        $bad = Join-Path $TestDrive 'bad.json'
        Set-Content -Path $bad -Value '{ "items": [] }'
        Invoke-Gate -Sarif (Join-Path $script:SarifRoot 'clean.sarif') -Exceptions $bad | Should -Be 2
    }
}
