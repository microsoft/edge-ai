---
title: GitHub workflow templates
description: Design and implementation patterns for reusable GitHub Actions workflows in the Edge AI Accelerator project
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: reference
keywords:
  - github actions
  - reusable workflows
  - template design
  - workflow architecture
  - ci/cd patterns
  - modular workflows
estimated_reading_time: 4
---

## GitHub Workflow Templates

Documentation of reusable GitHub Actions workflow design patterns and architecture used in the Edge AI Accelerator project.

## In this guide

- [Template architecture](#template-architecture)
- [Core templates](#core-templates)
- [Usage patterns](#usage-patterns)

## Template architecture

Our GitHub Actions workflows follow a modular, reusable design with three main types:

### Reusable workflows

Complete workflows that can be called from other workflows using `workflow_call`. These provide:

- **Component validation**: Standardized validation for Terraform and Bicep components
- **Matrix generation**: Dynamic detection of changed components for targeted builds
- **Security scanning**: Centralized security validation with Checkov and other tools
- **Documentation validation**: Automated checks for Terraform and Bicep documentation

### Composite actions

Custom actions stored in `.github/actions/` that combine multiple steps:

- **terraform-setup**: Terraform installation, caching, and initialization
- **bicep-validate**: Bicep linting and template validation
- **azure-auth**: Standardized Azure authentication setup
- **security-scan**: Multi-framework security scanning

### Template benefits

- **Consistency**: Standardized patterns across all components and blueprints
- **Maintainability**: Updates in one place propagate to all consumers
- **Matrix builds**: Only validate/deploy changed components, not the entire codebase
- **Parameterization**: Environment-specific behavior through inputs and secrets

## Core templates

### Component validation workflow

**Location**: `.github/workflows/template-component-validation.yml`

Validates individual components (Terraform/Bicep) with configurable scope levels:

- **Basic**: Format checking and syntax validation
- **Standard**: Includes planning and linting
- **Full**: Adds documentation validation and security scanning

### Matrix generation workflow

**Location**: `.github/workflows/template-matrix-generation.yml`

Dynamically detects changed components and generates build matrices for:

- Terraform components in `src/**/terraform/**`
- Bicep components in `src/**/bicep/**`
- Scripts and configurations

### Security validation workflow

Uses Checkov and other tools to scan infrastructure code for:

- Security misconfigurations
- Policy violations
- Secret detection
- Compliance validation

## Usage patterns

### Main workflow integration

```yaml
jobs:
  generate-matrix:
    uses: ./.github/workflows/template-matrix-generation.yml

  validate-components:
    needs: generate-matrix
    strategy:
      matrix: ${{ fromJson(needs.generate-matrix.outputs.component-matrix) }}
    uses: ./.github/workflows/template-component-validation.yml
    with:
      component-path: ${{ matrix.component }}
      component-type: ${{ matrix.type }}
```

### Composite action usage

```yaml
  - name: Setup and Validate Terraform
  uses: ./.github/actions/terraform-setup
  with:
    working-directory: ${{ matrix.component }}
```

## Related documentation

- [GitHub Actions Workflows][github-actions-guide] - Main workflow documentation
- [CI/CD Best Practices][ci-cd-best-practices] - Implementation guidelines

<!-- Reference Links -->
[github-actions-guide]: ../github-actions.md
[ci-cd-best-practices]: ../ci-cd-best-practices.md

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
