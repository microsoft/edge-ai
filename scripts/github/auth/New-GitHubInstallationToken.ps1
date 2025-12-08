# -----------------------------------------------------------------------------
# New-GitHubInstallationToken.ps1
# -----------------------------------------------------------------------------
#
# This script exchanges a GitHub App JWT for an installation access token.
# The installation token can be used to perform API operations on behalf of
# the GitHub App installation (e.g., create branches, manage pull requests).
#
# The script posts the JWT to the installation access tokens URL and extracts
# the token from the response. Installation tokens are valid for 1 hour and
# provide repository-level permissions based on the GitHub App configuration.
#
# Dependencies:
#   - PowerShell 7.x for Invoke-RestMethod
#   - Valid GitHub App JWT token
#   - Valid installation access tokens URL
#
# Exit Codes:
#   0 - Success
#   1 - Failure (e.g., API error, invalid JWT, expired token)
#
# Usage:
#   ./New-GitHubInstallationToken.ps1 -JWT <token> -AccessTokensUrl <url>
#   ./New-GitHubInstallationToken.ps1 -JWT $jwt -AccessTokensUrl $url
#
# Returns:
#   Installation access token string (valid for 1 hour)
#
# Example:
#   $jwt = ./New-GitHubAppJWT.ps1 -ClientId "123456" -PrivateKeyPath "app.pem"
#   $url = ./Get-GitHubAccessTokensUrl.ps1 -JWT $jwt -Repository "microsoft/edge-ai"
#   $token = ./New-GitHubInstallationToken.ps1 -JWT $jwt -AccessTokensUrl $url
#   $headers = @{ Authorization = "Bearer $token" }
# -----------------------------------------------------------------------------

<#
.SYNOPSIS
Exchanges GitHub App JWT for an installation access token.

.DESCRIPTION
Posts a GitHub App JWT to the installation access tokens URL and retrieves
an installation access token. This token can be used for repository operations
with permissions based on the GitHub App configuration.

Installation tokens expire after 1 hour and must be refreshed for longer operations.

.PARAMETER JWT
GitHub App JWT token (obtained from New-GitHubAppJWT.ps1).

.PARAMETER AccessTokensUrl
Installation access tokens URL (obtained from Get-GitHubAccessTokensUrl.ps1).

.OUTPUTS
[string] - Installation access token (valid for 1 hour)

.EXAMPLE
$jwt = .\New-GitHubAppJWT.ps1 -ClientId "123456" -PrivateKeyPath "app.pem"
$url = .\Get-GitHubAccessTokensUrl.ps1 -JWT $jwt -Repository "microsoft/edge-ai"
$token = .\New-GitHubInstallationToken.ps1 -JWT $jwt -AccessTokensUrl $url

.EXAMPLE
$installationToken = .\New-GitHubInstallationToken.ps1 `
    -JWT $env:GITHUB_APP_JWT `
    -AccessTokensUrl $accessTokensUrl

$headers = @{
    Authorization = "Bearer $installationToken"
    Accept = "application/vnd.github+json"
    "X-GitHub-Api-Version" = "2022-11-28"
}

.NOTES
Installation tokens expire after 1 hour (JWT expires after 10 minutes).
Refresh tokens as needed for long-running operations.
#>

[CmdletBinding()]
[OutputType([string])]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$JWT,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$AccessTokensUrl
)

try {
    # Validate access tokens URL format
    if ($AccessTokensUrl -notmatch '^https://api\.github\.com/') {
        Write-Error "Invalid access tokens URL. Expected GitHub API URL format."
        exit 1
    }

    # Prepare headers
    $headers = @{
        Accept         = "application/vnd.github+json"
        Authorization  = "Bearer $JWT"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    # Request installation access token
    Write-Verbose "Requesting installation token from: $AccessTokensUrl"
    $response = Invoke-RestMethod -Uri $AccessTokensUrl -Headers $headers -Method Post

    # Extract token from response
    $token = $response.token

    if ([string]::IsNullOrEmpty($token)) {
        Write-Error "Failed to retrieve installation token from API response"
        exit 1
    }

    # Output installation token
    Write-Output $token
}
catch {
    Write-Error "Failed to obtain installation access token: $_"
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Error "HTTP Status Code: $statusCode"
    }
    exit 1
}
