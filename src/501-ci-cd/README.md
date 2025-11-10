---
title: CI/CD Component
description: GitOps CI/CD workflows and setup utilities for Edge AI applications
author: Edge AI Team
ms.date: 2025-01-08
ms.topic: tutorial
estimated_reading_time: 5
keywords:
  - cicd
  - GitOps
  - GitHub Actions
  - continuous deployment
  - Kalypso
---

## Overview

The CI/CD component enables [Multi-Environment Promotional Flow with GitOps](../../../docs/solution-adr-library/cicd-gitops.md) for the workloads on Kubernetes clusters.

## Component Structure

```text
src/501-ci-cd/
├── README.md                        # This documentation
├── setup.md                         # Detailed GitOps setup guide
├── init.sh                          # Script to import Kalypso templates
└── basic-inference-cicd/            # End-to-end implementation and tutorial
    ├── README.md                    # Tutorial for Basic Inference CI/CD pipeline
    ├── basic-inference-cicd.sh      # Automated setup for Basic Inference application
    └── media/                       # Documentation images
```

### Step 1: Import Kalypso Templates

#### Prerequisites

- GitHub CLI (`gh`) installed and authenticated
- Git configured with user name and email

Run the initialization script to download and import workflow templates:

```bash
cd src/501-ci-cd
./init.sh
```

This will:

1. Clone the Microsoft/Kalypso repository
2. Copy the latest Kalypso templates and scripts to `.github/workflows/templates/`
3. Copy the setup script to this directory
4. Create a pull request with the imported files

> **Important!**
>
> - If you are using a GitHub repository, the script will automatically create a pull request with the imported files.
> - For Azure DevOps environments, the script will create a new branch containing the imported files. You will need to manually create a pull request from this branch.

Once the latest Kalypso templates and scripts are merged into this accelerator repository, you own and maintain them going forward. These templates serve as the foundation for setting up CI/CD GitOps promotional flows for applications across your organization.

### Step 2: Setup CI/CD GitOps promotional flow for an applications

For detailed instructions on setting up GitOps repositories and configuring the promotional flow, see the comprehensive [Setup Guide](setup.md).

#### Quick Setup

After importing the templates, use the setup script to create your GitOps repositories:

```bash
## Run the setup script (imported from Kalypso)
./setup.sh -o <github org> -r <github application src repo> -e <first environment in chain>
```

Example:

```sh
./setup.sh -o microsoft -r hello-world -e dev
```

This creates or updates the three-repository GitOps pattern:

- Source repository with application code
- Config repository with environment-specific configurations
- GitOps repository with deployment manifests

### Step 3: Quick Start with Basic Inference setup

For a complete working implementation, see the [CI/CD setup for the Basic Inference application](basic-inference-cicd/README.md).

This implementation provides:

- End-to-end GitOps setup for the Basic Inference Application
- Automated repository creation and configuration
- Step-by-step tutorial with detailed explanations
- Ready-to-run automation script for quick deployment

## Related Components

- **[Resource Group](../000-cloud/000-resource-group/README.md)**: Azure resource organization
- **[CNCF Cluster](../100-edge/100-cncf-cluster/README.md)**: Azure Arc-enabled Kubernetes deployment targets
- **[Basic Inference Application](../500-application/500-basic-inference/README.md)**: Sample Edge AI workload

---

<!-- markdown-lint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdown-lint-enable MD036 -->
