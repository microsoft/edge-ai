<#
.SYNOPSIS
    Detects changes in repository.EXAMPLE
    # Include all Terraform and Bicep folders for security scanning:
    .\Detect-Folder-Changes.ps1 -IncludeAllIaC

.EXAMPLE
    # Compare against a different branch with application detection:
    .\Detect-Folder-Changes.ps1 -BaseBranch origi    if (-not [string]::IsNullOrWhiteSpace($repoRoot) -and $resolvedApplicationPath.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativeApplicationPath = $resolvedApplicationPath.Substring($repoRoot.Length) -replace '^[/\\]+', ''
    }
    else {
        $relativeApplicationPath = ($ApplicationPath -replace '^[/\\]+', '')
    }
}
else {
    $relativeApplicationPath = ($ApplicationPath -replace '^[/\\]+', '') -IncludeAllApplications

.EXAMPLE
    # Write output to a file with application detection:
    .\Detect-Folder-Changes.ps1 -OutputFile "changes.json" -IncludeAllApplications

.DESCRIPTION
    This script detects changes in the repository's folders and files, providing a structured
    JSON output that identifies which components have been modified to help determine what
    needs to be tested or rebuilt.

    - Detects changes in shell scripts (.sh) in the subscription setup folder
    - Detects changes in PowerShell scripts (.ps1) in the subscription setup folder
    - Identifies Terraform folders that contain modified files
    - Identifies Bicep folders that contain modified files
    - Detects application changes in src/500-application/ with service-level granularity
    - Optionally returns all folders containing Terraform and Bicep files for security scanning, not just those with changes
    - Generates a structured JSON response with the results

.PARAMETER IncludeAllIaC
    When provided alone, includes ONLY Infrastructure as Code (Terraform/Bicep) folders for Checkov security scanning.
    When combined with IncludeAllApplications, includes all folders (same as default).

.PARAMETER IncludeAllApplications
    When provided alone, includes ONLY application change detection.
    When combined with IncludeAllIaC, includes all folders (same as default).

.PARAMETER BaseBranch
    The branch to compare against (default: origin/main)

.PARAMETER OutputFile
    Optional file path to write the JSON output to instead of returning it

.PARAMETER OutputJson
    Switch parameter that forces the script to return the JSON string even when writing to a file

.PARAMETER ApplicationPath
    Path to applications directory (default: src/500-application)

.PARAMETER DependencyFile
    Path to application dependency configuration (default: src/500-application/dependency-graph.json)

.EXAMPLE
    # Default: Check both infrastructure and application changes:
    .\Detect-Folder-Changes.ps1

.EXAMPLE
    # Check ONLY infrastructure folders for security scanning:
    .\Detect-Folder-Changes.ps1 -IncludeAllIaC

.EXAMPLE
    # Check ONLY application changes:
    .\Detect-Folder-Changes.ps1 -IncludeAllApplications

.EXAMPLE
    # Explicitly include all types (same as default):
    .\Detect-Folder-Changes.ps1 -IncludeAllIaC -IncludeAllApplications

.EXAMPLE
    # Compare against a different branch (all types):
    .\Detect-Folder-Changes.ps1 -BaseBranch origin/develop

.EXAMPLE
    # Write output to a file with default detection:
    .\Detect-Folder-Changes.ps1 -OutputFile "changes.json"

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
      },
      "applications": {
        "has_changes": true|false,
        "changed_applications": ["app1", "app2"],
        "services": {
          "app1": ["service1", "service2"],
          "app2": ["service1"]
        },
        "dependencies": {
          "build_order": ["app1", "app2"],
          "affected_by_changes": ["app1", "app2", "app3"]
        }
      }
    }
#>

[CmdletBinding()]
param(
    [switch]$IncludeAllIaC,
    [switch]$IncludeAllApplications,
    [string]$BaseBranch = "origin/main",
    [string]$OutputFile = "",
    [switch]$OutputJson,
    [string]$ApplicationPath = "src/500-application"
)

