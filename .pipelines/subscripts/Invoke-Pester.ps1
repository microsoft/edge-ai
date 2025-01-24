# Used for Azure DevOps unit test results

# To run locally, simply just run Invoke-Pester, no need to run this script

param (
    [Parameter(Mandatory=$true)]
    [string]$Path,

    [Parameter(Mandatory=$true)]
    [string]$OutputFile
)

# Update Pester to the latest version
Install-Module -Name Pester -Force -AllowClobber

Import-Module Pester

# Print out the Path and OutputFile variables
Write-Host "Test file path: $Path"
Write-Host "Output test file path: $OutputFile"

Invoke-Pester -Path $Path -OutputFile $OutputFile -OutputFormat NUnitXml
