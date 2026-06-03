---
title: Full Single Node Arc Cluster Blueprint
description: Deploys Azure IoT Operations on a customer-supplied Arc-enabled Linux machine with full cloud and edge components for a single-node deployment
author: Edge AI Team
ms.date: 2026-06-02
ms.topic: reference
keywords:
  - azure iot operations
  - single node cluster
  - kubernetes
  - arc-enabled
  - terraform
  - edge computing
  - arc machine
  - k3s cluster
  - dataflow graphs
  - schema registry
estimated_reading_time: 5
---

## Full Single Node Arc Cluster Blueprint

This blueprint provides a complete end-to-end deployment of Azure IoT Operations (AIO) on a customer-supplied Azure Arc-enabled Linux machine. Unlike the [full-single-node-cluster](../full-single-node-cluster/README.md) blueprint, this variant does not provision an Azure VM. Instead, it expects an Arc-onboarded Linux host to already exist, installs K3s in-place via `azurerm_arc_machine_extension`, and uses the machine's system-assigned managed identity for cluster onboarding. Set `should_deploy_aio = false` to deploy an Arc-connected cluster without AIO.

Please follow general blueprint recommendations from the blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. A customer-supplied Arc-enabled Linux machine (existing; not created by this blueprint)
2. K3s installed in-place via `azurerm_arc_machine_extension`
3. Azure Arc connection for the cluster
4. Cloud resources (Key Vault, Storage, Observability, Messaging, ACR)
5. Azure IoT Operations components (optional, controlled by `should_deploy_aio`)
6. Schema registry with versioned message schemas (when AIO is enabled)
7. Optional messaging and observability components
8. Optional dataflow graphs for WASM-based data processing pipelines
9. Optional Preview Connectors for asset discovery

The resulting architecture provides a unified edge-to-cloud solution with secure communication, data processing capabilities, and comprehensive monitoring, anchored on an Arc-connected machine that you control.

## Prerequisites

In addition to the prerequisites described in the blueprints [README.md](../README.md), this blueprint requires:

- An existing Linux host running Ubuntu 22.04 or later that has been onboarded to Azure Arc (`azcmagent connect`).
- The Arc machine must have a **system-assigned managed identity** enabled. This identity is used for Arc onboarding and replaces the user-assigned managed identity (UAMI) used by the VM-based blueprint.
- A Linux user on the Arc machine that owns the kubeconfig produced by the K3s installer (typically the user that ran `azcmagent connect`). Provide this user via `cluster_server_host_machine_username`.
- At least 8 GB of RAM (16 GB recommended) on the Arc machine.
- Registered Azure resource providers (see deployment instructions in the blueprints [README.md](../README.md)).
- Appropriate permissions to create cloud resources in the target subscription.

## Terraform Structure

This blueprint consists of the following key components:

- **Main Configuration** (`main.tf`): Orchestrates the deployment workflow and module dependencies. Includes an `azurerm_arc_machine` data source that resolves the customer-supplied Arc machine.
- **Variables** (`variables.tf`): Defines input parameters with descriptions and defaults, including three Arc-specific inputs: `arc_machine_name`, `arc_machine_resource_group_name`, and `cluster_server_host_machine_username`.
- **Outputs** (`outputs.tf`): Exposes important resource information for future reference.
- **Versions** (`versions.tf`): Specifies provider versions and requirements.

### Key Modules Used in Terraform

| Module                    | Purpose                                                               | Source Location                                          |
|---------------------------|-----------------------------------------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`    | Creates resource groups                                               | `../../../src/000-cloud/000-resource-group/terraform`    |
| `cloud_security_identity` | Handles identity and security resources (`onboard_identity_type=skip`) | `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_observability`     | Sets up monitoring infrastructure                                     | `../../../src/000-cloud/020-observability/terraform`     |
| `cloud_data`              | Creates data storage resources                                        | `../../../src/000-cloud/030-data/terraform`              |
| `cloud_messaging`         | Sets up messaging infrastructure                                      | `../../../src/000-cloud/040-messaging/terraform`         |
| `cloud_acr`               | Azure Container Registry                                              | `../../../src/000-cloud/060-acr/terraform`               |
| `edge_cncf_cluster`       | Installs K3s on the Arc machine and registers Arc cluster             | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_iot_ops`            | Installs Azure IoT Operations                                         | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_observability`      | Sets up edge monitoring                                               | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`          | Deploys edge messaging components                                     | `../../../src/100-edge/130-messaging/terraform`          |

This blueprint does **not** deploy `cloud_vm_host`; the Arc machine you supply is the cluster host.

### Arc-Specific Variable Reference

The Arc-specific inputs in this blueprint:

| Variable                               | Description                                                                                                  | Default  |
|----------------------------------------|--------------------------------------------------------------------------------------------------------------|----------|
| `arc_machine_name`                     | Name of the existing Azure Arc-enabled machine                                                               | Required |
| `arc_machine_resource_group_name`      | Resource group name containing the Arc-enabled machine; when null, defaults to the blueprint resource group  | `null`   |
| `cluster_server_host_machine_username` | Linux user on the Arc machine that owns the kubeconfig                                                       | Required |

For the full list of cloud and AIO inputs (private endpoints, AKS, Azure ML, AI Foundry, dataflow graphs, schema registry, and connectors), see [variables.tf](terraform/variables.tf). The [terraform/arc.tfvars.example](terraform/arc.tfvars.example) file covers the Arc-machine inputs and core features (AIO, ACR registry endpoint, resource sync rules, OPC UA simulator). To enable optional add-ons (dataflow graphs, AI Foundry, Preview Connectors, leak detection), copy the matching `*.tfvars.example` files from `full-single-node-cluster` blueprint `terraform/` directory.

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow). Use `terraform/arc.tfvars.example` as the starting point for the Arc-machine inputs.
