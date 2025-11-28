---
title: Documentation Validation Template
description: Azure DevOps pipeline template for comprehensive documentation quality validation and consistency checks
author: Edge AI Team
ms.date: 2025-06-17
ms.topic: concept
estimated_reading_time: 8
keywords:
  - documentation validation
  - azure devops
  - pipeline template
  - sidebar validation
  - frontmatter validation
  - link validation
  - documentation quality
  - markdown validation
  - build automation
  - pull request validation
  - documentation consistency
  - three-tree architecture
---

This template provides comprehensive documentation validation for Azure DevOps pipelines,
ensuring documentation quality standards are maintained and navigation stays synchronized
with content changes across all tracked folders.

## Overview

The Documentation Validation Template addresses the critical challenge of maintaining
documentation quality and consistency in large repositories with multiple documentation
areas. It validates that sidebar navigation matches the current documentation structure,
ensures frontmatter consistency across different content types, and verifies that all
links remain functional. Unlike automated fixes, this template focuses on validation and
feedback, requiring developers to consciously address documentation issues to maintain
high standards.

## Features

- **Sidebar Validation**: Ensures three-tree navigation sidebar is current with latest documentation structure
- **Frontmatter Consistency**: Validates required fields and format across all content types
- **Link Validation**: Checks all documentation links for accessibility and correctness
- **Multi-Folder Support**: Validates content across docs, src, blueprints, learning, and .github folders
- **Learning Content Validation**: Specialized validation for learning platform content
- **GitHub Resources Validation**: Validates prompts, chatmodes, and issue templates
- **Configurable Severity**: Can produce warnings or fail builds based on requirements
- **Azure DevOps Integration**: Uses proper logging commands for build system integration

## Parameters

| Parameter          | Type    | Required | Default                                                         | Description                                                                         |
|--------------------|---------|----------|-----------------------------------------------------------------|-------------------------------------------------------------------------------------|
| `dependsOn`        | object  | No       | `[]`                                                            | Jobs this validation job depends on                                                 |
| `displayName`      | string  | No       | `'Documentation Validation'`                                    | Custom display name for the job                                                     |
| `condition`        | string  | No       | `'succeeded()'`                                                 | Condition to run this job                                                           |
| `breakBuild`       | boolean | No       | `false`                                                         | Whether to treat validation issues as errors (true) or warnings (false)             |
| `onlyChangedFiles` | boolean | No       | `false`                                                         | Whether to validate only files changed in the PR/commit (true) or all files (false) |
| `pool`             | object  | No       | `{ name: 'ai-on-edge-managed-pool', vmImage: 'ubuntu-latest' }` | Configuration for the agent pool                                                    |

## Outputs

This template doesn't produce formal pipeline outputs, but it generates build warnings or errors for each detected documentation issue, integrated with Azure DevOps logging.

## Dependencies

This template depends on the following:

- **Required Tools**:
  - PowerShell Core
  - Node.js 18+
  - markdown-link-check npm package
- **Required Scripts**:
  - `./scripts/Generate-DocsSidebar.ps1`: For sidebar generation and validation
  - `./scripts/Three-Tree-Enhancement.ps1`: For enhanced three-tree navigation
  - `./scripts/Validate-MarkdownFrontmatter.ps1`: For dedicated frontmatter validation
- **Required Project Structure**:
  - Three-tree documentation architecture (docs, src, blueprints folders)
  - Learning platform content (learning folder)
  - GitHub resources (.github folder with prompts, chatmodes, templates)

## Usage

### Basic Usage

```yaml
# Basic validation with warnings only
  - template: .azdo/templates/docs-validation-template.yml
```

### Advanced Usage

```yaml
# Strict validation for pull request gates
  - template: .azdo/templates/docs-validation-template.yml
    parameters:
      dependsOn: [MegaLinter, SecurityScan]
      displayName: "Strict Documentation Validation"
      condition: and(succeeded(), eq(variables['Build.Reason'], 'PullRequest'))
      breakBuild: true
      pool:
        name: "high-priority-pool"
        vmImage: "ubuntu-latest"
```

## Implementation Details

The template executes three main validation processes:

1. **Frontmatter Validation**:
   - Validates required fields in main documentation (title, description, author, ms.date, ms.topic)
   - Checks date format consistency (MM/DD/YYYY)
   - Validates keywords array format
   - Differentiates requirements between content types (stricter for docs/src/blueprints)

2. **Sidebar Validation**:
   - Generates temporary sidebar using Generate-DocsSidebar.ps1
   - Compares with existing sidebar (excluding timestamps)
   - Fails validation if sidebar is outdated
   - Provides clear instructions for manual regeneration

3. **Link Validation**:
   - Uses markdown-link-check to validate all documentation links
   - Covers all tracked folders (docs, src, blueprints, learning, .github)
   - Configurable timeout and retry settings
   - Ignores localhost and fragment-only links

