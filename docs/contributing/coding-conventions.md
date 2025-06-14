---
title: Coding Conventions
description: Comprehensive coding standards and conventions for the AI on Edge Flagship Accelerator project, covering Terraform, Bicep, PowerShell, Python, and documentation standards
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: reference
estimated_reading_time: 14
keywords:
  - coding conventions
  - coding standards
  - terraform standards
  - bicep standards
  - powershell standards
  - python standards
  - documentation standards
  - file naming
  - best practices
---

This document outlines the coding conventions and standards for this repository. Following these conventions ensures
consistency across the codebase and makes it easier for contributors to collaborate effectively. For information about
the overall contribution process, please refer to our [Contributing Guide](contributing.md).

This document uses terminology as defined in [RFC 2119](https://www.rfc-editor.org/rfc/rfc2119) where the keywords "
MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" are to
be interpreted as described in the RFC.

## Table of Contents

- [Table of Contents](#table-of-contents)
- [Folder Structure and Naming Conventions](#folder-structure-and-naming-conventions)
  - [Root-Level Organization](#root-level-organization)
  - [Source Components (`/src`)](#source-components-src)
  - [Blueprints (`/blueprints`)](#blueprints-blueprints)
  - [Documentation (`/docs`)](#documentation-docs)
  - [Scripts (`/scripts`)](#scripts-scripts)
  - [DevOps Configuration (`/docs/build-cicd`)](#devops-configuration-docsbuild-cicd)
  - [GitHub Workflows (`/.github`)](#github-workflows-github)
- [Linting and Code Quality](#linting-and-code-quality)
- [Infrastructure as Code](#infrastructure-as-code)
  - [Terraform Conventions](#terraform-conventions)
    - [Module Organization (Terraform)](#module-organization-terraform)
    - [Variable Definitions (Terraform)](#variable-definitions-terraform)
    - [Terraform Style Guide](#terraform-style-guide)
  - [Bicep Conventions](#bicep-conventions)
    - [Module Organization (Bicep)](#module-organization-bicep)
    - [Variable Definitions (Bicep)](#variable-definitions-bicep)
- [Git Workflow](#git-workflow)
  - [Conventional Commits](#conventional-commits)
    - [Commit Structure](#commit-structure)
    - [Types](#types)
    - [Examples](#examples)
  - [Pull Request Conventions](#pull-request-conventions)
  - [Work Item Association and Customer Context](#work-item-association-and-customer-context)
    - [Work Item Linkage](#work-item-linkage)
    - [Customer Context](#customer-context)
    - [Reviewer Assignment](#reviewer-assignment)
- [Documentation](#documentation)
  - [Automated Documentation Checks](#automated-documentation-checks)
  - [Wiki Auto-Publishing](#wiki-auto-publishing)
- [Security and Compliance Standards](#security-and-compliance-standards)
  - [Security Best Practices](#security-best-practices)
  - [Compliance Requirements](#compliance-requirements)
- [Testing Standards](#testing-standards)
  - [Component Testing](#component-testing)
  - [Blueprint Testing](#blueprint-testing)
- [AI-Assisted Development Standards](#ai-assisted-development-standards)
  - [GitHub Copilot Integration](#github-copilot-integration)
  - [Best Practices for AI Tools](#best-practices-for-ai-tools)
- [Performance and Optimization](#performance-and-optimization)
  - [Resource Optimization](#resource-optimization)
  - [Development Efficiency](#development-efficiency)
- [Review and Quality Assurance](#review-and-quality-assurance)
  - [Code Review Standards](#code-review-standards)
  - [Continuous Improvement](#continuous-improvement)
- [Additional Resources](#additional-resources)

## Folder Structure and Naming Conventions

The repository follows a structured organization to maintain clarity and separation of concerns. This section outlines
where different types of files SHOULD be placed and how folders SHOULD be named.

### Root-Level Organization

The repository is organized into these primary directories:

| Directory          | Purpose                                                         |
|--------------------|-----------------------------------------------------------------|
| `/src`             | Individual infrastructure components as reusable modules        |
| `/blueprints`      | Deployable infrastructure combinations using the src components |
| `/docs`            | Project documentation and architectural decision records        |
| `/scripts`         | Utility scripts for development, deployment, and maintenance    |
| `/docs/build-cicd` | CI/CD pipeline definitions and configuration                    |
| `/.devcontainer`   | Development container configuration for consistent environments |

### Source Components (`/src`)

The `/src` directory contains all individual infrastructure components:

- Components MUST follow the decimal naming convention for deployment order (e.g., `010-security-identity`,
  `100-cncf-cluster`)
- Component names SHOULD clearly indicate their purpose
- Each component directory MUST contain:
  - A `terraform` subdirectory for the Terraform module implementation
  - A `README.md` file documenting the module's purpose and usage
  - A `tests` directory with Terraform tests
  - A `ci` directory with CI-specific configurations when applicable
  - Tool-generated, SDK-style readmes such as terraform-docs

Example structure:

```text
src/
  000-cloud/
    010-security-identity/
      README.md
      terraform/          # This is a COMPONENT MODULE
        main.tf
        variables.tf
        variables.core.tf
        variables.deps.tf
        outputs.tf
        versions.tf
        README.md
        modules/
          key-vault/      # This is an INTERNAL MODULE
            main.tf
            variables.tf
            outputs.tf
      bicep/              # This is a BICEP COMPONENT MODULE
      ci/
        terraform/        # This is a CI TERRAFORM DIRECTORY
          main.tf
          variables.tf
          versions.tf
        bicep/            # This is a CI BICEP DIRECTORY
```

### Blueprints (`/blueprints`)

Blueprints combine multiple components from `/src` to create complete deployable infrastructure solutions:

- Blueprint directories SHOULD use descriptive names reflecting their purpose
- The main blueprint files MUST be in either `terraform` or `bicep` subdirectories
- Each blueprint MUST include a README.md describing:
  - Purpose of the blueprint
  - Components included
  - Deployment instructions
  - Required parameters

Example structure:

```text
/blueprints/
  terraform/
    full-single-cluster/
      main.tf
      variables.tf
      outputs.tf
      README.md
  bicep/
    minimal-deployment/
      main.bicep
      parameters.json
      README.md
```

### Documentation (`/docs`)

The `/docs` directory contains:

- Project-wide documentation MUST be in markdown format
- Architectural decision records (ADRs) MUST follow the format `adr-NNN-title.md`
- Technical specifications SHOULD include diagrams where appropriate
- Diagrams SHOULD use standard formats (PNG, SVG) with source files when available

### Scripts (`/scripts`)

The `/scripts` directory contains utility scripts for various purposes:

- Deployment scripts SHOULD be in a relevant subdirectory (e.g., `deployment`)
- Scripts MUST include inline documentation and usage information
- Cross-platform scripts SHOULD be provided where possible (both PowerShell and Bash)
- Scripts MUST be executable and have consistent permissions

Notable scripts include:

- `update-all-terraform-docs.sh`: Updates documentation for all Terraform modules
- `tf-docs-check.sh`: Verifies Terraform documentation is current
- `wiki-build.sh`: Compiles documentation for Azure DevOps wiki publication
- `aio-version-checker.sh`: Verifies Azure IoT Operations component versions
- `tf-var-compliance-check.py`: Ensures variable consistency across modules

### DevOps Configuration (`/docs/build-cicd`)

The `/docs/build-cicd` directory contains CI/CD pipeline configurations:

- Pipeline definitions MUST use the `.yml` extension
- Template files SHOULD include `-template` in their name
- Each pipeline template MUST have an accompanying markdown document explaining its usage
- Pipeline variables and secrets SHOULD be documented but not committed

### GitHub Workflows (`/.github`)

The `/.github` directory contains GitHub-specific configurations and workflows:

- GitHub Actions workflows MUST be stored in the `/.github/workflows` directory with the `.yml` extension
- Workflow names MUST clearly indicate their purpose (e.g., `ci.yml`, `release.yml`, `docs-validation.yml`)
- Issue and PR templates MUST be stored in `/.github/ISSUE_TEMPLATE` and `/.github/PULL_REQUEST_TEMPLATE` directories
- GitHub-specific documentation (e.g., `SECURITY.md`, `SUPPORT.md`) SHOULD be stored in the root or `/.github` directory
- GitHub environment configurations SHOULD be documented but secret values MUST NOT be committed
- Reusable workflow files SHOULD use the format `reusable-[purpose].yml`

Example structure:

```text
/.github/
  workflows/
    ci.yml                     # Main CI workflow
    dependency-review.yml      # Dependency scanning
    release.yml                # Release automation
    reusable-terraform.yml     # Reusable Terraform workflow
  ISSUE_TEMPLATE/
    bug-report.md
    feature-request.md
  PULL_REQUEST_TEMPLATE.md
  dependabot.yml               # Dependabot configuration
  CODEOWNERS                   # Code ownership definitions
```

GitHub workflows SHOULD follow these principles:

- Single responsibility (each workflow should have a clear purpose)
- Use of GitHub environment variables and secrets for configuration
- Consistent job and step naming conventions
- Appropriate triggering conditions (e.g., branches, paths, events)
- Clear job dependencies and workflow structure
- Use of reusable workflows for common tasks
- Consistent error handling and notifications

## Linting and Code Quality

We use [MegaLinter](https://megalinter.github.io/) as our comprehensive linting solution to ensure code quality across
all languages and file types in the repository.

For detailed information about our MegaLinter configuration, integration with our CI/CD pipeline, and how to use it in
your development workflow, please refer to our [MegaLinter documentation](./build-cicd/azure-pipelines/templates/megalinter-template.md).

This includes:

- How to run MegaLinter locally
- Available linters and configuration options
- CI/CD integration details
- Pipeline optimization with caching

## Infrastructure as Code

### Terraform Conventions

#### Module Organization (Terraform)

- Each module MUST be in its own directory under `/src` with a meaningful name
- Modules MUST follow the decimal naming convention (e.g., `000-subscription`, `010-vm-host`) to indicate deployment
  order
- Each module MUST include a `README.md` with documentation generated by `terraform-docs`
- Each module MUST include a `tests` directory with Terraform tests for the module

#### Variable Definitions (Terraform)

Variables MUST be defined consistently across modules:

```hcl
variable "resource_prefix" {
  description = "Prefix for all resources created by this module"
  type        = string
  validation {
    condition     = length(var.resource_prefix) <= 13
    error_message = "The resource_prefix value must be 13 characters or less."
  }
}
```

1. **Naming Convention**:
   - Variable names MUST use `snake_case`
   - Variable names MUST be descriptive and indicate purpose
   - Environment-specific variables MUST be prefixed with `env_` (e.g., `env_name`)
   - Common concept variables MUST use consistent names across modules
   - Boolean variables SHOULD start with `should_` or `is_`
2. **Documentation**:
   - Descriptions MUST end with a period
   - Descriptions MUST explain the purpose, expected format, and constraints
   - For complex variables, descriptions SHOULD include examples
3. **Type Constraints**:
   - Variables MUST specify their type
   - Specific subtypes SHOULD be used where applicable (e.g., `list(string)` instead of just `list`)
   - Complex types MUST use `object()` with clear attribute definitions
4. **Default Values**:
   - Optional variables SHOULD provide sensible defaults
   - Required variables MUST NOT have defaults
   - Required status MUST be clearly documented
   - Internal Modules MUST NOT have defaults
5. **Validation Rules**:
   - Important constraints SHOULD include validation rules
   - Validation error messages MUST clearly guide the user
   - Validation rules MUST be tested in module tests
6. **Variable Files**:
   - Variables MUST be organized in `variables.tf`, `variables.core.tf`, `variables.deps.tf`, or
     `variables.<internal-module>.tf`
   - Environment-specific values SHOULD use `.tfvars` files
   - Sensitive values MUST NEVER be committed in `.tfvars` files

#### Terraform Style Guide

- All Terraform code MUST be formatted with `terraform fmt` before committing
- Code MUST follow [HashiCorp's Terraform Style Conventions](https://www.terraform.io/docs/language/syntax/style.html)
- Code MUST use consistent indentation (2 spaces)
- Related resources SHOULD be grouped logically
- Resource names and IDs MUST be meaningful and descriptive

### Bicep Conventions

#### Module Organization (Bicep)

- Bicep modules MUST be in a dedicated directory `/modules` within the component directory, module file name should be
  descriptive of the module's purpose
- Each module MUST include a `README.md` with clear documentation
- Parameters and outputs MUST be well-documented within the module

#### Variable Definitions (Bicep)

Bicep parameters MUST follow these conventions:

```bicep
@description('The name of the resource prefix to use for all resources.')
@maxLength(13)
param resourcePrefix string

@description('The Azure region to deploy resources to.')
param location string = resourceGroup().location
```

1. **Naming Convention**:
   - Parameter names MUST use `camelCase`
   - Parameter names MUST be descriptive and indicate purpose
   - Type names MUST use `PascalCase`
   - Resource names MUST use `kebab-case`
   - Common concept parameters MUST use consistent names across modules
2. **Documentation**:
   - All parameters MUST use the `@description()` decorator
   - Descriptions MUST explain the purpose, expected format, and constraints
3. **Type Constraints**:
   - All parameters MUST specify their type
   - Parameters SHOULD use decorators like `@minLength()`, `@maxLength()`, `@allowed()` for validation
   - Constraint violations MUST produce clear error messages
4. **Default Values**:
   - Optional parameters SHOULD provide sensible defaults
   - Required parameters MUST NOT have defaults
   - Context-aware defaults (e.g., `resourceGroup().location`) SHOULD be used when appropriate
5. **Parameter Files**:
   - Environment-specific values SHOULD use parameter files (`.parameters.json`)
   - Sensitive values MUST NEVER be committed in parameter files

## Git Workflow

### Conventional Commits

We follow the [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/) specification for commit messages.
This creates a readable commit history and enables automated versioning and changelog generation.

#### Commit Structure

All commits MUST adhere to this structure:

```text
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

#### Types

Commit types MUST be one of the following:

- **feat**: A new feature
- **fix**: A bug fix
- **docs**: Documentation only changes
- **style**: Changes that do not affect the meaning of the code (white-space, formatting, etc.)
- **refactor**: A code change that neither fixes a bug nor adds a feature
- **perf**: A code change that improves performance
- **test**: Adding missing tests or correcting existing tests
- **build**: Changes that affect the build system or external dependencies
- **ci**: Changes to our CI configuration files and scripts
- **chore**: Other changes that don't modify src or test files
- **revert**: Reverts a previous commit

#### Examples

```text
feat(vm-host): add support for premium SSD disks

This change allows users to specify premium SSD disks for the VM host,
which provides better performance for I/O-intensive workloads.

Fixes #123
```

```text
fix(iot-ops): correct connection string format in messaging module

The connection string was incorrectly formatted, causing connection failures.
This fix ensures the proper format is used.

BREAKING CHANGE: Connection string format has changed and requires reconfiguration.
```

### Pull Request Conventions

Pull request titles MUST follow the Conventional Commits format:

```text
feat(k8s): add support for external secrets
```

Each pull request MUST:

1. Address a single concern
2. Include comprehensive tests
3. Update documentation as needed
4. Pass all CI checks

Each pull request SHOULD:

1. Be reviewed by at least one core team member
2. Include a clear description of the changes and the motivation

### Work Item Association and Customer Context

#### Work Item Linkage

All pull requests MUST have an associated work item in the project backlog:

1. Contributors MUST link their PR to the relevant work item using the Azure DevOps PR creation interface
2. Contributors SHOULD reference the work item ID in the PR description with the format `AB#123`
3. Work items MUST be in an appropriate state (e.g., "In Progress")

#### Customer Context

When code changes relate to a specific customer implementation or request:

1. Contributors SHOULD tag the pull request with the customer's name in the PR's tags section
2. Contributors MUST NOT add NDA or customer specific data to PR titles or descriptions, including:

- NO customer names
- NO specific requirements or constraints that would identify a customer
- NO links to customer-specific documentation
- NO product/project names or descriptions of customer business units

#### Reviewer Assignment

Our repository uses automated reviewer assignment based on the areas of the codebase being modified:

1. Reviewer groups will be automatically assigned based on the directories and components modified
2. The following specialist teams are configured:
   - **IaC Team (Terraform)**: Changes to core Terraform infrastructure modules
   - **IaC Team (Bicep)**: Changes to core Bicep infrastructure modules
   - **Security Reviewers**: Changes to security related folders
   - **TPM Reviewers**: Significant documentation changes including ADRs & tech papers
3. Contributors MUST NOT manually remove automatically assigned reviewers
4. Contributors MAY add additional reviewers if needed for specific expertise or perspective

## Documentation

- Documentation MUST be kept up-to-date with code changes
- Documentation MUST use markdown for all documentation files
- Documentation SHOULD be placed as close as possible to the code it documents
- Contributors MUST run `./scripts/update-all-terraform-docs.sh` to update Terraform module documentation
- Complex features (e.g. a new blueprint) SHOULD include examples
- Breaking changes MUST be prominently documented

### Automated Documentation Checks

The CI pipeline includes checks to ensure documentation is up-to-date:

- `DocsCheckTerraform` verifies that Terraform documentation is current
- `DocsCheckBicep` verifies that Bicep documentation is current
- Documentation changes MUST be included in the same PR as the related code changes

### Wiki Auto-Publishing

The repository includes an automated system that collects all project documentation and publishes it to the Azure DevOps
wiki:

- Documentation from markdown files in `/docs` and component READMEs is automatically gathered
- Upon successful builds of the main branch, documentation is synchronized to the Azure DevOps wiki
- This ensures that the latest documentation is always available in a user-friendly format
- Code and documentation changes are kept in sync through this automated process

The wiki update process:

1. Checks out both the main code repo and the wiki repo
2. Runs the wiki-build.sh script to process and structure documentation
3. Pushes the updated content to the wiki repository

For detailed information about the wiki auto-publishing system, configuration, and how it works, see
the [Wiki Update documentation](./build-cicd/azure-pipelines/templates/wiki-update-template.md).

## Security and Compliance Standards

### Security Best Practices

All infrastructure code MUST follow security best practices:

1. **Secrets Management**:
   - Never commit secrets, API keys, or sensitive data to the repository
   - Use Azure Key Vault for secret storage
   - Reference secrets using secure methods (Key Vault references, Managed Identity)

2. **Resource Security**:
   - Enable encryption at rest and in transit by default
   - Use least privilege access principles
   - Enable audit logging for all resources
   - Follow Azure Security Benchmark recommendations

3. **Network Security**:
   - Use private endpoints where possible
   - Implement network segmentation
   - Apply appropriate firewall rules and NSG configurations

### Compliance Requirements

1. **Code Scanning**:
   - All code MUST pass security scanning (Checkov, Gitleaks)
   - False positives MUST be documented with skip annotations
   - Regular updates to scanning tools and rules

2. **Documentation**:
   - Security configurations MUST be documented
   - Compliance mappings SHOULD be included for regulated environments
   - Risk assessments SHOULD be documented for architectural decisions

## Testing Standards

### Component Testing

Each component MUST include comprehensive testing:

1. **Unit Tests**:
   - Terraform syntax validation
   - Variable type and constraint validation
   - Output verification

2. **Integration Tests**:
   - End-to-end deployment testing
   - Resource dependency validation
   - Cross-component interaction testing

3. **Security Tests**:
   - Infrastructure security scanning
   - Compliance validation
   - Access control verification

### Blueprint Testing

Blueprints MUST undergo additional testing:

1. **Deployment Validation**:
   - Full deployment testing in isolated environments
   - Rollback testing
   - Performance validation

2. **Scenario Testing**:
   - Use case-specific validation
   - Load testing where applicable
   - Disaster recovery testing

## AI-Assisted Development Standards

### GitHub Copilot Integration

When using AI assistance tools:

1. **Code Quality**:
   - All AI-generated code MUST be reviewed for security
   - Follow project conventions consistently
   - Validate against coding standards

2. **Documentation**:
   - Use AI to maintain consistent documentation style
   - Verify AI-generated documentation for accuracy
   - Include realistic examples and use cases

3. **Testing**:
   - Generate comprehensive test cases with AI assistance
   - Validate AI-suggested test scenarios
   - Ensure test coverage meets project requirements

### Best Practices for AI Tools

1. **Context Awareness**:
   - Provide clear context about project structure
   - Reference existing patterns and conventions
   - Specify framework preferences (Terraform vs Bicep)

2. **Validation**:
   - Review all AI suggestions carefully
   - Test generated code thoroughly
   - Verify compliance with project standards

## Performance and Optimization

### Resource Optimization

1. **Cost Management**:
   - Use appropriate SKUs for workload requirements
   - Implement auto-scaling where beneficial
   - Include cost optimization recommendations

2. **Performance**:
   - Choose appropriate Azure regions
   - Optimize for workload characteristics
   - Monitor and tune resource configurations

### Development Efficiency

1. **Code Reusability**:
   - Maximize component reuse across blueprints
   - Avoid duplicating functionality
   - Design for extensibility

2. **Automation**:
   - Automate repetitive tasks
   - Use infrastructure automation tools effectively
   - Implement CI/CD best practices

## Review and Quality Assurance

### Code Review Standards

All contributions MUST undergo thorough code review:

1. **Technical Review**:
   - Code quality and maintainability
   - Security and compliance validation
   - Performance considerations

2. **Documentation Review**:
   - Accuracy and completeness
   - Consistency with project standards
   - User experience considerations

3. **Testing Review**:
   - Test coverage and quality
   - Scenario validation
   - Integration testing completeness

### Continuous Improvement

1. **Feedback Loops**:
   - Regular review of coding standards
   - Community feedback integration
   - Performance metrics analysis

2. **Standards Evolution**:
   - Update standards based on project learnings
   - Incorporate industry best practices
   - Maintain alignment with Azure recommendations

---

## Additional Resources

- [Development Environment Setup](development-environment.md) - Dev Container configuration and tooling
- [AI-Assisted Engineering](ai-assisted-engineering.md) - GitHub Copilot integration and best practices
- [Testing and Validation](testing-validation.md) - Comprehensive testing strategies
- [Contributing Guidelines](contributing.md) - Contribution process and requirements
- [Troubleshooting Guide](troubleshooting.md) - Common issues and solutions

For questions about coding conventions, see our [troubleshooting guide](troubleshooting.md) or reach out through repository discussions.

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
