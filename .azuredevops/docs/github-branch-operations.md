---
title: GitHub Branch Operations Template
description: Comprehensive guide to GitHub API branch operations template for Azure DevOps pipelines including branch checking, creation, and state validation
author: Edge AI Team
ms.date: 2025-11-17
ms.topic: reference
keywords:
  - github
  - branch
  - api
  - operations
  - create
  - validate
  - check
  - automation
estimated_reading_time: 12
---

## Overview

The GitHub Branch Operations template (`github-branch-operations.yml`) provides standardized GitHub API operations for branch management. It supports checking branch existence, creating branches, validating branch state, and retrieving comprehensive branch information through GitHub REST API calls.

## When to Use

Use this template when you need:

- Release branch creation and validation workflows
- Branch existence checking before operations
- GitHub branch state validation
- Automated branch management through API
- Branch metadata retrieval and validation
- Protection rule verification

## Template Location

```plaintext
.azuredevops/templates/github-branch-operations.yml
```

## Operations

### check-exists

Checks if a branch exists on GitHub and retrieves basic metadata.

**Use Cases**:

- Pre-flight checks before branch creation
- Conditional workflow based on branch existence
- Branch validation in release workflows

### create-branch

Creates a new branch on GitHub from a source branch.

**Use Cases**:

- Automated release branch creation
- Feature branch generation from templates
- Environment-specific branch creation

### validate-state

Validates comprehensive branch state including commit details and protection.

**Use Cases**:

- Release readiness validation
- Branch health checks
- Compliance verification

### get-branch-info

Retrieves detailed branch information and metadata.

**Use Cases**:

- Branch audit and reporting
- Metadata extraction for workflows
- Protection rule verification

## Parameters

| Parameter              | Type    | Default             | Description                                                                                |
|------------------------|---------|---------------------|--------------------------------------------------------------------------------------------|
| `operation`            | string  | *required*          | Operation to perform: `check-exists`, `create-branch`, `validate-state`, `get-branch-info` |
| `branchName`           | string  | *required*          | Branch name to operate on                                                                  |
| `sourceBranch`         | string  | `main`              | Source branch for creation operations                                                      |
| `repository`           | string  | `microsoft/edge-ai` | GitHub repository in `owner/name` format                                                   |
| `installationToken`    | string  | *required*          | GitHub App installation token                                                              |
| `failOnExists`         | boolean | `false`             | Fail pipeline if branch already exists                                                     |
| `failOnNotExists`      | boolean | `false`             | Fail pipeline if branch does not exist                                                     |
| `outputVariablePrefix` | string  | `branchOps`         | Prefix for output variables                                                                |

## Output Variables

### check-exists Operation

| Variable             | Type    | Description                                |
|----------------------|---------|--------------------------------------------|
| `{prefix}.exists`    | boolean | `true` if branch exists, `false` otherwise |
| `{prefix}.sha`       | string  | Commit SHA of the branch head              |
| `{prefix}.protected` | boolean | `true` if branch has protection rules      |
| `{prefix}.error`     | string  | Error message if operation failed          |

### create-branch Operation

| Variable           | Type    | Description                               |
|--------------------|---------|-------------------------------------------|
| `{prefix}.created` | boolean | `true` if branch was created successfully |
| `{prefix}.sha`     | string  | Commit SHA of the new branch              |
| `{prefix}.ref`     | string  | Full ref path: `refs/heads/{branchName}`  |
| `{prefix}.error`   | string  | Error message if creation failed          |

### validate-state Operation

| Variable                 | Type    | Description                        |
|--------------------------|---------|------------------------------------|
| `{prefix}.valid`         | boolean | `true` if branch state is valid    |
| `{prefix}.sha`           | string  | Current commit SHA                 |
| `{prefix}.protected`     | boolean | Branch protection status           |
| `{prefix}.authorName`    | string  | Last commit author name            |
| `{prefix}.commitDate`    | string  | Last commit date (ISO 8601)        |
| `{prefix}.commitMessage` | string  | Last commit message                |
| `{prefix}.error`         | string  | Error message if validation failed |

