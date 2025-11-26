---
title: Azure DevOps Release Automation Templates
description: Reusable Azure DevOps pipeline templates for GitHub integration, branch operations, pull requests, git synchronization, and release validation
author: wberry
ms.date: 01/17/2025
ms.topic: reference
keywords:
  - azure-devops
  - pipelines
  - templates
  - github
  - authentication
  - validation
estimated_reading_time: 8
---

This directory contains reusable Azure DevOps pipeline templates for release automation workflows. These templates provide standardized operations for GitHub integration, branch management, pull request operations, git synchronization, and release validation.

## Active Templates

All release automation pipelines now use these templates for consistent, maintainable operations:

### GitHub Authentication ([github-auth.yml](./github-auth.md))

Provides standardized GitHub App authentication for all pipelines requiring GitHub API access.

**Key Parameters:**

- `githubRepository` - Target repository (default: microsoft/edge-ai)
- `outputVariableName` - Name for token output variable (default: installationToken)

**Outputs:**

- `$(outputVariableName)` - GitHub installation token (secret)
- `GITHUB_AUTH_SUCCESS` - Boolean authentication status

**Usage:**

```yaml
- template: ../templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'
    outputVariableName: 'GITHUB_TOKEN'
    displayName: 'Authenticate with GitHub'
```

### GitHub Branch Operations ([github-branch-operations.yml](./github-branch-operations.md))

Manages GitHub branch operations via REST API with 4 operation modes.

**Operations:**

- `check-exists` - Verify branch existence
- `create-branch` - Create new branch from source
- `validate-state` - Validate branch protection status
- `get-branch-info` - Retrieve branch metadata

**Key Parameters:**

- `operation` - Operation type (required)
- `branchName` - Target branch name (required)
- `installationToken` - GitHub token (required)
- `sourceBranch` - Source for creation (create-branch only)
- `failOnExists` / `failOnNotExists` - Failure behavior flags

**Outputs:**

- `$(outputVariablePrefix)exists` - Boolean existence status
- `$(outputVariablePrefix)sha` - Branch commit SHA
- `$(outputVariablePrefix)created` - Boolean creation status
- `$(outputVariablePrefix)error` - Error message if failed

**Usage:**

```yaml
- template: ../templates/github-branch-operations.yml
  parameters:
    operation: 'check-exists'
    branchName: 'release/v1.0.0'
    installationToken: '$(GITHUB_TOKEN)'
    failOnExists: true
```

### Pull Request Operations ([pr-creation.yml](./pr-creation.md))

Comprehensive pull request management with 4 operation modes.

**Operations:**

- `create-pr` - Create new pull request
- `check-conflicts` - Check PR for merge conflicts
- `validate-pr` - Validate PR against criteria
- `update-pr` - Update existing PR properties

**Key Parameters:**

- `operation` - Operation type (required)
- `head` - Source branch (required for create-pr)
- `base` - Target branch (required for create-pr)
- `title` - PR title (required for create-pr)
- `body` - PR description
- `installationToken` - GitHub token (required)
- `isDraft` - Draft PR flag (default: false)
- `labels` - Comma-separated labels
- `assignees` - Comma-separated assignees
- `reviewers` - Comma-separated reviewers
- `prNumber` - PR number (required for update-pr)

**Outputs:**

- `$(outputVariablePrefix)created` - Boolean creation status
- `$(outputVariablePrefix)number` - PR number
- `$(outputVariablePrefix)url` - PR URL
- `$(outputVariablePrefix)hasConflicts` - Boolean conflict status
- `$(outputVariablePrefix)valid` - Boolean validation status

**Usage:**

```yaml
- template: ../templates/pr-creation.yml
  parameters:
    operation: 'create-pr'
    head: 'release/v1.0.0'
    base: 'main'
    title: 'Release v1.0.0'
    body: 'Automated release branch'
    installationToken: '$(GITHUB_TOKEN)'
    isDraft: false
```

### Git Synchronization Operations ([git-sync-operations.yml](./git-sync-operations.md))

Git operations for repository synchronization with 4 operation modes.

**Operations:**

- `configure-git` - Configure git identity and settings
- `clone-from-github` - Clone repository from GitHub
- `push-to-github` - Push changes to GitHub
- `fetch-merge` - Fetch and merge remote changes

**Key Parameters:**

- `operation` - Operation type (required)
- `workingDirectory` - Working directory path (default: $(Build.SourcesDirectory))
- `sourceBranch` - Source branch for operations
- `targetBranch` - Target branch for operations
- `mergeStrategy` - Merge strategy: merge, rebase, squash (default: merge)
- `conflictResolution` - Conflict handling: fail, ours, theirs (default: fail)
- `forceWithLease` - Force push with lease flag

**Usage:**

```yaml
- template: ../templates/git-sync-operations.yml
  parameters:
    operation: 'fetch-merge'
    sourceBranch: 'main'
    targetBranch: 'dev'
    mergeStrategy: 'merge'
    conflictResolution: 'fail'
```

