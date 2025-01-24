BeforeAll {
    $emptyFilePath = "$PSScriptRoot/empty-azure-providers.txt"
    New-Item -Path $emptyFilePath -ItemType File -Force | Out-Null
    . "$PSScriptRoot/register-azure-providers.ps1" -filePath $emptyFilePath
}

AfterAll {
    # Clean up the empty file
    Remove-Item -Path $emptyFilePath -Force
}

Describe "Show-ProviderName" {
    It "should display the provider name with dots" {
        $maxLenProviderName = 30
        $provider = "Microsoft.DocumentDB"
        $expectedOutput = "`e[0KMicrosoft.DocumentDB " + "." * ($maxLenProviderName - $provider.Length + 5) + " "
        $output = Show-ProviderName -provider $provider
        $output | Should -Be $expectedOutput
    }
}

Describe "Show-NotRegisteredState" {
    It "should display NotRegistered state" {
        $expectedOutput = "`e[38;5;15m`e[48;5;1m NotRegistered `e[m"
        $output = Show-NotRegisteredState
        $output | Should -Be $expectedOutput
    }
}

Describe "Show-RegisteredState" {
    It "should display Registered state" {
        $expectedOutput = "`e[38;5;0m`e[48;5;2m Registered `e[m"
        $output = Show-RegisteredState
        $output | Should -Be $expectedOutput
    }
}

Describe "Show-State" {
    It "should display the given state" {
        $state = "Registered"
        $expectedOutput = "`e[38;5;15m`e[48;5;243m Registered `e[m"
        $output = Show-State -state $state
        $output | Should -Be $expectedOutput
    }
}
