---
title: GitHub Actions Configuration
description: Configuration guide for GitHub Actions workflows and CI/CD setup for the Edge AI Accelerator repository
author: Edge AI Team
ms.date: 2025-06-06
ms.topic: hub-page
estimated_reading_time: 7
keywords:
  - github-actions
  - workflows
  - ci-cd
  - configuration
  - automation
  - terraform
  - bicep
  - infrastructure as code
  - service principal
  - azure authentication
  - megalinter
  - security scanning
  - pull request validation
  - deployment
  - reusable workflows
  - template workflows
---

This repository can be cloned and used as the base image for an IaC repo with
integrated CI/CD. There is minimal configuration required to enable the workflows,
though fully automated, IaC-based setup is under design/construction.

## Engineering Principles

This project follows a set of guiding principles for all development and
automation:

- All IaC goes through a validation process on commit
- All IaC dependencies are monitored for outdated packages
- A reasonable effort will be made to test all IaC
- All Iac changes can be easily checked against
- empty environments
- QA and Integration Environments
- Pre-production environments, and
- Production Environments
- All IaC changes will produce detailed deployment plans for security reviews
- All IaC changes will use a decimal system for process organization
- All build processes will be built on each pull request
- Key build processes will be run on each merge to main
- All workflow components should be templatized for reuse and consistency
- Workflow templates should be modular and parameterized for flexibility and reuse

## Build Feature Sets

The build workflow provides several key features, with more on the way:

- Checks Terraform Provider versions for update opportunities and publishes build warning
- Runs a lightweight vulnerability scan for all dependant packages
- Runs file linting on a wide variety of languages and file types using MegaLinter
- Performs a matrix build on only resources that have been modified in the current PR
- Publishes Terraform Plans for all changed resources within the current PR
- Runs unit tests on changed Terraform within the current PR
- Provides modular, reusable workflow components for flexible workflow creation
- Ensures consistent validation steps across all workflows through shared components
- Enables PR comment integration for linting results through MegaLinter
- Optimizes workflow performance with intelligent caching mechanisms

## Getting Started

The following sections will walk you through the process of configuring GitHub
Actions for this repository.

### Create GitHub Service Principal in Azure