### Release Validation ([release-validation.yml](./release-validation.md))

Comprehensive release validation with 4 operation modes.

**Operations:**

- `validate-version` - Semantic version validation
- `validate-changelog` - Changelog format validation
- `validate-readiness` - Overall release readiness scoring
- `validate-dependencies` - Dependency validation

**Key Parameters:**

- `operation` - Operation type (required)
- `releaseVersion` - Version to validate (required for validate-version)
- `previousVersion` - Previous version for comparison
- `validateIncrement` - Enforce semantic versioning rules
- `allowPrerelease` - Allow prerelease versions
- `changelogPath` - Path to CHANGELOG.md (default: CHANGELOG.md)
- `requireNotes` - Require release notes
- `strictValidation` - Enable strict validation mode

**Outputs:**

- `$(outputVariablePrefix)isValid` - Boolean validation status
- `$(outputVariablePrefix)versionType` - Version type: major, minor, patch, prerelease
- `$(outputVariablePrefix)validationErrors` - Error messages
- `$(outputVariablePrefix)validationWarnings` - Warning messages
- `$(outputVariablePrefix)changelogValid` - Boolean changelog validation
- `$(outputVariablePrefix)readinessScore` - Readiness score (0-100)

**Usage:**

```yaml
- template: ../templates/release-validation.yml
  parameters:
    operation: 'validate-readiness'
    releaseVersion: '1.0.0'
    changelogPath: 'CHANGELOG.md'
    requireNotes: true
    strictValidation: true
```

## Template Integration Patterns

### Job Dependencies and Variable Passing

Templates output variables using `isOutput=true` for cross-job consumption:

```yaml
jobs:
- job: AuthenticateGitHub
  steps:
  - template: ../templates/github-auth.yml
    parameters:
      outputVariableName: 'GITHUB_INSTALLATION_TOKEN'
    name: githubAuth

- job: CreateBranch
  dependsOn: AuthenticateGitHub
  variables:
    GITHUB_TOKEN: $[ dependencies.AuthenticateGitHub.outputs['githubAuth.GITHUB_INSTALLATION_TOKEN'] ]
  steps:
  - template: ../templates/github-branch-operations.yml
    parameters:
      operation: 'create-branch'
      branchName: 'release/v1.0.0'
      installationToken: '$(GITHUB_TOKEN)'
```

### Multi-Operation Template Pattern

Many templates support multiple operations via the `operation` parameter:

```yaml
# Check if branch exists
- template: ../templates/github-branch-operations.yml
  parameters:
    operation: 'check-exists'
    branchName: 'release/v1.0.0'
    installationToken: '$(GITHUB_TOKEN)'
    failOnExists: true

# Create branch if it doesn't exist
- template: ../templates/github-branch-operations.yml
  parameters:
    operation: 'create-branch'
    branchName: 'release/v1.0.0'
    sourceBranch: 'main'
    installationToken: '$(GITHUB_TOKEN)'
```

### Authentication Flow Pattern

Authenticate once, pass token to downstream operations:

```yaml
- job: ValidatePrerequisites
  steps:
  # Authenticate with GitHub
  - template: ../templates/github-auth.yml
    parameters:
      githubRepository: 'microsoft/edge-ai'
      outputVariableName: 'GITHUB_INSTALLATION_TOKEN'
    name: githubAuth

  # Use token in same job
  - template: ../templates/github-branch-operations.yml
    parameters:
      operation: 'check-exists'
      branchName: 'release/v1.0.0'
      installationToken: '$(GITHUB_INSTALLATION_TOKEN)'
      failOnExists: true
```

## Prerequisites

All templates requiring GitHub API access need:

- **Variable Group**: `ai-on-edge-secrets` containing:
  - `github-edge-ai-app-client-id` - GitHub App client ID
  - `github-edge-ai-app-private-key` - GitHub App private key (secret)
- **PowerShell Scripts**: Available in `.azuredevops/scripts/`
  - `Get-GitHubInstallationToken.ps1` - Token generation script

See [Authentication Guide](../docs/authentication.md) for setup instructions.

## Related Documentation

- [Authentication Guide](../docs/authentication.md) - GitHub App setup and configuration
- [Template Integration Guide](../docs/template-integration.md) - Advanced orchestration patterns
- [Pipeline Documentation](../pipelines/README.md) - Pipeline inventory and architecture
- [Release Branch Creation](../docs/release-branch-create.md) - Example pipeline using templates

## Template Development Guidelines

When creating new templates:

1. **Multi-Operation Pattern**: Use `operation` parameter for related functionality
2. **Output Variables**: Always use `isOutput=true` for cross-job variables
3. **Parameter Validation**: Provide clear defaults and validation rules
4. **Error Handling**: Handle API status codes (404, 422) explicitly
5. **Documentation**: Include parameter tables, operation descriptions, usage examples
