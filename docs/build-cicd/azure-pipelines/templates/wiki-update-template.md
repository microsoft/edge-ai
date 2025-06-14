---
title: Wiki Update Template
description: Azure DevOps pipeline template for automating synchronization of documentation from repository to wiki
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
estimated_reading_time: 7
keywords:
  - wiki synchronization
  - documentation automation
  - azure devops
  - pipeline template
  - documentation management
  - wiki update
  - repository sync
  - documentation publishing
  - automated documentation
  - wiki maintenance
---

This template automates the synchronization of documentation from the main code
repository to the Azure DevOps wiki, ensuring that documentation remains up-to-date and
accessible in a user-friendly format.

## Overview

The Wiki Update Template manages a critical but often overlooked aspect of project
maintenance: keeping project documentation synchronized between code and wiki
repositories. It solves the challenge of maintaining documentation in two places by
automatically processing markdown files from the code repository, formatting them for
wiki compatibility, and publishing them to the Azure DevOps wiki. This ensures that as
code and its documentation evolve, the same changes are reflected in the wiki that team
members reference for guidance.

## Features

- **Dual Repository Management**: Handles checkouts of both code and wiki repositories/branches in a single job
- **Automated Content Building**: Processes markdown documentation using a dedicated build script
- **Wiki Structure Preservation**: Maintains wiki navigation structure through `.order` files (Azure DevOps specific)
- **Selective Execution**: Only runs on successful builds of the main branch to ensure quality
- **Credential Persistence**: Properly configures Git credentials for authenticated operations
- **Customizable Paths**: Supports configurable folder names for both repositories
- **Automated Commit Process**: Handles the commit and push operations to update the wiki

## Parameters

| Parameter          | Type   | Required | Default                                   | Description                              |
|--------------------|--------|----------|-------------------------------------------|------------------------------------------|
| `dependsOn`        | object | No       | `[]`                                      | Jobs this wiki update job depends on     |
| `displayName`      | string | No       | `'Wiki Documentation Update'`             | Custom display name for the job          |
| `condition`        | string | No       | `succeeded()`                             | Condition to run this job                |
| `branchRepoFolder` | string | No       | `'branch'`                                | Folder name for the main branch checkout |
| `wikiRepoFolder`   | string | No       | `'wiki'`                                  | Folder name for the wiki branch checkout |
| `wikiRepo`         | string | No       | `'git://edge-ai/edge-ai@refs/heads/wiki'` | Wiki repository reference                |
| `wikiBranch`       | string | No       | `'wiki'`                                  | Wiki branch name                         |

## Outputs

This template doesn't produce formal pipeline outputs, but it results in updated content in the Azure DevOps wiki repository.

## Dependencies

This template may depend on the following:

- **Required Scripts**: `wiki-build.sh` to process markdown files and build wiki content
- **Required Permissions**: Write access to the wiki repository
- **Required Agent Capabilities**:
- Git with credential persistence support
- Bash shell
- **Required Project Configuration**:
- A "code" wiki associated with your Azure DevOps project
- Source repository with markdown documentation

## Usage

### Basic Usage

```yaml
# Basic implementation with minimal parameters
  - template: .azdo/templates/wiki-update-template.yml
  parameters:
    dependsOn: [BuildAndTest]
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
  - template: .azdo/templates/wiki-update-template.yml
  parameters:
    dependsOn:
      - BuildAndTest
      - SecurityScan
    displayName: "Update Project Documentation"
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    branchRepoFolder: "source-code"
    wikiRepoFolder: "docs-wiki"
    wikiRepo: "git://custom-project/custom-project@refs/heads/wiki"
    wikiBranch: "documentation"
```

## Implementation Details

The template executes a series of steps to update the wiki:

1. **Environment Setup**:
   - Creates directories for both repository checkouts
   - Configures Git to preserve credentials for authenticated operations

2. **Repository Checkouts**:
   - Checks out the main code repository to access documentation
   - Checks out the wiki repository to update with new content

3. **Wiki Content Generation**:
   - Runs the `wiki-build.sh` script to process markdown files
   - Formats content for wiki compatibility
   - Generates a structured wiki hierarchy

4. **Content Publication**:
   - Copies generated content to the wiki repository
   - Adds all changes to Git
   - Commits with a standardized message including build information
   - Pushes changes to the wiki repository

### Key Components

- **Branch Checkout**: Uses the `checkout` task with custom parameters for each repository
- **Wiki Build Script**: Processes markdown documentation into wiki-compatible format
- **Git Operations**: Handles adding, committing, and pushing changes to the wiki
- **Conditional Execution**: Only runs on successful builds of the main branch

### Error Handling

The template handles errors through these mechanisms:

- Check for script execution success before proceeding to commit
- Use of the `continueOnError` flag for non-critical steps
- Pipeline will fail if critical Git operations fail

## Examples

### Example 1: Basic Wiki Update on Main Branch

```yaml
# Only update wiki when merging to main branch
stages:
  - stage: Documentation
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    jobs:
      - template: .azdo/wiki-update-template.yml
```

## Troubleshooting

Common issues and their solutions:

1. **Authentication Failures**:
   - **Symptom**: Git operations fail with authentication errors
   - **Solution**: Ensure the build service has sufficient permissions to push to the wiki repository

2. **Missing Wiki Repository**:
   - **Symptom**: Cannot find the wiki repository
   - **Solution**: Verify that a code wiki has been published in your Azure DevOps project

3. **Wiki Build Script Errors**:
   - **Symptom**: Wiki content is not properly formatted or incomplete
   - **Solution**: Check the `wiki-build.sh` script for errors and verify it's processing all documentation files correctly

4. **Empty Wiki Updates**:
   - **Symptom**: Wiki update job succeeds but no changes appear in the wiki
   - **Solution**: Verify that documentation files have changed and that the build script is generating content

## Related Templates

- MegaLinter Template: [YAML](/.azdo/templates/megalinter-template.yml) | [Documentation](./megalinter-template.md) - Validates documentation quality before wiki updates
- Docs Check Template: [YAML](/.azdo/templates/docs-check-terraform-template.yml) | [Documentation](./docs-check-terraform-template.md) - Ensures documentation follows standards
- Matrix Folder Check Template: [YAML](/.azdo/templates/matrix-folder-check-template.yml) | [Documentation](./matrix-folder-check-template.md) - Detects changes in documentation files

## Learn More

- [Azure DevOps Wiki Documentation](https://learn.microsoft.com/azure/devops/project/wiki/wiki-create-repo)
- [Wiki Markdown Syntax](https://learn.microsoft.com/azure/devops/project/wiki/markdown-guidance)
- [Azure DevOps Pipeline YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)
- [Git Operations in Azure Pipelines](https://learn.microsoft.com/azure/devops/pipelines/scripts/git-commands)
- [Documentation Best Practices](https://learn.microsoft.com/style-guide/)
- [Repository Structure Guide](/README.md)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
