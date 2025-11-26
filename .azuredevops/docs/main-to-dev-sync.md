---
title: Main-to-Dev Sync Pipeline
description: Intelligent synchronization pipeline that automatically syncs AzDO main branch to dev branch using conditional strategy selection (force-push or merge)
author: Edge AI Team
ms.date: 2025-11-16
ms.topic: reference
keywords:
  - azure-pipelines
  - synchronization
  - branch-strategy
  - automation
---

## Overview

The **main-to-dev-sync.yml** pipeline provides intelligent synchronization from the Azure DevOps `main` branch to the `dev` branch. It automatically selects the appropriate sync strategy (force-push or merge) based on the current repository state, ensuring both external contributions and unreleased development work are properly handled.

### Purpose

* **Integrate External Contributions**: Automatically merge external contributions from GitHub main into AzDO dev
* **Preserve Unreleased Work**: Protect unreleased commits in dev during mid-cycle syncs
* **Post-Release Clean Slate**: Reset dev to match main after releases for a clean development cycle
* **Prevent Work Loss**: Intelligent decision logic prevents accidental overwriting of unreleased commits

### Key Features

* **Conditional Strategy Selection**: Automatically chooses force-push or merge based on `git log` analysis
* **Conflict Detection**: Gracefully fails with clear instructions when merge conflicts occur
* **SHA Verification**: Validates sync success for both strategy paths
* **Idempotent**: Skips sync if dev is already up-to-date with main
* **Dual Triggering**: Runs after GitHub sync AND on daily schedule

---

## Pipeline Architecture

### Trigger Configuration

```yaml
trigger: none          # No CI trigger
pr: none              # No PR validation

schedules:
  - cron: "0 3 * * *" # Daily at 03:00 UTC (backup)
    branches: [main]
    always: false      # Only if changes exist
```

### Trigger Sources

1. **Primary Trigger**: Chained from `github-pull.yml` after successful GitHub→AzDO main sync
2. **Backup Trigger**: Daily scheduled run at 03:00 UTC
3. **Manual Trigger**: Can be queued manually from Azure DevOps UI

---

## Decision Logic

### Strategy Selection

The pipeline selects sync strategy based on dev branch state relative to main:

* **SKIP**: `main SHA == dev SHA` (already synchronized)
* **FORCE_PUSH**: `git log main..dev` is empty (dev has no unreleased commits → safe reset to main)
* **MERGE**: `git log main..dev` has commits (dev has unreleased work → preserve via merge commit)

---

## Strategy Paths

### Force-Push Strategy

* **When**: Dev has no unreleased commits (typically post-release)
* **Action**: `git push origin main:dev --force-with-lease`
* **Result**: Dev history becomes identical to main (fast-forward)
* **Verification**: SHA match after push

### Merge Strategy

* **When**: Dev has unreleased commits (mid-cycle development)
* **Action**: `git checkout dev && git merge origin/main --no-ff -m "chore: integrate external contributions"`
* **Result**: Merge commit preserves both histories (non-fast-forward)
* **Verification**: Main SHA exists in dev history

---

## Conflict Handling

### Conflict Detection

Merge conflicts occur when:

* Same file modified in both main and dev
* Conflicting changes to same lines
* File deleted in one branch, modified in other

### Automatic Detection

```powershell
git merge origin/main --no-ff -m "chore: integrate external contributions"

if ($LASTEXITCODE -ne 0) {
  # Merge failed - conflict detected
  Write-Host "##vso[task.logissue type=error]Merge conflict detected"
  Write-Host "##vso[task.setvariable variable=CONFLICT_DETECTED]true"

  # Pipeline fails - manual intervention required
  exit 1
}
```

### Manual Resolution Workflow

When conflict detected, follow these steps:

1. **Clone Repository Locally**

   ```bash
   git clone <azdo-repo-url>
   cd edge-ai
   ```

2. **Checkout Dev Branch**

   ```bash
   git checkout dev
   git pull origin dev
   ```

3. **Attempt Merge**

   ```bash
   git merge origin/main
   # Conflict markers will appear in affected files
   ```

