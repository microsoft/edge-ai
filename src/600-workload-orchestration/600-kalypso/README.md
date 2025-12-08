---
title: Kalypso Workload Orchestration (600-kalypso)
description: Kalypso-based multi-cluster workload orchestration with bootstrap tooling and end-to-end tutorials
author: Edge AI Platform Team
ms.date: 2025-11-20
keywords: kalypso, workload orchestration, multi-cluster, gitops, kubernetes, flux, helm
estimated_reading_time: 5 minutes
---

This component provides tooling and tutorials for deploying and managing workloads across multiple Kubernetes clusters using [Kalypso](https://github.com/microsoft/kalypso), a GitOps-based workload orchestration solution.

## Overview

Kalypso enables organizations to manage application deployments across distributed edge and cloud environments with:

- **Multi-Cluster Orchestration**: Deploy and manage workloads consistently across multiple clusters
- **GitOps-Based Workflows**: Leverage Git as the single source of truth for configuration and deployment state
- **Environment Promotion**: Automated promotion flows from dev → qa → prod with approval gates
- **Configuration Management**: Centralized configuration with environment-specific overrides

## Quick Start with Bootstrap

Kalypso provides a bootstrap script to quickly set up the complete GitOps infrastructure for your project.

### Bootstrap Script

The Kalypso bootstrap script automates the creation of:

- AKS management cluster
- Kalypso Scheduler installation
- Platform Control Plane and GitOps repositories on GitHub

**Bootstrap Script Location:**
<https://github.com/microsoft/kalypso/tree/main/scripts/bootstrap>

**Detailed Bootstrap Documentation:**
<https://github.com/microsoft/kalypso/tree/main/docs/bootstrap>

### Prerequisites

Before running the bootstrap script, ensure you have:

1. **Required Tools**:
   - `kubectl` (>= 1.20.0)
   - `az` (Azure CLI >= 2.30.0)
   - `git` (>= 2.0.0)
   - `helm` (>= 3.0.0)
   - `gh` (GitHub CLI >= 2.0.0)
   - `jq` (>= 1.6)

2. **Optional Tools**:
   - `yq` (>= 4.0) - required if using YAML configuration files

3. **Authentication**:
   - Azure account with permissions to create AKS clusters
   - GitHub personal access token with `repo`, `workflow`, and `admin:org` scopes

For detailed installation instructions, see the [prerequisites documentation](https://github.com/microsoft/kalypso/blob/main/docs/bootstrap/prerequisites.md).

### Running the Bootstrap Script

First, clone the Kalypso repository to access the bootstrap script:

```bash
# Clone the Kalypso repository
git clone https://github.com/microsoft/kalypso.git
cd kalypso
```

The bootstrap script can be run in multiple modes depending on your needs.

#### Interactive Mode (Recommended)

The easiest way to get started:

```bash
export GITHUB_TOKEN="your-github-token"
cd scripts/bootstrap
./bootstrap.sh
```

The script will guide you through all configuration options interactively.

#### Non-Interactive Mode

For automation or CI/CD pipelines:

```bash
./bootstrap.sh \
  --create-cluster \
  --cluster-name my-kalypso-cluster \
  --resource-group my-rg \
  --location eastus \
  --create-repos \
  --non-interactive
```

#### Using Configuration File

Create a configuration file in YAML, JSON, or ENV format:

```yaml
# kalypso-config.yaml
cluster:
  create: true
  name: kalypso-cluster
  resourceGroup: kalypso-rg
  location: eastus
  nodeCount: 3
  nodeSize: Standard_DS2_v2

repositories:
  create: true
  controlPlane: my-control-plane
  gitops: my-gitops

github:
  org: my-organization
```

Then run:

```bash
./bootstrap.sh --config kalypso-config.yaml
```

### What the Script Creates

#### New AKS Cluster Mode

When creating a new cluster, the script:

1. Creates Azure resource group (if it doesn't exist)
2. Creates AKS cluster with specified configuration
3. Configures kubectl credentials
4. Creates `kalypso-system` namespace
5. Validates cluster readiness

#### New Repositories Mode

When creating new repositories, the script:

1. **Creates `kalypso-control-plane` repository** with:
   - Minimal environment structure (dev environment)
   - Placeholder cluster types, scheduling policies, and config maps
   - README with repository structure

2. **Creates `kalypso-gitops` repository** with:
   - GitHub Actions workflow templates
   - README with usage instructions
   - Placeholder cluster configurations

#### Kalypso Installation

The script installs Kalypso using Helm with:

- **Namespace**: `kalypso-system`
- **Release name**: `kalypso-scheduler`
- **Configuration**: Pointing to your control-plane and gitops repositories

### Post-Installation Verification

After successful bootstrap, verify the installation:

```bash
# Check that Kalypso is running
kubectl get pods -n kalypso-system

# Verify CRDs are installed
kubectl get crd | grep kalypso
```

## Tutorials

### Basic Inference Workload Orchestration

For a complete end-to-end tutorial demonstrating Kalypso with a real application, see:

**[Basic Inference Workload Orchestration Tutorial](./basic-inference-workload-orchestration/README.md)**

This tutorial walks through:

- Setting up GitOps repositories with Kalypso
- Deploying a basic inference application
- Configuring multi-cluster deployment
- Managing configuration across clusters

## Resources

- **Kalypso GitHub Repository**: <https://github.com/microsoft/kalypso>
- **Bootstrap Scripts**: <https://github.com/microsoft/kalypso/tree/main/scripts/bootstrap>
- **Bootstrap Documentation**: <https://github.com/microsoft/kalypso/tree/main/docs/bootstrap>
- **Workload management in a multi-cluster environment with GitOps**: <https://learn.microsoft.com/azure/azure-arc/kubernetes/conceptual-workload-management>

## Next Steps

1. Review the [Basic Inference Workload Orchestration Tutorial](./basic-inference-workload-orchestration/README.md)
2. Set up your GitHub repositories using the Kalypso bootstrap script
3. Deploy your first application with multi-environment promotion
4. Explore advanced configuration patterns and multi-cluster scenarios

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
