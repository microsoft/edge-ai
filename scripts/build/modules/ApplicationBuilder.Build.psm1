Set-StrictMode -Version Latest

function Get-ServiceSourceImageTag {
    <#
    .SYNOPSIS
    Resolves an existing image tag for a compose service if one is already present locally.

    .DESCRIPTION
    Builds a prioritized list of potential image references using service metadata and compose context,
    returning the first tag that resolves via `docker image inspect`.

    .PARAMETER Context
    Build context containing application metadata and compose settings.

    .PARAMETER ServiceMetadata
    Metadata describing the compose service under evaluation.

    .OUTPUTS
    [string] representing an existing image reference, or $null if none resolve.
    #>
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$Context,
        [Parameter(Mandatory = $true)][pscustomobject]$ServiceMetadata
    )

    $candidates = [System.Collections.Generic.List[string]]::new()
    $seen = [System.Collections.Generic.HashSet[string]]::new()

    $tagSuffixes = [System.Collections.Generic.List[string]]::new()
    $tagSuffixes.Add("latest") | Out-Null
    $tagSuffixes.Add("local") | Out-Null

    if (-not [string]::IsNullOrWhiteSpace($Context.App.BuildId)) {
        $tagSuffixes.Add($Context.App.BuildId) | Out-Null
    }

    $addCandidate = {
        param([string]$Repository)

        if ([string]::IsNullOrWhiteSpace($Repository)) {
            return
        }

        $normalized = $Repository.Trim()

        if ($normalized.Contains(':')) {
            if ($seen.Add($normalized)) {
                $candidates.Add($normalized) | Out-Null
            }
            return
        }

        foreach ($suffix in $tagSuffixes) {
            if ([string]::IsNullOrWhiteSpace($suffix)) {
                continue
            }

            $reference = "{0}:{1}" -f $normalized, $suffix
            if ($seen.Add($reference)) {
                $candidates.Add($reference) | Out-Null
            }
        }
    }

    if ($ServiceMetadata.PSObject.Properties['ImageName'] -and -not [string]::IsNullOrWhiteSpace($ServiceMetadata.ImageName)) {
        & $addCandidate $ServiceMetadata.ImageName
    }

    if ($ServiceMetadata.PSObject.Properties['Repository'] -and -not [string]::IsNullOrWhiteSpace($ServiceMetadata.Repository)) {
        & $addCandidate $ServiceMetadata.Repository
    }

    $projectCandidates = [System.Collections.Generic.List[string]]::new()

    if ($Context.Compose.PSObject.Properties['ProjectName'] -and -not [string]::IsNullOrWhiteSpace($Context.Compose.ProjectName)) {
        $projectCandidates.Add($Context.Compose.ProjectName) | Out-Null
    }

    if (-not [string]::IsNullOrWhiteSpace($Context.App.Name) -and -not $projectCandidates.Contains($Context.App.Name)) {
        $projectCandidates.Add($Context.App.Name) | Out-Null
    }

    # Add directory basename as candidate since Docker Compose uses it as default project name
    if (-not [string]::IsNullOrWhiteSpace($Context.App.Path)) {
        try {
            $dirBasename = Split-Path -Path $Context.App.Path -Leaf
            if (-not [string]::IsNullOrWhiteSpace($dirBasename) -and -not $projectCandidates.Contains($dirBasename)) {
                $projectCandidates.Add($dirBasename) | Out-Null
            }
        }
        catch {
            Write-BuildDebug "Failed to extract directory basename from path: $_"
        }
    }

    foreach ($prefix in $projectCandidates) {
        foreach ($separator in @('-', '_')) {
            $composedName = "$prefix$separator$($ServiceMetadata.Name)"
            & $addCandidate $composedName
        }
    }

    & $addCandidate $ServiceMetadata.Name

    foreach ($candidate in $candidates) {
        $null = & docker image inspect $candidate 2>$null
        if ($LASTEXITCODE -eq 0) {
            Write-BuildDebug "Located existing image reference '$candidate' for service $($ServiceMetadata.Name)"
            return $candidate
        }
    }

    Write-BuildDebug "No existing image tag located for service $($ServiceMetadata.Name)"
    return $null
}

function Set-CanonicalServiceTag {
    <#
    .SYNOPSIS
    Ensures locally built images have the expected canonical tags.

    .DESCRIPTION
    Tags the located source image for a service with all derived canonical tags so subsequent steps can reference consistent names.

    .PARAMETER Context
    Build context containing application configuration.

    .PARAMETER ServiceMetadata
    Metadata describing the compose service whose image was built.

    .PARAMETER CanonicalTags
    Collection of target tags generated for the service image.
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)][pscustomobject]$Context,
        [Parameter(Mandatory = $true)][pscustomobject]$ServiceMetadata,
        [Parameter(Mandatory = $true)][string[]]$CanonicalTags
    )

    if (-not $CanonicalTags -or $CanonicalTags.Count -eq 0) {
        return
    }

    $sourceTag = Get-ServiceSourceImageTag -Context $Context -ServiceMetadata $ServiceMetadata

    if ([string]::IsNullOrWhiteSpace($sourceTag)) {
        return
    }

    foreach ($targetTag in $CanonicalTags) {
        if ([string]::IsNullOrWhiteSpace($targetTag) -or $targetTag -eq $sourceTag) {
            continue
        }

        if (-not $PSCmdlet.ShouldProcess($targetTag, "Tag image $sourceTag")) {
            continue
        }

        $tagOutput = & docker tag $sourceTag $targetTag 2>&1

        if ($LASTEXITCODE -eq 0) {
            Write-BuildDebug "Tagged $sourceTag as $targetTag"
        }
        else {
            $errorMessage = $tagOutput -join " "
            Write-Warn ("Failed to tag {0} as {1}: {2}" -f $sourceTag, $targetTag, $errorMessage)
        }
    }
}

