---
title: Azure DevOps pipelines
description: Documentation for Azure DevOps CI/CD pipelines used in the Edge AI Accelerator project for infrastructure testing and deployment automation.
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: how-to-guide
keywords:
  - azure devops
  - ci/cd pipelines
  - pipeline templates
  - infrastructure testing
  - terraform testing
  - bicep validation
  - checkov security scanning
  - megalinter
  - matrix testing
  - change detection
  - service connections
  - managed identity
  - azure devops infrastructure
  - deployment automation
  - agent pools
estimated_reading_time: 3
---
## Azure DevOps Pipelines

This document provides documentation for Azure DevOps CI/CD pipelines used in the Edge AI Accelerator project for infrastructure testing and deployment automation.

## In this guide

- [Overview](#overview)
- [Main pipeline structure](#main-pipeline-structure)
- [Pipeline templates](#pipeline-templates)
- [Azure DevOps infrastructure](#azure-devops-infrastructure)
- [Getting started](#getting-started)

## Overview

The Edge AI Accelerator project uses Azure DevOps for automated infrastructure testing and deployment. The pipeline system provides:

- **Automated Testing**: Matrix-based testing for Terraform and Bicep components
- **Security Scanning**: Integrated security validation with Checkov
- **Quality Assurance**: Documentation validation and compliance checking
- **Version Management**: Automated component version checking

## Main pipeline structure

**File**: `azure-pipelines.yml` (194 lines)

The main pipeline is triggered on:

- Pull requests to main branch
- Commits to main and internal-eng branches
- Daily scheduled runs (5 AM UTC)

### Pipeline stages

#### Scheduled stage

Runs daily for security and update scanning:

- **Security scanning** with Checkov
- **Component version checking** for AIO components
- **Full repository scanning** for all components
- **Terraform testing** for all infrastructure components

#### Main stage

Runs on pull requests and main branch commits:

- **Change detection** to identify modified components
- **Matrix testing** for affected Terraform components
- **Bicep validation** for affected Bicep components
- **Script testing** for PowerShell scripts

## Pipeline templates

Located in `.azdo/templates/`, these templates provide reusable pipeline functionality:

### Core templates

- **`matrix-folder-check-template.yml`**: Detects changes and generates test matrices
- **`cluster-test-terraform-template.yml`**: Terraform component testing
- **`checkov-template.yml`**: Security scanning with Checkov
- **`megalinter-template.yml`**: Code quality and linting
- **`aio-version-checker-template.yml`**: Component version validation

### Validation templates

- **`variable-compliance-terraform-template.yml`**: Terraform variable compliance
- **`variable-compliance-bicep-template.yml`**: Bicep variable compliance
- **`docs-check-terraform-template.yml`**: Terraform documentation validation
- **`docs-check-bicep-template.yml`**: Bicep documentation validation

### Utility templates

- **`resource-provider-pwsh-tests-template.yml`**: PowerShell script testing
- **`wiki-update-template.yml`**: Documentation updates

### GitHub integration

- **`github-push.yml`**: Pushes content from Azure DevOps to GitHub
- **`github-pull.yml`**: Pulls content from GitHub to Azure DevOps

## Azure DevOps infrastructure

The `deploy/azdo/` directory contains Terraform modules for Azure DevOps infrastructure:

### Main components

- **Resource Group**: Container for all Azure DevOps resources
- **Virtual Network**: Network infrastructure with dedicated subnets
- **Storage Account**: Artifact storage and state management
- **Key Vault**: Secure secret management with private endpoint
- **Container Registry**: Private container image storage
- **Managed Identity**: Authentication for pipeline operations

### Infrastructure modules

- **`modules/key-vault/`**: Key Vault with private endpoint configuration
- **`modules/storage-account/`**: Storage account for artifacts
- **`modules/network/`**: Virtual network and subnet configuration
- **`modules/identity/`**: Managed identity and role assignments

## Getting started

### Prerequisites

1. **Azure DevOps Organization**: Access to Azure DevOps with appropriate permissions
2. **Azure Subscription**: Target subscription for infrastructure deployment
3. **Service Principal or Managed Identity**: Authentication for Azure operations

### Service connection setup

Create a service connection in Azure DevOps using either:

#### Managed Identity (Recommended)

For scenarios where your Azure DevOps organization is in the same tenant as your target subscription.

#### Service Principal

For cross-tenant scenarios or when managed identity is not available.

Follow the [Azure DevOps documentation](https://learn.microsoft.com/azure/devops/pipelines/library/service-endpoints?view=azure-devops) for detailed setup instructions.

### Pipeline configuration

The main pipeline (`azure-pipelines.yml`) uses these key configurations:

- **Pool**: `ai-on-edge-managed-pool` with Ubuntu agents
- **Service Connection**: `azdo-ai-for-edge-iac-for-edge`
- **Triggers**: Automatic on main/internal-eng branches and daily schedule
- **Parameters**: Optional security scanning flag for manual runs

### Agent pool requirements

The pipeline requires a managed agent pool with:

- Ubuntu 2022 or later
- Terraform CLI installed
- Azure CLI installed
- PowerShell Core installed
- Docker support for container operations

## Related guides

- [GitHub Actions Workflows][github-actions-guide] - GitHub Actions CI/CD documentation
- [Build Scripts Guide][build-scripts-guide] - Automated build and validation scripts
- [Security Scanning Guide][security-scanning-guide] - Security validation processes
- [Deployment Processes][deployment-processes-guide] - Comprehensive deployment documentation

<!-- Reference Links -->
[github-actions-guide]: ./github-actions.md
[build-scripts-guide]: ./build-scripts.md
[security-scanning-guide]: ./security-scanning.md
[deployment-processes-guide]: ./deployment-processes.md

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
