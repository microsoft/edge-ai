# ApplicationBuilder.Helpers.psm1

# Explicit helpers module for application builder scripts

Set-StrictMode -Version Latest

# Initialize script-level variables
$script:VerboseLogging = $false

<#
.SYNOPSIS
    Safely gets a property value from an object, returning null if the property doesn't exist.

.DESCRIPTION
    Helper function to handle property access in strict mode. Checks if property exists
    before attempting to access it, preventing errors in Set-StrictMode -Version Latest.

.PARAMETER Object
    The object to get the property from.

.PARAMETER PropertyName
    The name of the property to retrieve.

.EXAMPLE
    $value = Get-SafeProperty $myObject 'build'
#>
function Get-SafeProperty {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [object]$Object,

        [Parameter(Mandatory = $true)]
        [string]$PropertyName
    )

    if ($Object.PSObject.Properties[$PropertyName]) {
        return $Object.$PropertyName
    }
    return $null
}

<#
.SYNOPSIS
    Writes a timestamped build log message.

.DESCRIPTION
    Outputs a formatted build message with timestamp prefix. Messages are displayed
    in cyan color unless verbose mode is enabled.

.PARAMETER Message
    The message to log.

.EXAMPLE
    Write-BuildLog "Starting build process"
    Writes a cyan-colored build log message with timestamp.
#>
function Write-BuildLog {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    process {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $formattedMessage = "[$timestamp] [BUILD] $Message"

        if ($VerbosePreference -eq 'Continue') {
            Write-Verbose $formattedMessage
        }

        [Console]::Error.WriteLine("{0}", $formattedMessage)
    }
}

<#
.SYNOPSIS
    Writes a timestamped debug message.

.DESCRIPTION
    Outputs a debug message with timestamp prefix. Messages are only displayed
    when debug preference is enabled or when verbose logging is active.

.PARAMETER Message
    The debug message to log.

.EXAMPLE
    Write-BuildDebug "Processing file: example.txt"
    Writes a debug message that is only visible in debug/verbose mode.
#>
function Write-BuildDebug {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    process {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Debug "[$timestamp] [BUILD:DEBUG] $Message"

        if ($VerbosePreference -eq 'Continue' -or $script:VerboseLogging) {
            Write-Verbose "[$timestamp] [BUILD:DEBUG] $Message"
        }
    }
}

<#
.SYNOPSIS
    Writes a timestamped informational message.

.DESCRIPTION
    Outputs an informational message with timestamp prefix. Messages are displayed
    in green color unless verbose mode is enabled.

.PARAMETER Message
    The informational message to log.

.EXAMPLE
    Write-Info "Configuration loaded successfully"
    Writes a green-colored informational message with timestamp.
#>
function Write-Info {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    process {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        $formattedMessage = "[$timestamp] [INFO] $Message"

        if ($VerbosePreference -eq 'Continue') {
            Write-Verbose $formattedMessage
        }

        [Console]::Error.WriteLine("{0}", $formattedMessage)
    }
}

<#
.SYNOPSIS
    Writes a timestamped warning message.

.DESCRIPTION
    Outputs a warning message with timestamp prefix using PowerShell's Write-Warning.

.PARAMETER Message
    The warning message to log.

.EXAMPLE
    Write-Warn "Configuration file not found, using defaults"
    Writes a warning message with timestamp.
#>
function Write-Warn {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message
    )

    process {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
        Write-Warning "[$timestamp] [BUILD] $Message"
    }
}

<#
.SYNOPSIS
    Writes a timestamped error message and terminates execution.

.DESCRIPTION
    Outputs an error message with timestamp prefix and throws an exception to
    terminate execution. Optionally includes a full ErrorRecord for detailed diagnostics.

.PARAMETER Message
    The error message to log.

.PARAMETER ErrorRecord
    Optional ErrorRecord containing detailed exception information.

.EXAMPLE
    Write-BuildError "Critical failure during build"
    Writes an error message and terminates execution.

.EXAMPLE
    try { $result = Do-Something } catch { Write-BuildError "Operation failed" -ErrorRecord $_ }
    Writes an error with full exception details and terminates.
#>
function Write-BuildError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$Message,

        [Parameter(Mandatory = $false)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    process {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

        if ($ErrorRecord) {
            Write-Error "[$timestamp] [BUILD:ERROR] $Message`n$($ErrorRecord.Exception.Message)`n$($ErrorRecord.ScriptStackTrace)" -ErrorAction Continue
            throw $ErrorRecord
        }
        else {
            Write-Error "[$timestamp] [BUILD:ERROR] $Message" -ErrorAction Continue
            throw $Message
        }
    }
}

<#
.SYNOPSIS
    Converts various input formats to Docker build argument list.

.DESCRIPTION
    Transforms hashtables, JSON strings, arrays, or simple values into a flat array
    of Docker build arguments in the format "--build-arg KEY=VALUE".

.PARAMETER InputArgs
    Input to convert. Can be hashtable, OrderedDictionary, JSON string, array, or scalar value.

.OUTPUTS
    System.Object[]
    Array of strings formatted as Docker build arguments.

.EXAMPLE
    ConvertTo-BuildArgList @{ VERSION="1.0"; ENV="prod" }
    Returns: @("--build-arg", "VERSION=1.0", "--build-arg", "ENV=prod")

.EXAMPLE
    ConvertTo-BuildArgList '{"VERSION":"1.0","ENV":"prod"}'
    Parses JSON and returns formatted build arguments.
#>
function ConvertTo-BuildArgList {
    [CmdletBinding()]
    [OutputType([System.Object[]])]
    param(
        [Parameter(Mandatory = $false)]
        [AllowNull()]
        [AllowEmptyCollection()]
        [object]$InputArgs
    )

    process {
        if ($null -eq $InputArgs) {
            return @()
        }

        $result = @()

        if ($InputArgs -is [hashtable] -or $InputArgs -is [System.Collections.Specialized.OrderedDictionary]) {
            foreach ($key in $InputArgs.Keys) {
                $value = $InputArgs[$key]
                $result += "--build-arg"
                $result += "$key=$value"
            }
            return $result
        }

        if ($InputArgs -is [string]) {
            try {
                $parsed = $InputArgs | ConvertFrom-Json -AsHashtable -ErrorAction Stop
                foreach ($key in $parsed.Keys) {
                    $value = $parsed[$key]
                    $result += "--build-arg"
                    $result += "$key=$value"
                }
                return $result
            }
            catch {
                Write-Warn "Failed to parse input as JSON: $_"
                if (-not [string]::IsNullOrWhiteSpace($InputArgs)) {
                    return @($InputArgs)
                }
                return @()
            }
        }

        if ($InputArgs -is [array] -or $InputArgs -is [System.Collections.IEnumerable]) {
            foreach ($item in $InputArgs) {
                if ($null -ne $item -and -not [string]::IsNullOrWhiteSpace($item.ToString())) {
                    $result += $item.ToString()
                }
            }
            return $result
        }

        if (-not [string]::IsNullOrWhiteSpace($InputArgs.ToString())) {
            return @($InputArgs.ToString())
        }

        return @()
    }
}

