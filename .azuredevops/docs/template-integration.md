---
title: Template Integration Guide
description: Comprehensive guide to integrating GitHub and Git operation templates in Azure DevOps pipelines including chaining patterns, variable passing, error handling, and composition strategies
author: Edge AI Team
ms.date: 2025-11-17
ms.topic: guide
keywords:
  - template-integration
  - pipeline-composition
  - variable-passing
  - template-chaining
  - error-handling
  - best-practices
  - workflow-patterns
  - automation
estimated_reading_time: 7
---

## Overview

This guide covers essential template integration patterns for Azure DevOps pipelines, including template chaining, variable passing, error handling, and best practices for building automated workflows.

## Template Integration Patterns

### Sequential Chaining

Execute templates in sequence with dependencies:

```yaml
stages:
- stage: Setup
  jobs:
  - job: Auth
    steps:
    - template: templates/github-auth.yml

- stage: Operations
  dependsOn: Setup
  jobs:
  - job: Execute
    steps:
    - template: templates/git-sync-operations.yml
    - template: templates/release-validation.yml
```

### Parallel Execution

Execute independent templates simultaneously:

```yaml
jobs:
- job: ValidateVersion
  steps:
  - template: templates/release-validation.yml
    parameters:
      operation: 'validate-version'

- job: ValidateChangelog
  steps:
  - template: templates/release-validation.yml
    parameters:
      operation: 'validate-changelog'
```

### Conditional Execution

Execute templates based on conditions:

```yaml
steps:
- template: templates/github-auth.yml

- ${{ if eq(variables['Build.Reason'], 'PullRequest') }}:
  - template: templates/pr-creation.yml

- ${{ if eq(variables['Build.SourceBranchName'], 'main') }}:
  - template: templates/git-sync-operations.yml
```

## Variable Passing Strategies

### Output Variable Patterns

#### Pattern 1: Direct Variable Reference

```yaml
- template: templates/github-auth.yml
  parameters:
    outputVariableName: 'INSTALLATION_TOKEN'

- template: templates/github-branch-operations.yml
  parameters:
    installationToken: '$(githubAuth.INSTALLATION_TOKEN)'
```

Templates expose data through output variables:

```yaml
# Same job access
- template: templates/github-auth.yml
- script: echo "$(githubAuth.GITHUB_TOKEN)"

# Cross-job access
jobs:
- job: Auth
  steps:
  - template: templates/github-auth.yml
- job: Use
  dependsOn: Auth
  variables:
    token: $[ dependencies.Auth.outputs['githubAuth.GITHUB_TOKEN'] ]

# Cross-stage access
stages:
- stage: Auth
  jobs:
  - job: GetToken
    steps:
    - template: templates/github-auth.yml
- stage: Use
  dependsOn: Auth
  variables:
    token: $[ stageDependencies.Auth.GetToken.outputs['githubAuth.GITHUB_TOKEN'] ]
```

### Parameter Transformation

Transform parameters between templates:

```yaml
- pwsh: |
    $bump = switch ('${{ parameters.releaseType }}') {
      'major' { '1.0.0' }
      'minor' { '0.1.0' }
      'patch' { '0.0.1' }
    }
    Write-Host "##vso[task.setvariable variable=VERSION_BUMP]$bump"

- template: templates/github-branch-operations.yml
  parameters:
    versionBump: '$(VERSION_BUMP)'
```

## Error Handling Strategies

Handle template failures gracefully:

```yaml
# Continue on error with validation
- template: templates/github-branch-operations.yml
  parameters:
    operation: 'create-branch'
  continueOnError: true

- pwsh: |
    if ($env:GITHUB_OPERATION_SUCCESS -ne "true") {
        Write-Warning "Branch creation failed, using fallback"
    }

# Conditional error propagation
- template: templates/release-validation.yml
- pwsh: |
    if ("$(releaseValidation.isValid)" -ne "true") {
        if ($env:BUILD_REASON -eq "PullRequest") {
            Write-Warning "Validation failed in PR"
            exit 0
        } else {
            Write-Error "Validation failed"
            exit 1
        }
    }

# Retry logic
- pwsh: |
    $maxAttempts = 3
    $attempt = 0
    while ($attempt -lt $maxAttempts) {
        $attempt++
        # Attempt operation
        if ($LASTEXITCODE -eq 0) { break }
        Start-Sleep -Seconds (5 * $attempt)
    }
```

