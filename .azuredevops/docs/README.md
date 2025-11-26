---
title: Release Automation Documentation
description: Technical documentation for Azure DevOps release automation pipelines - operator guides and process documentation
author: Edge AI Team
ms.date: 2025-11-15
ms.topic: hub-page
keywords:
  - release automation
  - pipeline documentation
  - operator guides
  - azure devops
estimated_reading_time: 8
---

Technical documentation for Azure DevOps release automation pipelines. This directory contains **operator-focused documentation** for running and troubleshooting release workflows, complementing the developer-focused documentation in `docs/build-cicd/`.

## Overview

This documentation serves pipeline operators (DevOps engineers, release managers) who need to:

* Manually trigger release automation pipelines
* Monitor and troubleshoot pipeline executions
* Configure GitHub App authentication
* Understand release workflow dependencies and sequencing

**Developer Documentation**: For build/test pipeline information, see [Build CI/CD Documentation](../../docs/build-cicd/README.md)

## Pipeline Documentation

Detailed technical documentation for each release automation pipeline:

### [Main to Dev Sync](./main-to-dev-sync.md)

Intelligent synchronization of main branch to dev after releases.

* **Purpose**: Keep dev branch in sync with main after release merges
* **Triggers**: Scheduled (03:00 UTC daily), chained after PR merges
* **Duration**: ~5-10 minutes per execution
* **Key Features**: Conflict detection, intelligent merge strategy, automatic retry logic

### [Release Branch Create](./release-branch-create.md)

Creation of release branches from main with validation.

* **Purpose**: Create versioned release branches for controlled release workflows
* **Triggers**: Manual execution by release managers
* **Duration**: ~3-5 minutes per execution
* **Key Features**: Version tag creation, branch protection, validation checks

## Template Documentation

Reusable pipeline templates for GitHub integration and release operations:

### [Template Overview](../templates/README.md)

Complete reference for all available templates with usage examples.

* **GitHub Authentication** - [github-auth.yml](../templates/github-auth.md)
* **Branch Operations** - [github-branch-operations.yml](../templates/github-branch-operations.md)
* **Pull Request Management** - [pr-creation.yml](../templates/pr-creation.md)
* **Git Synchronization** - [git-sync-operations.yml](../templates/git-sync-operations.md)
* **Release Validation** - [release-validation.yml](../templates/release-validation.md)

### [Authentication Guide](./authentication.md)

GitHub App setup and configuration for pipeline authentication.

### [Template Integration Guide](./template-integration.md)

Advanced orchestration patterns for multi-template workflows.

## Process Documentation

End-to-end workflow documentation for release processes:

### [Release Workflows Overview](./release-workflows.md)

Complete documentation of release workflow patterns and sequencing.

* Release branch creation workflow
* Pull request creation and review workflow
* Main-to-dev synchronization workflow
* Workflow dependencies and chaining

### [Intelligent Sync Gaps Analysis](./intelligent-sync-gaps.md)

Gap analysis and implementation details for intelligent sync capabilities.

* Identified gaps in release automation
* Implementation specifications for each gap
* Testing and validation procedures
* Troubleshooting common issues

## Common Pipeline Operator Tasks

### Manually Trigger a Release Pipeline

