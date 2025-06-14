---
title: Azure pipeline templates
description: Design and implementation patterns for reusable Azure DevOps pipeline templates in the Edge AI Accelerator project
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: reference
keywords:
  - azure devops
  - pipeline templates
  - reusable pipelines
  - template design
  - ci/cd patterns
  - modular pipelines
estimated_reading_time: 4
---

## Azure Pipeline Templates

Documentation of reusable Azure DevOps pipeline design patterns and template architecture used in the Edge AI Accelerator project.

## In this guide

- [Template architecture](#template-architecture)
- [Core templates](#core-templates)
- [Usage patterns](#usage-patterns)

## Template architecture

Our Azure DevOps pipelines follow a modular, template-based design with multiple layers:

### Template types

- **Stage templates**: Complete validation and deployment stages that can be reused across pipelines
- **Job templates**: Specific jobs like security scanning, linting, and infrastructure validation
- **Task templates**: Individual tasks for Terraform/Bicep operations and Azure authentication
- **Variable templates**: Shared variable definitions for environments and configurations

### Template benefits

- **Consistency**: Standardized pipeline patterns across all components and blueprints
- **Maintainability**: Updates in template files propagate to all consuming pipelines
- **Matrix builds**: Conditional execution based on changed components for efficient resource usage
- **Environment promotion**: Same templates used across dev, staging, and production environments

### Template organization

Templates are organized in `.azdo/templates/` with clear separation by function:

- **Validation templates**: Code quality, security scanning, and infrastructure validation
- **Deployment templates**: Environment-specific deployment and post-deployment validation
- **Utility templates**: Common tasks like authentication, caching, and artifact management

## Core templates

### Matrix folder check template

**Location**: `.azdo/templates/matrix-folder-check-template.yml`

Dynamically detects changed components and generates pipeline matrices for:

- Terraform components in `src/**/terraform/**`
- Bicep components in `src/**/bicep/**`
- Scripts and configuration changes

### Component validation templates

**Terraform validation**: `.azdo/templates/cluster-test-terraform-template.yml`
**Bicep validation**: `.azdo/templates/docs-check-bicep-template.yml`

Provide standardized validation with configurable scope:

- **Format checking**: Terraform fmt and Bicep linting
- **Security scanning**: Checkov integration for policy compliance
- **Documentation validation**: Ensures docs stay in sync with code changes

### Security and compliance templates

**Checkov template**: `.azdo/templates/checkov-template.yml`
**MegaLinter template**: `.azdo/templates/megalinter-template.yml`

Centralized security and quality validation:

- Multi-framework security scanning (Terraform, Bicep, Docker)
- Code quality validation across multiple languages
- Compliance checking and policy enforcement

### Variable compliance templates

**Terraform**: `.azdo/templates/variable-compliance-terraform-template.yml`
**Bicep**: `.azdo/templates/variable-compliance-bicep-template.yml`

Ensure consistent variable definitions across modules and maintain parameter compliance.

## Usage patterns

### Main pipeline integration

```yaml
stages:
  - template: templates/matrix-folder-check-template.yml

  - template: templates/cluster-test-terraform-template.yml
    parameters:
      componentPath: $(matrix.component)
      environment: 'dev'
```

### Variable template usage

```yaml
variables:
  - template: templates/variables/common-variables.yml
  - template: templates/variables/dev-variables.yml
```

### Conditional template execution

```yaml
  - template: templates/checkov-template.yml
  parameters:
    scanPath: 'src/'
    frameworks: 'terraform,bicep'
```

## Related documentation

- [Azure DevOps Guide][azure-devops-guide] - Main Azure DevOps pipeline documentation
- [CI/CD Best Practices][ci-cd-best-practices] - Implementation guidelines

<!-- Reference Links -->
[azure-devops-guide]: ../azure-devops.md
[ci-cd-best-practices]: ../ci-cd-best-practices.md

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
