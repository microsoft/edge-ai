---
title: Pull Request Creation Template
description: Comprehensive guide to GitHub pull request operations template for Azure DevOps pipelines including PR creation, conflict checking, and validation
author: Edge AI Team
ms.date: 2025-11-17
ms.topic: reference
keywords:
  - github
  - pull-request
  - pr
  - api
  - create
  - validate
  - conflict
  - automation
estimated_reading_time: 15
---

## Overview

The Pull Request Creation template (`pr-creation.yml`) provides standardized GitHub API operations for creating, managing, and validating pull requests. It handles PR creation with comprehensive metadata, validation of existing PRs, conflict detection, and standardized output for integration workflows.

## When to Use

Use this template when you need:

- Release branch PR creation workflows
- Automated PR creation from CI/CD pipelines
- PR validation and conflict checking
- Standardized PR creation with labels, reviewers, and templates
- PR metadata management (assignees, milestone, draft status)
- Existing PR detection and conflict prevention

## Template Location

```plaintext
.azuredevops/templates/pr-creation.yml
```

## Operations

### create-pr

Creates a new pull request with comprehensive metadata support.

**Use Cases**:

- Automated release PR creation
- Feature branch to main PRs
- Cross-environment synchronization PRs

### check-conflicts

Checks for existing conflicting pull requests.

**Use Cases**:

- Pre-creation conflict detection
- Preventing duplicate PRs
- Workflow validation

### validate-pr

Validates PR state and mergeable status.

**Use Cases**:

- Pre-merge validation
- Release readiness checks
- Automated merge workflows

### update-pr

Updates existing pull request metadata.

**Use Cases**:

- Adding labels post-creation
- Updating reviewers
- Modifying PR state

## Parameters

| Parameter              | Type    | Default             | Description                                                           |
|------------------------|---------|---------------------|-----------------------------------------------------------------------|
| `operation`            | string  | *required*          | Operation: `create-pr`, `check-conflicts`, `validate-pr`, `update-pr` |
| `head`                 | string  | *required*          | Source branch name (without `refs/heads/`)                            |
| `base`                 | string  | `main`              | Target branch name (without `refs/heads/`)                            |
| `title`                | string  | *required*          | Pull request title                                                    |
| `body`                 | string  | `''`                | Pull request body/description                                         |
| `repository`           | string  | `microsoft/edge-ai` | GitHub repository (`owner/name` format)                               |
| `installationToken`    | string  | *required*          | GitHub App installation token                                         |
| `isDraft`              | boolean | `false`             | Create as draft pull request                                          |
| `labels`               | string  | `''`                | Comma-separated list of labels                                        |
| `assignees`            | string  | `''`                | Comma-separated list of GitHub usernames                              |
| `reviewers`            | string  | `''`                | Comma-separated list of reviewers                                     |
| `teamReviewers`        | string  | `''`                | Comma-separated list of team reviewers                                |
| `milestone`            | string  | `''`                | Milestone number or title                                             |
| `failOnConflict`       | boolean | `true`              | Fail pipeline if conflicting PR exists                                |
| `outputVariablePrefix` | string  | `prOps`             | Prefix for output variables                                           |
| `prNumber`             | string  | `''`                | PR number for update operations                                       |

## Output Variables

### create-pr Operation

| Variable           | Type    | Description                           |
|--------------------|---------|---------------------------------------|
| `{prefix}.created` | boolean | `true` if PR was created successfully |
| `{prefix}.number`  | number  | GitHub PR number                      |
| `{prefix}.url`     | string  | HTML URL to the pull request          |
| `{prefix}.state`   | string  | PR state: `open`, `closed`            |
| `{prefix}.draft`   | boolean | Whether PR is in draft state          |
| `{prefix}.error`   | string  | Error message if creation failed      |

### check-conflicts Operation

