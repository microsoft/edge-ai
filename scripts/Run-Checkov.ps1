<#
.SYNOPSIS
    Runs Checkov security scanner on folders identified by Detect-Folder-Changes.ps1 and aggregates results.

.DESCRIPTION
    This script processes JSON output from Detect-Folder-Changes.ps1, runs Checkov security scanner on each identified
    folder, and aggregates all results into a single JUnit XML file. It handles both Terraform and Bicep files,
    and deduplicates any redundant findings in the final report.

    When the -UseExistingData switch is specified, the script will skip the Checkov scanning phase
    and use existing report files in the output folder to generate the final aggregated report.

.PARAMETER InputJson
    The JSON output from Detect-Folder-Changes.ps1. If omitted, will look for input from pipeline.

.PARAMETER OutputFolder
    The folder to store temporary and final Checkov reports. Default is "./checkov-results".

.PARAMETER OutputFile
    The name of the final aggregated XML report file. Default is "code-analysis.xml".

.PARAMETER UseExistingData
    Switch to skip the Checkov scanning phase and use existing report files for XML integration.

.EXAMPLE
    # Run with explicit JSON input
    .\Run-Checkov.ps1 -InputJson $jsonData

.EXAMPLE
    # Run by piping from Detect-Folder-Changes.ps1
    .\Detect-Folder-Changes.ps1 | .\Run-Checkov.ps1

.EXAMPLE
    # Run with custom output location
    .\Run-Checkov.ps1 -OutputFolder "./security-reports" -OutputFile "security-results.xml"

.EXAMPLE
    # Use existing data for report generation only
    .\Run-Checkov.ps1 -UseExistingData -OutputFolder "./checkov-results"

.OUTPUTS
    String containing the path to the aggregated JUnit XML report file.
#>

param(
    [Parameter(Mandatory = $false, ValueFromPipeline = $true)]
    [string]$InputJson,

    [Parameter(Mandatory = $false)]
    [string]$OutputFolder = "./checkov-results",

    [Parameter(Mandatory = $false)]
    [string]$OutputFile = "code-analysis.xml",

    [Parameter(Mandatory = $false)]
    [switch]$UseExistingData
)

begin {
    # Initialize variables to capture pipeline input if coming from pipeline
    $pipelineInput = ""
}

process {
    # If input is coming from pipeline, accumulate it
    if ($_ -ne $null) {
        $pipelineInput += $_
    }
}

