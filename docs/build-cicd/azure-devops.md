---
title: Azure DevOps pipelines
description: Documentation for Azure DevOps CI/CD pipeline and infrastructure components in the Edge AI Accelerator project.
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: reference
keywords:
  - azure devops
  - pipelines
  - ci/cd
  - pipeline templates
  - checkov security scanning
  - megalinter
  - terraform testing
  - bicep validation
  - infrastructure automation
  - managed pool
  - azure devops infrastructure
  - terraform module
estimated_reading_time: 3
---
## Azure DevOps Pipelines

This document covers the Azure DevOps CI/CD pipeline and infrastructure components that exist in the Edge AI Accelerator repository.

## In this guide

- [Main pipeline](#main-pipeline)
- [Pipeline templates](#pipeline-templates)
- [Azure DevOps infrastructure](#azure-devops-infrastructure)

## Main pipeline

The repository contains a main Azure DevOps pipeline in `azure-pipelines.yml` (194 lines) that provides CI/CD automation for infrastructure components.

### Trigger configuration

The pipeline triggers on:

- **Branch triggers**: `main` and `internal-eng` branches
- **Scheduled triggers**: Daily at 5 AM UTC (9 PM PST)
- **Manual triggers**: With optional security scanning parameter

### Pipeline stages

The pipeline consists of two main stages:

#### Scheduled stage

Runs security and update scanning with these jobs:

- **Checkov security scanning**: Uses `checkov-template.yml` for infrastructure security validation
- **AIO version checking**: Uses `aio-version-checker-template.yml` to check component versions
- **Matrix folder checking**: Uses `matrix-folder-check-template.yml` to detect changes in source directories
- **Terraform testing**: Uses `cluster-test-terraform-template.yml` for infrastructure component testing

#### Main stage

Runs on pull requests and commits to main branch for component validation and testing.

### Pipeline configuration

- **Pool**: `ai-on-edge-managed-pool`
- **VM Image**: `ubuntu-latest`
- Uses managed DevOps pool with Ubuntu 2022 and Windows 2022 agents

## Pipeline templates

The repository includes 11 specialized pipeline templates in `.azdo/templates/`:

### Security and quality templates

| Template                           | Purpose                                 |
|------------------------------------|-----------------------------------------|
| `checkov-template.yml`             | Security scanning with Checkov          |
| `megalinter-template.yml`          | Code quality and linting validation     |
| `matrix-folder-check-template.yml` | Dynamic change detection for components |

### Infrastructure testing templates

| Template                                     | Purpose                                |
|----------------------------------------------|----------------------------------------|
| `cluster-test-terraform-template.yml`        | Terraform component testing            |
| `docs-check-terraform-template.yml`          | Terraform documentation validation     |
| `docs-check-bicep-template.yml`              | Bicep documentation validation         |
| `variable-compliance-terraform-template.yml` | Terraform variable compliance checking |
| `variable-compliance-bicep-template.yml`     | Bicep variable compliance checking     |

### Utility templates

| Template                                    | Purpose                                          |
|---------------------------------------------|--------------------------------------------------|
| `aio-version-checker-template.yml`          | Azure IoT Operations version checking            |
| `resource-provider-pwsh-tests-template.yml` | PowerShell script testing for resource providers |
| `wiki-update-template.yml`                  | Documentation wiki updates                       |

## Azure DevOps infrastructure

The repository includes Terraform infrastructure for Azure DevOps integration in `deploy/azdo/`.

### Infrastructure components

The Azure DevOps infrastructure module creates:

- **Resource Group**: Container for Azure DevOps resources
- **Virtual Network**: With subnets for Key Vault, ACR, and DevOps agent pool
- **Storage Account**: For pipeline artifacts and state storage
- **Key Vault**: With private endpoint for secure secret management
- **Container Registry**: With private endpoint for container image storage
- **DevOps Managed Pool**: For pipeline execution agents
- **User Assigned Managed Identity**: With appropriate role assignments

### Module structure

| File           | Purpose                           |
|----------------|-----------------------------------|
| `main.tf`      | Main infrastructure configuration |
| `variables.tf` | Input variable definitions        |
| `versions.tf`  | Provider version constraints      |
| `modules/`     | Internal module components        |

### Requirements

- **Terraform**: >= 1.9.8, < 2.0
- **Azure Provider**: >= 4.8.0
- **Azure AD Provider**: >= 3.0.2
- **Azure API Provider**: >= 2.2.0

For detailed deployment instructions and module documentation, see the [Azure DevOps infrastructure README](../../deploy/azdo/README.md).

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