function Get-CommonBuildArgument {
    <#
    .SYNOPSIS
    Builds a normalized list of Docker build arguments shared across services.

    .DESCRIPTION
    Generates common build argument key/value pairs using build metadata and
    merges any caller-supplied build arguments. Returns values in "KEY=VALUE"
    format so callers can prepend "--build-arg" as needed.

    .PARAMETER AppName
    Name of the current application.

    .PARAMETER BuildId
    Unique build identifier used for tagging.

    .PARAMETER BuildEnv
    Build environment descriptor (dev, staging, prod).

    .PARAMETER CommitSha
    Git commit SHA for traceability.

    .PARAMETER BaseImageTag
    Tag for the base image; defaults to BuildId when empty.

    .PARAMETER DockerBuildArgs
    Additional build arguments or configuration supplied by the caller.

    .OUTPUTS
    System.String[]
    List of formatted build arguments without the "--build-arg" prefix.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)][string]$AppName,
        [Parameter(Mandatory = $true)][string]$BuildId,
        [Parameter(Mandatory = $true)][string]$BuildEnv,
        [Parameter(Mandatory = $true)][string]$CommitSha,
        [Parameter()][string]$BaseImageTag,
        [Parameter()][object]$DockerBuildArgs
    )

    process {
        $resolvedBaseTag = if ([string]::IsNullOrWhiteSpace($BaseImageTag)) { $BuildId } else { $BaseImageTag }

        $arguments = [System.Collections.Generic.List[string]]::new()
        $arguments.Add("APP_NAME=$AppName") | Out-Null
        $arguments.Add("BUILD_ID=$BuildId") | Out-Null
        $arguments.Add("BUILD_ENVIRONMENT=$BuildEnv") | Out-Null
        $arguments.Add("COMMIT_SHA=$CommitSha") | Out-Null
        $arguments.Add("BASE_IMAGE_TAG=$resolvedBaseTag") | Out-Null

        $additionalSource = $null

        if ($null -ne $DockerBuildArgs) {
            if ($DockerBuildArgs -is [System.Collections.IDictionary]) {
                foreach ($key in @('buildArgs', 'BuildArgs', 'args', 'Args')) {
                    if ($DockerBuildArgs.Contains($key)) {
                        $additionalSource = $DockerBuildArgs[$key]
                        break
                    }
                }

                if ($null -eq $additionalSource) {
                    $nonOptionKeys = @($DockerBuildArgs.Keys | Where-Object { $_ -notin @('options', 'Options', 'flags', 'Flags', 'additionalArgs', 'AdditionalArgs') })
                    if ($nonOptionKeys.Count -gt 0) {
                        $table = @{}
                        foreach ($name in $nonOptionKeys) {
                            $table[$name] = $DockerBuildArgs[$name]
                        }
                        if ($table.Count -gt 0) {
                            $additionalSource = $table
                        }
                    }
                }
            }
            elseif ($DockerBuildArgs -is [PSCustomObject]) {
                foreach ($key in @('buildArgs', 'BuildArgs', 'args', 'Args')) {
                    $prop = $DockerBuildArgs.PSObject.Properties[$key]
                    if ($null -ne $prop) {
                        $additionalSource = $prop.Value
                        break
                    }
                }

                if ($null -eq $additionalSource) {
                    $allProps = $DockerBuildArgs.PSObject.Properties | Where-Object { $_.Name -notin @('options', 'Options', 'flags', 'Flags', 'additionalArgs', 'AdditionalArgs') }
                    if ($allProps.Count -gt 0) {
                        $table = @{}
                        foreach ($prop in $allProps) {
                            $table[$prop.Name] = $prop.Value
                        }
                        if ($table.Count -gt 0) {
                            $additionalSource = $table
                        }
                    }
                }
            }
            else {
                $additionalSource = $DockerBuildArgs
            }
        }

        if ($null -ne $additionalSource) {
            if ($additionalSource -is [System.Collections.IDictionary]) {
                foreach ($key in $additionalSource.Keys) {
                    if ([string]::IsNullOrWhiteSpace($key)) {
                        continue
                    }
                    $value = $additionalSource[$key]
                    $arguments.Add("$key=$value") | Out-Null
                }
            }
            elseif ($additionalSource -is [System.Collections.IEnumerable] -and -not ($additionalSource -is [string])) {
                foreach ($item in $additionalSource) {
                    if ($null -eq $item) {
                        continue
                    }
                    $arguments.Add($item.ToString()) | Out-Null
                }
            }
            elseif (-not [string]::IsNullOrWhiteSpace($additionalSource.ToString())) {
                $arguments.Add($additionalSource.ToString()) | Out-Null
            }
        }

        $unique = New-Object System.Collections.Generic.HashSet[string]
        $ordered = [System.Collections.Generic.List[string]]::new()

        foreach ($item in $arguments) {
            if ([string]::IsNullOrWhiteSpace($item)) {
                continue
            }

            if ($unique.Add($item)) {
                $ordered.Add($item) | Out-Null
            }
        }

        return $ordered.ToArray()
    }
}

function Get-AdditionalDockerBuildArgument {
    <#
    .SYNOPSIS
    Extracts supplemental docker build options from configuration objects.

    .DESCRIPTION
    Normalizes docker build option sources (arrays, strings, dictionaries) and
    ensures optional verbose progress flags are appended when requested.

    .PARAMETER DockerBuildArgs
    Configuration object potentially containing additional docker build options.

    .PARAMETER EnableVerboseProgress
    Adds "--progress plain" if verbose output is desired and not already present.

    .OUTPUTS
    System.String[]
    List of docker build options such as "--progress", "plain", "--no-cache".
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter()][object]$DockerBuildArgs,
        [Parameter()][switch]$EnableVerboseProgress
    )

    process {
        $options = [System.Collections.Generic.List[string]]::new()

        $rawOptions = $null

        if ($null -ne $DockerBuildArgs) {
            if ($DockerBuildArgs -is [System.Collections.IDictionary]) {
                foreach ($key in @('options', 'Options', 'flags', 'Flags', 'additionalArgs', 'AdditionalArgs')) {
                    if ($DockerBuildArgs.Contains($key)) {
                        $rawOptions = $DockerBuildArgs[$key]
                        break
                    }
                }
            }
            elseif ($DockerBuildArgs -is [PSCustomObject]) {
                foreach ($key in @('options', 'Options', 'flags', 'Flags', 'additionalArgs', 'AdditionalArgs')) {
                    $prop = $DockerBuildArgs.PSObject.Properties[$key]
                    if ($null -ne $prop) {
                        $rawOptions = $prop.Value
                        break
                    }
                }
            }
            elseif ($DockerBuildArgs -is [System.Collections.IEnumerable] -and -not ($DockerBuildArgs -is [string])) {
                $rawOptions = $DockerBuildArgs
            }
            else {
                $rawOptions = $DockerBuildArgs
            }
        }

        if ($null -ne $rawOptions) {
            if ($rawOptions -is [string]) {
                foreach ($token in ($rawOptions -split '\s+' | Where-Object { $_ })) {
                    $options.Add($token) | Out-Null
                }
            }
            elseif ($rawOptions -is [System.Collections.IDictionary]) {
                foreach ($entry in $rawOptions.GetEnumerator()) {
                    if ([string]::IsNullOrWhiteSpace($entry.Key)) {
                        continue
                    }
                    $options.Add($entry.Key) | Out-Null
                    if ($null -ne $entry.Value) {
                        if ($entry.Value -is [System.Collections.IEnumerable] -and -not ($entry.Value -is [string])) {
                            foreach ($item in $entry.Value) {
                                if ($null -ne $item -and -not [string]::IsNullOrWhiteSpace($item.ToString())) {
                                    $options.Add($item.ToString()) | Out-Null
                                }
                            }
                        }
                        else {
                            $options.Add($entry.Value.ToString()) | Out-Null
                        }
                    }
                }
            }
            elseif ($rawOptions -is [System.Collections.IEnumerable]) {
                foreach ($item in $rawOptions) {
                    if ($null -eq $item) {
                        continue
                    }

                    if ($item -is [System.Collections.IEnumerable] -and -not ($item -is [string])) {
                        foreach ($nested in $item) {
                            if ($null -ne $nested -and -not [string]::IsNullOrWhiteSpace($nested.ToString())) {
                                $options.Add($nested.ToString()) | Out-Null
                            }
                        }
                    }
                    else {
                        $options.Add($item.ToString()) | Out-Null
                    }
                }
            }
            else {
                $options.Add($rawOptions.ToString()) | Out-Null
            }
        }

        if ($EnableVerboseProgress) {
            $hasProgress = $false
            for ($index = 0; $index -lt $options.Count; $index++) {
                if ($options[$index] -eq '--progress') {
                    $hasProgress = $true
                    break
                }
            }

            if (-not $hasProgress) {
                $options.Add('--progress') | Out-Null
                $options.Add('plain') | Out-Null
            }
        }

        $unique = New-Object System.Collections.Generic.HashSet[string]
        $ordered = [System.Collections.Generic.List[string]]::new()

        foreach ($item in $options) {
            if ([string]::IsNullOrWhiteSpace($item)) {
                continue
            }

            if ($unique.Add($item)) {
                $ordered.Add($item) | Out-Null
            }
        }

        return $ordered.ToArray()
    }
}