### Key Components

- **Generate-DocsSidebar.ps1**: PowerShell script that manages three-tree navigation and provides frontmatter parsing
- **Three-Tree-Enhancement.ps1**: Enhanced navigation functions for sidebar generation
- **markdown-link-check**: Node.js tool for comprehensive link validation
- **Azure DevOps Logging**: Integration with `##vso[task.logissue type=error|warning]` for build system

### Validation Philosophy

This template follows a validation-only approach:

- **No Automatic Fixes**: Requires developers to consciously address issues
- **Clear Feedback**: Provides specific error messages with file paths and remediation steps
- **Configurable Severity**: Supports both warning and error modes based on pipeline requirements
- **Comprehensive Coverage**: Validates all aspects of documentation quality

## Performance Considerations

### Changed Files Validation

When `onlyChangedFiles` is set to `true`, the template optimizes performance by:

- **Git Diff Analysis**: Uses `git diff` to identify only markdown files that have changed in the PR/commit
- **Targeted Validation**: Validates only frontmatter and links in changed files
- **Fallback Handling**: Automatically falls back to full validation if git operations fail
- **Skip Empty Changes**: Automatically skips validation if no markdown files were changed

**Benefits**:

- Significantly faster validation for large repositories
- Reduced resource usage in CI/CD pipelines
- Maintains validation quality while improving efficiency

**Best Practices**:

- Use `onlyChangedFiles: true` for pull request validation
- Use `onlyChangedFiles: false` (default) for main branch builds
- Combine with `breakBuild: true` for strict PR gates

## Examples

### Example 1: Pull Request Gate

```yaml
# Use as a pull request gate with strict validation
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/docs-validation-template.yml
        parameters:
          displayName: "PR Documentation Gate"
          breakBuild: true
          condition: eq(variables['Build.Reason'], 'PullRequest')
```

### Example 2: CI Validation with Warnings

```yaml
# Use in CI with warnings to encourage good practices
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/docs-validation-template.yml
        parameters:
          displayName: "Documentation Quality Check"
          breakBuild: false
```

### Example 3: Changed Files Only (Performance Optimization)

```yaml
# Use for large repositories to validate only changed files in PRs
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/docs-validation-template.yml
        parameters:
          displayName: "Changed Files Documentation Validation"
          onlyChangedFiles: true
          breakBuild: true
          condition: eq(variables['Build.Reason'], 'PullRequest')
```

### Example 4: Integration with Other Validation

```yaml
# Integration with existing validation pipeline
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/megalinter-template.yml
        # MegaLinter parameters...

      - template: .azdo/templates/docs-validation-template.yml
        parameters:
          dependsOn: [MegaLinter]
          condition: succeeded('MegaLinter')
          displayName: "Documentation Validation"
```

## Troubleshooting

Common issues and their solutions:

1. **Sidebar Validation Failures**:
   - **Symptom**: Build fails with "Sidebar is outdated and needs regeneration"
   - **Solution**: Run `pwsh -File ./scripts/Generate-DocsSidebar.ps1` locally, commit changes, and push

2. **Frontmatter Validation Errors**:
   - **Symptom**: Build warns or fails with missing required fields
   - **Solution**: Add required frontmatter fields (title, description, author, ms.date, ms.topic) to markdown files

3. **Link Validation Failures**:
   - **Symptom**: Build warns or fails with broken links
   - **Solution**: Fix broken links or update link targets, ensure external links are accessible

4. **PowerShell Module Import Issues**:
   - **Symptom**: Build fails with module import errors
   - **Solution**: Ensure `scripts/Three-Tree-Enhancement.ps1` exists and has proper execution permissions

5. **Node.js Package Installation Issues**:
   - **Symptom**: Build fails during markdown-link-check installation
   - **Solution**: Verify agent has npm access and sufficient permissions to install global packages

## Related Templates

- MegaLinter Template: [YAML](/.azdo/templates/megalinter-template.yml) | [Documentation](./megalinter-template.md) - Provides comprehensive linting for various file types
- Wiki Update Template: [YAML](/.azdo/templates/wiki-update-template.yml) | [Documentation](./wiki-update-template.md) - Manages wiki synchronization and now includes health reporting
- Docs Check Bicep Template: [YAML](/.azdo/templates/docs-check-bicep-template.yml) | [Documentation](./docs-check-bicep-template.md) - Specialized template for Bicep documentation validation

## Learn More

- [Azure DevOps Pipeline Templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
- [Azure DevOps YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)
- [Markdown Link Check Documentation](https://github.com/tcort/markdown-link-check)
- [PowerShell Documentation](https://learn.microsoft.com/powershell/)
- [Documentation Quality Best Practices](https://docs.microsoft.com/style-guide/)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
