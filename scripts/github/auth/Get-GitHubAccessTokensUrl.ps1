# -----------------------------------------------------------------------------
# Get-GitHubAccessTokensUrl.ps1
# -----------------------------------------------------------------------------
#
# This script retrieves the installation access tokens URL for a GitHub App
# installation associated with a specific repository. The URL is used to
# exchange a GitHub App JWT for an installation access token.
#
# The script queries the GitHub API installation endpoint for a repository
# and extracts the access_tokens_url from the response. This URL is then
# used with New-GitHubInstallationToken.ps1 to obtain access tokens.
#
# Dependencies:
#   - PowerShell 7.x for Invoke-RestMethod
#   - Valid GitHub App JWT token
#   - Repository must have GitHub App installed
#
# Exit Codes:
#   0 - Success
#   1 - Failure (e.g., API error, repository not found, app not installed)
#
# Usage:
#   ./Get-GitHubAccessTokensUrl.ps1 -JWT <token> -Repository <owner/repo>
#   ./Get-GitHubAccessTokensUrl.ps1 -JWT $jwt -Repository "microsoft/edge-ai"
#
# Returns:
#   Installation access tokens URL (e.g., https://api.github.com/app/installations/12345/access_tokens)
#
# Example:
#   $jwt = ./New-GitHubAppJWT.ps1 -ClientId "123456" -PrivateKeyPath "app.pem"
#   $url = ./Get-GitHubAccessTokensUrl.ps1 -JWT $jwt -Repository "microsoft/edge-ai"
#   $token = ./New-GitHubInstallationToken.ps1 -JWT $jwt -AccessTokensUrl $url
# -----------------------------------------------------------------------------

<#
.SYNOPSIS
Retrieves the installation access tokens URL for a GitHub App installation.

.DESCRIPTION
Queries the GitHub API to get installation details for a repository and
extracts the access_tokens_url. This URL is used to exchange a GitHub App
JWT for an installation access token that can perform API operations.

The GitHub App must be installed on the target repository for this to succeed.

.PARAMETER JWT
GitHub App JWT token (obtained from New-GitHubAppJWT.ps1).

.PARAMETER Repository
Repository in owner/repo format (e.g., "microsoft/edge-ai").

.OUTPUTS
[string] - Installation access tokens URL

.EXAMPLE
$jwt = .\New-GitHubAppJWT.ps1 -ClientId "123456" -PrivateKeyPath "app.pem"
$url = .\Get-GitHubAccessTokensUrl.ps1 -JWT $jwt -Repository "microsoft/edge-ai"

.EXAMPLE
$accessTokensUrl = .\Get-GitHubAccessTokensUrl.ps1 `
    -JWT $env:GITHUB_APP_JWT `
    -Repository "microsoft/edge-ai"

.NOTES
Requires GitHub App to be installed on the target repository.
JWT must be valid and not expired (tokens expire after 10 minutes).
#>

[CmdletBinding()]
[OutputType([string])]
param (
    [Parameter(Mandatory = $true, Position = 0)]
    [string]$JWT,

    [Parameter(Mandatory = $true, Position = 1)]
    [string]$Repository
)

try {
    # Validate repository format (owner/repo)
    if ($Repository -notmatch '^[^/]+/[^/]+$') {
        Write-Error "Invalid repository format. Expected: owner/repo (e.g., microsoft/edge-ai)"
        exit 1
    }

    # Construct GitHub API URL
    $apiUrl = "https://api.github.com/repos/$Repository/installation"

    # Prepare headers
    $headers = @{
        Accept         = "application/vnd.github+json"
        Authorization  = "Bearer $JWT"
        "X-GitHub-Api-Version" = "2022-11-28"
    }

    # Query GitHub API for installation details
    Write-Verbose "Querying GitHub API: $apiUrl"
    $response = Invoke-RestMethod -Uri $apiUrl -Headers $headers -Method Get

    # Extract access_tokens_url
    $accessTokensUrl = $response.access_tokens_url

    if ([string]::IsNullOrEmpty($accessTokensUrl)) {
        Write-Error "Failed to retrieve access_tokens_url from API response"
        exit 1
    }

    # Output access tokens URL
    Write-Output $accessTokensUrl
}
catch {
    Write-Error "Failed to retrieve installation access tokens URL: $_"
    if ($_.Exception.Response) {
        $statusCode = $_.Exception.Response.StatusCode.value__
        Write-Error "HTTP Status Code: $statusCode"
    }
    exit 1
}