function Resolve-AppRelativePath {
    <#
    .SYNOPSIS
    Resolves a path relative to the application directory.

    .DESCRIPTION
    Converts a relative path to an absolute path using the provided base directory.
    Paths that are already rooted are returned as full paths.

    .PARAMETER BasePath
    Root directory of the application.

    .PARAMETER RelativePath
    Relative or absolute path to resolve.

    .OUTPUTS
    System.String
    Absolute path derived from the supplied values.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)][string]$BasePath,
        [Parameter(Mandatory = $true)][string]$RelativePath
    )

    process {
        if ([string]::IsNullOrWhiteSpace($RelativePath)) {
            return $BasePath
        }

        if ([System.IO.Path]::IsPathRooted($RelativePath)) {
            try {
                return [System.IO.Path]::GetFullPath($RelativePath)
            }
            catch {
                return $RelativePath
            }
        }

        $combined = Join-Path -Path $BasePath -ChildPath $RelativePath

        try {
            return [System.IO.Path]::GetFullPath($combined)
        }
        catch {
            return $combined
        }
    }
}

function Get-ServiceBuildTag {
    <#
    .SYNOPSIS
    Generates image tags for a service based on build metadata.

    .DESCRIPTION
    Creates deterministic tag values using build identifiers, environment, and commit
    SHA, and merges any explicit service tags defined in metadata.

    .PARAMETER ServiceMetadata
    Service metadata object describing the build target.

    .PARAMETER AppName
    Application name for namespace composition.

    .PARAMETER Registry
    Target container registry or "local" for in-place builds.

    .PARAMETER BuildId
    Unique build identifier used for tagging.

    .PARAMETER BuildEnv
    Build environment descriptor.

    .PARAMETER CommitSha
    Git commit SHA used for provenance tagging.

    .OUTPUTS
    System.String[]
    Collection of unique image tags for the service.
    #>
    [CmdletBinding()]
    [OutputType([string[]])]
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$ServiceMetadata,
        [Parameter(Mandatory = $true)][string]$AppName,
        [Parameter(Mandatory = $true)][string]$Registry,
        [Parameter(Mandatory = $true)][string]$BuildId,
        [Parameter(Mandatory = $true)][string]$BuildEnv,
        [Parameter(Mandatory = $true)][string]$CommitSha
    )

    process {
        $registryRoot = if ([string]::IsNullOrWhiteSpace($Registry) -or $Registry -eq 'local') { '' } else { $Registry.TrimEnd('/') }

        $serviceName = $ServiceMetadata.Name
        $repository = $null

        if ($ServiceMetadata.PSObject.Properties['Repository'] -and -not [string]::IsNullOrWhiteSpace($ServiceMetadata.Repository)) {
            $repository = $ServiceMetadata.Repository
        }
        elseif ($ServiceMetadata.PSObject.Properties['ImageName'] -and -not [string]::IsNullOrWhiteSpace($ServiceMetadata.ImageName)) {
            $imageName = $ServiceMetadata.ImageName.Trim()
            $repository = ($imageName -split ':', 2)[0]
        }

        if ([string]::IsNullOrWhiteSpace($repository)) {
            $repository = "$AppName/$serviceName"
        }

        $fullyQualifiedRepository = if ([string]::IsNullOrWhiteSpace($registryRoot)) {
            $repository
        }
        elseif ($repository.StartsWith("$registryRoot/", [System.StringComparison]::OrdinalIgnoreCase)) {
            $repository
        }
        else {
            "$registryRoot/$repository"
        }

        $normalizedBuildId = ConvertTo-DockerTagValue -Source $BuildId -Fallback 'build'
        Test-DockerTagValue -Value $normalizedBuildId -Name 'BuildId'

        $normalizedEnvironment = ConvertTo-DockerTagValue -Source $BuildEnv -Fallback 'environment'
        Test-DockerTagValue -Value $normalizedEnvironment -Name 'BuildEnv'

        $commitFragmentLength = [Math]::Min(12, $CommitSha.Length)
        $commitFragment = $CommitSha.Substring(0, $commitFragmentLength)
        $normalizedCommit = ConvertTo-DockerTagValue -Source $commitFragment -Fallback 'commit'
        Test-DockerTagValue -Value $normalizedCommit -Name 'CommitSha'

        $defaultTags = @(
            "${fullyQualifiedRepository}:$normalizedBuildId",
            "${fullyQualifiedRepository}:$normalizedEnvironment",
            "${fullyQualifiedRepository}:$normalizedCommit"
        )

        $customTags = @()
        foreach ($propName in @('Tags', 'ImageTags', 'AdditionalTags')) {
            $prop = $ServiceMetadata.PSObject.Properties[$propName]
            if ($null -eq $prop) {
                continue
            }

            $value = $prop.Value
            if ($null -eq $value) {
                continue
            }

            if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                foreach ($item in $value) {
                    if (-not [string]::IsNullOrWhiteSpace($item)) {
                        $customTags += $item.ToString()
                    }
                }
            }
            elseif (-not [string]::IsNullOrWhiteSpace($value.ToString())) {
                $customTags += $value.ToString()
            }
        }

        $allTags = $defaultTags + $customTags
        $unique = New-Object System.Collections.Generic.HashSet[string]
        $ordered = [System.Collections.Generic.List[string]]::new()

        foreach ($tag in $allTags) {
            if ([string]::IsNullOrWhiteSpace($tag)) {
                continue
            }

            $resolvedTag = $tag.Trim()

            if ($resolvedTag.Contains(':')) {
                $tagParts = $resolvedTag.Split(':', 2)
                $tagValue = ConvertTo-DockerTagValue -Source $tagParts[1] -Fallback 'tag'
                Test-DockerTagValue -Value $tagValue -Name 'CustomTag'
                $resolvedTag = "{0}:{1}" -f $tagParts[0], $tagValue
            }
            else {
                $tagValue = ConvertTo-DockerTagValue -Source $resolvedTag -Fallback 'tag'
                Test-DockerTagValue -Value $tagValue -Name 'CustomTag'
                $resolvedTag = "${fullyQualifiedRepository}:$tagValue"
            }

            if ($unique.Add($resolvedTag)) {
                $ordered.Add($resolvedTag) | Out-Null
            }
        }

        return $ordered.ToArray()
    }
}

