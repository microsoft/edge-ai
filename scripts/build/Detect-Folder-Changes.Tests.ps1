# Copyright (c) Microsoft Corporation.
# SPDX-License-Identifier: MIT

BeforeAll {
    $script:SutPath = (Resolve-Path (Join-Path -Path $PSScriptRoot -ChildPath 'Detect-Folder-Changes.ps1')).Path
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

Describe 'Test-IsRustChangeFile' -Tag 'Unit' {
    It 'matches files under src/500-application/' {
        Test-IsRustChangeFile -Path 'src/500-application/503/media-capture-service/src/main.rs' | Should -BeTrue
    }

    It 'matches root Cargo.toml exactly' {
        Test-IsRustChangeFile -Path 'Cargo.toml' | Should -BeTrue
    }

    It 'matches root Cargo.lock exactly' {
        Test-IsRustChangeFile -Path 'Cargo.lock' | Should -BeTrue
    }

    It 'matches codecov.yml exactly' {
        Test-IsRustChangeFile -Path 'codecov.yml' | Should -BeTrue
    }

    It 'matches the rust-tests workflow' {
        Test-IsRustChangeFile -Path '.github/workflows/rust-tests.yml' | Should -BeTrue
    }

    It 'matches the pr-validation workflow' {
        Test-IsRustChangeFile -Path '.github/workflows/pr-validation.yml' | Should -BeTrue
    }

    It 'returns false for unrelated documentation' {
        Test-IsRustChangeFile -Path 'docs/readme.md' | Should -BeFalse
    }

    It 'returns false for terraform sources outside 500-application' {
        Test-IsRustChangeFile -Path 'src/020-iac/main.tf' | Should -BeFalse
    }

    It 'returns true for any nested Cargo.toml' {
        Test-IsRustChangeFile -Path 'crates/foo/Cargo.toml' | Should -BeTrue
    }

    It 'matches Rust sources under src/900-tools-utilities/' {
        Test-IsRustChangeFile -Path 'src/900-tools-utilities/901-video-tools/cli/video-to-gif/src/main.rs' | Should -BeTrue
    }

    It 'matches Cargo.toml under src/900-tools-utilities/' {
        Test-IsRustChangeFile -Path 'src/900-tools-utilities/901-video-tools/cli/video-to-gif/Cargo.toml' | Should -BeTrue
    }

    It 'returns false for markdown files containing .rs in the name' {
        Test-IsRustChangeFile -Path 'docs/example.rs.md' | Should -BeFalse
    }

    It 'returns false for text files referencing rs' {
        Test-IsRustChangeFile -Path 'notes/rs-overview.txt' | Should -BeFalse
    }

    It 'returns false for the matrix-folder-check workflow' {
        Test-IsRustChangeFile -Path '.github/workflows/matrix-folder-check.yml' | Should -BeFalse
    }

    It 'returns false for an empty path' {
        Test-IsRustChangeFile -Path '' | Should -BeFalse
    }
}

Describe 'Test-RustHasChange' -Tag 'Unit' {
    It 'returns false for $null input' {
        Test-RustHasChange -ChangedFiles $null | Should -BeFalse
    }

    It 'returns false for an empty array' {
        Test-RustHasChange -ChangedFiles @() | Should -BeFalse
    }

    It 'returns true when any file matches' {
        Test-RustHasChange -ChangedFiles @('docs/readme.md', 'Cargo.toml') | Should -BeTrue
    }

    It 'returns true when a src/500-application file is present' {
        Test-RustHasChange -ChangedFiles @('src/500-application/503/foo/src/lib.rs') | Should -BeTrue
    }

    It 'returns false when no file matches' {
        Test-RustHasChange -ChangedFiles @('docs/readme.md', 'src/020-iac/main.tf') | Should -BeFalse
    }
}
