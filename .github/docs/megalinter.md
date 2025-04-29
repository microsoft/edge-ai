# MegaLinter

This workflow runs MegaLinter to perform static analysis across the codebase, ensuring code quality and adherence to coding standards.

## Overview

MegaLinter is a robust static analysis tool that analyzes code in the repository across multiple languages and formats. This workflow automates the execution of MegaLinter, which helps identify issues, enforce coding standards, and maintain code quality. It runs checks for syntax errors, style violations, security vulnerabilities, and more across all files in the repository.

## Features

- **Multi-language Support**: Validates code across multiple languages and file formats
- **Pull Request Integration**: Automatically runs on pull requests to main branch
- **Detailed Reporting**: Posts comments on PRs with linting results for easy review
- **Artifact Generation**: Uploads detailed linting reports as workflow artifacts
- **Configurable Behavior**: Controllable via environment variables and configuration files

## Parameters

| Parameter | Type | Required | Default | Description                                                           |
|-----------|------|----------|---------|-----------------------------------------------------------------------|
| N/A       | N/A  | N/A      | N/A     | This workflow uses environment variables instead of direct parameters |

### Environment Variables

| Environment Variable                      | Default     | Description                                                      |
|-------------------------------------------|-------------|------------------------------------------------------------------|
| `VALIDATE_ALL_CODEBASE`                   | Conditional | Controls whether to validate the entire codebase or just changes |
| `GITHUB_COMMENT_REPORTER`                 | `true`      | Enables PR commenting with results                               |
| `GITHUB_STATUS_REPORTER`                  | `true`      | Reports status checks to GitHub                                  |
| `GITHUB_COMMENT_REPORTER_ON_CHANGES_ONLY` | `true`      | Only comments on files with changes                              |

## Outputs

| Output Variable | Description                                        |
|-----------------|----------------------------------------------------|
| N/A             | This workflow does not expose any output variables |

## Dependencies

This template depends on the following:

- **Required GitHub Actions**: `actions/checkout@v4`, `actions/upload-artifact@v4`
- **Required External Tools**: MegaLinter (oxsecurity/megalinter@v8)
- **Required Permissions**: `contents: write`, `pull-requests: write`, `packages: read`

## Usage

### Basic Usage

The workflow runs automatically on pull requests to the main branch:

```yaml
# This triggers automatically on pull requests to main
# No manual configuration needed in workflow runs
```

### Advanced Usage

To customize MegaLinter behavior, create a `.mega-linter.yml` file at the root of your repository:

```yaml
# Example .mega-linter.yml configuration
DISABLE:
  - COPYPASTE  # Disable copy-paste detection
  - SPELL      # Disable spell checking
ENABLE_LINTERS:
  - TERRAFORM_TERRASCAN  # Enable specific linters
  - MARKDOWN_MARKDOWNLINT
```

## Implementation Details

The workflow consists of the following steps:

1. **Code Checkout**: Retrieves the repository's files
2. **MegaLinter Execution**: Runs the MegaLinter analysis with specified configuration
3. **Report Artifact Upload**: Archives the linting reports and logs for later review

### Key Components

- **MegaLinter Configuration**: Controls which linters are enabled and their behavior
- **GitHub Reporter**: Posts comments on PRs showing linting issues
- **Artifact Generation**: Creates downloadable reports for detailed review

### Error Handling

The workflow uploads artifacts regardless of success or failure, ensuring that linting reports are always available for troubleshooting. Issues found by MegaLinter are reported in multiple formats:

- GitHub status checks
- PR comments
- Detailed reports in artifact storage

## Examples

### Example 1: Running with Default Settings

The workflow runs automatically on pull requests with default settings.

### Example 2: Customized MegaLinter Configuration

Create a `.megalinter.yml` file in your repository root:

```yaml
# .mega-linter.yml
DISABLE_LINTERS:
  - YAML_YAMLLINT
SHOW_ELAPSED_TIME: true
FILEIO_REPORTER: true
```

## Troubleshooting

Common issues and their solutions:

1. **Too Many Linting Errors**:
   - **Solution**: Create a `.megalinter.yml` file to disable specific linters or rules

2. **Long Execution Time**:
   - **Solution**: Use `VALIDATE_ALL_CODEBASE: false` to only check changed files, or disable heavy linters

## Related Workflows

- Variable Compliance Terraform: [YAML](../workflows/variable-compliance-terraform.yml) | [Documentation](./variable-compliance-terraform.md) - Checks Terraform variable consistency
- Docs Check (Terraform): [YAML](../workflows/docs-check-terraform.yml) | [Documentation](./docs-check-terraform.md) - Ensures documentation quality
- Docs Check (Bicep): [YAML](../workflows/docs-check-bicep.yml) | [Documentation](./docs-check-bicep.md) - Ensures documentation quality

## Learn More

- [MegaLinter Documentation](https://megalinter.io)
- [MegaLinter Configuration Options](https://megalinter.io/latest/configuration/)
- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Repository Structure Guide](/README.md)