<#
.SYNOPSIS
    Tests whether a command exists in the current environment.

.DESCRIPTION
    Checks if a command is available by attempting to retrieve it using Get-Command.

.PARAMETER CommandName
    The name of the command to check.

.OUTPUTS
    System.Boolean
    True if command exists, false otherwise.

.EXAMPLE
    Test-CommandExist "docker"
    Returns $true if Docker is installed and available on PATH.
#>
function Test-CommandExist {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$CommandName
    )

    process {
        $null -ne (Get-Command $CommandName -ErrorAction SilentlyContinue)
    }
}

<#
.SYNOPSIS
    Generates a Docker Compose project name from application name or path.

.DESCRIPTION
    Creates a normalized Docker Compose project name by sanitizing the application
    name or deriving it from the application path. Ensures the name follows Docker
    Compose naming conventions (lowercase, alphanumeric with hyphens).

.PARAMETER AppName
    The application name to use as the base for the project name.

.PARAMETER AppPath
    The application path to derive the project name from if AppName is not provided.

.OUTPUTS
    String. The normalized Docker Compose project name.

.EXAMPLE
    Get-ComposeProjectName -AppName "MyApp"
    Returns "myapp"

.EXAMPLE
    Get-ComposeProjectName -AppPath "/path/to/500-my-application"
    Returns "my-application"
#>
function Get-ComposeProjectName {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)][string]$AppName,
        [Parameter(Mandatory = $false)][string]$AppPath
    )

    process {
        $candidates = [System.Collections.Generic.List[string]]::new()

        if (-not [string]::IsNullOrWhiteSpace($AppName)) {
            $candidates.Add($AppName) | Out-Null
        }

        if (-not [string]::IsNullOrWhiteSpace($AppPath)) {
            try {
                $leaf = Split-Path -Path $AppPath -Leaf
            }
            catch {
                $leaf = $null
            }

            if (-not [string]::IsNullOrWhiteSpace($leaf)) {
                $candidates.Add($leaf) | Out-Null
            }
        }

        if ($candidates.Count -eq 0) {
            $candidates.Add('app') | Out-Null
        }

        $base = $null
        foreach ($candidate in $candidates) {
            if ([string]::IsNullOrWhiteSpace($candidate)) {
                continue
            }

            $base = $candidate
            break
        }

        if ([string]::IsNullOrWhiteSpace($base)) {
            $base = 'app'
        }

        $normalized = $base.ToLowerInvariant()
        $normalized = ($normalized -replace '[^a-z0-9_.-]', '-').Trim('-')

        if ([string]::IsNullOrWhiteSpace($normalized)) {
            $normalized = 'app'
        }

        if ($normalized -notmatch '^[a-z0-9]') {
            $normalized = "app-$normalized"
        }

        return $normalized
    }
}

<#
.SYNOPSIS
    Tests whether a Docker image exists locally.

.DESCRIPTION
    Checks if the specified Docker image exists in the local Docker daemon by
    using docker image inspect. Returns true if the image exists, false otherwise.

.PARAMETER ImageReference
    The Docker image reference to check (e.g., "myapp:latest" or "registry/myapp:v1.0").

.OUTPUTS
    Boolean. True if the image exists locally, false otherwise.

.EXAMPLE
    Test-DockerImageExist -ImageReference "nginx:latest"
    Returns $true if nginx:latest exists locally.

.EXAMPLE
    if (Test-DockerImageExist -ImageReference "myapp:dev") {
        Write-Host "Image exists"
    }
#>
function Test-DockerImageExist {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory = $true)][string]$ImageReference
    )

    process {
        if ([string]::IsNullOrWhiteSpace($ImageReference)) {
            return $false
        }

        try {
            $null = & docker image inspect $ImageReference 2>$null
            return ($LASTEXITCODE -eq 0)
        }
        catch {
            return $false
        }
    }
}

<#
.SYNOPSIS
    Finds the root directory of the project.

.DESCRIPTION
    Traverses up the directory tree from the starting path to locate the project root,
    identified by the presence of .git, Cargo.toml, or package.json.

.PARAMETER StartPath
    The directory to start searching from. Defaults to current directory.

.OUTPUTS
    System.String
    The absolute path to the project root, or $null if not found.

.EXAMPLE
    Get-ProjectRootPath
    Returns the project root path starting from current directory.

.EXAMPLE
    Get-ProjectRootPath -StartPath "/path/to/subdirectory"
    Returns the project root path starting from specified directory.
#>
function Get-ProjectRootPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $false)]
        [string]$StartPath = $PWD.Path
    )

    process {
        $currentPath = $StartPath
        $maxDepth = 10
        $depth = 0

        while ($depth -lt $maxDepth) {
            $gitPath = Join-Path $currentPath ".git"
            $cargoPath = Join-Path $currentPath "Cargo.toml"
            $packagePath = Join-Path $currentPath "package.json"

            if ((Test-Path $gitPath) -or (Test-Path $cargoPath) -or (Test-Path $packagePath)) {
                return $currentPath
            }

            $parent = Split-Path $currentPath -Parent
            if ([string]::IsNullOrEmpty($parent) -or $parent -eq $currentPath) {
                break
            }

            $currentPath = $parent
            $depth++
        }

        return $null
    }
}

<#
.SYNOPSIS
    Formats byte count as human-readable file size.

.DESCRIPTION
    Converts a byte count to a human-readable string with appropriate unit
    (GB, MB, KB, or bytes).

.PARAMETER Bytes
    The number of bytes to format.

.OUTPUTS
    System.String
    Formatted file size string with unit.

.EXAMPLE
    Format-FileSize 1048576
    Returns "1.00 MB"

.EXAMPLE
    Format-FileSize 1536
    Returns "1.50 KB"
#>
function Format-FileSize {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [long]$Bytes
    )

    process {
        if ($Bytes -ge 1GB) {
            return "{0:N2} GB" -f ($Bytes / 1GB)
        }
        elseif ($Bytes -ge 1MB) {
            return "{0:N2} MB" -f ($Bytes / 1MB)
        }
        elseif ($Bytes -ge 1KB) {
            return "{0:N2} KB" -f ($Bytes / 1KB)
        }
        else {
            return "{0} bytes" -f $Bytes
        }
    }
}

<#
.SYNOPSIS
    Converts a string to a filesystem-safe filename.

