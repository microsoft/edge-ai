---
title: Security Scanning & Supply Chain Hardening
description: Comprehensive security scanning, supply chain hardening, and vulnerability assessment for the Edge AI Accelerator CI/CD pipelines.
author: Edge AI Team
ms.date: 06/06/2025
ms.topic: concept
keywords:
  - security scanning
  - supply chain security
  - sha pinning
  - checkov
  - megalinter
  - terraform security
  - bicep security
  - vulnerability assessment
  - slsa
  - stepSecurity
  - ossf scorecard
estimated_reading_time: 8
---

The Edge AI Accelerator implements comprehensive security scanning and supply chain hardening to ensure infrastructure security, identify vulnerabilities, maintain compliance, and protect against supply chain attacks.

## Overview

### Security Layers

- **Supply Chain Security**: Immutable dependency pinning, runtime monitoring, SLSA compliance
- **Infrastructure as Code**: Terraform and Bicep security validation
- **Dependencies**: Package and library vulnerability assessment with automated updates
- **Containers**: Docker and Kubernetes configuration scanning with SHA pinning
- **Configuration**: CI/CD and secret management validation
- **Runtime Security**: Egress filtering, network monitoring, and runtime attestation

### Integration Points

- **Pull Requests**: Security checks block non-compliant changes
- **GitHub Actions**: Automated scanning, hardening, and monitoring
- **Azure DevOps**: Enterprise security validation with full template parity
- **Local Development**: Pre-commit security validation and SHA pinning
- **Runtime**: StepSecurity Harden-Runner and egress filtering

## Supply Chain Security

### SHA Pinning & Dependency Management

The Edge AI Accelerator implements comprehensive SHA pinning for immutable dependencies across all CI/CD workflows.

#### GitHub Actions SHA Pinning

**Script**: `./scripts/security/Update-ActionSHAPinning.ps1`

```powershell
# Pin all GitHub Actions to SHA hashes
./scripts/security/Update-ActionSHAPinning.ps1 -Path ".github/workflows" -WhatIf

# Apply SHA pinning with build warnings
./scripts/security/Update-ActionSHAPinning.ps1 -Path ".github/workflows" -OutputFormat "BuildWarning"

# Generate JSON output for CI/CD
./scripts/security/Update-ActionSHAPinning.ps1 -Path ".github/workflows" -OutputFormat "JSON"
```

#### Docker Image SHA Pinning

**Script**: `./scripts/security/Update-DockerSHAPinning.ps1`

```powershell
# Pin Docker images in Dockerfiles and Compose files
./scripts/security/Update-DockerSHAPinning.ps1 -Path "src/" -WhatIf

# Apply with structured security issue output
./scripts/security/Update-DockerSHAPinning.ps1 -Path "src/" -OutputFormat "BuildWarning"
```

#### Shell Script Dependency Tracking

**Script**: `./scripts/security/Update-ShellScriptSHAPinning.ps1`

```powershell
# Analyze shell script dependencies for pinning opportunities
./scripts/security/Update-ShellScriptSHAPinning.ps1 -Path "src/" -OutputFormat "BuildWarning"
```

### SHA Staleness Monitoring

**Script**: `./scripts/security/Test-SHAStaleness.ps1`

Monitors pinned dependencies for security updates and generates build warnings for outdated SHAs.

```powershell
# Check for stale SHA pins with build warnings
./scripts/security/Test-SHAStaleness.ps1 -Path ".github/workflows" -OutputFormat "BuildWarning"

# Generate JSON report for CI/CD integration
./scripts/security/Test-SHAStaleness.ps1 -Path ".github/workflows" -OutputFormat "JSON"
```

### Automated Dependency Management

#### Dependabot Configuration

**File**: `.github/dependabot.yml`

Automated dependency updates for:

- GitHub Actions (weekly updates)
- Docker images (weekly updates)
- npm packages (weekly updates)
- Python packages (weekly updates)

#### Azure DevOps Dependency Scanning

Enterprise-grade dependency scanning integrated with Azure DevOps Security Center for comprehensive vulnerability assessment and automated remediation.

### Runtime Security Hardening

#### StepSecurity Harden-Runner

