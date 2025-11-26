---
title: Git Sync Operations Template
description: Comprehensive guide to git synchronization operations template for Azure DevOps pipelines including clone, push, and merge operations
author: Edge AI Team
ms.date: 2025-11-17
ms.topic: reference
keywords:
  - git
  - sync
  - operations
  - clone
  - push
  - merge
  - rebase
  - conflict-resolution
estimated_reading_time: 12
---

## Overview

The Git Sync Operations template (`git-sync-operations.yml`) provides standardized git operations for repository synchronization in Azure DevOps pipelines. It handles cloning, pushing, fetching, and merging with configurable strategies and conflict resolution.

## When to Use

Use this template when you need:

- Synchronized Azure DevOps and GitHub repositories
- Automated branch merging with conflict handling
- Push operations with safety checks (force-with-lease)
- Git configuration for automated commits
- Repository cloning with authentication

## Template Location

```plaintext
.azuredevops/templates/git-sync-operations.yml
```

## Operations

The template supports four primary operations:

### configure-git

Configure git user settings for commit attribution.

**Required Parameters**: `gitUserEmail`, `gitUserName`

**Use Cases**:

- Setting automation user for commits
- Configuring git before merge operations
- Preparing repository for push

### clone-from-github

Clone repository from GitHub with authentication and remote setup.

**Required Parameters**: `installationToken`

**Use Cases**:

- Initial repository setup in pipeline
- Fresh clone for validation
- Multi-repository workflows

### push-to-github

Push changes to GitHub with optional force-with-lease protection.

**Required Parameters**: `sourceBranch`, `installationToken`

**Optional Parameters**: `forceWithLease`, `createNewBranch`

**Use Cases**:

- Pushing synchronized changes
- Creating new remote branches
- Safe force push with lease protection

### fetch-merge

Fetch from remote and merge with configurable strategy and conflict resolution.

**Required Parameters**: `sourceBranch`, `targetBranch`

**Optional Parameters**: `mergeStrategy`, `conflictResolution`

**Use Cases**:

- Merging changes between branches
- Automated conflict resolution
- Branch synchronization

## Parameters

| Parameter            | Type    | Default                     | Description                                                                                 |
|----------------------|---------|-----------------------------|---------------------------------------------------------------------------------------------|
| `operation`          | string  | *(required)*                | Operation to perform: `configure-git`, `clone-from-github`, `push-to-github`, `fetch-merge` |
| `workingDirectory`   | string  | `$(Build.SourcesDirectory)` | Working directory for git operations                                                        |
| `sourceBranch`       | string  | `''`                        | Source branch name (for push/fetch-merge)                                                   |
| `targetBranch`       | string  | `''`                        | Target branch name (for fetch-merge)                                                        |
| `createNewBranch`    | boolean | `false`                     | Create new branch if it doesn't exist (for push)                                            |
| `forceWithLease`     | boolean | `false`                     | Use force-with-lease for push (safer than force)                                            |
| `fetchDepth`         | number  | `0`                         | Fetch depth (0 = full history)                                                              |
| `mergeStrategy`      | string  | `merge`                     | Merge strategy: `merge`, `rebase`, `squash`                                                 |
| `conflictResolution` | string  | `fail`                      | Conflict resolution: `fail`, `ours`, `theirs`                                               |
| `gitUserEmail`       | string  | `''`                        | Git user email for commits                                                                  |
| `gitUserName`        | string  | `''`                        | Git user name for commits                                                                   |

## Merge Strategies

### merge (default)

Creates a merge commit preserving history from both branches.

**Advantages**:

- Preserves complete history
- Clear indication of merge points
- Safe for collaborative work

**Use Cases**:

- Standard branch synchronization
- Feature branch integration
- Release branch merges

### rebase

Replays commits from source onto target, creating linear history.

**Advantages**:

- Clean, linear history
- No merge commits
- Easier to follow commit trail

**Disadvantages**:

- Rewrites history (use with caution)
- Conflicts may occur per commit

**Use Cases**:

- Feature branch cleanup before merge
- Keeping main branch linear
- Internal synchronization only

### squash

Combines all commits into single commit.

**Advantages**:

- Clean single commit
- Simplified history
- Easy to revert entire feature

