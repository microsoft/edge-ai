# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

# Regression tests for issue #362: Security Gate Naming Mismatch.
# Verifies the writer contract in Invoke-GrypeScan so generated report
# basenames match the 'grype-*.json' glob enforced by the gate reader.

BeforeAll {
    $script:SutPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '../Invoke-ContainerSecurityScan.ps1')).Path

    # Load only function definitions to avoid executing the top-level Main
    # invocation at end-of-file.
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

Describe 'Invoke-GrypeScan filename contract (issue #362)' -Tag 'Unit' {

    It 'prefixes report basenames with grype- and sanitizes / and : separators' {
        $result = Invoke-GrypeScan `
            -FullImageName 'reg.example.io/mqtt-tools/edge-mqtt-broker:1.0' `
            -ImageName    'mqtt-tools/edge-mqtt-broker' `
            -ImageTag     '1.0' `
            -OutputPath   $TestDrive `
            -DryRun

        $result.success | Should -BeTrue

        $jsonLeaf  = Split-Path $result.jsonReport  -Leaf
        $sarifLeaf = Split-Path $result.sarifReport -Leaf
        $tableLeaf = Split-Path $result.tableReport -Leaf

        $pattern = '^grype-mqtt-tools_edge-mqtt-broker-1\.0-\d{8}-\d{6}'
        $jsonLeaf  | Should -Match ($pattern + '\.json$')
        $sarifLeaf | Should -Match ($pattern + '\.sarif$')
        $tableLeaf | Should -Match ($pattern + '\.txt$')
    }

    It 'sanitizes colon characters in image tags' {
        $result = Invoke-GrypeScan `
            -FullImageName 'svc:port/img:tag' `
            -ImageName    'svc:port/img' `
            -ImageTag     'tag:weird' `
            -OutputPath   $TestDrive `
            -DryRun

        $jsonLeaf = Split-Path $result.jsonReport -Leaf
        $jsonLeaf | Should -Match '^grype-svc_port_img-tag_weird-\d{8}-\d{6}\.json$'
    }
}
