---
title: Matrix Folder Check Template
description: Azure DevOps pipeline template for detecting directory changes and creating dynamic outputs for conditional execution
author: Edge AI Team
ms.date: 09/21/2025
ms.topic: concept
estimated_reading_time: 7
keywords:
  - matrix strategy
  - folder change detection
  - dynamic outputs
  - conditional execution
  - azure devops
  - pipeline template
  - change detection
  - directory monitoring
  - ci-cd optimization
  - parallel testing
  - build efficiency
  - terraform detection
  - bicep detection
  - script detection
---

This template detects changes in specific directories of your repository and creates
dynamic outputs to drive conditional execution in downstream jobs, improving pipeline
efficiency by only running jobs on components that have changed.

## Overview

The Matrix Folder Check Template is a key component in our CI/CD pipeline that enables
efficient testing by identifying which parts of the codebase have been modified. It
compares the current branch against the main branch to detect changes in Terraform
files, PowerShell scripts, and shell scripts. Based on these changes, it creates output
variables that downstream jobs can use to determine whether they need to run, thus
optimizing pipeline execution time and resources.

## Features

- **Change Detection**: Automatically identifies modified files between the current branch and main
- **Terraform Module Tracking**: Creates a dynamic build matrix of changed Terraform modules
- **Script Modification Detection**: Detects changes in shell and PowerShell scripts in the subscription setup folder
- **Conditional Output Generation**: Produces output variables that can be used to conditionally run downstream jobs
- **Blueprint and Component Support**: Works with both component directories in `./src` and `./blueprint` directories
- **JSON Matrix Generation**: Creates properly formatted JSON for Azure DevOps matrix strategies
- **Full Directory Support**: Optional ability to include all folders containing Terraform and Bicep files, not just those with changes

## Parameters

| Parameter           | Type    | Required | Default                                | Description                                                                          |
|---------------------|---------|----------|----------------------------------------|--------------------------------------------------------------------------------------|
| `dependsOn`         | object  | No       | `[]`                                   | Specifies which jobs this job depends on                                             |
| `displayName`       | string  | No       | `'Check for changes in src directory'` | Custom display name for the job                                                      |
| `condition`         | string  | No       | `succeeded()`                          | Condition that determines when this job runs                                         |
| `includeIaCFolders` | boolean | No       | `false`                                | When true, returns all folders with Terraform and Bicep files, not just changed ones |

## Outputs

| Output Variable              | Description                                                                                      | Example                                                                                                |
|------------------------------|--------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| `changesInRpEnablementShell` | Indicates if shell scripts changed in subscription setup                                         | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementShell']` |
| `changesInRpEnablementPwsh`  | Indicates if PowerShell scripts changed in subscription setup                                    | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementPwsh']`  |
| `changesInTfInstall`         | Indicates if any Terraform or Bicep files changed (true if either has changes)                   | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInTfInstall']`         |
| `changedTfFolders`           | JSON object with Terraform folder names (changed folders or all folders depending on parameters) | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedTfFolders']`           |
| `changesInBicepInstall`      | Indicates if any Bicep files changed                                                             | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInBicepInstall']`      |
| `changedBicepFolders`        | JSON object with Bicep folder names (changed folders or all folders depending on parameters)     | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedBicepFolders']`        |

## Dependencies

This template may depend on the following:

- **Required Agent Capabilities**: Git, Bash, jq
- **Required Git Configuration**: Repository must be checked out with sufficient history (`fetchDepth: 0`)

## Usage

### Basic Usage

```yaml
# Basic implementation with minimal parameters
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Detect Changed Components"
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      dependsOn:
        - PreviousValidationJob
      displayName: "Custom Change Detection"
      condition: and(succeeded(), eq(variables['Build.Reason'], 'PullRequest'))
```

### Including All Folders

```yaml
# Implementation that includes all folders with Terraform and Bicep files
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Include All Components"
      includeIaCFolders: true
```

## Implementation Details

The template executes a series of steps to identify changes and create structured outputs:

