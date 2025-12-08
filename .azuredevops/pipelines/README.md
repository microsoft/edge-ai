---
title: Azure DevOps Pipelines
description: Documentation for Azure DevOps CI/CD pipelines used in the edge-ai project
author: Edge AI Team
ms.date: 2025-11-16
ms.topic: reference
keywords:
  - azure-pipelines
  - ci-cd
  - github-sync
  - release-automation
---

This directory contains Azure DevOps pipeline definitions for the edge-ai project, including GitHub synchronization workflows, release automation, and CI/CD processes.

## Architecture

### Template-Based Design

All pipelines use reusable templates from `../templates/` for:

* **GitHub Authentication** - [github-auth.yml](../templates/github-auth.md)
* **Branch Operations** - [github-branch-operations.yml](../templates/github-branch-operations.md)
* **Pull Request Management** - [pr-creation.yml](../templates/pr-creation.md)
* **Git Synchronization** - [git-sync-operations.yml](../templates/git-sync-operations.md)
* **Release Validation** - [release-validation.yml](../templates/release-validation.md)

This template architecture ensures consistent authentication patterns, standardized error handling, and maintainable operations across all pipelines. See [Template Integration Guide](../docs/template-integration.md) for orchestration patterns.

## Pipeline Inventory

### GitHub Synchronization Pipelines

#### main-to-dev-sync.yml

**Purpose**: Synchronizes main branch changes back to development branch.

**Trigger**: Scheduled or manual

**Functionality**:

* Monitors main branch for new commits
* Creates sync PRs to development branch
* Handles merge conflicts with automated resolution strategies

### Release Management Pipelines

#### release-branch-create.yml

**Purpose**: Creates release branches with version management and validation.

**Trigger**: Manual or scheduled

**Functionality**:

* Creates release branches following semantic versioning
* Validates branch naming conventions
* Checks for PR collisions (Gap 1 validation)
* Verifies branch existence (Gap 3 validation)
* Updates version files and changelogs

**Prerequisites**:

* Azure Key Vault access for GitHub credentials
* Git configuration with service principal

**Related Scripts**:

* `scripts/github/auth/Get-GitHubInstallationToken.ps1`: GitHub App authentication
* `scripts/github/Test-GitHubBranchExists.ps1`: Branch existence validation (Gap 3)
* `scripts/github/New-GitHubBranch.ps1`: GitHub branch creation via REST API
* `scripts/github/New-GitHubPullRequest.ps1`: Pull request creation

## Pipeline Architecture

### Authentication Pattern

All GitHub-integrated pipelines use a consistent authentication pattern:

1. **Key Vault Retrieval**: Uses `AzureCLI@2` task to retrieve secrets from Azure Key Vault
2. **Secret Variables**: Sets pipeline variables as secrets using `##vso[task.setvariable variable=NAME;isSecret=true]`
3. **GitHub Authentication**: Calls `Get-GitHubInstallationToken.ps1` helper script (handles JWT generation and installation token exchange)
4. **API Calls**: Uses installation token for GitHub REST API operations via helper scripts

### Service Connection

* **Name**: `ai-on-edge-service-connection`
* **Purpose**: Azure service principal for Key Vault access
* **Scope**: Azure subscription containing `ai-on-edge-secrets` Key Vault

### Agent Pool

* **Name**: `ai-on-edge-managed-pool`
* **Image**: `ubuntu-latest`
* **Purpose**: Consistent execution environment for all pipelines

## Common Prerequisites

All GitHub-integrated pipelines require the following prerequisites:

### Required Azure Resources

* **Key Vault**: `ai-on-edge-secrets` in the target Azure subscription
* **Service Connection**: `ai-on-edge-service-connection` with Key Vault access
* **Agent Pool**: `ai-on-edge-managed-pool` with `ubuntu-latest` image

### Key Vault Secrets

Required secrets in `ai-on-edge-secrets`:

| Secret Name                     | Purpose                   | Format                  | Example     |
| `github-edge-ai-app-client-id` | GitHub App authentication | String (numeric ID) | `123456` |
| `github-edge-ai-app-private-key` | GitHub App signing key | Base64-encoded PEM | `LS0tLS...` |

### GitHub App Permissions

The GitHub App must have the following permissions:

* **Contents**: Read and write access (for branch and commit operations)
* **Pull Requests**: Read and write access (for PR creation and management)
* **Metadata**: Read access (for repository information)

### PowerShell Dependencies

* **PowerShell 7.x** (`pwsh`) installed on agent
* **Helper Scripts** available in `scripts/github/` and `scripts/github/auth/`:
  * `Get-GitHubInstallationToken.ps1` - GitHub App authentication
  * `Test-GitHubBranchExists.ps1` - Branch validation
  * `New-GitHubBranch.ps1` - Branch creation
  * `New-GitHubPullRequest.ps1` - PR creation

### Authentication Flow

All pipelines follow this standard authentication pattern:

1. **Retrieve Secrets**: Use `AzureCLI@2` task to fetch secrets from Key Vault
2. **Set Variables**: Convert secrets to pipeline secret variables
3. **Authenticate**: Call `Get-GitHubInstallationToken.ps1` with client ID and private key
4. **Execute**: Use installation token for GitHub REST API operations

## Gap Implementations

The pipelines implement solutions for intelligent main-to-dev synchronization gaps:

* **Gap 1**: Automated Release PR Creation (integrated into `release-branch-create.yml`)
  * Status: IMPLEMENTED
  * Prevents manual PR creation errors
  * Ensures consistent PR structure and metadata