end {
    # If InputJson wasn't provided but we got pipeline input, use that
    if ([string]::IsNullOrEmpty($InputJson) -and -not [string]::IsNullOrEmpty($pipelineInput)) {
        $InputJson = $pipelineInput
    }

    # Helper function to execute a process with proper output capture
    function Invoke-ProcessWithOutput {
        param (
            [Parameter(Mandatory = $true)]
            [string]$FilePath,

            [Parameter(Mandatory = $false)]
            [string[]]$ArgumentList,

            [Parameter(Mandatory = $false)]
            [switch]$NoThrow
        )

        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = $FilePath
        if ($ArgumentList) {
            $processStartInfo.Arguments = $ArgumentList
        }
        $processStartInfo.RedirectStandardOutput = $true
        $processStartInfo.RedirectStandardError = $true
        $processStartInfo.UseShellExecute = $false
        $processStartInfo.CreateNoWindow = $true

        $process = New-Object System.Diagnostics.Process
        $process.StartInfo = $processStartInfo

        # Create result object
        $result = [PSCustomObject]@{
            ExitCode = $null
            StdOut = ""
            StdErr = ""
            Success = $false
        }

        try {
            $process.Start() | Out-Null

            # Capture output streams
            $result.StdOut = $process.StandardOutput.ReadToEnd()
            $result.StdErr = $process.StandardError.ReadToEnd()
            $process.WaitForExit()
            $result.ExitCode = $process.ExitCode
            $result.Success = ($process.ExitCode -eq 0)

            if (-not $result.Success -and -not $NoThrow) {
                throw "Process '$FilePath' failed with exit code $($result.ExitCode): $($result.StdErr)"
            }

            return $result
        }
        catch {
            if (-not $NoThrow) {
                throw "Failed to execute process '$FilePath': $_"
            }
            $result.StdErr = $_.Exception.Message
            return $result
        }
    }

    function Get-CheckovVersion {
        try {
            # Use our helper function to run the checkov version command
            $versionResult = Invoke-ProcessWithOutput -FilePath "checkov" -ArgumentList "--version" -NoThrow
            if ($versionResult.Success) {
                # Parse the version from the output
                $versionOutput = $versionResult.StdOut.Trim()
                $versionMatch = [regex]::Match($versionOutput, '\d+\.\d+\.\d+')
                if ($versionMatch.Success) {
                    return $versionMatch.Value
                }
            }
            return $null
        }
        catch {
            return $null
        }
    }

    function Initialize-CheckovEnvironment {
        # Try to find Checkov version from the project requirements.txt file
        $requiredVersion = $null
        $requirementsFile = "$PSScriptRoot/../requirements.txt"

        if (Test-Path -Path $requirementsFile) {
            Write-Host "Reading requirements from: $requirementsFile"
            $requirements = Get-Content -Path $requirementsFile
            $checkovRequirement = $requirements | Where-Object { $_ -match "^checkov[~=]=(.+)" }
            if ($checkovRequirement) {
                # Handle both exact versions (==) and compatible versions (~=)
                $requiredVersion = $checkovRequirement -replace "^checkov[~=]=", ""
                Write-Host "Found Checkov version in requirements.txt: $requiredVersion" -ForegroundColor Green
            }
        }

        # Upgrade pip first to avoid common installation issues
        Write-Host "Upgrading pip..." -ForegroundColor Gray
        Invoke-ProcessWithOutput -FilePath "pip" -ArgumentList "install", "--upgrade", "pip" -NoThrow | Out-Null

        # Check if Checkov is installed
        $currentVersion = Get-CheckovVersion

        if ($currentVersion) {
            Write-Host "Found Checkov: $currentVersion" -ForegroundColor Green

            # If we have a required version and it's different, update
            if ($requiredVersion -and $currentVersion -ne $requiredVersion) {
                Write-Host "Installing required Checkov version: $requiredVersion" -ForegroundColor Yellow

                # Simple install with upgrade flag
                Invoke-ProcessWithOutput -FilePath "pip" -ArgumentList "install", "--upgrade", "checkov==$requiredVersion" -NoThrow | Out-Null

                # Check if installation was successful
                $newVersion = Get-CheckovVersion
                if ($newVersion) {
                    Write-Host "Successfully installed Checkov $newVersion" -ForegroundColor Green
                }
            }
        }
        else {
            Write-Host "Checkov not found. Installing..." -ForegroundColor Yellow

            if ($requiredVersion) {
                # Try to install the specific version
                Write-Host "Installing Checkov version $requiredVersion" -ForegroundColor Yellow
                $result = Invoke-ProcessWithOutput -FilePath "pip" -ArgumentList "install", "checkov==$requiredVersion" -NoThrow

                # If it fails, just install the latest version
                if (-not $result.Success) {
                    Write-Host "Failed to install specific version. Installing latest version..." -ForegroundColor Yellow
                    Invoke-ProcessWithOutput -FilePath "pip" -ArgumentList "install", "checkov" -NoThrow | Out-Null
                }
            }
            else {
                # If no specific version is required, install the latest
                Invoke-ProcessWithOutput -FilePath "pip" -ArgumentList "install", "checkov" -NoThrow | Out-Null
            }

            # Final verification
            $installedVersion = Get-CheckovVersion
            if ($installedVersion) {
                Write-Host "Installed Checkov: $installedVersion" -ForegroundColor Green
            }
            else {
                Write-Warning "Failed to install Checkov. Please install it manually."
            }
        }
    }

    function Get-FoldersToScan {
        param (
            [Parameter(Mandatory = $true)]
            [string]$InputJson
        )

        $foldersToScan = @()

        try {
            # Convert JSON string to PowerShell object
            $folderData = $InputJson | ConvertFrom-Json

            # Extract Terraform folders if they exist
            if ($folderData.terraform.has_changes) {
                foreach ($folder in $folderData.terraform.folders.PSObject.Properties) {
                    $folderPath = $folder.Value.folderName
                    if (-not [string]::IsNullOrEmpty($folderPath) -and (Test-Path -Path $folderPath)) {
                        $foldersToScan += $folderPath
                    }
                }
            }

            # Extract Bicep folders if they exist
            if ($folderData.bicep.has_changes) {
                foreach ($folder in $folderData.bicep.folders.PSObject.Properties) {
                    $folderPath = $folder.Value.folderName
                    if (-not [string]::IsNullOrEmpty($folderPath) -and (Test-Path -Path $folderPath)) {
                        $foldersToScan += $folderPath
                    }
                }
            }

            # Deduplicate the folders
            $foldersToScan = $foldersToScan | Select-Object -Unique

            Write-Host "Found $($foldersToScan.Count) folders to scan"
            return $foldersToScan
        }
        catch {
            Write-Error "Error processing JSON input: $_"
            return @()
        }
    }

    function Invoke-CheckovScan {
        param (
            [Parameter(Mandatory = $true)]
            [string[]]$Folders,

            [Parameter(Mandatory = $true)]
            [string]$OutputFolder
        )

        $reportFiles = @()

        foreach ($folder in $Folders) {
            $folderSafe = $folder -replace '[/\\]', '_'
            $outputXml = Join-Path -Path $OutputFolder -ChildPath "checkov-$folderSafe"

            # Use the .checkov.yml config file directly
            $checkovConfigPath = "$PSScriptRoot/../.checkov.yml"
            # Always set the config file path
            $commandArgs = @("-d", $folder)
            $commandArgs += "--config-file"
            $commandArgs += $checkovConfigPath
            # Add output file path
            $commandArgs += "--output-file-path"
            $commandArgs += $outputXml

            # Show command for logging purposes
            $commandDisplay = "checkov " + ($commandArgs -join " ")
            Write-Host "Running: $commandDisplay" -ForegroundColor Gray

            try {
                # Use our helper function for executing Checkov
                $checkovResult = Invoke-ProcessWithOutput -FilePath "checkov" -ArgumentList $commandArgs -NoThrow

                # Check the exit code
                if (-not $checkovResult.Success) {
                    # Output any errors but don't fail the script
                    if ($checkovResult.StdErr) {
                        Write-Host "Checkov warning/error output: $($checkovResult.StdErr)" -ForegroundColor Yellow
                    }
                }

                # Check if file was created
                if (Test-Path -Path $outputXml) {
                    $reportFiles += $outputXml
                    Write-Host "Created report: $outputXml" -ForegroundColor Green
                }
                else {
                    # Create an empty XML file to avoid errors in the aggregation step
                    @'
<?xml version="1.0" encoding="UTF-8"?>
<testsuites name="Checkov" tests="0" errors="0" failures="0">
</testsuites>
'@ | Out-File -FilePath $outputXml -Encoding utf8
                    $reportFiles += $outputXml
                }
            }
            catch {
                Write-Host "Error scanning folder $folder : $_" -ForegroundColor Red
            }
        }

        return $reportFiles
    }

    function Get-ExistingReport {
        param (
            [Parameter(Mandatory = $true)]
            [string]$OutputFolder
        )

        # Find existing XML report files
        $reportFiles = Get-ChildItem -Path $OutputFolder -Recurse -Filter "results_junitxml.xml" |
                      Select-Object -ExpandProperty FullName

        Write-Host "Found $(($reportFiles | Measure-Object).Count) existing report files to aggregate" -ForegroundColor Cyan
        return $reportFiles
    }

    function Merge-CheckovReport {
        param (
            [Parameter(Mandatory = $true)]
            [string[]]$ReportFiles,

            [Parameter(Mandatory = $true)]
            [string]$OutputPath
        )

        try {
            # Load the XML files
            $combinedXml = [xml]'<?xml version="1.0" encoding="UTF-8"?><testsuites name="Checkov" tests="0" errors="0" failures="0"></testsuites>'
            $totalTests = 0
            $totalFailures = 0
            $totalErrors = 0

            # Track seen test cases by their signature to deduplicate
            $seenTestCases = @{}

            foreach ($reportFile in $ReportFiles) {
                try {
                    # Check if the report file is actually a directory
                    if (Test-Path -Path $reportFile -PathType Container) {
                        # Look for results_junitxml.xml inside the directory
                        $actualReportFile = Join-Path -Path $reportFile -ChildPath "results_junitxml.xml"
                        if (Test-Path -Path $actualReportFile -PathType Leaf) {
                            $reportFile = $actualReportFile
                        }
                        else {
                            Write-Warning "No results_junitxml.xml found in directory: $reportFile"
                            continue # Skip this directory
                        }
                    }

                    # Check if file exists and is not empty
                    if (-not (Test-Path -Path $reportFile -PathType Leaf) -or (Get-Item $reportFile).Length -eq 0) {
                        Write-Warning "File not found or empty: $reportFile"
                        continue
                    }

                    try {
                        $xmlContent = Get-Content -Path $reportFile -Encoding UTF8 -Raw -ErrorAction Stop

                        # First check if there's actually any content
                        if ([string]::IsNullOrWhiteSpace($xmlContent)) {
                            Write-Warning "Empty XML content in file: $reportFile"
                            continue
                        }

                        # Try to load the XML
                        $xml = [xml]$xmlContent

                        # Check if XML has the expected structure before processing
                        if ($null -ne $xml -and $null -ne $xml.testsuites) {
                            # Process each testsuite - handle case where there might be none
                            if ($null -ne $xml.testsuites.testsuite) {
                                $testsuites = @($xml.testsuites.testsuite)

                                foreach ($testsuite in $testsuites) {
                                    # Create or find matching testsuite in the combined XML
                                    $existingSuite = $combinedXml.testsuites.testsuite | Where-Object { $_.name -eq $testsuite.name }

                                    if ($null -eq $existingSuite) {
                                        $newSuite = $combinedXml.CreateElement("testsuite")
                                        $newSuite.SetAttribute("name", $testsuite.name)
                                        $newSuite.SetAttribute("tests", $testsuite.tests)
                                        $newSuite.SetAttribute("failures", $testsuite.failures)
                                        $newSuite.SetAttribute("errors", $testsuite.errors)
                                        $newSuite.SetAttribute("time", $testsuite.time)
                                        $combinedXml.testsuites.AppendChild($newSuite) | Out-Null
                                        $existingSuite = $newSuite
                                    }
                                    else {
                                        # Update the counters for existing suite
                                        $existingSuite.tests = ([int]$existingSuite.tests + [int]$testsuite.tests).ToString()
                                        $existingSuite.failures = ([int]$existingSuite.failures + [int]$testsuite.failures).ToString()
                                        $existingSuite.errors = ([int]$existingSuite.errors + [int]$testsuite.errors).ToString()
                                    }

                                    # Add testcases, checking for duplicates
                                    if ($null -ne $testsuite.testcase) {
                                        # Handle both single testcase and multiple testcases
                                        $testcases = @($testsuite.testcase)

                                        foreach ($testcase in $testcases) {
                                            # Create a signature for the test case to identify duplicates
                                            $signature = "$($testcase.name)::$($testcase.classname)"

                                            if (-not $seenTestCases.ContainsKey($signature)) {
                                                $seenTestCases[$signature] = $true
                                                # Clone the testcase node
                                                $newTestCase = $combinedXml.ImportNode($testcase, $true)
                                                $existingSuite.AppendChild($newTestCase) | Out-Null

                                                # Update counters
                                                $totalTests++
                                                if ($testcase.failure) {
                                                    $totalFailures++
                                                }
                                                if ($testcase.error) {
                                                    $totalErrors++
                                                }
                                            }
                                        }
                                    }
                                }
                            } else {
                                Write-Warning "No testsuite elements found in XML file: $reportFile"
                            }
                        } else {
                            Write-Warning "XML file has unexpected structure (missing testsuites element): $reportFile"
                        }
                    }
                    catch [System.Xml.XmlException] {
                        Write-Warning "XML parsing error in file $reportFile : $($_.Exception.Message)"
                    }
                }
                catch {
                    Write-Warning "Could not read or process file $reportFile : $_"
                }
            }

            # Update the root element counters
            $combinedXml.testsuites.tests = $totalTests.ToString()
            $combinedXml.testsuites.failures = $totalFailures.ToString()
            $combinedXml.testsuites.errors = $totalErrors.ToString()

            # Save the combined XML
            $combinedXml.Save($OutputPath)
            Write-Host "Successfully created aggregated report with $totalTests tests, $totalFailures failures at: $OutputPath" -ForegroundColor Green

            # Return the path to the final XML file
            return $OutputPath
        }
        catch {
            Write-Error "Error aggregating XML reports: $_"
            return $null
        }
    }

    # Main execution flow
    # Ensure OutputFolder exists and clean if needed
    if (-not (Test-Path -Path $OutputFolder)) {
        New-Item -Path $OutputFolder -ItemType Directory | Out-Null
        Write-Host "Created output directory: $OutputFolder"
    }
    elseif (-not $UseExistingData) {
        Get-ChildItem -Path $OutputFolder -Recurse | Remove-Item -Force -Recurse
        Write-Host "Cleaned existing output directory (including subdirectories): $OutputFolder"
    }
    else {
        Write-Host "Using existing data in: $OutputFolder"
    }

    # Initialize Checkov environment
    Initialize-CheckovEnvironment

    # Create final output path
    $finalOutputPath = Join-Path -Path $OutputFolder -ChildPath $OutputFile
    $reportFiles = @()

    if ($UseExistingData) {
        # Use existing report files
        $reportFiles = Get-ExistingReport -OutputFolder $OutputFolder
    }
    elseif (-not [string]::IsNullOrWhiteSpace($InputJson)) {
        Write-Host "Processing input JSON (length: $($InputJson.Length))"
        # Get folders to scan from input JSON
        $foldersToScan = Get-FoldersToScan -InputJson $InputJson

        if ($foldersToScan.Count -gt 0) {
            # Run Checkov on the folders
            $reportFiles = Invoke-CheckovScan -Folders $foldersToScan -OutputFolder $OutputFolder
        }
        else {
            Write-Host "No valid folders to scan." -ForegroundColor Yellow
        }
    }
    else {
        Write-Host "No input JSON provided and UseExistingData not specified. Cannot proceed." -ForegroundColor Yellow
        return $null
    }

    # If we have reports, merge them
    if ($reportFiles.Count -gt 0) {
        return Merge-CheckovReport -ReportFiles $reportFiles -OutputPath $finalOutputPath
    }
    else {
        Write-Host "No reports to aggregate" -ForegroundColor Yellow
        return $null
    }
}
