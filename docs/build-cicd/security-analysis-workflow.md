---
title: Security Analysis with Work Item Management
description: Automated security analysis workflow that leverages Checkov security scanning and creates structured work item planning files for Azure DevOps integration to systematically track and resolve security vulnerabilities in Kubernetes clusters and Arc components
author: Edge AI Team
ms.date: 2025-09-30
ms.topic: how-to
keywords:
  - security analysis
  - checkov
  - work item management
  - azure devops
  - kubernetes security
  - arc security
estimated_reading_time: 8
---

This document describes the automated security analysis workflow that leverages Checkov security scanning and creates structured work item planning files for Azure DevOps integration to systematically track and resolve security vulnerabilities in Kubernetes clusters and Arc components.

## Overview

The security analysis workflow provides:

- **Automated Security Scanning**: Uses Checkov with existing [`.checkov.yml`](../.checkov.yml) configuration
- **Focused Component Analysis**: Targets K8s clusters and Arc components specifically
- **Severity-Based Filtering**: Prioritizes findings by security impact
- **Work Item Planning**: Creates structured planning files for Azure DevOps work item creation
- **Interactive Triage**: Optional manual review of security findings

## Quick Start

### Basic Usage

```powershell
# Run security analysis with default settings (HIGH severity threshold)
.\scripts\Invoke-SecurityAnalysisWithWorkItems.ps1

# Use different severity threshold
.\scripts\Invoke-SecurityAnalysisWithWorkItems.ps1 -SeverityThreshold MEDIUM

# Interactive mode for manual triage
.\scripts\Invoke-SecurityAnalysisWithWorkItems.ps1 -Interactive
```

### Advanced Usage

```powershell
# Specify Azure DevOps project and area path
.\scripts\Invoke-SecurityAnalysisWithWorkItems.ps1 `
    -Project "edge-ai" `
    -AreaPath "edge-ai\\Security" `
    -IterationPath "edge-ai\\Sprint-1"

# Custom output location and configuration
.\scripts\Invoke-SecurityAnalysisWithWorkItems.ps1 `
    -OutputFolder "./custom-security-reports" `
    -ConfigFile "./custom-checkov.yml"
```

## Workflow Stages

### Stage 1: Security Scanning

- Executes [`Run-Checkov.ps1`](../scripts/Run-Checkov.ps1) script with existing configuration
- Scans target K8s and Arc component directories:
  - [`src/100-edge/100-cncf-cluster/`](../src/100-edge/100-cncf-cluster/)
  - [`src/100-edge/110-iot-ops/`](../src/100-edge/110-iot-ops/)
  - [`src/000-cloud/070-kubernetes/`](../src/000-cloud/070-kubernetes/)
- Generates JSON output files for analysis

### Stage 2: Finding Analysis and Filtering

- Parses Checkov JSON output files
- Filters findings to focus on K8s and Arc-related security issues
- Classifies findings by component type:
  - **CNCF-Cluster**: Edge cluster components
  - **IoT-Operations**: IoT operations components
  - **Azure-Kubernetes**: Cloud Kubernetes components
  - **K8s-Arc-Related**: General K8s/Arc findings

### Stage 3: Severity Evaluation and Triage

- Assigns severity levels based on security impact:
  - **CRITICAL**: RBAC, privileged access, admin rights
  - **HIGH**: Security policies, secrets, credentials
  - **MEDIUM**: Resource limits, configurations
  - **LOW**: General recommendations

- Optional interactive triage for manual review
- Filters findings based on severity threshold

### Stage 4: Planning File Generation

- Creates structured planning files following repository conventions (work item planning instructions are provided by the [hve-core](https://github.com/microsoft/hve-core) VS Code extension)

- Generates proper acceptance criteria and story points
- **Note**: This stage creates planning files only - actual Azure DevOps work items are created separately using Copilot chat with the handoff file

## Severity Thresholds

| Threshold  | Includes                  | Use Case                  |
|------------|---------------------------|---------------------------|
| `CRITICAL` | Only critical findings    | Production emergencies    |
| `HIGH`     | Critical + High findings  | Standard security reviews |
| `MEDIUM`   | Medium severity and above | Comprehensive audits      |
| `LOW`      | All findings              | Development environments  |

## Output Structure

```text
logs/checkov-security-analysis/
├── checkov-src_*_*/                    # Raw Checkov results
├── security-analysis.xml               # JUnit XML report
└── security-analysis-summary.md        # Executive summary

