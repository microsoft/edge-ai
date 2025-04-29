# Terraform Cluster Test Template

This template provides a comprehensive set of tasks for testing Terraform components
within the repository, ensuring modules are validated, run through planning, and tested
before integration into the main codebase.

## Overview

The Terraform Cluster Test template automates the testing of Terraform components/
modules by running a series of validation, planning, and testing operations. It
supports dynamic matrix-based execution to test multiple folders based on detected
changes in source code. This approach ensures that only modified components are tested,
improving pipeline efficiency while maintaining quality assurance for our
infrastructure code.

## Features

- **Dynamic Matrix Testing**: Tests multiple Terraform folders based on detected changes
- **Multi-stage Testing**: Runs initialization, validation, terraform plans, and testing for each folder
- **Provider Version Check**: Detects outdated or mismatched provider versions and warns or fails the build
- **Artifact Publishing**: Creates and publishes Terraform plans as build artifacts for review
- **Test Results**: Converts Terraform test output to JUnit XML format and publishes to the Test Results UI
- **Compatibility Checks**: Validates Terraform configuration across multiple versions and platforms
- **Parameterized Execution**: Configurable options to adjust testing scope and behavior

## Parameters

| Parameter                | Type    | Required | Default                                                                                      | Description                                                    |
|--------------------------|---------|----------|----------------------------------------------------------------------------------------------|----------------------------------------------------------------|
| `dependsOn`              | object  | No       | `[]`                                                                                         | Job dependencies, typically pointing to the matrix builder job |
| `displayName`            | string  | No       | `'Terraform Cluster Test'`                                                                   | Custom display name for the job in the pipeline                |
| `condition`              | string  | No       | `succeeded()`                                                                                | Execution condition determining when this template should run  |
| `matrixVariable`         | string  | Yes      | `dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedTFFolders']` | Variable containing the matrix of folders to test              |
| `poolName`               | string  | No       | `'ai-on-edge-managed-pool'`                                                                  | Agent pool name to use for running the jobs                    |
| `vmImage`                | string  | No       | `'ubuntu-latest'`                                                                            | VM image to use for the build agent                            |
| `azureServiceConnection` | string  | No       | `'azdo-ai-for-edge-iac-for-edge'`                                                            | Azure service connection name for authenticating with Azure    |
| `backendResourceGroup`   | string  | No       | `'IaC_For_Edge'`                                                                             | Terraform backend resource group for state storage             |
| `backendStorageAccount`  | string  | No       | `'edge-ai-tf'`                                                                               | Terraform backend storage account name                         |
| `backendContainer`       | string  | No       | `'edge-ai-tf'`                                                                               | Terraform backend container name                               |
| `backendKey`             | string  | No       | `'edge-ai.tfstate'`                                                                          | Terraform backend state key                                    |
| `backendLocation`        | string  | No       | `'eastus'`                                                                                   | Terraform backend location                                     |
| `maxParallel`            | number  | No       | `1`                                                                                          | Maximum parallel jobs to run in the matrix                     |
| `breakBuild`             | boolean | No       | `true`                                                                                       | Whether to break the build on provider version mismatches      |

## Outputs

| Output Variable          | Description                                                         | Example                                                               |
|--------------------------|---------------------------------------------------------------------|-----------------------------------------------------------------------|
| `terraformTestResults`   | Contains the combined test results from all tested folders          | `dependencies.TerraformClusterTest.outputs['terraformTestResults']`   |
| `providerVersionsStatus` | Indicates whether all provider versions match the required versions | `dependencies.TerraformClusterTest.outputs['providerVersionsStatus']` |

## Dependencies

This template depends on the following:

- **Required Azure DevOps Tasks**: Terraform, Bash, AzureCLI, PublishPipelineArtifact, PublishTestResults
- **Required Pipeline Variables**:
  - Subscription ID (SUBSCRIPTION_ID in pipeline variables)
  - Custom Locations OID (TF_VAR_CUSTOM_LOCATIONS_OID in pipeline variables)
- **Required Agent Capabilities**:
  - Bash shell
  - Node.js (installed during execution)
  - jq command-line JSON processor
- **Required Prior Jobs**:
  - MatrixBuildFolderCheck job that outputs the folders to test

## Usage

### Basic Usage

```yaml
# Basic implementation with minimal parameters
jobs:
  - job: MatrixBuildFolderCheck
    displayName: Detect Changed Terraform Folders
    steps:
      - template: .azdo/templates/matrix-folder-check-template.yml
        parameters:
          displayName: "Detect component changes"
          condition: succeeded()

  - job: TerraformClusterTest
    dependsOn: MatrixBuildFolderCheck
    displayName: Terraform Component Tests
    steps:
      - template: .azdo/templates/cluster-test-terraform-template.yml
        parameters:
          dependsOn: MatrixBuildFolderCheck
          matrixVariable: dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedTFFolders']
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
jobs:
  - job: MatrixBuildFolderCheck
    displayName: Detect Changed Terraform Folders
    steps:
      - template: .azdo/templates/matrix-folder-check-template.yml
        parameters:
          displayName: "Detect component changes"
          condition: succeeded()

  - job: TerraformClusterTest
    dependsOn:
      - MatrixBuildFolderCheck
      - PreviousValidationJob
    displayName: Custom Terraform Component Tests
    steps:
      - template: .azdo/templates/cluster-test-terraform-template.yml
        parameters:
          dependsOn:
            - MatrixBuildFolderCheck
            - PreviousValidationJob
          displayName: "Custom Terraform Component Tests"
          condition: and(succeeded(), eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInInstall'], 'true'))
          matrixVariable: dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedTFFolders']
          azureServiceConnection: 'your-custom-service-connection'
          backendResourceGroup: 'Your-Custom-RG'
          backendStorageAccount: 'yourcustomstorageacct'
          backendContainer: 'terraform-state'
          backendKey: 'project.tfstate'
          maxParallel: 3
          breakBuild: false
```