**GitHub Actions Integration**:

```yaml
- name: Harden Runner
  uses: step-security/harden-runner@17d0e2bd7d51742c71671bd19fa12bdc9d40a3d6 # v2.8.1
  with:
    egress-policy: audit
    disable-sudo: true
    disable-file-monitoring: false
```

**Azure DevOps Template**: `.azdo/templates/harden-runner-template.yml`

#### OSSF Scorecard Integration

Automated supply chain security analysis using OpenSSF Scorecard for comprehensive security posture assessment.

**GitHub Actions**:

```yaml
- name: OSSF Scorecard
  uses: ossf/scorecard-action@0864cf19026789058feabb7e87baa5f140aac736 # v2.3.1
  with:
    results_file: results.sarif
    results_format: sarif
```

## Traditional Security Scanning

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

## CI/CD Security Integration

### GitHub Actions Workflows

All workflows include comprehensive security monitoring:

#### Main Workflow Security Steps

```yaml
jobs:
  security-monitoring:
    runs-on: ubuntu-latest
    steps:
      - name: Harden Runner
        uses: step-security/harden-runner@17d0e2bd7d51742c71671bd19fa12bdc9d40a3d6 # v2.8.1
        with:
          egress-policy: audit

      - name: Security Monitoring
        uses: step-security/secure-repo@f0aa4c52c23e5cdcc8d5088bd60badb2a08c24c4 # v1.0.0

      - name: SHA Staleness Check
        run: |
          ./scripts/security/Test-SHAStaleness.ps1 -Path ".github/workflows" -OutputFormat "BuildWarning"
```

#### Pull Request Security Validation

```yaml
- name: Infrastructure Security Scan
  run: |
    ./scripts/Run-Checkov.ps1 -Path "src/" -Output "sarif"

- name: Upload Security Results
  uses: github/codeql-action/upload-sarif@v3
  with:
    sarif_file: checkov-results.sarif
```

### Azure DevOps Pipeline Integration

**Main Pipeline**: `azure-pipelines.yml`

All security templates integrated for full parity:

```yaml
- template: .azdo/templates/harden-runner-template.yml
- template: .azdo/templates/security-monitoring-template.yml
- template: .azdo/templates/security-scorecard-template.yml
- template: .azdo/templates/egress-monitoring-template.yml
- template: .azdo/templates/security-staleness-check.yml
```

#### Security Template Examples

**Staleness Monitoring**: `.azdo/templates/security-staleness-check.yml`

```yaml
- task: PowerShell@2
  displayName: 'SHA Staleness Check'
  inputs:
    filePath: './scripts/security/Test-SHAStaleness.ps1'
    arguments: '-Path "$(Build.SourcesDirectory)/.github/workflows" -OutputFormat "BuildWarning"'
```

## Troubleshooting

### Common Issues

#### SHA Pinning Problems

**Symptoms**: Missing SHA mappings, dependencies that cannot be pinned, API rate limits

**Solutions**:

- Check GitHub API rate limits and authentication
- Use manual SHA mapping for actions without releases
- Review build warnings for dependencies that cannot be pinned
- Configure appropriate timeout values for API calls

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
# Test SHA pinning in WhatIf mode
./scripts/security/Update-ActionSHAPinning.ps1 -Path ".github/workflows" -WhatIf

# Check SHA staleness with detailed output
./scripts/security/Test-SHAStaleness.ps1 -Path ".github/workflows" -OutputFormat "JSON"

# Verbose Checkov output
./scripts/Run-Checkov.ps1 -Path "src/" -Verbose

# List available policies
checkov --list

# Test specific policy
checkov --check CKV_AZURE_1 -f terraform-file.tf
```

## Best Practices

### Supply Chain Best Practices

- **Immutable Pinning**: Always pin dependencies to SHA hashes, not tags
- **Regular Updates**: Monitor and update pinned dependencies regularly
- **Automated Monitoring**: Use staleness monitoring for proactive security management
- **Graceful Degradation**: Handle dependencies that cannot be pinned with structured tracking
- **Build Integration**: Integrate security checks into CI/CD with appropriate warnings

### Scanning Best Practices

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