| Variable                          | Type    | Description                               |
|-----------------------------------|---------|-------------------------------------------|
| `{prefix}.hasExactConflict`       | boolean | `true` if exact PR (head→base) exists     |
| `{prefix}.hasPatternConflict`     | boolean | `true` if any PR from head exists         |
| `{prefix}.exactConflictNumber`    | number  | PR number of exact conflict (if exists)   |
| `{prefix}.patternConflictNumbers` | string  | Comma-separated PR numbers with same head |
| `{prefix}.hasConflicts`           | boolean | Overall conflict status                   |
| `{prefix}.error`                  | string  | Error message if check failed             |

### validate-pr Operation

| Variable                  | Type    | Description                                       |
|---------------------------|---------|---------------------------------------------------|
| `{prefix}.valid`          | boolean | `true` if PR is valid and mergeable               |
| `{prefix}.mergeable`      | boolean | GitHub mergeable status                           |
| `{prefix}.mergeableState` | string  | Detailed merge state: `clean`, `dirty`, `blocked` |
| `{prefix}.state`          | string  | PR state: `open`, `closed`                        |
| `{prefix}.draft`          | boolean | Draft status                                      |
| `{prefix}.headSha`        | string  | HEAD commit SHA                                   |
| `{prefix}.baseSha`        | string  | BASE commit SHA                                   |
| `{prefix}.error`          | string  | Error message if validation failed                |

### update-pr Operation

| Variable           | Type    | Description                           |
|--------------------|---------|---------------------------------------|
| `{prefix}.updated` | boolean | `true` if PR was updated successfully |
| `{prefix}.error`   | string  | Error message if update failed        |

## Usage Examples

### Basic PR Creation

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
    body: |
      ## Release v1.2.3

      This PR contains changes for the v1.2.3 release.

      ### Changes
      - Feature A
      - Bug fix B
      - Performance improvement C
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'releasePR'

- pwsh: |
    Write-Host "PR Created: $(releasePR.url)"
    Write-Host "PR Number: #$(releasePR.number)"
```

### PR with Labels and Reviewers

```yaml
- template: templates/pr-creation.yml
  parameters:
    operation: 'create-pr'
    head: 'release/v1.2.3'
    base: 'main'
    title: 'Release v1.2.3'
    body: 'Automated release PR'
    labels: 'release,automated,v1.2.3'
    reviewers: 'user1,user2,user3'
    teamReviewers: 'team-reviewers'
    assignees: 'release-manager'
    installationToken: '$(githubAuth.installationToken)'
```

### Draft PR Creation

```yaml
- template: templates/pr-creation.yml
  parameters:
    operation: 'create-pr'
    head: 'feature/new-capability'
    base: 'dev'
    title: '[WIP] New Capability Implementation'
    body: 'Work in progress - do not merge yet'
    isDraft: true
    labels: 'work-in-progress,feature'
    installationToken: '$(githubAuth.installationToken)'
```

### Check for Conflicts Before Creation

```yaml
# Step 1: Check for existing conflicting PRs
- template: templates/pr-creation.yml
  parameters:
    operation: 'check-conflicts'
    head: 'release/v1.2.3'
    base: 'main'
    repository: 'microsoft/edge-ai'
    installationToken: '$(githubAuth.installationToken)'
    failOnConflict: false
    outputVariablePrefix: 'conflictCheck'

# Step 2: Create PR only if no conflicts
- template: templates/pr-creation.yml
  parameters:
    operation: 'create-pr'
    head: 'release/v1.2.3'
    base: 'main'
    title: 'Release v1.2.3'
    installationToken: '$(githubAuth.installationToken)'
  condition: eq(variables['conflictCheck.hasConflicts'], 'false')
```

### Validate PR State

```yaml
- template: templates/pr-creation.yml
  parameters:
    operation: 'validate-pr'
    prNumber: '$(releasePR.number)'
    repository: 'microsoft/edge-ai'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'validation'

