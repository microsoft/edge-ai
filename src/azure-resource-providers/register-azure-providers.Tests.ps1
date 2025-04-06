BeforeAll {

    Mock -CommandName Write-Host

    $emptyFilePath = "$PSScriptRoot\empty-azure-providers.txt"
    New-Item -Path $emptyFilePath -ItemType File -Force | Out-Null
    . "$PSScriptRoot\register-azure-providers.ps1" -filePath $emptyFilePath
}

AfterAll {
    # Clean up the empty file
    Remove-Item -Path $emptyFilePath -Force
}

Describe "Show-ProviderName" {
    It "should display the provider name with dots" {
        $maxLenProviderName = 30

        Mock -CommandName Write-Host

        $provider = "Microsoft.DocumentDB"
        $expectedOutput = "`e[0KMicrosoft.DocumentDB " + "." * ($maxLenProviderName - $provider.Length + 5) + " "
        $output = Show-ProviderName -provider $provider
        $output | Should -Be $expectedOutput
    }
}

Describe "Show-NotRegisteredState" {
    It "should display NotRegistered state" {

        Mock -CommandName Write-Host

        $expectedOutput = "`e[38;5;15m`e[48;5;1m NotRegistered `e[m"
        $output = Show-NotRegisteredState
        $output | Should -Be $expectedOutput
    }
}

Describe "Show-RegisteredState" {
    It "should display Registered state" {

        Mock -CommandName Write-Host

        $expectedOutput = "`e[38;5;0m`e[48;5;2m Registered `e[m"
        $output = Show-RegisteredState
        $output | Should -Be $expectedOutput
    }
}

Describe "Show-State" {
    It "should display the given state" {

        Mock -CommandName Write-Host

        $state = "Registered"
        $expectedOutput = "`e[38;5;15m`e[48;5;243m Registered `e[m"
        $output = Show-State -state $state
        $output | Should -Be $expectedOutput
    }
}

Describe 'Register-Azure-Providers' {

    BeforeEach {
        [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUserDeclaredVarsMoreThanAssignments', '', Scope = 'Function')]
        $hash = @{
            callcount = 0
        }
    }

    It 'Should not register providers if no providers are present in text file' {

        Mock -CommandName Write-Host

        Mock -CommandName Get-RegisteredProvider -MockWith {
            return @("Microsoft.Compute", "Microsoft.Network")
        }

        Mock -CommandName Register-Provider

        Mock -CommandName Show-Provider -MockWith { }

        . "$PSScriptRoot\register-azure-providers.ps1" $emptyFilePath
        # Assert
        Assert-MockCalled -CommandName Get-RegisteredProvider -Times 0
        Assert-MockCalled -CommandName Register-Provider -Exactly -Times 0 -Scope It -ParameterFilter { $provider -eq "Microsoft.Storage" }
        Assert-MockCalled -CommandName Show-Provider -Times 0
    }

    It 'Should not need to register the supplied provider because it is already registered' {

        Mock -CommandName Write-Host

        Mock -CommandName Get-RegisteredProvider -MockWith {
            return @("Microsoft.Storage")
        }

        Mock -CommandName Register-Provider

        Mock -CommandName Show-Provider -MockWith {
            param ($provider)
            if ($provider -eq "Microsoft.Storage") {
                return "NotRegistered"
            }
            else {
                return "Registered"
            }
        }

        $oneProviderFilePath = "$PSScriptRoot/one-provider.txt"
        Set-Content -Path $oneProviderFilePath -Value "Microsoft.Storage"

        . "$PSScriptRoot\register-azure-providers.ps1" $oneProviderFilePath
        # Assert
        Assert-MockCalled -CommandName Get-RegisteredProvider -Times 1
        Assert-MockCalled -CommandName Register-Provider -Exactly -Times 0 -Scope It -ParameterFilter { $provider -eq "Microsoft.Storage" }
        Assert-MockCalled -CommandName Show-Provider -Times 0

        Remove-Item -Path $oneProviderFilePath -Force
    }

    It 'Should loop once through all commands because the provider is not registered' {

        Mock -CommandName Write-Host

        Mock -CommandName Get-RegisteredProvider -MockWith {
            return @("")
        }

        Mock -CommandName Register-Provider -MockWith {
            $hash.callcount++
        }

        Mock -CommandName Show-Provider -MockWith {
            param ($provider)
            if ($provider -eq "Microsoft.Storage" -and $hash.callcount -eq 1) {
                return "Registered"
            }
            else {
                return "NotRegistered"
            }
        }

        $oneProviderFilePath = "$PSScriptRoot/one-provider.txt"
        Set-Content -Path $oneProviderFilePath -Value "Microsoft.Storage"

        . "$PSScriptRoot\register-azure-providers.ps1" $oneProviderFilePath
        # Assert
        Assert-MockCalled -CommandName Get-RegisteredProvider -Times 1
        Assert-MockCalled -CommandName Register-Provider -Exactly -Times 1 -Scope It -ParameterFilter { $provider -eq "Microsoft.Storage" }
        Assert-MockCalled -CommandName Show-Provider -Times 1

        Remove-Item -Path $oneProviderFilePath -Force
    }
}