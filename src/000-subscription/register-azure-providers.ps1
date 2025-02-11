<#
.SYNOPSIS
    Register Azure resource providers that are defined in a text file.

.DESCRIPTION
    This script registers Azure resource providers specified in a text file. Each line in the text file should contain the name of an Azure resource provider.

.PARAMETER filePath
    The path to the text file that contains the list of Azure resource providers to register. This parameter is required.

.INPUTS
    None

.OUTPUTS
    None

.EXAMPLE
    ./register-azure-providers.ps1 -filePath azure-providers.txt
    This command registers the Azure resource providers listed in the azure-providers.txt file.

.NOTES
    Author: Your Name
    Date: YYYY-MM-DD
    Version: 1.0
#>

Param (
    [Parameter(Mandatory)]
    [string]$filePath
)

function Show-ProviderName {
    param (
        [string]$provider
    )
    $providerNameLen = $provider.Length
    $dotLen = $maxLenProviderName - $providerNameLen + 5
    return ("`e[0K$provider " + "." * $dotLen + " ")
}

function Show-NotRegisteredState {
    return ("`e[38;5;15m`e[48;5;1m NotRegistered `e[m")
}

function Show-RegisteredState {
    return ("`e[38;5;0m`e[48;5;2m Registered `e[m")
}

function Show-State {
    param (
        [string]$state
    )
    return ("`e[38;5;15m`e[48;5;243m $state `e[m")
}

function Move-CursorToFirstLine {
    param (
        [int]$numberOfLines
    )
    Write-Host -NoNewline "`e[${numberOfLines}F"
}

function Test-Cli-Install {
    # Check if Azure CLI is installed on Windows
    $azCliPath = Get-Command az -ErrorAction SilentlyContinue

    if ($azCliPath) {
        Write-Output "Azure CLI is installed. Path: $($azCliPath.Path)"
    } else {
        Write-Output "Azure CLI is not installed. Please install Azure CLI at https://aka.ms/azurecli."
    exit 1
    }
}

function Get-RegisteredProvider {
    # Get list of all registered azure resource providers
    return az provider list --query "sort_by([?registrationState=='Registered'].{Provider:namespace}, &Provider)" --out tsv
}

function Register-Provider {
    param (
        [string]$provider
    )
    # Register the azure resource provider
    az provider register --namespace $provider > $null 2>&1
}

function Show-Provider {
    param (
        [string]$provider
    )
    # Show the azure resource provider
    return az provider show --namespace $provider --query "registrationState" --out tsv
}

Test-Cli-Install

if (-not (Test-Path $filePath)) {
    Write-Error "Providers file not found: $filePath"
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

# Check if there are any providers to register
if ($providers.Count -eq 0) {
    Write-Host "No providers to register."
    exit 0
}

# Get list of all registered azure resource providers
$registeredProviders = Get-RegisteredProvider

# Build a sorted list of azure resource providers to register
$sortedRequiredProviders = $providers.Keys | Sort-Object

# Register the providers in the list that are not already registered
foreach ($provider in $sortedRequiredProviders) {
    Write-Host -NoNewline (Show-ProviderName -provider $provider)

    if ($registeredProviders -notcontains $provider) {
        Write-Host (Show-NotRegisteredState)
        Register-Provider -provider $provider
    }
    else {
        Write-Host (Show-RegisteredState)
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
        }
        else {
            $state = Show-Provider -provider $provider
        }

        Write-Host -NoNewline (Show-ProviderName -provider $provider)
        if ($state -eq "Registered") {
            $notRegisteredCount--
            Write-Host (Show-RegisteredState)
            $providers[$provider] = "Registered"
        }
        elseif ($state -eq "NotRegistered") {
            Write-Host (Show-NotRegisteredState)
        }
        else {
            Write-Host (Show-State $state)
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
