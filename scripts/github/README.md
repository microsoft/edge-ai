# GitHub Scripts

PowerShell and Bash scripts for GitHub API interactions, primarily focused on GitHub App authentication and pull request automation.

## Directory Structure

```plaintext
scripts/github/
├── README.md                                    # This file
├── helpers/                                     # Helper utilities (PowerShell)
│   ├── Initialize-GitHubAuthentication.ps1     # Consolidated authentication helper
│   └── New-GitHubApiHeaders.ps1                # GitHub API headers construction
├── New-GitHubAppJWT.ps1                         # JWT generation from App credentials
├── Get-GitHubAccessTokensUrl.ps1                # Installation tokens endpoint retrieval
├── New-GitHubInstallationToken.ps1              # JWT → Installation token exchange
├── New-GitHubPullRequest.ps1                    # Pull request creation helper
├── New-GitHubReleasePR.ps1                      # Release branch PR creation
└── *.sh                                         # Bash equivalents for Unix environments
```

## Helper Functions

### Initialize-GitHubAuthentication.ps1

Consolidates the 3-script GitHub App authentication chain into a single helper function.

**Purpose**: Simplifies authentication by orchestrating JWT generation, installation URL retrieval, and token exchange in one call.

**Parameters**:

- `AppId` (string, required): GitHub App ID from App settings
- `PrivateKey` (string, required): GitHub App private key in PEM format (RSA PRIVATE KEY)
- `InstallationId` (string, required): GitHub App Installation ID for target organization/repository

**Returns**: `PSCustomObject` with properties:

- `Token` (string): Installation access token (format: `ghs_...`, valid for 1 hour)
- `ExpiresAt` (string): ISO 8601 timestamp indicating token expiration

**Example**:

```powershell
# Basic usage
$auth = . scripts/github/helpers/Initialize-GitHubAuthentication.ps1 `
    -AppId "123456" `
    -PrivateKey $pemKeyContent `
    -InstallationId "789012"

Write-Host "Token: $($auth.Token)"
Write-Host "Expires: $($auth.ExpiresAt)"
```

**Azure DevOps Pipeline Example**:

```powershell
# Using with pipeline variables
$privateKey = $env:GITHUB_APP_PRIVATE_KEY
$authResult = . scripts/github/helpers/Initialize-GitHubAuthentication.ps1 `
    -AppId $env:GITHUB_APP_ID `
    -PrivateKey $privateKey `
    -InstallationId $env:GITHUB_INSTALLATION_ID

# Create API headers
$headers = @{
    Authorization = "Bearer $($authResult.Token)"
    Accept = "application/vnd.github+json"
}

# Make API call
$response = Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/edge-ai/pulls" `
    -Method Get -Headers $headers
```

**Internal Dependencies**:

- Calls `New-GitHubAppJWT.ps1` to generate JWT from App credentials
- Calls `Get-GitHubAccessTokensUrl.ps1` to retrieve installation tokens endpoint
- Calls `New-GitHubInstallationToken.ps1` to exchange JWT for installation token

**Error Handling**:

- Uses `$ErrorActionPreference = 'Stop'` for fail-fast behavior
- Throws descriptive errors on authentication failures
- Includes verbose logging at each authentication step (use `-Verbose` flag)

---

### New-GitHubApiHeaders.ps1

Creates standardized GitHub API headers for REST requests.

**Purpose**: Ensures consistent header formatting across all GitHub API interactions, providing a single source of truth for API version management and authentication header construction.

**Parameters**:

- `Token` (string, required): GitHub installation access token or personal access token
- `ApiVersion` (string, optional): GitHub API version (default: `'2022-11-28'`)

**Returns**: `Hashtable` with 4 headers:

- `Accept`: `'application/vnd.github+json'`
- `Authorization`: `'Bearer {token}'`
- `X-GitHub-Api-Version`: API version string (default: `'2022-11-28'`)
- `User-Agent`: `'AzureDevOps-Pipeline'`

**Example**:

```powershell
# Basic usage
$token = "ghs_exampleToken123456"
$headers = . scripts/github/helpers/New-GitHubApiHeaders.ps1 -Token $token

Invoke-RestMethod -Uri "https://api.github.com/repos/microsoft/edge-ai/pulls" `
    -Method Get -Headers $headers
```

**Combined with Authentication Helper**:

```powershell
# Full authentication + headers workflow
$auth = . scripts/github/helpers/Initialize-GitHubAuthentication.ps1 `
    -AppId $env:GITHUB_APP_ID `
    -PrivateKey $env:GITHUB_APP_PRIVATE_KEY `
    -InstallationId $env:GITHUB_INSTALLATION_ID

