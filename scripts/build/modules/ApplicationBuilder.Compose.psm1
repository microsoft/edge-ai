Set-StrictMode -Version Latest

function Test-ComposeRequirement {
    <#
    .SYNOPSIS
    Detects and validates Docker Compose availability.

    .DESCRIPTION
    Checks for Docker Compose availability by testing multiple executable candidates
    (docker compose, docker-compose). Updates the build context with the detected
    executable, required argument prefix, and availability status.

    .PARAMETER Context
    The build context object to update with Compose detection results.

    .OUTPUTS
    System.Boolean
    True if Docker Compose is available, false otherwise.

    .EXAMPLE
    $hasCompose = Test-ComposeRequirement -Context $context
    #>
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context
    )

    if ($null -eq $Context -or $null -eq $Context.Compose) {
        throw "Build context compose state is required"
    }

    if ($Context.Compose.Available -and -not [string]::IsNullOrWhiteSpace($Context.Compose.Executable)) {
        return $true
    }

    $Context.Compose.Available = $false
    $Context.Compose.Executable = $null
    $Context.Compose.ArgsPrefix = @()

    $candidates = @(
        [pscustomobject]@{
            Executable  = "docker"
            ArgsPrefix  = @("compose")
            VersionArgs = @("compose", "version")
            DisplayName = "docker compose"
        },
        [pscustomobject]@{
            Executable  = "docker-compose"
            ArgsPrefix  = @()
            VersionArgs = @("--version")
            DisplayName = "docker-compose"
        }
    )

    foreach ($candidate in $candidates) {
        try {
            $null = Get-Command -Name $candidate.Executable -ErrorAction Stop
            $null = & $candidate.Executable @($candidate.VersionArgs) 2>$null
            if ($LASTEXITCODE -ne 0) {
                continue
            }

            $Context.Compose.Executable = $candidate.Executable
            $Context.Compose.ArgsPrefix = $candidate.ArgsPrefix
            $Context.Compose.Available = $true
            Write-BuildDebug ("Compose executable detected: {0}" -f $candidate.DisplayName)
            return $true
        }
        catch {
            continue
        }
    }

    Write-Warn "Docker Compose not available; builds will use docker build fallback"
    return $false
}

function Format-ComposeCommand {
    <#
    .SYNOPSIS
    Formats Docker Compose commands for display and logging.

    .DESCRIPTION
    Constructs a formatted command string from the detected Compose executable,
    argument prefix, and provided arguments. Handles shell-safe quoting for
    arguments containing spaces.

    .PARAMETER Context
    The build context object containing Compose executable information.

    .PARAMETER Arguments
    Additional arguments to append to the formatted command.

    .OUTPUTS
    System.String
    Formatted command string with proper quoting.

    .EXAMPLE
    $cmd = Format-ComposeCommand -Context $context -Arguments @('build', '--parallel')
    # Returns: "docker compose build --parallel"
    #>
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,

        [Parameter()]
        [string[]]$Arguments
    )

    if (-not $Context.Compose.Available -or [string]::IsNullOrWhiteSpace($Context.Compose.Executable)) {
        if ($null -eq $Arguments -or $Arguments.Count -eq 0) {
            return "docker compose (unavailable)"
        }

        return "docker compose (unavailable) " + ($Arguments -join ' ')
    }

    $parts = @($Context.Compose.Executable)
    if (@($Context.Compose.ArgsPrefix).Count -gt 0) {
        $parts += $Context.Compose.ArgsPrefix
    }
    if ($Arguments) {
        $parts += $Arguments
    }

    # Quote arguments for shell safety
    $quotedParts = $parts | ForEach-Object {
        if ($_ -match '\s') {
            "'$_'"
        }
        else {
            $_
        }
    }

    return $quotedParts -join ' '
}

function Invoke-Compose {
    <#
    .SYNOPSIS
    Executes Docker Compose commands.

    .DESCRIPTION
    Invokes the detected Docker Compose executable with the appropriate argument
    prefix and provided arguments. Validates Compose availability before execution
    and throws exceptions on command failures.

    .PARAMETER Context
    The build context object containing Compose executable configuration.

    .PARAMETER Arguments
    Command-line arguments to pass to the Compose executable.

    .PARAMETER CaptureOutput
    When specified, captures combined stdout/stderr while still streaming it to the console
    and returns the collected output as a string array.

    .OUTPUTS
    System.String[]
    Only returned when CaptureOutput is specified; otherwise no output is emitted.

    .EXAMPLE
    $output = Invoke-Compose -Context $context -Arguments @('build', '--no-cache') -CaptureOutput
    #>
    param(
        [Parameter(Mandatory = $true)]
        [pscustomobject]$Context,

        [Parameter()]
        [string[]]$Arguments,

        [Parameter()]
        [switch]$CaptureOutput
    )

    if (-not (Test-ComposeRequirement -Context $Context)) {
        throw "Docker Compose is not available"
    }

    $executable = $Context.Compose.Executable
    $commandArgs = @()
    if ($Context.Compose.ArgsPrefix.Count -gt 0) {
        $commandArgs += $Context.Compose.ArgsPrefix
    }
    if ($Arguments) {
        $commandArgs += $Arguments
    }

    $outputBuffer = [System.Collections.Generic.List[string]]::new()
    & $executable @commandArgs 2>&1 | ForEach-Object {
        $raw = $_
        $text = $null

        if ($null -eq $raw) {
            $text = ''
        }
        elseif ($raw -is [System.Management.Automation.InformationRecord]) {
            $messageData = $raw.MessageData
            if ($null -eq $messageData) {
                $text = $raw.ToString()
            }
            elseif ($messageData -is [string]) {
                $text = $messageData
            }
            else {
                $text = $messageData.ToString()
            }
        }
        else {
            $text = $raw.ToString()
        }

        if ($null -eq $text) {
            $text = ''
        }

        $outputBuffer.Add($text) | Out-Null

        if ($text.EndsWith("`n") -or $text.EndsWith("`r")) {
            [Console]::Error.Write($text)
        }
        else {
            [Console]::Error.WriteLine($text)
        }
    }
    $exitCode = $LASTEXITCODE

    if ($exitCode -ne 0) {
        $lastLine = $null
        if ($outputBuffer.Count -gt 0) {
            $lastLine = $outputBuffer[$outputBuffer.Count - 1]
        }

        if ($lastLine) {
            throw "Compose command failed with exit code $exitCode. Last output: $lastLine"
        }

        throw "Compose command failed with exit code $exitCode"
    }

    if ($CaptureOutput.IsPresent) {
        return [string[]]$outputBuffer.ToArray()
    }

    return
}

Export-ModuleMember -Function `
    Test-ComposeRequirement, `
    Format-ComposeCommand, `
    Invoke-Compose
