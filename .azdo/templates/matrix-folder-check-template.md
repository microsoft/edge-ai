# Matrix Folder Check Template

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
- **Full Directory Support**: Optional ability to include all folders containing Terraform files, not just those with changes

## Parameters

| Parameter           | Type    | Required | Default                                | Description                                                                      |
|---------------------|---------|----------|----------------------------------------|----------------------------------------------------------------------------------|
| `dependsOn`         | object  | No       | `[]`                                   | Specifies which jobs this job depends on                                         |
| `displayName`       | string  | No       | `'Check for changes in src directory'` | Custom display name for the job                                                  |
| `condition`         | string  | No       | `succeeded()`                          | Condition that determines when this job runs                                     |
| `includeAllFolders` | boolean | No       | `false`                                | When true, returns all folders with Terraform files, not just those with changes |

## Outputs

| Output Variable              | Description                                                                                           | Example                                                                                                |
|------------------------------|-------------------------------------------------------------------------------------------------------|--------------------------------------------------------------------------------------------------------|
| `changesInRpEnablementShell` | Indicates if shell scripts changed in subscription setup                                              | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementShell']` |
| `changesInRpEnablementPwsh`  | Indicates if PowerShell scripts changed in subscription setup                                         | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementPwsh']`  |
| `changesInInstall`           | Indicates if any Terraform files changed                                                              | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInInstall']`           |
| `changedTFFolders`           | JSON object with folder names (changed folders or all folders depending on includeAllFolders setting) | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedTFFolders']`           |

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
# Implementation that includes all folders with Terraform files
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Include All Terraform Components"
      includeAllFolders: true
```

## Implementation Details

The template executes a series of steps to identify changes and create structured outputs:

1. **Repository Checkout**: Checks out the repository with full history (`fetchDepth: 0`)
2. **Change Detection**: Uses `git diff` to compare the current branch with main
3. **Shell Script Detection**: Searches for changes in `.sh` files in the subscription setup folder
4. **PowerShell Script Detection**: Searches for changes in `.ps1` files in the subscription setup folder
5. **Terraform File Detection**: Identifies changes in `.tf`, `.tfvars`, `.tfstate`, or `.hcl` files
   - If `includeAllFolders` is true, finds all folders containing Terraform files instead of only changed ones
6. **Matrix Generation**: Creates a JSON object with folder names as keys for matrix-based job execution

### Key Components

- **Git Diff Command**: Uses `git diff --name-only --diff-filter=ACMRT origin/main...HEAD` to find changed files
- **Folder Name Extraction**: Parses file paths to extract the first-level directory names
- **Directory Scanning**: When `includeAllFolders` is true, uses `find` to locate all directories containing Terraform files
- **JSON Formatting**: Uses jq to convert the list of folders into a properly formatted JSON object
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

### Example 3: Testing All Terraform Components

```yaml
# Run tests on all Terraform components regardless of changes
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Get All Terraform Components"
      includeAllFolders: true

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
   - **Note**: When using `includeAllFolders: true`, this is less likely to occur as it will find all relevant folders

2. **JSON Format Issues**:
   - **Symptom**: Azure DevOps complains about matrix format
   - **Solution**: Verify the jq command is correctly generating valid JSON for Azure DevOps matrices

3. **Git History Issues**:
   - **Symptom**: Change detection isn't finding changes that you know exist
   - **Solution**: Ensure the repository is checked out with `fetchDepth: 0` to get full history
   - **Alternative**: Use `includeAllFolders: true` to bypass change detection entirely

4. **Variable Access Errors**:
   - **Symptom**: Downstream jobs can't access the output variables
   - **Solution**: Ensure you're referencing the variables correctly with the full path, including task name

## Related Templates

- Terraform Cluster Test Template: [YAML](./cluster-test-terraform-template.yml) | [Documentation](./cluster-test-terraform-template.md) - Uses the matrix to run Terraform tests
- Resource Provider Tests Template: [YAML](./resource-provider-tests-template.yml) | [Documentation](./resource-provider-tests-template.md) - Uses shell and PowerShell change detection
- Variable Compliance Terraform Template: [YAML](./variable-compliance-terraform-template.yml) | [Documentation](./variable-compliance-terraform-template.md) - Validates Terraform variable consistency

## Learn More

- [Azure DevOps Matrix Strategy](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/jobs-job-strategy)
- [Dynamic Matrix Generation](https://learn.microsoft.com/azure/devops/pipelines/process/runtime-parameters)
- [Git Diff Documentation](https://git-scm.com/docs/git-diff)
- [jq Manual](https://stedolan.github.io/jq/manual/)
- [Azure DevOps Pipeline Variables](https://learn.microsoft.com/azure/devops/pipelines/process/variables)
- [Repository Structure Guide](/README.md)