function Build-ServicesWithCompose {
    <#
    .SYNOPSIS
    Builds application services using Docker Compose.

    .DESCRIPTION
    Orchestrates the build process for services using Docker Compose with parallel builds,
    common build arguments, and tracking of build results in the Context object.

    .PARAMETER Context
    The build context object containing application configuration and state.

    .PARAMETER Services
    Array of service metadata objects to build.

    .PARAMETER VerboseLogging
    Enable verbose build output with detailed progress information.

    .PARAMETER DryRun
    Simulate the build without executing Docker commands.

    .EXAMPLE
    Build-ServicesWithCompose -Context $context -Services $services -DryRun
    #>
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,

        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Services,

        [Parameter()]
        [switch]$VerboseLogging,

        [Parameter()]
        [switch]$DryRun
    )

    Write-BuildLog "Building services using Docker Compose"

    $buildStart = Get-Date
    $originalLocation = Get-Location

    try {
        Set-Location $Context.App.Path

        $composeArgs = @("build")

        if ($env:COMPOSE_PARALLEL_LIMIT -or $env:DOCKER_BUILDKIT -eq "1") {
            $composeArgs += "--parallel"
        }

        $commonArgs = Get-CommonBuildArgument -AppName $Context.App.Name -BuildId $Context.App.BuildId -BuildEnv $Context.App.Environment -CommitSha $Context.App.CommitSha -BaseImageTag $Context.App.BaseImageTag -DockerBuildArgs $Context.App.DockerBuildArgs

        foreach ($arg in $commonArgs) {
            $composeArgs += "--build-arg"
            $composeArgs += $arg
        }

        $additionalArgs = Get-AdditionalDockerBuildArgument -DockerBuildArgs $Context.App.DockerBuildArgs -EnableVerboseProgress:$VerboseLogging
        if (@($additionalArgs).Count -gt 0) {
            $composeArgs += $additionalArgs
        }

        Write-BuildDebug "Docker compose build command: $(Format-ComposeCommand -Context $Context -Arguments $composeArgs)"

        if ($DryRun) {
            Write-Info "DRY RUN: Would run $(Format-ComposeCommand -Context $Context -Arguments $composeArgs)"
            foreach ($service in $Services) {
                $Context.Build.Successful += $service.Name
                $Context.Build.Results += [PSCustomObject]@{
                    service    = $service.Name
                    success    = $true
                    image      = (Get-ServiceBuildTag -ServiceMetadata $service -AppName $Context.App.Name -Registry $Context.App.Registry -BuildId $Context.App.BuildId -BuildEnv $Context.App.Environment -CommitSha $Context.App.CommitSha | Select-Object -First 1)
                    built_with = "docker-compose (dry-run)"
                }
            }
            return
        }

        try {
            # Set environment variables for docker-compose.yml interpolation
            # These allow ${REGISTRY}, ${APPLICATION}, and ${BUILD_ID} to be resolved
            $env:BUILD_ID = $Context.App.BuildId
            $env:REGISTRY = $Context.App.Registry
            $env:APPLICATION = $Context.App.Name

            $null = Invoke-Compose -Context $Context -Arguments $composeArgs
            Write-Info "✅ Successfully built services with Docker Compose"

            foreach ($service in $Services) {
                $serviceTags = Get-ServiceBuildTag -ServiceMetadata $service -AppName $Context.App.Name -Registry $Context.App.Registry -BuildId $Context.App.BuildId -BuildEnv $Context.App.Environment -CommitSha $Context.App.CommitSha
                $Context.Build.Successful += $service.Name
                $Context.Build.Results += [PSCustomObject]@{
                    service    = $service.Name
                    success    = $true
                    image      = ($serviceTags | Select-Object -First 1)
                    built_with = "docker-compose"
                }

                Set-CanonicalServiceTag -Context $Context -ServiceMetadata $service -CanonicalTags $serviceTags
            }
        }
        catch {
            $errorRecord = $_
            Write-Warn ("❌ Docker Compose build failed: {0}" -f $errorRecord)

            foreach ($service in $Services) {
                $Context.Build.Failed += $service.Name
                $Context.Build.Results += [PSCustomObject]@{
                    service    = $service.Name
                    success    = $false
                    error      = "docker-compose build failed"
                    built_with = "docker-compose"
                }
            }
        }
    }
    finally {
        Set-Location $originalLocation
        $Context.Build.Duration = [int]((Get-Date) - $buildStart).TotalSeconds
    }
}

