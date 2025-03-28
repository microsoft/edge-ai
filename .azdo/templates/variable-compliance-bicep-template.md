# Bicep Variable Compliance Template

This template provides an automated process for ensuring consistent variable definitions
across Bicep modules in your repository, detecting inconsistencies in variable descriptions,
types, default values, and validation rules.

## Overview

The Bicep Variable Compliance Template detects and reports inconsistencies in parameter
definitions across Bicep modules. By analyzing how parameters with the same name are defined
in different modules, it helps maintain high code quality and reduces confusion for
contributing developers. The checker scans all Bicep files in the repository, extracts
parameter definitions, compares them for consistency, and reports any discrepancies as build
warnings or errors, ensuring that your infrastructure code remains clean and maintainable.

## Features

- **Parameter Definition Consistency**: Ensures parameters with the same name have consistent descriptions across modules
- **Cross-Module Analysis**: Compares parameter definitions across all Bicep modules in the repository
- **Detailed Reporting**: Provides specific information about inconsistencies, including which modules and what differences
- **Configurable Severity**: Can be set to produce warnings or break the build based on compliance requirements
- **Pipeline Integration**: Seamlessly integrates with Azure DevOps build pipelines
- **Structured Output**: Generates clear, actionable information about detected inconsistencies

## Parameters

| Parameter     | Type    | Required | Default                                                        | Description                                                                  |
|---------------|---------|----------|----------------------------------------------------------------|------------------------------------------------------------------------------|
| `dependsOn`   | object  | No       | `[]`                                                           | Job dependencies, typically pointing to the preceding job                    |
| `displayName` | string  | No       | `'Bicep Variable Compliance Check'`                            | Custom display name for the job in the pipeline                              |
| `condition`   | string  | No       | `'succeeded()'`                                                | Execution condition determining when this template should run                |
| `breakBuild`  | boolean | No       | `false`                                                        | Whether to treat inconsistent variables as errors (true) or warnings (false) |
| `pool`        | object  | No       | `{ name: 'ai-on-edge-managed-pool', vmImage: 'windows-2022' }` | Agent pool configuration                                                     |

## Outputs

This template doesn't produce formal pipeline outputs, but it generates build warnings or errors for each detected variable inconsistency.

## Dependencies

This template depends on the following:

- **Required Tools**:
  - PowerShell 7.0+
  - Az.Bicep PowerShell module (installed automatically if not present)
- **Required Scripts**:
  - `scripts/Bicep-Var-Compliance-Check.ps1`: For checking variable consistency
- **Required Repository Structure**:
  - Bicep modules with parameter definitions organized in a consistent structure

## Usage

### Basic Usage

```yaml
# Basic implementation with minimal parameters
- template: .azdo/templates/variable-compliance-bicep-template.yml
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
- template: .azdo/templates/variable-compliance-bicep-template.yml
  parameters:
    dependsOn: [MegaLinter]
    displayName: "Parameter Definition Compliance"
    condition: succeeded('MegaLinter')
    breakBuild: true
    pool:
      name: 'custom-pool'
      vmImage: 'windows-2022'
```

## Implementation Details

The template executes a PowerShell script to analyze and compare variable definitions:

1. **Checkout Code**: Ensures clean workspace with latest code
2. **PowerShell Analysis**: Runs the PowerShell script to find all Bicep files, extract parameters, and analyze definitions
3. **Result Processing**: Parses the JSON output and creates build warnings/errors for inconsistencies based on the breakBuild parameter

### Key Components

- **bicep-var-compliance-check.ps1**: PowerShell script that analyzes Bicep parameter definitions
- **Find-BicepFile**: Function that locates all Bicep files in the specified directories
- **Get-BicepVariable**: Function that extracts parameter metadata from Bicep files
- **Compare-BicepVariable**: Function that identifies inconsistencies across Bicep modules
- **Issue Reporting**: Logic to convert findings into Azure DevOps build warnings/errors

### Error Handling

The template handles variable inconsistencies according to the `breakBuild` parameter:

- When `breakBuild` is `false` (default), inconsistencies generate warnings but allow the build to continue
- When `breakBuild` is `true`, inconsistencies cause the build to fail, enforcing variable consistency

## Examples

### Example 1: Basic Variable Compliance Check

```yaml
# Simple variable consistency check with warnings
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/variable-compliance-bicep-template.yml
```

### Example 2: Strict Variable Compliance Check

```yaml
# Variable compliance check that breaks the build on inconsistencies
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/variable-compliance-bicep-template.yml
        parameters:
          displayName: "Strict Parameter Compliance"
          breakBuild: true
```

### Example 3: Integration with Matrix Folder Check

```yaml
# Variable compliance as part of a larger validation process
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Detect Changed Folders"

  - template: .azdo/templates/variable-compliance-bicep-template.yml
    parameters:
      dependsOn: MatrixBuildFolderCheck
      condition: succeeded('MatrixBuildFolderCheck')
```

## Troubleshooting

Common issues and their solutions:

1. **PowerShell Module Errors**:
   - **Symptom**: Build fails with errors about Az.Bicep module not being available
   - **Solution**: The script attempts to install the module automatically, but you may need to ensure the build agent has permissions to install PowerShell modules

2. **Variable Inconsistencies Detected**:
   - **Symptom**: Build warns or fails with "Variable has inconsistencies in folders"
   - **Solution**: Update the parameter descriptions to be consistent across modules where the same parameter is used

3. **Regular Expression Issues**:
   - **Symptom**: Not all parameters are being detected or compared correctly
   - **Solution**: The detection pattern may need adjustment for certain parameter styles; review the PowerShell script for potential updates

4. **False Positives**:
   - **Symptom**: The check reports inconsistencies for parameters that should be different
   - **Solution**: Consider refactoring to use different parameter names if they truly represent different concepts

## Related Templates

- Variable Compliance Terraform Template: [YAML](./variable-compliance-terraform-template.yml) | [Documentation](./variable-compliance-terraform-template.md) - Similar functionality but for Terraform files
- Matrix Folder Check Template: [YAML](./matrix-folder-check-template.yml) | [Documentation](./matrix-folder-check-template.md) - Detects changes in repository structure
- Docs Check Template: [YAML](./docs-check-template.yml) | [Documentation](./docs-check-template.md) - Validates documentation quality

## Learn More

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- [Azure DevOps Pipeline Templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
- [PowerShell Az.Bicep Module](https://learn.microsoft.com/powershell/module/az.bicep/)
- [Reusable Infrastructure as Code](https://learn.microsoft.com/azure/architecture/framework/devops/automation-infrastructure)
- [Repository Structure Guide](/README.md)
