# Used for Azure DevOps unit test results

# To run locally, simply just run Invoke-Pester, no need to run this script

param (
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

function Find-PesterModule {
    param (
        [string]$ModuleName = "Pester",
        [string]$MinimumVersion = "5.0.0"
    )

    # Check if the module is installed
    $module = Get-Module -ListAvailable -Name $ModuleName | Sort-Object -Property Version -Descending | Select-Object -First 1

    if ($null -eq $module -or $module.Version -lt [version]$MinimumVersion) {
        Write-Host "Installing or updating $ModuleName to version $MinimumVersion or higher..."
        Install-Module -Name $ModuleName -MinimumVersion $MinimumVersion -Force -AllowClobber
    } else {
        Write-Host "$ModuleName version $($module.Version) is already installed."
    }
}

# Ensure Pester module is installed and at least version 5
Find-PesterModule -ModuleName "Pester" -MinimumVersion "5.0.0"


Import-Module Pester

$configuration = [PesterConfiguration]@{
    Run = @{
        Path = $Path
    }
    Output = @{
        Verbosity = 'Detailed'
     }
     TestResult = @{
        Enabled = $true
        OutputFormat = "NUnitXml"
        OutputPath   = $OutputFile
    }
}

# Print out the Path and OutputFile variables
Write-Host "Test file path: $Path"
Write-Host "Output test file path: $OutputFile"

Invoke-Pester -Configuration $configuration