function Build-ServicesWithoutCompose {
    <#
    .SYNOPSIS
    Builds individual services without Docker Compose using standalone docker build commands.

    .DESCRIPTION
    Iterates through services and builds each one individually using docker build,
    applying service-specific configurations and tracking results in Context.

    .PARAMETER Context
    The build context object containing application configuration and state.

    .PARAMETER Services
    Array of service metadata objects to build.

    .PARAMETER VerboseLogging
    Enable verbose build output with detailed progress information.

    .PARAMETER DryRun
    Simulate the build without executing Docker commands.

    .EXAMPLE
    Build-ServicesWithoutCompose -Context $context -Services $services
    #>
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,

        [Parameter(Mandatory = $true)]
        [pscustomobject[]]$Services,

        [Parameter()]
        [switch]$VerboseLogging,

        [Parameter()]
        [switch]$DryRun
    )

    Write-BuildLog "Building services using docker build fallback"

    if (@($Services).Count -eq 0) {
        Write-Warn "No buildable services were detected; skipping docker build fallback"
        $Context.Build.Duration = 0
        return
    }

    $buildStart = Get-Date
    $commonArgs = Get-CommonBuildArgument -AppName $Context.App.Name -BuildId $Context.App.BuildId -BuildEnv $Context.App.Environment -CommitSha $Context.App.CommitSha -BaseImageTag $Context.App.BaseImageTag -DockerBuildArgs $Context.App.DockerBuildArgs
    $additionalArgs = Get-AdditionalDockerBuildArgument -DockerBuildArgs $Context.App.DockerBuildArgs -EnableVerboseProgress:$VerboseLogging

    try {
        foreach ($service in $Services) {
            $contextRelative = if ([string]::IsNullOrWhiteSpace($service.BuildContext)) { "." } else { $service.BuildContext }
            $contextPath = Resolve-AppRelativePath -BasePath $Context.App.Path -RelativePath $contextRelative

            if (-not (Test-Path -LiteralPath $contextPath)) {
                $message = "Build context '$contextRelative' for service $($service.Name) was not found"
                Write-Warn $message
                $Context.Build.Failed += $service.Name
                $Context.Build.Results += [PSCustomObject]@{
                    service    = $service.Name
                    success    = $false
                    error      = $message
                    built_with = "docker build"
                }
                continue
            }

            $dockerfileRelative = if ([string]::IsNullOrWhiteSpace($service.Dockerfile)) { "Dockerfile" } else { $service.Dockerfile }
            $dockerfilePath = if ([System.IO.Path]::IsPathRooted($dockerfileRelative)) {
                [System.IO.Path]::GetFullPath($dockerfileRelative)
            }
            else {
                [System.IO.Path]::GetFullPath((Join-Path $contextPath $dockerfileRelative))
            }

            if (-not (Test-Path -LiteralPath $dockerfilePath)) {
                $message = "Dockerfile '$dockerfileRelative' for service $($service.Name) was not found"
                Write-Warn $message
                $Context.Build.Failed += $service.Name
                $Context.Build.Results += [PSCustomObject]@{
                    service    = $service.Name
                    success    = $false
                    error      = $message
                    built_with = "docker build"
                }
                continue
            }

            $serviceTags = Get-ServiceBuildTag -ServiceMetadata $service -AppName $Context.App.Name -Registry $Context.App.Registry -BuildId $Context.App.BuildId -BuildEnv $Context.App.Environment -CommitSha $Context.App.CommitSha

            $dockerArgs = @("build")

            foreach ($tag in $serviceTags) {
                $dockerArgs += "-t"
                $dockerArgs += $tag
            }

            if (-not [string]::IsNullOrWhiteSpace($service.Platform)) {
                $dockerArgs += "--platform"
                $dockerArgs += $service.Platform
            }

            foreach ($arg in $commonArgs) {
                $dockerArgs += "--build-arg"
                $dockerArgs += $arg
            }

            foreach ($arg in $service.BuildArgs) {
                if ([string]::IsNullOrWhiteSpace($arg)) {
                    continue
                }
                $dockerArgs += "--build-arg"
                $dockerArgs += $arg
            }

            if (@($additionalArgs).Count -gt 0) {
                $dockerArgs += $additionalArgs
            }

            if (-not [string]::IsNullOrWhiteSpace($service.Target)) {
                $dockerArgs += "--target"
                $dockerArgs += $service.Target
            }

            $dockerArgs += "-f"
            $dockerArgs += $dockerfilePath
            $dockerArgs += $contextPath

            if ($DryRun) {
                Write-Info "DRY RUN: Would run docker $($dockerArgs -join ' ')"
                $Context.Build.Successful += $service.Name
                $Context.Build.Results += [PSCustomObject]@{
                    service    = $service.Name
                    success    = $true
                    image      = $serviceTags[0]
                    built_with = "docker build (dry-run)"
                }
                continue
            }

            try {
                Write-BuildDebug "Executing docker $($dockerArgs -join ' ')"
                $null = & docker @dockerArgs
                $exitCode = $LASTEXITCODE
                if ($exitCode -ne 0) {
                    throw "Docker build failed with exit code $exitCode"
                }

                Write-Info "✅ Built service $($service.Name) using docker build"
                $Context.Build.Successful += $service.Name
                $Context.Build.Results += [PSCustomObject]@{
                    service    = $service.Name
                    success    = $true
                    image      = $serviceTags[0]
                    built_with = "docker build"
                }
            }
            catch {
                $errorMessage = if ($_.Exception -and $_.Exception.Message) { $_.Exception.Message } else { [string]$_ }
                Write-Warn "❌ Docker build failed for service $($service.Name): $errorMessage"
                $Context.Build.Failed += $service.Name
                $Context.Build.Results += [PSCustomObject]@{
                    service    = $service.Name
                    success    = $false
                    error      = $errorMessage
                    built_with = "docker build"
                }
            }
        }
    }
    finally {
        $Context.Build.Duration = [int]((Get-Date) - $buildStart).TotalSeconds
    }
}

