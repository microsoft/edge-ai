---
title: Pull Request Validation Workflow
description: GitHub Actions workflow for comprehensive pull request validation, testing, and quality assurance
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: concept
estimated_reading_time: 7
keywords:
  - pull-request
  - validation
  - github-actions
  - ci-cd
  - megalinter
  - terraform
  - bicep
  - infrastructure as code
  - code quality
  - security scanning
  - dependency analysis
  - aio version checking
  - azure iot operations
  - powershell testing
  - variable compliance
  - matrix testing
  - documentation validation
---
## Overview

The Pull Request Validation workflow is a comprehensive CI/CD pipeline that runs on pull requests to ensure code quality, validate infrastructure changes, and verify readiness for merging to the main branch. It intelligently detects changed files to run the appropriate validation steps, focusing computational resources on relevant components.

## Features

- Intelligent detection of changed files to determine necessary validation steps
- Static code analysis with MegaLinter across multiple languages and file formats
- Strict documentation standards validation for Terraform and Bicep configurations
- Terraform validation including init, validate, plan, and test operations
- Azure IoT Operations component version checking
- Resource provider script testing for PowerShell and bash
- Matrix-based testing for efficient validation of multiple components
- Dependency scanning for security vulnerabilities

## Inputs

When triggered automatically by pull requests, this workflow doesn't require inputs. When manually triggered using `workflow_dispatch`, it accepts:

| Input                        | Description                                                          | Required | Default |
|------------------------------|----------------------------------------------------------------------|----------|---------|
| `includeAllTerraformFolders` | Include all folders in the matrix check instead of only changed ones | No       | `false` |

## Outputs

This workflow doesn't produce any direct output variables, but it generates the following:

- GitHub annotations for issues found during validation
- Pull request comments with linting and validation results
- Comprehensive test results for infrastructure code

## Usage Examples

### Automatic Execution

The workflow is automatically triggered on pull requests targeting the main branch and doesn't need manual invocation.

### Manual Execution

The workflow can also be triggered manually from the GitHub Actions tab:

1. Navigate to the "Actions" tab in the repository
2. Select the "PR Validation" workflow
3. Click "Run workflow"
4. Configure the optional inputs:
   - Select whether to include all terraform folders in validation (not just changed ones)
5. Click "Run workflow"

## Implementation Details

The workflow consists of multiple jobs that run in a specific sequence:

1. **Dependency Scan**: Analyzes project dependencies for security issues
2. **MegaLinter**: Performs comprehensive linting and static analysis
3. **Terraform Documentation Check**: Validates Terraform documentation consistency with strict validation
4. **Bicep Documentation Check**: Validates Bicep documentation consistency with strict validation
5. **AIO Version Check**: Verifies Azure IoT Operations component versions
6. **Matrix Changes Detection**: Determines which folders have changes to optimize testing
7. **PowerShell Provider Tests**: Tests resource provider scripts when relevant
8. **Terraform Variable Compliance**: Ensures consistent Terraform variable definitions
9. **Terraform Module Tests**: Runs tests for changed Terraform modules

## Workflow Steps

### Dependency Scan

1. Checks out the repository code
2. Performs dependency review for security vulnerabilities
3. Reports findings as GitHub annotations

### MegaLinter

Calls the reusable `megalinter.yml` workflow with:

- `github_comment_reporter: true` - Enables PR comment reporting for linting results

### Terraform Documentation Check

Calls the reusable `docs-check-terraform.yml` workflow with:

- `break_build: true` - Documentation issues will fail the workflow
- `terraformDocsVersion: 'v0.19.0'` - Specifies the version of terraform-docs to use

### Bicep Documentation Check

Calls the reusable `docs-check-bicep.yml` workflow with:

- `break_build: true` - Documentation issues will fail the workflow

### AIO Version Check

Calls the reusable `aio-version-checker.yml` workflow with:

- `iac-type: all` - Checks versions in all IaC types (Terraform and Bicep)
- `break-build: false` - Version warnings won't fail the build

### Matrix Changes Detection

Calls the reusable `matrix-folder-check.yml` workflow to:

1. Detect which specific folders have changes in the pull request
2. Create a matrix of changed folders for subsequent test steps
3. Output boolean flags indicating changes in specific areas
4. Optionally include all folders when manually triggered with that option

### PowerShell Provider Tests

Calls the reusable `resource-provider-pwsh-tests.yml` workflow when relevant changes are detected:

- Only runs if PowerShell resource provider scripts were changed
- Tests Azure resource provider registration scripts

### Terraform Variable Compliance

Calls the reusable `variable-compliance-terraform.yml` workflow to:

- Ensure consistent Terraform variable definitions across modules
- Report any inconsistencies as warnings

### Terraform Module Tests

Uses the `cluster-test-terraform.yml` workflow with a matrix strategy to:

- Run tests for each changed Terraform module individually
- Use a specific Terraform version (1.9.8)
- Test without actually applying the changes

## Troubleshooting

### Common Issues

1. **MegaLinter Failures**:
   - **Solution**: Review the linter report in PR comments or workflow artifacts and fix identified issues

2. **Documentation Validation Issues**:
   - **Solution**: Use the documentation generation scripts (`update-all-terraform-docs.sh` or `update-all-bicep-docs.sh`) to regenerate documentation, then commit changes

3. **Matrix Changes Detection Issues**:
   - **Solution**: If tests aren't running for your changes, check the `matrix-changes` job output to ensure changes were properly detected

4. **Terraform Variable Compliance Failures**:
   - **Solution**: Use the `tf-vars-compliance-check.py` script to identify and fix variable inconsistencies

### Extending the Workflow

To enhance this workflow:

1. To add additional validation steps:
   - Add new jobs after existing checks
   - Use the `needs` parameter to ensure proper sequencing

2. To modify detection thresholds:
   - Edit the `matrix-folder-check.yml` workflow to adjust change detection logic

## Related Workflows

- [main.yml](./main.md): Main branch CI/CD workflow that runs after PRs are merged
- [megalinter.yml](./megalinter.md): Linting workflow called by this workflow
- [docs-check-terraform.yml](./docs-check-terraform.md): Terraform documentation validation
- [docs-check-bicep.yml](./docs-check-bicep.md): Bicep documentation validation
- [matrix-folder-check.yml](./matrix-folder-check.md): Changes detection workflow
- [variable-compliance-terraform.yml](./variable-compliance-terraform.md): Terraform variable compliance check
- [cluster-test-terraform.yml](./cluster-test-terraform.md): Terraform module testing workflow

## Security Considerations

This workflow requires these permissions to function correctly:

- `contents: write`: Required for checking out code and potentially making annotations
- `pull-requests: write`: Required for commenting on pull requests
- `statuses: write`: Required for setting PR status checks

The workflow uses secrets inheritance (`secrets: inherit`) to pass repository secrets to called workflows.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
