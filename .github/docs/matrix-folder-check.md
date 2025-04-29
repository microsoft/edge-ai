# Matrix Folder Check Workflow

A reusable workflow that detects changes in repository directory structure and creates dynamic outputs for driving conditional execution in downstream jobs.

## Overview

This workflow is designed to efficiently identify changes in specific directories and file types, providing outputs that help optimize CI/CD pipelines by only running necessary jobs. It's particularly useful for large repositories with multiple components, allowing targeted testing of only modified components rather than the entire codebase.

## Features

- **Change Detection**: Identifies changes in shell scripts, PowerShell scripts, Terraform files, and Bicep files
- **Matrix Generation**: Creates a JSON matrix of changed folders for parallel testing
- **Comprehensive Mode**: Optional parameter to include all folders regardless of changes
- **Reusable Design**: Can be called from other workflows with customizable parameters
- **Efficient Processing**: Uses a specialized script to quickly identify relevant changes

## Parameters

| Parameter           | Type    | Required | Default                              | Description                                          |
|---------------------|---------|----------|--------------------------------------|------------------------------------------------------|
| `displayName`       | string  | No       | 'Check for changes in src directory' | Custom display name for the job                      |
| `includeAllFolders` | boolean | No       | `false`                              | When true, returns all folders regardless of changes |

## Outputs

| Output Variable              | Description                                                                      | Example                                                     |
|------------------------------|----------------------------------------------------------------------------------|-------------------------------------------------------------|
| `changesInRpEnablementShell` | Boolean flag indicating if shell scripts in subscription setup have changed      | `needs.check-changes.outputs.changesInRpEnablementShell`    |
| `changesInRpEnablementPwsh`  | Boolean flag indicating if PowerShell scripts in subscription setup have changed | `needs.check-changes.outputs.changesInRpEnablementPwsh`     |
| `changesInTfInstall`         | Boolean flag indicating if any Terraform files have changed                      | `needs.check-changes.outputs.changesInTfInstall`            |
| `changedTfFolders`           | JSON object with all identified Terraform folder names for matrix strategy       | `fromJson(needs.check-changes.outputs.changedTfFolders)`    |
| `changesInBicepInstall`      | Boolean flag indicating if any Bicep files have changed                          | `needs.check-changes.outputs.changesInBicepInstall`         |
| `changedBicepFolders`        | JSON object with all identified Bicep folder names for matrix strategy           | `fromJson(needs.check-changes.outputs.changedBicepFolders)` |

## Dependencies

This template may depend on the following:

- **Required Scripts**: Uses `./scripts/build/detect-folder-changes.sh` for change detection
- **Required Tools**:
  - `jq` for JSON processing
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
jobs:
  check-all-folders:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeAllFolders: true
      displayName: "Check all folders"
```

## Implementation Details

The workflow executes a single job that:

1. Checks out the repository with full history
2. Makes the detection script executable
3. Runs the script with appropriate parameters
4. Parses the JSON output for change detection
5. Sets output values for downstream jobs

### Key Components

- **detect-folder-changes.sh**: The core script that analyzes repository changes
- **JSON Processing**: Uses `jq` to extract and format the necessary information
- **Matrix Formation**: Formats detected folders into a matrix-compatible JSON structure

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

### Example 2: Bicep Template Validation

```yaml
name: Bicep Validation

on:
  pull_request:
    branches: [main]

jobs:
  check-changes:
    uses: ./.github/workflows/matrix-folder-check.yml

  bicep-tests:
    needs: check-changes
    if: ${{ needs.check-changes.outputs.changesInBicepInstall == 'true' }}
    strategy:
      matrix: ${{ fromJson(needs.check-changes.outputs.changedBicepFolders) }}
    steps:
      - name: Validate Bicep Templates
        run: az bicep build --file "${{ matrix.folderName }}/main.bicep"
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
      includeAllFolders: true
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