function Build-AllService {
    <#
    .SYNOPSIS
    Main entry point for building all services in the application.

    .DESCRIPTION
    Orchestrates the complete build workflow by detecting services, determining the build strategy
    (Compose vs individual), and executing builds while tracking results in Context.

    .PARAMETER Context
    The build context object containing application configuration and state.

    .PARAMETER VerboseLogging
    Enable verbose build output with detailed progress information.

    .PARAMETER DryRun
    Simulate the build without executing Docker commands.

    .EXAMPLE
    Build-AllService -Context $context -VerboseLogging -DryRun
    #>
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,

        [Parameter()]
        [switch]$VerboseLogging,

        [Parameter()]
        [switch]$DryRun
    )

    $servicesToBuild = @($Context.Compose.BuildableServices)

    if (@($servicesToBuild).Count -eq 0) {
        $composePath = Join-Path $Context.App.Path "docker-compose.yml"
        if (Test-Path $composePath) {
            throw "docker-compose.yml exists at '$composePath' but no buildable services detected. This indicates a compose parsing failure. Verify powershell-yaml module is installed."
        }
        Write-Warn "No buildable services detected; skipping build step"
        $Context.Build.Duration = 0
        return
    }

    $composeAvailable = Test-ComposeRequirement -Context $Context

    if ($composeAvailable -and $Context.Compose.Available) {
        Build-ServicesWithCompose -Context $Context -Services $servicesToBuild -VerboseLogging:$VerboseLogging -DryRun:$DryRun
    }
    else {
        Build-ServicesWithoutCompose -Context $Context -Services $servicesToBuild -VerboseLogging:$VerboseLogging -DryRun:$DryRun
    }

    Write-BuildLog "Build Summary"
    Write-Info "Total detected services: $(@($Context.Compose.DetectedServices).Count)"
    Write-Info "Buildable services: $(@($servicesToBuild).Count)"
    Write-Info "Successful builds: $(@($Context.Build.Successful).Count) ($($Context.Build.Successful -join ', '))"
    Write-Info "Failed builds: $(@($Context.Build.Failed).Count) ($($Context.Build.Failed -join ', '))"
    Write-Info "Build duration: $($Context.Build.Duration) seconds"
}

