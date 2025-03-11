# MegaLinter Integration

This project uses [MegaLinter](https://megalinter.github.io/) as a comprehensive linting solution to ensure code quality across all languages and file types. This document explains how MegaLinter is integrated into our build system.

## How MegaLinter Works in Our Build System

MegaLinter runs as part of our CI/CD pipeline to validate code quality before changes are merged. It:

1. **Detects languages** in the repository automatically
2. **Runs appropriate linters** for each file type
3. **Generates detailed reports** for fixing linting issues
4. **Blocks builds** when linting standards are not met

### Configuration Files

MegaLinter uses the following configuration files in the root directory:

| File                            | Purpose                                                                                                |
|---------------------------------|--------------------------------------------------------------------------------------------------------|
| `.mega-linter.yml`              | Main configuration file that controls which linters are enabled, disabled, and their specific settings |
| `.cspell.json`                  | Dictionary configuration for spell checking                                                            |
| `.markdownlint.json`            | Markdown linting rules                                                                                 |
| `terrascan.toml`                | Configuration for Terrascan security scanner for IaC                                                   |
| `PSScriptAnalyzerSettings.psd1` | PowerShell script analyzer settings                                                                    |

## Using the MegaLinter Template

We provide a reusable template for MegaLinter integration in your Azure DevOps pipelines. This template simplifies configuration and ensures consistent linting across all pipelines.

### Template Location

The template is available at [`.azdo/megalinter-template.yml`](./megalinter-template.yml)

### Parameters

| Parameter             | Type    | Default                                    | Description                                                                          |
|-----------------------|---------|--------------------------------------------|--------------------------------------------------------------------------------------|
| `dependsOn`           | object  | `[]`                                       | Jobs this MegaLinter job depends on                                                  |
| `displayName`         | string  | 'Run MegaLinter'                           | Custom display name for the job                                                      |
| `condition`           | string  | succeeded()                                | Condition to run this job                                                            |
| `megalinterCachePath` | string  | '/mnt/storage/sdc/cache/images/megalinter' | Path for caching the MegaLinter Docker image                                         |
| `enableAzureReporter` | boolean | false                                      | Enable Azure DevOps PR commenting integration                                        |
| `pullRequestId`       | string  | ''                                         | Pull Request ID for Azure Reporter (required when enableAzureReporter is true)       |
| `sourceRepoUri`       | string  | ''                                         | Source Repository URI for Azure Reporter (required when enableAzureReporter is true) |

### Example Usage

Here's how to integrate the MegaLinter template into your Azure DevOps pipeline:

```yaml
# Basic usage
stages:
  - stage: Validate
    jobs:
      - template: .azdo/megalinter-template.yml

# Advanced usage with parameters
stages:
  - stage: Validate
    jobs:
      - template: .azdo/megalinter-template.yml
        parameters:
          displayName: 'Lint Pull Request Code'
          dependsOn: [BuildAndTest]
          condition: succeeded('BuildAndTest')
          enableAzureReporter: ${{ eq(variables['Build.Reason'], 'PullRequest') }}
          pullRequestId: $(System.PullRequest.PullRequestId)
          sourceRepoUri: $(System.PullRequest.SourceRepositoryURI)
```

### PR Comment Integration

When `enableAzureReporter` is set to `true`, MegaLinter will automatically post comments to your Pull Request with linting results. To enable this:

1. Make sure the build service has permissions to comment on PRs
2. Set the required parameters: `pullRequestId` and `sourceRepoUri`
3. These typically come from system variables when the pipeline is triggered by a PR

## Build Pipeline Integration

MegaLinter is integrated into our Azure DevOps pipeline in the following locations:

1. **PR Stage** - In `.azdo/azure-pipeline.yml`
   - The `lint` job executes MegaLinter as a pre-merge quality gate
   - Runs on PRs to enforce code standards before code review

2. **Main Stage** - In `.azdo/azure-pipeline.yml`
   - Validates all committed code meets quality standards
   - Generates quality reports as pipeline artifacts

3. **Scheduled** - In `.azdo/azure-pipeline.yml`
   - Attempts to download and cache the most recent Megalinter container release

### Legacy Example Job Configuration

For reference, here is a basic implementation that can be used inplace of our template:

```yaml
- task: Cache@2
  displayName: Cache MegaLinter
  inputs:
    key: 'megalinter | "$(Agent.OS)"'
    restoreKeys: |
      megalinter | "$(Agent.OS)"
      megalinter
    path: $(Pipeline.Workspace)/.megalinter-cache

- bash: |
    set -e
    MegalinterCachePath=$(Pipeline.Workspace)/.megalinter-cache
    mkdir -p $MegalinterCachePath

    # Check if the Docker image is already cached
    if [ -f "$MegalinterCachePath/megalinterv8-cache.tar" ]; then
      echo "Loading cached MegaLinter Docker image..."
      docker load -i $MegalinterCachePath/megalinterv8-cache.tar
      echo "##vso[task.setvariable variable=CacheRestored]true"
    else
      echo "No cached MegaLinter Docker image found. Will pull and cache after use."
      echo "##vso[task.setvariable variable=CacheRestored]false"
    fi
  displayName: 'Restore MegaLinter Docker image from cache'

- bash: |
    docker pull oxsecurity/megalinter:v8
  displayName: 'Pull MegaLinter Docker image'
  condition: ne(variables['CacheRestored'], 'true')

- bash: |
    MegalinterCachePath=$(Pipeline.Workspace)/.megalinter-cache
    mkdir -p $MegalinterCachePath
    docker save oxsecurity/megalinter:v8 -o $MegalinterCachePath/megalinterv8-cache.tar
  displayName: 'Save MegaLinter Docker image to cache'
  condition: and(succeeded(), ne(variables['CacheRestored'], 'true'))

- bash: |
    docker run \
      --rm \
      -e MEGALINTER_CONFIG=.mega-linter.yml \
      -e DEFAULT_WORKSPACE=/tmp/lint \
      -e REPORT_OUTPUT_FOLDER=/tmp/lint/megalinter-reports \
      -e VALIDATE_ALL_CODEBASE=true \
      -v $(System.DefaultWorkingDirectory):/tmp/lint \
      oxsecurity/megalinter:v8
  displayName: 'Run MegaLinter'

- task: PublishPipelineArtifact@1
  displayName: Publish MegaLinter Report
  inputs:
    targetPath: '$(System.DefaultWorkingDirectory)/megalinter-reports/'
    artifact: 'MegaLinter Report'
    publishLocation: 'pipeline'
  condition: succeededOrFailed()
```

> **Note:** We recommend using the new template rather than this legacy approach.

### Pipeline Optimization with Caching

Our implementation of MegaLinter includes caching to improve pipeline performance by saving the Docker image to disk. The template automatically handles:

- Using a storage disk for all build agents
- Saving the entire Docker image to disk to avoid repeated downloads
- Loading the cached image in subsequent runs of agents
- Significantly reducing pipeline execution time by eliminating excessive image pull operations
- Falling back to downloading the image only when cache is not available

## Why You Should Adopt This Approach

### Benefits We've Experienced

- **Consistent Code Quality**: Standardized quality across all project files
- **Reduced Technical Debt**: Issues caught early before they accumulate
- **Faster Code Reviews**: Less time spent on style and formatting issues
- **Improved Developer Experience**: Clear feedback on how to fix issues
- **Self-Documentation**: Code standards are codified, not tribal knowledge
- **Simplified Integration**: Template-based approach for easy reuse

### Situations Where You May Not Want to Use Cached Versions

1. **Updated Linter Versions**: If you want to ensure that you are always using the latest version of MegaLinter and its linters, you may choose to skip the cache to pull the latest image each time.
2. **Configuration Changes**: If you have made significant changes to the MegaLinter configuration or added new linters, it might be beneficial to pull a fresh image to ensure compatibility.
3. **Debugging Issues**: If you encounter issues with the cached version, pulling a fresh image can help determine if the problem is related to the cache.
4. **Security Concerns**: Regularly pulling the latest image ensures that you have the most recent security updates and patches.

### Getting Started in Your Project

1. Copy our `.mega-linter.yml` as a starting point for configuration
2. Copy the remainder of our configuration files (noted above)
3. Include the `.azdo/megalinter-template.yml` template in your project
4. Reference the template in your pipeline definition (per instructions above)
5. Gradually enforce stricter rules and new linters as your team adapts

## Learn More

- [MegaLinter Documentation](https://megalinter.github.io/)
- [Available Linters](https://megalinter.github.io/latest/supported-linters/)
- [Azure DevOps Integration Guide](https://megalinter.github.io/latest/azure-pipelines/)
