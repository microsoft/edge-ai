---
title: Application Matrix Builds
description: GitHub Actions workflow for building applications detected by matrix change detection
author: Edge AI Team
ms.date: 09/21/2025
ms.topic: concept
estimated_reading_time: 10
keywords:
  - application builds
  - matrix builds
  - docker builds
  - container registry
  - slsa bundles
  - security scanning
  - github actions
  - workflow
  - multi-service applications
  - build automation
  - devops optimization
---

This reusable workflow builds applications detected by the matrix-folder-check workflow. It consumes application matrix data and executes standardized builds for each changed application and its services using Docker conventions and enterprise-grade security practices.

## Overview

The Application Matrix Builds workflow provides a comprehensive solution for building containerized applications in a matrix-driven approach. It supports both single-service and multi-service applications, integrates with container registries for secure image storage, generates SLSA security attestations, and provides detailed build analytics and reporting.

## Features

- **Matrix-Driven Building**: Consumes application matrix data from matrix-folder-check workflow
- **Multi-Service Support**: Automatically detects and builds multiple services within applications
- **Container Registry Integration**: Supports pushing to any OCI-compatible registry with secure authentication
- **SLSA Attestations**: Generates security attestations for supply chain security
- **Security Scanning**: Optional integration with container security scanning
- **Build Analytics**: Comprehensive build metrics and performance reporting
- **Automatic Detection Fallback**: Runs change detection inside the workflow when no matrix is supplied
- **Flexible Deployment**: Configurable for different environments (dev, staging, prod)

## Parameters

### Workflow Call Parameters

| Parameter             | Type    | Required | Default                      | Description                                                   |
|-----------------------|---------|----------|------------------------------|---------------------------------------------------------------|
| `applicationMatrix`   | string  | No       | `''`                         | JSON matrix of applications from matrix-folder-check workflow |
| `includeApplications` | boolean | No       | `false`                      | Include all applications when fallback detection runs         |
| `registryName`        | string  | No       | `'edgeai.azurecr.io'`        | Container registry hostname                                   |
| `baseImageTag`        | string  | No       | `'${{ github.run_number }}'` | Base tag for container images                                 |
| `buildEnvironment`    | string  | No       | `'dev'`                      | Build environment identifier                                  |
| `pushImages`          | boolean | No       | `false`                      | Enable pushing images to registry                             |
| `enableSLSA`          | boolean | No       | `true`                       | Enable SLSA attestation generation                            |
| `enableSecurityScan`  | boolean | No       | `true`                       | Enable security scanning during builds                        |
| `securityThreshold`   | string  | No       | `'critical'`                 | Security scanning threshold (critical, high, medium, low)     |
| `dockerBuildArgs`     | string  | No       | `''`                         | Additional Docker build arguments                             |

### Workflow Dispatch Parameters

| Parameter             | Type    | Required | Default               | Description                                                           |
|-----------------------|---------|----------|-----------------------|-----------------------------------------------------------------------|
| `includeApplications` | boolean | No       | `true`                | Include all applications when running manual builds                   |
| `applicationMatrix`   | string  | No       | `''`                  | Optional precomputed application matrix JSON                          |
| `baseImageTag`        | string  | No       | `'manual'`            | Base tag for manually triggered builds                                |
| `dockerBuildArgs`     | string  | No       | `''`                  | Additional Docker build arguments                                     |
| `registryName`        | string  | No       | `'edgeai.azurecr.io'` | Container registry hostname                                           |
| `buildEnvironment`    | string  | No       | `'dev'`               | Environment identifier for manual builds                              |
| `pushImages`          | boolean | No       | `false`               | Enable registry push for manual builds                                |
| `enableSLSA`          | boolean | No       | `true`                | Enable SLSA attestation generation                                    |
| `enableSecurityScan`  | boolean | No       | `true`                | Enable security scanning during builds                                |
| `securityThreshold`   | string  | No       | `'critical'`          | Security scanning threshold (critical, high, medium, low, negligible) |

## Dependencies

This workflow requires:

- **Container Registry Access**: Secrets for registry authentication
  - `REGISTRY_USERNAME`: Registry username or service principal
  - `REGISTRY_PASSWORD`: Registry password or service principal secret
- **PowerShell**: Available on GitHub-hosted runners
- **Docker**: Available on GitHub-hosted runners
- **Application Structure**: Standardized application directory structure

## Usage

### Basic Usage with Matrix Detection

```yaml
name: Application CI/CD

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  detect-changes:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeApplications: true

  build-applications:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.changesInApplications == 'true' }}
    uses: ./.github/workflows/application-matrix-builds.yml
    with:
      applicationMatrix: ${{ needs.detect-changes.outputs.changedApplicationFolders }}
      registryName: "myregistry.azurecr.io"
      pushImages: true
      enableSLSA: true
      enableSecurityScan: true
    secrets: inherit
```

### Manual Trigger Usage