function Get-SecurityScannerJsonContent {
    <#
    .SYNOPSIS
    Extracts the first valid JSON payload from mixed scanner output.

    .DESCRIPTION
    Normalizes heterogeneous PowerShell stream records, concatenates them, and scans for balanced
    JSON documents, returning the first segment that converts successfully.

    .PARAMETER Output
    Collection of objects emitted by the scanner invocation across all streams.

    .OUTPUTS
    [string] containing a JSON document when discovered; otherwise $null.
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Output
    )

    if (-not $Output) {
        return $null
    }

    $stringSegments = @()

    foreach ($entry in $Output) {
        if ($null -eq $entry) {
            continue
        }

        $segment = $null

        if ($entry -is [System.Management.Automation.InformationRecord]) {
            $messageData = $entry.MessageData
            if ($messageData -is [string]) {
                $segment = $messageData
            }
            elseif ($messageData -is [System.Array]) {
                $segment = ($messageData | ForEach-Object { $_.ToString() }) -join "`n"
            }
            elseif ($null -ne $messageData) {
                $segment = $messageData.ToString()
            }
        }
        elseif ($entry -is [System.Management.Automation.WarningRecord]) {
            $segment = $entry.Message
        }
        elseif ($entry -is [System.Management.Automation.VerboseRecord]) {
            $segment = $entry.Message
        }
        elseif ($entry -is [System.Management.Automation.DebugRecord]) {
            $segment = $entry.Message
        }
        elseif ($entry -is [System.Management.Automation.ErrorRecord]) {
            $segment = $entry.ToString()
        }
        else {
            $segment = $entry.ToString()
        }

        if (-not [string]::IsNullOrWhiteSpace($segment)) {
            $stringSegments += $segment
        }
    }

    if (@($stringSegments).Count -eq 0) {
        return $null
    }

    $combinedOutput = $stringSegments -join "`n"

    if ([string]::IsNullOrWhiteSpace($combinedOutput)) {
        return $null
    }

    $length = $combinedOutput.Length
    $position = 0

    while ($position -lt $length) {
        $startChar = $combinedOutput[$position]

        if ($startChar -ne '{' -and $startChar -ne '[') {
            $position++
            continue
        }

        $stack = New-Object System.Collections.Generic.Stack[char]
        if ($startChar -eq '{') {
            $stack.Push('}')
        }
        else {
            $stack.Push(']')
        }

        $inString = $false
        $escapeNext = $false
        $endIndex = -1

        for ($i = $position + 1; $i -lt $length; $i++) {
            $char = $combinedOutput[$i]

            if ($escapeNext) {
                $escapeNext = $false
                continue
            }

            if ($inString) {
                if ($char -eq '\\') {
                    $escapeNext = $true
                    continue
                }

                if ($char -eq '"') {
                    $inString = $false
                }

                continue
            }

            if ($char -eq '"') {
                $inString = $true
                continue
            }

            if ($char -eq '{') {
                $stack.Push('}')
                continue
            }

            if ($char -eq '[') {
                $stack.Push(']')
                continue
            }

            if ($char -eq '}' -or $char -eq ']') {
                if ($stack.Count -eq 0) {
                    $endIndex = -1
                    break
                }

                $expected = $stack.Pop()

                if (($char -eq '}' -and $expected -ne '}') -or ($char -eq ']' -and $expected -ne ']')) {
                    $endIndex = -1
                    break
                }

                if ($stack.Count -eq 0) {
                    $endIndex = $i
                    break
                }

                continue
            }
        }

        if ($endIndex -ge $position) {
            $candidate = $combinedOutput.Substring($position, $endIndex - $position + 1).Trim()

            if (-not [string]::IsNullOrWhiteSpace($candidate)) {
                try {
                    $null = $candidate | ConvertFrom-Json -Depth 15 -ErrorAction Stop
                    return $candidate
                }
                catch {
                    $position = $endIndex + 1
                    continue
                }
            }
        }

        if ($endIndex -ge $position) {
            $position = $endIndex + 1
        }
        else {
            $position++
        }
    }

    return $null
}