.DESCRIPTION
    Replaces invalid filename characters with a safe replacement character,
    ensuring the resulting string can be used as a filename.

.PARAMETER InputString
    The string to convert to a safe filename.

.PARAMETER Replacement
    The character to use as replacement for invalid characters. Defaults to underscore (_).

.OUTPUTS
    System.String
    Sanitized filename-safe string.

.EXAMPLE
    ConvertTo-SafeFileName "my:file*name?.txt"
    Returns "my_file_name_.txt"

.EXAMPLE
    ConvertTo-SafeFileName "report|summary" -Replacement "-"
    Returns "report-summary"
#>
function ConvertTo-SafeFileName {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InputString,

        [Parameter(Mandatory = $false)]
        [string]$Replacement = "_"
    )

    process {
        $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
        $result = $InputString

        foreach ($char in $invalidChars) {
            $result = $result.Replace($char.ToString(), $Replacement)
        }

        return $result
    }
}

<#
.SYNOPSIS
    Normalizes arbitrary input into a Docker tag-safe string.

.DESCRIPTION
    Converts the provided source string into a lowercase Docker tag value by replacing
    whitespace and invalid characters, trimming length, and prepending a safe prefix
    when required. Falls back to a supplied default when normalization produces an
    empty value.

.PARAMETER Source
    The string to normalize into a Docker tag-safe value.

.PARAMETER Fallback
    Value to return when Source is empty or normalizes to an empty string. Default is "value".

.OUTPUTS
    System.String
    Docker tag compatible value.

.EXAMPLE
    ConvertTo-DockerTagValue -Source "Release Candidate #1" -Fallback "rc"
    Returns "release-candidate-1".
#>
function ConvertTo-DockerTagValue {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter()][string]$Source,
        [Parameter()][ValidateNotNullOrEmpty()][string]$Fallback = "value"
    )

    process {
        if ([string]::IsNullOrWhiteSpace($Source)) {
            return $Fallback
        }

        $normalized = $Source.ToLowerInvariant()
        $normalized = [Regex]::Replace($normalized, '\s+', '-')
        $normalized = [Regex]::Replace($normalized, '[^a-z0-9_.-]', '-')
        $normalized = [Regex]::Replace($normalized, '[-]{2,}', '-')
        $normalized = $normalized.Trim('-')

        if ([string]::IsNullOrWhiteSpace($normalized)) {
            return $Fallback
        }

        if ($normalized.Length -gt 128) {
            $normalized = $normalized.Substring(0, 128)
        }

        if ($normalized[0] -match '[^a-z0-9]') {
            $normalized = "a$normalized"
            if ($normalized.Length -gt 128) {
                $normalized = $normalized.Substring(0, 128)
            }
        }

        return $normalized
    }
}

<#
.SYNOPSIS
    Validates that a string conforms to Docker tag requirements.

.DESCRIPTION
    Ensures the supplied value matches Docker tag character and length constraints.
    Throws if the value is invalid so callers can surface meaningful tag errors.

.PARAMETER Value
    Candidate Docker tag value to validate.

.PARAMETER Name
    Logical name of the value being validated, used for error messaging context.

.EXAMPLE
    Test-DockerTagValue -Value "build-2025-10-08" -Name "BuildId"
    Confirms the tag is valid or throws if it isn't.
#>
function Test-DockerTagValue {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)][string]$Value,
        [Parameter(Mandatory = $true)][string]$Name
    )

    process {
        if ($Value.Length -gt 128 -or $Value -notmatch '^[a-z0-9][a-z0-9_.-]{0,127}$') {
            throw "${Name} contains invalid characters for Docker tags: $Value"
        }
    }
}

<#
.SYNOPSIS
    Executes a script block with retry logic.

.DESCRIPTION
    Attempts to execute a script block multiple times with exponential backoff,
    retrying on failure until maximum attempts is reached.

.PARAMETER ScriptBlock
    The script block to execute.

.PARAMETER MaxAttempts
    Maximum number of execution attempts. Defaults to 3.

.PARAMETER DelaySeconds
    Number of seconds to wait between retry attempts. Defaults to 5.

.PARAMETER OperationDescription
    Descriptive name for the operation, used in logging. Defaults to "Operation".

.OUTPUTS
    System.Object
    The result of the script block if successful.

.EXAMPLE
    Invoke-WithRetry { Invoke-WebRequest "https://example.com/api" } -MaxAttempts 5
    Retries web request up to 5 times with default delay.

.EXAMPLE
    Invoke-WithRetry { Test-Connection "server" } -DelaySeconds 10 -OperationDescription "Server ping"
    Retries with 10 second delay and custom operation name.
#>
function Invoke-WithRetry {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [scriptblock]$ScriptBlock,

        [Parameter(Mandatory = $false)]
        [int]$MaxAttempts = 3,

        [Parameter(Mandatory = $false)]
        [int]$DelaySeconds = 5,

        [Parameter(Mandatory = $false)]
        [string]$OperationDescription = "Operation"
    )

    process {
        $attempt = 1
        $lastError = $null

        while ($attempt -le $MaxAttempts) {
            try {
                Write-BuildDebug "$OperationDescription - Attempt $attempt of $MaxAttempts"
                $result = & $ScriptBlock
                Write-BuildDebug "$OperationDescription succeeded on attempt $attempt"
                return $result
            }
            catch {
                $lastError = $_
                Write-Warn "$OperationDescription failed on attempt $attempt`: ${_}"

                if ($attempt -lt $MaxAttempts) {
                    Write-BuildDebug "Waiting $DelaySeconds seconds before retry..."
                    Start-Sleep -Seconds $DelaySeconds
                }

                $attempt++
            }
        }

        Write-BuildError "$OperationDescription failed after $MaxAttempts attempts" -ErrorRecord $lastError
    }
}

<#
.SYNOPSIS
    Creates a new build context object with all build parameters.

.DESCRIPTION
    Initializes a context object containing all build-related parameters and configuration
    needed throughout the build process. This context object is passed to other build functions.

.PARAMETER AppPath
    Path to the application directory.

.PARAMETER AppName
    Name of the application.

.PARAMETER Registry
    Container registry URL.

.PARAMETER BuildId
    Unique build identifier.

.PARAMETER BuildEnv
    Build environment (dev, staging, prod).

.PARAMETER CommitSha
    Git commit SHA.

.PARAMETER BaseImageTag
    Base image tag for multi-stage builds.

.PARAMETER DockerBuildArgs
    Docker build arguments as hashtable.

.PARAMETER PushImages
    Whether to push images to registry.

.PARAMETER DryRun
    Whether to run in dry-run mode.

.OUTPUTS
    PSCustomObject
    Returns a context object with nested properties matching module expectations.

.EXAMPLE
    $context = New-BuildContext -AppPath "./app" -AppName "myapp" -BuildId "123" -BuildEnv "dev" -CommitSha "abc"
    Creates a new build context with the specified parameters.