.copilot-tracking/workitems/security-analysis/checkov-k8s-arc-findings/
├── artifact-analysis.md               # Human-readable analysis table + recommendations
├── work-items.md                      # Machine/human-readable work item definitions
├── handoff.md                         # Execution checklist for work item creation
└── planning-log.md                    # Operational state tracking and progress log
```

## Integration with Azure DevOps

The generated planning files follow repository work item planning conventions and can be processed using Copilot chat:

1. **Review Planning Files**: Examine generated work item definitions and acceptance criteria in [`.copilot-tracking`](../.copilot-tracking/) folder
2. **Execute Work Item Creation**: Use Copilot chat with the [`handoff.md`](../.copilot-tracking/workitems/security-analysis/checkov-k8s-arc-findings/handoff.md) file to create actual work items in Azure DevOps
3. **Track Progress**: Monitor resolution through Azure DevOps after work items are created
4. **Follow-up Scanning**: Verify fixes with subsequent security scans

## Troubleshooting

### Common Issues

#### Checkov Installation Issues

**Symptom**: Script fails with "Checkov not found" or pip installation errors.

**Resolution**:

1. Verify Python 3.8+ is installed: `python --version`
2. Install Checkov manually: `pip install checkov`
3. Verify installation: `checkov --version`
4. If using a virtual environment, ensure it is activated

#### Scan Configuration Failures

**Symptom**: Checkov runs but produces no results or skips all checks.

**Resolution**:

1. Verify `.checkov.yml` exists and is properly formatted
2. Check that target directories exist and contain scannable files
3. Run Checkov directly to see verbose output: `checkov -d <directory> --config-file .checkov.yml`
4. Ensure the framework filters match your infrastructure code (terraform, kubernetes, etc.)

#### Azure Authentication Errors

**Symptom**: Work item creation fails with authentication or authorization errors.

**Resolution**:

1. Verify Azure DevOps PAT token has required permissions (Work Items: Read & Write)
2. Check that the project name and organization are correct
3. Ensure the area path and iteration path exist in the target project
4. Test connectivity: `az devops project list --organization <org-url>`

#### Work Item Creation Failures

**Symptom**: Planning files generated but work items fail to create.

**Resolution**:

1. Review the generated planning files for formatting issues
2. Verify all required fields are populated in `work-items.md`
3. Check that the handoff file references valid work item definitions
4. Ensure Copilot chat has access to the Azure DevOps MCP tools

### Debugging Commands

```bash
# Verify Checkov installation and version
checkov --version

# Run Checkov with verbose output for debugging
checkov -d src/100-edge/100-cncf-cluster/ --config-file .checkov.yml -o cli --compact

# Test Azure DevOps connectivity
az devops project list --organization https://dev.azure.com/<org>

# Validate planning file structure
cat .copilot-tracking/workitems/security-analysis/checkov-k8s-arc-findings/work-items.md
```

## Related Documentation

- [Invoke-SecurityAnalysisWithWorkItems.ps1 Script](../scripts/Invoke-SecurityAnalysisWithWorkItems.ps1)
- [Run-Checkov.ps1 Documentation](../scripts/README.md)
- [Checkov Configuration Reference](../.checkov.yml)

---

*This documentation was generated with the assistance of GitHub Copilot to ensure comprehensive coverage and accuracy. The content has been reviewed and validated by the Edge AI Team to meet our documentation standards and provide practical guidance for security analysis workflows.*