# ============================================================================
# DEPENDENCY VALIDATION AND ERROR HANDLING
# ============================================================================

function Test-Dependency {
    [CmdletBinding()]
    param()

    $missingDeps = @()

    # Test required external dependencies
    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        $missingDeps += "git"
    }

    if ($missingDeps.Count -gt 0) {
        $message = "Missing required dependencies: $($missingDeps -join ', ')"
        Write-Error $message
        throw $message
    }

    Write-Verbose "All dependencies validated successfully"
}

# ============================================================================
# APPLICATION DETECTION FUNCTIONS
# ============================================================================

function Get-ApplicationStructure {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$ApplicationPath
    )

    if (-not (Test-Path $ApplicationPath)) {
        Write-Warning "Application path does not exist: $ApplicationPath"
        return @{}
    }

    $applications = @{}

    try {
        # Get all application directories (5xx-* pattern)
        $appDirs = Get-ChildItem -Path $ApplicationPath -Directory -Name |
        Where-Object { $_ -match '^5\d{2}-' }

        foreach ($appDir in $appDirs) {
            $appPath = Join-Path $ApplicationPath $appDir
            $services = @()

            # Check for services directory
            $servicesPath = Join-Path $appPath "services"
            if (Test-Path $servicesPath) {
                $servicesList = Get-ChildItem -Path $servicesPath -Directory -Name
                $services = @($servicesList)
            }

            # Extract app name without 5xx prefix
            $appName = $appDir -replace '^5\d{2}-', ''

            $applications[$appName] = @{
                appName      = $appName
                directory    = $appDir
                path         = $appPath
                services     = $services
                has_services = $services.Count -gt 0
            }
        }

        Write-Verbose "Found $($applications.Count) applications in $ApplicationPath"
        return $applications
    }
    catch {
        Write-Error "Failed to analyze application structure: $_"
        return @{}
    }
}

function Get-ApplicationChange {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string[]]$ChangedFiles,
        [Parameter(Mandatory)]
        [hashtable]$ApplicationStructure,
        [Parameter(Mandatory)]
        [string]$ApplicationRelativePath
    )

    $changedApps = @{}
    $appPattern = "^$($ApplicationRelativePath -replace '\\', '/')/"

    try {
        foreach ($file in $ChangedFiles) {
            # Normalize path separators for cross-platform compatibility
            $normalizedFile = $file -replace '\\', '/'

            if ($normalizedFile -match $appPattern) {
                # Extract application directory from path
                $relativePath = $normalizedFile -replace $appPattern, ''
                $pathParts = $relativePath -split '/'

                if ($pathParts.Count -gt 0 -and $pathParts[0] -match '^5\d{2}-') {
                    $appDir = $pathParts[0]
                    $appName = $appDir -replace '^5\d{2}-', ''

                    if ($ApplicationStructure.ContainsKey($appName)) {
                        if (-not $changedApps.ContainsKey($appName)) {
                            $changedApps[$appName] = @{
                                appName   = $appName
                                directory = "$ApplicationRelativePath/$appDir"
                            }
                        }
                    }
                }
            }
        }

        Write-Verbose "Detected changes in $($changedApps.Count) applications"
        return $changedApps
    }
    catch {
        Write-Error "Failed to analyze application changes: $_"
        return @{}
    }
}

# ============================================================================
# INFRASTRUCTURE DETECTION FUNCTIONS (ENHANCED)
# ============================================================================

# Validate dependencies at script start
Test-Dependency

# Resolve repository root to normalize application path handling
$repoRoot = ""
try {
    $repoRoot = git rev-parse --show-toplevel 2>$null
    if ($repoRoot) {
        $repoRoot = $repoRoot.Trim()
    }
}
catch {
    Write-Verbose "git rev-parse failed when resolving repository root: $_"
}

