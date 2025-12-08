---
title: Release Validation Template
description: Comprehensive guide to release validation template for Azure DevOps pipelines including version validation, changelog verification, and release readiness assessment
author: Edge AI Team
ms.date: 2025-11-17
ms.topic: reference
keywords:
  - release
  - validation
  - version
  - changelog
  - semantic-versioning
  - quality-gates
  - readiness
  - dependencies
estimated_reading_time: 15
---

## Overview

The Release Validation template (`release-validation.yml`) provides comprehensive release quality gates for Azure DevOps pipelines. It validates semantic versioning, changelog completeness, dependency integrity, and overall release readiness with configurable strictness levels.

## When to Use

Use this template when you need:

- Pre-release validation and quality gates
- Semantic version format and increment verification
- Changelog completeness checking
- Release readiness assessment with scoring
- Dependency version compatibility validation
- Automated release compliance checks

## Template Location

```plaintext
.azuredevops/templates/release-validation.yml
```

## Operations

The template supports four validation operations:

### validate-version

Validates semantic version format and increment rules.

**Required Parameters**: `releaseVersion`

**Optional Parameters**: `previousVersion`, `validateIncrement`, `allowPrerelease`

**Use Cases**:

- Version format compliance checking
- Semantic versioning increment validation
- Pre-release version control

### validate-changelog

Verifies changelog format, completeness, and version entries.

**Required Parameters**: `releaseVersion`

**Optional Parameters**: `changelogPath`, `strictValidation`

**Use Cases**:

- Changelog entry verification
- Version documentation validation
- Release notes compliance

### validate-readiness

Comprehensive release readiness assessment with scoring.

**Required Parameters**: `releaseVersion`

**Optional Parameters**: `previousVersion`, `changelogPath`, `releaseNotesPath`, `requireNotes`, `strictValidation`

**Use Cases**:

- Complete release quality gate
- Multi-factor readiness scoring
- Go/no-go decision automation

### validate-dependencies

Checks dependency file format and version consistency.

**Optional Parameters**: `dependencyFiles`, `strictValidation`

**Use Cases**:

- Dependency file integrity validation
- Version pinning verification
- Multi-language dependency checking

## Parameters

| Parameter           | Type    | Default        | Description                                                                                                   |
|---------------------|---------|----------------|---------------------------------------------------------------------------------------------------------------|
| `operation`         | string  | *(required)*   | Validation operation: `validate-version`, `validate-changelog`, `validate-readiness`, `validate-dependencies` |
| `releaseVersion`    | string  | `''`           | Version string to validate (e.g., "1.2.3")                                                                    |
| `previousVersion`   | string  | `''`           | Previous version for increment validation                                                                     |
| `changelogPath`     | string  | `CHANGELOG.md` | Path to changelog file                                                                                        |
| `validateIncrement` | boolean | `true`         | Validate version increment rules                                                                              |
| `allowPrerelease`   | boolean | `false`        | Allow pre-release versions                                                                                    |
| `requireNotes`      | boolean | `true`         | Require release notes for readiness validation                                                                |
| `dependencyFiles`   | object  | `[]`           | Array of dependency files to validate                                                                         |
| `releaseNotesPath`  | string  | `''`           | Path to release notes file                                                                                    |
| `strictValidation`  | boolean | `false`        | Enable strict validation mode                                                                                 |
| `customRules`       | object  | `[]`           | Array of custom validation rules (reserved for future use)                                                    |

## Version Types

The template recognizes four version increment types based on semantic versioning:

### major

Breaking changes, incompatible API modifications.

**Example**: `1.5.3` → `2.0.0`

**Validation**:

- Major version increases
- Minor and patch reset to 0
- Previous version exists for comparison

### minor

Backward-compatible functionality additions.

**Example**: `1.5.3` → `1.6.0`

**Validation**:

- Minor version increases, major unchanged
- Patch resets to 0
- No breaking changes indicated

### patch

Backward-compatible bug fixes.

**Example**: `1.5.3` → `1.5.4`

**Validation**:

- Patch version increases only
- Major and minor unchanged
- Bug fixes or minor updates

### prerelease

Pre-release versions with identifiers.

**Example**: `1.6.0-alpha.1`, `2.0.0-rc.2`

