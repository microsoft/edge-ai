# Docs Check

This workflow validates documentation standards across the codebase to ensure all Terraform modules are properly documented and documentation stays in sync with code.

## Overview

The Docs Check workflow is designed to maintain high-quality documentation throughout the repository. It performs two primary functions: verifying that Terraform module documentation is current by using terraform-docs, and identifying links that contain language-specific paths which may become outdated when documentation is updated for different languages. This workflow helps ensure that documentation remains accurate, up-to-date, and useful for all users.

## Features

- **Documentation Synchronization**: Verifies Terraform module documentation is current using terraform-docs
- **Language Path Validation**: Identifies links containing language-specific paths (e.g., 'en-us')
- **Issue Annotation**: Creates GitHub annotations directly on the PR for issues found
- **Configurable Severity**: Can be set to either warn or fail the build when issues are detected
- **Summary Reporting**: Generates a comprehensive summary report of findings

## Parameters

| Parameter              | Type    | Required | Default   | Description                                                 |
|------------------------|---------|----------|-----------|-------------------------------------------------------------|
| `break_build`          | Boolean | No       | `false`   | Whether to fail the workflow on documentation issues        |
| `terraformDocsVersion` | String  | No       | `v0.19.0` | Version of terraform-docs to use for checking documentation |

### Environment Variables

| Environment Variable     | Default                                            | Description                                                   |
|--------------------------|----------------------------------------------------|---------------------------------------------------------------|
| `TERRAFORM_DOCS_VERSION` | Value from input parameters, defaults to `v0.19.0` | Version of terraform-docs to use for checking documentation   |
| `BREAK_BUILD`            | Value from input parameters, defaults to `false`   | Controls whether to fail the workflow on documentation issues |

## Outputs

| Output Variable | Description                                        |
|-----------------|----------------------------------------------------|
| N/A             | This workflow does not expose any output variables |

## Dependencies

This template depends on the following:

- **Required GitHub Actions**: `actions/checkout@v4`, `actions/setup-python@v4`
- **Required External Tools**: terraform-docs
- **Required Scripts**: scripts/install-terraform-docs.sh, scripts/tf-docs-check.sh, scripts/link-lang-check.py

## Usage

### Basic Usage

The workflow runs automatically on pull requests to main branch:

```yaml
# Runs automatically on PR to main branch
# No manual configuration needed
```

### Advanced Usage

Manually trigger the workflow with custom settings:

```yaml
# Manually triggered via GitHub Actions UI
# Can be configured to break the build on documentation issues
```

## Implementation Details

The workflow operates in multiple steps:

1. **Code Checkout**: Retrieves the repository's files with full git history
2. **Python Setup**: Configures Python 3.11 environment
3. **terraform-docs Installation**: Installs specified version of terraform-docs
4. **Documentation Check**: Runs the tf-docs-check.sh script to identify documentation that's out of sync with code
5. **Language Path Check**: Executes link-lang-check.py to find URLs with language-specific paths (en-us)
6. **Issue Reporting**: Creates annotations for any issues found, with configurable severity

### Key Components

- **terraform-docs Integration**: Uses terraform-docs to validate module documentation
- **Link Language Checker**: Custom Python script to scan for links with language-specific paths
- **GitHub Annotations**: Creates inline annotations on pull requests for issues

### Error Handling

By default, the workflow produces warnings but does not fail the build when issues are found. This can be modified by setting the `BREAK_BUILD` environment variable to `true`, which will make the workflow fail on any documentation issues.

## Examples

### Example 1: Standard Pull Request Run

When a pull request affects documentation files, the workflow runs automatically.

### Example 2: Manual Execution with Build Failure

```yaml
# Manual trigger with build breaking enabled
# Configure via GitHub UI:
# - Set BREAK_BUILD=true in the workflow environment
```

## Troubleshooting

Common issues and their solutions:

1. **Documentation Out of Sync**:
   - **Solution**: Run the update-all-terraform-docs.sh script in the project's src directory, then commit the changes

2. **Language-Specific Links**:
   - **Solution**: Replace links containing 'en-us' with language-neutral paths

3. **terraform-docs Installation Issues**:
   - **Solution**: Check if install-terraform-docs.sh has execution permissions or if the specified version exists

## Related Workflows

- Variable Compliance Terraform: [YAML](../.github/workflows/variable-compliance-terraform.yml) | [Documentation](./.github/docs/variable-compliance-terraform.md) - Checks Terraform variable consistency
- MegaLinter: [YAML](../.github/workflows/mega-linter.yml) | [Documentation](./.github/docs/mega-linter.md) - Provides broader code quality checks

## Learn More

- [terraform-docs Documentation](https://terraform-docs.io/)
- [Markdown Best Practices](https://www.markdownguide.org/basic-syntax/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Repository Structure Guide](/README.md)
