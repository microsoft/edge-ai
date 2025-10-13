---
title: Application Build Template
description: Azure DevOps pipeline template for building applications detected by matrix change detection
author: Edge AI Team
ms.date: 09/21/2025
ms.topic: concept
estimated_reading_time: 8
keywords:
  - application builds
  - matrix builds
  - docker builds
  - container registry
  - slsa bundles
  - security scanning
  - azure devops
  - pipeline template
  - multi-service applications
  - build automation
  - devops optimization
---

This template builds applications detected by the matrix-folder-check-template. It consumes
application matrix data and executes generic builds for each changed application and its
services using Docker conventions and standardized build patterns. The matrix data is
always sourced from change detection outputs—manual overrides are no longer supported.

## Overview

The Application Build Template is designed to process applications identified by change
detection workflows and build them using standardized Docker patterns. It supports both
single-service and multi-service applications, integrates with Azure Container Registry
for image storage, and generates SLSA-style security bundles for dependency tracking.

## Features

- **Matrix-Driven Building**: Consumes application matrices emitted by matrix-folder-check-template
- **Change-Aware Gating**: Honors detection outputs to skip builds when no applications changed
- **Multi-Service Support**: Handles applications with multiple services automatically
- **Container Registry Integration**: Supports pushing to Azure Container Registry with authentication
- **SLSA Bundle Generation**: Creates security bundles for dependency tracking and provenance
- **Standardized Build Patterns**: Uses generic Docker build patterns across all applications
- **Security Scanning Integration**: Optional integration with security scanning workflows
- **Structured Logging**: Provides detailed build metrics and logging for monitoring

## Parameters

| Parameter            | Type    | Required | Default                                                                                                   | Description                                                                           |
|----------------------|---------|----------|-----------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------|
| `jobName`            | string  | No       | `'ApplicationMatrixBuild'`                                                                                | Job name used when instantiating the template                                         |
| `dependsOn`          | object  | No       | `[]`                                                                                                      | Dependencies for the job instance                                                     |
| `displayName`        | string  | No       | `'Application Matrix Build'`                                                                              | Display name shown in the pipeline                                                    |
| `condition`          | string  | No       | `succeeded()`                                                                                             | Condition controlling whether the job runs                                            |
| `matrixVariable`     | string  | No       | `'dependencies.MatrixBuildFolderCheck.outputs[''matrixBuildFolderCheckTask.changedApplicationFolders'']'` | Expression resolving to the JSON application matrix from matrix-folder-check-template |
| `hasChangesVariable` | string  | No       | `'dependencies.MatrixBuildFolderCheck.outputs[''matrixBuildFolderCheckTask.changesInApplications'']'`     | Expression resolving to the changes flag emitted by matrix-folder-check-template      |
| `breakBuild`         | boolean | No       | `false`                                                                                                   | Reserved for builds that must fail on downstream security gate results                |
| `agentPool`          | object  | No       | `{ name: 'ai-on-edge-managed-pool', vmImage: 'ubuntu-latest' }`                                           | Agent pool configuration                                                              |
| `registryName`       | string  | No       | `'edgeai.azurecr.io'`                                                                                     | Container registry for image storage                                                  |
| `baseImageTag`       | string  | No       | `'$(Build.BuildId)'`                                                                                      | Base tag applied to built images                                                      |
| `pushImages`         | boolean | No       | `false`                                                                                                   | Enable pushing images to registry                                                     |
| `enableSLSA`         | boolean | No       | `true`                                                                                                    | Enable SLSA bundle generation                                                         |
| `enableSecurityScan` | boolean | No       | `true`                                                                                                    | Enable security scanning during builds                                                |
| `securityThreshold`  | string  | No       | `'critical'`                                                                                              | Security scanning threshold (critical, high, medium, low, negligible)                 |
| `dockerBuildArgs`    | string  | No       | `''`                                                                                                      | Additional Docker build arguments                                                     |

## Dependencies

This template has the following dependencies:

- **Required Agent Capabilities**: Docker, PowerShell, jq
- **Required Scripts**: `./scripts/build/application-builder.ps1`
- **Container Registry**: Azure Container Registry or compatible registry
- **Input Dependencies**: `matrixBuildFolderCheckTask` outputs from matrix-folder-check-template

