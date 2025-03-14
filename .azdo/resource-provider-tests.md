# Resource Provider Testing Integration

This document explains how Azure Resource Provider testing is integrated into our build system through a reusable Azure DevOps pipeline template.

## Overview

The resource provider testing template provides standardized testing for both shell scripts and PowerShell scripts that manage Azure resource provider registration and unregistration. These tests ensure that the scripts correctly enable or disable required Azure services for your infrastructure.

## How Resource Provider Testing Works

The template implements two parallel testing tracks:

1. **Shell Script Testing** (Linux-based):
   - Tests the bash scripts that register and unregister Azure resource providers
   - Runs the unregistration script to remove providers
   - Runs the registration script to add providers back
   - Verifies that both operations complete successfully

2. **PowerShell Script Testing** (Windows-based):
   - Runs Pester tests against PowerShell scripts for provider management
   - Publishes test results in a standardized format
   - Fails the build if tests don't pass

3. **Conditional Execution**:
   - Tests only run when changes are detected in relevant files
   - Shell and PowerShell test paths can be independently controlled

## Using the Resource Provider Tests Template

The template is available at [`.azdo/resource-provider-tests-template.yml`](./resource-provider-tests-template.yml) and can be included in your project's pipeline.

### Parameters

| Parameter               | Type   | Default                                                                                     | Description                                        |
|-------------------------|--------|---------------------------------------------------------------------------------------------|----------------------------------------------------|
| `dependsOn`             | string | MatrixBuildFolderCheck                                                                      | Job this template depends on                       |
| `shellScriptCondition`  | string | eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementShell'], 'true') | Condition to run shell script tests               |
| `pwshScriptCondition`   | string | eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementPwsh'], 'true')  | Condition to run PowerShell script tests          |
| `azureServiceConnection`| string | azdo-ai-for-edge-iac-for-edge                                                               | Azure service connection to use                    |
| `workingDirectory`      | string | $(System.DefaultWorkingDirectory)/src/000-subscription                                      | Directory containing resource provider scripts     |
| `pwshTestResultsOutput` | string | $(System.DefaultWorkingDirectory)/PWSH-TEST-RESULTS.xml                                     | Path for PowerShell test results output            |

### Example Usage

Include the template in your pipeline:

```yaml
- template: .azdo/resource-provider-tests-template.yml
  parameters:
    dependsOn: MatrixBuildFolderCheck
    azureServiceConnection: my-azure-connection
    workingDirectory: $(System.DefaultWorkingDirectory)/src/subscription-setup
```

### Advanced Example with Custom Conditions

```yaml
- template: .azdo/resource-provider-tests-template.yml
  parameters:
    dependsOn: CustomCheckJob
    shellScriptCondition: eq(dependencies.CustomCheckJob.outputs['customTask.shellFilesChanged'], 'true')
    pwshScriptCondition: eq(dependencies.CustomCheckJob.outputs['customTask.pwshFilesChanged'], 'true')
    azureServiceConnection: production-service-connection
    workingDirectory: $(System.DefaultWorkingDirectory)/src/setup
    pwshTestResultsOutput: $(System.DefaultWorkingDirectory)/test-results/powershell-tests.xml
```

## Implementation Details

The template runs two independent jobs:

### ResourceProviderShellScriptTest

- Runs on Linux (ubuntu-latest)
- Executes `unregister-azure-providers.sh` followed by `register-azure-providers.sh`
- Uses the Azure CLI task for authentication
- Assumes scripts take a text file with provider names as input

### ResourceProviderPWSHScriptTest

- Runs on Windows (windows-2022)
- Executes the `Invoke-Pester.ps1` script to run all Pester tests in the specified directory
- Publishes test results in the NUnit format
- Fails the build if any test fails

## Requirements

To use this template, you need:

1. **Azure Service Connection**: A valid Azure service connection with permissions to register and unregister resource providers
2. **Resource Provider Scripts**:
   - Shell scripts: `register-azure-providers.sh` and `unregister-azure-providers.sh`
   - PowerShell scripts with Pester tests (typically `.ps1` files)
3. **Pester Test Script**: A script called `Invoke-Pester.ps1` in the scripts directory
4. **Provider List File**: A file (default: `aio-azure-resource-providers.txt`) containing the list of Azure resource providers

## Benefits

- **Change-Based Testing**: Only runs tests when relevant files change
- **Cross-Platform Coverage**: Tests both Windows (PowerShell) and Linux (Bash) implementations
- **Clear Test Results**: Integration with Azure DevOps test reporting
- **Reusable Implementation**: Standardized template that can be used across projects
- **Pipeline Integration**: Works with the build folder check process

## Learn More

- [Azure Resource Providers Documentation](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types)
- [Pester Documentation](https://pester.dev/docs/quick-start)
- [Azure DevOps Test Publishing](https://learn.microsoft.com/azure/devops/pipelines/tasks/test/publish-test-results)