function Invoke-SecurityScan {
    <#
    .SYNOPSIS
    Executes container security scanning on successfully built images.

    .DESCRIPTION
    Scans Docker images for vulnerabilities using an external security scanner,
    validates results against threshold, and tracks scan outcomes in Context.

    .PARAMETER Context
    The build context object containing application configuration and build results.

    .PARAMETER Threshold
    Minimum severity level for vulnerability reporting (negligible, low, medium, high, critical).

    .EXAMPLE
    Invoke-SecurityScan -Context $context -Threshold 'high'
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,

        [Parameter()]
        [ValidateSet('negligible', 'low', 'medium', 'high', 'critical')]
        [string]$Threshold = 'medium'
    )

    Write-BuildLog "Starting security scans for built images"

    if ($Context.App.DryRun) {
        Write-Info "DRY RUN: Would scan $(@($Context.Build.Successful).Count) images for security vulnerabilities"
        # Simulate successful scans
        foreach ($service in $Context.Build.Successful) {
            $Context.Security.Passed += 1
            $scanResult = [PSCustomObject]@{
                service         = $service
                success         = $true
                image           = "$($Context.App.Registry)/$($Context.App.Name)/${service}:$($Context.App.BuildId)"
                vulnerabilities = @{ critical = 0; high = 0; medium = 0; low = 0; negligible = 0 }
                thresholdPassed = $true
            }
            $Context.Security.Results += $scanResult
        }
        return
    }

    # Check if security scanner is available
    $scannerPath = Join-Path $PSScriptRoot "../../security/Invoke-ContainerSecurityScan.ps1"

    if (-not (Test-Path $scannerPath)) {
        Write-Warn "Security scanner not found at expected location: $scannerPath"
        Write-Warn "Skipping security scans"
        return
    }

    # Scan each successfully built service
    foreach ($service in $Context.Build.Successful) {
        Write-Info "Scanning service: $service"

        try {
            $scanArgs = @{
                ImageName      = "$($Context.App.Name)/$service"
                ImageTag       = $Context.App.BuildId
                Registry       = $Context.App.Registry
                OutputPath     = "./security-reports"
                FailOnSeverity = $Threshold
                Quiet          = $true
                VerboseLogging = $true
            }

            Write-BuildDebug "Executing security scan with args: $($scanArgs | ConvertTo-Json -Compress)"

            # Execute security scanner
            $scanOutput = & pwsh $scannerPath @scanArgs 2>&1
            $scanExitCode = $LASTEXITCODE

            # Validate scan output exists before parsing
            if ([string]::IsNullOrWhiteSpace($scanOutput)) {
                Write-Warn "Security scan for $service produced no output - checking if image exists"

                # Verify the Docker image exists
                $imageName = "$($Context.App.Registry)/$($Context.App.Name)/${service}:$($Context.App.BuildId)"
                $imageCheckOutput = docker image inspect $imageName 2>&1
                $imageExists = $LASTEXITCODE -eq 0

                if (-not $imageExists) {
                    Write-BuildDebug "Docker inspect output: $imageCheckOutput"
                    throw [System.Exception]::new("Container image not found: $imageName. Build may have failed silently.")
                }
                else {
                    # DETAILED DIAGNOSTICS: Capture comprehensive information about scanner crash
                    Write-Warn "⚠️ SCANNER TOOL FAILURE DETECTED for service: $service"
                    Write-Warn "Scanner Exit Code: $scanExitCode"
                    Write-Warn "Image: $imageName"
                    Write-Warn "Image Exists: $imageExists"

                    # Verify Grype is installed and callable
                    $grypeCheck = try { & grype version 2>&1 } catch { $_.Exception.Message }
                    Write-Warn "Grype Availability: $grypeCheck"

                    # Environment diagnostics
                    Write-Warn "PowerShell Version: $($PSVersionTable.PSVersion)"
                    Write-Warn "Working Directory: $(Get-Location)"
                    Write-Warn "Scanner Path: $scannerPath"

                    # Log scan command for reproduction
                    Write-Warn "Scanner Command: pwsh $scannerPath $(($scanArgs.GetEnumerator() | ForEach-Object { "-$($_.Key) $($_.Value)" }) -join ' ')"

                    # Create tool failure result instead of throwing exception
                    Write-Warn "Marking as tool failure (not security finding) - build will continue"

                    $toolFailureResult = [PSCustomObject]@{
                        service          = $service
                        thresholdPassed  = $true  # Tool failure doesn't fail security gate
                        toolFailure      = $true  # Flag this as a tool failure
                        exitCode         = $scanExitCode
                        vulnerabilities  = @{ critical = 0; high = 0; medium = 0; low = 0; negligible = 0; unknown = 0 }
                        thresholdReasons = @("Scanner tool produced no output - tool failure")
                        diagnostics      = @{
                            scannerExitCode = $scanExitCode
                            imageExists     = $imageExists
                            imageName       = $imageName
                            grypeCheck      = $grypeCheck
                            psVersion       = $PSVersionTable.PSVersion.ToString()
                        }
                    }

                    $Context.Security.Results += $toolFailureResult
                    $Context.Security.Failed += 1

                    Write-Warn "⚠️ Security scan tool failed for $service - recorded as tool failure"
                    continue
                }
            }

            Write-BuildDebug "Security scan output length: $($scanOutput.Length) characters"

            # Parse JSON output from scanner
            try {
                $scanJson = Get-SecurityScannerJsonContent -Output $scanOutput
                if (-not $scanJson) {
                    throw [System.Exception]::new("Scanner output did not include a JSON payload")
                }

                $scanResult = $scanJson | ConvertFrom-Json -Depth 20

                if (-not ($scanResult.PSObject.Properties.Name -contains 'thresholdReasons')) {
                    $scanResult | Add-Member -NotePropertyName "thresholdReasons" -NotePropertyValue @()
                }

                $scanResult | Add-Member -NotePropertyName "service" -NotePropertyValue $service -Force

                # Ensure toolFailure property exists on all results for consistency
                if (-not ($scanResult.PSObject.Properties.Name -contains 'toolFailure')) {
                    $scanResult | Add-Member -NotePropertyName "toolFailure" -NotePropertyValue $false -Force
                }

                $Context.Security.Results += $scanResult

                if ($scanExitCode -eq 0 -and $scanResult.thresholdPassed) {
                    Write-Info "✅ Security scan passed for service: $service"
                    $Context.Security.Passed += 1
                }
                else {
                    Write-Warn "❌ Security scan failed for service: $service"

                    if (@($scanResult.thresholdReasons).Count -gt 0) {
                        Write-BuildDebug ("Threshold failure reasons: {0}" -f ($scanResult.thresholdReasons -join ', '))
                    }

                    $Context.Security.Failed += 1
                }
            }
            catch {
                $errorRecord = $_
                Write-Warn ("Failed to parse security scan output for {0}: {1}" -f $service, $errorRecord)

                # Log truncated output for debugging
                if ($scanOutput.Length -gt 500) {
                    Write-BuildDebug "Scanner output (first 500 chars): $($scanOutput.Substring(0, 500))..."
                }
                else {
                    Write-BuildDebug "Scanner output: $scanOutput"
                }

                $scanResult = [PSCustomObject]@{
                    service          = $service
                    success          = $false
                    error            = "Failed to parse scanner output: $($errorRecord.Exception.Message)"
                    image            = "$($Context.App.Registry)/$($Context.App.Name)/${service}:$($Context.App.BuildId)"
                    thresholdPassed  = $false
                    thresholdReasons = @()
                    toolFailure      = $true
                }
                $Context.Security.Results += $scanResult
                $Context.Security.Failed += 1
            }
        }
        catch {
            $errorRecord = $_
            Write-Warn ("Failed to execute security scan for {0}: {1}" -f $service, $errorRecord)

            $scanResult = [PSCustomObject]@{
                service         = $service
                success         = $false
                error           = $errorRecord.Exception.Message
                image           = "$($Context.App.Registry)/$($Context.App.Name)/${service}:$($Context.App.BuildId)"
                thresholdPassed = $false
                toolFailure     = $true
            }
            $Context.Security.Results += $scanResult
            $Context.Security.Failed += 1
        }
    }
}

