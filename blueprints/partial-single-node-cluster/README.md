---
title: Partial Single Node Cluster Blueprint
description: Deployment of a single-node, Arc-enabled Kubernetes cluster without Azure IoT Operations providing a foundational edge computing environment for later extension
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - kubernetes
  - arc-enabled cluster
  - single node
  - foundational deployment
  - terraform
  - edge computing
  - vm deployment
  - k3s cluster
  - partial deployment
estimated_reading_time: 2
---

## Partial Single Node Cluster Blueprint

This blueprint provides a deployment of a single-node, Arc-enabled Kubernetes cluster without Azure IoT Operations (AIO). It deploys only the necessary components from VM creation to Arc-enabled cluster setup, resulting in a foundational edge computing environment that can later be extended with additional services.

Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. A Linux VM host in Azure
2. A K3s Kubernetes cluster on the VM
3. Azure Arc connection for the cluster
4. Cloud resources required for the cluster (Key Vault, Resource Group, etc.)

Unlike the full-single-node-cluster blueprint, this blueprint does NOT install:

- Edge messaging components
- Edge observability components

This blueprint is ideal for scenarios where you:

- Need only the Kubernetes infrastructure without IoT components
- Plan to install custom workloads on the cluster
- Want to manually install Azure IoT Operations later

## Terraform Structure

This blueprint consists of the following key components:

- **Main Configuration** (`main.tf`): Orchestrates the deployment workflow and module dependencies
- **Variables** (`variables.tf`): Defines input parameters with descriptions and defaults
- **Outputs** (`outputs.tf`): Exposes important resource information for future reference
- **Versions** (`versions.tf`): Specifies provider versions and requirements

### Key Modules Used

| Module                    | Purpose                                 | Source Location                                          |
|---------------------------|-----------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`    | Creates resource groups                 | `../../../src/000-cloud/001-resource-group/terraform`    |
| `cloud_security_identity` | Handles identity and security resources | `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_vm_host`           | Creates the VM host for the cluster     | `../../../src/000-cloud/020-vm-host/terraform`           |
| `edge_cncf_cluster`       | Deploys K3s Kubernetes cluster          | `../../../src/100-edge/100-cncf-cluster/terraform`       |

### Variable Reference

This blueprint has the following variables:

| Variable                          | Description                        | Default             | Notes                                                      |
|-----------------------------------|------------------------------------|---------------------|------------------------------------------------------------|
| `environment`                     | Environment type                   | Required            | "dev", "test", "prod", etc.                                |
| `resource_prefix`                 | Prefix for resource naming         | Required            | Short unique alphanumeric string (max 8 chars recommended) |
| `location`                        | Azure region location              | Required            | "eastus2", "westus3", etc.                                 |
| `instance`                        | Deployment instance number         | `"001"`             | For multiple deployments                                   |
| `virtual_machine_size`            | VM size for the cluster host       | `"Standard_D4s_v3"` | Adjust based on your workload requirements                 |
| `admin_username`                  | Username for the VM admin account  | `null`              | Defaults to resource_prefix if not provided                |
| `admin_ssh_key`                   | Public SSH key for the admin user  | `null`              | A key will be generated if not provided                    |
| `should_get_custom_locations_oid` | Auto-retrieve Custom Locations OID | `true`              | Set to false when providing custom_locations_oid           |
| `custom_locations_oid`            | Custom Locations SP Object ID      | `null`              | Required for Arc custom locations                          |

## Prerequisites

Ensure you have the following prerequisites:

- Sufficient quota for a VM in your target region
- At least 8 GB of RAM per VM, recommended 16 GB of RAM per VM
- Registered resource providers (see deployment instructions)
- Appropriate permissions to create resources

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
