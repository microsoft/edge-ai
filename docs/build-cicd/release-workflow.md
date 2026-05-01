---
title: Release Workflow - Dual-Branch Architecture
description: Comprehensive guide for the dual-branch release workflow between Azure DevOps and GitHub, including branch architecture, release process, and team guidelines
author: Edge AI Team
ms.date: 2025-11-12
ms.topic: concept
keywords:
  - release
  - workflow
  - dual-branch
  - azure devops
  - github
  - automation
  - synchronization
estimated_reading_time: 10
---

## Release Workflow - Dual-Branch Architecture

This guide documents the dual-branch release workflow for the Edge AI Accelerator project, establishing clear processes for development, release creation, and synchronization between Azure DevOps and GitHub.

## In this guide

- [Architecture overview](#architecture-overview)
- [Branch structure](#branch-structure)
- [Development workflow](#development-workflow)
- [Release workflow](#release-workflow)
- [Synchronization process](#synchronization-process)
- [Team guidelines](#team-guidelines)
- [Troubleshooting](#troubleshooting)

## Architecture overview

### Dual-branch model

The project uses a dual-branch architecture to separate development work from production-ready releases:

```text
┌─────────────────────────────────────────────────────────────┐
│                    Azure DevOps Repository                  │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌────────────────────────────────────────────────┐        │
│  │  dev branch (Development Branch)               │        │
│  │  • Primary development branch                  │        │
│  │  • All feature PRs target dev                  │        │
│  │  • Source for release branch creation          │        │
│  │  • Default branch for new PRs                  │        │
│  └────────────────────────────────────────────────┘        │
│                         │                                   │
│                         │ Release branch creation           │
│                         ▼                                   │
│  ┌────────────────────────────────────────────────┐        │
│  │  release/x.y.z (Release Staging Branch)        │        │
│  │  • Created from dev branch                     │        │
│  │  • Pushed to GitHub for review                 │        │
│  │  • One active release at a time                │        │
│  └────────────────────────────────────────────────┘        │
│                                                             │
│  ┌────────────────────────────────────────────────┐        │
│  │  main branch (Read-Only GitHub Mirror)         │        │
│  │  • Synced from GitHub main (manual pipeline)   │        │
│  │  • Protected - no direct commits               │        │
│  │  • Merged back to dev after sync               │        │
│  └────────────────────────────────────────────────┘        │
│                         ▲                                   │
└─────────────────────────┼───────────────────────────────────┘
                          │ Manual sync (github-pull pipeline)
                          │
┌─────────────────────────┼───────────────────────────────────┐
│                    GitHub Repository                        │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌────────────────────────────────────────────────┐        │
│  │  release-please--branches--main (PR Branch)    │        │
│  │  • Maintained by release-please action         │        │
│  │  • Aggregates conventional commits from main   │        │
│  │  • Opens/updates Release PR targeting main     │        │
│  └────────────────────────────────────────────────┘        │
│                         │                                   │
│                         │ PR with 2+ approvals              │
│                         ▼                                   │
│  ┌────────────────────────────────────────────────┐        │
│  │  main branch (Source of Truth)                 │        │
│  │  • Protected - requires 2+ approvals           │        │
│  │  • Accepts release PRs from release-please     │        │
│  │  • Accepts community PRs from forks            │        │
│  │  • Synced to AzDO main manually (github-pull)  │        │
│  └────────────────────────────────────────────────┘        │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Key principles

- **Development happens on AzDO dev branch**: All feature work, bug fixes, and improvements target the `dev` branch
- **GitHub main is source of truth**: Production-ready code lives on GitHub `main`, synced to AzDO `main`
- **Release branches bridge the gap**: Release branches move code from AzDO dev → GitHub main with review
- **Manual synchronization**: GitHub main is synced to AzDO main on demand via the `github-pull` pipeline; AzDO dev is pushed to GitHub via the `github-push` pipeline
- **One active release**: Only one release branch can be active at a time to prevent conflicts

## Branch structure

### AzDO dev branch (Development)

**Purpose**: Primary development branch for all feature work

**Characteristics**:

- Default branch for new pull requests
- Receives all feature branches, bug fixes, improvements
- Source branch for release creation
- Protected with PR requirements (reviewers, build validation)

**Access pattern**:

```bash
# Clone repository
git clone https://dev.azure.com/ai-at-the-edge-flagship-accelerator/edge-ai/_git/edge-ai
cd edge-ai

# Create feature branch from dev
git checkout dev
git pull origin dev
git checkout -b feature/my-feature

# Submit PR targeting dev branch
```

### AzDO main branch (Read-Only Mirror)

**Purpose**: Read-only mirror of GitHub main branch

**Characteristics**:

- Synced from GitHub main on demand via the `github-pull` Azure DevOps pipeline (manual trigger)
- Protected - no direct commits allowed
- Build Service has bypass permissions for the sync pipeline
- Merged back to dev after successful sync

**Access pattern**:

```bash
# View current state of production code
git checkout main
git pull origin main

# DO NOT create branches from main
# DO NOT commit directly to main
```

### Release branches (Staging)

**Purpose**: Stage releases for GitHub review and publication

**Characteristics**:

- Created from AzDO dev branch using automated pipeline
- Naming pattern: `release/x.y.z` (semantic versioning)
- Pushed to GitHub automatically
- Opens PR to GitHub main automatically
- One active release at a time

**Access pattern**:

```bash
# Release branches created via pipeline only
# Manual creation not recommended
```

### GitHub main branch (Source of Truth)

**Purpose**: Production-ready source of truth

**Characteristics**:

- Protected with branch policies (2+ approvals required)
- Accepts release PRs from `release/x.y.z` branches
- Accepts community contributions from forked repositories
- Creates GitHub releases with tags and changelogs via release-please
- Synced to AzDO main on demand via the `github-pull` pipeline

## Development workflow

### Feature development

**Standard development process for team members**:

1. **Create feature branch from dev**:

   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b feature/descriptive-name
   ```

2. **Develop and commit changes**:

   ```bash
   git add .
   git commit -m "feat: descriptive commit message"
   git push origin feature/descriptive-name
   ```

3. **Create pull request**:
   - Navigate to Azure DevOps → Repos → Pull Requests
   - Click "New Pull Request"
   - Source: `feature/descriptive-name`
   - Target: `dev` (automatically set via `.azuredevops/pull_request_targets.yml`)
   - Add reviewers and work item links
   - Submit for review

4. **Address review feedback**:

   ```bash
   # Make requested changes
   git add .
   git commit -m "fix: address review comments"
   git push origin feature/descriptive-name
   ```

5. **Merge after approval**:
   - Reviewer approves PR
   - Build validation passes
   - Merge to dev (squash merge recommended)
   - Delete feature branch after merge

### Bug fixes

**Process for bug fixes follows the same pattern as features**:

```bash
git checkout dev
git pull origin dev
git checkout -b fix/issue-description
# Make fixes
git commit -m "fix: resolve issue with component"
git push origin fix/issue-description
# Create PR to dev
```

### Hotfixes

**Critical fixes that need immediate release**:

1. **Create hotfix branch from current release or main**:

   ```bash
   git checkout main
   git pull origin main
   git checkout -b hotfix/x.y.z
   ```

2. **Apply fix and test**:

   ```bash
   git add .
   git commit -m "fix: critical security issue"
   git push origin hotfix/x.y.z
   ```

3. **Create PR to GitHub main directly**:
   - Open PR on GitHub (not AzDO)
   - Get expedited review and approval
   - Merge to main after approval

4. **Backport to dev**:

   ```bash
   # After hotfix merges to GitHub main
   git checkout dev
   git pull origin dev
   git cherry-pick <hotfix-commit-sha>
   git push origin dev
   ```

## Release workflow

### Creating a release

Releases are managed by [release-please](https://github.com/googleapis/release-please) on GitHub. There is no manual release-branch-create pipeline.

1. **Land changes on GitHub `main`**:
   - Conventional commits (`feat:`, `fix:`, `feat!:`, etc.) reach GitHub `main` via the `github-push` pipeline (ADO `dev` → GitHub `main` PR), which is itself triggered manually.
   - The `release-please.yml` workflow is **manual-only** (`workflow_dispatch`); it does not auto-run on pushes to `main`. This decouples release cuts from ADO→GitHub mirror activity.

2. **Open or refresh the release PR**:
   - From GitHub Actions → **Release Please** → **Run workflow** (against `main`), invoke release-please when ready to propose the next release.
   - release-please opens (or refreshes) a single release PR against `main` containing the next version, updated `CHANGELOG.md`, and bumped manifest entries computed from conventional commits since the last tag.
   - Re-run the workflow any time you want the release PR refreshed with newly landed commits.

3. **Release review**:
   - Reviewers examine the release PR diff and changelog on GitHub.
   - Run any final validation needed before approval.
   - Requires the standard GitHub branch-protection approvals.

4. **Release publication**:
   - Merge the release PR into GitHub `main`.
   - Re-run the **Release Please** workflow once more so release-please tags the release commit and publishes the GitHub Release with the generated changelog.
   - Bring the release commit and tags back into AzDO by running the `github-pull` pipeline (see [Synchronization process](#synchronization-process)).

### Release versioning

**Semantic versioning scheme**:

- **Major release** (`x.0.0`): Breaking changes, major features
- **Minor release** (`x.y.0`): New features, backward-compatible
- **Patch release** (`x.y.z`): Bug fixes, security patches

**Version determination**:

- release-please analyzes conventional commits on `main`.
- Commit types drive the version bump (`feat:` → minor, `fix:` → patch, `!`/`BREAKING CHANGE:` → major).
- The next version, tag, and changelog entry are computed automatically and proposed in the release PR.

### Release checklist

**Before creating release**:

- [ ] All planned features merged to dev
- [ ] Build validation passes on dev
- [ ] Documentation updated
- [ ] Team notified of upcoming release

**During release review**:

- [ ] Changelog reviewed and accurate
- [ ] All tests passing
- [ ] Security scans complete
- [ ] Breaking changes documented
- [ ] Migration guide available (if needed)

**After release**:

- [ ] GitHub Release published
- [ ] Documentation site updated
- [ ] Team notified of release
- [ ] Monitor for issues

## Synchronization process

GitHub ↔ AzDO synchronization is **manual**. Both pipelines (`github-push.yml` and `github-pull.yml`) declare `trigger: none` and only run via `workflow_dispatch`.

### AzDO main → GitHub main (push)

Use the `github-push` pipeline to publish AzDO `main` changes out to GitHub.

1. **Trigger the pipeline manually**:
   - Navigate to Azure DevOps → Pipelines → github-push.
   - Click "Run pipeline" and select the `main` branch.

2. **Sync process**:

   ```bash
   # Pipeline force-pushes AzDO main to GitHub main
   git fetch azdo main
   git push github azdo/main:refs/heads/main --force
   ```

3. **Post-sync follow-up**:
   - Confirm GitHub `main` now matches AzDO `main`.
   - The scheduled `main-to-dev-sync` AzDO pipeline merges AzDO `main` into AzDO `dev` daily at 03:00 UTC; the `github-pull` pipeline also chains this sync after a force-update of AzDO `main`.
   - Note: this push step does **not** trigger a GitHub release — release-please is manual-only on the GitHub side.

### GitHub main → AzDO main (pull)

Use the `github-pull` pipeline to bring release-please tags and merges from GitHub back into AzDO `main`.

1. **Trigger the pipeline manually**:
   - Navigate to Azure DevOps → Pipelines → github-pull.
   - Click "Run pipeline" and select the `main` branch.

2. **Verify sync success**:
   - Confirm AzDO `main` matches the GitHub `main` commit SHA after the run.
   - If the SHAs disagree, re-run the pipeline or investigate divergent history before continuing release work.

## Team guidelines

### Pull request guidelines

**Creating pull requests**:

- Always target `dev` branch (automatically set)
- Link related work items
- Provide clear description
- Include testing evidence
- Update documentation if needed

**Reviewing pull requests**:

- Verify changes align with requirements
- Check for security implications
- Ensure tests are adequate
- Validate documentation updates
- Approve only when confident

### Branch protection rules

**AzDO dev branch**:

- Minimum 1 reviewer required
- Build validation must pass
- Comment resolution required
- Direct commits blocked

**AzDO main branch**:

- Minimum 1 reviewer required (automated sync bypasses)
- Direct commits blocked for all users
- Build Service has bypass permissions

**GitHub main branch**:

- Minimum 2 reviewers required
- Build validation must pass
- Direct commits blocked
- Only release PRs and community PRs accepted

### Commit message conventions

**Follow conventional commits**:

```text
<type>(<scope>): <subject>

<body>

<footer>
```

**Types**:

- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `chore`: Maintenance tasks
- `refactor`: Code refactoring
- `test`: Test additions/changes
- `ci`: CI/CD changes

**Examples**:

```text
feat(iot-ops): add MQTT broker configuration
fix(terraform): resolve Azure provider version conflict
docs(release): document dual-branch workflow
chore(deps): update terraform providers to latest
```

### Merge strategies

**Feature branches to dev**:

- **Squash merge** (recommended): Combines all commits into one clean commit
- **Merge commit**: Preserves all individual commits (use when commit history is valuable)

**Release branches to main**:

- **Merge commit** (required): Preserves complete release history

**Main to dev**:

- **Merge commit** (required): Maintains synchronization history

## Troubleshooting

### Common Issues and Solutions

---

#### Issue 1: Release Workflow Fails to Create PR

**Symptoms**:

- Workflow completes but no PR created
- Error: "Failed to create pull request"
- PR creation step shows failure

**Possible Causes**:

1. Insufficient permissions for automation
2. Branch protection prevents PR creation
3. Release branch already exists
4. Invalid version format

**Solutions**:

**Check Permissions**:

```bash
# GitHub: Verify github-actions bot has write access
# Settings → Actions → General → Workflow permissions
# Ensure "Read and write permissions" selected

# Azure DevOps: Verify build service permissions
# Project Settings → Repositories → Security
# Grant "Contribute", "Create Branch", "Create Tag"
```

**Delete Existing Release Branch**:

```bash
git fetch origin
git branch -r | grep release/v1.2.3
git push origin --delete release/v1.2.3
```

**Verify Version Format**:

- Must be semantic version: MAJOR.MINOR.PATCH
- Examples: 1.2.3, 2.0.0, 0.1.0
- Pre-release: 1.2.3-rc1, 1.2.3-beta1

**Re-run Workflow**:

```bash
gh workflow run release-please.yml --ref main
```

release-please auto-detects the next version from conventional commits since the last tag — no version input is required.

---

#### Issue 2: Dev/Main Synchronization Fails

**Symptoms**:

- Sync workflow fails with error
- `dev` branch not updated after release
- Error: "dev has unreleased commits"

**Possible Causes**:

1. Dev has commits not in release
2. Force-push permissions not configured
3. Branch protection prevents sync
4. Network or timeout issues

**Solutions**:

**Check for Unreleased Commits**:

```bash
git fetch origin main dev
git log origin/main..origin/dev --oneline
```

If commits exist:

- These commits were not included in the release
- Create new release including these commits, OR
- Cherry-pick commits to main, OR
- Discard commits (if safe to do so)

**Manual Sync (if commits resolved)**:

Trigger the `main-to-dev-sync.yml` workflow (scheduled daily at 03:00 UTC, also runnable on demand):

```bash
gh workflow run main-to-dev-sync.yml --ref main
```

**Verify Automation Permissions**:

```bash
# GitHub: Check Actions bot can force-push to dev
# Settings → Branches → dev → Edit
# Allow force pushes → Specify: github-actions[bot]

# Azure DevOps: Check build service bypass policies
# Project Settings → Repositories → dev → Bypass policies
# Add build service account
```

**Check Workflow Logs**:

```bash
gh run list --workflow=main-to-dev-sync.yml
gh run view <run-id> --log
```

---

#### Issue 3: Release Notes Generation Fails or Incomplete

**Symptoms**:

- Release notes empty or missing
- AI generation errors
- Incomplete commit history

**Possible Causes**:

1. No commits since last release
2. Git history unavailable
3. API rate limits
4. Incorrect tag references

**Solutions**:

**Verify Commits Exist**:

```bash
git fetch origin --tags
LAST_TAG=$(git describe --tags --abbrev=0 origin/dev)
git log $LAST_TAG..origin/dev --oneline
```

If no commits, release not needed.

**Check Git Fetch Depth**:

GitHub workflow:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 0  # Full history required
```

Azure DevOps pipeline:

```yaml
- checkout: self
  fetchDepth: 0
```

**Manually Generate Notes**:

```bash
# Get commits since last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# Generate notes manually using conventional commits
```

**Check API Rate Limits** (if using AI generation):

```bash
# GitHub
gh api rate_limit

# If rate limited, wait or use manual notes
```

---

#### Issue 4: Breaking Change Detection Not Working

**Symptoms**:

- Breaking changes in code not reflected in release notes
- Version bump doesn't include major version increment
- No breaking change warning in PR

**Possible Causes**:

1. Commit messages missing `!` suffix
2. Detection script not running
3. Conventional commits not enforced
4. Breaking change marker in wrong position

**Solutions**:

**Use Correct Commit Format**:

```bash
# Breaking change format
git commit -m "feat!: change API endpoint structure"

# Or with body
git commit -m "feat: change API

BREAKING CHANGE: API endpoint structure changed"
```

**Verify Detection in Workflow**:

```yaml
- name: Check for breaking changes
  run: |
    BREAKING=$(git log $LAST_TAG..HEAD --oneline | grep -E '^\w+!:' || true)
    if [ -n "$BREAKING" ]; then
      echo "breaking=true" >> $GITHUB_OUTPUT
    fi
```

**Manual Version Override**:

Release-please derives the next version from Conventional Commit footers. To force a specific version, add a `Release-As: <version>` footer to a commit on `main` (or amend the release-please manifest), then re-run the workflow:

```bash
# Re-run release-please after pushing a Release-As: 2.0.0 commit footer to main
gh workflow run release-please.yml --ref main
```

**Enforce Conventional Commits**:

- Add commit message linter (e.g., commitlint)
- Configure PR checks to validate commit messages
- Document commit conventions in CONTRIBUTING.md

---

#### Issue 5: Release Branch Not Deleted After Merge

**Symptoms**:

- Release branch (e.g., release/v1.2.3) still exists after merge
- Old release branches accumulating

**Possible Causes**:

1. Auto-delete not configured
2. Workflow step failed
3. Permissions insufficient

**Solutions**:

**Enable Auto-Delete in GitHub**:

```bash
# Settings → General → Pull Requests
# Check "Automatically delete head branches"
```

**Manual Delete**:

```bash
# Delete locally
git branch -d release/v1.2.3

# Delete remotely
git push origin --delete release/v1.2.3
```

**Configure Workflow Auto-Delete**:

```yaml
- name: Delete release branch
  if: success()
  run: |
    git push origin --delete release/${{ inputs.version }}
```

**Bulk Delete Old Branches**:

```bash
# List old release branches
git branch -r | grep 'release/'

# Delete multiple branches
git push origin --delete release/v1.0.0 release/v1.1.0
```

---

#### Issue 6: Merge Conflicts in Release PR

**Symptoms**:

- Release PR to main shows conflicts
- Unable to auto-merge release
- Conflicts in multiple files

**Possible Causes**:

1. Main and dev diverged (should not happen with force-push sync)
2. Manual commits to main
3. Hotfix not synced to dev
4. Sync workflow failed previously

**Solutions**:

**Check Branch Divergence**:

```bash
git fetch origin main dev
git log origin/main..origin/dev --oneline  # Commits in dev not in main
git log origin/dev..origin/main --oneline  # Commits in main not in dev (should be empty)
```

**Resolve Conflicts in Release Branch**:

```bash
# Checkout release branch
git checkout release/v1.2.3
git fetch origin main

# Merge main into release branch
git merge origin/main

# Resolve conflicts
git status
# Edit conflicting files
git add .
git commit -m "Resolve merge conflicts"

# Push resolution
git push origin release/v1.2.3
```

**Prevent Future Conflicts**:

- Verify sync workflow runs after each release
- Never commit directly to main
- Ensure hotfixes follow proper workflow

---

#### Issue 7: Workflow Timeout or Performance Issues

**Symptoms**:

- Release workflow exceeds time limits
- Workflow cancelled after 6 hours
- Slow performance in CI checks

**Possible Causes**:

1. Large repository history
2. Expensive CI checks
3. Network issues
4. Resource constraints

**Solutions**:

**Optimize Git Checkout**:

```yaml
- uses: actions/checkout@v4
  with:
    fetch-depth: 50  # Shallow clone for better performance
```

**Increase Timeout**:

```yaml
jobs:
  create-release:
    timeout-minutes: 30  # Default is 360 (6 hours)
```

**Parallelize CI Checks**:

```yaml
jobs:
  lint:
    runs-on: ubuntu-latest
  test:
    runs-on: ubuntu-latest
  security:
    runs-on: ubuntu-latest
```

**Use Caching**:

```yaml
- uses: actions/cache@v4
  with:
    path: ~/.npm
    key: ${{ runner.os }}-node-${{ hashFiles('**/package-lock.json') }}
```

**Monitor Workflow Performance**:

```bash
# GitHub
gh run list --workflow=release-please.yml --limit 10

# Check individual job times
gh run view <run-id> --log
```

---

#### Issue 8: Version Tag Already Exists

**Symptoms**:

- Error: "tag already exists"
- Release creation fails at tagging step
- Previous release with same version

**Possible Causes**:

1. Previous failed release not cleaned up
2. Manual tag creation
3. Version not incremented

**Solutions**:

**Check Existing Tags**:

```bash
git fetch --tags
git tag -l 'v1.2.3'
```

**Delete Incorrect Tag**:

```bash
# Delete local tag
git tag -d v1.2.3

# Delete remote tag
git push origin :refs/tags/v1.2.3
```

**Increment Version**:

```bash
# Land a new conventional commit on main (e.g. fix:) and re-run release-please
gh workflow run release-please.yml --ref main
```

**Force Tag Update** (use with caution):

```bash
git tag -f v1.2.3 <commit-sha>
git push origin v1.2.3 --force
```

---

#### Issue 9: Permissions Errors in Workflows

**Symptoms**:

- Error: "Resource not accessible by integration"
- Error: "Permission denied"
- Workflow step fails with 403

**Possible Causes**:

1. Insufficient workflow permissions
2. GITHUB_TOKEN has limited scope
3. Branch protection prevents automation
4. Repository settings restrict workflows

**Solutions**:

**Check Workflow Permissions**:

GitHub:

```yaml
permissions:
  contents: write      # For creating releases, tags
  pull-requests: write # For creating PRs
  issues: write        # For issue comments
```

**Update Repository Settings**:

```bash
# Settings → Actions → General → Workflow permissions
# Select "Read and write permissions"
# Check "Allow GitHub Actions to create and approve pull requests"
```

**Configure Branch Protection Bypass**:

```bash
# Settings → Branches → main/dev → Edit
# Allow specified actors to bypass required pull requests
# Add: github-actions[bot]
```

**Use Personal Access Token** (if needed):

```yaml
- name: Create PR
  env:
    GITHUB_TOKEN: ${{ secrets.PERSONAL_ACCESS_TOKEN }}
  run: gh pr create --base main --head release/v1.2.3
```

**Azure DevOps Permissions**:

```bash
# Project Settings → Repositories → Security
# Grant build service:
# - Contribute
# - Create Branch
# - Create Tag
# - Bypass policies (for automation)
```

---

### Diagnostic Commands

**Health Check Script**:

```bash
#!/bin/bash
# Release automation health check

echo "🔍 Checking release automation health..."

# Check branches exist
echo "📋 Checking branches..."
git fetch origin
git branch -r | grep -E 'origin/(main|dev)' || echo "❌ Missing branches"

# Check branch sync
echo "📊 Checking branch sync..."
git fetch origin main dev
MAIN_SHA=$(git rev-parse origin/main)
DEV_SHA=$(git rev-parse origin/dev)
if [ "$MAIN_SHA" == "$DEV_SHA" ]; then
  echo "✅ Branches in sync"
else
  echo "⚠️  Branches out of sync"
  echo "Main: $MAIN_SHA"
  echo "Dev:  $DEV_SHA"
  UNRELEASED=$(git log origin/main..origin/dev --oneline)
  echo "Unreleased commits:"
  echo "$UNRELEASED"
fi

# Check active release PRs
echo "🔄 Checking active release PRs..."
ACTIVE_PRS=$(gh pr list --base main --label release --state open --json number,title)
if [ "$ACTIVE_PRS" == "[]" ]; then
  echo "✅ No active release PRs"
else
  echo "⚠️  Active release PRs found:"
  echo "$ACTIVE_PRS" | jq -r '.[] | "  #\(.number): \(.title)"'
fi

# Check latest tag
echo "🏷️  Checking latest tag..."
LATEST_TAG=$(git describe --tags --abbrev=0 origin/main 2>/dev/null || echo "none")
echo "Latest tag: $LATEST_TAG"

# Check workflow status
echo "⚙️  Checking workflow status..."
RECENT_RUNS=$(gh run list --workflow=release-please.yml --limit 5 --json conclusion,status)
echo "$RECENT_RUNS" | jq -r '.[] | "  \(.status): \(.conclusion // "running")"'

# Check permissions
echo "🔒 Checking permissions..."
gh api repos/:owner/:repo/actions/permissions | jq '.default_workflow_permissions'

echo "✨ Health check complete"
```

**Run Health Check**:

```bash
# Save script as scripts/release-health-check.sh
chmod +x scripts/release-health-check.sh
./scripts/release-health-check.sh
```

---

### Emergency Procedures

**Manual Release Process** (when automation fails):

1. **Create Release Branch**:

   ```bash
   git checkout dev
   git pull origin dev
   git checkout -b release/v1.2.3
   ```

2. **Update Version**:

   ```bash
   # Update version in relevant files (package.json, etc.)
   git commit -am "chore: bump version to 1.2.3"
   ```

3. **Generate Release Notes**:

   ```bash
   # Get commits since last release
   git log $(git describe --tags --abbrev=0)..HEAD --oneline > release-notes.md
   # Edit and format manually
   ```

4. **Create PR to Main**:

   ```bash
   git push origin release/v1.2.3
   gh pr create --base main --head release/v1.2.3 \
     --title "Release v1.2.3" \
     --body-file release-notes.md
   ```

5. **Merge and Tag**:

   ```bash
   # After PR approval
   gh pr merge <pr-number> --merge
   git checkout main
   git pull origin main
   git tag v1.2.3
   git push origin v1.2.3
   ```

6. **Create Release**:

   ```bash
   gh release create v1.2.3 \
     --title "v1.2.3" \
     --notes-file release-notes.md
   ```

7. **Sync Dev Branch**:

   ```bash
   git push origin main:dev --force
   ```

---

### Getting Help

**Internal Support**:

- Post in team Slack/Teams channel
- Contact DevOps team
- Review [Build & CI/CD documentation](./README.md)
- Check workflow run logs for detailed errors
- Review [Branch Strategy documentation](./branch-strategy.md)

**External Support**:

- Review [Contributing Guidelines](../contributing/README.md)
- Open discussion on GitHub Discussions
- Submit issue for bugs or feature requests
- Consult GitHub Actions documentation
- Consult Azure DevOps documentation

**Escalation Path**:

1. Check troubleshooting guide (this section)
2. Review workflow logs and error messages
3. Run health check script
4. Contact team DevOps lead
5. Open GitHub issue with full context

## Related documentation

- [Azure DevOps Guide](./azure-devops.md) - Pipeline configuration and usage
- [GitHub Actions Guide](./github-actions.md) - Workflow configuration and usage
- [Contributing Guidelines](../contributing/README.md) - Code contribution standards
- [Build & CI/CD Overview](./README.md) - Complete build documentation

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