**Disadvantages**:

- Loses individual commit history
- Harder to track detailed changes

**Use Cases**:

- Feature branch completion
- Minor fixes consolidation
- Release preparation

## Conflict Resolution

### fail (default)

Stop execution when conflicts are detected.

**Use Cases**:

- Manual conflict resolution required
- High-risk merges
- Production environments

### ours

Accept changes from current branch, discarding conflicting changes from incoming branch.

**Use Cases**:

- Known safe conflicts
- Reverting specific changes
- Override with local version

**Caution**: May discard important changes

### theirs

Accept changes from incoming branch, discarding conflicting changes from current branch.

**Use Cases**:

- Upstream synchronization
- Accept remote changes
- Override with remote version

**Caution**: May overwrite local changes

## Output Variables

This template modifies git state directly and does not produce output variables. Check git status and command exit codes for operation results.

## Usage Examples

### Configure Git for Automation

```yaml
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'configure-git'
    gitUserEmail: 'azure-devops@microsoft.com'
    gitUserName: 'Azure DevOps Automation'
```

### Clone with Authentication

```yaml
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

- template: templates/git-sync-operations.yml
  parameters:
    operation: 'clone-from-github'
    installationToken: '$(githubAuth.installationToken)'
```

### Push to New Branch

```yaml
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'release/v1.2.3'
    createNewBranch: true
    installationToken: '$(GITHUB_TOKEN)'
```

### Fetch and Merge with Conflict Resolution

```yaml
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'fetch-merge'
    sourceBranch: 'origin/main'
    targetBranch: 'dev'
    mergeStrategy: 'merge'
    conflictResolution: 'fail'
```

### Safe Force Push

```yaml
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'main'
    forceWithLease: true
    installationToken: '$(GITHUB_TOKEN)'
```

### Complete Sync Workflow

```yaml
# Step 1: Authenticate
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

# Step 2: Configure git
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'configure-git'
    gitUserEmail: 'azure-devops@microsoft.com'
    gitUserName: 'Azure DevOps Automation'

# Step 3: Fetch and merge
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'fetch-merge'
    sourceBranch: 'origin/main'
    targetBranch: 'dev'
    mergeStrategy: 'merge'

# Step 4: Push synchronized changes
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'dev'
    installationToken: '$(githubAuth.installationToken)'
```

## Integration Patterns

### Main to Dev Synchronization

```yaml
trigger:
  branches:
    include:
      - main

steps:
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

- template: templates/git-sync-operations.yml
  parameters:
    operation: 'configure-git'
    gitUserEmail: 'sync-bot@microsoft.com'
    gitUserName: 'Sync Bot'

- template: templates/git-sync-operations.yml
  parameters:
    operation: 'fetch-merge'
    sourceBranch: 'origin/main'
    targetBranch: 'dev'
    mergeStrategy: 'merge'
    conflictResolution: 'fail'

- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'dev'
    installationToken: '$(githubAuth.installationToken)'
```

### Release Branch Synchronization

```yaml
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'fetch-merge'
    sourceBranch: 'origin/release/v1.2.3'
    targetBranch: 'main'
    mergeStrategy: 'merge'

- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'main'
    forceWithLease: false
    installationToken: '$(GITHUB_TOKEN)'
```

### Multi-Repository Sync

```yaml
# Sync repository A
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/repo-a'
    outputVariableName: 'REPO_A_TOKEN'

- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'main'
    workingDirectory: '$(Build.SourcesDirectory)/repo-a'
    installationToken: '$(REPO_A_TOKEN)'

# Sync repository B
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/repo-b'
    outputVariableName: 'REPO_B_TOKEN'

- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'main'
    workingDirectory: '$(Build.SourcesDirectory)/repo-b'
    installationToken: '$(REPO_B_TOKEN)'
```

## Error Handling

### Authentication Failures

**Symptom**: Push or clone fails with authentication error

**Resolution**:

1. Verify installation token is valid
2. Check GitHub App has repository access
3. Ensure token hasn't expired
4. Confirm repository exists

### Merge Conflicts

**Symptom**: Fetch-merge fails with conflict error

**Resolution with `fail` strategy**:

1. Review conflicting files manually
2. Resolve conflicts locally
3. Commit resolved changes
4. Re-run sync

**Resolution with `ours`/`theirs` strategy**:

1. Verify automatic resolution is acceptable
2. Review changes after merge
3. Test merged code
4. Push synchronized branch

### Push Rejection

**Symptom**: Push fails with "non-fast-forward" error

**Resolution**:

1. Fetch latest changes from remote
2. Merge or rebase local changes
3. Retry push
4. Use `forceWithLease: true` if safe to overwrite

### Conflict Resolution Failures

**Symptom**: Automatic conflict resolution fails

**Resolution**:

1. Switch to `fail` strategy
2. Manually resolve conflicts
3. Consider different merge strategy
4. Review conflict patterns

## Best Practices

### Configure Git First

Always configure git user before operations that create commits:

```yaml
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'configure-git'
    gitUserEmail: 'automation@microsoft.com'
    gitUserName: 'Automation Bot'

# Now safe to perform merge operations
```

### Use Force-With-Lease Over Force

Prefer `forceWithLease: true` over traditional force push:

```yaml
# Good - protects against unexpected remote changes
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'main'
    forceWithLease: true

# Avoid - can overwrite unexpected changes
# forceWithLease: false with force flag
```

### Choose Appropriate Merge Strategy

- **merge**: Default for most cases, preserves history
- **rebase**: Use for clean linear history, internal branches only
- **squash**: Use for feature completion, simplified history

### Handle Conflicts Explicitly

Default to `fail` strategy for conflict resolution:

```yaml
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'fetch-merge'
    sourceBranch: 'origin/main'
    targetBranch: 'dev'
    conflictResolution: 'fail'  # Explicit handling

# Add error handling
- pwsh: |
    if ($LASTEXITCODE -ne 0) {
      Write-Error "Merge conflicts detected - manual resolution required"
      exit 1
    }
```

### Verify Operations

Check git state after critical operations:

```yaml
- template: templates/git-sync-operations.yml
  parameters:
    operation: 'push-to-github'
    sourceBranch: 'main'
    installationToken: '$(GITHUB_TOKEN)'

- pwsh: |
    git status
    git log -1
    # Verify expected state
```

## Troubleshooting

### Issue: Authentication Token Not Available

**Symptom**: Clone or push fails with "authentication required"

**Solution**:

1. Ensure `github-auth.yml` template runs first
2. Verify output variable name matches
3. Check token is not expired
4. Confirm variable is accessible in current scope

### Issue: Merge Conflict with Auto-Resolution

**Symptom**: `ours` or `theirs` strategy produces unexpected results

**Solution**:

1. Review conflicting files list
2. Verify automatic resolution is appropriate
3. Consider switching to `fail` strategy
4. Manually resolve complex conflicts

### Issue: Push Rejected by Remote

**Symptom**: "Updates were rejected because the remote contains work..."

**Solution**:

1. Fetch latest changes: `git fetch origin`
2. Merge remote changes into local branch
3. Retry push operation
4. Use `forceWithLease: true` if local version is authoritative

### Issue: Remote Tracking Branch Not Found

**Symptom**: "fatal: 'origin/branch-name' is not a commit..."

**Solution**:

1. Verify branch name is correct
2. Ensure branch exists on remote
3. Run `git fetch origin` first
4. Check remote configuration: `git remote -v`

### Issue: Working Directory Not Clean

**Symptom**: "error: Your local changes to the following files would be overwritten..."

**Solution**:

1. Commit or stash local changes
2. Verify working directory state
3. Clean untracked files if necessary
4. Reset to known good state

## Related Documentation

- [GitHub Authentication](github-auth.md)
- [GitHub Branch Operations](github-branch-operations.md)
- [Pull Request Creation](pr-creation.md)
- [Authentication Guide](authentication.md)
- [Template Integration Guide](template-integration.md)

## References

- [Git Documentation](https://git-scm.com/doc)
- [Git Merge Strategies](https://git-scm.com/docs/git-merge#_merge_strategies)
- [Git Rebase](https://git-scm.com/docs/git-rebase)
- [Force with Lease](https://git-scm.com/docs/git-push#Documentation/git-push.txt---force-with-leaseltrefnamegt)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
