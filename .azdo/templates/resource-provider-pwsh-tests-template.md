# Resource Provider Testing Template

This template provides automated testing for PowerShell scripts that manage Azure resource provider registration and unregistration, ensuring they correctly enable or disable required Azure services for your Edge AI infrastructure.

## Overview

The Resource Provider Testing Template validates the functionality of scripts that manage Azure resource providers. It runs tests for PowerShell scripts using PowerShell Core on Linux, ensuring proper functionality of your resource provider management code. Tests are intelligently triggered when changes are detected in the respective script files, optimizing pipeline execution time while maintaining quality assurance.

## Features

- **Linux-Based Testing**: Tests PowerShell scripts on Ubuntu environments
- **Conditional Execution**: Only runs tests when changes are detected in the relevant script files
- **Azure CLI Integration**: Authenticates with Azure to execute the actual provider registration/unregistration operations (**CAUTION**: this is a destructive test)
- **Pester Test Framework**: Uses industry-standard PowerShell testing framework for robust test coverage
- **Test Results Publishing**: Integrates with Azure DevOps test reporting for clear visibility of test status
- **Configurable Service Connection**: Allows using different Azure connections for testing in various environments
- **Custom Working Directory**: Supports testing scripts located in different repository folders

## Parameters

| Parameter                | Type   | Required | Default                                                                                                           | Description                                    |
|--------------------------|--------|----------|-------------------------------------------------------------------------------------------------------------------|------------------------------------------------|
| `dependsOn`              | string | No       | `MatrixBuildFolderCheck`                                                                                          | Job this template depends on                   |
| `pwshScriptCondition`    | string | No       | `eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementPwsh'], 'true')` | Condition to run PowerShell script tests       |
| `azureServiceConnection` | string | No       | `azdo-ai-for-edge-iac-for-edge`                                                                                   | Azure service connection to use                |
| `workingDirectory`       | string | No       | `$(System.DefaultWorkingDirectory)/src/000-subscription`                                                          | Directory containing resource provider scripts |
| `pwshTestResultsOutput`  | string | No       | `$(System.DefaultWorkingDirectory)/PWSH-TEST-RESULTS.xml`                                                         | Path for PowerShell test results output        |

## Outputs

This template doesn't produce formal pipeline outputs, but it generates test results that are published to Azure DevOps test reporting system.

## Dependencies

This template may depend on the following:

- **Required Azure DevOps Tasks**: Bash, PublishTestResults
- **Required Service Connections**:
  - Azure service connection with permissions to register and unregister resource providers
- **Required Agent Capabilities**:
  - Ubuntu Linux agent
  - PowerShell Core (pwsh) installation
  - Azure CLI installation
  - Pester module for PowerShell
- **Required Scripts**:
  - PowerShell scripts: `register-azure-providers.ps1` with corresponding Pester tests
  - `scripts/Invoke-Pester.ps1` for running PowerShell tests
- **Required Prior Jobs**:
  - MatrixBuildFolderCheck job that detects changes in PowerShell files

## Usage

### Basic Usage

```yaml
# Basic implementation with minimal parameters
- template: .azdo/templates/resource-provider-pwsh-tests-template.yml
  parameters:
    dependsOn: MatrixBuildFolderCheck
    azureServiceConnection: my-azure-connection
    workingDirectory: $(System.DefaultWorkingDirectory)/src/subscription-setup
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
- template: .azdo/templates/resource-provider-pwsh-tests-template.yml
  parameters:
    dependsOn: CustomCheckJob
    pwshScriptCondition: eq(dependencies.CustomCheckJob.outputs['customTask.pwshFilesChanged'], 'true')
    azureServiceConnection: production-service-connection
    workingDirectory: $(System.DefaultWorkingDirectory)/src/setup
    pwshTestResultsOutput: $(System.DefaultWorkingDirectory)/test-results/powershell-tests.xml
```

## Implementation Details

The template creates a job that tests resource provider management:

**PowerShell Testing Process**:

- Runs on an Ubuntu Linux agent (ubuntu-latest)
- Uses PowerShell Core (pwsh) to execute Invoke-Pester.ps1 to run all Pester tests
- Publishes test results in NUnit format
- Fails the build if any test fails

### Key Components

- **ResourceProviderPWSHScriptTest**: Job that tests PowerShell scripts on Windows
- **Pester Framework**: Runs structured tests for PowerShell scripts
- **Test Results Publisher**: Integrates test outcomes with Azure DevOps

### Error Handling

The template handles errors by:

- Failing the build if any script execution returns a non-zero exit code
- Publishing detailed test results for debugging PowerShell test failures
- Using the failTaskOnFailedTests flag to ensure build failures on test issues

## Examples

### Example 1: Default Testing Configuration

```yaml
# Standard test configuration with default conditions
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Check for script changes"

  - template: .azdo/templates/resource-provider-pwsh-tests-template.yml
    parameters:
      dependsOn: MatrixBuildFolderCheck
      azureServiceConnection: my-azure-service-connection
```

### Example 2: Custom Test Conditions

```yaml
jobs:
  # Use the matrix folder check template to detect changes in scripts
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Detect Script Changes"
      condition: succeeded()

  # Run the resource provider tests based on detected changes
  - template: .azdo/templates/resource-provider-pwsh-tests-template.yml
    parameters:
      dependsOn: MatrixBuildFolderCheck
      pwshScriptCondition: eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementPwsh'], 'true')
      azureServiceConnection: azdo-ai-for-edge-iac-for-edge
      workingDirectory: $(System.DefaultWorkingDirectory)/src/000-subscription
```

## Troubleshooting

Common issues and their solutions:

1. **Azure Authentication Failures**:
   - **Symptom**: Scripts fail with authentication or permission errors
   - **Solution**: Verify the service connection has the correct permissions to register and unregister resource providers

2. **Missing Script Files**:
   - **Symptom**: Build fails with "file not found" errors
   - **Solution**: Ensure the script files exist in the specified working directory

3. **PowerShell Test Framework Issues**:
   - **Symptom**: Error messages about Pester module not found
   - **Solution**: Verify the Invoke-Pester.ps1 script exists and properly imports the Pester module

4. **Wrong Provider List**:
   - **Symptom**: Scripts run but fail when trying to register/unregister providers
   - **Solution**: Check that the provider list file (aio-azure-resource-providers.txt) exists and contains valid provider names

## Related Templates

- Matrix Folder Check Template: [YAML](./matrix-folder-check-template.yml) | [Documentation](./matrix-folder-check-template.md) - Detects changes in script files and creates output variables
- Cluster Test Terraform Template: [YAML](./cluster-test-terraform-template.yml) | [Documentation](./cluster-test-terraform-template.md) - Tests Terraform components that may use these resource providers
- AIO Version Checker Template: [YAML](./aio-version-checker-template.yml) | [Documentation](./aio-version-checker-template.md) - Checks Azure IoT Operations component versions

## Learn More

- [Azure Resource Providers Documentation](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types)
- [Pester Documentation](https://pester.dev/docs/quick-start)
- [Azure DevOps Test Publishing](https://learn.microsoft.com/azure/devops/pipelines/tasks/test/publish-test-results)
- [Azure CLI Authentication](https://learn.microsoft.com/cli/azure/authenticate-azure-cli)
- [Azure DevOps Tasks](https://learn.microsoft.com/azure/devops/pipelines/tasks/reference/)
- [PowerShell Scripting Guide](https://learn.microsoft.com/powershell/scripting/overview)
