#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    $script:ScriptPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath '../Test-WorkflowPermissions.ps1')).Path

    function script:Invoke-PermCheck {
        param(
            [Parameter(Mandatory)] [hashtable] $Files,
            [switch] $RequireDenyAll
        )
        $dir = Join-Path $TestDrive ([guid]::NewGuid().ToString())
        New-Item -ItemType Directory -Path $dir -Force | Out-Null
        foreach ($name in $Files.Keys) {
            Set-Content -Path (Join-Path $dir $name) -Value $Files[$name] -NoNewline -Encoding utf8
        }
        $jsonOut = Join-Path $TestDrive ("{0}.json" -f ([guid]::NewGuid()))
        $argList = @('-NoProfile', '-File', $script:ScriptPath, '-Path', $dir, '-OutputPath', $jsonOut, '-Format', 'json')
        if ($RequireDenyAll) { $argList += '-RequireDenyAll' }
        & pwsh @argList *> $null
        if (-not (Test-Path $jsonOut)) {
            throw "Script did not produce output at $jsonOut"
        }
        return (Get-Content -Path $jsonOut -Raw | ConvertFrom-Json)
    }

    function script:Get-ViolationsByType {
        param($Report, [string] $Type)
        if ($null -eq $Report.Violations) { return @() }
        return @($Report.Violations | Where-Object { $_.ViolationType -eq $Type })
    }
}

Describe 'Test-WorkflowPermissions.ps1 -RequireDenyAll' -Tag 'Unit' {

    Context 'when -RequireDenyAll is OFF (default)' {
        It 'does not flag inline read permissions' {
            $yaml = @"
name: ci
on: push
permissions:
  contents: read
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hi
"@
            $report = Invoke-PermCheck -Files @{ 'wf.yml' = $yaml }
            (Get-ViolationsByType -Report $report -Type 'NonDenyAllPermissions').Count | Should -Be 0
        }
    }

    Context 'when -RequireDenyAll is ON' {
        It 'passes for permissions: {}' {
            $yaml = @"
name: ci
on: push
permissions: {}
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hi
"@
            $report = Invoke-PermCheck -Files @{ 'wf.yml' = $yaml } -RequireDenyAll
            (Get-ViolationsByType -Report $report -Type 'NonDenyAllPermissions').Count | Should -Be 0
            (Get-ViolationsByType -Report $report -Type 'MissingPermissions').Count | Should -Be 0
        }

        It 'flags inline { contents: read }' {
            $yaml = @"
name: ci
on: push
permissions: { contents: read }
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hi
"@
            $report = Invoke-PermCheck -Files @{ 'wf.yml' = $yaml } -RequireDenyAll
            (Get-ViolationsByType -Report $report -Type 'NonDenyAllPermissions').Count | Should -Be 1
        }

        It 'flags block-style mapping with contents: read' {
            $yaml = @"
name: ci
on: push
permissions:
  contents: read
  issues: none
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hi
"@
            $report = Invoke-PermCheck -Files @{ 'wf.yml' = $yaml } -RequireDenyAll
            (Get-ViolationsByType -Report $report -Type 'NonDenyAllPermissions').Count | Should -Be 1
        }

        It 'passes for block-style mapping where every value is none' {
            $yaml = @"
name: ci
on: push
permissions:
  contents: none
  issues: none
  pull-requests: none
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hi
"@
            $report = Invoke-PermCheck -Files @{ 'wf.yml' = $yaml } -RequireDenyAll
            (Get-ViolationsByType -Report $report -Type 'NonDenyAllPermissions').Count | Should -Be 0
            (Get-ViolationsByType -Report $report -Type 'MissingPermissions').Count | Should -Be 0
        }

        It 'ignores job-scoped permissions when no top-level permissions exist' {
            $yaml = @"
name: ci
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    permissions:
      contents: read
    steps:
      - run: echo hi
"@
            $report = Invoke-PermCheck -Files @{ 'wf.yml' = $yaml } -RequireDenyAll
            (Get-ViolationsByType -Report $report -Type 'NonDenyAllPermissions').Count | Should -Be 0
        }

        It 'still flags workflows missing permissions entirely' {
            $yaml = @"
name: ci
on: push
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - run: echo hi
"@
            $report = Invoke-PermCheck -Files @{ 'wf.yml' = $yaml } -RequireDenyAll
            (Get-ViolationsByType -Report $report -Type 'MissingPermissions').Count | Should -Be 1
        }
    }
}