## Implementation Details

The template executes a series of steps for each Terraform folder identified in the matrix build:

1. **Step 1**: Set up environment by authenticating with Azure and installing required tools
2. **Step 2**: Check provider versions against latest available versions
3. **Step 3**: Initialize Terraform with the remote backend
4. **Step 4**: Validate the Terraform configuration
5. **Step 5**: Run Terraform plan and capture the output
6. **Step 6**: Execute Terraform tests if present
7. **Step 7**: Process and publish results

### Key Components

- **Matrix Executor**: Dependency that dynamically creates test jobs based on changed Terraform folders
- **Provider Version Checker**: Script that analyzes and validates provider versions
- **Test Converter**: Transforms Terraform test output into standard JUnit XML format
- **Backend Configuration**: Manages state storage and sharing across pipeline runs

### Error Handling

The template handles several error conditions:

- Provider version mismatches can be configured to issue warnings or break the build
- Terraform init/validate/plan failures are clearly reported with detailed logs
- Test failures are captured and reported in the Azure DevOps Test Results UI
- Matrix failures are isolated to individual folders, allowing other tests to continue

## Examples

### Example 1: Testing Changes in a Pull Request

```yaml
# Testing changes detected in a PR
jobs:
  - job: MatrixBuildFolderCheck
    displayName: Detect Changed Terraform Folders
    steps:
      - template: .azdo/templates/matrix-folder-check-template.yml
        parameters:
          displayName: "Detect component changes"
          condition: succeeded()

  - job: TerraformClusterTest
    dependsOn: MatrixBuildFolderCheck
    displayName: Terraform Testing and Validation
    steps:
      - template: .azdo/templates/cluster-test-terraform-template.yml
        parameters:
          dependsOn: MatrixBuildFolderCheck
          matrixVariable: dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedTFFolders']
```

### Example 2: Scheduled Full Test Run

```yaml
# Running full test suite on a schedule
schedules:
- cron: "0 0 * * 0"  # Weekly Sunday midnight
  displayName: Weekly Full Test
  branches:
    include:
      - main
  always: true

jobs:
  - job: MatrixBuildFolderCheck
    displayName: Prepare Full Test Matrix
    steps:
      - template: .azdo/templates/matrix-folder-check-template.yml
        parameters:
          displayName: "Full component scan"
          condition: succeeded()

  - job: TerraformClusterTest
    dependsOn: MatrixBuildFolderCheck
    displayName: Terraform Testing and Validation
    steps:
      - template: .azdo/templates/cluster-test-terraform-template.yml
        parameters:
          dependsOn: MatrixBuildFolderCheck
          matrixVariable: dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedTFFolders']
```

## Troubleshooting

Common issues and their solutions:

1. **Backend Authentication Failures**:
   - **Solution**: Verify the Azure service connection has proper permissions and that all backend parameters are correctly specified.

2. **Matrix Variable Empty**:
   - **Solution**: Ensure the matrix folder check job is correctly detecting changes and verify the output variable name matches exactly what's expected.

3. **Provider Version Failures**:
   - **Solution**: Update provider versions in the affected modules to match repository standards or set `breakBuild: false` to continue with warnings.

4. **Test Conversion Errors**:
   - **Solution**: Ensure Terraform test output follows expected format or update the conversion script to handle the specific output pattern.

## Related Templates

- Matrix Folder Check Template: [YAML](./matrix-folder-check-template.yml) | [Documentation](./matrix-folder-check-template.md) - Detects changes in Terraform folders and creates a build matrix
- Variable Compliance Terraform Template: [YAML](./variable-compliance-terraform-template.yml) | [Documentation](./variable-compliance-terraform-template.md) - Ensures consistent variable definitions across Terraform modules
- Resource Provider Tests Template: [YAML](./resource-provider-pwsh-tests-template.yml) | [Documentation](./resource-provider-pwsh-tests-template.md) - Tests Azure Resource Provider registration scripts

## Learn More

- [Azure DevOps YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)
- [Azure IoT Operations Documentation](https://learn.microsoft.com/azure/iot-operations/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Terraform Testing Best Practices](https://www.terraform.io/docs/extend/testing/index.html)
- [Repository Structure Guide](/README.md)
- [Azure DevOps Test Results Publishing](https://learn.microsoft.com/azure/devops/pipelines/test/review-continuous-test-results-after-build)
