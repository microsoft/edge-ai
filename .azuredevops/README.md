---
title: Azure DevOps Release Automation
description: Centralized directory for Azure DevOps release automation pipelines, templates, and operator documentation
author: Edge AI Team
ms.date: 2025-11-15
ms.topic: reference
keywords:
  - azure devops
  - release automation
  - pipelines
  - ci/cd
estimated_reading_time: 10
---

This directory contains Azure DevOps pipelines, templates, and documentation for release automation workflows in the Edge AI project.

## Overview

The `.azuredevops/` directory houses all release automation infrastructure separate from the existing `.azdo/` CI/CD pipelines. This separation provides:

* **Clarity**: Release automation separated from build/test pipelines
* **Discoverability**: Centralized location for release workflows
* **Modularity**: Reusable templates for GitHub integration and validation

## Directory Structure

```text
.azuredevops/
├── README.md           # This file - overview and quick start
├── pipelines/          # Release automation pipeline YAML files
│   ├── README.md       # Pipeline inventory and detailed documentation
│   ├── main-to-dev-sync.yml
│   └── release-branch-create.yml
├── templates/          # Reusable pipeline templates for GitHub integration
│   ├── README.md       # Template documentation and integration patterns
│   ├── github-auth.yml
│   ├── github-branch-operations.yml
│   ├── pr-creation.yml
│   ├── git-sync-operations.yml
│   └── release-validation.yml
└── docs/               # Pipeline operator documentation
    ├── README.md       # Documentation index
    ├── main-to-dev-sync.md
    ├── release-branch-create.md
    ├── release-workflows.md
    └── intelligent-sync-gaps.md
```

## Pipeline Inventory

| Pipeline Name             | File                        | Purpose                                    | Templates Used                                     | Documentation                           | Triggers                      |
|---------------------------|-----------------------------|--------------------------------------------|----------------------------------------------------|-----------------------------------------|-------------------------------|
| **Main to Dev Sync**      | `main-to-dev-sync.yml`      | Intelligent synchronization of main to dev | None                                               | [Docs](./docs/main-to-dev-sync.md)      | Schedule (03:00 UTC), Chained |
| **Release Branch Create** | `release-branch-create.yml` | Create release branches from main          | github-auth, github-branch-operations, pr-creation | [Docs](./docs/release-branch-create.md) | Manual                        |

## Authentication and Configuration

### GitHub App Authentication Flow

All pipelines use GitHub App authentication for secure GitHub API operations:

1. **Generate JWT Token**: Using App ID and private key from Key Vault
2. **Get Installation Token**: Exchange JWT for installation token with repository access
3. **Authenticate API Calls**: Use installation token for GitHub API operations
4. **Token Expiration**: Tokens valid for 10 minutes, regenerated per pipeline run
5. **Security**: Secrets stored in Azure Key Vault, accessed via service connection

### Required Secrets

Secrets are stored in Azure Key Vault and accessed via the `ai-on-edge-service-connection` service connection:

| Secret Name            | Purpose                   | Format                  | Required By                      |
|------------------------|---------------------------|-------------------------|----------------------------------|
| `GitHubAppId`          | GitHub App identifier     | Numeric                 | All GitHub integration pipelines |
| `GitHubAppPrivateKey`  | GitHub App authentication | PEM format (multi-line) | All GitHub integration pipelines |
| `GitHubInstallationId` | Installation identifier   | Numeric                 | All GitHub integration pipelines |

### Service Connection

* **Name**: `ai-on-edge-service-connection`
* **Type**: Azure Resource Manager
* **Permissions**: Key Vault read access for secret retrieval

## Quick Start for Pipeline Operators

### Manually Trigger a Pipeline

1. Navigate to [Azure DevOps Pipelines](https://dev.azure.com/msazure/One/_build)
2. Select the pipeline to run from the list
3. Click **Run pipeline**
4. Configure parameters (if required)
5. Click **Run**

### View Pipeline Logs

1. Navigate to pipeline runs page
2. Click on the specific run you want to inspect
3. Select the job/stage to view detailed logs
4. Download logs for offline analysis if needed

### Troubleshoot Pipeline Failures

1. Check pipeline run summary for high-level error messages
2. Review job logs for detailed failure information
3. Verify Key Vault secrets are current and accessible
4. Check service connection permissions and validity
5. See [Troubleshooting Guide](./docs/intelligent-sync-gaps.md#troubleshooting) for common issues

## Development Workflow

### Adding New Release Automation Pipelines

1. Create pipeline YAML file in `pipelines/` directory
2. Add entry to pipeline inventory table above
3. Create pipeline documentation in `docs/` directory
4. Configure pipeline in Azure DevOps portal
5. Test pipeline on feature branch before merging

### Testing Pipeline Changes

1. Create feature branch for pipeline modifications
2. Update pipeline YAML file with changes
3. Temporarily configure Azure DevOps to use feature branch
4. Run test executions and validate behavior
5. Merge to main after successful validation

### GitHub App Configuration

If GitHub App credentials need to be rotated or updated:

1. Generate new private key in GitHub App settings
2. Update `GitHubAppPrivateKey` secret in Azure Key Vault
3. Verify `GitHubAppId` and `GitHubInstallationId` remain unchanged
4. Test authentication with a manual pipeline run

## Dependencies

### PowerShell Scripts

Release automation pipelines depend on PowerShell scripts in `scripts/github/`:

* `Create-GitHubJWT.ps1` - Generate JWT tokens for GitHub App authentication
* `Get-GitHubAppInstallationToken.ps1` - Exchange JWT for installation token
* `Create-GitHubPullRequest.ps1` - Create pull requests via GitHub API
* `Get-GitHubPullRequest.ps1` - Query pull request status
* `Get-LatestVersionTag.ps1` - Retrieve latest version tag for release branches

### Azure DevOps Variable Groups

* **Variable Group**: `ai-on-edge-secrets`
* **Secrets**: GitHub App credentials (linked from Key Vault)
* **Access**: Available to all pipelines in the project

### External Dependencies

* **Azure CLI**: Used for Key Vault secret retrieval
* **PowerShell 7+**: Required for script execution
* **Git**: For repository operations and branch management

## Related Documentation

* [Release Workflows Overview](./docs/release-workflows.md) - End-to-end release process
* [Intelligent Sync Gaps Analysis](./docs/intelligent-sync-gaps.md) - Gap analysis and implementations
* [Pipeline Inventory](./pipelines/README.md) - Detailed pipeline documentation
* [Build CI/CD Documentation](../docs/build-cicd/README.md) - Developer build and test pipelines

## Migration Notes

This directory structure was created on 2025-11-15 to reorganize NEW release automation pipelines from the intelligent sync gaps implementation. The `.azdo/` directory continues to house existing build, test, and legacy sync pipelines.

### Key Differences from `.azdo/`

* **Focus**: Release automation vs. build/test infrastructure
* **Templates**: GitHub integration templates vs. build/test template library
* **Documentation**: Operator-focused vs. developer-focused
* **Triggers**: Manual/scheduled release workflows vs. automated CI/CD

### Future Considerations

* **Template Expansion**: Add additional templates for common operations as patterns emerge
* **Template Versioning**: Consider versioning strategy if breaking changes to templates occur
* **Documentation Integration**: Link operator guides with developer documentation in `docs/build-cicd/`

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
