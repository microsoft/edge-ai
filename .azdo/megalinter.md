# MegaLinter Integration

This project uses [MegaLinter](https://megalinter.github.io/) as a comprehensive linting solution to ensure code quality across all languages and file types. This document explains how MegaLinter is integrated into our build system.

## How MegaLinter Works in Our Build System

MegaLinter runs as part of our CI/CD pipeline to validate code quality before changes are merged. It:

1. **Detects languages** in the repository automatically
2. **Runs appropriate linters** for each file type
3. **Generates detailed reports** for fixing issues
4. **Blocks builds** when quality standards aren't met

### Configuration Files

MegaLinter uses the following configuration files in the root directory:

| File                            | Purpose                                                                                                |
|---------------------------------|--------------------------------------------------------------------------------------------------------|
| `.mega-linter.yml`              | Main configuration file that controls which linters are enabled, disabled, and their specific settings |
| `.cspell.json`                  | Dictionary configuration for spell checking                                                            |
| `.markdownlint.json`            | Markdown linting rules                                                                                 |
| `terrascan.toml`                | Configuration for Terrascan security scanner for IaC                                                   |
| `PSScriptAnalyzerSettings.psd1` | PowerShell script analyzer settings                                                                    |

### Build Pipeline Integration

MegaLinter is integrated into our Azure DevOps pipeline in the following locations:

1. **PR Stage** - In `.azdo/azure-pipeline.yml`
   - The `lint` job executes MegaLinter as a pre-merge quality gate
   - Runs on PRs to enforce code standards before code review

2. **Main Stage** - In `.azdo/azure-pipeline.yml`
   - Validates all committed code meets quality standards
   - Generates quality reports as pipeline artifacts

3. **Scheduled** - In `.azdo/azure-pipeline.yml`
   - Attempts to download and cache the most recent Megalinter container release

### Example Job Configuration

Here's the exact implementation from our `.azdo/pipelines/azure-pipelines.yml` file:

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

This implementation:

- Uses caching to store and retrieve the MegaLinter Docker image between runs
- Checks if the image is already cached before pulling
- Runs MegaLinter with our configuration
- Publishes the linting reports as pipeline artifacts

### Pipeline Optimization with Caching

Our implementation of MegaLinter includes caching to improve pipeline performance by saving the Docker image to disk:

```yaml
- bash: |
    MegalinterCachePath=$(Pipeline.Workspace)/.megalinter-cache
    mkdir -p $MegalinterCachePath
    docker save oxsecurity/megalinter:v8 -o $(MegalinterCachePath)/megalinterv8-cache.tar
  displayName: 'Save MegaLinter Docker image to cache'
  condition: and(succeeded(), ne(variables['CacheRestored'], 'true'))
```

This caching mechanism:

- Uses a storage disk for all build agents
- Saves the entire Docker image to disk to avoid repeated downloads
- Loads the cached image in subsequent runs of agents
- Significantly reduces pipeline execution time by eliminating excessive image pull operations
- Falls back to downloading the image only when cache is not available

When implementing MegaLinter in your pipelines, we strongly recommend including similar caching to optimize performance.

## Why You Should Adopt This Approach

### Benefits We've Experienced

- **Consistent Code Quality**: Standardized quality across all project files
- **Reduced Technical Debt**: Issues caught early before they accumulate
- **Faster Code Reviews**: Less time spent on style and formatting issues
- **Improved Developer Experience**: Clear feedback on how to fix issues
- **Self-Documentation**: Code standards are codified, not tribal knowledge

### Situations Where You May Not Want to Use Cached Versions

1. **Updated Linter Versions**: If you want to ensure that you are always using the latest version of MegaLinter and its linters, you may choose to skip the cache to pull the latest image each time.
2. **Configuration Changes**: If you have made significant changes to the MegaLinter configuration or added new linters, it might be beneficial to pull a fresh image to ensure compatibility.
3. **Debugging Issues**: If you encounter issues with the cached version, pulling a fresh image can help determine if the problem is related to the cache.
4. **Security Concerns**: Regularly pulling the latest image ensures that you have the most recent security updates and patches.

### Getting Started in Your Project

1. Copy our `.mega-linter.yml` as a starting point
2. Copy all configuration files noted above
3. Refer to our `.azdo/pipelines/azure-pipelines.yml` file for the complete MegaLinter job(s) implementations including setup, caching, and execution
4. Gradually enforce stricter rules and new linters as your team adapts

## Learn More

- [MegaLinter Documentation](https://megalinter.github.io/)
- [Available Linters](https://megalinter.github.io/latest/supported-linters/)
- [Azure DevOps Integration Guide](https://megalinter.github.io/latest/azure-pipelines/)