```yaml
# Manually trigger builds and optionally supply a custom matrix
name: Manual Application Builds

on:
  workflow_dispatch:
    inputs:
      includeApplications:
        description: 'Include every application when no matrix is provided'
        required: false
        default: true
        type: boolean
      applicationMatrix:
        description: 'Optional application matrix JSON for targeted builds'
        required: false
        default: ''
        type: string

jobs:
  manual-builds:
    uses: ./.github/workflows/application-matrix-builds.yml
    with:
      includeApplications: ${{ github.event.inputs.includeApplications }}
      applicationMatrix: ${{ github.event.inputs.applicationMatrix }}
      baseImageTag: 'manual-${{ github.run_number }}'
      buildEnvironment: 'dev'
      pushImages: true
      enableSLSA: true
      enableSecurityScan: true
    secrets: inherit
```

### Production Build Pipeline

```yaml
name: Production Release

on:
  release:
    types: [published]

jobs:
  detect-all-apps:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeApplications: true
      forceComplete: true

  production-builds:
    needs: detect-all-apps
    uses: ./.github/workflows/application-matrix-builds.yml
    with:
      includeApplications: true
      applicationMatrix: ${{ needs.detect-all-apps.outputs.changedApplicationFolders }}
      registryName: "prod-registry.azurecr.io"
      baseImageTag: ${{ github.event.release.tag_name }}
      buildEnvironment: 'prod'
      pushImages: true
      enableSLSA: true
      enableSecurityScan: true
      securityThreshold: 'critical'
    secrets: inherit
```

### Pull Request Validation

```yaml
name: PR Validation

on:
  pull_request:
    branches: [main]

jobs:
  detect-changes:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeApplications: true

  validate-applications:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.changesInApplications == 'true' }}
    uses: ./.github/workflows/application-matrix-builds.yml
    with:
      applicationMatrix: ${{ needs.detect-changes.outputs.changedApplicationFolders }}
      baseImageTag: 'pr-${{ github.event.number }}'
      buildEnvironment: 'pr'
      pushImages: false  # Don't push PR builds
      enableSLSA: false
      enableSecurityScan: true
      securityThreshold: 'medium'
    secrets: inherit
```

## Application Structure Requirements

Applications must follow this standardized structure for successful builds:

```text
src/500-application/
├── app-name/
│   ├── docker-compose.yml          # Optional: Multi-service orchestration
│   ├── Dockerfile                  # Single-service application
│   ├── .dockerignore              # Docker ignore patterns
│   ├── package.json               # Node.js dependencies (if applicable)
│   ├── requirements.txt           # Python dependencies (if applicable)
│   └── services/                   # Multi-service applications
│       ├── service1/
│       │   ├── Dockerfile
│       │   └── src/
│       └── service2/
│           ├── Dockerfile
│           └── src/
```

## Output Variables

The workflow provides comprehensive outputs for integration with other workflows:

| Output Variable | Description                                   | Example Value                                |
|-----------------|-----------------------------------------------|----------------------------------------------|
| `buildResults`  | JSON summary of all application build results | `{"successful": 2, "failed": 0, "total": 2}` |
| `imagesBuilt`   | Number of container images successfully built | `4`                                          |
| `buildDuration` | Total build duration in seconds               | `345`                                        |

### Build Results JSON Structure

```json
{
  "buildId": "build-20250921-143022-123456",
  "timestamp": "2025-09-21T14:30:22.123Z",
  "totalApplications": 2,
  "successfulApplications": 2,
  "failedApplications": 0,
  "totalImages": 4,
  "registry": "edgeai.azurecr.io",
  "buildEnvironment": "dev",
  "securityScanning": {
    "enabled": true,
    "scansExecuted": 4,
    "scansPassed": 4,
    "scansFailed": 0
  },
  "applications": {
    "app1": {
      "status": "success",
      "images": ["app1-api:dev-123", "app1-worker:dev-123"],
      "buildDuration": 120,
      "services": ["api", "worker"]
    },
    "app2": {
      "status": "success",
      "images": ["app2:dev-123"],
      "buildDuration": 85,
      "services": []
    }
  }
}
```

## Implementation Details

### Build Process Flow

1. **Matrix Preparation**: Parse and validate input matrix data
2. **Parallel Building**: Execute builds for each application in parallel
3. **Image Management**: Tag and optionally push images to registry
4. **Security Processing**: Generate SLSA attestations and run security scans
5. **Result Aggregation**: Collect and summarize build results

### Key Components

- **PowerShell Application Builder**: Cross-platform application build script
- **Matrix Transformation**: Converts detection matrix to build matrix format
- **Registry Integration**: Secure authentication and image pushing
- **SLSA Generation**: Supply chain security attestation creation
- **Build Analytics**: Comprehensive metrics collection and reporting

### Security Features

- **OIDC Authentication**: Uses GitHub OIDC tokens for secure registry access
- **SLSA Attestations**: Can be toggled via the `enableSLSA` parameter for environment-specific control
- **Security Scanning**: Optional container vulnerability scanning
- **Secret Management**: Secure handling of registry credentials
- **Build Isolation**: Each application builds in isolated environment

## Examples

### Example 1: Complete CI Pipeline