#>
function New-BuildContext {
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'Low')]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [string]$AppPath,

        [Parameter(Mandatory = $true)]
        [string]$AppName,

        [Parameter(Mandatory = $false)]
        [string]$Registry = "local",

        [Parameter(Mandatory = $true)]
        [string]$BuildId,

        [Parameter(Mandatory = $true)]
        [string]$BuildEnv,

        [Parameter(Mandatory = $true)]
        [string]$CommitSha,

        [Parameter(Mandatory = $false)]
        [string]$BaseImageTag = "",

        [Parameter(Mandatory = $false)]
        [object]$DockerBuildArgs = $null,

        [Parameter(Mandatory = $false)]
        [switch]$PushImages,

        [Parameter(Mandatory = $false)]
        [switch]$DryRun
    )

    process {
        if (-not $PSCmdlet.ShouldProcess("app '$AppName'", "Initialize build context")) {
            return $null
        }

        $resolvedRegistry = if ([string]::IsNullOrWhiteSpace($Registry)) { 'local' } else { $Registry }
        $resolvedBaseImageTag = if ([string]::IsNullOrWhiteSpace($BaseImageTag)) { $BuildId } else { $BaseImageTag }
        $dryRunEnabled = $DryRun.IsPresent
        $pushEnabled = $PushImages.IsPresent

        $context = [PSCustomObject]@{
            App             = [PSCustomObject]@{
                Path            = $AppPath
                Name            = $AppName
                BuildId         = $BuildId
                Environment     = $BuildEnv
                CommitSha       = $CommitSha
                BaseImageTag    = $resolvedBaseImageTag
                DockerBuildArgs = $DockerBuildArgs
                Registry        = $resolvedRegistry
                DryRun          = $dryRunEnabled
                PushImages      = $pushEnabled
            }
            DependencyAudit = [PSCustomObject]@{
                Results = @()
                Summary = $null
            }
            Build           = [PSCustomObject]@{
                Successful = @()
                Failed     = @()
                Results    = @()
                Duration   = 0
            }
            Compose         = [PSCustomObject]@{
                Available         = $false
                Executable        = $null
                ArgsPrefix        = @()
                ManifestFiles     = @()
                PrimaryFile       = $null
                DetectedServices  = @()
                BuildableServices = @()
                ServiceMetadata   = @()
                ProjectName       = (Get-ComposeProjectName -AppName $AppName -AppPath $AppPath)
            }
            Security        = [PSCustomObject]@{
                Enabled  = $false
                Results  = @()
                Passed   = @()
                Failed   = @()
                Duration = 0
                Reports  = @()
            }
            Flags           = [PSCustomObject]@{
                PushImages = $pushEnabled
                DryRun     = $dryRunEnabled
            }
            Output          = [PSCustomObject]@{
                Artifacts = @()
            }
        }

        return $context
    }
}

<#
.SYNOPSIS
    Validates build context parameters.

.DESCRIPTION
    Checks that all required build context parameters are present and valid.
    Validates both top-level containers and nested application properties.

.PARAMETER Context
    The build context object to validate.

.EXAMPLE
    Test-Parameter -Context $context
    Validates the build context parameters.
#>
function Test-Parameter {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Context
    )

    process {
        # Validate top-level containers exist
        $requiredContainers = @('App', 'Build', 'DependencyAudit', 'Compose', 'Flags')
        foreach ($container in $requiredContainers) {
            if ($null -eq $Context.$container) {
                Write-BuildError "Required container '$container' is missing from build context"
            }
        }

        # Validate required App properties
        $requiredAppProps = @{
            'Path'        = 'Application path'
            'Name'        = 'Application name'
            'BuildId'     = 'Build identifier'
            'Environment' = 'Build environment'
            'CommitSha'   = 'Commit SHA'
        }

        foreach ($prop in $requiredAppProps.Keys) {
            if ([string]::IsNullOrWhiteSpace($Context.App.$prop)) {
                Write-BuildError "Required App property '$prop' ($($requiredAppProps[$prop])) is missing or empty"
            }
        }
    }
}

<#
.SYNOPSIS
    Checks for required dependencies.

.DESCRIPTION
    Verifies that required tools and dependencies are available in the environment.

.PARAMETER Context
    The build context PSCustomObject.

.EXAMPLE
    Test-Dependency -Context $context
    Checks for required build dependencies.
#>
function Test-Dependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Context
    )

    process {
        # Check for docker
        if (-not (Test-CommandExist 'docker')) {
            Write-BuildError "Docker is not installed or not in PATH"
        }

        # Check if AppPath exists
        if (-not (Test-Path $Context.App.Path)) {
            Write-BuildError "Application path does not exist: $($Context.App.Path)"
        }
    }
}

<#
.SYNOPSIS
    Initializes Rust registry configuration.

.DESCRIPTION
    Configures Cargo registry settings for Azure IoT Operations packages if building Rust applications.

.PARAMETER Context
    The build context PSCustomObject.

.EXAMPLE
    Initialize-RustRegistryConfiguration -Context $context
    Configures Rust registry for the build.
#>
function Initialize-RustRegistryConfiguration {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Context
    )

    process {
        # Check if Cargo.toml exists in the app path
        $cargoToml = Join-Path $Context.App.Path "Cargo.toml"
        if (Test-Path $cargoToml) {
            Write-BuildLog "Rust project detected, registry configuration should be set in .cargo/config.toml"
        }
    }
}

<#
.SYNOPSIS
    Gets application structure information.

.DESCRIPTION
    Analyzes the application directory to determine its structure and detect docker-compose or Dockerfiles.

.PARAMETER Context
    The build context PSCustomObject.

.EXAMPLE
    Get-ApplicationStructure -Context $context
    Analyzes the application structure and updates the context.
