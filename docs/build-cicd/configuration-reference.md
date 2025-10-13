---
title: Configuration reference
description: Reference guide for build and CI/CD configuration files used in the Edge AI Accelerator project
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: reference
keywords:
  - configuration
  - ci/cd
  - build settings
  - yaml
  - json
  - reference
  - linting
  - validation
estimated_reading_time: 4
---

## Configuration Reference

Complete reference for all configuration files used in the Edge AI Accelerator project's build and CI/CD processes.

## In this guide

- [CI/CD pipeline configuration](#cicd-pipeline-configuration)
- [Code quality and linting](#code-quality-and-linting)
- [Security and compliance](#security-and-compliance)
- [Build and deployment tools](#build-and-deployment-tools)
- [Documentation generation](#documentation-generation)

## CI/CD pipeline configuration

### Azure DevOps pipelines

| File                                     | Purpose                                                               | Location           |
|------------------------------------------|-----------------------------------------------------------------------|--------------------|
| [`azure-pipelines.yml`][azure-pipelines] | Main Azure DevOps pipeline definition                                 | Repository root    |
| [Template files][azdo-templates]         | Reusable pipeline templates for validation, deployment, and utilities | `.azdo/templates/` |

**Key templates**:

- [`matrix-folder-check-template.yml`][matrix-template] - Dynamic component detection
- [`application-build-template.yaml`][application-build-template] - Multi-language application build orchestration
- [`cluster-test-terraform-template.yml`][terraform-test] - Terraform validation
- [`docs-check-bicep-template.yml`][bicep-docs] - Bicep documentation validation
- [`docs-validation-template.yml`][docs-validation-template] - Comprehensive documentation validation
- [`checkov-template.yml`][checkov-template] - Security scanning
- [`megalinter-template.yml`][megalinter-template] - Code quality validation
- [`aio-version-checker-template.yml`][aio-version-template] - Azure IoT Operations version validation
- [`resource-provider-pwsh-tests-template.yml`][resource-provider-template] - Azure resource provider tests
- [`wiki-update-template.yml`][wiki-update-template] - Documentation synchronization

### GitHub Actions workflows

| File                                | Purpose                             | Location             |
|-------------------------------------|-------------------------------------|----------------------|
| [Workflow files][github-workflows]  | GitHub Actions workflow definitions | `.github/workflows/` |
| [Composite actions][github-actions] | Reusable action components          | `.github/actions/`   |

**Key workflows**:

- [`cluster-test-terraform.yml`][gh-terraform] - Terraform component testing
- [`docs-check-terraform.yml`][gh-terraform-docs] - Terraform documentation validation
- [`docs-check-bicep.yml`][gh-bicep-docs] - Bicep documentation validation
- [`aio-version-checker.yml`][gh-aio-version] - Azure IoT Operations version validation

## Code quality and linting

### MegaLinter configuration

| File                                    | Purpose                                        | Documentation                             |
|-----------------------------------------|------------------------------------------------|-------------------------------------------|
| [`.mega-linter.yml`][megalinter-config] | Primary linting and code quality configuration | [Security Scanning Guide][security-guide] |

**Enabled linters**:

- Shell scripting (Bash, ShellCheck)
- Infrastructure as Code (Terraform, Bicep)
- Container configuration (Dockerfile, Kubernetes)
- Documentation (Markdown)
- PowerShell
- Security scanning (GitLeaks, Grype, SecretLint)
- Container image vulnerability scanning (Grype)
- Language-specific dependency audits (.NET, Rust, Node.js, Python)

### Language-specific linting

| File                                           | Purpose                          | Location        |
|------------------------------------------------|----------------------------------|-----------------|
| [`PSScriptAnalyzerSettings.psd1`][ps-settings] | PowerShell script analysis rules | Repository root |
| [`.cspell.json`][cspell-config]                | Spell checking configuration     | Repository root |

## Security and compliance

### Security scanning

| File                                                  | Purpose                                               | Documentation                             |
|-------------------------------------------------------|-------------------------------------------------------|-------------------------------------------|
| [`.checkov.yml`][checkov-config]                      | Checkov security scanning configuration               | [Security Scanning Guide][security-guide] |
| [`Invoke-ContainerSecurityScan.ps1`][container-scan]  | Container image vulnerability scanning with Grype     | [Security Scanning Guide][security-guide] |
| [`Invoke-SecurityGate.ps1`][security-gate]            | Centralized security gate enforcement                 | [Security Scanning Guide][security-guide] |
| [`Invoke-SecurityReportCompression.ps1`][report-comp] | Security report compression and artifact optimization | [Security Scanning Guide][security-guide] |
| Security templates                                    | Azure DevOps security validation templates            | [Template Documentation][template-docs]   |

### Compliance validation

| File                          | Purpose                                 | Location           |
|-------------------------------|-----------------------------------------|--------------------|
| Variable compliance templates | Terraform and Bicep variable validation | `.azdo/templates/` |
| Resource provider tests       | PowerShell-based compliance testing     | `.azdo/templates/` |

## Build and deployment tools

### Infrastructure as Code

| File                                    | Purpose                                   | Location        |
|-----------------------------------------|-------------------------------------------|-----------------|
| [`bicepconfig.json`][bicep-config]      | Bicep CLI configuration and linting rules | Repository root |
| [`.terraform-docs.yml`][tf-docs-config] | Terraform documentation generation        | Repository root |

### Package management

| File                               | Purpose                               | Location        |
|------------------------------------|---------------------------------------|-----------------|
| [`package.json`][package-json]     | Node.js dependencies and npm scripts  | Repository root |
| [`requirements.txt`][requirements] | Python dependencies for build scripts | Repository root |
| [`Cargo.toml`][cargo-config]       | Rust dependencies (if applicable)     | Repository root |

## Documentation generation

### Configuration files

| File                                      | Purpose                                  | Documentation                        |
|-------------------------------------------|------------------------------------------|--------------------------------------|
| [`docsify-url-config.js`][docsify-config] | Docsify documentation site configuration | [Build Scripts Guide][build-scripts] |
| [`GitVersion.yml`][gitversion-config]     | Semantic versioning configuration        | [Build Scripts Guide][build-scripts] |

### Build automation

| File                        | Purpose                                           | Location   |
|-----------------------------|---------------------------------------------------|------------|
| Documentation build scripts | Automated documentation generation and validation | `scripts/` |
| Sidebar generation scripts  | Dynamic navigation generation                     | `scripts/` |

## Usage patterns

### Local development

Most configuration files support local development workflows:

```bash
# Run MegaLinter locally
npx mega-linter-runner --flavor terraform

# Validate Bicep templates
az bicep build --file template.bicep

# Generate Terraform docs
terraform-docs markdown table . > README.md
```

### CI/CD integration

Configuration files are automatically used by:

- **Azure DevOps**: Reads `azure-pipelines.yml` and template files
- **GitHub Actions**: Uses workflow files and composite actions
- **MegaLinter**: Processes `.mega-linter.yml` configuration
- **Checkov**: Applies `.checkov.yml` security policies

## Related documentation

- [Build Scripts Guide][build-scripts] - Automated build processes
- [CI/CD Best Practices][best-practices] - Implementation guidelines
- [Security Scanning Guide][security-guide] - Security validation processes
- [Azure DevOps Guide][azure-devops-guide] - Azure pipeline documentation
- [GitHub Actions Guide][github-actions-guide] - GitHub workflow documentation

<!-- Reference Links -->
[azure-pipelines]: /azure-pipelines.yml
[azdo-templates]: /.azdo/templates/
[matrix-template]: /.azdo/templates/matrix-folder-check-template.yml
[application-build-template]: /.azdo/templates/application-build-template.yaml
[terraform-test]: /.azdo/templates/cluster-test-terraform-template.yml
[bicep-docs]: /.azdo/templates/docs-check-bicep-template.yml
[docs-validation-template]: /.azdo/templates/docs-validation-template.yml
[checkov-template]: /.azdo/templates/checkov-template.yml
[megalinter-template]: /.azdo/templates/megalinter-template.yml
[aio-version-template]: /.azdo/templates/aio-version-checker-template.yml
[resource-provider-template]: /.azdo/templates/resource-provider-pwsh-tests-template.yml
[wiki-update-template]: /.azdo/templates/wiki-update-template.yml
[github-workflows]: /.github/workflows/
[github-actions]: /.github/actions/
[gh-terraform]: /.github/workflows/cluster-test-terraform.yml
[gh-terraform-docs]: /.github/workflows/docs-check-terraform.yml
[gh-bicep-docs]: /.github/workflows/docs-check-bicep.yml
[gh-aio-version]: /.github/workflows/aio-version-checker.yml
[megalinter-config]: /.mega-linter.yml
[ps-settings]: /PSScriptAnalyzerSettings.psd1
[cspell-config]: /.cspell.json
[checkov-config]: /.checkov.yml
[container-scan]: /scripts/security/Invoke-ContainerSecurityScan.ps1
[security-gate]: /scripts/security/Invoke-SecurityGate.ps1
[report-comp]: /scripts/security/Invoke-SecurityReportCompression.ps1
[bicep-config]: /bicepconfig.json
[tf-docs-config]: /.terraform-docs.yml
[package-json]: /package.json
[requirements]: /requirements.txt
[cargo-config]: /src/500-application/**/**/**/Cargo.toml
[docsify-config]: /docsify-url-config.js
[gitversion-config]: /GitVersion.yml
[build-scripts]: build-scripts.md
[best-practices]: ci-cd-best-practices.md
[security-guide]: security-scanning.md
[template-docs]: templates/
[azure-devops-guide]: azure-devops.md
[github-actions-guide]: github-actions.md

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