Default practices for establishing connections between GitHub Actions
and an Azure subscription is through the use of a Service Principal. Please follow
the Azure documentation for creating a [GitHub Action Authentication](https://learn.microsoft.com/azure/developer/github/connect-from-azure)
in your subscription, before proceeding. We recommend using contributor rights
until further, fine-grained access guidance is added to this repository.

### Configure GitHub Secrets

After creating the service principal, you'll need to store the credentials as GitHub Secrets:

1. Navigate to your GitHub repository
2. Go to "Settings" → "Secrets and variables" → "Actions"
3. Add the following secrets:
   - `AZURE_CLIENT_ID`: The Application (client) ID of the service principal
   - `AZURE_TENANT_ID`: The Azure tenant ID
   - `AZURE_SUBSCRIPTION_ID`: The Azure subscription ID
   - `AZURE_CLIENT_SECRET`: The service principal's client secret

### GitHub Actions Workflow System

This repository implements a modular approach to workflow definitions. Instead of monolithic workflow files, we break down common tasks into reusable components that can be combined in different ways. This approach provides several benefits:

1. **Consistency**: Ensures the same validation steps are applied across all workflows
2. **Maintainability**: Changes to a workflow component only need to be made in one place
3. **Reusability**: Common tasks can be easily reused across different workflows and copied/referenced for additional projects
4. **Flexibility**: Components can be parameterized for different scenarios

#### Core CI/CD Orchestration Workflows

The repository includes two primary workflows that orchestrate the overall CI/CD process:

| Workflow            | Trigger                             | Purpose                                                 |
|---------------------|-------------------------------------|---------------------------------------------------------|
| `main.yml`          | Push to main branch, manual trigger | Complete validation and deployment to environments      |
| `pr-validation.yml` | Pull requests to main branch        | Validates changes before merging to ensure code quality |

These core workflows typically call the template workflows above in a specific sequence, providing a comprehensive validation and deployment process.

#### Available Template Workflows

The following reusable template workflows are available in the `.github/workflows` directory:

| Workflow                            | Purpose                                                                   | Documentation                                                |
|-------------------------------------|---------------------------------------------------------------------------|--------------------------------------------------------------|
| `aio-version-checker.yml`           | Checks component versions against latest available releases               | [Workflow Documentation](./aio-version-checker.md)           |
| `cluster-test-terraform.yml`        | Performs comprehensive testing of Terraform modules against real clusters | [Workflow Documentation](./cluster-test-terraform.md)        |
| `docs-check-bicep.yml`              | Validates documentation quality including Bicep docs and URL checks       | [Workflow Documentation](./docs-check-bicep.md)              |
| `docs-check-terraform.yml`          | Validates documentation quality including Terraform docs and URL checks   | [Workflow Documentation](./docs-check-terraform.md)          |
| `matrix-folder-check.yml`           | Creates dynamic matrices of changed folders for downstream jobs           | [Workflow Documentation](./matrix-folder-check.md)           |
| `megalinter.yml`                    | Provides linting capabilities across multiple languages and file formats  | [Workflow Documentation](./megalinter.md)                    |
| `pages-deploy.yml`                  | Deploys documentation to GitHub Pages                                     | [Workflow Documentation](./pages-deploy.md)                  |
| `resource-provider-pwsh-tests.yml`  | Validates Azure resource provider registration scripts                    | [Workflow Documentation](./resource-provider-pwsh-tests.md)  |
| `variable-compliance-bicep.yml`     | Ensures consistent Bicep variable definitions across modules              | [Workflow Documentation](./variable-compliance-bicep.md)     |
| `variable-compliance-terraform.yml` | Ensures consistent Terraform variable definitions across modules          | [Workflow Documentation](./variable-compliance-terraform.md) |

> **Note:** All workflow documentation follows a standardized format that includes overview,
> features, parameters, usage examples, implementation details, and troubleshooting sections.
> This consistent structure makes it easier to learn and use the workflows effectively.

#### Core CI/CD Workflows

The repository includes two primary workflows that orchestrate the overall CI/CD process:

| Workflow            | Trigger                             | Purpose                                                 | Documentation                                |
|---------------------|-------------------------------------|---------------------------------------------------------|----------------------------------------------|
| `main.yml`          | Push to main branch, manual trigger | Complete validation and deployment to environments      | [Workflow Documentation](./main.md)          |
| `pr-validation.yml` | Pull requests to main branch        | Validates changes before merging to ensure code quality | [Workflow Documentation](./pr-validation.md) |

#### Documentation Template

To maintain consistency across all workflow documentation, this repository includes a standardized documentation template. This template serves several important purposes:

- Provides a uniform structure for all workflow documentation
- Ensures comprehensive coverage of essential information (inputs, outputs, examples, etc.)
- Makes it easier for new team members to understand how GitHub Actions workflows work
- Helps GitHub Copilot generate properly formatted documentation when assisting with updates

When creating documentation for a new workflow or updating existing workflow documentation:

1. Use the `workflow-template.md` as a starting point
2. Replace the placeholder content with information specific to your workflow
3. Maintain the standardized formatting, especially for inputs and outputs tables
4. Include all relevant sections (Overview, Features, Inputs, Outputs, etc.)

This standardized approach significantly improves documentation quality and helps users find the information they need quickly and consistently across all workflows.

##### Pull Request Validation Workflow

The PR validation workflow is designed to:

1. Validate code quality (linting, formatting)
2. Check for security vulnerabilities
3. Validate Terraform configurations
4. Run tests on modified components
5. Generate Terraform plans for review

This ensures that code changes meet quality standards before being merged to the main branch. The workflow posts results directly to the pull request, making the review process more efficient.

##### Main Deployment Workflow

The main workflow is triggered when changes are merged to the main branch and handles:

1. Running all validation checks on the integrated codebase
2. Building necessary artifacts for deployment
3. Deploying to development environments automatically (if configured)
4. Preparing deployment plans for higher environments
5. Optionally deploying to production environments (with approvals)

This workflow implements the continuous deployment aspect of the CI/CD pipeline, ensuring that validated changes can be reliably deployed to target environments.

#### How to Use GitHub Workflows

GitHub Action workflows are defined in YAML files in the `.github/workflows` directory. They automatically run based on their configured triggers, such as push events or pull requests.

#### Example GitHub Action Workflow

```yaml
name: Linting

on:
  pull_request:
    branches: [ main ]
  workflow_dispatch:

jobs:
  megalinter:
    name: MegaLinter
    uses: ./.github/workflows/megalinter.yml
    with:
      github_comment_reporter: true
      github_status_reporter: true
      validate_all_codebase: ${{ github.event_name == 'push' && github.ref == 'refs/heads/main' }}
    secrets: inherit
```

### Required GitHub Secrets

The following secrets are required/optional to run this repository's main workflows.
Please see [Using secrets in GitHub Actions](https://docs.github.com/en/actions/security-guides/using-secrets-in-github-actions) for this process.

| Secret                        | Suggested value            | Details                                                                                                                                       |
|:------------------------------|:---------------------------|:----------------------------------------------------------------------------------------------------------------------------------------------|
| `AZURE_SUBSCRIPTION_ID`       | Azure subscription GUID    | Used for authenticating to Azure                                                                                                              |
| `AZURE_CLIENT_ID`             | Service Principal App ID   | Used for authenticating to Azure                                                                                                              |
| `AZURE_TENANT_ID`             | Azure Tenant ID            | Used for authenticating to Azure                                                                                                              |
| `AZURE_CLIENT_SECRET`         | Service Principal Secret   | Used for authenticating to Azure                                                                                                              |
| `TF_VAR_CUSTOM_LOCATIONS_OID` | OID of Arc Custom Location | [Create and manage custom locations on Azure Arc-enabled Kubernetes](https://learn.microsoft.com/azure/azure-arc/kubernetes/custom-locations) |

### Environment Variables

The following environment variables can be configured in your workflows:

| Variable                         | Suggested value    | Details                                                                                             |
|:---------------------------------|:-------------------|:----------------------------------------------------------------------------------------------------|
| `TF_VAR_ENVIRONMENT`             | `prod`             | e.g. `dev`, `stage`, `prod`                                                                         |
| `TF_VAR_EXISTING_RESOURCE_GROUP` | `build_system`     | useful for integration environments                                                                 |
| `TF_VAR_LOCATION`                | `westus`           | [Azure region](https://azure.microsoft.com/explore/global-infrastructure/geographies/) to deploy to |
| `TF_VAR_RESOURCE_PREFIX`         | `build`            | prefix for all created resources                                                                    |
| `TF_VAR_VM_SKU_SIZE`             | `Standard_D8s_v3`  | [VM Size](https://learn.microsoft.com/azure/virtual-machines/sizes)                                 |
| `TF_VAR_VM_USERNAME`             | VM admin user name | Username for provisioned VMs                                                                        |

## Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Workflow Syntax for GitHub Actions](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Azure Login Action](https://github.com/marketplace/actions/azure-login)
- [Terraform GitHub Actions](https://github.com/hashicorp/terraform-github-actions)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
