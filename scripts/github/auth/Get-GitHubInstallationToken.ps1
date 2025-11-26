<#
.SYNOPSIS
    Get a GitHub App installation access token (all-in-one convenience script).

.DESCRIPTION
    Performs the complete GitHub App authentication flow:
    1. Generates a JWT from the GitHub App private key
    2. Retrieves the installation access tokens URL
    3. Exchanges the JWT for an installation access token

    This is a convenience wrapper that combines all three authentication steps.
    For modular usage, use the individual scripts in this directory.

.PARAMETER ClientId
    The GitHub App Client ID.

.PARAMETER PrivateKeyPath
    Path to the GitHub App private key file (.pem format).
    Use either -PrivateKeyPath OR -PrivateKey, not both.

.PARAMETER PrivateKey
    The GitHub App private key as a string (PEM format).
    Use either -PrivateKeyPath OR -PrivateKey, not both.

.PARAMETER Repository
    The GitHub repository in format 'owner/repo' (e.g., 'microsoft/edge-ai').

.OUTPUTS
    System.String - The installation access token (valid for 1 hour).

.EXAMPLE
    $token = .\Get-GitHubInstallationToken.ps1 -ClientId "Iv1.abc123" -PrivateKeyPath "path/to/key.pem" -Repository "microsoft/edge-ai"

.EXAMPLE
    $token = .\Get-GitHubInstallationToken.ps1 -ClientId "Iv1.abc123" -PrivateKey $keyContent -Repository "microsoft/edge-ai"

.NOTES
    Requires PowerShell 7.0 or later for JWT generation and GitHub API calls.
#>

[CmdletBinding()]
[OutputType([string])]
param (
    [Parameter(Mandatory = $true)]
    [string]$ClientId,

    [Parameter(Mandatory = $true, ParameterSetName = "File")]
    [string]$PrivateKeyPath,

    [Parameter(Mandatory = $true, ParameterSetName = "String")]
    [string]$PrivateKey,

    [Parameter(Mandatory = $true)]
    [string]$Repository
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

#region Helper Functions

function ConvertTo-ProperPemFormat {
    <#
    .SYNOPSIS
    Converts various PEM storage formats to proper PEM format with actual newlines.

    .DESCRIPTION
    Key Vault stores PEM as single-line with literal \n. This function detects
    various escape formats and converts to actual newlines required by ImportFromPem.

    .PARAMETER PemContent
    The PEM content string that may contain escaped newlines.

    .OUTPUTS
    System.String with actual newline characters.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$PemContent
    )

    # Diagnostic: Log preview of input format (only with -Verbose)
    $preview = if ($PemContent.Length -gt 100) {
        $PemContent.Substring(0, 100) + "..."
    } else {
        $PemContent
    }
    Write-Verbose "PEM format detection starting... Input preview: $preview"
    Write-Verbose "PEM length: $($PemContent.Length) characters"

    $normalized = $PemContent

    # Pattern Detection and Conversion
    if ($normalized -match '\\\\n') {
        # Double-escaped from bash → Azure DevOps variable → PowerShell
        Write-Verbose "Detected: Double-escaped format (\\\\n)"
        $normalized = $normalized -replace '\\\\n', "`n"
    }
    elseif ($normalized -match '\\r\\n') {
        # Windows CRLF literal escape
        Write-Verbose "Detected: Windows newline format (\\r\\n)"
        $normalized = $normalized -replace '\\r\\n', "`n"
    }
    elseif ($normalized -match '\\n') {
        # Single literal \n (most common from Key Vault)
        Write-Verbose "Detected: Literal backslash-n format (\\n)"
        $normalized = $normalized -replace '\\n', "`n"
    }
    else {
        Write-Verbose "No escaped newlines detected - assuming already proper format"
    }

    # Validation: Ensure PEM structure exists
    if ($normalized -notmatch '-----BEGIN.*PRIVATE KEY-----') {
        $errorMsg = "PEM content does not contain expected header '-----BEGIN.*PRIVATE KEY-----'. Format detection may have failed."
        Write-Error $errorMsg
        Write-Verbose "Post-conversion preview: $($normalized.Substring(0, [Math]::Min(200, $normalized.Length)))"
        throw $errorMsg
    }

    if ($normalized -notmatch '-----END.*PRIVATE KEY-----') {
        $errorMsg = "PEM content does not contain expected footer '-----END.*PRIVATE KEY-----'. Content may be truncated."
        Write-Error $errorMsg
        throw $errorMsg
    }

    Write-Verbose "PEM format conversion complete. Structure validated."
    return $normalized
}

function ConvertTo-Base64Url {
    <#
    .SYNOPSIS
        Convert byte array to RFC 4648 base64url encoding.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [byte[]]$InputBytes
    )

    $base64 = [Convert]::ToBase64String($InputBytes)
    $base64url = $base64.TrimEnd('=').Replace('+', '-').Replace('/', '_')
    return $base64url
}