## Usage

### Basic Job Pairing

```yaml
# Detect application changes and build when changes exist
jobs:
  - template: .azdo/templates/matrix-folder-check-template.yml
    parameters:
      includeApplications: true

  - template: .azdo/templates/application-build-template.yaml
    parameters:
      dependsOn:
        - MatrixBuildFolderCheck
      condition: >-
        and(
          succeeded(),
          eq(
            dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInApplications'],
            'true'
          )
        )
```

### Cross-Stage Integration

```yaml
stages:
  - stage: DetectChanges
    jobs:
      - template: .azdo/templates/matrix-folder-check-template.yml
        parameters:
          includeApplications: true

  - stage: BuildApplications
    dependsOn: DetectChanges
    jobs:
      - template: .azdo/templates/application-build-template.yaml
        parameters:
          dependsOn:
            - MatrixBuildFolderCheck
          matrixVariable: >-
            stageDependencies.DetectChanges.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedApplicationFolders']
          hasChangesVariable: >-
            stageDependencies.DetectChanges.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInApplications']
          condition: >-
            and(
              succeeded(),
              eq(
                stageDependencies.DetectChanges.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInApplications'],
                'true'
              )
            )
```

### Customizing Build Behavior

```yaml
jobs:
  - template: .azdo/templates/application-build-template.yaml
    parameters:
      dependsOn:
        - MatrixBuildFolderCheck
      pushImages: true
      enableSLSA: true
      enableSecurityScan: true
      securityThreshold: 'high'
      baseImageTag: '$(Build.SourceBranchName)-$(Build.BuildId)'
      registryName: 'myregistry.azurecr.io'
      dockerBuildArgs: '--build-arg ENV=production'
```

### Pull Request Configuration

```yaml
jobs:
  - template: .azdo/templates/application-build-template.yaml
    parameters:
      dependsOn:
        - MatrixBuildFolderCheck
      condition: >-
        and(
          eq(variables['Build.Reason'], 'PullRequest'),
          eq(
            dependencies.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInApplications'],
            'true'
          )
        )
      pushImages: false
      enableSLSA: false
      enableSecurityScan: true
      securityThreshold: 'medium'
```

## Implementation Details

The template executes a comprehensive build process for each application:

1. **Matrix Validation**: Validates and processes application matrix input
2. **Environment Setup**: Ensures Docker and required tools are available
3. **Application Building**: Calls the PowerShell application builder script for each app
4. **Image Management**: Handles tagging and optional pushing to container registry
5. **SLSA Bundle Generation**: Creates security bundles for dependency tracking
6. **Result Collection**: Aggregates build results and metrics

### Key Components

- **PowerShell Builder Script**: Uses `./scripts/build/application-builder.ps1` for cross-platform builds
- **Matrix Processing**: Consumes change detection outputs and supports parameter overrides for custom dependency graphs
- **Service Discovery**: Automatically discovers services within each application
- **Build Orchestration**: Coordinates Docker builds across multiple services per application
- **Registry Authentication**: Handles Azure Container Registry authentication when pushing
- **Error Handling**: Comprehensive error handling with detailed logging

### Application Structure Requirements

Applications must follow this structure for successful builds:

```text
src/500-application/
├── app-name/
│   ├── docker-compose.yml          # Optional: Service orchestration
│   ├── Dockerfile                  # Single-service application
│   └── services/
│       ├── service1/
│       │   └── Dockerfile          # Multi-service application
│       └── service2/
│           └── Dockerfile
```

## Output Variables

The template provides the following output variables for downstream consumption:

| Output Variable   | Description                                      | Access Pattern                                                        |
|-------------------|--------------------------------------------------|-----------------------------------------------------------------------|
| `build_results`   | JSON summary of all application build results    | `dependencies.BuildJob.outputs['build_applications.build_results']`   |
| `total_images`    | Total number of container images built           | `dependencies.BuildJob.outputs['build_applications.total_images']`    |
| `build_duration`  | Total build duration in seconds                  | `dependencies.BuildJob.outputs['build_applications.build_duration']`  |
| `registry_pushed` | Number of images successfully pushed to registry | `dependencies.BuildJob.outputs['build_applications.registry_pushed']` |

## Examples

### Example 1: Standard Application Build Pipeline

