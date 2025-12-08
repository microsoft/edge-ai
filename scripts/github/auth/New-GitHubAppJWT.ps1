# -----------------------------------------------------------------------------
# New-GitHubAppJWT.ps1
# -----------------------------------------------------------------------------
#
# This script generates a JSON Web Token (JWT) for GitHub App authentication.
# The JWT is used to authenticate as a GitHub App installation and obtain
# installation access tokens for API operations.
#
# The script uses RS256 algorithm (RSA Signature with SHA-256) to sign the JWT
# using the GitHub App's private key. The JWT includes standard claims:
#   - iat (issued at): Current time minus 60 seconds for clock skew
#   - exp (expiration): Current time plus 600 seconds (10 minutes)
#   - iss (issuer): GitHub App client ID
#
# Dependencies:
#   - .NET System.Security.Cryptography for RSA operations
#   - PowerShell 7.x for proper cryptographic support
#
# Exit Codes:
#   0 - Success
#   1 - Failure (e.g., invalid private key, missing parameters)
#
# Usage:
#   ./New-GitHubAppJWT.ps1 -ClientId <app-id> -PrivateKeyPath <path-to-pem>
#   ./New-GitHubAppJWT.ps1 -ClientId "123456" -PrivateKeyPath "./app.pem"
#
# Returns:
#   JWT token string suitable for GitHub API authentication
#
# Example:
#   $jwt = ./New-GitHubAppJWT.ps1 -ClientId "123456" -PrivateKeyPath "./app.pem"
#   $headers = @{ Authorization = "Bearer $jwt" }
# -----------------------------------------------------------------------------

<#
.SYNOPSIS
Generates a JWT for GitHub App authentication using RS256 algorithm.

.DESCRIPTION
Creates a JSON Web Token (JWT) for authenticating as a GitHub App installation.
The JWT is signed using RS256 (RSA Signature with SHA-256) with the provided
private key. The token is valid for 10 minutes and includes standard JWT claims.

This token can be used to obtain installation access tokens via the GitHub API.

.PARAMETER ClientId
The GitHub App client ID (numeric application identifier).

.PARAMETER PrivateKeyPath
Path to the GitHub App private key file in PEM format.

.OUTPUTS
[string] - JWT token suitable for GitHub API Bearer authentication

.EXAMPLE
$jwt = .\New-GitHubAppJWT.ps1 -ClientId "123456" -PrivateKeyPath "app.pem"

.EXAMPLE
$token = .\New-GitHubAppJWT.ps1 -ClientId $env:GITHUB_APP_ID -PrivateKeyPath $keyPath
$headers = @{
    Authorization = "Bearer $token"
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

.NOTES
Requires PowerShell 7.x for proper cryptographic support.
JWT expires after 10 minutes and must be refreshed for long-running operations.
#>

[CmdletBinding()]
[OutputType([string])]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$ClientId,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$PrivateKeyPath
)

function ConvertTo-Base64Url {
    <#
    .SYNOPSIS
    Converts byte array to base64url encoding (RFC 4648).

    .DESCRIPTION
    Performs base64url encoding by:
    1. Base64 encoding the input bytes
    2. Removing padding (=)
    3. Replacing + with -
    4. Replacing / with _

    .PARAMETER Bytes
    Byte array to encode.

    .OUTPUTS
    [string] - Base64url encoded string
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [byte[]]$Bytes
    )

    $base64 = [Convert]::ToBase64String($Bytes)
    return $base64.TrimEnd('=').Replace('+', '-').Replace('/', '_')
}

try {
    # Validate private key file exists
    if (-not (Test-Path -Path $PrivateKeyPath -PathType Leaf)) {
        Write-Error "Private key file not found: $PrivateKeyPath"
        exit 1
    }

    # Read private key PEM file
    $privateKeyPem = Get-Content -Path $PrivateKeyPath -Raw

    # Create RSA provider and import private key
    $rsa = [System.Security.Cryptography.RSA]::Create()
    try {
        $rsa.ImportFromPem($privateKeyPem)
    }
    catch {
        Write-Error "Failed to import private key from PEM: $_"
        exit 1
    }

    # Calculate timestamps (Unix epoch)
    $now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $iat = $now - 60   # Issued 60 seconds in the past (clock skew tolerance)
    $exp = $now + 600  # Expires in 10 minutes

    # Create JWT header
    $header = @{
        typ = "JWT"
        alg = "RS256"
    } | ConvertTo-Json -Compress

    # Create JWT payload
    $payload = @{
        iat = $iat
        exp = $exp
        iss = $ClientId
    } | ConvertTo-Json -Compress

    # Encode header and payload as base64url
    $headerBytes = [System.Text.Encoding]::UTF8.GetBytes($header)
    $payloadBytes = [System.Text.Encoding]::UTF8.GetBytes($payload)

    $headerEncoded = ConvertTo-Base64Url -Bytes $headerBytes
    $payloadEncoded = ConvertTo-Base64Url -Bytes $payloadBytes

    # Create signature input (header.payload)
    $signatureInput = "$headerEncoded.$payloadEncoded"
    $signatureInputBytes = [System.Text.Encoding]::UTF8.GetBytes($signatureInput)

    # Sign with RSA-SHA256
    $signatureBytes = $rsa.SignData(
        $signatureInputBytes,
        [System.Security.Cryptography.HashAlgorithmName]::SHA256,
        [System.Security.Cryptography.RSASignaturePadding]::Pkcs1
    )

    # Encode signature as base64url
    $signatureEncoded = ConvertTo-Base64Url -Bytes $signatureBytes

    # Create complete JWT (header.payload.signature)
    $jwt = "$signatureInput.$signatureEncoded"

    # Output JWT token
    Write-Output $jwt
}
catch {
    Write-Error "Failed to generate JWT: $_"
    exit 1
}
finally {
    if ($null -ne $rsa) {
        $rsa.Dispose()
    }
}
