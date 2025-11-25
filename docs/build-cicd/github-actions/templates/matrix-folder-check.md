---
title: Matrix Folder Check Workflow
description: GitHub Actions reusable workflow for detecting directory changes and creating dynamic outputs for conditional execution
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: concept
estimated_reading_time: 7
keywords:
  - matrix strategy
  - folder change detection
  - dynamic outputs
  - conditional execution
  - github-actions
  - workflow template
  - change detection
  - directory monitoring
  - ci-cd optimization
  - parallel testing
  - build efficiency
  - terraform detection
  - bicep detection
  - script detection
---

A reusable workflow that detects changes in repository directory structure and creates dynamic outputs for driving conditional execution in downstream jobs.

## Overview

This reusable workflow efficiently identifies changes in specific directories and file types, providing outputs that help optimize CI/CD pipelines by only running necessary jobs. It's particularly useful for large repositories with multiple components, allowing targeted testing of only modified components rather than the entire codebase.

The workflow has been consolidated into a single, comprehensive solution that combines all detection capabilities, including application support, into one reusable workflow file.

## Features

- **Change Detection**: Identifies changes in shell scripts, PowerShell scripts, Terraform files, Bicep files, and application folders
- **Matrix Generation**: Creates JSON matrices of changed folders for parallel testing
- **Application Support**: Detects application changes in src/500-application with docker-compose files
- **Comprehensive Mode**: Optional parameters to include all folders regardless of changes
- **Cross-Platform**: Uses PowerShell script for consistent cross-platform execution
- **Reusable Design**: Can be called from other workflows with customizable parameters
- **Efficient Processing**: Uses a specialized PowerShell script to quickly identify relevant changes

## Parameters

| Parameter             | Type    | Required | Default                              | Description                                                                               |
|-----------------------|---------|----------|--------------------------------------|-------------------------------------------------------------------------------------------|
| `displayName`         | string  | No       | 'Check for changes in src directory' | Custom display name for the job                                                           |
| `includeIaCFolders`   | boolean | No       | `false`                              | When true, returns all Infrastructure as Code folders regardless of changes               |
| `includeApplications` | boolean | No       | `false`                              | When true, returns all application folders from src/500-application regardless of changes |

## Outputs

| Output Variable              | Description                                                                      | Example                                                           |
|------------------------------|----------------------------------------------------------------------------------|-------------------------------------------------------------------|
| `changesInRpEnablementShell` | Boolean flag indicating if shell scripts in subscription setup have changed      | `needs.check-changes.outputs.changesInRpEnablementShell`          |
| `changesInRpEnablementPwsh`  | Boolean flag indicating if PowerShell scripts in subscription setup have changed | `needs.check-changes.outputs.changesInRpEnablementPwsh`           |
| `changesInTfInstall`         | Boolean flag indicating if any Terraform files have changed                      | `needs.check-changes.outputs.changesInTfInstall`                  |
| `changedTfFolders`           | JSON object with all identified Terraform folder names for matrix strategy       | `fromJson(needs.check-changes.outputs.changedTfFolders)`          |
| `changesInBicepInstall`      | Boolean flag indicating if any Bicep files have changed                          | `needs.check-changes.outputs.changesInBicepInstall`               |
| `changedBicepFolders`        | JSON object with all identified Bicep folder names for matrix strategy           | `fromJson(needs.check-changes.outputs.changedBicepFolders)`       |
| `changesInApplications`      | Boolean flag indicating if any Application folders have changed                  | `needs.check-changes.outputs.changesInApplications`               |
| `changedApplicationFolders`  | JSON object with Application folder details for matrix strategy                  | `fromJson(needs.check-changes.outputs.changedApplicationFolders)` |

## Dependencies

This template may depend on the following:

- **Required Scripts**: Uses `./scripts/build/Detect-Folder-Changes.ps1` PowerShell script for change detection
- **Required Tools**:
  - PowerShell Core (pwsh) for cross-platform execution
  - Git with fetch-depth: 0 for full history access

## Usage

### Basic Usage

```yaml
jobs:
  check-changes:
    uses: ./.github/workflows/matrix-folder-check.yml
```

### Advanced Usage