$headers = . scripts/github/helpers/New-GitHubApiHeaders.ps1 -Token $auth.Token

# Make authenticated API call
$pullRequests = Invoke-RestMethod `
    -Uri "https://api.github.com/repos/microsoft/edge-ai/pulls?state=open" `
    -Method Get `
    -Headers $headers
```

**Custom API Version Example**:

```powershell
# Use specific API version
$headers = . scripts/github/helpers/New-GitHubApiHeaders.ps1 `
    -Token $token `
    -ApiVersion "2023-01-01"
```

**Notes**:

- GitHub recommends specifying `X-GitHub-Api-Version` for all requests
- Current stable version: `2022-11-28`
- See [GitHub API Versioning](https://docs.github.com/en/rest/overview/api-versions) for updates
- User-Agent header is required by GitHub API; using `'AzureDevOps-Pipeline'` to identify automation context

---

## Core Authentication Scripts

These scripts are called internally by `Initialize-GitHubAuthentication.ps1` but can be used independently if needed.

### New-GitHubAppJWT.ps1

Generates a JSON Web Token (JWT) from GitHub App credentials.

**Parameters**:

- `AppId`: GitHub App ID
- `PrivateKey`: GitHub App private key in PEM format

**Returns**: JWT string for GitHub App authentication

### Get-GitHubAccessTokensUrl.ps1

Retrieves the installation access tokens URL for a GitHub App installation.

**Parameters**:

- `InstallationId`: GitHub App Installation ID
- `JWT`: JWT from `New-GitHubAppJWT.ps1`

**Returns**: URL string for installation token endpoint

### New-GitHubInstallationToken.ps1

Exchanges a JWT for an installation access token.

**Parameters**:

- `AccessTokensUrl`: URL from `Get-GitHubAccessTokensUrl.ps1`
- `JWT`: JWT from `New-GitHubAppJWT.ps1`

**Returns**: Object with `token` and `expires_at` properties

---

## Pull Request Scripts

### New-GitHubPullRequest.ps1

Creates a new pull request via GitHub API.

**Usage**: See script header for detailed parameter documentation.

### New-GitHubReleasePR.ps1

Specialized script for creating release branch pull requests with validation logic.

**Usage**: See script header for detailed parameter documentation.

---

## Bash Scripts

Unix/Linux equivalents of PowerShell scripts for cross-platform compatibility:

- `jwt-token.sh`: JWT generation
- `access-tokens-url.sh`: Installation URL retrieval
- `installation-token.sh`: Token exchange
- `create-pr.sh`: Pull request creation

**Note**: Bash scripts use similar parameters but may have different output formats.

---

## Testing

Pester unit tests are provided for helper functions:

- `helpers/Initialize-GitHubAuthentication.Tests.ps1`
- `helpers/New-GitHubApiHeaders.Tests.ps1`

**Run tests**:

```powershell
# Test individual helper
Invoke-Pester scripts/github/helpers/Initialize-GitHubAuthentication.Tests.ps1

# Test all helpers
Invoke-Pester scripts/github/helpers/*.Tests.ps1
```

---

## Azure DevOps Integration

These scripts are designed for use in Azure DevOps pipelines. See `.azuredevops/templates/github-authentication.yml` for a reusable pipeline template that leverages these helpers.

**Template Usage**:

```yaml
- template: ../templates/github-authentication.yml
  parameters:
    appId: $(GITHUB_APP_ID)
    keyVaultName: $(KEY_VAULT_NAME)
    installationId: $(GITHUB_INSTALLATION_ID)
    serviceConnection: $(AZURE_SERVICE_CONNECTION)

- script: |
    # Token available as output variable
    echo "Token: $(githubAuth.github_token)"
  displayName: 'Use GitHub Token'
```

---

## Security Considerations

- **Private Keys**: Never commit private keys to source control. Use Azure Key Vault for secure storage.
- **Token Lifetime**: Installation tokens expire after 1 hour. Regenerate for long-running operations.
- **Token Scope**: Installation tokens inherit permissions from GitHub App configuration.
- **Verbose Logging**: Avoid logging tokens in verbose output (helpers log token length only).

---

## Contributing

When adding new GitHub integration scripts:

1. Follow existing naming conventions (`Verb-NounDescription.ps1`)
2. Include comment-based help with `.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`
3. Add Pester tests for helper functions (`*.Tests.ps1`)
4. Update this README.md with usage examples
5. Use `Initialize-GitHubAuthentication.ps1` and `New-GitHubApiHeaders.ps1` for consistency

---

## References

- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [GitHub REST API Documentation](https://docs.github.com/en/rest)
- [GitHub API Versioning](https://docs.github.com/en/rest/overview/api-versions)
- [Azure DevOps Pipeline Templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