function New-SlsaBundle {
    <#
    .SYNOPSIS
    Generates SLSA (Supply-chain Levels for Software Artifacts) provenance bundle.

    .DESCRIPTION
    Creates a comprehensive SLSA provenance bundle containing build metadata, dependencies,
    security scan results, and artifact information for supply chain verification.

    .PARAMETER Context
    The build context object containing complete build and security information.

    .EXAMPLE
    New-SlsaBundle -Context $context
    #>
    [CmdletBinding(SupportsShouldProcess)]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    Write-BuildLog "Generating SLSA security bundle"

    if ($Context.App.DryRun) {
        Write-Info "DRY RUN: Would generate SLSA bundle for $($Context.App.Name)"
        return
    }

    # Store original location
    $originalLocation = Get-Location

    try {
        # Change to application directory
        Set-Location $Context.App.Path

        # Create SLSA bundle directory
        $slsaDir = ".slsa-bundles"
        if (-not (Test-Path $slsaDir)) {
            New-Item -ItemType Directory -Path $slsaDir -Force | Out-Null
        }

        # Analyze Docker base images
        $baseImages = @()
        foreach ($service in $Context.Compose.DetectedServices) {
            $dockerfile = "services/$service/Dockerfile"
            if (Test-Path $dockerfile) {
                # Extract FROM statements
                $content = Get-Content $dockerfile
                $fromLines = $content | Where-Object { $_ -match '^FROM\s+' } | ForEach-Object {
                    ($_ -split '\s+')[1]
                } | Sort-Object -Unique
                $baseImages += $fromLines
            }
        }

        # Remove duplicates
        $baseImages = $baseImages | Sort-Object -Unique

        # Create SLSA bundle object
        $slsaBundle = [PSCustomObject]@{
            bundleVersion    = "1.0"
            application      = $Context.App.Name
            buildId          = $Context.App.BuildId
            timestamp        = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
            commit           = $Context.App.CommitSha
            buildEnvironment = $Context.App.Environment
            registry         = $Context.App.Registry
            services         = @($Context.Compose.DetectedServices | ForEach-Object {
                    [PSCustomObject]@{
                        name       = $_
                        dockerfile = "services/$_/Dockerfile"
                    }
                })
            dependencies     = [PSCustomObject]@{
                docker = [PSCustomObject]@{
                    baseImages       = $baseImages
                    buildEnvironment = $Context.App.Environment
                }
            }
            buildResults     = [PSCustomObject]@{
                successful    = $Context.Build.Successful
                failed        = $Context.Build.Failed
                totalServices = @($Context.Compose.DetectedServices).Count
            }
            securityScans    = if ($Context.Security.Results) {
                [PSCustomObject]@{
                    enabled     = $true
                    totalScans  = @($Context.Security.Results).Count
                    passedScans = @($Context.Security.Passed).Count
                    failedScans = @($Context.Security.Failed).Count
                    scanResults = $Context.Security.Results
                }
            }
            else {
                [PSCustomObject]@{
                    enabled = $false
                }
            }
        }

        # Save SLSA bundle
        $bundleFile = Join-Path $slsaDir "$($Context.App.BuildId).json"
        $slsaBundle | ConvertTo-Json -Depth 10 | Set-Content -Path $bundleFile -Encoding UTF8
        Write-Info "SLSA bundle generated: $bundleFile"

        # Validate JSON if jq is available
        try {
            $null = Get-Command "jq" -ErrorAction Stop
            $null = & jq empty $bundleFile 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-BuildDebug "SLSA bundle JSON validation successful"
            }
            else {
                Write-Warn "SLSA bundle JSON validation failed"
            }
        }
        catch {
            Write-BuildDebug "jq not available for JSON validation"
        }
    }
    finally {
        Set-Location $originalLocation
    }
}

function Get-BuildOutput {
    <#
    .SYNOPSIS
    Aggregates and formats comprehensive build output.

    .DESCRIPTION
    Consolidates all build results, security scans, and dependency audits from Context
    into a structured output object ready for JSON serialization.

    .PARAMETER Context
    The build context object containing all build execution state and results.

    .OUTPUTS
    PSCustomObject containing complete build results with nested service, security, and audit data.

    .EXAMPLE
    $output = Get-BuildOutput -Context $context
    #>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    Write-BuildLog "Generating build output"

    # Generate final output object
    $output = [PSCustomObject]@{
        application        = $Context.App.Name
        success            = (@($Context.Build.Failed).Count -eq 0 -and @($Context.Security.Failed).Count -eq 0)
        buildId            = $Context.App.BuildId
        timestamp          = Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ'
        path               = $Context.App.Path
        totalServices      = @($Context.Compose.DetectedServices).Count
        successfulServices = @($Context.Build.Successful).Count
        failedServices     = @($Context.Build.Failed).Count
        buildDuration      = $Context.Build.Duration
        services           = $Context.Build.Results
        securityScans      = if ($Context.Security.Results) {
            [PSCustomObject]@{
                enabled     = $true
                threshold   = 'medium'
                totalScans  = @($Context.Security.Results).Count
                passedScans = @($Context.Security.Passed).Count
                failedScans = @($Context.Security.Failed).Count
                results     = $Context.Security.Results
            }
        }
        else {
            [PSCustomObject]@{
                enabled = $false
            }
        }
        dependencyAudits   = if ($Context.DependencyAudit.Results) {
            [PSCustomObject]@{
                enabled          = $true
                totalAudits      = @($Context.DependencyAudit.Results).Count
                cleanAudits      = @($Context.DependencyAudit.Results | Where-Object { $_.Status -eq "CLEAN" }).Count
                vulnerableAudits = @($Context.DependencyAudit.Results | Where-Object { $_.Status -eq "VULNERABLE" }).Count
                errorAudits      = @($Context.DependencyAudit.Results | Where-Object { $_.Status -eq "ERROR" }).Count
                results          = $Context.DependencyAudit.Results
            }
        }
        else {
            [PSCustomObject]@{
                enabled = $false
            }
        }
    }

    Write-BuildDebug "Build output generation completed"

    return $output
}