- pwsh: |
    if ("$(validation.valid)" -eq "true") {
      Write-Host "✓ PR is valid and ready to merge"
      Write-Host "  Mergeable: $(validation.mergeable)"
      Write-Host "  State: $(validation.mergeableState)"
    } else {
      Write-Warning "PR validation issues detected"
    }
```

### Update PR Labels

```yaml
- template: templates/pr-creation.yml
  parameters:
    operation: 'update-pr'
    prNumber: '$(releasePR.number)'
    labels: 'release,reviewed,approved'
    repository: 'microsoft/edge-ai'
    installationToken: '$(githubAuth.installationToken)'
```

## Integration Patterns

### Complete Release PR Workflow

```yaml
# Step 1: Authenticate
- template: templates/github-auth.yml
  parameters:
    githubRepository: 'microsoft/edge-ai'

# Step 2: Check for conflicting PRs
- template: templates/pr-creation.yml
  parameters:
    operation: 'check-conflicts'
    head: 'release/v$(RELEASE_VERSION)'
    base: 'main'
    installationToken: '$(githubAuth.installationToken)'
    failOnConflict: true
    outputVariablePrefix: 'prConflict'

# Step 3: Create release PR
- template: templates/pr-creation.yml
  parameters:
    operation: 'create-pr'
    head: 'release/v$(RELEASE_VERSION)'
    base: 'main'
    title: 'Release v$(RELEASE_VERSION)'
    body: '$(RELEASE_NOTES)'
    labels: 'release,automated'
    reviewers: 'release-team'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'createPR'

# Step 4: Validate new PR
- template: templates/pr-creation.yml
  parameters:
    operation: 'validate-pr'
    prNumber: '$(createPR.number)'
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'validatePR'

# Step 5: Report results
- pwsh: |
    Write-Host "=== Release PR Summary ==="
    Write-Host "PR Number: #$(createPR.number)"
    Write-Host "PR URL: $(createPR.url)"
    Write-Host "Valid: $(validatePR.valid)"
    Write-Host "Mergeable: $(validatePR.mergeable)"
```

### Multi-Target PR Creation

```yaml
- ${{ each target in parameters.targetBranches }}:
  - template: templates/pr-creation.yml
    parameters:
      operation: 'create-pr'
      head: 'feature/$(FEATURE_NAME)'
      base: ${{ target }}
      title: '[Feature] $(FEATURE_NAME) → ${{ target }}'
      body: 'Automated PR for ${{ target }} integration'
      installationToken: '$(githubAuth.installationToken)'
      outputVariablePrefix: 'pr_${{ target }}'
```

## Error Handling

### 422 Unprocessable Entity

**Scenario**: PR already exists with same head and base

**Template Behavior**:

- Sets `{prefix}.created = false`
- Sets `{prefix}.error` with details
- Does not fail unless `failOnConflict: true`

**Handling**:

```yaml
- pwsh: |
    if ("$(prOps.created)" -eq "false") {
      Write-Host "PR already exists: $(prOps.error)"
      # Get existing PR details or skip
    }
```

### Validation Errors

**Scenario**: PR cannot be created due to validation issues

**Template Behavior**:

- Returns validation errors in `{prefix}.error`
- Sets appropriate output flags to `false`
- Pipeline fails with error details

**Handling**:

```yaml
- pwsh: |
    if ("$(prOps.created)" -ne "true") {
      Write-Error "PR creation failed: $(prOps.error)"
      # Perform rollback or notify
      exit 1
    }
```

### Conflict Detection

**Scenario**: Existing PR conflicts detected

**Template Behavior**:

- Sets `hasExactConflict` or `hasPatternConflict` to `true`
- Provides conflict PR numbers in output variables
- Fails if `failOnConflict: true`

**Handling**:

```yaml
- pwsh: |
    if ("$(conflictCheck.hasExactConflict)" -eq "true") {
      $existingPR = "$(conflictCheck.exactConflictNumber)"
      Write-Host "Existing PR found: #$existingPR"
      Write-Host "Updating existing PR instead of creating new one"
    }
