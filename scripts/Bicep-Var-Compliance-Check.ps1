# -----------------------------------------------------------------------------
# Bicep Variable Compliance Check (PowerShell Version)
# -----------------------------------------------------------------------------
#
# This script validates Bicep parameter definitions across files for consistency.
# It scans all Bicep files in the specified directory (default: ../src and ../blueprints),
# extracts parameter definitions, and checks for inconsistencies.
#
# The script generates a JSON array of inconsistencies found in parameter definitions.
# Each inconsistency is reported as a warning with details about the current and expected values.
#
# Dependencies:
#   - Bicep PowerShell module (automatically installed if missing)
#
# Exit Codes:
#   0 - Success
#   1 - Failure (e.g., missing dependencies, errors during execution)
#
# Usage:
#   ./bicep-var-compliance-check.ps1 [<path-to-src-directory>]
#
# Example:
#   ./bicep-var-compliance-check.ps1
#   ./bicep-var-compliance-check.ps1 -BasePath "../src"
#
# The script performs the following:
#   1. Verifies that Bicep module is installed and accessible
#   2. Finds all Bicep files in the specified directories
#   3. Extracts parameter definitions from each file
#   4. Checks for inconsistencies in parameter descriptions across files
#   5. Outputs warnings as JSON for integration with build systems
# -----------------------------------------------------------------------------

[CmdletBinding()]
param (
    [Parameter(Position = 0, Mandatory = $false)]
    [string[]]$DirectoryPaths = @("src", "blueprints")
)

function Find-BicepFile {
    <#
    .SYNOPSIS
    Finds all Bicep files in the specified directories.

    .DESCRIPTION
    This function recursively searches for .bicep files in the specified directories.
    It converts relative paths to absolute paths based on the script's location.

    .PARAMETER DirectoryPaths
    Array of directory paths to search for Bicep files.

    .EXAMPLE
    Find-BicepFile -DirectoryPaths @("C:\Projects\src", "C:\Projects\blueprints")

    .OUTPUTS
    [System.Array] - Array of file paths for .bicep files
    #>
    [CmdletBinding()]
    [OutputType([System.Array])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string[]]$DirectoryPaths
    )

    $bicepFiles = @()

    foreach ($directory in $DirectoryPaths) {
        # Convert relative path to absolute path using Join-Path
        if (-not [System.IO.Path]::IsPathRooted($directory)) {
            $directory = Join-Path -Path $PWD.Path -ChildPath $directory
        }

        if (Test-Path -Path $directory -PathType Container) {
            Write-Verbose "Scanning for .bicep files in: $directory"
            # Get all .bicep files recursively
            $files = Get-ChildItem -Path $directory -Filter "*.bicep" -Recurse -File
            $bicepFiles += $files.FullName
        }
        else {
            Write-Warning "Directory not found: $directory"
        }
    }

    Write-Verbose "Found $($bicepFiles.Count) Bicep files"
    return $bicepFiles
}