1. **Repository Checkout**: Checks out the repository with full history (`fetchDepth: 0`)
2. **Change Detection**: Uses the `Detect-Folder-Changes.ps1` script to process changes
3. **Output Processing**: Extracts values from the script's JSON output and sets them as pipeline variables

The script handles:

- Comparing the current branch with main using `git diff`
- Searching for changes in `.sh` files in the subscription setup folder
- Searching for changes in `.ps1` files in the subscription setup folder
- Identifying changes in `.tf`, `.tfvars`, `.tfstate`, or `.hcl` files
- Creating a JSON object with folder names for matrix-based job execution

### Key Components

- **External Script**: Uses `./scripts/build/Detect-Folder-Changes.ps1` for efficient change detection
- **Script Parameters**:
- `--include-all-folders`: When provided, returns all folders with Terraform and Bicep files, not just changed ones
- `--base-branch`: Allows specifying a different base branch (defaults to origin/main)
- **JSON Output Processing**: Parses the structured JSON response from the script to extract relevant values
- **Variable Output**: Sets Azure DevOps variables with the `isOutput=true` flag for downstream job consumption

### Error Handling

The template has built-in error handling for common scenarios:

- If no changes are detected, appropriate output variables are still set to false/none
- JSON parsing errors are captured and reported in the job logs
- Empty directory lists are properly handled to prevent downstream jobs from failing

## Examples

### Example 1: Conditional Terraform Testing

```yaml
# Use matrix outputs to conditionally run Terraform tests
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Check Component Changes"

  - job: TerraformTests
    dependsOn: MatrixBuildFolderCheck
    condition: eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInInstall'], 'true')
    strategy:
      matrix:
        $[ dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedTFFolders'] ]
    steps:
      - script: echo "Running tests for $(folderName)"
```

### Example 2: Resource Provider Script Testing

```yaml
# Conditionally run tests for resource provider scripts
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml

  - job: ShellScriptTesting
    dependsOn: MatrixBuildFolderCheck
    condition: eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementShell'], 'true')
    steps:
      - script: echo "Testing shell scripts in subscription setup folder"

  - job: PowerShellTesting
    dependsOn: MatrixBuildFolderCheck
    condition: eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementPwsh'], 'true')
    steps:
      - script: echo "Testing PowerShell scripts in subscription setup folder"
```

### Example 3: Testing All Components

```yaml
# Run tests on all Terraform and Bicep components regardless of changes
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Get All Components"
      includeIaCFolders: true

  - job: TestAllComponents
    dependsOn: MatrixBuildFolderCheck
    strategy:
      matrix:
        $[ dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedTFFolders'] ]
    steps:
      - script: echo "Running tests for $(folderName) regardless of changes"
```

## Troubleshooting

Common issues and their solutions:

1. **Empty Matrix Error**:
   - **Symptom**: Downstream job fails with "A matrix job cannot be empty"
   - **Solution**: The condition should check if changes were detected before referencing the matrix variable
   - **Note**: When using `includeIaCFolders: true`, this is less likely to occur as it will find all relevant folders

2. **JSON Format Issues**:
   - **Symptom**: Azure DevOps complains about matrix format
   - **Solution**: Verify the script is generating valid JSON for Azure DevOps matrices

3. **Script Execution Issues**:
   - **Symptom**: The pipeline fails with script execution errors
   - **Solution**: Ensure the Detect-Folder-Changes.ps1 script exists and is properly located at ./scripts/build/Detect-Folder-Changes.ps1

4. **Git History Issues**:
   - **Symptom**: Change detection isn't finding changes that you know exist
   - **Solution**: Ensure the repository is checked out with `fetchDepth: 0` to get full history
   - **Alternative**: Use `includeIaCFolders: true` to bypass change detection entirely

5. **Variable Access Errors**:
   - **Symptom**: Downstream jobs can't access the output variables
   - **Solution**: Ensure you're referencing the variables correctly with the full path, including task name

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
