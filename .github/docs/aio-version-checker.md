# AIO Version Checker

This workflow validates that Azure IoT Operations component versions defined in the codebase match the latest published versions, to ensure deployments use current and compatible components.

## Overview

The Azure IoT Operations (AIO) Version Checker workflow is designed to keep your deployment infrastructure aligned with the latest officially released versions of AIO components. It scans Terraform and Bicep files for version definitions, compares them against official release manifests, and reports any mismatches. This ensures that deployments are using current, compatible components and helps maintain consistency across the infrastructure.

## Features

- **Multi-IaC Support**: Checks component versions in both Terraform and Bicep files
- **Version Comparison**: Compares local versions with latest versions from remote manifests
- **Train Validation**: Verifies component versions belong to consistent release trains
- **Detailed Annotations**: Generates GitHub annotations for version mismatches
- **Configurable Severity**: Can be set to either warn or fail the build when mismatches are detected
- **Summary Reporting**: Creates a comprehensive summary table of all version mismatches

## Parameters

| Parameter     | Type    | Required | Default | Description                                                 |
|---------------|---------|----------|---------|-------------------------------------------------------------|
| `iac-type`    | choice  | Yes      | `all`   | The IaC type to check: terraform, bicep, or all             |
| `break-build` | boolean | Yes      | `false` | Controls whether to fail the workflow on version mismatches |

## Outputs

| Output Variable    | Description                                             |
|--------------------|---------------------------------------------------------|
| `mismatches_found` | Boolean indicating if any version mismatches were found |

## Dependencies

This template depends on the following:

- **Required GitHub Actions**: `actions/checkout@v4`, `actions/setup-python@v5`
- **Required Python Packages**: hcl2, requests
- **Required Scripts**: scripts/aio-version-checker.py

## Usage

### Basic Usage

The workflow runs automatically on pull requests and pushes to main that affect IoT Ops files:

```yaml
# Automatically runs on PR or push to main that changes files in src/040-iot-ops/**
# No manual configuration needed
```

### Advanced Usage

Manually trigger the workflow with custom settings:

```yaml
# Manually triggered via Actions UI with specific parameters
name: Manual AIO Version Check
uses: ./.github/workflows/aio-version-checker.yml
with:
  iac-type: 'terraform'  # Only check Terraform files
  break-build: true  # Fail the workflow if mismatches are found
```

## Implementation Details

The workflow consists of the following key steps:

1. **Code Checkout**: Retrieves the repository's files
2. **Python Setup**: Configures Python 3.11 environment with caching for dependencies
3. **Dependency Installation**: Installs required Python packages
4. **Version Check Execution**: Runs the aio-version-checker.py script with specified parameters
5. **Result Analysis**: Processes the comparison results and generates appropriate annotations
6. **Summary Creation**: Builds a markdown summary table of all version mismatches
7. **Build Control**: Conditionally fails the build based on the break-build parameter

### Key Components

- **Version Checker Script**: Python script that compares local versions with remote manifests
- **IaC Type Filtering**: Ability to focus on either Terraform, Bicep, or both file types
- **GitHub Annotations**: Creates inline annotations on pull requests for mismatches
- **GitHub Summary**: Generates a detailed table in the workflow summary

### Error Handling

By default, the workflow produces warnings but does not fail the build when version mismatches are found. This behavior can be modified by setting the `break-build` parameter to `true`, which will cause the workflow to fail if any mismatches are detected.

## Examples

### Example 1: Checking All IaC Files

```yaml
# Check all IaC files (Terraform and Bicep)
name: Full AIO Version Check
uses: ./.github/workflows/aio-version-checker.yml
with:
  iac-type: 'all'
  break-build: false
```

### Example 2: Strict Terraform Check

```yaml
# Only check Terraform files with build breaking
name: Strict Terraform AIO Version Check
uses: ./.github/workflows/aio-version-checker.yml
with:
  iac-type: 'terraform'
  break-build: true
```

## Troubleshooting

Common issues and their solutions:

1. **Version Mismatches**:
   - **Solution**: Update the component versions in your Terraform and Bicep files to match the latest releases

2. **Manifest Access Issues**:
   - **Solution**: Ensure the workflow runner has network access to the remote manifest URLs

3. **File Pattern Mismatches**:
   - **Solution**: Check that your AIO component definitions are in the expected files and follow the expected format

## Related Workflows

- Variable Compliance Terraform: [YAML](../workflows/variable-compliance-terraform.yml) | [Documentation](./variable-compliance-terraform.md) - Checks Terraform variable consistency
- Docs Check (Terraform): [YAML](../workflows/docs-check-terraform.yml) | [Documentation](./docs-check-terraform.md) - Ensures documentation quality
- Docs Check (Bicep): [YAML](../workflows/docs-check-bicep.yml) | [Documentation](./docs-check-bicep.md) - Ensures documentation quality

## Learn More

- [Azure IoT Operations Documentation](https://learn.microsoft.com/azure/iot-operations/)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Repository Structure Guide](/README.md)