if ([string]::IsNullOrWhiteSpace($repoRoot)) {
    try {
        $repoRoot = (Resolve-Path -Path (Join-Path $PSScriptRoot "..") -ErrorAction SilentlyContinue).Path
    }
    catch {
        Write-Verbose "Failed to resolve script-relative repository root, falling back to current location: $_"
        $repoRoot = (Get-Location).Path
    }
}

if (-not [string]::IsNullOrWhiteSpace($repoRoot)) {
    $repoRoot = [System.IO.Path]::GetFullPath($repoRoot)
}

if ([System.IO.Path]::IsPathRooted($ApplicationPath)) {
    $resolvedApplicationPath = $ApplicationPath
    try {
        $resolvedApplicationPath = (Resolve-Path -Path $ApplicationPath -ErrorAction SilentlyContinue).Path
    }
    catch {
        Write-Verbose "Failed to resolve absolute application path '$ApplicationPath': $_"
        $resolvedApplicationPath = $ApplicationPath
    }

    if (-not [string]::IsNullOrWhiteSpace($repoRoot) -and $resolvedApplicationPath.StartsWith($repoRoot, [System.StringComparison]::OrdinalIgnoreCase)) {
        $relativeApplicationPath = $resolvedApplicationPath.Substring($repoRoot.Length) -replace '^[/\\]+', ''
    }
    else {
        $relativeApplicationPath = ($ApplicationPath -replace '^[/\\]+', '')
    }
}
else {
    $relativeApplicationPath = ($ApplicationPath -replace '^[/\\]+', '')
    $candidateApplicationPath = if (-not [string]::IsNullOrWhiteSpace($repoRoot)) {
        Join-Path $repoRoot $ApplicationPath
    }
    else {
        Join-Path (Get-Location).Path $ApplicationPath
    }

    try {
        $resolvedApplicationPath = (Resolve-Path -Path $candidateApplicationPath -ErrorAction SilentlyContinue).Path
    }
    catch {
        Write-Verbose "Failed to resolve candidate application path '$candidateApplicationPath': $_"
        $resolvedApplicationPath = [System.IO.Path]::GetFullPath($candidateApplicationPath)
    }
}

