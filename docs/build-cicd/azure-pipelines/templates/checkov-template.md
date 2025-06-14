---
title: Checkov Security Scanner Template
description: Azure DevOps pipeline template that integrates Checkov security scanning for Infrastructure as Code files
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
estimated_reading_time: 7
keywords:
  - checkov
  - security scanning
  - infrastructure as code
  - security analysis
  - azure devops
  - pipeline template
  - vulnerability detection
  - misconfiguration detection
  - terraform security
  - bicep security
  - static analysis
  - compliance scanning
---

A pipeline template that integrates Checkov security scanning into the Azure DevOps CI/CD pipeline to detect misconfigurations and security issues in Infrastructure as Code (IaC) files, specifically Terraform and Bicep.

## Overview

The Checkov template automates security scanning for Infrastructure as Code (IaC) files in the Edge AI repository. It detects potential security issues, compliance violations, and misconfigurations in Terraform and Bicep files before they reach production environments. The template uses PowerShell scripts to automatically discover folders containing IaC files, runs Checkov scans, and generates a consolidated JUnit XML report that is published as test results and pipeline artifacts.

## Features

- **Automatic Folder Detection**: Uses the PowerShell script `Detect-Folder-Changes.ps1` to find all folders containing Terraform or Bicep files
- **Consolidated Scanning**: Processes all detected folders and produces a single aggregated report
- **Configurable Scope**: Allows scanning only Terraform files, only Bicep files, or both based on parameters
- **Version Control**: Supports specific Checkov versions or defaults to latest for consistent scanning
- **Test Integration**: Publishes results as JUnit XML test reports, making security findings visible in the test results tab
- **Artifact Publication**: Stores scan results as pipeline artifacts for further analysis

## Parameters

| Parameter        | Type   | Required | Default           | Description                                                                                       |
|------------------|--------|----------|-------------------|---------------------------------------------------------------------------------------------------|
| `resourceType`   | string | No       | `'all'`           | Type of IaC files to scan. Allowed values: 'terraform', 'bicep', or 'all'                         |
| `agentPool`      | string | No       | `'ubuntu-latest'` | Azure DevOps agent pool to use for scanning jobs                                                  |
| `checkovVersion` | string | No       | `'latest'`        | Version of Checkov to install (use 'latest' for newest version or specify a version like '2.5.8') |
| `dependsOn`      | object | No       | `[]`              | Job or jobs that this template's jobs should depend on                                            |

## Dependencies

This template depends on the following:

- **Required Scripts**:
- `/scripts/Detect-Folder-Changes.ps1` - Identifies folders containing IaC files
- `/scripts/Run-Checkov.ps1` - Runs Checkov on identified folders and aggregates results
- **Required Agent Capabilities**: Python 3.9+ support, PowerShell 7+ (pwsh)

## Usage

### Basic Usage

```yaml
# Basic implementation scanning all IaC types
  - template: .azdo/templates/checkov-template.yml
```

### Terraform-Only Scan

```yaml
# Scan only Terraform files
  - template: .azdo/templates/checkov-template.yml
  parameters:
    resourceType: terraform
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
  - template: .azdo/templates/checkov-template.yml
  parameters:
    resourceType: all
    agentPool: 'ubuntu-latest'
    checkovVersion: '2.5.8'
    dependsOn: [PreviousJob]
```

## Implementation Details

The template executes security scanning in three distinct phases:

1. **Folder Detection**: Uses the `Detect-Folder-Changes.ps1` script with the `-IncludeAllFolders` flag to identify all folders containing Terraform and/or Bicep files.

2. **Security Scanning**: Installs Checkov with the specified version, then pipes the detected folders to `Run-Checkov.ps1` which handles the scanning of each folder.

3. **Results Aggregation**: The `Run-Checkov.ps1` script combines individual scan results into a consolidated JUnit XML report file (`code-analysis.xml`).

### Key Components

- **PowerShell-Based Detection**: Uses PowerShell scripts for efficient folder detection and result aggregation.

- **Deduplication Logic**: The `Run-Checkov.ps1` script automatically deduplicates identical findings to prevent redundancy in the final report.

- **Test Results Integration**: Leverages the JUnit output format to present security findings as test failures, making them visible in the Azure DevOps test results tab.

### Error Handling

The template is configured with `continueOnError: true` for the publishing steps, ensuring that the pipeline doesn't fail if security issues are found. This allows the pipeline to complete while still reporting the security findings in test results and artifacts.

## Examples

### Example 1: Integrate with PR Build

```yaml
  - stage: PR
  displayName: PR Build Process
  condition: and(eq(variables.isMain, false), eq(variables.isScheduled, false))
  jobs:
    # Run security scanning on Terraform files only
    - template: .azdo/templates/checkov-template.yml
      parameters:
        resourceType: terraform
        dependsOn: []
```

### Example 2: Scan with a Specific Version

```yaml
  - template: .azdo/templates/checkov-template.yml
  parameters:
    resourceType: all
    checkovVersion: '2.5.9'
    dependsOn: [DependencyCheck, CodeQuality]
```

## Troubleshooting

1. **Missing Python Dependencies**: If the pipeline fails with Python module errors
   - **Solution**: Ensure the agent has Python 3.9+ and pip installed correctly

2. **PowerShell Script Errors**: If the detection or scanning scripts fail
   - **Solution**: Check that the scripts exist at the expected paths and have the correct permissions

3. **Empty Report**: If the report contains no findings even though issues exist
   - **Solution**: Verify that the `resourceType` parameter matches the IaC files you're trying to scan

## Related Templates

- Terraform Test Template: [YAML](/.azdo/templates/cluster-test-terraform-template.yml) - Runs functional tests on Terraform modules after security scanning
- MegaLinter Template: [YAML](/.azdo/templates/megalinter-template.yml) - Performs broader linting including security checks

## Learn More

- [Checkov Documentation](https://www.checkov.io/1.Welcome/Quick%20Start.html)
- [Azure DevOps Pipeline YAML Schema](https://learn.microsoft.com/azure/devops/pipelines/yaml-schema/)
- [Infrastructure as Code Security Best Practices](https://learn.microsoft.com/azure/architecture/framework/security/devops-infrastructure-as-code)
- [Terraform Security Guidelines](https://www.terraform.io/docs/cloud/guides/recommended-practices/index.html)
- [Repository Structure Guide](/README.md)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