**Validation**:

- Contains prerelease identifier
- Follows semantic versioning prerelease format
- Requires `allowPrerelease: true`

## Validation Rules

### Semantic Version Format

**Pattern**: `MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]`

**Valid Examples**:

- `1.0.0`
- `2.5.3`
- `1.0.0-alpha.1`
- `1.0.0-beta.2+build.123`

**Invalid Examples**:

- `1.0` (missing patch)
- `v1.0.0` (prefix not allowed)
- `1.0.0.0` (fourth version number)
- `release-1.0.0` (contains prefix)

### Version Increment Rules

When `validateIncrement: true`:

**Rule 1**: Never decrement versions

- ❌ `2.0.0` → `1.9.9`
- ✅ `1.9.9` → `2.0.0`

**Rule 2**: Increment only one component

- ❌ `1.5.3` → `2.5.3`
- ✅ `1.5.3` → `2.0.0`

**Rule 3**: Reset lower components on increment

- ❌ `1.5.3` → `1.6.3`
- ✅ `1.5.3` → `1.6.0`

**Rule 4**: Sequential increments preferred

- ⚠ `1.0.0` → `3.0.0` (warning: skipped versions)
- ✅ `1.0.0` → `2.0.0`

### Changelog Validation Rules

**Standard Format**:

```markdown
# Changelog

## [Unreleased]
### Added
- New features in development

## [1.2.3] - 2025-11-17
### Added
- Feature 1
- Feature 2

### Changed
- Change 1

### Fixed
- Bug fix 1
```

**Validation Checks**:

- Changelog file exists at specified path
- Version entry exists (e.g., `## [1.2.3]`)
- Version section has meaningful content (>50 characters)
- Contains standard sections (Added, Changed, Fixed, Removed) when `strictValidation: true`
- Includes [Unreleased] section for ongoing work

### Readiness Scoring

Comprehensive readiness assessment scores components out of 100:

| Component            | Points | Requirement                                          |
|----------------------|--------|------------------------------------------------------|
| Version validation   | 30     | Valid semantic version format and increments         |
| Changelog validation | 30     | Version entry exists with meaningful content         |
| Release notes        | 20     | Release notes file exists with content (if required) |
| Git status           | 10     | Working directory clean (no uncommitted changes)     |
| Branch validation    | 10     | On `dev` or `release/*` branch                       |

**Scoring Thresholds**:

- **≥80 points**: Release ready to proceed
- **60-79 points**: Release may proceed with caution
- **<60 points**: Release not ready, address critical issues

### Dependency Validation

Validates dependency files by format:

**package.json** (Node.js):

- Valid JSON format
- Dependency and devDependency counts
- No problematic patterns when `strictValidation: true`

**requirements.txt** (Python):

- Readable file format
- Version pinning warnings when `strictValidation: true`

**Cargo.toml** (Rust):

- Valid TOML format
- Dependencies section exists
- Module declaration present

**go.mod** (Go):

- Module declaration exists
- Valid format structure

## Output Variables

| Variable             | Type    | Description                                                         |
|----------------------|---------|---------------------------------------------------------------------|
| `isValid`            | boolean | Whether validation passed (`true`/`false`)                          |
| `validationErrors`   | string  | Semicolon-separated validation error messages                       |
| `validationWarnings` | string  | Semicolon-separated validation warning messages                     |
| `versionType`        | string  | Type of version: `major`, `minor`, `patch`, `prerelease`, `unknown` |
| `changelogValid`     | boolean | Whether changelog validation passed                                 |
| `dependenciesValid`  | boolean | Whether dependency validation passed                                |
| `readinessScore`     | number  | Overall readiness score (0-100, for `validate-readiness` operation) |

## Usage Examples

### Basic Version Validation

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-version'
    releaseVersion: '1.2.3'
```

### Version Increment Validation

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-version'
    releaseVersion: '$(RELEASE_VERSION)'
    previousVersion: '$(PREVIOUS_VERSION)'
    validateIncrement: true
```

### Allow Pre-release Versions

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-version'
    releaseVersion: '2.0.0-rc.1'
    allowPrerelease: true
```

### Changelog Validation

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-changelog'
    releaseVersion: '1.2.3'
    changelogPath: 'CHANGELOG.md'
```