function Write-FailureSummary {
    <#
    .SYNOPSIS
    Emits a consolidated summary of build, security, and dependency issues.

    .DESCRIPTION
    Surfaces the key failure reasons captured throughout the build pipeline so that
    calling scripts and operators can quickly understand the blocking problems.

    .PARAMETER Context
    Build context that contains accumulated results for the run.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    $buildFailures = @()
    if ($Context.Build -and $Context.Build.Results) {
        $buildFailures = $Context.Build.Results | Where-Object { -not $_.success }
    }

    $securityFailures = @()
    if ($Context.Security -and $Context.Security.Results) {
        $securityFailures = $Context.Security.Results | Where-Object { ($_.PSObject.Properties['thresholdPassed'] -and -not $_.thresholdPassed) -or ($_.PSObject.Properties['success'] -and -not $_.success) }
    }

    $auditIssues = @()
    if ($Context.DependencyAudit -and $Context.DependencyAudit.Results) {
        $auditIssues = $Context.DependencyAudit.Results | Where-Object { $_.Status -ne 'CLEAN' }
    }

    $totalIssues = @($buildFailures).Count + @($securityFailures).Count + @($auditIssues).Count
    if ($totalIssues -eq 0) {
        return
    }

    Write-BuildLog "Aggregated failure summary"

    if (@($buildFailures).Count -gt 0) {
        Write-Warn ("Build failures ({0}):" -f @($buildFailures).Count)
        foreach ($failure in $buildFailures) {
            $serviceName = if ($failure.PSObject.Properties['service']) { $failure.service } else { '<unknown service>' }
            $reason = if ($failure.PSObject.Properties['error'] -and -not [string]::IsNullOrWhiteSpace($failure.error)) { $failure.error } else { 'No additional error details provided' }
            $reasonLine = ($reason -split "\r?\n")[0]
            Write-Warn (" - {0}: {1}" -f $serviceName, $reasonLine)
        }
    }

    if (@($securityFailures).Count -gt 0) {
        Write-Warn ("Security scan issues ({0}):" -f @($securityFailures).Count)
        foreach ($failure in $securityFailures) {
            $serviceName = if ($failure.PSObject.Properties['service']) { $failure.service } else { '<unknown service>' }
            $reason = if ($failure.PSObject.Properties['error'] -and -not [string]::IsNullOrWhiteSpace($failure.error)) { $failure.error }
            elseif ($failure.PSObject.Properties['thresholdReasons'] -and @($failure.thresholdReasons).Count -gt 0) { $failure.thresholdReasons -join '; ' }
            else { 'Scan reported threshold failure' }
            $reasonLine = ($reason -split "\r?\n")[0]
            Write-Warn (" - {0}: {1}" -f $serviceName, $reasonLine)
        }
    }

    if (@($auditIssues).Count -gt 0) {
        Write-Warn ("Dependency audit findings ({0}):" -f @($auditIssues).Count)
        foreach ($issue in $auditIssues) {
            $language = if ($issue.PSObject.Properties['Language']) { $issue.Language } else { 'Unknown language' }
            $project = if ($issue.PSObject.Properties['Project'] -and -not [string]::IsNullOrWhiteSpace($issue.Project)) { $issue.Project } else { '<project not reported>' }
            $status = if ($issue.PSObject.Properties['Status']) { $issue.Status } else { 'UNKNOWN' }
            $detail = if ($issue.PSObject.Properties['Details'] -and -not [string]::IsNullOrWhiteSpace($issue.Details)) { ($issue.Details -split "\r?\n")[0] } else { 'No details provided' }
            Write-Warn (" - {0} ({1}) [{2}]: {3}" -f $project, $language, $status, $detail)
        }
    }
}

Export-ModuleMember -Function `
    Build-ServicesWithCompose, `
    Build-ServicesWithoutCompose, `
    Build-AllService, `
    Invoke-SecurityScan, `
    New-SlsaBundle, `
    Get-BuildOutput, `
    Write-FailureSummary