```yaml
name: Complete Application CI

on:
  push:
    branches: [main, develop]
  pull_request:
    branches: [main]

jobs:
  detect-changes:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeApplications: true

  build-and-test:
    needs: detect-changes
    if: ${{ needs.detect-changes.outputs.changesInApplications == 'true' }}
    uses: ./.github/workflows/application-matrix-builds.yml
    with:
      applicationMatrix: ${{ needs.detect-changes.outputs.changedApplicationFolders }}
      registryName: ${{ vars.DEV_REGISTRY }}
      baseImageTag: ${{ github.sha }}
      buildEnvironment: ${{ github.ref == 'refs/heads/main' && 'staging' || 'dev' }}
      pushImages: ${{ github.event_name == 'push' }}
      enableSLSA: true
      enableSecurityScan: true
      securityThreshold: 'high'
    secrets: inherit

  deploy-staging:
    needs: [detect-changes, build-and-test]
    if: ${{ github.ref == 'refs/heads/main' && needs.build-and-test.outputs.imagesBuilt > 0 }}
    runs-on: ubuntu-latest
    steps:
      - name: Deploy to Staging
        run: |
          echo "Deploying ${{ needs.build-and-test.outputs.imagesBuilt }} images to staging"
```

### Example 2: Multi-Environment Build

```yaml
name: Multi-Environment Builds

on:
  workflow_dispatch:
    inputs:
      target_environment:
        description: 'Target environment'
        required: true
        default: 'dev'
        type: choice
        options: ['dev', 'staging', 'prod']

jobs:
  build-for-environment:
    uses: ./.github/workflows/application-matrix-builds.yml
    with:
      applicationMatrix: ${{ vars.ALL_APPLICATIONS_MATRIX }}
      registryName: ${{ vars[format('{0}_REGISTRY', github.event.inputs.target_environment)] }}
      baseImageTag: ${{ format('{0}-{1}', github.event.inputs.target_environment, github.run_number) }}
      buildEnvironment: ${{ github.event.inputs.target_environment }}
      pushImages: true
      enableSLSA: ${{ github.event.inputs.target_environment != 'dev' }}
      enableSecurityScan: ${{ github.event.inputs.target_environment == 'prod' }}
      securityThreshold: ${{ github.event.inputs.target_environment == 'prod' && 'critical' || 'high' }}
    secrets: inherit
```

### Example 3: Scheduled Complete Builds

```yaml
name: Nightly Complete Builds

on:
  schedule:
    - cron: '0 2 * * *'  # Run at 2 AM daily

jobs:
  detect-all-applications:
    uses: ./.github/workflows/matrix-folder-check.yml
    with:
      includeApplications: true
      forceComplete: true  # Include all applications regardless of changes

  nightly-builds:
    needs: detect-all-applications
    uses: ./.github/workflows/application-matrix-builds.yml
    with:
      includeApplications: true
      applicationMatrix: ${{ needs.detect-all-applications.outputs.changedApplicationFolders }}
      registryName: ${{ vars.NIGHTLY_REGISTRY }}
      baseImageTag: 'nightly-${{ github.run_number }}'
      buildEnvironment: 'nightly'
      pushImages: true
      enableSLSA: true
      enableSecurityScan: true
      securityThreshold: 'medium'
    secrets: inherit
```

## Troubleshooting

Common issues and their solutions:

1. **Matrix Parsing Errors**

  **Symptom**: Workflow fails with "Invalid JSON in application matrix"

  **Solution**: Verify the matrix-folder-check workflow output format

  **Debug**: Check the JSON structure matches expected format

1. **Registry Authentication Failures**

  **Symptom**: Docker login fails with authentication errors

  **Solution**: Verify `REGISTRY_USERNAME` and `REGISTRY_PASSWORD` secrets are configured

  **Check**: Ensure the service principal has `AcrPush` permissions

1. **Build Script Not Found**

  **Symptom**: PowerShell application builder script cannot be found

  **Solution**: Verify `./scripts/build/application-builder.ps1` exists in repository

  **Alternative**: Check repository checkout step completed successfully

1. **SLSA Attestation Failures**

  **Symptom**: SLSA generation fails or produces invalid attestations

  **Solution**: Ensure OIDC tokens are properly configured for the workflow

  **Alternative**: Set `enableSLSA: false` to disable attestation generation

1. **Security Scan Issues**

  **Symptom**: Security scanning fails or produces no results

  **Solution**: Verify security scanning tools are available in the environment

  **Check**: Review security scanner logs and adjust threshold if needed

1. **Build Performance Issues**

  **Symptom**: Builds are slow or timeout

  **Solution**: Consider reducing matrix size or using Docker layer caching

  **Optimization**: Use multi-stage Dockerfiles and .dockerignore files

## Performance Optimization

- **Docker Layer Caching**: Use GitHub Actions Docker layer caching for faster builds
- **Matrix Parallelization**: Leverage GitHub's matrix strategy for parallel execution
- **Build Context Optimization**: Use .dockerignore to reduce build context size
- **Multi-stage Builds**: Implement multi-stage Dockerfiles for smaller final images
- **Resource Management**: Monitor and adjust runner resource allocation as needed

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
