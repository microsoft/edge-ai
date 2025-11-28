---
title: Bicep Documentation Check Template
description: Azure DevOps pipeline template for validating Bicep documentation quality and consistency
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: concept
estimated_reading_time: 7
keywords:
  - bicep
  - documentation validation
  - azure devops
  - pipeline template
  - infrastructure as code
  - documentation standards
  - link validation
  - build automation
  - code quality
  - documentation sync
  - module documentation
  - language path validation
  - internationalization
---

This template provides automated tools for validating documentation quality across the
repository, ensuring Bicep documentation is consistent with the code and
identifying problematic URL patterns that could cause internationalization issues.

## Overview

The Documentation Check Template ensures documentation standards are maintained
throughout the codebase by running automated checks during the CI/CD pipeline. It
focuses on two main areas: validating that Bicep module documentation matches the
actual code implementation, and scanning for URLs with language-specific paths that
could impair internationalization efforts. These checks help maintain high
documentation quality and consistency across the repository.

## Features

- **Bicep Documentation Validation**: Ensures Bicep module documentation stays in sync with the code
- **Language Path Detection**: Identifies URLs with language-specific paths ('en-us') that could cause internationalization issues
- **Automated Remediation Guidance**: Provides clear instructions for fixing documentation issues
- **Configurable Severity**: Can be set to produce warnings or break the build based on requirements
- **Custom Documentation Generator**: Uses custom Python script to generate consistent Bicep documentation

## Parameters

| Parameter     | Type    | Required | Default                                                         | Description                                                                |
|---------------|---------|----------|-----------------------------------------------------------------|----------------------------------------------------------------------------|
| `dependsOn`   | object  | No       | `[]`                                                            | Jobs this docs check job depends on                                        |
| `displayName` | string  | No       | `'Bicep Documentation Check'`                                   | Custom display name for the job                                            |
| `condition`   | string  | No       | `'succeeded()'`                                                 | Condition to run this job                                                  |
| `breakBuild`  | boolean | No       | `false`                                                         | Whether to treat documentation issues as errors (true) or warnings (false) |
| `pool`        | object  | No       | `{ name: 'ai-on-edge-managed-pool', vmImage: 'ubuntu-latest' }` | Configuration for the agent pool                                           |

## Outputs

This template doesn't produce formal pipeline outputs, but it generates build warnings or errors for each detected documentation issue.

## Dependencies

This template depends on the following:

- **Required Tools**:
- Python 3.11
- Python packages specified in requirements.txt
- jq command-line JSON processor
- Azure CLI with Bicep extension
- **Required Scripts**:
- `./scripts/update-all-bicep-docs.sh`: For updating all Bicep documentation
  - `scripts/generate-bicep-docs.py`: Custom Python script for generating Bicep documentation (called by the above script)
- `scripts/bicep-docs-check.sh`: For checking if Bicep docs need updating
- `scripts/link-lang-check.py`: For detecting URLs with language paths

## Usage

### Basic Usage

```yaml
# Basic implementation with minimal parameters
  - template: .azdo/templates/docs-check-bicep-template.yml
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
  - template: .azdo/templates/docs-check-bicep-template.yml
  parameters:
    dependsOn: [MegaLinter]
    displayName: "Bicep Documentation Quality Validation"
    condition: succeeded('MegaLinter')
    breakBuild: true
    pool:
      name: "custom-pool"
      vmImage: "ubuntu-latest"
```

## Implementation Details

The template executes two main validation processes:

1. **Bicep Documentation Check**:

   - Runs the `bicep-docs-check.sh` script to detect outdated documentation
   - Generates warnings or errors if documentation needs updating

2. **Link Language Path Check**:
   - Runs the `link-lang-check.py` script to scan for URLs with 'en-us' path segments
   - Parses the JSON output to identify problematic URLs
   - Creates source-linked warnings with file and line information

### Key Components

- **update-all-bicep-docs.sh**: Script that updates all Bicep documentation in the repository
- **generate-bicep-docs.py**: Custom Python script for generating consistent documentation from Bicep modules (called by the above script)
- **bicep-docs-check.sh**: Script that checks if Bicep documentation is up-to-date
- **link-lang-check.py**: Python script that detects URLs with language-specific paths

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
      - template: .azdo/templates/docs-check-bicep-template.yml
```

### Example 2: Strict Documentation Check

```yaml
# Documentation check that breaks the build on issues
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/docs-check-bicep-template.yml
        parameters:
          displayName: "Strict Bicep Documentation Check"
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

      - template: .azdo/templates/docs-check-bicep-template.yml
        parameters:
          dependsOn: [MegaLinter]
          condition: succeeded('MegaLinter')
```

## Troubleshooting

Common issues and their solutions:

1. **Python Package Dependencies**:

   - **Symptom**: Build fails with errors about missing Python packages
   - **Solution**: Ensure the pipeline has access to install packages from requirements.txt or add them to the agent's pre-installed packages

2. **Outdated Bicep Documentation**:

   - **Symptom**: Build warns or fails with "Bicep auto-gen documentation needs to be updated"
   - **Solution**: Run `./scripts/update-all-bicep-docs.sh` locally, commit the changes, and push

   **Note**: The `update-all-bicep-docs.sh` script uses `scripts/generate-bicep-docs.py` behind the scenes to generate the documentation for all Bicep modules in the repository.

3. **URLs with Language Paths**:

   - **Symptom**: Build warns or fails with "URL contains language path segment (en-us)"
   - **Solution**: Either manually edit the links to remove 'en-us/' or run `python3 scripts/link-lang-check.py -f` to automatically fix all occurrences

4. **Script Execution Permissions**:
   - **Symptom**: Build fails with permission denied errors when running scripts
   - **Solution**: Ensure scripts have execute permissions (`chmod +x scripts/*.sh`)

## Related Templates

- MegaLinter Template: [YAML](/.azdo/templates/megalinter-template.yml) | [Documentation](./megalinter-template.md) - Provides comprehensive linting for various file types
- Variable Compliance Bicep Template: [YAML](/.azdo/templates/variable-compliance-bicep-template.yml) | [Documentation](./variable-compliance-bicep-template.md) - Ensures consistent parameter definitions
- Docs Check Terraform Template: [YAML](/.azdo/templates/docs-check-terraform-template.yml) | [Documentation](./docs-check-terraform-template.md) - Similar template for checking Terraform documentation

## Learn More

- [Bicep Documentation](https://learn.microsoft.com/azure/azure-resource-manager/bicep/)
- [Microsoft Internationalization Guidelines](https://learn.microsoft.com/style-guide/global-communications/)
- [Azure DevOps Pipeline Templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
- [Bicep Documentation Best Practices](https://learn.microsoft.com/azure/azure-resource-manager/bicep/best-practices)
- [Azure DevOps YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