4. **Resolve Conflicts**

   ```bash
   # Open conflicted files, resolve markers
   # Choose correct version or combine changes

   # Example conflict markers:
   # <<<<<<< HEAD (dev)
   #   dev version code
   # =======
   #   main version code
   # >>>>>>> origin/main
   ```

5. **Finalize Merge**

   ```bash
   git add <resolved-files>
   git commit -m "chore: resolve merge conflicts from main sync"
   git push origin dev
   ```

6. **Verify Resolution**

   ```bash
   # Check dev contains main SHA
   git log dev --oneline | grep $(git rev-parse origin/main)
   ```

### Conflict Prevention Best Practices

* **Minimize Main Changes**: Keep direct commits to main rare (release merges only)
* **External Contribution Review**: Review external PRs for potential conflicts before merge
* **Regular Syncs**: Frequent syncs reduce conflict complexity
* **Communication**: Coordinate with team when large external changes arrive

---

## Manual Override

### Force-Push Override (Manual)

Use when you need to **reset dev to match main** regardless of unreleased commits.

⚠️ **WARNING**: This will **permanently delete** unreleased commits in dev.

```bash
# Verify you want to discard unreleased commits
git log origin/main..origin/dev --oneline
# Review output carefully!

# Force-push main to dev
git push origin origin/main:dev --force

# Verification
git fetch origin dev
git log origin/dev --oneline -5
```

**Use Cases**:

* Dev branch corrupted or in bad state
* Release was completed but sync failed
* Intentionally discarding experimental dev work

### Merge Override (Manual)

Use when you need to **manually merge main into dev** during automation outage.

```bash
# Ensure local branches are current
git fetch origin main
git fetch origin dev

# Checkout dev and merge main
git checkout dev
git pull origin dev
git merge origin/main --no-ff -m "chore: manual merge from main (automation outage)"

# Resolve any conflicts, then:
git push origin dev

# Verification
git log dev --oneline -10
```

**Use Cases**:

* Pipeline automation unavailable
* Immediate sync required (can't wait for scheduled trigger)
* Custom merge message needed

---

## Test Scenarios

### Scenario 1: Post-Release Force-Push

**Test Setup**:

```bash
# Simulate post-release state
# Both branches at v1.2.0
dev:  A-B-C-D-E-F-G
main: A-B-C-D-E-F-G
```

**Expected Behavior**:

1. Pipeline checks `git log main..dev` → **empty**
2. Strategy selected: **FORCE_PUSH**
3. Action: `git push origin main:dev --force-with-lease`
4. Verification: SHA match ✓
5. Result: dev = A-B-C-D-E-F-G (unchanged, but reset)

**Validation**:

```bash
git rev-parse origin/main
git rev-parse origin/dev
# Output should be identical
```

---

### Scenario 2: Mid-Cycle Merge with Unreleased Work

**Test Setup**:

```bash
# Simulate mid-cycle external contribution
dev:  A-B-C-D-E-F-G-H-I  # H-I unreleased
main: A-B-C-D-E-F-G-X    # X external fix
```

**Expected Behavior**:

1. Pipeline checks `git log main..dev` → **"H I"** (non-empty)
2. Strategy selected: **MERGE**
3. Action: `git merge origin/main --no-ff`
4. Verification: main SHA in dev history ✓
5. Result: dev = A-B-C-D-E-F-G-H-I-X-M (merge commit M)

**Validation**:

```bash
# Check main SHA is in dev
MAIN_SHA=$(git rev-parse origin/main)
git log origin/dev --oneline | grep ${MAIN_SHA:0:7}
# Should find X commit

# Check unreleased commits still exist
git log origin/dev --oneline | grep -E 'H|I'
# Should find H and I commits
```

---

### Scenario 3: Conflict Detection

**Test Setup**:

```bash
# Simulate conflicting changes
dev:  A-B-C-D-H    # H modifies file.txt line 10
main: A-B-C-D-X    # X also modifies file.txt line 10
```

**Expected Behavior**:

1. Pipeline checks `git log main..dev` → **"H"** (non-empty)
2. Strategy selected: **MERGE**
3. Action: `git merge origin/main --no-ff`
4. **Conflict Detected**: Merge fails with exit code 1
5. Pipeline **FAILS** with clear error message
6. `CONFLICT_DETECTED` variable set to `true`

**Validation**:

```bash
# Check pipeline logs for error
# Look for:
# "##vso[task.logissue type=error]Merge conflict detected"
# "Manual resolution required"
```

**Resolution**: Follow [Manual Resolution Workflow](#manual-resolution-workflow)

---

### Scenario 4: Already Synchronized (Skip)

**Test Setup**:

```bash
# Both branches identical
dev:  A-B-C-D-E-F-G
main: A-B-C-D-E-F-G
```

**Expected Behavior**:

1. Pipeline compares SHAs → **match**
2. Strategy selected: **SKIP**
3. Action: No git operations
4. Result: Pipeline completes quickly with "already current" message

**Validation**:

```bash
# Check pipeline logs for:
# "✓ Dev is already up-to-date with main"
# "Sync Executed: false"
```

---

## Monitoring and Alerts

### Pipeline Output Variables

| Variable             | Values                    | Description                         |
| `SYNC_STRATEGY` | `FORCE_PUSH`, `MERGE`, `''` | Strategy selected by decision logic |
| `SYNC_EXECUTED` | `true`, `false` | Whether sync was performed |
| `COMMITS_INTEGRATED` | Number | Count of commits synced |
| `CONFLICT_DETECTED` | `true`, `false` | Whether merge conflict occurred |

### Success Indicators

**Force-Push Success**:

```text
Strategy Used:      FORCE_PUSH
Sync Executed:      true
Commits Integrated: 0
Conflict Detected:  false
```

**Merge Success**:

```text
Strategy Used:      MERGE
Sync Executed:      true
Commits Integrated: 3
Conflict Detected:  false
```

**Skip (Already Current)**:

```text
Strategy Used:
Sync Executed:      false
Commits Integrated: 0
Conflict Detected:  false
```

### Failure Indicators

**Merge Conflict**:

```text
Strategy Used:      MERGE
Sync Executed:      false
Commits Integrated: 0
Conflict Detected:  true
```

⚠️ **Action Required**: Follow manual resolution workflow

**Verification Failed**:

```text
##vso[task.logissue type=error]Force-push verification failed (SHAs do not match)
```

⚠️ **Action Required**: Check network issues, retry pipeline

---

## Troubleshooting

See [Common Troubleshooting](../pipelines/README.md#common-troubleshooting) for authentication and Key Vault issues.

### Force-Push Failed

* Check Build Service has **Force push** permission on `dev` branch (Settings → Repositories → Security)
* Retry pipeline run

### Merge Conflict Detected

* Requires manual resolution workflow (see below)
* Same file modified in both main and dev with conflicting changes

### Wrong Strategy Selected

* Diagnose: `git log origin/main..origin/dev --oneline` (empty=force-push, non-empty=merge)
* If commits lost: Check `git reflog` for recovery

---

## Related Documentation

* **[Branch Strategy Overview](../branch-strategy.md)**: Dual-branch architecture and workflows
* **[Release Workflow](../release-workflow.md)**: Complete release process documentation
* **[GitHub Pull Pipeline](./github-pull.yml.md)**: GitHub→AzDO main sync pipeline
* **[ADR-006: Release Automation](../../project-adrs/Accepted/006-adr-release-automation.md)**: Architecture decisions

---

## Pipeline Source

**Location**: `.azuredevops/pipelines/main-to-dev-sync.yml`

**Repository**: `microsoft/edge-ai`

**Maintained By**: Build & Release Engineering Team

---

## Support and Feedback

For questions, issues, or suggestions:

* **Internal**: Post in the Edge AI DevOps Teams channel
* **Issues**: Create an issue in the [GitHub repository](https://github.com/microsoft/edge-ai/issues)
* **Documentation**: Suggest improvements via pull request to this documentation