if ([string]::IsNullOrWhiteSpace($relativeApplicationPath)) {
    $relativeApplicationPath = ($ApplicationPath -replace '^[/\\]+', '')
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
        # DEBUG: Log git state before merge-base calculation
        Write-Host "DEBUG: ===== Git State Diagnosis ====="
        Write-Host "DEBUG: Current HEAD: $(git rev-parse HEAD 2>&1)"
        Write-Host "DEBUG: Current HEAD short: $(git rev-parse --short HEAD 2>&1)"
        Write-Host "DEBUG: Current branch: $(git rev-parse --abbrev-ref HEAD 2>&1)"
        Write-Host "DEBUG: Target branch: $BaseBranch"
        Write-Host "DEBUG: Target branch exists: $(git rev-parse --verify $BaseBranch 2>&1)"
        Write-Host "DEBUG: Remote branches: $(git branch -r | Select-Object -First 5)"

        # Use explicit merge-base for Azure DevOps PR compatibility
        # This pattern works correctly with refs/pull/*/merge checkout strategy
        Write-Host "DEBUG: Calculating merge-base between HEAD and $BaseBranch..."
        $mergeBase = git merge-base HEAD $BaseBranch 2>$null

        if (-not $mergeBase) {
            Write-Warning "Could not determine merge-base between HEAD and $BaseBranch, falling back to direct comparison"
            Write-Host "DEBUG: Merge-base FAILED. Trying direct comparison."
            Write-Host "DEBUG: Running: git diff --name-only --diff-filter=ACMRT $BaseBranch HEAD"
            $diffFiles = git diff --name-only --diff-filter=ACMRT $BaseBranch HEAD
            Write-Host "DEBUG: Direct diff returned $(@($diffFiles).Count) files"
            if ($diffFiles) {
                Write-Host "DEBUG: First 5 files from direct diff:"
                $diffFiles | Select-Object -First 5 | ForEach-Object { Write-Host "  - $_" }
            }
            return $diffFiles
        }

        Write-Host "DEBUG: Merge-base SUCCESS: $mergeBase"
        Write-Host "DEBUG: Merge-base short: $(git rev-parse --short $mergeBase 2>&1)"
        Write-Host "DEBUG: Running: git diff --name-only --diff-filter=ACMRT $mergeBase HEAD"
        $diffFiles = git diff --name-only --diff-filter=ACMRT $mergeBase HEAD
        Write-Host "DEBUG: Merge-base diff returned $(@($diffFiles).Count) files"

        if ($diffFiles -and @($diffFiles).Count -gt 0) {
            Write-Host "DEBUG: First 10 changed files:"
            $diffFiles | Select-Object -First 10 | ForEach-Object { Write-Host "  - $_" }
        }
        else {
            Write-Host "DEBUG: WARNING - No changed files found!"
            Write-Host "DEBUG: Checking commit range $mergeBase..HEAD:"
            $commits = git log --oneline "$mergeBase..HEAD" 2>$null
            if ($commits) {
                Write-Host "DEBUG: Commits found in range:"
                $commits | Select-Object -First 5 | ForEach-Object { Write-Host "  - $_" }
            }
            else {
                Write-Host "DEBUG: ERROR - No commits found between merge-base and HEAD"
                Write-Host "DEBUG: This means HEAD and merge-base are the same commit!"
            }

            # Try alternative: compare with remote tracking branch
            Write-Host "DEBUG: Attempting alternative comparison with refs/remotes/$BaseBranch..."
            $altBase = git merge-base HEAD "refs/remotes/$BaseBranch" 2>$null
            if ($altBase) {
                Write-Host "DEBUG: Alternative merge-base: $altBase"
                $altDiff = git diff --name-only --diff-filter=ACMRT $altBase HEAD
                Write-Host "DEBUG: Alternative diff returned $(@($altDiff).Count) files"
            }
        }
        Write-Host "DEBUG: ===== End Git State Diagnosis ====="

        return $diffFiles
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

# Get changed files for IaC detection
$changedFiles = Get-ChangedFileData -IncludeAll:$IncludeAllIaC -BaseBranch $BaseBranch

# Get all changed files for application detection if needed
$allChangedFiles = $changedFiles
if ($IncludeAllApplications -and $IncludeAllIaC) {
    # When both are requested, we need all changed files for application detection
    $allChangedFiles = Get-ChangedFileData -IncludeAll:$false -BaseBranch $BaseBranch
}

# Batch process subscription file checks
$subscriptionChanges = Test-ProviderRegChange -Files $changedFiles
$subscriptionShellChanges = $subscriptionChanges.Shell
$subscriptionPwshChanges = $subscriptionChanges.PowerShell

# Both categories (IaC and Applications) are ALWAYS scanned
# Switches control whether to return ALL folders or ONLY changed folders
Write-Debug "IncludeAllIaC: $IncludeAllIaC, IncludeAllApplications: $IncludeAllApplications"

# Process application changes - ALWAYS scan, switch controls filter
$applicationChanges = @{}
$appStructure = Get-ApplicationStructure -ApplicationPath $resolvedApplicationPath
if ($appStructure.Count -gt 0) {
    if ($IncludeAllApplications) {
        # When IncludeAllApplications flag is ON, return ALL applications
        $applicationChanges = @{}
        foreach ($appName in $appStructure.Keys) {
            $app = $appStructure[$appName]
            $applicationChanges[$appName] = @{
                directory    = $app.directory
                path         = $app.path
                services     = $app.services
                has_services = $app.has_services
            }
        }
    }
    else {
        # When IncludeAllApplications flag is OFF (default for PRs), return only applications with changes
        Write-Host "DEBUG: Application detection - allChangedFiles count: $($allChangedFiles.Count)"
        Write-Host "DEBUG: Application detection - relativeApplicationPath: $relativeApplicationPath"
        Write-Host "DEBUG: Application detection - resolvedApplicationPath: $resolvedApplicationPath"
        Write-Host "DEBUG: Application detection - appStructure count: $($appStructure.Count)"
        if ($allChangedFiles -and $allChangedFiles.Count -gt 0) {
            Write-Host "DEBUG: Calling Get-ApplicationChange..."
            Write-Host "DEBUG: First 5 changed files passed to Get-ApplicationChange:"
            $allChangedFiles | Select-Object -First 5 | ForEach-Object { Write-Host "  - $_" }
            $applicationChanges = Get-ApplicationChange -ChangedFiles $allChangedFiles -ApplicationStructure $appStructure -ApplicationRelativePath $relativeApplicationPath
            Write-Host "DEBUG: Get-ApplicationChange returned $($applicationChanges.Count) changed applications"
        }
        else {
            Write-Host "DEBUG: Skipping Get-ApplicationChange - no changed files"
        }
    }
}

# Performance improvement: Only run debug information if Verbose is enabled
if ($IncludeAllIaC -and $VerbosePreference -ne 'SilentlyContinue') {
    Write-Information "[DEBUG] Searching for all Terraform and Bicep files..." -InformationAction Continue
    $tfDebug = Get-ChildItem -Path src, blueprints -Recurse -File -Include *.tf, *.tfvars, *.tfstate, *.hcl -ErrorAction SilentlyContinue
    $bicepDebug = Get-ChildItem -Path src, blueprints -Recurse -File -Include *.bicep -ErrorAction SilentlyContinue

    Write-Information "Found $($tfDebug.Count) Terraform files and $($bicepDebug.Count) Bicep files" -InformationAction Continue

    # If no files found, check if directories exist
    if ($tfDebug.Count -eq 0 -and $bicepDebug.Count -eq 0) {
        $srcExists = Test-Path -Path "src"
        $blueprintsExists = Test-Path -Path "blueprints"
        Write-Information "Directory check: src exists: $srcExists, blueprints exists: $blueprintsExists" -InformationAction Continue
    }
}

# Process IaC changes - ALWAYS scan, switch controls filter
$tfFiles = $changedFiles | Where-Object { $_ -match '\.(tf|tfvars|tfstate|hcl)$' }
$bicepFiles = $changedFiles | Where-Object { $_ -match '\.bicep$' }

# Process paths in single batch operations
if ($tfFiles) {
    $tfPaths = Get-FilePathData -Paths $tfFiles
    if ($tfPaths.Count -gt 0) {
        $terraformHasChanges = $true

        # Detect dependent blueprints when components change
        $dependentBlueprints = @()

        foreach ($changedPath in $tfPaths) {
            # Check if changed file is in src/ (a component)
            if ($changedPath -match '^src/') {
                # Extract component path (e.g., "src/000-cloud/010-security-identity")
                $componentPath = $changedPath -replace '/terraform(/.*)?$', ''

                Write-Verbose "Checking for blueprints that depend on component: $componentPath"

                # Search all blueprint main.tf files for this component
                $blueprintMainFiles = Get-ChildItem -Path "$PSScriptRoot/../../blueprints/*/terraform/main.tf" -ErrorAction SilentlyContinue

                foreach ($blueprintFile in $blueprintMainFiles) {
                    $content = Get-Content $blueprintFile.FullName -Raw -ErrorAction SilentlyContinue

                    if ($content) {
                        # Check if blueprint references this component
                        # Pattern matches: source = "../../../src/000-cloud/010-security-identity/terraform"
                        $escapedComponentPath = [regex]::Escape($componentPath)
                        $pattern = "source\s*=\s*`"(\.\./)+$escapedComponentPath/terraform`""

                        if ($content -match $pattern) {
                            # Extract blueprint path (e.g., "blueprints/full-single-node-cluster")
                            $blueprintPath = $blueprintFile.Directory.Parent.FullName
                            $blueprintRelativePath = $blueprintPath -replace '.*[/\\]blueprints[/\\]', 'blueprints/'
                            $blueprintRelativePath = $blueprintRelativePath -replace '\\', '/'

                            Write-Verbose "  Found dependent blueprint: $blueprintRelativePath"
                            $dependentBlueprints += $blueprintRelativePath
                        }
                    }
                }
            }
        }

        # Combine direct changes and dependent blueprints, removing duplicates
        $allPaths = @($tfPaths) + @($dependentBlueprints) | Select-Object -Unique
        Write-Verbose "Total Terraform folders to test: $($allPaths.Count) (Direct: $($tfPaths.Count), Dependent: $($dependentBlueprints.Count))"

        $terraformFolders = Convert-PathsToJson -Paths $allPaths
    }
}

if ($bicepFiles) {
    $bicepPaths = Get-FilePathData -Paths $bicepFiles
    if ($bicepPaths.Count -gt 0) {
        $bicepHasChanges = $true

        # Detect dependent blueprints when components change
        $dependentBlueprints = @()

        foreach ($changedPath in $bicepPaths) {
            # Check if changed file is in src/ (a component)
            if ($changedPath -match '^src/') {
                # Extract component path (e.g., "src/000-cloud/010-security-identity")
                $componentPath = $changedPath -replace '/bicep(/.*)?$', ''

                Write-Verbose "Checking for blueprints that depend on component: $componentPath"

                # Search all blueprint main.bicep files for this component
                $blueprintMainFiles = Get-ChildItem -Path "$PSScriptRoot/../../blueprints/*/bicep/main.bicep" -ErrorAction SilentlyContinue

                foreach ($blueprintFile in $blueprintMainFiles) {
                    $content = Get-Content $blueprintFile.FullName -Raw -ErrorAction SilentlyContinue

                    if ($content) {
                        # Check if blueprint references this component
                        # Pattern matches: module ... '../../../src/000-cloud/010-security-identity/bicep/main.bicep'
                        $escapedComponentPath = [regex]::Escape($componentPath)
                        $pattern = "module\s+\w+\s+'(\.\./)+$escapedComponentPath/bicep/main\.bicep'"

                        if ($content -match $pattern) {
                            # Extract blueprint path (e.g., "blueprints/full-single-node-cluster")
                            $blueprintPath = $blueprintFile.Directory.Parent.FullName
                            $blueprintRelativePath = $blueprintPath -replace '.*[/\\]blueprints[/\\]', 'blueprints/'
                            $blueprintRelativePath = $blueprintRelativePath -replace '\\', '/'

                            Write-Verbose "  Found dependent blueprint: $blueprintRelativePath"
                            $dependentBlueprints += $blueprintRelativePath
                        }
                    }
                }
            }
        }

        # Combine direct changes and dependent blueprints, removing duplicates
        $allPaths = @($bicepPaths) + @($dependentBlueprints) | Select-Object -Unique
        Write-Verbose "Total Bicep folders to test: $($allPaths.Count) (Direct: $($bicepPaths.Count), Dependent: $($dependentBlueprints.Count))"

        $bicepFolders = Convert-PathsToJson -Paths $allPaths
    }
}

# Create the final JSON output with subscription (always included)
$jsonOutput = [PSCustomObject]@{
    subscription = [PSCustomObject]@{
        shell_changes      = $subscriptionShellChanges
        powershell_changes = $subscriptionPwshChanges
    }
}

$jsonOutput | Add-Member -MemberType NoteProperty -Name "terraform" -Value ([PSCustomObject]@{
        has_changes = [bool]$terraformHasChanges
        folders     = $terraformFolders
    })

$jsonOutput | Add-Member -MemberType NoteProperty -Name "bicep" -Value ([PSCustomObject]@{
        has_changes = [bool]$bicepHasChanges
        folders     = $bicepFolders
    })

$jsonOutput | Add-Member -MemberType NoteProperty -Name "applications" -Value ([PSCustomObject]@{
        has_changes = ($applicationChanges.Count -gt 0)
        folders     = $applicationChanges
    })

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
