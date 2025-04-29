<#
.SYNOPSIS
    Detects changes in repository folders and files, providing structured JSON output.

.DESCRIPTION
    This script detects changes in the repository's folders and files, providing a structured
    JSON output that identifies which components have been modified to help determine what
    needs to be tested or rebuilt.

    - Detects changes in shell scripts (.sh) in the subscription setup folder
    - Detects changes in PowerShell scripts (.ps1) in the subscription setup folder
    - Identifies Terraform folders that contain modified files
    - Identifies Bicep folders that contain modified files
    - Optionally returns all folders containing Terraform and Bicep files, not just those with changes
    - Generates a structured JSON response with the results

.PARAMETER IncludeAllFolders
    When provided, includes all folders that contain Terraform and Bicep files

.PARAMETER BaseBranch
    The branch to compare against (default: origin/main)

.PARAMETER OutputFile
    Optional file path to write the JSON output to instead of returning it

.PARAMETER OutputJson
    Switch parameter that forces the script to return the JSON string even when writing to a file

.EXAMPLE
    # Check only changed Terraform and Bicep folders:
    .\Detect-Folder-Changes.ps1

.EXAMPLE
    # Include all Terraform and Bicep folders regardless of changes:
    .\Detect-Folder-Changes.ps1 -IncludeAllFolders

.EXAMPLE
    # Compare against a different branch:
    .\Detect-Folder-Changes.ps1 -BaseBranch origin/develop

.EXAMPLE
    # Write output to a file:
    .\Detect-Folder-Changes.ps1 -OutputFile "folder-data.json"

.EXAMPLE
    # Write output to a file and also return the JSON:
    .\Detect-Folder-Changes.ps1 -OutputFile "folder-data.json" -OutputJson

.OUTPUTS
    A JSON object with the following structure:
    {
      "subscription": {
        "shell_changes": true|false,
        "powershell_changes": true|false
      },
      "terraform": {
        "has_changes": true|false,
        "folders": { ... }
      },
      "bicep": {
        "has_changes": true|false,
        "folders": { ... }
      }
    }
#>

[CmdletBinding()]
param(
    [switch]$IncludeAllFolders,
    [string]$BaseBranch = "origin/main",
    [string]$OutputFile = "",
    [switch]$OutputJson
)

# Check for dependencies using PowerShell-native Get-Command
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    Write-Error "Error: git is not installed or not in PATH"
    exit 1
}

# Initialize variables to track changes
$subscriptionShellChanges = $false
$subscriptionPwshChanges = $false
$terraformHasChanges = $false
$terraformFolders = @{}
$bicepHasChanges = $false
$bicepFolders = @{}

# Use native PowerShell commands where possible and minimize redundant operations

function Get-ChangedFileData {
    param (
        [switch]$IncludeAll,
        [string]$BaseBranch
    )

    if ($IncludeAll) {
        # CRITICAL PERFORMANCE FIX: Use git ls-files instead of Get-ChildItem for massive speedup
        # This matches what the bash script does with 'find'
        $patterns = @("*.tf", "*.tfvars", "*.tfstate", "*.hcl", "*.bicep")
        $allFiles = @()

        foreach ($pattern in $patterns) {
            # Use git ls-files which is much faster than PowerShell file operations
            $files = git ls-files "src/**/$pattern" "blueprints/**/$pattern" 2>$null
            if ($files) {
                $allFiles += $files
            }
        }

        return $allFiles
    }
    else {
        # This part is already fast
        return git diff --name-only --diff-filter=ACMRT "$BaseBranch...HEAD"
    }
}

# Also optimize the regex matching function
function Get-FilePathData {
    param (
        [string[]]$Paths
    )

    if (-not $Paths -or $Paths.Count -eq 0) {
        return @()
    }

    # Create a more efficient approach directly using pattern groups
    $results = @()

    # Process paths in batches rather than one at a time
    $srcPaths = $Paths | Where-Object { $_ -match '^src/' }
    $blueprintPaths = $Paths | Where-Object { $_ -match '^blueprints/' }

    if ($srcPaths) {
        # Extract src paths all at once with a single regex operation
        $srcMatches = $srcPaths | ForEach-Object {
            if ($_ -match '^src/([^/]+)/([^/]+)') {
                "src/$($Matches[1])/$($Matches[2])"
            }
        }
        $results += $srcMatches
    }

    if ($blueprintPaths) {
        # Extract blueprint paths all at once
        $blueprintMatches = $blueprintPaths | ForEach-Object {
            if ($_ -match '^blueprints/([^/]+)') {
                "blueprints/$($Matches[1])"
            }
        }
        $results += $blueprintMatches
    }

    # Use the much faster approach for unique items
    return $results | Select-Object -Unique
}