### get-branch-info Operation

| Variable                 | Type    | Description                       |
|--------------------------|---------|-----------------------------------|
| `{prefix}.name`          | string  | Branch name                       |
| `{prefix}.sha`           | string  | Current commit SHA                |
| `{prefix}.protected`     | boolean | Branch protection status          |
| `{prefix}.commitUrl`     | string  | URL to commit on GitHub           |
| `{prefix}.hasProtection` | boolean | Whether protection rules exist    |
| `{prefix}.error`         | string  | Error message if retrieval failed |

## Usage Examples

### Check Branch Existence

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

- template: templates/github-branch-operations.yml
  parameters:
    operation: 'check-exists'
    branchName: 'release/v1.2.3'
    repository: 'microsoft/edge-ai'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'releaseBranch'

- pwsh: |
    if ("$(releaseBranch.exists)" -eq "true") {
      Write-Host "Branch exists with SHA: $(releaseBranch.sha)"
    } else {
      Write-Host "Branch does not exist"
    }
```

### Create Release Branch

```yaml
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'create-branch'
    branchName: 'release/v1.2.3'
    sourceBranch: 'main'
    repository: 'microsoft/edge-ai'
    installationToken: '$(githubAuth.installationToken)'
    failOnExists: true
    outputVariablePrefix: 'newBranch'

- pwsh: |
    Write-Host "Branch created: $(newBranch.ref)"
    Write-Host "SHA: $(newBranch.sha)"
```

### Validate Branch State

```yaml
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'validate-state'
    branchName: 'release/v1.2.3'
    repository: 'microsoft/edge-ai'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'validation'

- pwsh: |
    if ("$(validation.valid)" -eq "true") {
      Write-Host "✓ Branch is valid"
      Write-Host "  Last commit: $(validation.commitMessage)"
      Write-Host "  Author: $(validation.authorName)"
      Write-Host "  Date: $(validation.commitDate)"
      Write-Host "  Protected: $(validation.protected)"
    }
```

### Conditional Branch Creation

```yaml
# Check if branch exists
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'check-exists'
    branchName: 'release/v1.2.3'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'check'

# Create only if it doesn't exist
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'create-branch'
    branchName: 'release/v1.2.3'
    sourceBranch: 'dev'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'create'
  condition: eq(variables['check.exists'], 'false')
```

### Get Detailed Branch Information

```yaml
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'get-branch-info'
    branchName: 'main'
    repository: 'microsoft/edge-ai'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'branchInfo'

- pwsh: |
    Write-Host "Branch Information:"
    Write-Host "  Name: $(branchInfo.name)"
    Write-Host "  SHA: $(branchInfo.sha)"
    Write-Host "  Protected: $(branchInfo.protected)"
    Write-Host "  Commit URL: $(branchInfo.commitUrl)"
```

## Integration Patterns

### Release Branch Creation Workflow

```yaml
# Step 1: Authenticate
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

# Step 2: Check if release branch exists
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'check-exists'
    branchName: 'release/v$(RELEASE_VERSION)'
    installationToken: '$(githubAuth.installationToken)'
    failOnExists: true
    outputVariablePrefix: 'preCheck'

# Step 3: Create release branch from dev
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'create-branch'
    branchName: 'release/v$(RELEASE_VERSION)'
    sourceBranch: 'dev'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'createRelease'

# Step 4: Validate new branch state
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'validate-state'
    branchName: 'release/v$(RELEASE_VERSION)'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'validateRelease'
```

### Multi-Branch Validation

```yaml
- ${{ each branch in parameters.branches }}:
  - template: templates/github-branch-operations.yml
    parameters:
      operation: 'validate-state'
      branchName: ${{ branch }}
      installationToken: '$(githubAuth.installationToken)'
      outputVariablePrefix: 'validate_${{ replace(branch, '/', '_') }}'