```

## Best Practices

### Use Descriptive PR Titles

Follow semantic conventions:

```yaml
# Good: Clear and descriptive
title: 'Release v1.2.3 - Feature Set B'
title: '[Hotfix] Security Vulnerability CVE-2024-12345'
title: 'Merge dev → main (Sprint 42)'

# Avoid: Vague or non-descriptive
title: 'Updates'
title: 'PR'
title: 'Changes'
```

### Include Comprehensive PR Body

Provide context and details:

```yaml
body: |
  ## Release v1.2.3

  ### Summary
  This release includes new features and bug fixes.

  ### Changes
  - ✨ Feature: Added user authentication
  - 🐛 Bug Fix: Resolved memory leak in cache layer
  - ⚡ Performance: Optimized database queries

  ### Testing
  - Unit tests: ✓ Passed
  - Integration tests: ✓ Passed
  - Manual QA: ✓ Completed

  ### Checklist
  - [x] Documentation updated
  - [x] Changelog updated
  - [x] Release notes prepared

  Resolves #123, #456
```

### Use Draft PRs for WIP

Mark incomplete work as draft:

```yaml
- template: templates/pr-creation.yml
  parameters:
    operation: 'create-pr'
    head: 'feature/in-progress'
    base: 'dev'
    title: '[WIP] Feature Implementation'
    isDraft: true
    labels: 'work-in-progress'
    installationToken: '$(githubAuth.installationToken)'
```

### Always Check Conflicts First

Prevent duplicate PRs:

```yaml
# Check first, create conditionally
- template: templates/pr-creation.yml
  parameters:
    operation: 'check-conflicts'
    head: 'release/v1.2.3'
    base: 'main'
    failOnConflict: false
    installationToken: '$(githubAuth.installationToken)'
    outputVariablePrefix: 'conflict'

- template: templates/pr-creation.yml
  parameters:
    operation: 'create-pr'
    # ... parameters ...
  condition: eq(variables['conflict.hasConflicts'], 'false')
```

### Assign Appropriate Reviewers

Use teams and individuals:

```yaml
parameters:
  reviewers: 'senior-dev1,senior-dev2'
  teamReviewers: 'architecture-review,security-team'
  assignees: 'release-manager'
```

## Troubleshooting

### Issue: PR Created But Labels Fail

**Symptom**: PR created successfully but labels not added

**Solution**:

1. Check label names exist in repository
2. Verify token has label write permissions
3. Labels fail gracefully - PR still created
4. Add labels manually or in subsequent update

### Issue: Reviewer Request Fails

**Symptom**: PR created but reviewers not requested

**Solution**:

1. Verify reviewer usernames are correct
2. Check team reviewer names match GitHub teams
3. Confirm token has reviewer request permissions
4. Reviewers can be added post-creation

### Issue: Draft Status Not Set

**Symptom**: PR created as open instead of draft

**Solution**:

1. Verify `isDraft` parameter is boolean `true` not string
2. Check repository allows draft PRs
3. Confirm GitHub App has PR write permissions
4. Convert to draft manually if needed

### Issue: Conflict Detection Misses Existing PR

**Symptom**: Existing PR not detected by conflict check

**Solution**:

1. Verify head/base branch names match exactly
2. Check PR state (might be closed)
3. Confirm repository parameter is correct
4. Review conflict check logic parameters

## Related Documentation

- [GitHub Authentication](github-auth.md)
- [GitHub Branch Operations](github-branch-operations.md)
- [Git Sync Operations](git-sync-operations.md)
- [Template Integration Guide](template-integration.md)

## References

- [GitHub Pull Requests API](https://docs.github.com/en/rest/pulls)
- [Pull Request Reviews API](https://docs.github.com/en/rest/pulls/reviews)
- [PR Best Practices](https://docs.github.com/en/pull-requests/collaborating-with-pull-requests)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
