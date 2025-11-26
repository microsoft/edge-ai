---
title: Authentication Guide
description: Comprehensive guide to GitHub App authentication configuration, JWT generation, installation token management, and security best practices for Azure DevOps pipelines
author: Edge AI Team
ms.date: 2025-11-17
ms.topic: guide
keywords:
  - github-app
  - authentication
  - jwt
  - installation-token
  - security
  - variable-groups
  - token-lifecycle
  - api-access
estimated_reading_time: 12
---

## Overview

This guide covers end-to-end GitHub App authentication for Azure DevOps pipelines, including GitHub App setup, JWT generation, installation token lifecycle, security best practices, and troubleshooting authentication issues.

## GitHub App Authentication Architecture

### Authentication Flow

```plaintext
┌──────────────────────────────────────────────────────────────┐
│ Azure DevOps Pipeline                                        │
│                                                               │
│ 1. Load GitHub App credentials from Variable Group           │
│    ├─ github-edge-ai-app-client-id                          │
│    └─ github-edge-ai-app-private-key (PEM format)           │
│                                                               │
│ 2. Generate JWT Token (short-lived, 10 minutes)             │
│    ├─ Sign with private key                                  │
│    ├─ Include App ID in payload                              │
│    └─ Set expiration timestamp                               │
│                                                               │
│ 3. Request Installation Token                                │
│    ├─ Authenticate with JWT                                  │
│    ├─ Identify GitHub App installation                       │
│    └─ Receive scoped installation token                      │
│                                                               │
│ 4. Use Installation Token for GitHub API                     │
│    ├─ Clone repositories                                     │
│    ├─ Create branches and PRs                                │
│    ├─ Manage repository operations                           │
│    └─ Token expires (1 hour default)                         │
└──────────────────────────────────────────────────────────────┘
```

### Token Types and Lifetimes

## Under the Hood

### JWT Token

- **Lifetime**: 10 minutes
- **Purpose**: Authenticates as GitHub App
- **Scope**: App-level authentication only
- **Renewal**: Generated on-demand for each authentication request

### Installation Token

- **Purpose**: Perform repository operations on behalf of installation
- **Scope**: Repository-level permissions defined by app
- **Renewal**: Regenerate before expiration for long-running operations

## GitHub App Setup

### Creating a GitHub App

#### Step 1: Navigate to GitHub App Settings

Organization-level app:

```plaintext
https://github.com/organizations/{org}/settings/apps/new
```

#### Step 1B: Set Pipeline Variables

```plaintext
AZDO_ORG_SERVICE_URL
AZDO_PROJECT_NAME
```

Personal account app:

```plaintext
https://github.com/settings/apps/new
```

#### Step 2: Configure Basic Information

Required fields:

- **GitHub App name**: `edge-ai-automation` (or your organization name)
- **Homepage URL**: Repository or organization URL
- **Webhook**: Disabled for CI/CD-only apps

#### Step 3: Configure Permissions

Required permissions:

- **Contents**: Read and write

#### Step 4: Generate Private Key

1. Scroll to "Private keys" section
2. Click "Generate a private key"
3. Save downloaded PEM file securely
4. Store in Azure DevOps variable group

#### Step 5: Note App ID

Find App ID at top of settings page:

```plaintext
App ID: 123456
```

Store as `github-edge-ai-app-client-id` in variable group.

### Installing the GitHub App

#### Step 1: Install on Repository

Navigate to app installation page:

```plaintext
https://github.com/apps/{app-name}/installations/new
```

#### Step 2: Select Repositories

Choose installation scope:

- **All repositories**: App accesses all repos in organization
- **Only select repositories**: Limit to specific repos

#### Step 3: Confirm Installation

Review permissions and confirm installation.

#### Step 4: Note Installation ID

Find installation ID in URL after installation:

```plaintext
https://github.com/organizations/{org}/settings/installations/{installation-id}
```

## Azure DevOps Variable Group Configuration

### Creating Variable Group

#### Step 1: Navigate to Library

```plaintext
Azure DevOps → Pipelines → Library → + Variable group
```

#### Step 2: Create Group

Variable group name: `ai-on-edge-secrets`

#### Step 3: Add Variables

Add required variables:

**github-edge-ai-app-client-id**:

- **Type**: Text
- **Value**: GitHub App ID from app settings
- **Secret**: No (App ID is not sensitive)

**github-edge-ai-app-private-key**:

- **Type**: Secret
- **Value**: Complete PEM private key content (including headers)
- **Format**:
  <!-- secretlint-disable @secretlint/secretlint-rule-privatekey -->
  ```text
  -----BEGIN RSA PRIVATE KEY-----
  ...
  -----END RSA PRIVATE KEY-----
  ```
  <!-- secretlint-enable @secretlint/secretlint-rule-privatekey -->

### Variable Group Security

#### Step 1: Configure Pipeline Permissions

1. Open variable group `ai-on-edge-secrets`
2. Navigate to "Pipeline permissions" tab
3. Add authorized pipelines
4. Set approval requirements if needed

#### Step 2: Configure Security Roles

Assign appropriate roles:

- **Reader**: View variable names (not values)
- **User**: Use in authorized pipelines
- **Administrator**: Manage variables and permissions

#### Step 3: Enable Audit Logging

Monitor variable access:

```plaintext
Organization Settings → Audit → Filter by "Variable groups"
```

## JWT Token Generation

### JWT Structure

GitHub App JWT tokens follow standard structure:

The JWT consists of:

#### Header

#### Payload

```json
{
  "iat": 1700000000,
  "exp": 1700000600,
  "iss": "123456"
}
```

#### Signature RSA-256 signature using private key

### PowerShell JWT Generation

The `Get-GitHubInstallationToken.ps1` script generates JWT tokens:

```powershell
# Load private key
$privateKey = $env:GITHUB_APP_PRIVATE_KEY

# Create JWT payload
$now = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
$payload = @{
    iat = $now
    exp = $now + 600  # 10 minutes
    iss = $env:GITHUB_APP_ID
}

# Generate JWT token
$jwt = New-JWTToken -Payload $payload -PrivateKey $privateKey -Algorithm RS256
```

### JWT Validation

Verify JWT token before use:

```powershell
# Decode JWT (without verification for inspection)
$parts = $jwt -split '\.'
$header = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($parts[0]))
$payload = [System.Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($parts[1]))

Write-Host "Header: $header"
Write-Host "Payload: $payload"
```

## Installation Token Retrieval

### API Request Flow

#### Step 1: Authenticate with JWT

```bash
curl -X GET \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/app
```

#### Step 2: Get Installation ID

```bash
curl -X GET \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations
```

#### Step 1C: Generate Installation Token

```bash
curl -X POST \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Accept: application/vnd.github+json" \
  https://api.github.com/app/installations/$INSTALLATION_ID/access_tokens
```

#### Response

```json
{
  "token": "ghs_abc123...",
  "expires_at": "2025-11-17T12:00:00Z",
  "permissions": {
    "contents": "write",
    "pull_requests": "write"
  }
}
```

### PowerShell Implementation

```powershell
# Authenticate and get installation token
$headers = @{
    'Authorization' = "Bearer $jwtToken"
    'Accept' = 'application/vnd.github+json'
}

# Get installation ID
$installationUrl = "https://api.github.com/repos/$repository/installation"
$installation = Invoke-RestMethod -Uri $installationUrl -Headers $headers

# Request installation token
$tokenUrl = "https://api.github.com/app/installations/$($installation.id)/access_tokens"
$response = Invoke-RestMethod -Uri $tokenUrl -Method Post -Headers $headers

# Set output variable
Write-Host "##vso[task.setvariable variable=INSTALLATION_TOKEN;issecret=true]$($response.token)"
```

## Token Lifecycle Management

### Token Expiration Handling

#### Strategy 1: Regenerate on Demand

For operations under 1 hour:

```yaml
- template: templates/github-auth.yml

- template: templates/github-branch-operations.yml
  parameters:
    installationToken: '$(githubAuth.installationToken)'
```

#### Strategy 2: Periodic Renewal

For long-running operations:

```yaml
jobs:
- job: LongRunningOperation
  steps:
  - template: templates/github-auth.yml
    parameters:
      outputVariableName: 'TOKEN_INITIAL'

  - pwsh: |
      # Operation part 1 (under 1 hour)
      Start-Sleep -Seconds 3000  # 50 minutes

  - template: templates/github-auth.yml
    parameters:
      outputVariableName: 'TOKEN_RENEWED'

  - pwsh: |
      # Operation part 2 with renewed token
      $token = "$(githubAuth.TOKEN_RENEWED)"
```

### Token Revocation

Tokens become invalid immediately upon:

#### Automatic Revocation

- Token expires after 1 hour automatically
- No manual revocation needed for normal operations

**Manual Revocation**:
Navigate to app installation settings:

```plaintext
https://github.com/organizations/{org}/settings/installations/{id}
```

Click "Revoke" to invalidate all tokens immediately.