#>
function Get-ApplicationStructure {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [PSCustomObject]$Context
    )

    process {
        $appPath = $Context.App.Path

        # Check for .nobuild marker (dev-only components with no buildable artifacts)
        $noBuildMarker = Join-Path -Path $appPath -ChildPath ".nobuild"
        if (Test-Path -LiteralPath $noBuildMarker) {
            Write-BuildLog "Component marked as non-buildable (.nobuild marker found) - skipping build"
            Write-Info "This is a development-only component with no custom application code to build"
            $Context.Compose.Available = $false
            $Context.Compose.DetectedServices = @()
            $Context.Compose.BuildableServices = @()
            return
        }

        $composeCandidates = @(
            "docker-compose.yml",
            "docker-compose.yaml",
            "compose.yml",
            "compose.yaml"
        )

        $composeFiles = [System.Collections.Generic.List[string]]::new()

        foreach ($candidate in $composeCandidates) {
            $candidatePath = Join-Path -Path $appPath -ChildPath $candidate
            if (Test-Path -LiteralPath $candidatePath) {
                $composeFiles.Add([System.IO.Path]::GetFullPath($candidatePath)) | Out-Null
            }
        }

        $Context.Compose.ManifestFiles = $composeFiles.ToArray()
        $Context.Compose.PrimaryFile = if ($composeFiles.Count -gt 0) { $composeFiles[0] } else { $null }
        $Context.Compose.Available = $composeFiles.Count -gt 0
        $Context.Compose.DetectedServices = @()
        $Context.Compose.BuildableServices = @()
        $Context.Compose.ServiceMetadata = @()

        if ($Context.Compose.Available) {
            $displayPath = $Context.Compose.PrimaryFile
            try {
                $displayPath = [System.IO.Path]::GetRelativePath($Context.App.Path, $Context.Compose.PrimaryFile)
            }
            catch {
                $displayPath = Split-Path -Path $Context.Compose.PrimaryFile -Leaf
            }

            Write-BuildLog "Found docker-compose file: $displayPath"

            if (Get-Command -Name 'ConvertFrom-Yaml' -ErrorAction SilentlyContinue) {
                $serviceNames = [System.Collections.Generic.List[string]]::new()
                $serviceMap = [System.Collections.Generic.Dictionary[string, object]]::new([System.StringComparer]::OrdinalIgnoreCase)

                $convertToArgs = {
                    param($value)

                    $result = [System.Collections.Generic.List[string]]::new()

                    if ($null -eq $value) {
                        return @()
                    }

                    if ($value -is [System.Collections.IDictionary]) {
                        foreach ($key in $value.Keys) {
                            if ([string]::IsNullOrWhiteSpace($key)) {
                                continue
                            }

                            $result.Add("$key=$($value[$key])") | Out-Null
                        }
                        return $result.ToArray()
                    }

                    if ($value -is [PSCustomObject]) {
                        foreach ($property in $value.PSObject.Properties) {
                            if (-not [string]::IsNullOrWhiteSpace($property.Name)) {
                                $result.Add("$($property.Name)=$($property.Value)") | Out-Null
                            }
                        }
                        return $result.ToArray()
                    }

                    if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                        foreach ($item in $value) {
                            if ($null -eq $item) {
                                continue
                            }

                            $text = $item.ToString()
                            if (-not [string]::IsNullOrWhiteSpace($text)) {
                                $result.Add($text) | Out-Null
                            }
                        }
                        return $result.ToArray()
                    }

                    $textValue = $value.ToString()
                    if (-not [string]::IsNullOrWhiteSpace($textValue)) {
                        $result.Add($textValue) | Out-Null
                    }

                    return $result.ToArray()
                }

                $convertToStringArray = {
                    param($value)

                    if ($null -eq $value) {
                        return @()
                    }

                    if ($value -is [System.Collections.IEnumerable] -and -not ($value -is [string])) {
                        $items = [System.Collections.Generic.List[string]]::new()
                        foreach ($item in $value) {
                            if ($null -eq $item) {
                                continue
                            }

                            $text = $item.ToString()
                            if (-not [string]::IsNullOrWhiteSpace($text)) {
                                $items.Add($text) | Out-Null
                            }
                        }
                        return $items.ToArray()
                    }

                    $textValue = $value.ToString()
                    if ([string]::IsNullOrWhiteSpace($textValue)) {
                        return @()
                    }

                    return @($textValue)
                }

                $resolvePath = {
                    param([string]$BasePath, [string]$Candidate)

                    if ([string]::IsNullOrWhiteSpace($Candidate)) {
                        return $null
                    }

                    try {
                        if ([System.IO.Path]::IsPathRooted($Candidate)) {
                            return [System.IO.Path]::GetFullPath($Candidate)
                        }

                        $resolvedBase = if ([string]::IsNullOrWhiteSpace($BasePath)) { $appPath } else { $BasePath }
                        return [System.IO.Path]::GetFullPath((Join-Path -Path $resolvedBase -ChildPath $Candidate))
                    }
                    catch {
                        Write-BuildDebug "Failed to resolve path '$Candidate' relative to '$BasePath': $_"
                        return $null
                    }
                }

                foreach ($manifestPath in $Context.Compose.ManifestFiles) {
                    $manifestDirectory = Split-Path -Path $manifestPath -Parent

                    try {
                        $rawDocument = Get-Content -LiteralPath $manifestPath -Raw -ErrorAction Stop
                        $documentSet = ConvertFrom-Yaml -Yaml $rawDocument -ErrorAction Stop
                    }
                    catch {
                        Write-Warn "Failed to parse compose manifest '$manifestPath': $_"
                        continue
                    }

                    if ($documentSet -is [System.Collections.IDictionary] -or -not ($documentSet -is [System.Collections.IEnumerable]) -or $documentSet -is [string]) {
                        $documents = @($documentSet)
                    }
                    else {
                        $documents = @($documentSet)
                    }

                    foreach ($document in $documents) {
                        if ($null -eq $document) {
                            continue
                        }

                        $documentObject = if ($document -is [PSCustomObject]) { $document } else { [PSCustomObject]$document }

                        $servicesProperty = $documentObject.PSObject.Properties['services']
                        if ($null -eq $servicesProperty) {
                            $servicesProperty = $documentObject.PSObject.Properties['Services']
                        }

                        if ($null -eq $servicesProperty) {
                            continue
                        }

                        $servicesValue = $servicesProperty.Value
                        if ($servicesValue -isnot [PSCustomObject]) {
                            $servicesValue = [PSCustomObject]$servicesValue
                        }

                        foreach ($serviceProperty in $servicesValue.PSObject.Properties) {
                            $serviceName = $serviceProperty.Name
                            if ([string]::IsNullOrWhiteSpace($serviceName)) {
                                continue
                            }

                            $definition = if ($serviceProperty.Value -is [PSCustomObject]) { $serviceProperty.Value } else { [PSCustomObject]$serviceProperty.Value }

                            $buildSection = Get-SafeProperty $definition 'build'
                            $hasBuild = $false
                            $buildContextFull = $null
                            $dockerfileValue = $null
                            $targetValue = $null
                            $buildArgsValue = @()
                            $platformValue = $null
                            $buildDefinitionRaw = $null

                            if ($null -ne $buildSection) {
                                $hasBuild = $true

                                if ($buildSection -is [string]) {
                                    $buildDefinitionRaw = $buildSection
                                    $buildContextFull = & $resolvePath $manifestDirectory $buildSection
                                }
                                else {
                                    if ($buildSection -isnot [PSCustomObject]) {
                                        $buildSection = [PSCustomObject]$buildSection
                                    }

                                    $buildDefinitionRaw = $buildSection

                                    $contextCandidate = Get-SafeProperty $buildSection 'context'
                                    if (-not $contextCandidate) {
                                        $contextCandidate = Get-SafeProperty $buildSection 'Context'
                                    }

                                    if ($contextCandidate) {
                                        $buildContextFull = & $resolvePath $manifestDirectory $contextCandidate.ToString()
                                    }

                                    $dockerfileCandidate = Get-SafeProperty $buildSection 'dockerfile'
                                    if (-not $dockerfileCandidate) {
                                        $dockerfileCandidate = Get-SafeProperty $buildSection 'Dockerfile'
                                    }
                                    if ($dockerfileCandidate) {
                                        $dockerfileValue = $dockerfileCandidate.ToString()
                                    }

                                    $targetCandidate = Get-SafeProperty $buildSection 'target'
                                    if (-not $targetCandidate) {
                                        $targetCandidate = Get-SafeProperty $buildSection 'Target'
                                    }
                                    if ($targetCandidate) {
                                        $targetValue = $targetCandidate.ToString()
                                    }

                                    $platformCandidate = Get-SafeProperty $buildSection 'platform'
                                    if (-not $platformCandidate) {
                                        $platformCandidate = Get-SafeProperty $buildSection 'Platform'
                                    }
                                    if ($platformCandidate) {
                                        $platformValue = $platformCandidate.ToString()
                                    }

                                    $argsCandidate = Get-SafeProperty $buildSection 'args'
                                    if (-not $argsCandidate) {
                                        $argsCandidate = Get-SafeProperty $buildSection 'Args'
                                    }

                                    if ($argsCandidate) {
                                        $buildArgsValue = & $convertToArgs $argsCandidate
                                    }
                                }

                                if (-not $buildContextFull) {
                                    $buildContextFull = & $resolvePath $manifestDirectory '.'
                                }
                            }

                            if (-not $platformValue) {
                                $servicePlatform = Get-SafeProperty $definition 'platform'
                                if (-not $servicePlatform) {
                                    $servicePlatform = Get-SafeProperty $definition 'Platform'
                                }

                                if ($servicePlatform) {
                                    $platformValue = $servicePlatform.ToString()
                                }
                            }

                            $imageName = $null
                            $imageCandidate = Get-SafeProperty $definition 'image'
                            if (-not $imageCandidate) {
                                $imageCandidate = Get-SafeProperty $definition 'Image'
                            }
                            if ($imageCandidate) {
                                $imageName = $imageCandidate.ToString()

                                # Expand environment variable patterns in image names
                                # This handles docker-compose variable syntax like ${VAR:-default}
                                if ($imageName -match '\$\{') {
                                    # Replace ${REGISTRY:-default} with actual registry value
                                    $imageName = $imageName -replace "`\$`{REGISTRY:-[^}]+`}", $Context.App.Registry
                                    # Replace ${REGISTRY} with actual registry value
                                    $imageName = $imageName -replace "`\$`{REGISTRY`}", $Context.App.Registry

                                    # Replace ${APPLICATION:-default} with actual app name
                                    $imageName = $imageName -replace "`\$`{APPLICATION:-[^}]+`}", $Context.App.Name
                                    # Replace ${APPLICATION} with actual app name
                                    $imageName = $imageName -replace "`\$`{APPLICATION`}", $Context.App.Name

                                    # Replace ${BUILD_ID:-default} with actual build ID
                                    $imageName = $imageName -replace "`\$`{BUILD_ID:-[^}]+`}", $Context.App.BuildId
                                    # Replace ${BUILD_ID} with actual build ID
                                    $imageName = $imageName -replace "`\$`{BUILD_ID`}", $Context.App.BuildId
                                }
                            }

                            $repositoryValue = $null
                            if ($imageName) {
                                $repositoryValue = ($imageName -split ':', 2)[0]
                            }

                            $profilesCandidate = Get-SafeProperty $definition 'profiles'
                            $profilesValue = & $convertToStringArray $profilesCandidate
                            if (@($profilesValue).Count -eq 0) {
                                $profilesCandidate = Get-SafeProperty $definition 'Profiles'
                                $profilesValue = & $convertToStringArray $profilesCandidate
                            }

                            $tagsCandidate = Get-SafeProperty $definition 'tags'
                            $tagsValue = & $convertToStringArray $tagsCandidate
                            if (@($tagsValue).Count -eq 0) {
                                $tagsCandidate = Get-SafeProperty $definition 'Tags'
                                $tagsValue = & $convertToStringArray $tagsCandidate
                            }

                            $buildContextRelative = $null
                            if ($buildContextFull) {
                                try {
                                    $relativeCandidate = [System.IO.Path]::GetRelativePath($Context.App.Path, $buildContextFull)
                                    if ([string]::IsNullOrWhiteSpace($relativeCandidate) -or $relativeCandidate -eq '.') {
                                        $buildContextRelative = '.'
                                    }
                                    else {
                                        $buildContextRelative = $relativeCandidate
                                    }
                                }
                                catch {
                                    $buildContextRelative = $buildContextFull
                                }
                            }
                            else {
                                $buildContextRelative = '.'
                            }

                            $serviceRecord = [pscustomobject]@{
                                Name             = $serviceName
                                ManifestPath     = $manifestPath
                                BuildDefined     = $hasBuild
                                BuildContext     = $buildContextRelative
                                BuildContextPath = $buildContextFull
                                Dockerfile       = $dockerfileValue
                                Target           = $targetValue
                                BuildArgs        = $buildArgsValue
                                Platform         = $platformValue
                                ImageName        = $imageName
                                Repository       = $repositoryValue
                                Profiles         = $profilesValue
                                Tags             = $tagsValue
                                BuildDefinition  = $buildDefinitionRaw
                            }

                            if (-not $serviceMap.ContainsKey($serviceName)) {
                                $serviceNames.Add($serviceName) | Out-Null
                            }

                            $serviceMap[$serviceName] = $serviceRecord
                        }
                    }
                }

                $Context.Compose.DetectedServices = $serviceNames.ToArray()

                $metadataArray = @()
                if ($serviceNames.Count -gt 0) {
                    $metadataArray = @(
                        foreach ($serviceName in $serviceNames) {
                            if ($serviceMap.ContainsKey($serviceName)) {
                                [pscustomobject]$serviceMap[$serviceName]
                            }
                        }
                    )
                }

                $Context.Compose.ServiceMetadata = $metadataArray

                $buildableOrdered = @()
                if ($metadataArray.Count -gt 0) {
                    $buildableOrdered = @(
                        foreach ($entry in $metadataArray) {
                            if ($entry.BuildDefined) { $entry }
                        }
                    )
                }

                $Context.Compose.BuildableServices = $buildableOrdered

                if (@($Context.Compose.DetectedServices).Count -gt 0) {
                    Write-BuildLog "Compose services detected: $(@($Context.Compose.DetectedServices).Count); Buildable: $(@($Context.Compose.BuildableServices).Count)"
                }
                else {
                    Write-Warn "Compose manifest found but no services were detected"
                }
            }
            else {
                Write-Warn "ConvertFrom-Yaml not found; skipping compose service extraction"
            }
        }
        else {
            Write-BuildDebug "No docker-compose manifests found"
        }

        $dockerfiles = @(Get-ChildItem -Path $appPath -Filter "Dockerfile*" -File -Recurse -ErrorAction SilentlyContinue)

        if ($null -eq $dockerfiles) {
            $dockerfiles = @()
        }

        $Context | Add-Member -MemberType NoteProperty -Name 'Dockerfiles' -Value $dockerfiles -Force
        $Context | Add-Member -MemberType NoteProperty -Name 'HasDockerfiles' -Value ($dockerfiles.Count -gt 0) -Force

        Write-BuildLog "Application structure: HasCompose=$($Context.Compose.Available), ComposeServices=$(@($Context.Compose.DetectedServices).Count), HasDockerfiles=$($Context.HasDockerfiles)"
    }
}

Export-ModuleMember -Function @(
    'Write-BuildLog',
    'Write-BuildDebug',
    'Write-Info',
    'Write-Warn',
    'Write-BuildError',
    'ConvertTo-BuildArgList',
    'Test-CommandExist',
    'Get-ComposeProjectName',
    'Test-DockerImageExist',
    'Get-ProjectRootPath',
    'Format-FileSize',
    'ConvertTo-SafeFileName',
    'ConvertTo-DockerTagValue',
    'Test-DockerTagValue',
    'Invoke-WithRetry',
    'New-BuildContext',
    'Test-Parameter',
    'Test-Dependency',
    'Initialize-RustRegistryConfiguration',
    'Get-ApplicationStructure',
    'Get-CommonBuildArgument',
    'Get-AdditionalDockerBuildArgument',
    'Get-ServiceBuildTag',
    'Get-SafeProperty'
)
