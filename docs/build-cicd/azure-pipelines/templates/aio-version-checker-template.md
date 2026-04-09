---
title: AIO Version Checker Template
description: Azure DevOps pipeline template for validating Azure IoT Operations component versions
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: concept
estimated_reading_time: 7
keywords:
  - azure iot operations
  - aio
  - version validation
  - component versions
  - azure devops
  - pipeline template
  - terraform
  - bicep
  - version checking
  - release train validation
  - infrastructure as code
  - deployment validation
  - version compliance
---

This template runs a Python script that checks Azure IoT Operations component versions
in both Terraform and Bicep configuration files against the latest released versions
from GitHub remote manifests.

## Overview

The AIO Version Checker Template ensures that the versions and trains of Azure IoT
Operations (AIO) components defined in the IaC files are in sync with the latest
published versions. It compares local configuration with official remote manifests to
identify any version or train mismatches. This helps maintain compatibility and enables
teams to stay current with the latest stable or preview versions, reducing integration
issues during deployments.

## Features

- **Version Verification**: Compares local AIO component versions with the latest published versions
- **Train Validation**: Ensures components are using the appropriate train (stable/preview)
- **Multiple IaC Support**: Works with both Terraform and Bicep configuration files
- **Detailed Reporting**: Provides specific information about each version or train mismatch
- **Configurable Severity**: Can produce warnings or break the build based on configuration

## Parameters

| Parameter     | Type         | Required | Default                          | Description                                                              |
|---------------|--------------|----------|----------------------------------|--------------------------------------------------------------------------|
| `displayName` | string       | No       | `"Check AIO Component Versions"` | Display name for the job                                                 |
| `dependsOn`   | object array | No       | `[]`                             | Array of jobs this job depends on                                        |
| `condition`   | string       | No       | `succeeded()`                    | Condition under which this job will run                                  |
| `iacType`     | string       | No       | `"all"`                          | Type of IaC files to check: "terraform", "bicep", or "all"               |
| `breakBuild`  | boolean      | No       | `false`                          | Whether to treat version mismatches as errors (true) or warnings (false) |

## Outputs

This template doesn't produce formal pipeline outputs, but it generates build warnings or errors for each detected version mismatch.

## Dependencies

This template depends on the following:

- **Required Agent Capabilities**: Python 3.11
- **Required Python Packages**: hcl2, requests
- **Required Files**: `./scripts/aio-version-checker.py` in the repository

## Usage

### Basic Usage

```yaml
  - template: .azdo/templates/aio-version-checker-template.yml
  parameters:
    iacType: all
```

### Advanced Usage

```yaml
  - template: .azdo/templates/aio-version-checker-template.yml
  parameters:
    displayName: "Check AIO Component Versions"
    dependsOn: [PreviousJob1, AnotherJob]
    condition: and(succeeded(), eq(variables['Build.SourceBranch'], 'refs/heads/main'))
    iacType: all
    breakBuild: true
```

## Implementation Details

The template runs through the following process:

1. **Environment Setup**: Checks out code and sets up Python 3.11
2. **Dependency Installation**: Installs required Python packages
3. **Version Analysis**: Runs the Python script to check component versions
4. **Report Generation**: Processes results and creates warnings or errors for any mismatches

### Components Checked

The version checker verifies these components:

| Component      | Terraform Name         | Bicep Name                      | Remote Manifest Source |
|----------------|------------------------|---------------------------------|------------------------|
| Cert Manager   | cert_manager_extension | aioCertManagerExtensionDefaults | enablement             |
| Secret Store   | secret_sync_controller | secretStoreExtensionDefaults    | enablement             |
| IoT Operations | azure-iot-operations   | aioExtensionDefaults            | instance               |

### Files Checked

- **Terraform**:
- `./src/100-edge/110-iot-ops/terraform/variables.init.tf` - Cert Manager and enablement components
- `./src/100-edge/110-iot-ops/terraform/variables.instance.tf` - IoT Operations instance config

- **Bicep**:
- `./src/100-edge/110-iot-ops/bicep/types.bicep` - All component extension defaults

## Examples

### Example 1: Basic Check with No Dependencies

```yaml
  - template: .azdo/templates/aio-version-checker-template.yml
  parameters:
    dependsOn: []
```

### Example 2: Check Only Terraform Files with Dependencies

```yaml
  - template: .azdo/templates/aio-version-checker-template.yml
  parameters:
    displayName: "Check Terraform AIO Versions"
    dependsOn: [Linting, UnitTests]
    iacType: terraform
```

### Example 3: Break Build on Version Mismatch

```yaml
  - template: .azdo/templates/aio-version-checker-template.yml
  parameters:
    displayName: "Strict AIO Version Check"
    dependsOn: [PrepStep]
    iacType: both
    breakBuild: true
```

## Troubleshooting

Common issues and their solutions:

1. **Missing Python Dependencies**: If the build fails with import errors
   - **Solution**: Ensure your repository has a requirements.txt file or that the template has access to install the required packages

2. **Script Not Found**: If the build fails to find the version checker script
   - **Solution**: Verify that the script exists at `./scripts/aio-version-checker.py` in your repository

3. **Excessive Warnings**: If you're getting too many version mismatch warnings
   - **Solution**: Update your local versions to match the remote ones, or temporarily change the iacType to focus on just terraform or bicep

## Related Templates

- MegaLinter Template: [YAML](/.azdo/templates/megalinter-template.yml) | [Documentation](./megalinter-template.md) - Provides code linting and quality checks before version checking
- Matrix Folder Check Template: [YAML](/.azdo/templates/matrix-folder-check-template.yml) | [Documentation](./matrix-folder-check-template.md) - Detects changes in the repository structure for downstream testing
- Docs Check Template: [YAML](/.azdo/templates/docs-check-terraform-template.yml) | [Documentation](./docs-check-terraform-template.md) - Validates documentation quality and consistency

## Learn More

- [Azure IoT Operations Documentation](https://learn.microsoft.com/azure/iot-operations/)
- [Azure IoT Operations GitHub Repository](https://github.com/Azure/azure-iot-operations)
- [Azure DevOps YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)
- [Terraform Documentation](https://www.terraform.io/docs)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
