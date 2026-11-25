#Requires -Modules Pester
# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    $script:ScriptPath = (Resolve-Path (Join-Path $PSScriptRoot '../Test-DangerousWorkflow.ps1')).Path
    . $script:ScriptPath
    Mock Write-Host {}
    Mock Write-Host {} -ModuleName WorkflowScanHelpers
    $script:FixturePath = Join-Path $PSScriptRoot 'fixtures/workflow-scans/dangerous/injection.yml'
}

Describe 'Get-DangerousWorkflowFinding' -Tag 'Unit' {
    BeforeAll {
        $script:Findings = @(Get-DangerousWorkflowFinding -Path $script:FixturePath -RelativePath '.github/workflows/injection.yml')
        $script:Lines = Get-Content -Path $script:FixturePath
    }

    It 'reports <Expression> as <Rule> on its own line' -ForEach @(
        @{ Expression = 'inputs.name'; Rule = 'dangerous-workflow/input-interpolation'; Text = 'run: echo "${{ inputs.name }}"' }
        @{ Expression = 'inputs.count'; Rule = 'dangerous-workflow/input-interpolation'; Text = 'echo "${{ inputs.count }}"' }
        @{ Expression = 'github.event.inputs.mode'; Rule = 'dangerous-workflow/input-interpolation'; Text = 'run: echo "${{ github.event.inputs.mode }}"' }
        @{ Expression = 'pull_request.title'; Rule = 'dangerous-workflow/untrusted-event-interpolation'; Text = 'run: echo "${{ github.event.pull_request.title }}"' }
        @{ Expression = 'inputs.unknown'; Rule = 'dangerous-workflow/input-interpolation'; Text = 'run: echo "${{ inputs.unknown }}"' }
        @{ Expression = 'toJSON(inputs)'; Rule = 'dangerous-workflow/input-interpolation'; Text = "run: echo '`${{ toJSON(inputs) }}'" }
        @{ Expression = 'const name'; Rule = 'dangerous-workflow/input-interpolation'; Text = 'const name = "${{ inputs.name }}";' }
    ) {
        $matching = @($script:Findings | Where-Object { $_.RuleId -eq $Rule -and $script:Lines[$_.Line - 1].Trim() -eq $Text })
        $matching | Should -HaveCount 1
    }

    It 'reports nothing for boolean inputs, safe event properties, env values, or other block scalars' {
        $script:Findings | Should -HaveCount 7
        foreach ($finding in $script:Findings) {
            $script:Lines[$finding.Line - 1] | Should -Not -Match 'enabled|pull_request\.number|NAME:|TITLE:|^\s+run: \$\{\{ inputs\.name \}\}$'
        }
    }
}

Describe 'Test-DangerousWorkflow.ps1 exit codes' -Tag 'Unit' {
    BeforeAll {
        function script:Invoke-Scanner {
            param([string]$Content)
            $root = Join-Path $TestDrive ([guid]::NewGuid().ToString())
            $workflows = Join-Path $root '.github/workflows'
            New-Item -ItemType Directory -Path $workflows -Force | Out-Null
            Set-Content -Path (Join-Path $workflows 'ci.yml') -Value $Content
            $sarif = Join-Path $TestDrive ("{0}.sarif" -f [guid]::NewGuid())
            & pwsh -NoProfile -File $script:ScriptPath -RepoRoot $root -OutputPath $sarif *> $null
            return $LASTEXITCODE
        }
    }

    It 'exits 0 for a workflow with no interpolated inputs' {
        Invoke-Scanner -Content "on:`n  push:`njobs:`n  a:`n    runs-on: ubuntu-24.04`n    steps:`n      - run: echo ok" | Should -Be 0
    }

    It 'exits 1 for the fixture' {
        Invoke-Scanner -Content (Get-Content -Path $script:FixturePath -Raw) | Should -Be 1
    }

    It 'exits 2 for unparsable YAML' {
        Invoke-Scanner -Content "jobs:`n  a: [unclosed" | Should -Be 2
    }
}
