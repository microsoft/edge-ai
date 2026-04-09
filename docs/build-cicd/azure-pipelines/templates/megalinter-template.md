---
title: MegaLinter Integration Template
description: Azure DevOps pipeline template for comprehensive code quality checking and linting across multiple languages
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: concept
estimated_reading_time: 7
keywords:
  - megalinter
  - code quality
  - static analysis
  - linting
  - azure devops
  - pipeline template
  - multi-language support
  - coding standards
  - syntax validation
  - security analysis
  - artifact generation
  - azure reporter
---

This template integrates MegaLinter into Azure DevOps pipelines, providing
comprehensive code quality checking and linting for all languages and file types in the
repository.

## Overview

MegaLinter is a powerful static analysis tool that detects coding issues, security
vulnerabilities, and enforces coding standards across multiple programming languages
and file formats. This template simplifies the integration of MegaLinter into the CI/CD
pipeline, making it easy to validate code quality before changes are merged.

## Features

- **Multi-Language Linting**: Automatically detects and lints code in 45+ languages, formats, and tooling standards
- **Azure DevOps PR Integration**: Posts comments directly on pull requests with linting results when enabled
- **Customizable Rules**: Uses repository-specific configuration files to control linting behavior
- **Detailed Reporting**: Generates comprehensive reports for fixing code quality issues
- **Build Blocking**: Optionally fails builds when linting standards aren't met
- **Parallel Processing**: Can run linters in parallel for improved performance
- **Pipeline Artifacts**: Publishes linting results as downloadable pipeline artifacts

## Parameters

| Parameter             | Type         | Required | Default            | Description                                                                          |
|-----------------------|--------------|----------|--------------------|--------------------------------------------------------------------------------------|
| `dependsOn`           | object array | No       | `[]`               | Jobs this MegaLinter job depends on                                                  |
| `displayName`         | string       | No       | `'Run MegaLinter'` | Custom display name for the job                                                      |
| `condition`           | string       | No       | `succeeded()`      | Condition to run this job                                                            |
| `enableAzureReporter` | boolean      | No       | `false`            | Enable Azure DevOps PR commenting integration                                        |
| `pullRequestId`       | string       | No       | `''`               | Pull Request ID for Azure Reporter (required when enableAzureReporter is true)       |
| `sourceRepoUri`       | string       | No       | `''`               | Source Repository URI for Azure Reporter (required when enableAzureReporter is true) |

## Outputs

This template doesn't produce formal pipeline outputs, but it generates the following artifacts:

| Artifact            | Description                                                                    |
|---------------------|--------------------------------------------------------------------------------|
| `MegaLinter Report` | Comprehensive reports in HTML, JSON, and other formats showing linting results |

## Dependencies

This template depends on the following:

- **Required Agent Capabilities**: Docker, bash
- **Required Configuration Files**:
- `.mega-linter.yml`: Main configuration file for MegaLinter
- `.cspell.json`: Dictionary configuration for spell checking
- `.cspell-dictionary.txt`: Additional dictionary terms
- `.markdownlint.json`: Markdown linting rules
- `terrascan.toml`: Configuration for Terrascan security scanner
- `PSScriptAnalyzerSettings.psd1`: PowerShell script analyzer settings

## Usage

### Basic Usage

```yaml
# Basic implementation with minimal parameters
  - template: .azdo/templates/megalinter-template.yml
```

### Advanced Usage

```yaml
# Advanced implementation with all parameters
  - template: .azdo/templates/megalinter-template.yml
  parameters:
    displayName: 'Comprehensive Code Quality Analysis'
    dependsOn:
      - SecurityScan
      - DependencyScan
    condition: and(succeeded('SecurityScan'), succeeded('DependencyScan'))
    enableAzureReporter: ${{ eq(variables['Build.Reason'], 'PullRequest') }}
    pullRequestId: $(System.PullRequest.PullRequestId)
    sourceRepoUri: $(System.PullRequest.SourceRepositoryURI)
```

## Implementation Details

The template executes a series of steps to run MegaLinter and process the results:

1. **Docker Cleanup (Before MegaLinter)**:
   - Removes unused Docker images, containers, and volumes to prevent disk exhaustion
   - Reports disk usage before and after cleanup
   - Frees ~10-20 GB of disk space on agents
   - Adds ~30-60 seconds to pipeline duration

2. **MegaLinter Execution**:
   - Pulls the MegaLinter Docker image from the registry (~12 GB uncompressed)
   - Runs the Docker container with repository-specific configuration
   - Mounts the repository as a volume for analysis
   - Sets environment variables to control MegaLinter behavior