```

## Error Handling

### 404 Not Found

**Scenario**: Branch does not exist

**Template Behavior**:

- Sets `{prefix}.exists = false`
- Does not fail unless `failOnNotExists: true`
- Logs informational message

**Handling**:

```yaml
- pwsh: |
    if ("$(branchOps.exists)" -eq "false") {
      Write-Host "Branch does not exist, creating..."
      # Proceed with creation
    }
```

### 422 Unprocessable Entity

**Scenario**: Branch already exists (during creation)

**Template Behavior**:

- Sets `{prefix}.created = false`
- Sets `{prefix}.error = "Branch already exists"`
- Does not fail unless `failOnExists: true`

**Handling**:

```yaml
- pwsh: |
    if ("$(createOps.created)" -eq "false") {
      Write-Warning "Branch already exists: $(createOps.error)"
      # Handle accordingly
    }
```

### Authentication Failures

**Scenario**: Invalid or expired token

**Template Behavior**:

- Throws exception
- Pipeline fails
- Sets error output variable

**Handling**:

```yaml
# Re-authenticate if needed
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'
  condition: failed()
```

## Best Practices

### Fail Fast Validation

Use `failOnExists` and `failOnNotExists` for early pipeline termination:

```yaml
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'check-exists'
    branchName: 'release/v1.2.3'
    installationToken: '$(githubAuth.installationToken)'
    failOnExists: true  # Fail immediately if branch exists
```

### Meaningful Output Prefixes

Use descriptive prefixes for clarity:

```yaml
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'check-exists'
    branchName: 'main'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'mainBranchCheck'  # Not just 'check'

- pwsh: |
    Write-Host "Main branch SHA: $(mainBranchCheck.sha)"
```

### Branch Naming Conventions

Follow consistent naming:

```yaml
# Good: semantic naming
branchName: 'release/v1.2.3'
branchName: 'feature/add-authentication'
branchName: 'hotfix/security-patch'

# Avoid: inconsistent or unclear names
branchName: 'my-branch'
branchName: 'temp'
```

### Idempotent Operations

Design workflows to be safe for re-runs:

```yaml
# Check before create for idempotency
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'check-exists'
    branchName: 'release/v1.2.3'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'exists'

- template: templates/github-branch-operations.yml
  parameters:
    operation: 'create-branch'
    branchName: 'release/v1.2.3'
    sourceBranch: 'main'
    installationToken: '$(githubAuth.installationToken)'
  condition: eq(variables['exists.exists'], 'false')
```

## Troubleshooting

### Issue: Branch Creation Fails Silently

**Symptom**: `{prefix}.created` is false but no error logged

**Solution**:

1. Check `{prefix}.error` output variable
2. Verify token has write permissions
3. Confirm source branch exists
4. Check repository name format

### Issue: Branch Exists Check Returns False Positive

**Symptom**: Branch exists but template reports not found

**Solution**:

1. Verify branch name spelling (case-sensitive)
2. Check repository parameter format
3. Confirm token has repository read access
4. Ensure branch is pushed to GitHub (not just local)

### Issue: Protected Branch Error

**Symptom**: Operations fail on protected branches

**Solution**:

1. Check branch protection rules
2. Verify GitHub App has admin permissions if required
3. Use appropriate workflow for protected branches
4. Consider creating from unprotected source

## Related Documentation

- [GitHub Authentication](github-auth.md)
- [Pull Request Creation](pr-creation.md)
- [Git Sync Operations](git-sync-operations.md)
- [Template Integration Guide](template-integration.md)

## References

- [GitHub Branches API](https://docs.github.com/en/rest/branches)
- [GitHub Git References API](https://docs.github.com/en/rest/git/refs)
- [Branch Protection Rules](https://docs.github.com/en/repositories/configuring-branches-and-merges-in-your-repository/defining-the-mergeability-of-pull-requests/about-protected-branches)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
