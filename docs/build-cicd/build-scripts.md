---
title: Build scripts guide
description: Essential build scripts for documentation generation, compliance validation, and security scanning in the Edge AI Accelerator project.
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: reference
keywords:
  - build scripts
  - documentation automation
  - terraform docs
  - bicep docs
  - compliance validation
  - security scanning
  - checkov
  - automation
estimated_reading_time: 4
---

## Build Scripts Guide

Essential build scripts in the `/scripts/` directory that automate application builds, documentation generation, compliance validation, and security scanning for the Edge AI Accelerator project.

## Application build scripts

### Matrix build detection

| Script                        | Purpose                                               | Usage                                         |
|-------------------------------|-------------------------------------------------------|-----------------------------------------------|
| `Detect-Folder-Changes.ps1`   | Detects application/service changes for matrix builds | `./scripts/build/Detect-Folder-Changes.ps1`   |
| `Build-Consistency-Check.ps1` | Validates Azure DevOps and GitHub workflow alignment  | `./scripts/build/Build-Consistency-Check.ps1` |

Enables dynamic matrix builds by detecting changes in application and service directories.

### Application building

| Script                    | Purpose                                        | Usage                                     |
|---------------------------|------------------------------------------------|-------------------------------------------|
| `application-builder.ps1` | Multi-language application build orchestration | `./scripts/build/application-builder.ps1` |

Supports .NET, Rust, Node.js, and Python application builds with integrated security scanning, Docker builds, and SLSA bundle generation.

## In this guide

- [Application build scripts](#application-build-scripts)
- [Documentation scripts](#documentation-scripts)
- [Compliance validation](#compliance-validation)
- [Security scanning](#security-scanning)
- [Version checking](#version-checking)
- [Usage examples](#usage-examples)

## Documentation scripts

### Terraform documentation

| Script                         | Purpose                                              | Usage                                    |
|--------------------------------|------------------------------------------------------|------------------------------------------|
| `tf-docs-check.sh`             | Validates Terraform module documentation consistency | `./scripts/tf-docs-check.sh`             |
| `update-all-terraform-docs.sh` | Updates all Terraform module documentation           | `./scripts/update-all-terraform-docs.sh` |
| `install-terraform-docs.sh`    | Installs terraform-docs tool                         | `./scripts/install-terraform-docs.sh`    |

Generates README.md files from Terraform configuration and validates documentation consistency across modules.

### Bicep documentation

| Script                     | Purpose                                          | Usage                                     |
|----------------------------|--------------------------------------------------|-------------------------------------------|
| `bicep-docs-check.sh`      | Validates Bicep module documentation consistency | `./scripts/bicep-docs-check.sh`           |
| `generate-bicep-docs.py`   | Generates Bicep module documentation             | `python ./scripts/generate-bicep-docs.py` |
| `update-all-bicep-docs.sh` | Updates all Bicep module documentation           | `./scripts/update-all-bicep-docs.sh`      |

Generates README.md files from Bicep templates and validates parameter documentation.

## Compliance validation

### Variable compliance

| Script                           | Purpose                                  | Platform   |
|----------------------------------|------------------------------------------|------------|
| `Bicep-Var-Compliance-Check.ps1` | Bicep parameter compliance validation    | PowerShell |
| `tf-vars-compliance-check.py`    | Terraform variable compliance validation | Python     |

Validates naming conventions, type definitions, documentation requirements, and default value standards.

## Security scanning

### Infrastructure security

| Script            | Purpose                          | Usage                       |
|-------------------|----------------------------------|-----------------------------|
| `Run-Checkov.ps1` | Infrastructure security scanning | `./scripts/Run-Checkov.ps1` |

Comprehensive security scanning for Terraform and Bicep configurations using Checkov.

### Container and dependency security

| Script                                 | Purpose                                        | Usage                                                     |
|----------------------------------------|------------------------------------------------|-----------------------------------------------------------|
| `Invoke-ContainerSecurityScan.ps1`     | Container image vulnerability scanning (Grype) | `./scripts/security/Invoke-ContainerSecurityScan.ps1`     |
| `Invoke-SecurityGate.ps1`              | Centralized security gate enforcement          | `./scripts/security/Invoke-SecurityGate.ps1`              |
| `Invoke-SecurityReportCompression.ps1` | Security report compression and optimization   | `./scripts/security/Invoke-SecurityReportCompression.ps1` |

Integrated container image vulnerability scanning, language-specific dependency audits, and centralized security gate enforcement with report compression.

## Version checking

| Script                         | Purpose                                 | Usage                                     |
|--------------------------------|-----------------------------------------|-------------------------------------------|
| `aio-version-checker.py`       | Azure IoT Operations version validation | `python ./scripts/aio-version-checker.py` |
| `tf-provider-version-check.sh` | Terraform provider version validation   | `./scripts/tf-provider-version-check.sh`  |

Validates version consistency and compatibility across components.

## Usage examples

### Application build workflows

```powershell
# Detect application changes for matrix builds
./scripts/build/Detect-Folder-Changes.ps1 -BaseBranch "main" -ChangedFiles @("src/500-application/myapp/Program.cs")

# Build application with security scanning
./scripts/build/application-builder.ps1 -ApplicationPath "src/500-application/myapp" -Language "dotnet" -SecurityScan

# Validate workflow consistency
./scripts/build/Build-Consistency-Check.ps1
```

#### Aggregated failure reporting

The application build system automatically aggregates and reports all failures at the end of each build run, providing a comprehensive view of:

- **Build Failures**: Services that failed to build with detailed error context
- **Security Issues**: Container images with critical vulnerabilities detected by Grype
- **Dependency Audits**: Services with vulnerable dependencies from language-specific audits (.NET, Rust, Node.js, Python)

This consolidated failure summary is emitted as warnings after the JSON output, making it easy to identify and address all issues in a single view.

### Documentation maintenance

```bash
# Update all Terraform documentation
./scripts/update-all-terraform-docs.sh

# Update all Bicep documentation
./scripts/update-all-bicep-docs.sh

# Validate documentation consistency
./scripts/tf-docs-check.sh
./scripts/bicep-docs-check.sh
```

### Compliance validation implementation

```powershell
# Validate Bicep parameter compliance
./scripts/Bicep-Var-Compliance-Check.ps1
```

```bash
# Validate Terraform variable compliance
python ./scripts/tf-vars-compliance-check.py

# Check version consistency
python ./scripts/aio-version-checker.py
./scripts/tf-provider-version-check.sh
```

### Security scanning implementation

```powershell
# Run infrastructure security scanning
./scripts/Run-Checkov.ps1

# Scan container image for vulnerabilities
./scripts/security/Invoke-ContainerSecurityScan.ps1 -ImageName "myapp:latest" -OutputFormat "sarif"

# Execute security gate with custom thresholds
./scripts/security/Invoke-SecurityGate.ps1 -GrypeSeverityThreshold "medium" -CheckovSeverityThreshold "high"

# Compress security reports for artifact optimization
./scripts/security/Invoke-SecurityReportCompression.ps1 -InputPath "./security-reports" -OutputPath "./compressed-reports"
```

## Related documentation

- [GitHub Actions Workflows](./github-actions.md) - GitHub Actions integration
- [Azure DevOps Pipelines](./azure-devops.md) - Azure DevOps integration
- [Security Scanning Guide](./security-scanning.md) - Security validation processes
- [Troubleshooting Builds](./troubleshooting-builds.md) - Build troubleshooting guide

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