# Optimize the subscription file check
function Test-ProviderRegChange {
    param (
        [string[]]$Files
    )

    $shellChanges = $false
    $pwshChanges = $false

    # Single pass through the files instead of two separate Where-Object calls
    foreach ($file in $Files) {
        if ($file -match 'src/azure-resource-providers/.*\.sh$') {
            $shellChanges = $true
        }
        elseif ($file -match 'src/azure-resource-providers/.*\.ps1$') {
            $pwshChanges = $true
        }

        # Early exit if both are already true
        if ($shellChanges -and $pwshChanges) {
            break
        }
    }

    return @{ Shell = $shellChanges; PowerShell = $pwshChanges }
}

# Function to convert paths to JSON object structure
function Convert-PathsToJson {
    param (
        [string[]]$Paths
    )

    $result = @{}

    foreach ($path in $Paths) {
        if ($path) {
            $result[$path] = @{
                folderName = $path
            }
        }
    }

    return $result
}

# Get changed files
$changedFiles = Get-ChangedFileData -IncludeAll:$IncludeAllFolders -BaseBranch $BaseBranch

# Batch process subscription file checks
$subscriptionChanges = Test-ProviderRegChange -Files $changedFiles
$subscriptionShellChanges = $subscriptionChanges.Shell
$subscriptionPwshChanges = $subscriptionChanges.PowerShell

# Performance improvement: Only run debug information if Verbose is enabled
if ($IncludeAllFolders -and $VerbosePreference -ne 'SilentlyContinue') {
    Write-Host "[DEBUG] Searching for all Terraform and Bicep files..." -ForegroundColor Cyan
    $tfDebug = Get-ChildItem -Path src, blueprints -Recurse -File -Include *.tf, *.tfvars, *.tfstate, *.hcl -ErrorAction SilentlyContinue
    $bicepDebug = Get-ChildItem -Path src, blueprints -Recurse -File -Include *.bicep -ErrorAction SilentlyContinue

    Write-Host "Found $($tfDebug.Count) Terraform files and $($bicepDebug.Count) Bicep files" -ForegroundColor Cyan

    # If no files found, check if directories exist
    if ($tfDebug.Count -eq 0 -and $bicepDebug.Count -eq 0) {
        $srcExists = Test-Path -Path "src"
        $blueprintsExists = Test-Path -Path "blueprints"
        Write-Host "Directory check: src exists: $srcExists, blueprints exists: $blueprintsExists" -ForegroundColor Cyan
    }
}

# Simplify file filtering with efficient pattern matching
$tfFiles = $changedFiles | Where-Object { $_ -match '\.(tf|tfvars|tfstate|hcl)$' }
$bicepFiles = $changedFiles | Where-Object { $_ -match '\.bicep$' }

# Process paths in single batch operations
if ($tfFiles) {
    $tfPaths = Get-FilePathData -Paths $tfFiles
    if ($tfPaths.Count -gt 0) {
        $terraformHasChanges = $true
        $terraformFolders = Convert-PathsToJson -Paths $tfPaths
    }
}

if ($bicepFiles) {
    $bicepPaths = Get-FilePathData -Paths $bicepFiles
    if ($bicepPaths.Count -gt 0) {
        $bicepHasChanges = $true
        $bicepFolders = Convert-PathsToJson -Paths $bicepPaths
    }
}

# Create the final JSON output
$jsonOutput = [PSCustomObject]@{
    subscription = [PSCustomObject]@{
        shell_changes = $subscriptionShellChanges
        powershell_changes = $subscriptionPwshChanges
    }
    terraform = [PSCustomObject]@{
        has_changes = $terraformHasChanges
        folders = $terraformFolders
    }
    bicep = [PSCustomObject]@{
        has_changes = $bicepHasChanges
        folders = $bicepFolders
    }
}

# Convert to JSON
$jsonString = $jsonOutput | ConvertTo-Json -Depth 10

# Write to file if specified
if ($OutputFile) {
    $jsonString | Out-File -FilePath $OutputFile -Encoding utf8
}

# Write to stdout if no OutputFile specified or if OutputJson is explicitly requested
if (-not $OutputFile -or $OutputJson) {

    # Return for module/dot-sourcing usage
    return $jsonString
}
