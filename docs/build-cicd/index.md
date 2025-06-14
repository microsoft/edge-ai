---
title: Build & CI/CD documentation
description: Comprehensive documentation for build processes, continuous integration, and deployment workflows across GitHub Actions, Azure DevOps, and build automation scripts
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: hub-page
keywords:
  - build
  - ci-cd
  - continuous integration
  - continuous deployment
  - github actions
  - azure devops
  - automation
  - deployment
  - build scripts
  - security
  - scanning
  - infrastructure as code
  - terraform
  - bicep
  - validation
  - documentation
  - megalinter
  - checkov
  - pipelines
  - workflows
  - templates
  - troubleshooting
estimated_reading_time: 4
---

## Build & CI/CD Documentation

This section provides comprehensive documentation for all build processes, continuous integration workflows, and deployment automation used in the Edge AI Accelerator project.

## In this guide

- [Overview](#overview)
- [CI/CD platforms](#cicd-platforms)
- [Build processes](#build-processes)
- [Security and validation](#security-and-validation)
- [Templates and reference](#templates-and-reference)
- [Troubleshooting](#troubleshooting)

## Overview

The Edge AI Accelerator uses multiple CI/CD platforms and build automation tools to ensure code quality, security, and reliable deployments:

- **GitHub Actions**: Primary CI/CD platform for pull request validation, testing, and deployment
- **Azure DevOps**: Enterprise CI/CD pipeline for infrastructure testing and deployment
- **Build Scripts**: Automated validation, documentation generation, and compliance checking
- **Security Scanning**: Integrated security validation and vulnerability assessment

## CI/CD platforms

### GitHub Actions workflows

Our GitHub Actions workflows provide automated validation and deployment capabilities:

| Workflow                 | Purpose                                  | Documentation                               |
|--------------------------|------------------------------------------|---------------------------------------------|
| Main CI/CD               | Primary workflow orchestration           | [GitHub Actions Guide](./github-actions.md) |
| Pull Request Validation  | Code quality and compliance validation   | [GitHub Actions Guide](./github-actions.md) |
| Documentation Validation | Infrastructure documentation consistency | [GitHub Actions Guide](./github-actions.md) |
| Security Scanning        | Code quality and security validation     | [GitHub Actions Guide](./github-actions.md) |
| Pages Deployment         | Documentation site deployment            | [GitHub Actions Guide](./github-actions.md) |

**Detailed workflow documentation**: [GitHub Actions Templates](./github-actions/)

### Azure DevOps pipelines

Our Azure DevOps pipelines handle enterprise infrastructure testing and deployment:

| Pipeline                 | Purpose                                                | Documentation                           |
|--------------------------|--------------------------------------------------------|-----------------------------------------|
| Infrastructure Testing   | Comprehensive Terraform and Bicep validation           | [Azure DevOps Guide](./azure-devops.md) |
| Matrix Testing           | Parallel testing of multiple infrastructure components | [Azure DevOps Guide](./azure-devops.md) |
| Deployment Orchestration | Multi-environment deployment workflows                 | [Azure DevOps Guide](./azure-devops.md) |
| Security Integration     | Security scanning and compliance validation            | [Azure DevOps Guide](./azure-devops.md) |

**Detailed pipeline documentation**: [Azure DevOps Templates](./azure-pipelines/)

## Build processes

### Automated validation scripts

The project includes comprehensive build scripts for validation and automation:

| Script Category              | Purpose                                                  | Documentation                                      |
|------------------------------|----------------------------------------------------------|----------------------------------------------------|
| **Documentation Validation** | Terraform and Bicep documentation consistency            | [Build Scripts Guide][build-scripts-guide]         |
| **Variable Compliance**      | Infrastructure variable validation and compliance        | [Build Scripts Guide][build-scripts-guide]         |
| **Security Scanning**        | Checkov security validation and vulnerability assessment | [Security Scanning Guide][security-scanning-guide] |
| **Version Checking**         | Azure IoT Operations version validation                  | [Build Scripts Guide][build-scripts-guide]         |
| **Folder Detection**         | Matrix build folder change detection                     | [Build Scripts Guide][build-scripts-guide]         |

### Build automation

- **Documentation Generation**: Automated Terraform and Bicep documentation
- **Dependency Management**: Package and provider version management
- **Quality Assurance**: Linting, formatting, and compliance validation

[Learn more about build processes][build-scripts-guide]

## Security and validation

### Security scanning integration

- **Checkov Integration**: Infrastructure as code security scanning
- **Dependency Scanning**: Package vulnerability assessment
- **Compliance Validation**: Policy and standard compliance checking

### Code quality validation

- **MegaLinter**: Comprehensive code quality and consistency validation
- **Format Validation**: Markdown, YAML, and code formatting standards
- **Link Validation**: Documentation link consistency and accuracy

[Learn more about security processes][security-scanning-guide]

## Templates and reference

### Reusable templates

- [GitHub Workflow Templates][github-workflow-templates] - Reusable GitHub Actions workflows
- [Azure Pipeline Templates][azure-pipeline-templates] - Azure DevOps pipeline templates
- [Build Script Templates][script-templates] - Common build automation patterns

### Reference documentation

- [Workflow Reference][workflow-reference] - Complete GitHub Actions and Azure DevOps reference
- [Script Reference][script-reference] - Build script command and parameter reference
- [Configuration Reference][configuration-reference] - CI/CD configuration options

## Troubleshooting

### Common build issues

- **Workflow Failures**: GitHub Actions troubleshooting and debugging
- **Pipeline Errors**: Azure DevOps pipeline issue resolution
- **Script Failures**: Build script debugging and error resolution
- **Dependency Issues**: Package and provider version conflicts

[Complete troubleshooting guide][troubleshooting-guide]

### Best practices

- **CI/CD Patterns**: Established workflow and pipeline patterns
- **Security Best Practices**: Secure CI/CD configuration and secret management
- **Performance Optimization**: Build performance and efficiency improvements

[Learn about CI/CD best practices][ci-cd-best-practices]

## Getting started

### For developers

1. **Review Prerequisites**: Understand required tools and permissions
2. **Local Development**: Set up build tools for local development
3. **Testing Workflows**: Validate changes before pull request submission

### For DevOps engineers

1. **Pipeline Configuration**: Understanding and modifying CI/CD pipelines
2. **Template Management**: Creating and maintaining reusable templates
3. **Security Integration**: Implementing security scanning and validation

### For contributors

1. **Build Process**: Understanding automated validation and testing
2. **Documentation Standards**: Maintaining documentation consistency
3. **Quality Standards**: Meeting code quality and security requirements

## Related documentation

- [Contributing Guidelines](../contributing/contributing.md) - Code contribution standards and processes
- [Getting Started Guides](../getting-started/) - Initial setup and development environment
- [Development Environment](../contributing/development-environment.md) - Dev Container setup and tools
- [Coding Conventions](../contributing/coding-conventions.md) - Infrastructure code standards
- [Observability Documentation](../observability/) - Monitoring and debugging guides
- [Security Documentation](../../SECURITY.md) - Security policies and best practices

<!-- Reference Links -->
[build-scripts-guide]: ./build-scripts.md
[security-scanning-guide]: ./security-scanning.md
[troubleshooting-guide]: ./troubleshooting-builds.md
[ci-cd-best-practices]: ./ci-cd-best-practices.md
[github-workflow-templates]: ./templates/github-workflow-templates.md
[azure-pipeline-templates]: ./templates/azure-pipeline-templates.md
[script-templates]: ./templates/script-templates.md
[workflow-reference]: ./reference/workflow-reference.md
[script-reference]: ./reference/script-reference.md
[configuration-reference]: ./configuration-reference.md

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
