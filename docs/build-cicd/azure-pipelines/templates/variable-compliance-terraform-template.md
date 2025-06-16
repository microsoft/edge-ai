---
title: Terraform Variable Compliance Template
description: Azure DevOps pipeline template for ensuring consistent variable definitions across Terraform modules
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
estimated_reading_time: 7
keywords:
  - terraform
  - variable compliance
  - consistency checking
  - azure devops
  - pipeline template
  - infrastructure as code
  - cross-module validation
  - terraform-docs
  - python script
  - build automation
  - code quality
  - standardization
  - variable definitions
  - compliance validation
---

This template provides an automated process for ensuring consistent variable
definitions across Terraform modules in your repository, detecting inconsistencies in
variable descriptions, types, default values, and validation rules.

## Overview

The Terraform Variable Compliance Template detects and reports inconsistencies in
definitions across Terraform modules. By analyzing how variables with the same name are
defined in different modules, it helps maintain high code quality and reduces confusion
for contributing developers. The checker scans all Terraform files in the repository,
extracts variable definitions, compares them for consistency, and reports any
discrepancies as build warnings or errors, ensuring that your infrastructure code
remains clean and maintainable.

## Features

- **Variable Definition Consistency**: Ensures variables with the same name have consistent descriptions, types, and defaults
- **Cross-Module Analysis**: Compares variable definitions across all Terraform modules in the repository
- **Detailed Reporting**: Provides specific information about inconsistencies, including which modules and what differences
- **Configurable Severity**: Can be set to produce warnings or break the build based on compliance requirements
- **Terraform-docs Integration**: Uses industry-standard tools to extract and analyze variable definitions
- **Pipeline Integration**: Seamlessly integrates with Azure DevOps build pipelines
- **Structured Output**: Generates clear, actionable information about detected inconsistencies

## Parameters

| Parameter              | Type    | Required | Default                                                         | Description                                                                  |
|------------------------|---------|----------|-----------------------------------------------------------------|------------------------------------------------------------------------------|
| `dependsOn`            | object  | No       | `[]`                                                            | Job dependencies, typically pointing to the preceding job                    |
| `displayName`          | string  | No       | `'Terraform Variable Compliance Check'`                         | Custom display name for the job in the pipeline                              |
| `condition`            | string  | No       | `succeeded()`                                                   | Execution condition determining when this template should run                |
| `terraformDocsVersion` | string  | No       | `'v0.20.0'`                                                     | Version of terraform-docs to use for parsing variables                       |
| `breakBuild`           | boolean | No       | `false`                                                         | Whether to treat inconsistent variables as errors (true) or warnings (false) |
| `pool`                 | object  | No       | `{ name: 'ai-on-edge-managed-pool', vmImage: 'ubuntu-latest' }` | Agent pool configuration                                                     |

## Outputs

This template doesn't produce formal pipeline outputs, but it generates build warnings or errors for each detected variable inconsistency.

## Dependencies

This template depends on the following:

- **Required Tools**:
- terraform-docs (installed during execution)
- Python 3.11
- jq command-line JSON processor
- **Required Scripts**:
- `scripts/install-terraform-docs.sh`: For installing terraform-docs
- `scripts/tf-vars-compliance-check.py`: For checking variable consistency
- **Required Repository Structure**:
- Terraform modules with variable definitions
- Consistent organization of modules in `/src` and `/blueprints` directories

## Usage

### Basic Usage

```yaml
# Basic implementation with minimal parameters
  - template: .azdo/templates/variable-compliance-terraform-template.yml
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
  - template: .azdo/templates/variable-compliance-terraform-template.yml
  parameters:
    dependsOn: [MegaLinter]
    displayName: "Variable Definition Compliance"
    condition: succeeded('MegaLinter')
    terraformDocsVersion: "v0.20.0"
    breakBuild: true
    pool:
      name: 'custom-pool'
      vmImage: 'ubuntu-latest'
```

## Implementation Details

The template executes a series of steps to analyze and compare variable definitions:

1. **Setup Environment**: Checks out code and sets up Python 3.11
2. **Install terraform-docs**: Installs the specified version of terraform-docs tool
3. **Variable Analysis**: Runs the Python script to analyze variable definitions
4. **Result Processing**: Parses the JSON output and creates build warnings/errors for inconsistencies

### Key Components

- **tf-vars-compliance-check.py**: Python script that analyzes Terraform variable definitions
- **terraform-docs**: Tool that extracts structured information from Terraform files
- **Variable Database**: In-memory database of all variables used across modules
- **Comparison Logic**: Algorithms that compare variable attributes across different modules
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
      - template: .azdo/templates/variable-compliance-terraform-template.yml
```

### Example 2: Strict Variable Compliance Check

```yaml
# Variable compliance check that breaks the build on inconsistencies
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/variable-compliance-terraform-template.yml
        parameters:
          displayName: "Strict Variable Compliance"
          breakBuild: true
```

### Example 3: Integration with Matrix Folder Check

```yaml
# Variable compliance as part of a larger validation process
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      displayName: "Detect Changed Folders"

  - template: .azdo/templates/variable-compliance-terraform-template.yml
    parameters:
      dependsOn: MatrixBuildFolderCheck
      condition: succeeded('MatrixBuildFolderCheck')
```

## Troubleshooting

Common issues and their solutions:

1. **Missing terraform-docs**:
   - **Symptom**: Build fails with errors about terraform-docs not being available
   - **Solution**: Ensure the `install-terraform-docs.sh` script is in the correct location and has execute permissions

2. **Variable Inconsistencies Detected**:
   - **Symptom**: Build warns or fails with "Variable has inconsistencies in folders"
   - **Solution**: Update the variable definitions to be consistent across modules where the same variable is used

3. **Python Module Errors**:
   - **Symptom**: Build fails with Python import or module errors
   - **Solution**: Ensure required Python packages are available in the pipeline environment

4. **False Positives**:
   - **Symptom**: The check reports inconsistencies for variables that should be different
   - **Solution**: Consider refactoring to use different variable names if they truly represent different concepts

## Related Templates

- Docs Check Template: [YAML](/.azdo/templates/docs-check-terraform-template.yml) | [Documentation](./docs-check-terraform-template.md) - Validates documentation quality
- Matrix Folder Check Template: [YAML](/.azdo/templates/matrix-folder-check-template.yml) | [Documentation](./matrix-folder-check-template.md) - Detects changes in repository structure
- Cluster Test Terraform Template: [YAML](/.azdo/templates/cluster-test-terraform-template.yml) | [Documentation](./cluster-test-terraform-template.md) - Tests Terraform component functionality

## Learn More

- [Terraform Variable Syntax](https://www.terraform.io/language/values/variables)
- [terraform-docs Documentation](https://terraform-docs.io/)
- [Azure DevOps Pipeline Templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
- [Reusable Infrastructure as Code](https://learn.microsoft.com/azure/architecture/framework/devops/automation-infrastructure)
- [Repository Structure Guide](/README.md)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
