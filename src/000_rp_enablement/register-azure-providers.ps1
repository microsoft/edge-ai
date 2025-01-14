<#
    .SYNOPSIS
    Register Azure resource providers that are defined in a text file.

    .PARAMETER filePath
    The path to the text file that contains the list of Azure resource providers to register.

    .PARAMETER help
    Prints the help message.

    .INPUTS
    None

    .OUTPUTS
    None

    .EXAMPLE
    ./register-azure-providers.ps1 -filePath azure-providers.txt

    .EXAMPLE
    ./register-azure-providers.ps1 -help

#>
param (
    [string]$filePath,
    [switch]$help
)

function Show-Usage {
    Write-Output ""
    Write-Output "  Register Azure resource providers"
    Write-Output "  ------------------------------------------------------------"
    Write-Output ""
    Write-Output "  USAGE: ./register-azure-providers.ps1 -filePath <providers-file>"
    Write-Output ""
    Write-Output "    Registers Azure resource providers that are defined in a"
    Write-Output "    text file."
    Write-Output ""
    Write-Output "    Example:"
    Write-Output ""
    Write-Output "    azure-providers.txt"
    Write-Output "    ------------------------------"
    Write-Output "    Microsoft.ApiManagement"
    Write-Output "    Microsoft.Web"
    Write-Output "    Microsoft.DocumentDB"
    Write-Output "    Microsoft.OperationalInsights"
    Write-Output ""
    Write-Output "    ./register-azure-providers.ps1 -filePath azure-providers.txt"
    Write-Output ""
    Write-Output "  USAGE: ./register-azure-providers.ps1 -help"
    Write-Output ""
    Write-Output "    Prints this help."
    Write-Output ""
}

function Show-ProviderName {
    param (
        [string]$provider
    )
    $providerNameLen = $provider.Length
    $dotLen = $maxLenProviderName - $providerNameLen + 5
    Write-Host -NoNewline ("`e[0K$provider " + "." * $dotLen + " ")
}

function Show-NotRegisteredState {
    Write-Host "`e[38;5;15m`e[48;5;1m NotRegistered `e[m"
}

function Show-RegisteredState {
    Write-Host "`e[38;5;0m`e[48;5;2m Registered `e[m"
}

function Show-State {
    param (
        [string]$state
    )
    Write-Host "`e[38;5;15m`e[48;5;243m $state `e[m"
}

function Move-CursorToFirstLine {
    param (
        [int]$numberOfLines
    )
    Write-Host -NoNewline "`e[${numberOfLines}F"
}

if ($help) {
    Show-Usage
    exit 0
}

if (-not (Test-Path $filePath)) {
    Write-Error "File not found: $filePath"
    Show-Usage
    exit 1
}

$delayInSeconds = 5
$maxLenProviderName = 0
$elapsedTimeStart = Get-Date

# Read azure resource providers from text file into hashtable with state of NotRegistered
$providers = @{}
Get-Content $filePath | ForEach-Object {
    $providers[$_] = "NotRegistered"
    $providerNameLen = $_.Length
    if ($providerNameLen -gt $maxLenProviderName) {
        $maxLenProviderName = $providerNameLen
    }
}

# Get list of all registered azure resource providers
$registeredProviders = az provider list --query "sort_by([?registrationState=='Registered'].{Provider:namespace}, &Provider)" --out tsv

# Build a sorted list of azure resource providers to register
$sortedRequiredProviders = $providers.Keys | Sort-Object

# Register the providers in the list that are not already registered
foreach ($provider in $sortedRequiredProviders) {
    Show-ProviderName $provider

    if ($registeredProviders -notcontains $provider) {
        Show-NotRegisteredState
        az provider register --namespace $provider > $null 2>&1
    } else {
        Show-RegisteredState
        $providers[$provider] = "Registered"
    }
}

$totalNumberOfProviders = $providers.Count
$notRegisteredCount = $totalNumberOfProviders

# Print the updated state of each of the provider registrations
while ($notRegisteredCount -gt 0) {
    Move-CursorToFirstLine $totalNumberOfProviders
    foreach ($provider in $sortedRequiredProviders) {
        if ($providers[$provider] -eq "Registered") {
            $state = "Registered"
        } else {
            $state = az provider show --namespace $provider --query 'registrationState' --output tsv
        }

        Show-ProviderName $provider
        if ($state -eq "Registered") {
            $notRegisteredCount--
            Show-RegisteredState
            $providers[$provider] = "Registered"
        } elseif ($state -eq "NotRegistered") {
            Show-NotRegisteredState
        } else {
            Show-State $state
        }
    }

    if ($notRegisteredCount -gt 0) {
        Start-Sleep -Seconds $delayInSeconds
        $notRegisteredCount = $totalNumberOfProviders
    }
}

$elapsedTimeEnd = Get-Date
$elapsedTime = $elapsedTimeEnd - $elapsedTimeStart
Write-Output ""
Write-Output ("Elapsed time - " + $elapsedTime.ToString("hh\:mm\:ss"))
Write-Output ""