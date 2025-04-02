# MegaLinter Integration Template

This template integrates MegaLinter into Azure DevOps pipelines, providing
comprehensive code quality checking and linting for all languages and file types in the
repository, with optimized caching for improved performance.

## Overview

MegaLinter is a powerful static analysis tool that detects coding issues, security
vulnerabilities, and enforces coding standards across multiple programming languages
and file formats. This template simplifies the integration of MegaLinter into the CI/CD
pipeline, making it easy to validate code quality before changes are merged. The
implementation includes advanced caching mechanisms to significantly improve pipeline
performance and reduce execution time.

## Features

- **Multi-Language Linting**: Automatically detects and lints code in 45+ languages, formats, and tooling standards
- **Azure DevOps PR Integration**: Posts comments directly on pull requests with linting results when enabled
- **Docker Image Caching**: Optimizes pipeline performance by caching the MegaLinter Docker image
- **Customizable Rules**: Uses repository-specific configuration files to control linting behavior
- **Detailed Reporting**: Generates comprehensive reports for fixing code quality issues
- **Build Blocking**: Optionally fails builds when linting standards aren't met
- **Parallel Processing**: Can run linters in parallel for improved performance
- **Pipeline Artifacts**: Publishes linting results as downloadable pipeline artifacts

## Parameters

| Parameter             | Type    | Required | Default                                      | Description                                                                          |
|-----------------------|---------|----------|----------------------------------------------|--------------------------------------------------------------------------------------|
| `dependsOn`           | object  | No       | `[]`                                         | Jobs this MegaLinter job depends on                                                  |
| `displayName`         | string  | No       | `'Run MegaLinter'`                           | Custom display name for the job                                                      |
| `condition`           | string  | No       | `succeeded()`                                | Condition to run this job                                                            |
| `megalinterCachePath` | string  | No       | `'/mnt/storage/sdc/cache/images/megalinter'` | Path for caching the MegaLinter Docker image                                         |
| `enableAzureReporter` | boolean | No       | `false`                                      | Enable Azure DevOps PR commenting integration                                        |
| `pullRequestId`       | string  | No       | `''`                                         | Pull Request ID for Azure Reporter (required when enableAzureReporter is true)       |
| `sourceRepoUri`       | string  | No       | `''`                                         | Source Repository URI for Azure Reporter (required when enableAzureReporter is true) |

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
    megalinterCachePath: '$(Build.ArtifactStagingDirectory)/megalinter-cache'
    enableAzureReporter: ${{ eq(variables['Build.Reason'], 'PullRequest') }}
    pullRequestId: $(System.PullRequest.PullRequestId)
    sourceRepoUri: $(System.PullRequest.SourceRepositoryURI)
```

## Implementation Details

The template executes a series of steps to run MegaLinter and process the results:

1. **Docker Image Management**:
   - Checks if the MegaLinter Docker image is cached
   - Loads the image from cache or pulls it from the registry
   - Saves the image to cache if it was pulled

2. **MegaLinter Execution**:
   - Runs the Docker container with repository-specific configuration
   - Mounts the repository as a volume for analysis
   - Sets environment variables to control MegaLinter behavior

3. **Result Processing**:
   - Publishes linting results as a pipeline artifact
   - Posts comments to the pull request if the Azure Reporter is enabled
   - Fails the build if linting issues are found and configured to do so

### Key Components

- **Docker Container**: Runs MegaLinter in an isolated environment with all necessary tools
- **Configuration Files**: Controls which linters run and how they evaluate code
- **Azure Reporter**: Integrates with Azure DevOps PR system to provide feedback directly in code reviews
- **Caching Mechanism**: Avoids repeatedly downloading the large Docker image on each pipeline run

### Error Handling

The template provides clear error messages for common issues:

- Docker image pulling or loading failures
- Configuration file errors
- Linting failures with links to specific files and line numbers
- Cache directory permission issues

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

### Example 2: Scheduled Build with Custom Cache Path

```yaml
# Scheduled build with custom cache path
schedules:
- cron: "0 0 * * *"
  displayName: Daily Build
  branches:
    include:
      - main
  always: true

jobs:
  - template: .azdo/templates/megalinter-template.yml
    parameters:
      megalinterCachePath: '/custom/cache/path'
```

## Troubleshooting

Common issues and their solutions:

1. **Cache Directory Access Issues**:
   - **Symptom**: Error messages about permissions or space in the cache directory
   - **Solution**: Ensure the agent has write access to the cache path and sufficient disk space

2. **PR Comment Integration Failures**:
   - **Symptom**: Linting runs successfully but no comments appear in the PR
   - **Solution**: Verify that `enableAzureReporter` is set to true and both `pullRequestId` and `sourceRepoUri` are correctly provided

3. **Docker Image Issues**:
   - **Symptom**: Errors related to Docker image pulling or loading
   - **Solution**: Verify Docker is available on the agent and network connectivity to Docker Hub

4. **Configuration File Not Found**:
   - **Symptom**: MegaLinter runs with default settings instead of custom configuration
   - **Solution**: Ensure `.mega-linter.yml` exists in the repository root

## Related Templates

- Matrix Folder Check Template: [YAML](./matrix-folder-check-template.yml) | [Documentation](./matrix-folder-check-template.md) - Detects changes for conditional running of downstream jobs
- Docs Check Template: [YAML](./docs-check-terraform-template.yml) | [Documentation](./docs-check-terraform-template.md) - Validates documentation quality
- AIO Version Checker Template: [YAML](./aio-version-checker-template.yml) | [Documentation](./aio-version-checker-template.md) - Ensures component versions are up to date

## Learn More

- [MegaLinter Documentation](https://megalinter.github.io/)
- [Available Linters](https://megalinter.github.io/latest/supported-linters/)
- [Azure DevOps Integration Guide](https://megalinter.github.io/latest/azure-pipelines/)
- [Configuration Options](https://megalinter.github.io/latest/configuration/)
- [Azure DevOps Pipeline Templates](https://learn.microsoft.com/azure/devops/pipelines/process/templates)
- [Docker Caching Best Practices](https://docs.docker.com/build/cache/)
