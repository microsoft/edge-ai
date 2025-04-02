# Terraform Variable Compliance

This workflow checks for consistency in Terraform variable definitions across modules, ensuring that variables with the same name have consistent descriptions, types, and defaults.

## Overview

The Terraform Variable Compliance workflow analyzes all Terraform files in the repository for variable definitions. It then compares these definitions across different modules to identify any inconsistencies in terms of descriptions, types, or default values. This ensures standardization across the entire infrastructure codebase and prevents unexpected behavior due to inconsistent variable usage.

## Features

- **Automated Variable Scanning**: Scans all Terraform files in the repository for variable definitions
- **Cross-Module Consistency Checks**: Compares variable definitions across different modules for consistency
- **Detailed Issue Reporting**: Reports inconsistencies as warnings or errors in the GitHub Action logs
- **Configurable Failure Mode**: Can be configured to either fail the workflow or just warn if inconsistencies are found
- **Artifact Generation**: Uploads results as artifacts for detailed review

## Parameters

| Parameter                | Type   | Required | Default   | Description                                                                   |
|--------------------------|--------|----------|-----------|-------------------------------------------------------------------------------|
| `terraform_docs_version` | string | No       | `v0.16.0` | Version of terraform-docs to use for parsing Terraform variables              |
| `break_build`            | choice | No       | `false`   | Whether to fail the workflow if inconsistencies are found (`true` or `false`) |

## Outputs

| Output Variable | Description                                        |
|-----------------|----------------------------------------------------|
| N/A             | This workflow does not expose any output variables |

## Dependencies

This template depends on the following:

- **Required GitHub Actions**: `actions/checkout@v4`, `actions/setup-python@v4`, `actions/upload-artifact@v4`
- **Required External Tools**: terraform-docs
- **Required Scripts**: scripts/tf-vars-compliance-check.py

## Usage

### Basic Usage

```yaml
# Run with default settings through GitHub UI or on PR
# This uses default terraform-docs version and doesn't break the build on inconsistencies
```

### Advanced Usage

```yaml
# Run with custom parameters
name: Manual Terraform Variable Check
uses: ./.github/workflows/variable-compliance-terraform.yml
with:
  terraform_docs_version: 'v0.17.0'
  break_build: 'true'
```

## Implementation Details

The workflow operates in several key steps:

1. **Code Checkout**: Retrieves the repository's files
2. **Python Setup**: Configures Python 3.11 environment
3. **terraform-docs Installation**: Downloads and installs the specified version of terraform-docs
4. **Python Dependencies**: Installs required Python packages (jq, pyyaml)
5. **Compliance Check**: Runs the tf-vars-compliance-check.py script to identify inconsistencies
6. **Result Processing**: Analyzes the output and creates GitHub annotations (warnings or errors)
7. **Artifact Generation**: Uploads the detailed results as workflow artifacts

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
name: Terraform Variables Strict Check
uses: ./.github/workflows/variable-compliance-terraform.yml
with:
  terraform_docs_version: 'v0.16.0'
  break_build: 'true'
```

## Troubleshooting

Common issues and their solutions:

1. **terraform-docs Installation Failure**:
   - **Solution**: Check that the specified version exists in the terraform-docs GitHub releases

2. **Python Script Errors**:
   - **Solution**: Ensure Python dependencies are correctly installed and the script path is correct

3. **Too Many Inconsistencies**:
   - **Solution**: Run the workflow with `break_build: false` first to get a complete list of issues without failing the build

## Related Workflows

- Docs Check: [YAML](../.github/workflows/docs-check.yml) | [Documentation](./.github/docs/docs-check.md) - Also ensures documentation quality
- MegaLinter: [YAML](../.github/workflows/mega-linter.yml) | [Documentation](./.github/docs/mega-linter.md) - Provides broader code quality checks

## Learn More

- [Terraform Documentation](https://www.terraform.io/docs)
- [terraform-docs Documentation](https://terraform-docs.io/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Repository Structure Guide](/README.md)