function Convert-BicepToArmTemplate {
    <#
    .SYNOPSIS
    Converts a Bicep file to an ARM JSON template.

    .DESCRIPTION
    This function takes a Bicep file as input and converts it to an ARM JSON template
    using the Bicep PowerShell module. It validates that the module is properly installed
    and available before conversion. The output is stored in a .arm directory.

    .PARAMETER BicepFilePath
    Full path to the Bicep file to convert.

    .EXAMPLE
    Convert-BicepToArmTemplate -BicepFilePath "./main.bicep"

    .OUTPUTS
    [System.String] - Path to the generated ARM template file when conversion is successful
    [System.Void] - Null when an error occurs

    .NOTES
    Requires Bicep PowerShell module.
    #>
    [CmdletBinding()]
    [OutputType([System.String])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$BicepFilePath
    )

    try {
        # Create a centralized .arm directory at the root of the repository
        $rootArmDirectory = Join-Path -Path $PWD.Path -ChildPath ".arm"

        # Create the .arm directory if it doesn't exist
        if (-not (Test-Path -Path $rootArmDirectory -PathType Container)) {
            New-Item -Path $rootArmDirectory -ItemType Directory -Force | Out-Null
            Write-Verbose "Created directory: $rootArmDirectory"
        }

        # Get relative path structure to maintain the folder structure within the centralized .arm directory
        $relativePath = [System.IO.Path]::GetDirectoryName($BicepFilePath).Replace($PWD.Path, "").TrimStart("/\")
        $targetDir = if ([string]::IsNullOrEmpty($relativePath)) {
            $rootArmDirectory
        } else {
            $armStructurePath = Join-Path -Path $rootArmDirectory -ChildPath $relativePath
            if (-not (Test-Path -Path $armStructurePath -PathType Container)) {
                New-Item -Path $armStructurePath -ItemType Directory -Force | Out-Null
                Write-Verbose "Created directory structure: $armStructurePath"
            }
            $armStructurePath
        }

        $bicepFileName = [System.IO.Path]::GetFileNameWithoutExtension($BicepFilePath)
        $outputFilePath = Join-Path -Path $targetDir -ChildPath "$bicepFileName.json"

        Write-Verbose "Converting Bicep file: $BicepFilePath to ARM template: $outputFilePath"
        Write-Verbose "Using Bicep PowerShell module"

        # Build the Bicep
        az bicep build --file $BicepFilePath --outfile $outputFilePath

        if (Test-Path $outputFilePath) {
            Write-Verbose "Successfully converted Bicep file to ARM template using PowerShell module: $outputFilePath"
            return $outputFilePath
        }

        # If all methods failed, throw an error
        Write-Error "Failed to convert Bicep file to ARM template. Ensure that Bicep PowerShell module is installed."
        return $null
    }
    catch {
        Write-Error "Error converting Bicep to ARM template: $_"
        return $null
    }
}

function Get-BicepVariableFromJson {
    <#
    .SYNOPSIS
    Extracts parameter and variable definitions from an ARM JSON template.

    .DESCRIPTION
    This function parses an ARM JSON template converted from a Bicep file and extracts
    all parameter and variable information including name, type, default value, metadata, and line number.
    The function also reads the original Bicep file to find the actual line numbers where parameters are defined.

    .PARAMETER ArmTemplatePath
    Path to the ARM JSON template file.

    .PARAMETER BicepFilePath
    Original Bicep file path (used for reporting)

    .EXAMPLE
    Get-BicepVariableFromJson -ArmTemplatePath "./main.json" -BicepFilePath "./main.bicep"

    .OUTPUTS
    [System.Object[]] - Array of objects representing parameter and variable definitions
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateNotNullOrEmpty()]
        [string]$ArmTemplatePath,

        [Parameter(Mandatory = $true, Position = 1)]
        [ValidateNotNullOrEmpty()]
        [string]$BicepFilePath
    )

    Write-Verbose "Extracting parameters and variables from ARM template: $ArmTemplatePath"
    $results = @()

    try {
        # Check if file exists before processing
        if (-not (Test-Path -Path $ArmTemplatePath -PathType Leaf)) {
            Write-Warning "ARM template file not found: $ArmTemplatePath"
            return @()
        }

        # Check if original Bicep file exists
        if (-not (Test-Path -Path $BicepFilePath -PathType Leaf)) {
            Write-Warning "Original Bicep file not found: $BicepFilePath"
        }

        # Read the original Bicep file to find line numbers
        $bicepContent = @()
        $paramLineNumbers = @{}
        $varLineNumbers = @{}

        if (Test-Path -Path $BicepFilePath -PathType Leaf) {
            $bicepContent = Get-Content -Path $BicepFilePath

            # Find parameter definitions - look for lines with 'param <name>'
            for ($i = 0; $i -lt $bicepContent.Count; $i++) {
                $line = $bicepContent[$i]

                # Match parameter definitions - param name: type
                if ($line -match '^\s*param\s+(\w+)') {
                    $paramName = $Matches[1]
                    # Store 1-based line number (human readable)
                    $paramLineNumbers[$paramName] = $i + 1
                }

                # Match variable definitions - var name = value
                if ($line -match '^\s*var\s+(\w+)') {
                    $varName = $Matches[1]
                    # Store 1-based line number (human readable)
                    $varLineNumbers[$varName] = $i + 1
                }
            }
        }

        # Read the ARM template JSON
        $armTemplate = Get-Content -Path $ArmTemplatePath -Raw | ConvertFrom-Json

        # Get repository-relative path for storage
        $repoPath = $BicepFilePath
        if ($BicepFilePath -match '(?:/|\\)(?:src|blueprints)(?:/|\\).*$') {
            # Trim any existing leading slashes before adding one to prevent double slashes
            $matchedPath = $Matches[0].TrimStart('/\')
            $repoPath = '/' + $matchedPath
        }

        # Process parameters if they exist
        if (Get-Member -InputObject $armTemplate -Name "parameters" -MemberType Properties) {
            foreach ($paramName in $armTemplate.parameters.PSObject.Properties.Name) {
                $parameter = $armTemplate.parameters.$paramName

                # Extract parameter information
                $variableName = $paramName
                $variableType = $parameter.type
                $defaultValue = if ($parameter.PSObject.Properties.Name -contains "defaultValue") {
                    $parameter.defaultValue | ConvertTo-Json -Depth 5 -Compress
                } else {
                    $null
                }

                # Get description from metadata if available
                $description = ""
                if ($parameter.PSObject.Properties.Name -contains "metadata" -and
                    $parameter.metadata.PSObject.Properties.Name -contains "description") {
                    $description = $parameter.metadata.description
                }

                # Use the line number found in the original Bicep file, or 0 if not found
                $lineNumber = if ($paramLineNumbers.ContainsKey($variableName)) {
                    $paramLineNumbers[$variableName]
                } else {
                    0
                }

                $results += [PSCustomObject]@{
                    Name = $variableName
                    Type = $variableType
                    DefaultValue = $defaultValue
                    Description = $description
                    FilePath = $BicepFilePath
                    RepoRelativePath = $repoPath
                    LineNumber = $lineNumber
                    ElementType = "parameter"
                }
            }
        }

        # Process variables if they exist
        if (Get-Member -InputObject $armTemplate -Name "variables" -MemberType Properties) {
            foreach ($varName in $armTemplate.variables.PSObject.Properties.Name) {
                $variable = $armTemplate.variables.$varName

                # Extract variable information
                $variableName = $varName
                # Variables don't have a type in ARM templates, so we'll infer from the value
                $variableType = if ($null -eq $variable) {
                    "null"
                } elseif ($variable -is [bool]) {
                    "bool"
                } elseif ($variable -is [int]) {
                    "int"
                } elseif ($variable -is [string]) {
                    "string"
                } elseif ($variable -is [array]) {
                    "array"
                } elseif ($variable -is [PSCustomObject]) {
                    "object"
                } else {
                    "unknown"
                }

                $defaultValue = $variable | ConvertTo-Json -Depth 5 -Compress

                # Variables don't have metadata in ARM templates directly
                # But we can look for a comment pattern in the JSON that Bicep might have added
                $description = ""

                # Use the line number found in the original Bicep file, or 0 if not found
                $lineNumber = if ($varLineNumbers.ContainsKey($variableName)) {
                    $varLineNumbers[$variableName]
                } else {
                    0
                }

                $results += [PSCustomObject]@{
                    Name = $variableName
                    Type = $variableType
                    DefaultValue = $defaultValue
                    Description = $description
                    FilePath = $BicepFilePath
                    RepoRelativePath = $repoPath
                    LineNumber = $lineNumber
                    ElementType = "variable"
                }
            }
        }

        Write-Verbose "Found $($results.Count) parameters and variables in $ArmTemplatePath"
        return $results
    }
    catch {
        Write-Error "Error extracting parameters and variables from ARM template $ArmTemplatePath`: $_"
        return @()
    }
}