## Common Integration Scenarios

### Complete Release Workflow

```yaml
# Trigger: release/* branches
stages:
- stage: Validate
  jobs:
  - job: Check
    steps:
    - template: templates/github-auth.yml
    - template: templates/release-validation.yml
      parameters:
        operation: 'validate-readiness'
    - pwsh: |
        if ([int]"$(releaseValidation.readinessScore)" -lt 80) {
            Write-Error "Readiness below threshold"
            exit 1
        }

- stage: CreatePR
  dependsOn: Validate
  jobs:
  - job: PR
    steps:
    - template: templates/github-auth.yml
    - template: templates/pr-creation.yml
      parameters:
        operation: 'create-pr'
        sourceBranch: '$(Build.SourceBranchName)'
        targetBranch: 'main'
```

### Main to Dev Sync

```yaml
# Trigger: main branch commits
jobs:
- job: Sync
  steps:
  - template: templates/github-auth.yml
  - template: templates/git-sync-operations.yml
    parameters:
      operation: 'check-sync-status'
  - pwsh: |
      if ("$(gitSync.syncStatus)" -eq "BEHIND") {
          Write-Host "Syncing dev branch"
      } else {
          Write-Host "Already up to date"
          exit 0
      }
  - template: templates/git-sync-operations.yml
    parameters:
      operation: 'sync-main-to-dev'
```

## Best Practices

### Template Organization

- Group templates logically, use descriptive names
- Document parameters and outputs clearly
- Keep single responsibility per template
- Avoid monolithic templates mixing multiple concerns

### Parameter Management

- Provide sensible defaults for optional parameters
- Use strongly-typed parameters with validation
- Document constraints and expected formats
- Avoid unclear names or overloaded meanings

### Error Handling

- Validate inputs before operations
- Provide clear, specific error messages
- Implement retry logic for transient failures
- Use appropriate error types (error vs warning)

### Security

- Mark tokens/secrets with `issecret=true`
- Use variable groups for sensitive data
- Implement token expiration handling
- Never log tokens or pass secrets without protection

## Troubleshooting Integration Issues

### Output Variables Not Available

- Verify `##vso[task.setvariable variable=name;isOutput=true]value` syntax
- Check naming format: same job `$(task.var)`, cross-job `$[dependencies.Job.outputs['task.var']]`, cross-stage `$[stageDependencies.Stage.Job.outputs['task.var']]`
- Ensure `dependsOn` configured for dependent jobs/stages

### Template Not Found

- Verify path relative to pipeline file, check spelling/case
- Ensure file committed to repository
- Validate branch/tag references for external templates

### Parameter Type Mismatch

- Verify parameter type matches template definition
- Use PowerShell type conversion: `[int]"${{ parameters.value }}"`
- Review template parameter constraints

### Authentication Fails Between Templates

- Verify token variable names match across templates
- Check `isOutput=true` set on token variable
- Validate variable scoping (job vs stage level)

### Conditional Templates Not Executing

- Verify compile-time condition syntax: `${{ if eq(parameters.value, 'expected') }}`
- Use runtime conditions for dynamic checks: `condition: eq(variables['VAR'], 'value')`

## Related Documentation

- [GitHub Authentication Template](github-auth.md)
- [GitHub Branch Operations](github-branch-operations.md)
- [Pull Request Creation](pr-creation.md)
- [Git Sync Operations](git-sync-operations.md)
- [Release Validation](release-validation.md)
- [Authentication Guide](authentication.md)

## References

- [Azure DevOps Templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
- [Template Expressions](https://learn.microsoft.com/azure/devops/pipelines/process/expressions)
- [Variable Groups](https://learn.microsoft.com/azure/devops/pipelines/library/variable-groups)
- [Pipeline Best Practices](https://learn.microsoft.com/azure/devops/pipelines/process/best-practices)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
