# Terraform Documentation Check Template

This template provides automated tools for validating documentation quality across the
repository, ensuring Terraform documentation is consistent with the code and
identifying problematic URL patterns that could cause internationalization issues.

## Overview

The Documentation Check Template ensures documentation standards are maintained
throughout the codebase by running automated checks during the CI/CD pipeline. It
focuses on two main areas: validating that Terraform module documentation matches the
actual code implementation, and scanning for URLs with language-specific paths that
could impair internationalization efforts. These checks help maintain high
documentation quality and consistency across the repository.

## Features

- **Terraform Documentation Validation**: Ensures Terraform module documentation stays in sync with the code
- **Language Path Detection**: Identifies URLs with language-specific paths ('en-us') that could cause internationalization issues
- **Automated Remediation Guidance**: Provides clear instructions for fixing documentation issues
- **Configurable Severity**: Can be set to produce warnings or break the build based on requirements
- **Terraform-docs Integration**: Leverages industry-standard tools for documentation management

## Parameters

| Parameter              | Type    | Required | Default                                                         | Description                                                                |
|------------------------|---------|----------|-----------------------------------------------------------------|----------------------------------------------------------------------------|
| `dependsOn`            | object  | No       | `[]`                                                            | Jobs this docs check job depends on                                        |
| `displayName`          | string  | No       | `'Terraform Documentation Check'`                               | Custom display name for the job                                            |
| `condition`            | string  | No       | `'succeeded()'`                                                 | Condition to run this job                                                  |
| `terraformDocsVersion` | string  | No       | `'v0.19.0'`                                                     | Version of terraform-docs to install                                       |
| `breakBuild`           | boolean | No       | `false`                                                         | Whether to treat documentation issues as errors (true) or warnings (false) |
| `pool`                 | object  | No       | `{ name: 'ai-on-edge-managed-pool', vmImage: 'ubuntu-latest' }` | Configuration for the agent pool                                           |

## Outputs

This template doesn't produce formal pipeline outputs, but it generates build warnings or errors for each detected documentation issue.

## Dependencies

This template depends on the following:

- **Required Tools**:
  - terraform-docs (installed during execution)
  - Python 3.11
  - jq command-line JSON processor
- **Required Scripts**:
  - `scripts/install-terraform-docs.sh`: For installing terraform-docs
  - `scripts/tf-docs-check.sh`: For checking if Terraform docs need updating
  - `scripts/link-lang-check.py`: For detecting URLs with language paths
- **Required Files**:
  - `.terraform-docs.yml`: Configuration file for terraform-docs format and behavior

## Usage

### Basic Usage

```yaml
# Basic implementation with minimal parameters
- template: .azdo/templates/docs-check-terraform-template.yml
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
- template: .azdo/templates/docs-check-terraform-template.yml
  parameters:
    dependsOn: [MegaLinter]
    displayName: "Documentation Quality Validation"
    condition: succeeded('MegaLinter')
    terraformDocsVersion: "v0.17.0"
    breakBuild: true
    pool:
      name: "custom-pool"
      vmImage: "ubuntu-latest"
```

## Implementation Details

The template executes two main validation processes:

1. **Terraform Documentation Check**:

   - Installs terraform-docs using the specified version
   - Runs the `tf-docs-check.sh` script to detect outdated documentation
   - Generates warnings or errors if documentation needs updating

2. **Link Language Path Check**:
   - Runs the `link-lang-check.py` script to scan for URLs with 'en-us' path segments
   - Parses the JSON output to identify problematic URLs
   - Creates source-linked warnings with file and line information

### Key Components

- **terraform-docs**: Industry-standard tool for generating consistent documentation from Terraform modules
- **tf-docs-check.sh**: Script that checks if Terraform documentation is up-to-date
- **link-lang-check.py**: Python script that detects URLs with language-specific paths
- **.terraform-docs.yml**: Configuration file that controls documentation format and structure

### Error Handling

The template handles documentation issues according to the `breakBuild` parameter:

- When `breakBuild` is `false` (default), issues generate warnings but allow the build to continue
- When `breakBuild` is `true`, issues cause the build to fail, enforcing documentation standards

## Examples

### Example 1: Basic Documentation Check

```yaml
# Simple documentation check with warnings
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/docs-check-terraform-template.yml
```

### Example 2: Strict Documentation Check

```yaml
# Documentation check that breaks the build on issues
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/docs-check-terraform-template.yml
        parameters:
          displayName: "Strict Documentation Check"
          breakBuild: true
```

### Example 3: Integration with Other Validation Jobs

```yaml
# Documentation check as part of a larger validation process
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/megalinter-template.yml
        # MegaLinter parameters...

      - template: .azdo/templates/docs-check-terraform-template.yml
        parameters:
          dependsOn: [MegaLinter]
          condition: succeeded('MegaLinter')
```

## Troubleshooting

Common issues and their solutions:

1. **Missing terraform-docs**:

   - **Symptom**: Build fails with errors about terraform-docs not being available
   - **Solution**: Ensure the `install-terraform-docs.sh` script is in the correct location and has execute permissions

2. **Outdated Terraform Documentation**:

   - **Symptom**: Build warns or fails with "Terraform auto-gen documentation needs to be updated"
   - **Solution**: Run `./scripts/update-all-terraform-docs.sh` locally, commit the changes, and push

3. **URLs with Language Paths**:

   - **Symptom**: Build warns or fails with "URL contains language path segment (en-us)"
   - **Solution**: Either manually edit the links to remove 'en-us/' or run `python3 scripts/link-lang-check.py -f` to automatically fix all occurrences

4. **Script Execution Permissions**:
   - **Symptom**: Build fails with permission denied errors when running scripts
   - **Solution**: Ensure scripts have execute permissions (`chmod +x scripts/*.sh`)

## Related Templates

- MegaLinter Template: [YAML](./megalinter-template.yml) | [Documentation](./megalinter-template.md) - Provides comprehensive linting for various file types
- Variable Compliance Terraform Template: [YAML](./variable-compliance-terraform-template.yml) | [Documentation](./variable-compliance-terraform-template.md) - Ensures consistent variable definitions
- Cluster Test Terraform Template: [YAML](./cluster-test-terraform-template.yml) | [Documentation](./cluster-test-terraform-template.md) - Tests Terraform component functionality

## Learn More

- [Terraform Docs Documentation](https://terraform-docs.io/)
- [Microsoft Internationalization Guidelines](https://learn.microsoft.com/style-guide/global-communications/)
- [Azure DevOps Pipeline Templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
- [Terraform Documentation Best Practices](https://www.terraform.io/docs/extend/best-practices/documentation.html)
- [Azure DevOps YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)
