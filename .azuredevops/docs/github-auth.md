---
title: GitHub Authentication Template
description: Comprehensive guide to GitHub App authentication template for Azure DevOps pipelines with JWT token generation and installation token retrieval
author: Edge AI Team
ms.date: 2025-11-17
ms.topic: reference
keywords:
  - github
  - authentication
  - app
  - token
  - jwt
  - installation
  - security
  - pipeline
estimated_reading_time: 10
---

## Overview

The GitHub Authentication template (`github-auth.yml`) provides standardized GitHub App authentication for Azure DevOps pipelines. It generates JWT tokens, retrieves installation tokens, and validates GitHub API access with proper security scoping.

## When to Use

Use this template when you need:

- Secure GitHub API access from Azure DevOps pipelines
- Automated GitHub operations requiring authentication
- GitHub App installation token generation
- Standardized authentication flow across multiple pipelines
- Token validation and access verification

## Template Location

```plaintext
.azuredevops/templates/github-auth.yml
```

## Parameters

| Parameter            | Type   | Default                     | Description                                  |
|----------------------|--------|-----------------------------|----------------------------------------------|
| `githubRepository`   | string | `microsoft/edge-ai`         | GitHub repository in `owner/repo` format     |
| `outputVariableName` | string | `installationToken`         | Output variable name for the generated token |
| `displayName`        | string | `GitHub App Authentication` | Step display name in pipeline UI             |

## Prerequisites

### Required Variable Group

Variable group `ai-on-edge-secrets` must contain:

- **`github-edge-ai-app-client-id`**: GitHub App client ID
- **`github-edge-ai-app-private-key`**: GitHub App private key in PEM format

### Required Script

PowerShell script: `scripts/github/auth/Get-GitHubInstallationToken.ps1`

This script handles:

- JWT token generation from private key
- GitHub API authentication
- Installation token retrieval
- Token scope configuration

## Output Variables

| Variable                | Type    | Description                                           |
|-------------------------|---------|-------------------------------------------------------|
| `$(outputVariableName)` | string  | GitHub installation token for API access (secret)     |
| `GITHUB_AUTH_SUCCESS`   | boolean | `true` if authentication succeeded, `false` otherwise |

## Usage Examples

### Basic Authentication

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'
```

Access token in subsequent steps:

```yaml
- pwsh: |
    $token = "$(githubAuth.installationToken)"
    # Use token for GitHub API calls
```

### Custom Output Variable

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'
    outputVariableName: 'GITHUB_TOKEN'
```

### Multiple Repository Authentication

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'
    outputVariableName: 'EDGE_AI_TOKEN'

- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/another-repo'
    outputVariableName: 'ANOTHER_REPO_TOKEN'
```

## Authentication Flow

### Step 1: JWT Generation

1. Reads GitHub App private key from Azure DevOps variable group
2. Generates JWT token signed with private key
3. Sets JWT expiration (typically 10 minutes)
4. Includes GitHub App client ID in JWT claims

### Step 2: Installation Token Retrieval

1. Uses JWT token to authenticate with GitHub API
2. Requests installation token for specified repository
3. Retrieves token with appropriate permissions/scopes
4. Returns short-lived installation token (typically 1 hour)

### Step 3: Token Validation

1. Tests token by making GitHub API call to repository
2. Verifies repository access permissions
3. Confirms token validity and scope
4. Sets output variables for downstream consumption

## Security Considerations

### Token Handling

- Installation tokens are marked as secret in Azure DevOps
- Tokens are automatically masked in pipeline logs
- Tokens expire automatically (typically 1 hour)
- Never commit tokens or credentials to source control

### Private Key Management

- Store private key in Azure DevOps secure variable group
- Use PEM format for private key
- Rotate keys according to security policy
- Limit access to variable group with RBAC

### GitHub App Permissions

Configure GitHub App with minimum required permissions:

- **Repository Contents**: Read/Write for file operations
- **Pull Requests**: Read/Write for PR creation
- **Metadata**: Read for repository information
- **Commits**: Read/Write for branch operations

## Error Handling

### Common Errors

#### JWT Generation Failure

```text
Failed to generate JWT token
```

**Resolution**:

- Verify private key format (PEM)
- Check client ID is correct
- Ensure private key is not expired

```text

#### Installation Token Failure

```text
Failed to obtain GitHub installation token
```

**Resolution**:

- Verify GitHub App is installed on repository
- Check repository name format (`owner/repo`)
- Confirm App has required permissions

#### API Validation Failure

```text

#### API Validation Failure

**Resolution**:

- Verify GitHub App installation scope
- Check repository permissions
- Confirm repository exists and is accessible

### Output Variable Checks

Check authentication success:

```yaml
- pwsh: |
    if ("$(githubAuth.GITHUB_AUTH_SUCCESS)" -eq "false") {
      Write-Error "GitHub authentication failed"
      exit 1
    }
```

## Integration Patterns

### With Branch Operations

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

- template: templates/github-branch-operations.yml
  parameters:
    operation: 'check-exists'
    branchName: 'release/v1.2.3'
    installationToken: '$(githubAuth.installationToken)'
```

### With PR Creation

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

- template: templates/pr-creation.yml
  parameters:
    operation: 'create-pr'
    head: 'release/v1.2.3'
    base: 'main'
    title: 'Release v1.2.3'
    installationToken: '$(githubAuth.installationToken)'
```

### With Git Sync Operations

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'release/v1.2.3'
```

## Best Practices

### Single Authentication Per Pipeline

Authenticate once at the beginning of pipeline:

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

# Use token in multiple subsequent operations
```

### Token Lifecycle Management

- Request tokens just before use
- Don't store tokens beyond pipeline execution
- Use token expiration for security boundaries
- Re-authenticate if pipeline runs exceed token lifetime

### Error Propagation

Always check authentication status before proceeding:

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

- pwsh: |
    if ("$(githubAuth.GITHUB_AUTH_SUCCESS)" -ne "true") {
      throw "Cannot proceed without GitHub authentication"
    }
```

## Troubleshooting

### Issue: Token Variable Not Set

#### Symptom

**Solution**:

1. Verify private key is in PEM format
2. Ensure key includes header/footer lines
3. Check for line break issues in variable storage

### Issue: Key Vault Access Denied

#### Symptom Token validation fails with 404 or 403

**Solution**:

1. Verify GitHub App is installed on repository
2. Check repository name spelling
3. Confirm App has required permissions

### Issue: Token Expiration During Pipeline

**Symptom**: Operations fail midway through long pipeline

**Solution**:

1. Re-authenticate before long-running operations
2. Split pipeline into smaller stages with re-authentication
3. Use conditional re-authentication based on elapsed time

## Related Documentation

- [GitHub Branch Operations](github-branch-operations.md)
- [Pull Request Creation](pr-creation.md)
- [Git Sync Operations](git-sync-operations.md)
- [Authentication Guide](authentication.md)
- [Template Integration Guide](template-integration.md)

## References

- [GitHub Apps Documentation](https://docs.github.com/en/apps)
- [GitHub App Authentication](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app)
- [JWT Token Format](https://jwt.io/)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
