<#
.SYNOPSIS
    Lists available Microsoft Fabric capacities and allows user to select one for Terraform.
.DESCRIPTION
    This script authenticates to Azure, retrieves a list of Microsoft Fabric capacities where
    the user has write access, and prompts the user to select one. The selected capacity ID
    is saved as a Terraform variable for use in deployment.
.EXAMPLE
    .\Select-FabricCapacity.ps1
#>

# Output directory for storing capacity ID
$OutputDir = "../terraform"
$OutputFile = "fabric_capacity.auto.tfvars"

Write-Host "Authenticating with Azure CLI..." -ForegroundColor Blue
# Check if user is logged in
try {
    # Just check if the command succeeds without storing the result
    az account show | Out-Null
} catch {
    Write-Host "You need to log in to Azure first." -ForegroundColor Yellow
    az login
}

Write-Host "Fetching Microsoft Fabric capacities..." -ForegroundColor Blue

# Get current user information
$userInfo = az ad signed-in-user show | ConvertFrom-Json
$userObjectId = $userInfo.id
$userPrincipalName = $userInfo.userPrincipalName

# Use the Microsoft Fabric API to list capacities
$token = az account get-access-token --resource "https://api.fabric.microsoft.com/" --query accessToken -o tsv

# Call the Fabric API to list capacities
$headers = @{
    "Authorization" = "Bearer $token"
    "Content-Type" = "application/json"
}

$response = Invoke-RestMethod -Uri "https://api.fabric.microsoft.com/v1/capacities" -Headers $headers -Method Get

# Check if we got any capacities
if ($null -eq $response.value -or $response.value.Count -eq 0) {
    Write-Host "No Microsoft Fabric capacities found for your account." -ForegroundColor Yellow
    Write-Host "You can continue without specifying a capacity (using the Fabric free tier)."

    # Ask if they want to continue without a capacity
    $continue = Read-Host "Continue without a capacity? (y/n)"
    if ($continue -eq "y" -or $continue -eq "Y") {
        # Ensure the output directory exists
        if (-not (Test-Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }

        # Write the empty capacity ID to the Terraform variables file
        Set-Content -Path "$OutputDir/$OutputFile" -Value "capacity_id = `"`""
        Write-Host "Configuration set to use Fabric free tier." -ForegroundColor Green
        return
    } else {
        Write-Host "Operation cancelled."
        exit 1
    }
}

# Filter capacities where user has write access
Write-Host "Filtering capacities where you have write access..." -ForegroundColor Blue

# Display available capacities
Write-Host "Available Microsoft Fabric capacities you can use:" -ForegroundColor Blue
Write-Host "--------------------------------------------------------"
Write-Host "ID  | Name | Admin | SKU | State"
Write-Host "--------------------------------------------------------"

# Create an array to store capacity IDs and a counter
$capacityIds = @{}
$count = 1
$totalAvailable = 0

# Process each capacity and display it if user has access
foreach ($capacity in $response.value) {
    $id = $capacity.id
    $name = $capacity.displayName
    $admin = $capacity.properties.admin
    $sku = $capacity.sku
    $state = $capacity.properties.state

    # Check if current user is admin or has access
    if ($admin -like "*$userPrincipalName*" -or $admin -like "*$userObjectId*") {
        Write-Host "$count | $name | $admin | $sku | $state"
        $capacityIds[$count] = $id
        $count++
        $totalAvailable++
    }
}

Write-Host "--------------------------------------------------------"

# Check if we found any capacities with write access
if ($totalAvailable -eq 0) {
    Write-Host "No Microsoft Fabric capacities found where you have write access." -ForegroundColor Yellow
    Write-Host "You can continue without specifying a capacity (using the Fabric free tier)."

    # Ask if they want to continue without a capacity
    $continue = Read-Host "Continue without a capacity? (y/n)"
    if ($continue -eq "y" -or $continue -eq "Y") {
        # Ensure the output directory exists
        if (-not (Test-Path $OutputDir)) {
            New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
        }

        # Write the empty capacity ID to the Terraform variables file
        Set-Content -Path "$OutputDir/$OutputFile" -Value "capacity_id = `"`""
        Write-Host "Configuration set to use Fabric free tier." -ForegroundColor Green
        return
    } else {
        Write-Host "Operation cancelled."
        exit 1
    }
}

# Prompt user to select a capacity
Write-Host "Select a capacity by number (or enter 0 to use free tier):" -ForegroundColor Yellow
$selection = Read-Host

# Validate selection
if ($selection -eq "0") {
    $selectedId = ""
    Write-Host "Using Fabric free tier (no capacity)." -ForegroundColor Green
} elseif ([int]::TryParse($selection, [ref]$null) -and [int]$selection -ge 1 -and [int]$selection -lt $count) {
    $selectedId = $capacityIds[[int]$selection]
    Write-Host "Selected capacity: $selectedId" -ForegroundColor Green
} else {
    Write-Host "Invalid selection." -ForegroundColor Red
    exit 1
}

# Create the output directory if it doesn't exist
if (-not (Test-Path $OutputDir)) {
    New-Item -Path $OutputDir -ItemType Directory -Force | Out-Null
}

# Write the selected capacity ID to the Terraform variables file
Set-Content -Path "$OutputDir/$OutputFile" -Value "capacity_id = `"$selectedId`""

Write-Host "Capacity ID saved to $OutputDir/$OutputFile" -ForegroundColor Green
Write-Host "You can now run terraform apply to deploy using this capacity." -ForegroundColor Blue
