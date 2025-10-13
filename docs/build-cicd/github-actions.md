---
title: GitHub Actions workflows
description: Essential guide to GitHub Actions workflows used in the Edge AI Accelerator project for CI/CD automation, validation, and deployment
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: reference
keywords:
- github actions
- workflows
- ci-cd
- automation
- validation
- deployment
- continuous integration
- infrastructure as code
- terraform
- bicep
- azure integration
- service principal
- reusable workflows
- templates
estimated_reading_time: 5
---

## GitHub Actions Workflows

GitHub Actions serves as the primary CI/CD platform for the Edge AI Accelerator, providing automated validation, testing, and deployment capabilities through modular, reusable workflow components.

## In this guide

- [Getting started](#getting-started)
- [Core workflows](#core-workflows)
- [Template workflows](#template-workflows)
- [Configuration requirements](#configuration-requirements)
- [Additional resources](#additional-resources)

## Getting started

### Prerequisites

1. **Azure Service Principal**: Create a service principal with contributor rights following the [GitHub Action Authentication](https://learn.microsoft.com/azure/developer/github/connect-from-azure) documentation
2. **GitHub Secrets**: Configure the required secrets in your repository settings

### Required GitHub Secrets

Navigate to "Settings" → "Secrets and variables" → "Actions" and add:

| Secret                  | Purpose                          |
|-------------------------|----------------------------------|
| `AZURE_CLIENT_ID`       | Service principal application ID |
| `AZURE_TENANT_ID`       | Azure tenant ID                  |
| `AZURE_SUBSCRIPTION_ID` | Azure subscription ID            |
| `AZURE_CLIENT_SECRET`   | Service principal client secret  |

## Core workflows

### Main workflows

| Workflow                  | Purpose                        | Documentation                                            |
|---------------------------|--------------------------------|----------------------------------------------------------|
| Main CI/CD                | Primary orchestration workflow | [Details](./github-actions/main.md)                      |
| Pull Request Validation   | Comprehensive PR validation    | [Details](./github-actions/pr-validation.md)             |
| Application Matrix Builds | Dynamic application building   | [Details](./github-actions/application-matrix-builds.md) |

### Key features

- **Dynamic matrix builds** detecting only modified applications and services
- **Multi-language application builds** (.NET, Rust, Node.js, Python)
- **Integrated security scanning** with container vulnerability assessment
- **Language-specific dependency audits** and security gates
- **Documentation validation** for Terraform and Bicep
- **Variable compliance** checking across modules
- **Automated deployment** with approval workflows

## Template workflows

Reusable workflow components for consistent CI/CD processes:

| Template                            | Purpose                                      |
|-------------------------------------|----------------------------------------------|
| `megalinter.yml`                    | Code quality and security validation         |
| `docs-check-terraform.yml`          | Terraform documentation validation           |
| `docs-check-bicep.yml`              | Bicep documentation validation               |
| `variable-compliance-terraform.yml` | Terraform variable compliance checking       |
| `variable-compliance-bicep.yml`     | Bicep variable compliance checking           |
| `cluster-test-terraform.yml`        | Infrastructure testing against real clusters |
| `pages-deploy.yml`                  | Documentation deployment to GitHub Pages     |

> **Complete template documentation**: [Template Workflows](./templates/)

## Configuration requirements

### Environment Variables

Common environment variables for workflows:

| Variable                 | Example Value | Purpose                |
|--------------------------|---------------|------------------------|
| `TF_VAR_ENVIRONMENT`     | `dev`         | Deployment environment |
| `TF_VAR_LOCATION`        | `westus`      | Azure region           |
| `TF_VAR_RESOURCE_PREFIX` | `edge-ai`     | Resource naming prefix |

### Workflow architecture

Our workflows follow a modular approach:

- **Consistency**: Same validation steps across all workflows
- **Reusability**: Template components for common tasks
- **Flexibility**: Parameterized components for different scenarios
- **Maintainability**: Changes made in one place, applied everywhere

## Additional resources

### Related documentation

- [Build Scripts Guide](./build-scripts.md) - Automated validation and documentation scripts
- [Security Scanning](./security-scanning.md) - Security validation processes
- [CI/CD Best Practices](./ci-cd-best-practices.md) - Workflow optimization and patterns
- [Troubleshooting Guide](./troubleshooting-builds.md) - Common issues and solutions
- [Azure DevOps Integration](./azure-devops.md) - Enterprise pipeline workflows

### External resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax Reference](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Azure Login Action](https://github.com/marketplace/actions/azure-login)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