## Security Best Practices

### Private Key Management

**DO**:

- Store private key in Azure DevOps secret variable
- Use variable groups with pipeline permissions
- Restrict variable group access to required pipelines
- Rotate private key periodically (quarterly recommended)
- Monitor private key access through audit logs

**DON'T**:

- Commit private key to repository
- Share private key across multiple systems
- Store private key in plain text files
- Log private key content in pipeline output
- Reuse private key across multiple apps

### Token Handling

#### DO

- Mark installation tokens as secrets: `issecret=true`
- Use tokens only for intended operations
- Validate token before critical operations
- Implement token refresh for long operations
- Clear tokens from memory after use

**DON'T**:

- Log tokens in pipeline output
- Pass tokens as plain text parameters
- Store tokens in files or artifacts
- Share tokens between unrelated jobs
- Use expired tokens (check `expires_at`)

### Permission Scoping

**Principle of Least Privilege**:

Grant minimum required permissions:

- **Read-only** for operations that only inspect
- **Write** only when commits/PRs needed
- **Admin** only for repository settings changes

Example minimal permissions:

```yaml
permissions:
  contents: read        # Clone and read
  pull_requests: write  # Create PRs only
```

### Audit and Monitoring

#### Enable Organization Audit Log

```plaintext
Organization Settings → Audit log
```

**Monitor for**:

- Private key access in variable groups
- Installation token creation requests
- Failed authentication attempts
- Unusual API usage patterns

## Integration with Templates

### Using Authentication Template

### Template Usage

#### Standard Pattern

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'
    outputVariableName: 'GITHUB_TOKEN'

- template: templates/git-sync-operations.yml
  parameters:
    operation: 'clone-from-github'
    installationToken: '$(githubAuth.GITHUB_TOKEN)'
```

### Multi-Repository Authentication

Authenticate for multiple repositories:

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'
    outputVariableName: 'TOKEN_EDGE_AI'

- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/other-repo'
    outputVariableName: 'TOKEN_OTHER'

- pwsh: |
    # Use separate tokens
    $token1 = "$(githubAuth.TOKEN_EDGE_AI)"
    $token2 = "$(githubAuth.TOKEN_OTHER)"
```

### Conditional Authentication

Authenticate only when needed:

```yaml
- ${{ if eq(parameters.requiresGitHub, true) }}:
  - template: templates/github-auth.yml
    parameters:
      githubRepository: '$(GITHUB_REPOSITORY)'
```

## Troubleshooting

### Issue: Private Key Not Found

**Symptom**: Authentication fails with "Private key variable not found"

#### Solution: Private Key Not Found

1. Verify variable group `ai-on-edge-secrets` exists
2. Check variable name: `github-edge-ai-app-private-key`
3. Confirm pipeline has access to variable group
4. Ensure variable group linked in pipeline YAML

### Issue: JWT Generation Fails

**Symptom**: Error generating JWT token

#### Solution: JWT Generation Fails

1. Verify private key format (PEM with headers)
2. Check for extra whitespace or newlines
3. Ensure App ID matches private key
4. Validate private key not expired/revoked

### Issue: Installation Token Request Fails

**Symptom**: 401 or 404 error when requesting installation token

#### Solution: Installation Token Request Fails

1. Verify GitHub App installed on repository
2. Check App ID in variable group
3. Confirm repository name format: `owner/repo`
4. Validate App permissions include required scopes

### Issue: Token Expires During Operation

**Symptom**: GitHub API calls fail midway through pipeline

#### Solution: Token Expires During Operation

1. Implement token renewal for long operations
2. Split operations into shorter jobs
3. Check operation duration vs token lifetime
4. Consider increasing token lifetime (not recommended)

### Issue: Insufficient Permissions

**Symptom**: 403 error on GitHub API calls despite valid token

#### Solution: Insufficient Permissions

1. Review GitHub App permissions in app settings
2. Verify installation includes target repository
3. Check operation requirements match app permissions
4. Reinstall app with updated permissions if needed

## Related Documentation

- [GitHub Authentication Template](github-auth.md)
- [GitHub Branch Operations](github-branch-operations.md)
- [Pull Request Creation](pr-creation.md)
- [Git Sync Operations](git-sync-operations.md)
- [Release Validation](release-validation.md)
- [Template Integration Guide](template-integration.md)

## References

- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [GitHub App Authentication](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app)
- [JWT Standard (RFC 7519)](https://datatracker.ietf.org/doc/html/rfc7519)
- [GitHub API Authentication](https://docs.github.com/en/rest/authentication)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
