---
title: Security Scanning Guide
description: Security scanning, vulnerability assessment, and compliance validation for the Edge AI Accelerator CI/CD pipelines.
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
keywords:
  - security scanning
  - checkov
  - megalinter
  - terraform security
  - bicep security
  - vulnerability assessment
estimated_reading_time: 4
---

## Security Scanning Guide

Security scanning is integrated throughout the Edge AI Accelerator CI/CD pipeline to ensure infrastructure security, identify vulnerabilities, and maintain compliance.

## Overview

### Scanning Scope

- **Infrastructure as Code**: Terraform and Bicep security validation
- **Dependencies**: Package and library vulnerability assessment
- **Containers**: Docker and Kubernetes configuration scanning
- **Configuration**: CI/CD and secret management validation

### Integration Points

- **Pull Requests**: Security checks block non-compliant changes
- **GitHub Actions**: Automated scanning in all workflows
- **Azure DevOps**: Enterprise security validation
- **Local Development**: Pre-commit security validation

## Security Tools

### Checkov - Infrastructure Security

**Primary Tool**: [Checkov][checkov-tool] for Infrastructure as Code scanning
**Script**: `./scripts/Run-Checkov.ps1`

#### Key Capabilities

- **Multi-Platform**: Terraform, Bicep, Docker, Kubernetes, ARM
- **Policy Libraries**: CIS benchmarks, NIST, SOC2, custom policies
- **Remediation**: Actionable fix recommendations

#### Usage Examples

```powershell
# Scan Terraform files
./scripts/Run-Checkov.ps1 -Path "src/" -Framework "terraform"

# Scan Bicep templates
./scripts/Run-Checkov.ps1 -Path "src/" -Framework "bicep"

# Scan specific file
checkov -f src/000-cloud/010-security-identity/terraform/main.tf
```

### MegaLinter - Code Quality & Security

**Tool**: [MegaLinter][megalinter-tool] for comprehensive validation
**Workflow**: `.github/workflows/megalinter.yml`

#### Security Features

- **Secret Detection**: Prevents accidental secret exposure
- **Dependency Scanning**: Package vulnerability assessment
- **SAST**: Static application security testing
- **Configuration Security**: YAML, JSON validation

## Security Workflows

### GitHub Actions Integration

#### Pull Request Validation

```yaml
- name: Infrastructure Security Scan
  run: |
    ./scripts/Run-Checkov.ps1 -Path "src/" -Output "sarif"

- name: Upload Security Results
  uses: github/codeql-action/upload-sarif@v2
  with:
    sarif_file: checkov-results.sarif
```

#### Dependency Scanning

```yaml
# npm packages
- name: NPM Security Audit
  run: npm audit --audit-level=moderate

# Python packages
- name: Python Security Scan
  run: pip-audit --requirement requirements.txt

# Container images
- name: Docker Image Security Scan
  uses: docker/scout-action@v1
  with:
    command: 'cves'
    image: '${{ env.REGISTRY }}/${{ env.IMAGE_NAME }}:${{ env.TAG }}'
```

### Azure DevOps Integration

```yaml
- task: PowerShell@2
  displayName: 'Infrastructure Security Scan'
  inputs:
    filePath: './scripts/Run-Checkov.ps1'
    arguments: '-Path $(Build.SourcesDirectory) -Output json'
```

## Troubleshooting

### Common Issues

#### Tool Configuration Problems

**Symptoms**: Configuration errors, policy failures

**Solutions**:

- Validate configuration files
- Update security policies
- Check tool version compatibility
- Verify environment dependencies

#### False Positives

**Symptoms**: Valid configurations flagged as issues

**Solutions**:

- Customize policies for organization requirements
- Configure exceptions for valid use cases
- Update policies based on analysis

#### Performance Issues

**Symptoms**: Slow scanning, timeouts

**Solutions**:

- Optimize scanning scope
- Implement parallel execution
- Use result caching
- Allocate more resources

### Debugging Commands

```powershell
# Verbose Checkov output
./scripts/Run-Checkov.ps1 -Path "src/" -Verbose

# List available policies
checkov --list

# Test specific policy
checkov --check CKV_AZURE_1 -f terraform-file.tf
```

## Best Practices

- **Early Integration**: Scan early in development workflow
- **Incremental Scanning**: Only scan changed files for efficiency
- **Fast Feedback**: Provide quick security feedback to developers
- **Baseline Tracking**: Establish security baseline and track changes
- **Actionable Results**: Include clear remediation guidance

## Related Documentation

- [GitHub Actions Workflows](github-actions/) - GitHub Actions security integration
- [Azure DevOps Pipelines](azure-pipelines/) - Azure DevOps security integration

<!-- Reference Links -->
[checkov-tool]: https://www.checkov.io/
[megalinter-tool]: https://megalinter.io/

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
