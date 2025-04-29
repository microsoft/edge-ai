# Bicep Variable Compliance

This workflow checks for consistency in Bicep parameter definitions across modules, ensuring that parameters with the same name have consistent descriptions, types, and default values.

## Overview

The Bicep Variable Compliance workflow analyzes all Bicep files in the repository for parameter definitions. It then compares these definitions across different modules to identify any inconsistencies in terms of descriptions, types, or default values. This ensures standardization across the entire infrastructure codebase and prevents unexpected behavior due to inconsistent parameter usage.

## Features

- **Automated Parameter Scanning**: Scans all Bicep files in the repository for parameter definitions
- **Cross-Module Consistency Checks**: Compares parameter definitions across different modules for consistency
- **Detailed Issue Reporting**: Reports inconsistencies as warnings or errors in the GitHub Action logs
- **Configurable Failure Mode**: Can be configured to either fail the workflow or just warn if inconsistencies are found
- **Structured Reporting**: Clearly identifies modules where parameters are inconsistently defined

## Parameters

| Parameter     | Type    | Required | Default | Description                                               |
|---------------|---------|----------|---------|-----------------------------------------------------------|
| `break_build` | boolean | No       | `false` | Whether to fail the workflow if inconsistencies are found |

## Outputs

| Output Variable    | Description                                                    |
|--------------------|----------------------------------------------------------------|
| `mismatches_found` | Boolean indicating if any parameter inconsistencies were found |

## Dependencies

This workflow depends on the following:

- **Required GitHub Actions**: `actions/checkout@v4`, `actions/setup-powershell@v1`
- **Required Scripts**: scripts/Bicep-Var-Compliance-Check.ps1

## Usage

### Basic Usage

```yaml
# Run with default settings through GitHub UI or on PR
# This will report inconsistencies as warnings but not fail the build
```

### Advanced Usage

```yaml
# Run with custom parameters
name: Strict Bicep Parameter Check
uses: ./.github/workflows/variable-compliance-bicep.yml
with:
  break_build: true
```

## Implementation Details

The workflow operates in several key steps:

1. **Code Checkout**: Retrieves the repository's files
2. **PowerShell Setup**: Configures PowerShell environment
3. **Compliance Check**: Runs the Bicep-Var-Compliance-Check.ps1 script to identify inconsistencies
4. **Result Processing**: Analyzes the output and creates GitHub annotations (warnings or errors)
5. **Result Summary**: Creates a summary of all detected inconsistencies

### Error Handling

The workflow can be configured to either fail the build or just provide warnings when inconsistencies are found:

- With `break_build: false`, the workflow will complete successfully but post warnings
- With `break_build: true`, the workflow will fail if any inconsistencies are found

## Examples

### Example 1: Default Run on Pull Request

Pull requests to the main branch automatically trigger this workflow with default settings.

### Example 2: Manual Run with Build Breaking

```yaml
# Manual trigger with maximum strictness
name: Bicep Parameters Strict Check
uses: ./.github/workflows/variable-compliance-bicep.yml
with:
  break_build: true
```

## Troubleshooting

Common issues and their solutions:

1. **PowerShell Module Errors**:
   - **Solution**: Ensure the workflow has permissions to install PowerShell modules, or adjust the workflow to use a container with modules pre-installed

2. **Script Execution Policy**:
   - **Solution**: The workflow may need to use `-ExecutionPolicy Bypass` when running PowerShell scripts

3. **Too Many Inconsistencies**:
   - **Solution**: Run the workflow with `break_build: false` first to get a complete list of issues without failing the build

4. **False Positives**:
   - **Solution**: Consider refactoring to use different parameter names if they truly represent different concepts

## Related Workflows

- Variable Compliance Terraform: [YAML](../workflows/variable-compliance-terraform.yml) | [Documentation](./variable-compliance-terraform.md) - Similar functionality but for Terraform files
- Docs Check (Terraform): [YAML](../workflows/docs-check-terraform.yml) | [Documentation](./docs-check-terraform.md) - Ensures documentation quality
- Docs Check (Bicep): [YAML](../workflows/docs-check-bicep.yml) | [Documentation](./docs-check-bicep.md) - Ensures documentation quality
- AIO Version Checker: [YAML](../workflows/aio-version-checker.yml) | [Documentation](./aio-version-checker.md) - Validates Azure IoT Operations component versions

## Learn More

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Bicep Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Repository Structure Guide](/README.md)