### Strict Changelog Validation

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-changelog'
    releaseVersion: '1.2.3'
    strictValidation: true
```

### Comprehensive Readiness Check

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-readiness'
    releaseVersion: '$(RELEASE_VERSION)'
    previousVersion: '$(PREVIOUS_VERSION)'
    changelogPath: 'CHANGELOG.md'
    releaseNotesPath: 'docs/releases/v1.2.3.md'
    requireNotes: true
    strictValidation: true
```

### Dependency Validation (Default Files)

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-dependencies'
```

### Dependency Validation (Custom Files)

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-dependencies'
    dependencyFiles:
      - 'package.json'
      - 'requirements.txt'
      - 'Cargo.toml'
    strictValidation: true
```

### Complete Release Pipeline

```yaml
trigger:
  branches:
    include:
      - release/*

variables:
  RELEASE_VERSION: $(Build.SourceBranchName.Replace('release/', ''))

steps:
# Step 1: Validate version format
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-version'
    releaseVersion: '$(RELEASE_VERSION)'
    previousVersion: '$(git describe --tags --abbrev=0)'
    validateIncrement: true
    allowPrerelease: false

# Step 2: Validate changelog
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-changelog'
    releaseVersion: '$(RELEASE_VERSION)'
    strictValidation: true

# Step 3: Validate dependencies
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-dependencies'
    strictValidation: true

# Step 4: Comprehensive readiness check
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-readiness'
    releaseVersion: '$(RELEASE_VERSION)'
    previousVersion: '$(git describe --tags --abbrev=0)'
    requireNotes: true
    strictValidation: true

# Step 5: Check readiness score
- pwsh: |
    $score = $(validateReadiness.readinessScore)
    if ($score -lt 80) {
      Write-Error "Release readiness score ($score) below threshold (80)"
      exit 1
    }
    Write-Host "✅ Release ready with score: $score/100"
```

## Integration Patterns

### Pre-Release Quality Gate

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-readiness'
    releaseVersion: '$(RELEASE_VERSION)'
    previousVersion: '$(PREVIOUS_VERSION)'
    strictValidation: true

- pwsh: |
    if ("$(validateReadiness.isValid)" -ne "true") {
      Write-Error "Release validation failed - cannot proceed"
      exit 1
    }
```

### Version-Only Validation

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-version'
    releaseVersion: '$(Build.SourceBranchName.Replace("release/", ""))'
    validateIncrement: true
```

### Multi-Stage Release Validation

```yaml
stages:
- stage: Validate
  jobs:
  - job: VersionCheck
    steps:
    - template: templates/release-validation.yml
      parameters:
        operation: 'validate-version'
        releaseVersion: '$(RELEASE_VERSION)'

  - job: ChangelogCheck
    steps:
    - template: templates/release-validation.yml
      parameters:
        operation: 'validate-changelog'
        releaseVersion: '$(RELEASE_VERSION)'

  - job: DependencyCheck
    steps:
    - template: templates/release-validation.yml
      parameters:
        operation: 'validate-dependencies'

- stage: Release
  dependsOn: Validate
  condition: succeeded()
  jobs:
  - job: CreateRelease
    steps:
    - pwsh: Write-Host "All validations passed - proceeding with release"
```

## Error Handling

### Common Validation Errors

#### Invalid Semantic Version Format

```text
Invalid semantic version format. Expected: MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]
```

**Resolution**:

- Verify version follows semantic versioning
- Remove prefixes like `v` or `version`
- Ensure three numeric components

#### Version Increment Violation

```text
Version does not represent a valid increment from 1.5.3
```

**Resolution**:

- Check version increment follows semver rules
- Verify major/minor/patch logic
- Review previous version accuracy

#### Changelog Entry Missing

```text
Version 1.2.3 not found in changelog
```

**Resolution**:

- Add version section to CHANGELOG.md
- Use format: `## [1.2.3] - YYYY-MM-DD`
- Include change descriptions

#### Release Notes Required

```text
Release notes required but not found or path not specified
```

**Resolution**:

- Create release notes file
- Specify `releaseNotesPath` parameter
- Or set `requireNotes: false`

### Output Variable Checking

Check validation results:

```yaml
- pwsh: |
    $isValid = "$(validateVersion.isValid)"
    $errors = "$(validateVersion.validationErrors)"
    $warnings = "$(validateVersion.validationWarnings)"

    if ($isValid -ne "true") {
      Write-Host "Validation Errors:"
      foreach ($error in ($errors -split ';')) {
        Write-Host "  ❌ $error"
      }
      exit 1
    }

    if ($warnings) {
      Write-Host "Validation Warnings:"
      foreach ($warning in ($warnings -split ';')) {
        Write-Host "  ⚠ $warning"
      }
    }
```

## Best Practices

### Use Strict Validation for Releases

Enable strict validation for production releases:

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-readiness'
    releaseVersion: '$(RELEASE_VERSION)'
    strictValidation: true
```

### Validate Early in Pipeline

Run validation as first stage to fail fast:

```yaml
stages:
- stage: Validate
  jobs:
  - job: ReleaseValidation
    steps:
    - template: templates/release-validation.yml
      parameters:
        operation: 'validate-readiness'
        releaseVersion: '$(RELEASE_VERSION)'

- stage: Build
  dependsOn: Validate
  condition: succeeded()
```

### Set Minimum Readiness Score

Enforce minimum score threshold:

```yaml
- template: templates/release-validation.yml
  parameters:
    operation: 'validate-readiness'
    releaseVersion: '$(RELEASE_VERSION)'

- pwsh: |
    $minScore = 80
    $actualScore = $(validateReadiness.readinessScore)
    if ($actualScore -lt $minScore) {
      throw "Score $actualScore below minimum $minScore"
    }
```

### Maintain Changelog Discipline

Keep changelog updated continuously:

```markdown
# Changelog

## [Unreleased]
### Added
- Feature being developed

### Fixed
- Bug fix merged today

## [1.2.3] - 2025-11-17
### Added
- Completed feature from previous sprint
```

### Use Previous Version from Git Tags

Automatically determine previous version:

```yaml
- pwsh: |
    $previousVersion = git describe --tags --abbrev=0
    Write-Host "##vso[task.setvariable variable=PREVIOUS_VERSION]$previousVersion"

- template: templates/release-validation.yml
  parameters:
    operation: 'validate-version'
    releaseVersion: '$(RELEASE_VERSION)'
    previousVersion: '$(PREVIOUS_VERSION)'
```

## Troubleshooting

### Issue: Version Format Rejected

**Symptom**: Valid-looking version fails format validation

**Solution**:

1. Remove any prefix characters (`v`, `version`)
2. Ensure exactly three numeric components
3. Verify prerelease format: `-alpha.1` not `_alpha_1`
4. Check for trailing spaces or special characters

### Issue: Changelog Not Found

**Symptom**: Validation fails even though CHANGELOG.md exists

**Solution**:

1. Verify file path relative to pipeline working directory
2. Check file name capitalization (CHANGELOG.md vs changelog.md)
3. Specify explicit path with `changelogPath` parameter
4. Ensure file is committed to repository

### Issue: Low Readiness Score

**Symptom**: Readiness validation scores below threshold

**Solution**:

1. Review individual component scores in logs
2. Address validation errors first (critical)
3. Clean git working directory
4. Ensure on appropriate branch (dev or release/*)
5. Create/update release notes if required

### Issue: Dependency Validation Fails

**Symptom**: Dependency validation reports errors

**Solution**:

1. Verify dependency file format (JSON, TOML, etc.)
2. Check for syntax errors in dependency files
3. Ensure dependency files are in expected locations
4. Review strict validation warnings

### Issue: Pre-release Version Blocked

**Symptom**: Pre-release version fails validation

**Solution**:

1. Set `allowPrerelease: true` parameter
2. Verify prerelease identifier format
3. Check if pre-release versions appropriate for context
4. Review version increment from previous version

## Related Documentation

- [GitHub Authentication](github-auth.md)
- [GitHub Branch Operations](github-branch-operations.md)
- [Pull Request Creation](pr-creation.md)
- [Git Sync Operations](git-sync-operations.md)
- [Authentication Guide](authentication.md)
- [Template Integration Guide](template-integration.md)

## References

- [Semantic Versioning Specification](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [Release Management Best Practices](https://docs.microsoft.com/azure/devops/pipelines/release/)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
