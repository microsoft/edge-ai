# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

# Regression tests for issue #362: Security Gate Naming Mismatch.
# Verifies the fail-closed reader contract in Get-GrypeScanResult so missing
# grype-*.json reports cause the gate to throw rather than silently pass.

BeforeAll {
    $script:SutPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '../Invoke-SecurityGate.ps1')).Path

    # Load only function definitions from the SUT to avoid executing the
    # unguarded top-level Main invocation at end-of-file.
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

Describe 'Get-GrypeScanResult fail-closed contract (issue #362)' -Tag 'Unit' {

    It 'throws when no grype-*.json reports exist under ResultsPath' {
        $emptyDir = Join-Path $TestDrive 'empty-results'
        New-Item -ItemType Directory -Path $emptyDir -Force | Out-Null

        { Get-GrypeScanResult -ResultsPath $emptyDir } |
            Should -Throw -ExpectedMessage '*no grype-*.json reports discovered*Refusing to pass*'
    }

    It 'throws when only non-grype JSON files exist' {
        $dir = Join-Path $TestDrive 'wrong-prefix'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        '{"matches":[]}' | Set-Content -Path (Join-Path $dir 'scan-output.json')
        '{}'             | Set-Content -Path (Join-Path $dir 'results-2026.json')

        { Get-GrypeScanResult -ResultsPath $dir } |
            Should -Throw -ExpectedMessage '*no grype-*.json reports discovered*'
    }

    It 'discovers grype-*.json nested in per-service subdirectories' {
        $root = Join-Path $TestDrive 'nested-results'
        $svc  = Join-Path $root 'svcA'
        New-Item -ItemType Directory -Path $svc -Force | Out-Null
        '{"matches":[]}' |
            Set-Content -Path (Join-Path $svc 'grype-svcA-1.0-20260101-000000.json')

        { Get-GrypeScanResult -ResultsPath $root } | Should -Not -Throw
    }

    It 'parses grype matches into vulnerability records with expected fields' {
        $dir = Join-Path $TestDrive 'with-findings'
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        $payload = @{
            matches = @(
                @{
                    vulnerability = @{
                        id          = 'CVE-2026-0001'
                        severity    = 'High'
                        description = 'example'
                        fix         = @{ versions = @('1.2.4') }
                    }
                    artifact = @{
                        name    = 'libexample'
                        version = '1.2.3'
                        type    = 'deb'
                    }
                }
            )
        } | ConvertTo-Json -Depth 6
        $payload | Set-Content -Path (Join-Path $dir 'grype-img-tag-20260101-000000.json')

        $result = @(Get-GrypeScanResult -ResultsPath $dir)
        $result.Count              | Should -Be 1
        $result[0].Type            | Should -Be 'Vulnerability'
        $result[0].Source          | Should -Be 'Grype'
        $result[0].VulnerabilityId | Should -Be 'CVE-2026-0001'
        $result[0].Severity        | Should -Be 'High'
        $result[0].PackageName     | Should -Be 'libexample'
        $result[0].Target          | Should -Be 'deb'
    }
}