```yaml
# Complete pipeline with change detection and application builds
stages:
  - stage: DetectChanges
    jobs:
      - template: .azdo/templates/matrix-folder-check-template.yml
        parameters:
          includeApplications: true

  - stage: BuildApplications
    dependsOn: DetectChanges
    condition: >-
      and(
        succeeded(),
        eq(
          stageDependencies.DetectChanges.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInApplications'],
          'true'
        )
      )
    jobs:
      - template: .azdo/templates/application-build-template.yaml
        parameters:
          dependsOn:
            - MatrixBuildFolderCheck
          matrixVariable: >-
            stageDependencies.DetectChanges.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changedApplicationFolders']
          hasChangesVariable: >-
            stageDependencies.DetectChanges.MatrixBuildFolderCheck.outputs['matrixBuildFolderCheckTask.changesInApplications']
          pushImages: true
          enableSLSA: true
```

### Example 2: Security-Focused Build

```yaml
# Build with enhanced security scanning
jobs:
  - template: .azdo/templates/application-build-template.yaml
    parameters:
      dependsOn:
        - MatrixBuildFolderCheck
      enableSecurityScan: true
      securityThreshold: 'high'
      pushImages: ${{ eq(variables['Build.Reason'], 'Manual') }}
      dockerBuildArgs: '--build-arg SECURITY_SCAN=true'
      enableSLSA: true
```

### Example 3: Multi-Environment Build

```yaml
# Build for multiple environments with different configurations
jobs:
  - template: .azdo/templates/application-build-template.yaml
    parameters:
      dependsOn:
        - MatrixBuildFolderCheck
      registryName: 'dev-registry.azurecr.io'
      baseImageTag: 'dev-$(Build.BuildId)'
      pushImages: true

  - template: .azdo/templates/application-build-template.yaml
    parameters:
      dependsOn:
        - MatrixBuildFolderCheck
      registryName: 'prod-registry.azurecr.io'
      baseImageTag: 'prod-$(Build.BuildId)'
      pushImages: ${{ eq(variables['Build.SourceBranch'], 'refs/heads/main') }}
      enableSecurityScan: true
      securityThreshold: 'critical'
```

## Troubleshooting

Use these targeted fixes for frequent build issues.

### Empty Matrix Error

- **Symptom:** Template fails with "no applications to build".
- **Likely cause:** Matrix detection job didn't emit application folders or the dependency reference is misconfigured.
- **Fix:** Ensure matrix-folder-check-template ran with `includeApplications: true` and that this job depends on the `MatrixBuildFolderCheck` outputs.
- **Verification:** Confirm applications exist in `src/500-application/`, follow the required structure, and the dependency name matches the default or your overridden `matrixVariable`.

### Docker Build Failures

- **Symptom:** Individual application builds fail with Docker errors.
- **Likely cause:** Dockerfile syntax issues or inaccessible base images.
- **Fix:** Check Dockerfile syntax and ensure base images are accessible.
- **Debug:** Review build logs for specific Docker error messages.

### Registry Authentication Issues

- **Symptom:** Fails to push images with authentication errors.
- **Likely cause:** Azure Container Registry service connection or permissions are misconfigured.
- **Fix:** Verify Azure Container Registry service connection is configured correctly.
- **Verification:** Ensure the service principal has ACRPush permissions.

### PowerShell Script Errors

- **Symptom:** Application builder script fails with PowerShell errors.
- **Likely cause:** Builder script is missing, renamed, or invoked with incorrect parameters.
- **Fix:** Verify `./scripts/build/application-builder.ps1` exists and has correct parameters.
- **Debug:** Run the script manually with the same parameters to identify issues.

### SLSA Bundle Generation Failures

- **Symptom:** SLSA bundle creation fails.
- **Likely cause:** Application structure lacks the dependency files required for bundle generation.
- **Fix:** Check that application structure includes proper dependency files.
- **Workaround:** Set `enableSLSA: false` to skip SLSA bundle generation.

### Security Scanner Integration Issues

- **Symptom:** Security scanning fails or produces no results.
- **Likely cause:** Security scanning tools are misconfigured or thresholds are too strict.
- **Fix:** Verify security scanning tools are properly configured in the environment.
- **Verification:** Review security scanner logs and ensure thresholds are appropriate.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