* **Gap 3**: GitHub Release Automation (`.github/workflows/create-release.yml`)
  * Status: IMPLEMENTED
  * Creates GitHub releases automatically after PR merge from `release/*` branches
  * Generates release notes with emoji-categorized conventional commits
  * Includes idempotency checks and error handling
  * Configuration: `.github/release.yml`

* **Gap 4**: Main-to-Dev Sync Automation (`main-to-dev-sync.yml`)
  * Status: PARTIAL
  * Automates sync PR creation
  * Requires conflict resolution enhancements

## Development Workflow

### Adding New Pipelines

1. Create YAML file in `.azuredevops/pipelines/`
2. Follow naming convention: `{feature}-{action}.yml`
3. Include comprehensive header comments
4. Document prerequisites and output variables
5. Update this README with pipeline entry
6. Test with dry-run or feature branch

### Testing Pipelines

1. Create feature branch: `git checkout -b feature/test-pipeline`
2. Modify pipeline YAML or referenced scripts
3. Push to trigger: `git push origin feature/test-pipeline`
4. Monitor pipeline execution in Azure DevOps
5. Validate outputs and logs
6. Clean up test branches and resources

### Debugging Guidelines

* Check Azure DevOps pipeline logs for error messages
* Verify Key Vault secret values and permissions
* Validate GitHub App installation and permissions
* Test authentication flow with helper scripts locally
* Review git operations with `git log --oneline --graph`

## Common Troubleshooting

This section covers troubleshooting scenarios that apply to all GitHub-integrated pipelines.

### Authentication Failures

**Problem**: `401 Unauthorized` or `403 Forbidden` from GitHub API

**Solutions**:

1. Verify GitHub App client ID is correct:

   ```bash
   az keyvault secret show --vault-name ai-on-edge-secrets --name github-edge-ai-app-client-id --query value -o tsv
   ```

2. Check private key format (must be base64-encoded PEM):

   ```bash
   az keyvault secret show --vault-name ai-on-edge-secrets --name github-edge-ai-app-private-key --query value -o tsv | base64 -d | head -n 1
   # Should output: -----BEGIN RSA PRIVATE KEY-----
   ```

3. Test authentication locally:

   ```powershell
   $clientId = az keyvault secret show --vault-name ai-on-edge-secrets --name github-edge-ai-app-client-id --query value -o tsv
   $privateKey = az keyvault secret show --vault-name ai-on-edge-secrets --name github-edge-ai-app-private-key --query value -o tsv

   .\scripts\github\auth\Get-GitHubInstallationToken.ps1 -ClientId $clientId -PrivateKeyBase64 $privateKey -Verbose
   ```

### Key Vault Access Issues

**Problem**: `The user, group or application does not have secrets get permission` error

**Solutions**:

1. Verify service connection has Key Vault access:

   ```bash
   az keyvault show --name ai-on-edge-secrets --query properties.accessPolicies
   ```

2. Grant service principal access:

   ```bash
   SP_OBJECT_ID=$(az ad sp list --display-name "ai-on-edge-service-connection" --query [0].id -o tsv)
   az keyvault set-policy --name ai-on-edge-secrets --object-id $SP_OBJECT_ID --secret-permissions get list
   ```

### GitHub API Rate Limiting

**Problem**: `403 rate limit exceeded` from GitHub API

**Solutions**:

1. GitHub App installations have higher rate limits than personal tokens (5,000 requests/hour vs 60/hour)
2. Check current rate limit status:

   ```bash
   curl -H "Authorization: Bearer $INSTALLATION_TOKEN" https://api.github.com/rate_limit
   ```

3. Add retry logic with exponential backoff in custom scripts
4. Spread operations across multiple workflow runs if needed

### Token Expiration

**Problem**: `401 Bad credentials` after working previously

**Solutions**:

1. Installation tokens expire after 1 hour - helper script automatically generates fresh tokens
2. If using cached token, regenerate it:

   ```powershell
   .\scripts\github\auth\Get-GitHubInstallationToken.ps1 -ClientId $clientId -PrivateKeyBase64 $privateKey
   ```

3. Verify system clock is synchronized (JWT validation requires accurate time)

### Insufficient GitHub App Permissions

**Problem**: `Resource not accessible by integration` error

**Solutions**:

1. Verify GitHub App has required permissions (see [Common Prerequisites](#common-prerequisites))
2. Check App installation scope:

   ```bash
   curl -H "Authorization: Bearer $INSTALLATION_TOKEN" https://api.github.com/installation/repositories
   ```

3. Update permissions in GitHub App settings: `https://github.com/settings/apps/{app-name}/permissions`
4. After permission changes, reinstall the App on the repository

## Related Documentation

* [GitHub Copilot Instructions](../../.github/copilot-instructions.md) - General repository conventions
* [Script Documentation](../../scripts/README.md) - Helper script reference
* [Main to Dev Sync Pipeline](../docs/main-to-dev-sync.md) - Detailed sync pipeline documentation
* [Release Branch Creation Pipeline](../docs/release-branch-create.md) - Release branch automation details

---

## Support and Feedback

For questions, issues, or suggestions:

* **Internal**: Post in the Edge AI DevOps Teams channel
* **Issues**: Create an issue in the [GitHub repository](https://github.com/microsoft/edge-ai/issues)
* **Documentation**: Suggest improvements via pull request to this documentation
