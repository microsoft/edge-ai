# Resource Provider PowerShell Tests

A reusable GitHub workflow that validates PowerShell scripts for Azure resource provider registration and unregistration using Pester tests, ensuring their functionality and reliability.

## Overview

This workflow is designed to run Pester tests against PowerShell scripts that manage Azure resource provider registration. It automates the testing process, publishes the results for review, and integrates with GitHub's interface to provide visibility into test outcomes. The workflow is particularly useful for maintaining the quality of scripts that handle subscription-level resource provider enablement.

## Features

- **Automated Pester Testing**: Executes PowerShell tests in the specified directory using the Pester framework
- **Test Result Artifacts**: Saves test results as artifacts for later examination and troubleshooting
- **GitHub Interface Integration**: Publishes test results directly to the GitHub interface for immediate visibility
- **Configurable Testing Paths**: Allows customization of working directory and test results output path
- **Conditional Execution**: Can be conditionally triggered based on file changes in PR validation workflows

## Parameters

| Parameter             | Type   | Required | Default                          | Description                                                |
|-----------------------|--------|----------|----------------------------------|------------------------------------------------------------|
| `working-directory`   | string | No       | `'src/azure-resource-providers'` | Directory containing the resource provider scripts to test |
| `test-results-output` | string | No       | `'PWSH-TEST-RESULTS.xml'`        | Path to output PowerShell test results in NUnit format     |

## Outputs

| Output Variable | Description                                                                                                                | Example |
|-----------------|----------------------------------------------------------------------------------------------------------------------------|---------|
| None            | The workflow doesn't expose output variables directly, but publishes test results as artifacts and to the GitHub interface | N/A     |

## Dependencies

This template may depend on the following:

- **Required GitHub Actions**: actions/checkout@v4, actions/upload-artifact@v4, EnricoMi/publish-unit-test-result-action@v2
- **Required Scripts**: Requires the `Invoke-Pester.ps1` script in the scripts directory
- **Required Testing Framework**: Pester framework for PowerShell
- **Required Agent OS**: Linux (runs on ubuntu-latest)

## Usage

### Basic Usage

```yaml
# Basic implementation with default parameters
pwsh-tests:
  name: PowerShell Provider Tests
  uses: ./.github/workflows/resource-provider-pwsh-tests.yml
```

### Advanced Usage

```yaml
# Advanced implementation with custom parameters
pwsh-tests-custom:
  name: Custom PowerShell Provider Tests
  uses: ./.github/workflows/resource-provider-pwsh-tests.yml
  with:
    working-directory: 'custom/path/to/scripts'
    test-results-output: 'custom-test-results.xml'
```

## Implementation Details

The workflow implements a single job that executes PowerShell tests and publishes results:

1. **Repository Checkout**: Checks out the repository with full history
2. **Test Execution**: Runs the Pester tests using the `Invoke-Pester.ps1` script in the specified directory
3. **Result Publishing**: Publishes the test results as artifacts for later review
4. **GitHub Integration**: Displays test results directly in the GitHub interface via a specialized action

### Key Components

- **Pester Test Runner**: Uses the `Invoke-Pester.ps1` script to execute tests in a standardized way
- **Test Results Publisher**: Publishes test results in NUnit format for integration with GitHub
- **Windows Runner**: Executes on a Windows environment to properly run PowerShell scripts

### Error Handling

The workflow uses the `if: always()` condition to ensure that test results are published even if tests fail, making it easier to diagnose issues when they occur.

## Examples

### Example 1: Usage in PR Validation

```yaml
# Usage in PR validation when PowerShell scripts have changed
pwsh-provider-tests:
  name: PowerShell Provider Tests
  needs: [mega-linter, changes]
  if: needs.changes.outputs.changesInRpEnablementPwsh == 'true'
  uses: ./.github/workflows/resource-provider-pwsh-tests.yml
  with:
    working-directory: 'src/azure-resource-providers'
    test-results-output: 'PWSH-TEST-RESULTS.xml'
```

### Example 2: Usage in Main Workflow

```yaml
# Usage in main workflow for regular validation
pwsh-provider-tests-main:
  name: PowerShell Provider Tests (Main)
  uses: ./.github/workflows/resource-provider-pwsh-tests.yml
  with:
    working-directory: 'src/azure-resource-providers'
    test-results-output: 'main-pwsh-test-results.xml'
```

## Troubleshooting

Common issues and their solutions:

1. **Missing Pester Tests**: The workflow fails with no test results
   - **Solution**: Ensure that Pester test files (ending in `.Tests.ps1`) exist in the specified directory

2. **Invoke-Pester.ps1 Not Found**: The workflow fails during the Pester run step
   - **Solution**: Verify that the `Invoke-Pester.ps1` script exists in the `/scripts` directory of the repository

3. **Failed Tests**: Tests are executed but some fail
   - **Solution**: Review the test results in the GitHub interface and the published artifacts to identify specific failures

## Related Templates

- PR Validation Workflow: [YAML](../workflows/pr-validation.yml) | [Documentation](./pr-validation.md) - Uses this template conditionally for PR validation
- Main Branch CI/CD: [YAML](../workflows/main.yml) | [Documentation](./main.md) - Can also use this template for regular validation

## Learn More

- [Pester Testing Framework](https://pester.dev/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Azure Resource Providers Documentation](https://learn.microsoft.com/azure/azure-resource-manager/management/resource-providers-and-types)
- [PowerShell in GitHub Actions](https://github.com/PowerShell/PowerShell/tree/master/docs/hosting/GitHubActions)
- [Azure IoT Operations Documentation](https://learn.microsoft.com/azure/iot-operations/)
