---
title: Release Draft Workflow
description: Semi-automated draft release creation process using GitHub Actions, providing quality control gates for maintainers before publishing releases
author: Edge AI Team
ms.date: 2025-11-15
ms.topic: how-to-guide
keywords:
  - release
  - github actions
  - draft release
  - automation
  - changelog
  - version
  - semi-automated
  - quality control
estimated_reading_time: 8
---

## Release Draft Workflow

When a release PR merges to `main`, GitHub Actions automatically creates a draft release with version detection, changelog parsing, and maintainer checklist. This provides a quality control gate before public release.

## Quick Reference

| Stage               | Action                                         | Automation | Manual Review    |
|---------------------|------------------------------------------------|------------|------------------|
| **Release PR**      | Create from AzDO dev                           | ✓ Auto     | ✓ Review & merge |
| **Draft Creation**  | Extract version, parse changelog, create draft | ✓ Auto     |                  |
| **Quality Control** | Verify notes, add highlights, attach assets    |            | ✓ Review         |
| **Publishing**      | Make release public                            |            | ✓ Publish        |

**Workflow**: Release PR merged → Draft created (auto) → Maintainer reviews → Publish (manual)

**Rationale**: Automation handles tedious tasks (version extraction, changelog parsing), humans provide quality control (review, enhancement, publish decision).

## Workflow Mechanics

**Trigger**: Release PR merged to `main` (source: `release/*` branch)

**Automation Steps**:

| Step            | Process                                       | Result                                               |
|-----------------|-----------------------------------------------|------------------------------------------------------|
| **Version**     | Extract from `release/X.Y.Z`                  | Supports stable (1.2.3) and pre-release (1.2.3-rc.1) |
| **Pre-release** | Detect `-rc`, `-alpha`, `-beta` suffix        | Sets GitHub pre-release flag                         |
| **Changelog**   | Parse `CHANGELOG.md` for `## [X.Y.Z]` section | Extracts release notes                               |
| **Draft**       | Create with tag `vX.Y.Z`, notes, checklist    | Includes changelog + auto-generated notes            |
| **Comment**     | Post draft link on merged PR                  | Notifies maintainers                                 |

**Version Formats**: `release/1.2.3` (stable), `release/1.2.3-rc.1` (RC), `release/2.0.0-alpha.1` (alpha)

**Changelog Format** (Keep a Changelog):

```markdown
## [1.2.3] - 2025-11-15
### Added
- Feature X
### Fixed
- Bug Y
```

Workflow location: `.github/workflows/release-draft-creation.yml`

## Maintainer Actions

### 1. Verify Draft Created

- Check merged PR for workflow comment with draft link
- Or run: `gh release list` (look for DRAFT status)

### 2. Review & Enhance

```markdown
Checklist:
[ ] Version/tag correct
[ ] Pre-release flag appropriate
[ ] Changelog accurate
[ ] Add highlights (optional)
[ ] Add migration guide (if breaking changes)
[ ] Note known issues
```

**3. Attach Assets** (if applicable)

```bash
gh release upload v1.2.3 build/edge-ai-linux-amd64.tar.gz
```

Common assets: binaries, installers, docs, config templates

### 4. Publish

```bash
# Stable release
gh release edit v1.2.3 --draft=false

# Pre-release
gh release edit v1.2.3 --draft=false --prerelease
```

Or via web: Releases → Edit → Publish release

## Configuration

**CHANGELOG.md Format** (Keep a Changelog):

```markdown
## [1.2.3] - 2025-11-15
### Added
- Feature X
### Changed
- Updated Y
### Fixed
- Bug Z
### Security
- CVE fix
```

**Versioning**: Semantic versioning (X.Y.Z) with optional pre-release suffixes (`-rc.1`, `-alpha.1`, `-beta.1`)

**Workflow**: `.github/workflows/release-draft-creation.yml` (requires `contents: write` and `pull-requests: write` permissions)

## Best Practices

**Changelog Maintenance**:

- Update `[Unreleased]` section as features merge
- Move to versioned section before release
- Include issue/PR references

**Pre-release Workflow**:

1. Create `release/1.2.0-rc.1` → draft with pre-release flag
2. Publish for testing, gather feedback
3. Create `release/1.2.0` → stable release

**Release Review Checklist**:

- [ ] Version follows semver, tag matches
- [ ] All changes documented, breaking changes highlighted
- [ ] Tests passing, security scans complete
- [ ] Assets attached (binaries, installers, docs)
- [ ] Team notified

**Asset Naming**: `[project]-[version]-[os]-[arch].[ext]` (e.g., `edge-ai-1.2.3-linux-amd64.tar.gz`)

## Troubleshooting

| Issue                          | Solution                                                                                                 |
|--------------------------------|----------------------------------------------------------------------------------------------------------|
| **Workflow didn't trigger**    | Verify PR merged (not closed), branch matches `release/*`, workflow file exists on main                  |
| **Version extraction failed**  | Check branch format: `release/X.Y.Z` or `release/X.Y.Z-rc.N` (no `v` prefix, must be semver)             |
| **Changelog parsing empty**    | Verify `CHANGELOG.md` exists, header format: `## [X.Y.Z] - YYYY-MM-DD` (with brackets)                   |
| **Permission error**           | Check workflow permissions: `contents: write`, `pull-requests: write` in Settings → Actions              |
| **PR comment missing**         | Verify `pull-requests: write` permission; manually comment if needed                                     |
| **Pre-release flag incorrect** | Suffixes `-rc`, `-alpha`, `-beta` auto-detected; manually fix with `gh release edit vX.Y.Z --prerelease` |
| **Draft not visible**          | Check if published accidentally with `gh release list`; only write access can see drafts                 |

### Debugging Commands

```bash
# Check workflow status
gh run list --workflow=release-draft-creation.yml --limit 10
gh run view [RUN_ID] --log

# Inspect drafts
gh release list
gh release view v1.2.3 --json isDraft,isPrerelease

# Test version extraction
BRANCH_NAME="release/1.2.3-rc.1"
[[ $BRANCH_NAME =~ release/([0-9]+\.[0-9]+\.[0-9]+(-[a-zA-Z0-9.]+)?) ]] && echo "Version: ${BASH_REMATCH[1]}"

# Test changelog parsing
VERSION="1.2.3"
awk "/^## \[$VERSION\]/,/^## \[/{if(/^## \[/ && !/^## \[$VERSION\]/)exit;print}" CHANGELOG.md
```

### Manual Draft Creation

When automation fails:

```bash
# Extract version, check for existing tag, parse changelog
gh pr view 123 --json headRefName
VERSION="${BRANCH_NAME#release/}"
awk "/^## \[$VERSION\]/,/^## \[/{if(/^## \[/ && !/^## \[$VERSION\]/)exit;print}" CHANGELOG.md > release-notes.md

# Create draft
gh release create "v$VERSION" --draft --title "v$VERSION" --notes-file release-notes.md --generate-notes

# Comment on PR
gh pr comment 123 --body "✅ Draft release created: [v$VERSION](https://github.com/microsoft/edge-ai/releases/tag/v$VERSION)"
```

## Related documentation

- [Release Workflow Overview](./release-workflow.md) - Complete dual-branch release process
- [GitHub Actions Guide](./github-actions.md) - Workflow configuration and best practices
- [Branch Strategy](./branch-strategy.md) - Branch protection and workflow policies
- [Troubleshooting Builds](./troubleshooting-builds.md) - Common build and CI issues
- [GitHub Releases Documentation](https://docs.github.com/en/repositories/releasing-projects-on-github) - Official GitHub release features

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