1. Navigate to [Azure DevOps Pipelines](https://dev.azure.com/msazure/One/_build)
2. Locate the release automation pipeline in the list
3. Click **Run pipeline**
4. Configure required parameters:
   * **Release Branch Create**: Version number (e.g., `v1.2.3`)
   * **Main to Dev Sync**: Branch name (usually automatic)
   * **GitHub Create Release PR**: Release branch name (usually automatic)
5. Click **Run** to start execution

### Monitor Pipeline Execution

1. Navigate to the pipeline run from the Pipelines page
2. View real-time logs by clicking on job/stage names
3. Check output variables for downstream pipeline triggers
4. Download logs for offline analysis if needed

### Troubleshoot Pipeline Failures

Common failure scenarios and resolutions:

| Failure Type          | Symptoms                    | Resolution                                             |
|-----------------------|-----------------------------|--------------------------------------------------------|
| **Authentication**    | 401 Unauthorized errors     | Verify Key Vault secrets, regenerate GitHub App token  |
| **Merge Conflicts**   | Merge operation fails       | Manually resolve conflicts, retry pipeline             |
| **Branch Protection** | Cannot push to branch       | Check Azure DevOps branch policies, verify permissions |
| **Network Timeout**   | Pipeline hangs or times out | Retry pipeline, check Azure DevOps service status      |

For detailed troubleshooting steps, see [Intelligent Sync Gaps - Troubleshooting](./intelligent-sync-gaps.md#troubleshooting)

## Authentication and Configuration

### GitHub App Authentication

All release automation pipelines use GitHub App authentication for secure API access:

**Authentication Flow**:

1. Retrieve GitHub App credentials from Azure Key Vault
2. Generate JWT token using App ID and private key
3. Exchange JWT for installation token with repository access
4. Use installation token for GitHub API operations
5. Token expires after 10 minutes (regenerated per pipeline run)

**Required Secrets** (stored in Azure Key Vault):

| Secret Name            | Purpose                    | Format                  | Rotation Frequency           |
| `GitHubAppId` | GitHub App identifier | Numeric | Never (unless app recreated) |
| `GitHubAppPrivateKey` | GitHub App authentication | PEM format (multi-line) | Annually or on compromise |
| `GitHubInstallationId` | Installation identifier | Numeric | Never (unless app reinstalled) |

### Service Connection

* **Name**: `ai-on-edge-service-connection`
* **Type**: Azure Resource Manager
* **Required Permissions**:
  * Key Vault: Get secrets, List secrets
  * Storage: Read access (for script downloads)

### Variable Groups

* **Group Name**: `ai-on-edge-secrets`
* **Linked Key Vault**: `ai-on-edge-kv` (or environment-specific vault)
* **Accessible By**: All pipelines in the Edge AI project

## Output Variables and Chaining

Release automation pipelines use output variables to chain workflows:

### Release Branch Create → GitHub Create Release PR

* **Output Variable**: `ReleaseBranchName`
* **Usage**: Passed to GitHub PR creation pipeline to identify source branch
* **Format**: `release/v1.2.3`

### GitHub Create Release PR → Main to Dev Sync

* **Output Variable**: `PullRequestMerged`
* **Usage**: Triggers sync pipeline after PR is merged to main
* **Format**: `true` or `false`

### Main to Dev Sync → Notification (Future)

* **Output Variable**: `SyncStatus`
* **Usage**: Could trigger notification pipelines on sync completion/failure
* **Format**: `success`, `conflict`, `failure`

## Related Documentation

### Operator Documentation (This Directory)

* [main-to-dev-sync.md](./main-to-dev-sync.md) - Intelligent sync pipeline
* [release-branch-create.md](./release-branch-create.md) - Release branch creation pipeline
* [release-workflows.md](./release-workflows.md) - End-to-end workflow documentation

### Developer Documentation

* [Build CI/CD Documentation](../../docs/build-cicd/README.md) - Build and test pipelines
* [Azure Pipelines Overview](../../docs/build-cicd/azure-pipelines.md) - General pipeline architecture
* [Contributing Guide](../../CONTRIBUTING.md) - Development workflow and standards

### External References

* [Azure DevOps Pipelines Documentation](https://learn.microsoft.com/azure/devops/pipelines/)
* [GitHub App Authentication](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app)
* [Azure Key Vault Integration](https://learn.microsoft.com/azure/devops/pipelines/release/azure-key-vault)

## Feedback and Support

For questions, issues, or suggestions:

* **Internal**: Post in the Edge AI DevOps Teams channel
* **Issues**: Create an issue in the [GitHub repository](https://github.com/microsoft/edge-ai/issues)
* **Documentation**: Suggest improvements via pull request to this documentation