3. **Docker Cleanup (After MegaLinter)**:
   - Frees MegaLinter container and images immediately (~12 GB)
   - Prevents disk space accumulation across concurrent builds
   - Ensures agents remain healthy for subsequent builds

4. **Result Processing**:
   - Publishes linting results as a pipeline artifact
   - Posts comments to the pull request if the Azure Reporter is enabled
   - Fails the build if linting issues are found and configured to do so

### Key Components

- **Docker Container**: Runs MegaLinter in an isolated environment with all necessary tools
- **Docker Cleanup**: Runs before and after MegaLinter to prevent disk exhaustion on agent pool VMs
- **Configuration Files**: Controls which linters run and how they evaluate code
- **Azure Reporter**: Integrates with Azure DevOps PR system to provide feedback directly in code reviews

### Docker Disk Management

**Why Cleanup is Required**:

Azure Managed DevOps Pool agents have limited disk space (typically 128 GB OS disk). Without cleanup:

- MegaLinter consumes ~12 GB per run (uncompressed image + containers)
- Application builds consume 40-50 GB (media capture, ROS2, Rust services)
- With 4 concurrent agents, disk exhaustion occurs within 2-3 build cycles

**Cleanup Strategy**:

- **Before MegaLinter**: Clears disk space from previous builds (ensures clean start)
- **After MegaLinter**: Frees MegaLinter's ~12 GB immediately (prevents accumulation)

**Command Used**: `docker system prune -af --volumes`

- `-a`: Remove ALL unused images, not just dangling ones
- `-f`: Force (no confirmation prompt, required for CI/CD)
- `--volumes`: Remove unused volumes

**Expected Impact**:

- Frees 10-20 GB per cleanup operation
- Adds ~90-120 seconds total to pipeline (2 cleanups × 45-60s each)
- Prevents "No space left on device" build failures
- Enables reliable concurrent builds

### Error Handling

The template provides clear error messages for common issues:

- Docker image pulling failures
- Configuration file errors
- Linting failures with links to specific files and line numbers

## Examples

### Example 1: PR Build with Commenting

```yaml
# PR build with automatic commenting
stages:
  - stage: Validate
    jobs:
      - template: .azdo/templates/megalinter-template.yml
        parameters:
          enableAzureReporter: ${{ eq(variables['Build.Reason'], 'PullRequest') }}
          pullRequestId: $(System.PullRequest.PullRequestId)
          sourceRepoUri: $(System.PullRequest.SourceRepositoryURI)
```

### Example 2: Scheduled Build

```yaml
# Scheduled build
schedules:
  - cron: "0 0 * * *"
  displayName: Daily Build
  branches:
    include:
      - main
  always: true

jobs:
  - template: .azdo/templates/megalinter-template.yml
```

## Troubleshooting

Common issues and their solutions:

1. **PR Comment Integration Failures**:
   - **Symptom**: Linting runs successfully but no comments appear in the PR
   - **Solution**: Verify that `enableAzureReporter` is set to true and both `pullRequestId` and `sourceRepoUri` are correctly provided

2. **Docker Image Issues**:
   - **Symptom**: Errors related to Docker image pulling
   - **Solution**: Verify Docker is available on the agent and network connectivity to Docker Hub

3. **Configuration File Not Found**:
   - **Symptom**: MegaLinter runs with default settings instead of custom configuration
   - **Solution**: Ensure `.mega-linter.yml` exists in the repository root

## Related Templates

- Matrix Folder Check Template: [YAML](/.azdo/templates/matrix-folder-check-template.yml) | [Documentation](./matrix-folder-check-template.md) - Detects changes for conditional running of downstream jobs
- Docs Check Template: [YAML](/.azdo/templates/docs-check-terraform-template.yml) | [Documentation](./docs-check-terraform-template.md) - Validates documentation quality
- AIO Version Checker Template: [YAML](/.azdo/templates/aio-version-checker-template.yml) | [Documentation](./aio-version-checker-template.md) - Ensures component versions are up to date

## Learn More

- [MegaLinter Documentation](https://megalinter.github.io/)
- [Available Linters](https://megalinter.io/latest/supported-linters/)
- [Configuration Options](https://megalinter.io/latest/configuration/)
- [Azure DevOps Pipeline Templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
- [Docker Caching Best Practices](https://docs.docker.com/build/cache/)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
