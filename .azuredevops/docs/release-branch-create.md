---
title: Release Branch Creation Pipeline
description: Automated pipeline for creating release branches in Azure DevOps and GitHub with validation gates and version management
author: Edge AI Team
ms.date: 2025-11-11
ms.topic: reference
estimated_reading_time: 12
keywords:
  - release branch
  - azure devops
  - github
  - pipeline automation
  - gitversion
  - semantic versioning
  - branch validation
  - pr detection
  - github app authentication
  - dual repository sync
---

## Overview

The Release Branch Creation pipeline automates the process of creating release branches from the development branch in both Azure DevOps and GitHub repositories. It ensures consistency between the two platforms, validates prerequisites, and prevents common issues like duplicate releases or conflicting pull requests.

## Purpose

This pipeline serves as the first step in the release workflow by:

- Calculating semantic versions using GitVersion
- Validating that no conflicting release PRs or branches exist
- Creating release branches in both Azure DevOps and GitHub
- Maintaining synchronization between dual repositories
- Enforcing release workflow best practices

## Prerequisites

See [Common Prerequisites](../pipelines/README.md#common-prerequisites) for Azure resources, Key Vault secrets, GitHub App permissions, and authentication flow.

### Pipeline-Specific Requirements

**Repository State**:

- Development branch (`dev`) must exist in both Azure DevOps and GitHub
- No open pull requests with `release/` prefix in GitHub
- Target release branch must not already exist in either repository

**Azure DevOps Permissions**:

- Build Service account needs branch creation and PR read permissions

## Pipeline Parameters

| Parameter        | Type   | Default | Description                                        |
|------------------|--------|---------|----------------------------------------------------|
| `releaseVersion` | string | (empty) | Optional semantic version override (e.g., `1.2.3`) |

**When to override `releaseVersion`:**

- Hotfix releases that don't follow standard versioning
- Major version bumps
- Pre-release versions (e.g., `2.0.0-beta.1`)

**When to use default (empty):**

- Standard feature releases
- Automated versioning from commit history
- Following GitVersion conventions

## Pipeline Triggers

**Manual trigger only** - This pipeline does not run automatically on commits or PRs.

## Pipeline Output Variables

The pipeline exposes the following output variables for downstream consumption:

| Variable             | Job                  | Description                   | Example         |
| `RELEASE_VERSION` | CalculateVersion | Semantic version for the release | `1.2.3` |
| `RELEASE_BRANCH_NAME` | CalculateVersion | Full branch name | `release/1.2.3` |
| `VALIDATION_STATUS` | ValidatePrerequisites | Validation result | `passed` |

**Consuming output variables in dependent stages:**

```yaml
stages:
  - stage: UseReleaseVariables
    dependsOn: CreateReleaseBranch
    jobs:
      - job: DeployRelease
        variables:
          releaseVersion: $[ stageDependencies.CreateReleaseBranch.CalculateVersion.outputs['version.RELEASE_VERSION'] ]
        steps:
          - script: echo "Deploying version $(releaseVersion)"
```

## Pipeline Structure

**Stage**: `CreateReleaseBranch`

**Jobs**:

1. **CalculateVersion**
   - Installs GitVersion and calculates semantic version from Git history
   - Uses `GitVersion.yml` configuration (GitFlow strategy)
   - Version based on: latest `dev` tag, commit messages (`fix:`, `feat:`, `BREAKING CHANGE:`)
   - Outputs: `RELEASE_VERSION`, `RELEASE_BRANCH_NAME`
   - **Fails if**: GitVersion.yml invalid, Git history inaccessible, or no tags found

2. **ValidatePrerequisites** (depends on CalculateVersion)
   - **Template**: [github-auth.yml](../templates/github-auth.md) - Authenticates with GitHub App
   - **Template**: [github-branch-operations.yml](../templates/github-branch-operations.md) (operation: check-exists) - Validates Azure DevOps branch doesn't exist
   - **Template**: [github-branch-operations.yml](../templates/github-branch-operations.md) (operation: check-exists) - Validates GitHub branch doesn't exist
   - **Prevents**: Multiple simultaneous releases, accidental branch overwrites
   - **Fails if**: Any validation check fails (branch already exists in either repository)

3. **CreateBranch** (depends on ValidatePrerequisites)
   - **Template**: [github-branch-operations.yml](../templates/github-branch-operations.md) (operation: create-branch) - Creates Azure DevOps branch from `dev`
   - **Template**: [github-branch-operations.yml](../templates/github-branch-operations.md) (operation: create-branch) - Creates GitHub branch from `dev`
   - **Template**: [pr-creation.yml](../templates/pr-creation.md) (operation: create-pr) - Creates pull request to merge release branch to main
   - **Rollback** (if needed):

     ```bash
     az repos ref delete --name "refs/heads/release/X.Y.Z" --repository edge-ai
     gh api -X DELETE "/repos/microsoft/edge-ai/git/refs/heads/release/X.Y.Z"
     ```

**Template Usage**: This pipeline demonstrates template orchestration with authentication flow, branch operations, and PR creation across Azure DevOps and GitHub repositories. See [Template Integration Guide](./template-integration.md) for advanced patterns.

## Usage Examples

### Standard Feature Release

```yaml
# Trigger manually from Azure Pipelines UI
# Leave releaseVersion parameter empty
# GitVersion will calculate version from commit history
```

**Expected Flow**:

1. GitVersion calculates `1.2.3` from dev branch
2. Validation checks pass
3. Branch `release/1.2.3` created in both repositories

### Hotfix Release with Manual Version

```yaml
# Trigger manually from Azure Pipelines UI
# Set releaseVersion parameter to: 1.2.4
```

**Expected Flow**:

1. Pipeline uses provided version `1.2.4`
2. Validation checks pass
3. Branch `release/1.2.4` created in both repositories

### Major Version Bump

```yaml
# Trigger manually from Azure Pipelines UI
# Set releaseVersion parameter to: 2.0.0
```

**Expected Flow**:

1. Pipeline uses provided version `2.0.0`
2. Validation checks pass
3. Branch `release/2.0.0` created in both repositories

## Troubleshooting

See [Common Troubleshooting](../pipelines/README.md#common-troubleshooting) for authentication, Key Vault, and API issues.

### Branch Already Exists

- **Azure DevOps**: `az repos ref delete --name "refs/heads/release/X.Y.Z" --repository edge-ai`
- **GitHub**: `gh api -X DELETE "/repos/microsoft/edge-ai/git/refs/heads/release/X.Y.Z"`
- **Split-brain** (GitHub exists, Azure DevOps doesn't): Delete GitHub branch and re-run, or create Azure DevOps branch: `az repos ref create --name "refs/heads/release/X.Y.Z" --repository edge-ai --object-id <github_commit_sha>`

### Release PR Already Open

- Check open PRs: `gh pr list --search "head:release/"`
- Complete/close existing PR before creating new release

### Version Calculation Fails

- Verify `GitVersion.yml` syntax, Git tags on dev, conventional commit messages
- Debug locally: `gitversion /showvariable SemVer`

## Integration with Release Workflow

This pipeline is **Phase 4, Task 4.3** of the broader release automation workflow:

### Workflow Position

```text
1. Development (dev branch) ──> Feature commits
                                     │
2. Release Branch Creation ──────> [THIS PIPELINE]
                                     │
3. Release Testing ──────────────> Validation in release/X.Y.Z
                                     │
4. GitHub PR Creation ───────────> Automated PR to main
                                     │
5. GitHub Merge ──────────────────> Release goes to main
                                     │
6. Sync to Azure DevOps ──────────> GitHub main → Azure DevOps main (3hr schedule)
                                     │
7. Merge to Dev ──────────────────> main → dev (closes loop)
```

### Related Pipelines

- **github-pull.yml**: Syncs GitHub main → Azure DevOps main (scheduled every 3 hours)
- **release-rebase.yml**: Rebases release branches from GitHub changes
- **GitHub Workflow** (future): Automates PR creation from release branches to main

### Next Steps After Pipeline Success

1. **Verify branches exist** in both Azure DevOps and GitHub
2. **Begin testing** on the release branch
3. **Create GitHub PR** (manual or automated) to merge release to main
4. **Monitor sync** to ensure changes propagate to Azure DevOps main

## Notes

- Pipeline uses PowerShell 7+ for cross-platform compatibility
- All API calls include proper error handling and exit codes
- GitHub installation token expires in 1 hour (sufficient for pipeline)
- JWT token expires in 10 minutes (sufficient for authentication flow)
- Pipeline fails fast to prevent partial state (except GitHub-only failures)
- Branch protection rules must allow Build Service account to create branches

## Security Considerations

- GitHub App private key stored in Azure Key Vault
- Installation token masked in pipeline logs
- JWT tokens expire quickly to minimize exposure window
- System.AccessToken uses built-in Azure DevOps authentication
- All secrets retrieved from variable group, never hardcoded

## Performance

- **Typical execution time**: 3-5 minutes
- **GitVersion calculation**: ~30 seconds
- **Validation checks**: ~45 seconds per repository
- **Branch creation**: ~30 seconds per repository
- **Total**: Approximately 3-4 minutes for successful run

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