```yaml
# Include all Infrastructure as Code folders
jobs:
  check-all-iac-folders:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeIaCFolders: true
      displayName: "Check all IaC folders"

# Include all application folders
  check-all-applications:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeApplications: true
      displayName: "Check all applications"

# Include both IaC and applications
  check-all-components:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeIaCFolders: true
      includeApplications: true
      displayName: "Check all components"
```

## Implementation Details

The workflow executes two jobs for optimal output handling:

1. **Detection Job**:
   - Checks out the repository with full history
   - Installs PowerShell Core for cross-platform execution
   - Runs the PowerShell detection script with appropriate parameters
   - Parses the JSON output for change detection
   - Sets raw output values from the detection script

2. **Output Mapping Job**:
   - Maps detection outputs to maintain backward compatibility
   - Formats matrix data for GitHub Actions consumption
   - Provides consistent output naming across different workflow versions

### Key Components

- **Detect-Folder-Changes.ps1**: The core PowerShell script that analyzes repository changes
- **JSON Processing**: Uses PowerShell's built-in JSON handling for data extraction and formatting
- **Matrix Formation**: Formats detected folders and applications into matrix-compatible JSON structures
- **Cross-Platform Execution**: Leverages PowerShell Core for consistent behavior across operating systems

## Examples

### Example 1: Conditional Testing Based on Changes

```yaml
name: CI Pipeline

on:
  pull_request:
    branches: [main]

jobs:
  check-changes:
    uses: ./.github/workflows/matrix-folder-check.yml

  terraform-tests:
    needs: check-changes
    if: ${{ needs.check-changes.outputs.changesInTfInstall == 'true' }}
    strategy:
      matrix: ${{ fromJson(needs.check-changes.outputs.changedTfFolders) }}
    steps:
      - name: Run Tests
        run: echo "Testing ${{ matrix.folderName }}"
```

### Example 2: Application Builds

```yaml
name: Application CI

on:
  pull_request:
    branches: [main]

jobs:
  check-changes:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeApplications: true

  application-builds:
    needs: check-changes
    if: ${{ needs.check-changes.outputs.changesInApplications == 'true' }}
    strategy:
      matrix: ${{ fromJson(needs.check-changes.outputs.changedApplicationFolders) }}
    steps:
      - name: Build Application
        run: |
          echo "Building application: ${{ matrix.applicationName }}"
          echo "Application path: ${{ matrix.applicationPath }}"
          echo "Services: ${{ matrix.services }}"
          echo "Has docker-compose: ${{ matrix.hasDockerCompose }}"

          # Build using docker-compose if available
          if [ "${{ matrix.hasDockerCompose }}" == "true" ]; then
            docker-compose -f "${{ matrix.applicationPath }}/docker-compose.yml" build
          fi
```

### Example 3: Complete Test Suite Run

```yaml
name: Weekly Full Test Run

on:
  schedule:
    - cron: '0 0 * * 0'

jobs:
  check-all-folders:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeIaCFolders: true
      displayName: "Check all infrastructure folders"

  run-complete-tests:
    needs: check-all-folders
    strategy:
      matrix: ${{ fromJson(needs.check-all-folders.outputs.changedTfFolders) }}
    steps:
      - name: Complete Test Suite
        run: ./scripts/test-runner.sh ${{ matrix.folderName }}
```

## Troubleshooting

1. **No Changes Detected**: Workflow reports no changes when there should be
   - **Solution**: Ensure fetch-depth is set to 0 to get full history

2. **Matrix Generation Failures**: Invalid JSON for matrix strategy
   - **Solution**: Check that the detection script is functioning correctly and returning valid JSON

3. **Missing Bicep Changes**: Bicep changes not detected properly
   - **Solution**: Verify the script has permissions to execute and properly recognizes .bicep files

## Related Workflows

- [Cluster Terraform Testing Workflow](./cluster-test-terraform.md) - Uses the matrix output from this workflow
- [Bicep Validation Workflow](./docs-check-bicep.md) - Validates Bicep templates based on detected changes

## Learn More

- [GitHub Actions Matrix Strategy](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- [GitHub Actions Workflow Reuse](https://docs.github.com/en/actions/using-workflows/reusing-workflows)
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [Azure Bicep Documentation](https://docs.microsoft.com/azure/azure-resource-manager/bicep/)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