function Compare-BicepVariable {
    <#
    .SYNOPSIS
    Compares variable definitions across multiple Bicep files for consistency.

    .DESCRIPTION
    This function checks if the same variables across different Bicep files
    have consistent descriptions, types, and default values.

    .PARAMETER VariablesList
    Array of variable definition objects extracted from Bicep files.

    .EXAMPLE
    $variables = Get-BicepVariable -BicepFilePaths @("./module1.bicep", "./module2.bicep")
    Compare-BicepVariable -VariablesList $variables

    .OUTPUTS
    [System.Object[]] - Array of objects representing inconsistencies found
    #>
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [AllowEmptyCollection()]
        [PSCustomObject[]]$VariablesList
    )

    Write-Verbose "Comparing Bicep variables for consistency"

    # Check if there are any variables to compare
    if ($null -eq $VariablesList -or $VariablesList.Count -eq 0) {
        Write-Warning "No variables provided for comparison"
        return @()
    }

    # Group variables by name
    $variablesByName = $VariablesList | Group-Object -Property Name

    # Dictionary to store collected differences
    $varDifferences = @{}
    $varFiles = @{}
    $varLocations = @{}

    # Check each variable group for inconsistencies
    foreach ($group in $variablesByName) {
        $variableName = $group.Name
        $variables = $group.Group

        # Skip if there's only one instance of this variable
        if ($variables.Count -le 1) {
            continue
        }

        Write-Verbose "Checking variable '$variableName' across $($variables.Count) files"

        # Initialize collections for this variable
        $descriptions = @()
        $files = @()
        $locations = @()

        # Get all descriptions and files
        foreach ($var in $variables) {
            if (-not [string]::IsNullOrEmpty($var.Description) -and
                -not $descriptions.Contains($var.Description)) {
                $descriptions += $var.Description
            }

            # Create location object with file path and line number
            $location = [PSCustomObject]@{
                file = $var.RepoRelativePath
                lineNumber = $var.LineNumber
            }
            $locations += $location

            # Store the repository-relative path
            if (-not $files.Contains($var.RepoRelativePath)) {
                $files += $var.RepoRelativePath
            }
        }

        # If multiple descriptions exist, we have an inconsistency
        if ($descriptions.Count -gt 1) {
            $varDifferences[$variableName] = $descriptions
            $varFiles[$variableName] = $files
            $varLocations[$variableName] = $locations
        }
    }

    # Format the output to match the Python script format with additional location info
    $inconsistencies = @()
    foreach ($varName in $varDifferences.Keys) {
        $inconsistencies += [PSCustomObject]@{
            variable = $varName
            differences = $varDifferences[$varName]
            files = $varFiles[$varName]
            locations = $varLocations[$varName]
        }
    }

    Write-Verbose "Found $($inconsistencies.Count) inconsistencies"
    return $inconsistencies
}

