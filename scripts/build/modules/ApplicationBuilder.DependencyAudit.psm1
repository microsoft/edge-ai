Set-StrictMode -Version Latest

function Test-DependencyAudit {
    <#
    .SYNOPSIS
    Executes multi-language dependency vulnerability audits.

    .DESCRIPTION
    Scans application dependencies for known security vulnerabilities across
    multiple languages (.NET, Rust, Node.js, Python). Detects project files,
    executes language-specific audit tools, aggregates results, and updates
    build context with vulnerability findings. Returns true if no vulnerabilities
    or errors are found.

    .PARAMETER Context
    The build context object containing application path and audit result storage.

    .OUTPUTS
    System.Boolean
    True if all dependency audits pass with no vulnerabilities or errors, false otherwise.

    .EXAMPLE
    $auditPassed = Test-DependencyAudit -Context $context
    if (-not $auditPassed) {
        Write-Warning "Vulnerabilities detected in dependencies"
    }
    #>
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    Write-BuildLog "Running language-specific dependency audits"

    $auditResults = @()
    $originalLocation = Get-Location

    try {
        $projectPath = $Context.App.Path

        if ([string]::IsNullOrWhiteSpace($projectPath) -or -not (Test-Path $projectPath)) {
            throw "Invalid project path provided for dependency audit"
        }

        Set-Location $projectPath

        # .NET Projects - Check for vulnerable packages
        $dotnetSolutions = Get-ChildItem -Recurse -Filter "*.sln" -ErrorAction SilentlyContinue
        $dotnetProjects = Get-ChildItem -Recurse -Filter "*.csproj" -ErrorAction SilentlyContinue
        $dotnetTargets = @()

        if ($dotnetSolutions) {
            $dotnetTargets = $dotnetSolutions
        }
        elseif ($dotnetProjects) {
            $dotnetTargets = $dotnetProjects
        }

        if (@($dotnetTargets).Count -gt 0) {
            Write-Info "Scanning .NET dependencies for vulnerabilities..."

            $dotnetCli = Get-Command "dotnet" -ErrorAction SilentlyContinue
            if (-not $dotnetCli) {
                Write-Warn "dotnet CLI not available; skipping .NET dependency audit"
                foreach ($target in $dotnetTargets) {
                    $auditResults += [PSCustomObject]@{
                        Language = ".NET"
                        Status   = "ERROR"
                        Details  = "dotnet CLI not available"
                        Project  = $target.FullName
                    }
                }
            }
            else {
                foreach ($target in $dotnetTargets) {
                    $targetPath = $target.FullName
                    $targetLabel = if ($target -is [System.IO.FileInfo]) { $target.Name } else { $targetPath }

                    try {
                        Write-BuildDebug "Running dotnet restore for $targetLabel to ensure assets file exists"
                        $restoreOutput = & $dotnetCli.Source restore $targetPath 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            Write-Warn ("dotnet restore failed for {0}" -f $targetLabel)
                            Write-BuildDebug ($restoreOutput | Out-String)
                        }

                        $dotnetAudit = & $dotnetCli.Source list $targetPath package --vulnerable --include-transitive --format json 2>&1
                        $dotnetAuditOutput = $dotnetAudit -join "`n"

                        $auditJson = $null
                        try {
                            $auditJson = $dotnetAuditOutput | ConvertFrom-Json -ErrorAction Stop
                        }
                        catch {
                            if ($LASTEXITCODE -ne 0) {
                                $errorPreview = if ($dotnetAuditOutput.Length -gt 200) {
                                    $dotnetAuditOutput.Substring(0, 200) + "..."
                                }
                                else {
                                    $dotnetAuditOutput
                                }
                                Write-Warn ("dotnet list package failed for {0} (invalid JSON): {1}" -f $targetLabel, $errorPreview)
                                $auditResults += [PSCustomObject]@{
                                    Language = ".NET"
                                    Status   = "ERROR"
                                    Details  = $dotnetAuditOutput
                                    Project  = $targetPath
                                }
                                continue
                            }
                        }

                        if ($null -eq $auditJson) {
                            continue
                        }

                        $hasProblems = $auditJson.PSObject.Properties.Name -contains 'problems'
                        if ($hasProblems -and @($auditJson.problems).Count -gt 0) {
                            $problemDetails = ($auditJson.problems | ForEach-Object { $_.text }) -join "; "
                            Write-Warn ("dotnet list package reported problems for {0}: {1}" -f $targetLabel, $problemDetails)
                            $auditResults += [PSCustomObject]@{
                                Language = ".NET"
                                Status   = "ERROR"
                                Details  = $problemDetails
                                Project  = $targetPath
                            }
                            continue
                        }

                        $vulnerablePackages = @()
                        if ($null -ne $auditJson.projects) {
                            foreach ($project in $auditJson.projects) {
                                $hasFrameworks = $project.PSObject.Properties.Name -contains 'frameworks'
                                if ($hasFrameworks -and $null -ne $project.frameworks) {
                                    foreach ($framework in $project.frameworks) {
                                        if ($null -ne $framework.topLevelPackages) {
                                            $vulnerablePackages += $framework.topLevelPackages | Where-Object { $null -ne $_.vulnerabilities }
                                        }
                                        if ($null -ne $framework.transitivePackages) {
                                            $vulnerablePackages += $framework.transitivePackages | Where-Object { $null -ne $_.vulnerabilities }
                                        }
                                    }
                                }
                            }
                        }

                        if (@($vulnerablePackages).Count -gt 0) {
                            $vulnDetails = @()
                            foreach ($pkg in $vulnerablePackages) {
                                foreach ($vuln in $pkg.vulnerabilities) {
                                    $vulnDetails += "$($pkg.id) $($pkg.resolvedVersion): $($vuln.severity) - $($vuln.advisoryUrl)"
                                }
                            }
                            $detailsText = $vulnDetails -join "`n"
                            Write-Warn ("⚠️  .NET vulnerable dependencies detected in {0}" -f $targetLabel)
                            $auditResults += [PSCustomObject]@{
                                Language = ".NET"
                                Status   = "VULNERABLE"
                                Details  = $detailsText
                                Project  = $targetPath
                            }
                        }
                        else {
                            Write-Info ("✅ No .NET vulnerable dependencies found in {0}" -f $targetLabel)
                            $auditResults += [PSCustomObject]@{
                                Language = ".NET"
                                Status   = "CLEAN"
                                Details  = "No vulnerable dependencies detected"
                                Project  = $targetPath
                            }
                        }
                    }
                    catch {
                        $errorRecord = $_
                        Write-Warn ("Failed to run dotnet list package for {0}: {1}" -f $targetLabel, $errorRecord)
                        $auditResults += [PSCustomObject]@{
                            Language = ".NET"
                            Status   = "ERROR"
                            Details  = ("Audit failed: {0}" -f $errorRecord)
                            Project  = $targetPath
                        }
                    }
                }
            }
        }

        # Rust Projects - cargo audit
        $rustManifests = Get-ChildItem -Recurse -Filter "Cargo.toml" -ErrorAction SilentlyContinue
        if ($rustManifests) {
            Write-Info "Scanning Rust dependencies for vulnerabilities..."

            $cargoCommand = Get-Command "cargo" -ErrorAction SilentlyContinue
            if (-not $cargoCommand) {
                Write-Warn "cargo CLI not available; skipping Rust dependency audit"
                foreach ($manifest in $rustManifests) {
                    $auditResults += [PSCustomObject]@{
                        Language = "Rust"
                        Status   = "ERROR"
                        Details  = "cargo CLI not available"
                        Project  = $manifest.DirectoryName
                    }
                }
            }
            else {
                $cargoExecutable = $cargoCommand.Source
                $cargoAuditAvailable = $false

                try {
                    & $cargoExecutable audit --version 2>$null
                    $cargoAuditAvailable = ($LASTEXITCODE -eq 0)
                }
                catch {
                    $cargoAuditAvailable = $false
                }

                if (-not $cargoAuditAvailable) {
                    try {
                        Write-Info "Installing cargo-audit..."
                        $installOutput = & $cargoExecutable install cargo-audit --locked 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "cargo-audit installation failed: $($installOutput -join '`n')"
                        }

                        & $cargoExecutable audit --version 2>$null
                        $cargoAuditAvailable = ($LASTEXITCODE -eq 0)
                    }
                    catch {
                        $errorRecord = $_
                        Write-Warn ("Unable to prepare cargo-audit: {0}" -f $errorRecord)
                        foreach ($manifest in $rustManifests) {
                            $auditResults += [PSCustomObject]@{
                                Language = "Rust"
                                Status   = "ERROR"
                                Details  = ("cargo-audit unavailable: {0}" -f $errorRecord)
                                Project  = $manifest.DirectoryName
                            }
                        }
                    }
                }

                if ($cargoAuditAvailable) {
                    $lockTargetMap = @{}

                    foreach ($manifest in $rustManifests) {
                        $projectDir = $manifest.DirectoryName
                        $projectRelative = [System.IO.Path]::GetRelativePath($Context.App.Path, $projectDir)
                        if ([string]::IsNullOrWhiteSpace($projectRelative) -or $projectRelative -eq "." -or $projectRelative.StartsWith("..")) {
                            $projectRelative = $projectDir
                        }

                        $lockFilePath = Join-Path $projectDir "Cargo.lock"
                        $workspaceLock = $null
                        $metadataError = $null

                        if (-not (Test-Path $lockFilePath)) {
                            try {
                                $metadataOutput = & $cargoExecutable metadata --format-version 1 --no-deps --manifest-path $manifest.FullName
                                if ($LASTEXITCODE -eq 0 -and $metadataOutput) {
                                    $metadataJson = ($metadataOutput -join "`n")
                                    $metadata = $metadataJson | ConvertFrom-Json -ErrorAction Stop
                                    if ($metadata.workspace_root) {
                                        $workspaceLock = Join-Path $metadata.workspace_root "Cargo.lock"
                                        if (Test-Path $workspaceLock) {
                                            $lockFilePath = $workspaceLock
                                        }
                                    }
                                }
                            }
                            catch {
                                $metadataError = $_
                            }
                        }

                        if (-not (Test-Path $lockFilePath)) {
                            $details = "Cargo.lock not found for $projectRelative"
                            if ($workspaceLock) {
                                $details = "$details (expected at $workspaceLock)"
                            }
                            if ($metadataError) {
                                $details = "$details. Metadata error: $metadataError"
                            }

                            $auditResults += [PSCustomObject]@{
                                Language = "Rust"
                                Status   = "ERROR"
                                Details  = $details
                                Project  = $projectDir
                            }
                            continue
                        }

                        $lockFullPath = [System.IO.Path]::GetFullPath($lockFilePath)
                        if (-not $lockTargetMap.ContainsKey($lockFullPath)) {
                            $auditRoot = [System.IO.Path]::GetDirectoryName($lockFullPath)
                            $label = [System.IO.Path]::GetRelativePath($Context.App.Path, $auditRoot)
                            if ([string]::IsNullOrWhiteSpace($label) -or $label -eq "." -or $label.StartsWith("..")) {
                                $label = Split-Path -Path $auditRoot -Leaf
                            }

                            $lockTargetMap[$lockFullPath] = [PSCustomObject]@{
                                LockPath  = $lockFullPath
                                AuditRoot = $auditRoot
                                Label     = $label
                                Projects  = [System.Collections.Generic.List[string]]::new()
                            }
                        }

                        $lockTarget = $lockTargetMap[$lockFullPath]
                        if (-not $lockTarget.Projects.Contains($projectRelative)) {
                            $lockTarget.Projects.Add($projectRelative)
                        }
                    }

                    foreach ($target in $lockTargetMap.Values) {
                        try {
                            Push-Location -Path $target.AuditRoot
                            $lockName = Split-Path -Path $target.LockPath -Leaf
                            $rustAudit = & $cargoExecutable audit --file $lockName 2>&1
                            $rustAuditText = $rustAudit -join "`n"

                            if ($LASTEXITCODE -eq 0) {
                                Write-Info ("✅ No Rust vulnerable dependencies found in {0}" -f $target.Label)
                                $auditResults += [PSCustomObject]@{
                                    Language = "Rust"
                                    Status   = "CLEAN"
                                    Details  = "No vulnerable dependencies detected"
                                    Project  = ($target.Projects.ToArray() -join ", ")
                                }
                            }
                            elseif ($rustAuditText -match "error\s*:") {
                                Write-Warn ("Rust dependency audit failed for {0}" -f $target.Label)
                                $auditResults += [PSCustomObject]@{
                                    Language = "Rust"
                                    Status   = "ERROR"
                                    Details  = $rustAuditText
                                    Project  = ($target.Projects.ToArray() -join ", ")
                                }
                            }
                            else {
                                Write-Warn ("Rust vulnerable dependencies detected in {0}" -f $target.Label)
                                $auditResults += [PSCustomObject]@{
                                    Language = "Rust"
                                    Status   = "VULNERABLE"
                                    Details  = $rustAuditText
                                    Project  = ($target.Projects.ToArray() -join ", ")
                                }
                            }
                        }
                        catch {
                            $errorRecord = $_
                            Write-Warn ("Failed to run cargo audit for {0}: {1}" -f $target.Label, $errorRecord)
                            $auditResults += [PSCustomObject]@{
                                Language = "Rust"
                                Status   = "ERROR"
                                Details  = ("Audit failed: {0}" -f $errorRecord)
                                Project  = ($target.Projects.ToArray() -join ", ")
                            }
                        }
                        finally {
                            Pop-Location -ErrorAction SilentlyContinue
                        }
                    }
                }
            }
        }

        # Node.js Projects - npm audit for security vulnerabilities
        $packageJsonFiles = Get-ChildItem -Recurse -Filter "package.json" -ErrorAction SilentlyContinue
        if ($packageJsonFiles) {
            Write-Info "Scanning Node.js dependencies for vulnerabilities..."
            foreach ($packageJson in $packageJsonFiles) {
                $projectDir = $packageJson.DirectoryName
                try {
                    Set-Location $projectDir
                    $npmAudit = & npm audit --json 2>&1
                    $auditJson = $npmAudit | ConvertFrom-Json -ErrorAction SilentlyContinue

                    if ($auditJson.vulnerabilities -and $auditJson.vulnerabilities.PSObject.Properties.Count -gt 0) {
                        $vulnCount = $auditJson.metadata.vulnerabilities.total
                        $auditResults += [PSCustomObject]@{
                            Language = "Node.js"
                            Status   = "VULNERABLE"
                            Details  = "Found $vulnCount vulnerabilities in $($packageJson.DirectoryName)"
                            Project  = $projectDir
                        }
                        Write-Warn "Node.js vulnerable dependencies detected in $projectDir"
                    }
                    else {
                        Write-Info "✅ No Node.js vulnerable dependencies found in $projectDir"
                        $auditResults += [PSCustomObject]@{
                            Language = "Node.js"
                            Status   = "CLEAN"
                            Details  = "No vulnerable dependencies detected"
                            Project  = $projectDir
                        }
                    }
                }
                catch {
                    $errorRecord = $_
                    Write-Warn ("Failed to run npm audit in {0}: {1}" -f $projectDir, $errorRecord)
                    $auditResults += [PSCustomObject]@{
                        Language = "Node.js"
                        Status   = "ERROR"
                        Details  = ("Audit failed: {0}" -f $errorRecord)
                        Project  = $projectDir
                    }
                }
            }
        }

        # Python Projects - pip-audit for security vulnerabilities
        $pythonFiles = @()
        $pythonFiles += Get-ChildItem -Recurse -Filter "requirements.txt" -ErrorAction SilentlyContinue
        $pythonFiles += Get-ChildItem -Recurse -Filter "pyproject.toml" -ErrorAction SilentlyContinue
        $pythonFiles += Get-ChildItem -Recurse -Filter "setup.py" -ErrorAction SilentlyContinue

        if ($pythonFiles) {
            Write-Info "Scanning Python dependencies for vulnerabilities..."
            try {
                $pythonCommand = Get-Command "python" -ErrorAction SilentlyContinue
                if (-not $pythonCommand) {
                    $pythonCommand = Get-Command "python3" -ErrorAction SilentlyContinue
                }

                if (-not $pythonCommand) {
                    throw "Python interpreter not found; unable to execute pip-audit"
                }

                $pythonExecutable = $pythonCommand.Source
                $minimumPipVersion = [Version]"24.3.1"
                $pipAuditReady = $false

                try {
                    $pipVersionOutput = & $pythonExecutable -m pip --version 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        Write-BuildDebug "pip module invocation failed; trying pip3 command as fallback"
                        $pipVersionOutput = & pip3 --version 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "Unable to determine pip version using both 'python -m pip' and 'pip3' commands"
                        }
                    }

                    $pipVersionMatch = [regex]::Match($pipVersionOutput, "pip\s+([0-9]+(?:\.[0-9]+)+)")
                    if (-not $pipVersionMatch.Success) {
                        throw "Unable to parse pip version from output: $pipVersionOutput"
                    }

                    $currentPipVersion = [Version]$pipVersionMatch.Groups[1].Value
                    if ($currentPipVersion -lt $minimumPipVersion) {
                        Write-Info "Upgrading pip to $minimumPipVersion..."
                        & $pythonExecutable -m pip install --quiet "pip==$($minimumPipVersion.ToString())"
                        $pipVersionOutput = & $pythonExecutable -m pip --version 2>&1
                        if ($LASTEXITCODE -ne 0) {
                            throw "pip upgrade failed"
                        }

                        $pipVersionMatch = [regex]::Match($pipVersionOutput, "pip\s+([0-9]+(?:\.[0-9]+)+)")
                        if (-not $pipVersionMatch.Success) {
                            throw "Unable to verify pip version"
                        }

                        $currentPipVersion = [Version]$pipVersionMatch.Groups[1].Value
                        if ($currentPipVersion -lt $minimumPipVersion) {
                            throw "pip version remains below required minimum"
                        }
                    }
                    Write-Info "Using pip version $currentPipVersion"
                }
                catch {
                    throw "Failed to ensure minimum pip version: $_"
                }

                try {
                    & $pythonExecutable -m pip_audit --version 2>$null
                    $pipAuditReady = ($LASTEXITCODE -eq 0)
                }
                catch {
                    $pipAuditReady = $false
                }

                if (-not $pipAuditReady) {
                    Write-Info "Installing pip-audit..."
                    & $pythonExecutable -m pip install pip-audit --quiet
                    if ($LASTEXITCODE -ne 0) {
                        throw "pip-audit installation failed with exit code $LASTEXITCODE"
                    }
                    & $pythonExecutable -m pip_audit --version 2>$null
                    if ($LASTEXITCODE -ne 0) {
                        throw "pip-audit installation verification failed"
                    }
                }

                Write-BuildDebug "Running pip-audit with JSON format..."
                $pythonAudit = & $pythonExecutable -m pip_audit --format=json --progress-spinner=off 2>&1
                $pipAuditExitCode = $LASTEXITCODE
                Write-BuildDebug "pip-audit exit code: $pipAuditExitCode"

                # Determine project path from first Python dependency file found
                $projectPath = if ($pythonFiles.Count -gt 0) {
                    $pythonFiles[0].DirectoryName
                }
                else {
                    $PWD.Path
                }

                # Enhanced debugging: Log raw pip-audit output for troubleshooting
                $pythonAuditText = $pythonAudit -join "`n"

                # Filter out non-JSON lines (summary messages from pip-audit)
                # pip-audit may output a summary line before the JSON: "Found X known vulnerabilities in Y packages"
                $jsonLines = $pythonAudit | Where-Object { $_ -match '^\s*[\[\{]' }
                $pythonAuditText = $jsonLines -join "`n"

                if ($pythonAuditText.Length -gt 500) {
                    Write-BuildDebug "pip-audit raw output (first 500 chars): $($pythonAuditText.Substring(0, 500))..."
                }
                else {
                    Write-BuildDebug "pip-audit raw output: $pythonAuditText"
                }

                # Validate output is JSON before attempting to parse
                $isJsonOutput = $false
                if (-not [string]::IsNullOrWhiteSpace($pythonAuditText)) {
                    $trimmedOutput = $pythonAuditText.TrimStart()
                    $isJsonOutput = $trimmedOutput -match '^[\[\{]'

                    if (-not $isJsonOutput) {
                        Write-Warn "pip-audit did not return JSON output. First character: '$($trimmedOutput[0])'. This typically indicates an error message instead of JSON."
                        Write-BuildDebug "Non-JSON output detected. Full output: $pythonAuditText"
                    }
                }
                else {
                    Write-Warn "pip-audit returned empty output"
                }

                if ($pipAuditExitCode -eq 0) {
                    Write-Info "✅ No Python vulnerable dependencies found"
                    $auditResults += [PSCustomObject]@{
                        Language = "Python"
                        Status   = "CLEAN"
                        Details  = "No vulnerable dependencies detected"
                        Project  = $projectPath
                    }
                }
                elseif ($pipAuditExitCode -eq 1) {
                    # Exit code 1 means vulnerabilities were found (expected behavior)
                    $auditJson = $null

                    # Only attempt JSON parsing if output appears to be JSON
                    if ($isJsonOutput) {
                        try {
                            $auditJson = $pythonAuditText | ConvertFrom-Json -ErrorAction Stop
                        }
                        catch {
                            Write-Warn "JSON parsing failed: $_"
                            Write-BuildDebug "Failed JSON content: $pythonAuditText"
                        }
                    }

                    # Safe property access using PSObject.Properties to avoid exceptions
                    if ($auditJson -and
                        $auditJson.PSObject.Properties.Name -contains 'dependencies' -and
                        @($auditJson.dependencies).Count -gt 0) {

                        # Count packages with vulnerabilities using safe property access
                        $depsWithVulns = @($auditJson.dependencies | Where-Object {
                                $_.PSObject.Properties.Name -contains 'vulns' -and
                                $null -ne $_.vulns -and
                                @($_.vulns).Count -gt 0
                            })

                        $packageCount = $depsWithVulns.Count

                        # Safely extract vulns arrays with property existence checks
                        $totalVulns = @($depsWithVulns | ForEach-Object {
                                if ($_.PSObject.Properties.Name -contains 'vulns' -and $null -ne $_.vulns) {
                                    $_.vulns
                                }
                            }).Count

                        Write-Warn "⚠️  Found $totalVulns known vulnerabilities in $packageCount Python packages"
                        $auditResults += [PSCustomObject]@{
                            Language = "Python"
                            Status   = "VULNERABLE"
                            Details  = "Found $totalVulns known vulnerabilities in $packageCount packages"
                            Project  = $projectPath
                        }
                    }
                    else {
                        # Exit code 1 but no JSON parsed - treat as error
                        Write-Warn "pip-audit returned exit code 1 but output could not be parsed as JSON. Output: $pythonAuditText"
                        $auditResults += [PSCustomObject]@{
                            Language = "Python"
                            Status   = "ERROR"
                            Details  = "pip-audit output parsing failed (exit code 1, non-JSON output): $pythonAuditText"
                            Project  = $projectPath
                        }
                    }
                }
                else {
                    # Exit code >1 indicates actual error
                    Write-Warn "pip-audit failed with exit code $pipAuditExitCode. Output: $pythonAuditText"
                    $auditResults += [PSCustomObject]@{
                        Language = "Python"
                        Status   = "ERROR"
                        Details  = "pip-audit failed with exit code ${pipAuditExitCode}: $pythonAuditText"
                        Project  = $projectPath
                    }
                }
            }
            catch {
                $errorRecord = $_
                $projectPath = if ($pythonFiles.Count -gt 0) {
                    $pythonFiles[0].DirectoryName
                }
                else {
                    $PWD.Path
                }
                Write-Warn "Failed to run Python pip-audit: $errorRecord"
                $auditResults += [PSCustomObject]@{
                    Language = "Python"
                    Status   = "ERROR"
                    Details  = "Audit failed: $errorRecord"
                    Project  = $projectPath
                }
            }
        }

        # Store structured results in context for reporting
        $Context.DependencyAudit.Results = $auditResults

        $summary = [PSCustomObject]@{
            Total       = @($auditResults).Count
            Clean       = @($auditResults | Where-Object { $_.Status -eq "CLEAN" }).Count
            Vulnerable  = @($auditResults | Where-Object { $_.Status -eq "VULNERABLE" }).Count
            Errors      = @($auditResults | Where-Object { $_.Status -eq "ERROR" }).Count
            GeneratedAt = (Get-Date -Format 'yyyy-MM-ddTHH:mm:ssZ')
        }

        $Context.DependencyAudit.Summary = $summary

        Write-BuildLog ("Dependency audit summary recorded: Clean={0}, Vulnerable={1}, Errors={2}" -f $summary.Clean, $summary.Vulnerable, $summary.Errors)

        if ($summary.Vulnerable -gt 0) {
            Write-Warn ("Dependency audit detected {0} vulnerable result(s)" -f $summary.Vulnerable)
        }

        if ($summary.Errors -gt 0) {
            Write-Warn ("Dependency audit encountered {0} error result(s)" -f $summary.Errors)
        }

        # Return whether any vulnerabilities or errors were found
        return ($summary.Vulnerable -eq 0 -and $summary.Errors -eq 0)
    }
    finally {
        Set-Location $originalLocation
    }
}

Export-ModuleMember -Function Test-DependencyAudit