function New-GitHubAppJWT {
    <#
    .SYNOPSIS
        Generate a GitHub App JWT (embedded function).
    #>
    [CmdletBinding()]
    [OutputType([string])]
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSUseShouldProcessForStateChangingFunctions', '', Justification='Internal helper function does not change system state')]
    param (
        [Parameter(Mandatory = $true)]
        [string]$ClientId,

        [Parameter(Mandatory = $true)]
        [string]$PrivateKeyContent
    )

    try {
        # Parse the private key
        # Convert from Key Vault storage format to proper PEM format
        $PrivateKeyContent = ConvertTo-ProperPemFormat -PemContent $PrivateKeyContent

        $rsa = [System.Security.Cryptography.RSA]::Create()
        try {
            $rsa.ImportFromPem($PrivateKeyContent.ToCharArray())
            Write-Verbose "Successfully imported RSA private key from PEM"
        }
        catch [System.Security.Cryptography.CryptographicException] {
            Write-Error "Failed to import PEM: $_"
            Write-Verbose "PEM Content Length: $($PrivateKeyContent.Length) characters"
            Write-Verbose "First 200 characters: $($PrivateKeyContent.Substring(0, [Math]::Min(200, $PrivateKeyContent.Length)))"
            Write-Verbose "Contains BEGIN marker: $($PrivateKeyContent -match '-----BEGIN')"
            Write-Verbose "Contains END marker: $($PrivateKeyContent -match '-----END')"
            throw
        }

        # Create JWT header
        $header = @{
            alg = "RS256"
            typ = "JWT"
        } | ConvertTo-Json -Compress

        # Create JWT payload
        $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $payload = @{
            iat = $now - 60  # Issued 60 seconds in the past to account for clock drift
            exp = $now + 540 # Expires in 9 minutes (max 10 minutes allowed)
            iss = $ClientId
        } | ConvertTo-Json -Compress

        # Encode header and payload
        $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
        $payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)

        $headerEncoded = ConvertTo-Base64Url -InputBytes $headerBytes
        $payloadEncoded = ConvertTo-Base64Url -InputBytes $payloadBytes

        # Create signature
        $message = "$headerEncoded.$payloadEncoded"
        $messageBytes = [System.Text.Encoding]::UTF8.GetBytes($message)

        $signatureBytes = $rsa.SignData(
            $messageBytes,
            [System.Security.Cryptography.HashAlgorithmName]::SHA256,
            [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
        )

        $signatureEncoded = ConvertTo-Base64Url -InputBytes $signatureBytes

        # Return complete JWT
        $jwt = "$headerEncoded.$payloadEncoded.$signatureEncoded"

        Write-Verbose "Generated JWT (expires in 9 minutes)"
        return $jwt
    }
    catch {
        Write-Error "Failed to generate JWT: $_"
        throw
    }
    finally {
        if ($rsa) {
            $rsa.Dispose()
        }
    }
}

#endregion

try {
    # Step 1: Load private key
    Write-Verbose "Loading GitHub App private key..."
    if ($PSCmdlet.ParameterSetName -eq "File") {
        if (-not (Test-Path -Path $PrivateKeyPath)) {
            throw "Private key file not found: $PrivateKeyPath"
        }
        $privateKeyContent = Get-Content -Path $PrivateKeyPath -Raw
    }
    else {
        $privateKeyContent = $PrivateKey
    }

    # Step 2: Generate JWT
    Write-Verbose "Generating GitHub App JWT..."
    $jwt = New-GitHubAppJWT -ClientId $ClientId -PrivateKeyContent $privateKeyContent

    # Step 3: Get installation access tokens URL
    Write-Verbose "Retrieving installation access tokens URL for repository: $Repository"

    $headers = @{
        "Accept"        = "application/vnd.github+json"
        "Authorization" = "Bearer $jwt"
    }

    $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repository/installation" -Headers $headers -Method Get

    if (-not $response.access_tokens_url) {
        throw "Failed to retrieve access_tokens_url from GitHub API response"
    }

    $accessTokensUrl = $response.access_tokens_url
    Write-Verbose "Access tokens URL: $accessTokensUrl"

    # Step 4: Exchange JWT for installation token
    Write-Verbose "Exchanging JWT for installation access token..."

    $tokenResponse = Invoke-RestMethod -Uri $accessTokensUrl -Headers $headers -Method Post

    if (-not $tokenResponse.token) {
        throw "Failed to retrieve installation access token from GitHub API response"
    }

    $token = $tokenResponse.token
    $expiresAt = $tokenResponse.expires_at

    Write-Verbose "Installation access token obtained (expires: $expiresAt)"

    # Return the token
    return $token
}
catch {
    Write-Error "Failed to obtain GitHub installation token: $_"
    throw
}