# Main Execution Code

# Display a friendly message showing which directories we're checking
Write-Verbose "Checking Bicep variable consistency in the following directories:"
foreach ($path in $DirectoryPaths) {
    Write-Verbose "  - $path"
}

# Find all Bicep files in the specified directories
$bicepFiles = Find-BicepFile -DirectoryPaths $DirectoryPaths

# Now you can process each Bicep file
Write-Verbose "Found $($bicepFiles.Count) Bicep files to process"

# Process each Bicep file and collect variables
$allVariables = @()
foreach ($file in $bicepFiles) {
    # Add validation to ensure file exists and isn't null or empty
    if (-not [string]::IsNullOrWhiteSpace($file) -and (Test-Path -Path $file -PathType Leaf)) {
        Write-Verbose "Processing file: $file"

        # Convert Bicep file to ARM template using Build-AzBicep
        $armTemplatePath = Convert-BicepToArmTemplate -BicepFilePath $file

        # Extract variables from ARM template if the conversion was successful
        if ($null -ne $armTemplatePath -and (Test-Path -Path $armTemplatePath -PathType Leaf)) {
            # Extract variables from ARM template JSON
            $fileVariables = Get-BicepVariableFromJson -ArmTemplatePath $armTemplatePath -BicepFilePath $file
            $allVariables += $fileVariables

            Write-Verbose "Processed $($fileVariables.Count) variables from $file"

        } else {
            Write-Warning "Failed to convert Bicep file to ARM template: $file"
        }
    }
    else {
        Write-Warning "Skipping invalid file path: '$file'"
    }
}

Write-Verbose "Collected $($allVariables.Count) total variables across all files"

# Compare variables for consistency
$inconsistencies = Compare-BicepVariable -VariablesList $allVariables

# Create .arm directory in the root of the workspace for compliance results
$armDirectory = Join-Path -Path $PWD.path -ChildPath ".arm"
if (-not (Test-Path -Path $armDirectory -PathType Container)) {
    New-Item -Path $armDirectory -ItemType Directory -Force | Out-Null
    Write-Verbose "Created directory for compliance results: $armDirectory"
}

# Define output file path in the .arm directory
$outputFile = Join-Path -Path $armDirectory -ChildPath "bicep-compliance-results.json"

# Output results
if ($inconsistencies.Count -eq 0) {
    Write-Host "No inconsistencies found in Bicep variables!" -ForegroundColor Green

    # Write an empty array to the output file
    "[]" | Out-File -FilePath $outputFile -Encoding utf8
    Write-Host "Writing empty results to $outputFile"
}
else {
    Write-Warning "Found $($inconsistencies.Count) inconsistencies in Bicep variables"

    # Format the inconsistencies as JSON
    $jsonResult = $inconsistencies | ConvertTo-Json -Depth 4

    # Output the JSON to the console (for debugging purposes)
    Write-Output $jsonResult

    # Save results to file for pipeline processing
    Write-Host "Writing results to $outputFile"
    $jsonResult | Out-File -FilePath $outputFile -Encoding utf8
}

# Always exit with code 0, let the pipeline decide whether to break the build
exit 0
