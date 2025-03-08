# Azure Resource Provider Installation & Testing

This document explains how our pipeline tests Azure Resource Provider registration and unregistration scripts to ensure they work correctly across different environments.

## Overview

Our project includes automated testing for Azure Resource Provider scripts in two formats:

1. **Bash shell scripts** - For Linux/macOS environments
2. **PowerShell scripts** - For Linux/Windows environments

These tests are automatically triggered when changes are made to the respective script files in the `src/000-subscription` folder and ensure that our resource provider management scripts remain functional across changes.

## Pipeline Integration

The testing is integrated into our Azure DevOps pipeline with two dedicated jobs:

### 1. ResourceProviderShellScriptTest

This job tests the bash shell scripts for Linux environments.

```yaml
- job: ResourceProviderShellScriptTest
  dependsOn:
    - MatrixBuildFolderCheck
  pool:
    name: ai-on-edge-managed-pool
    vmImage: ubuntu-latest
  # Only runs when shell scripts in the 000-subscription folder are modified
  condition: eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementShell'], 'true')
  steps:
    - checkout: self
      clean: true

    # Test unregister providers script
    - task: AzureCLI@2
      displayName: Azure CLI for Resource Provider Unregistration Script Test
      inputs:
        azureSubscription: "azdo-ai-for-edge-iac-for-edge"
        workingDirectory: "$(System.DefaultWorkingDirectory)/src/000-subscription"
        scriptType: bash
        scriptLocation: inlineScript
        inlineScript: |
          # Uninstall the Azure providers
          echo "uninstalling azure providers"
          ./unregister-azure-providers.sh aio-azure-resource-providers.txt
          echo "uninstalled azure providers"

    # Test register providers script
    - task: AzureCLI@2
      displayName: Azure CLI for Resource Provider Registration Script Test
      inputs:
        azureSubscription: "azdo-ai-for-edge-iac-for-edge"
        workingDirectory: "$(System.DefaultWorkingDirectory)/src/000-subscription"
        scriptType: bash
        scriptLocation: inlineScript
        inlineScript: |
          # Install the Azure providers
          echo "installing azure providers"
          ./register-azure-providers.sh aio-azure-resource-providers.txt
          echo "installed azure providers"
```

### 2. ResourceProviderPWSHScriptTest

This job tests the PowerShell scripts for Linux/Windows environments.

```yaml
- job: ResourceProviderPWSHScriptTest
  dependsOn:
    - MatrixBuildFolderCheck
  pool:
    name: ai-on-edge-managed-pool
    vmImage: "windows-2022"
  # Only runs when PowerShell scripts in the 000-subscription folder are modified
  condition: eq(dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInRpEnablementPwsh'], 'true')
  variables:
    testResultsOutput: "$(System.DefaultWorkingDirectory)/PWSH-TEST-RESULTS.xml"
  steps:
    - checkout: self
      clean: true

    # Run Pester tests for the resource provider scripts
    - powershell: ./scripts/Invoke-Pester.ps1 -Path ./src/000-subscription -OutputFile $(testResultsOutput)
      displayName: "Run pester"
      workingDirectory: $(System.DefaultWorkingDirectory)

    # Publish the Pester test results
    - task: PublishTestResults@2
      displayName: Publish Test Results
      inputs:
        testRunTitle: "Test Results for Pester"
        buildPlatform: "Windows"
        testRunner: "NUnit"
        testResultsFiles: "$(testResultsOutput)"
        failTaskOnFailedTests: true
```

## Script Files Being Tested

The following scripts are tested in these pipeline jobs:

### Bash Scripts

- `/src/000-subscription/register-azure-providers.sh` - Registers required Azure resource providers
- `/src/000-subscription/unregister-azure-providers.sh` - Unregisters Azure resource providers

### PowerShell Scripts

- `/src/000-subscription/register-azure-providers.ps1` - PowerShell version for registering providers
- `/src/000-subscription/register-azure-providers.Tests.ps1` - Pester tests for the PowerShell script

## Change Detection

The pipeline intelligently detects changes to relevant files using a dedicated job (`MatrixBuildFolderCheck`):

- For bash scripts, it checks for files matching `src/000-subscription/.*\.sh$`
- For PowerShell scripts, it checks for files matching `src/000-subscription/.*\.ps1$`

Tests are only run when changes are detected in the corresponding scripts, which helps optimize pipeline execution time.

## Testing Approach

### Shell Script Testing

The shell script test follows a practical approach:

1. First unregisters Azure resource providers using the `unregister-azure-providers.sh` script
2. Then registers them again using the `register-azure-providers.sh` script
3. Both commands must exit with code 0 (success) for the test to pass

### PowerShell Testing

The PowerShell testing uses [Pester](https://pester.dev/), a testing framework for PowerShell:

1. Runs the test suite defined in `register-azure-providers.Tests.ps1`
2. Tests individual functions within the script for proper functionality
3. Generates test results in NUnit XML format for integration with Azure DevOps test reporting

## Setting Up Local Testing

### Testing Shell Scripts Locally

```bash
cd src/000-subscription
# Login to Azure if not already logged in
az login
# First run the unregister script
./unregister-azure-providers.sh aio-azure-resource-providers.txt
# Then run the register script
./register-azure-providers.sh aio-azure-resource-providers.txt
```

### Testing PowerShell Scripts Locally

```powershell
cd src/000-subscription
# Import Pester if not already available
Import-Module Pester
# Run the Pester tests
Invoke-Pester -Path ./register-azure-providers.Tests.ps1
```

## Best Practices

When modifying resource provider scripts:

1. **Test on both platforms**: Ensure your changes work in both bash and PowerShell environments
2. **Update tests**: If you change script functionality, update the corresponding tests
3. **Run tests locally**: Before committing, test your changes locally
4. **Check dependencies**: Ensure your script correctly checks for dependencies like Azure CLI

By maintaining these cross-platform scripts and their tests, we ensure consistent resource provider management across all environments where our infrastructure is deployed.
