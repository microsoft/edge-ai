---
title: Azure Local IoT Operations Blueprint
description: End-to-end Terraform blueprint that provisions required Azure cloud services and an Azure Local (Azure Stack HCI) Kubernetes cluster, then deploys Azure IoT Operations (AIO) with optional assets, messaging, observability, and OPC UA simulation.
author: Edge AI Team
ms.date: 2025-11-11
ms.topic: reference
keywords:
   - azure iot operations
   - azure local
   - azure arc
   - terraform
   - edge computing
estimated_reading_time: 3
---

## Azure Local IoT Operations Blueprint

This blueprint provisions the cloud services and deploys a Kubernetes cluster on Azure Local (formerly Azure Stack HCI) infrastructure, then installs Azure IoT Operations (AIO) on that cluster. It creates a new Kubernetes cluster using Azure Local's native cluster provisioning capabilities rather than using VMs or existing CNCF clusters. Review the [blueprints README](../README.md) for general deployment guidance before proceeding.

## Architecture Overview

The Terraform blueprint orchestrates the following components:

1. **Resource group** – Allocates a dedicated resource group for cloud services (and optionally uses a separate resource group for Arc-connected cluster resources).
2. **Security and data services** – Deploys Azure Key Vault, managed identities, storage account with Data Lake Gen2, Schema Registry, and assigns RBAC roles.
3. **Observability services** – Creates Log Analytics workspace, Azure Monitor workspace, Managed Grafana, and data collection rules for monitoring.
4. **Cloud messaging** – Provisions Event Grid and Event Hubs for cloud-to-edge messaging integration.
5. **Azure Local Kubernetes cluster** – Deploys a new Kubernetes cluster on Azure Local infrastructure using the provided custom location and logical network.
6. **Azure IoT Operations** – Installs the AIO instance, MQTT broker, dataflows, resource sync rules, and optional OPC UA simulator.
7. **Edge assets** – Optionally creates asset endpoint profiles and assets for OPC UA integration.
8. **Edge observability** – Connects the cluster to Azure Monitor and Grafana for edge telemetry.
9. **Edge messaging** – Configures dataflow endpoints for Event Grid and Event Hubs integration.

The result is a complete Azure IoT Operations deployment on Azure Local infrastructure with all required cloud dependencies.

## Terraform Blueprint Structure

The Terraform implementation aligns with project conventions:

* `main.tf` – Orchestrates module composition and dependency wiring.
* `variables.tf` – Defines input parameters (core settings, Azure Local toggles, and AIO options).
* `outputs.tf` – Surfaces key resource information for downstream automation.
* `versions.tf` – Locks Terraform CLI and provider versions consistent with other blueprints.

### Key Terraform Modules

| Module                       | Purpose                                                         | Source                                                   |
|------------------------------|-----------------------------------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`       | Creates or looks up the Azure resource group                    | `../../../src/000-cloud/000-resource-group/terraform`    |
| `arc_cluster_resource_group` | (Optional) Uses existing resource group for Arc cluster         | `../../../src/000-cloud/000-resource-group/terraform`    |
| `cloud_security_identity`    | Provisions managed identities, Key Vault, and RBAC assignments  | `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_observability`        | Creates Log Analytics, Azure Monitor, and Managed Grafana       | `../../../src/000-cloud/020-observability/terraform`     |
| `cloud_data`                 | Deploys storage account with Data Lake Gen2 and Schema Registry | `../../../src/000-cloud/030-data/terraform`              |
| `cloud_messaging`            | Creates Event Hubs and Event Grid for cloud messaging           | `../../../src/000-cloud/040-messaging/terraform`         |
| `azure_local_host`           | Deploys Kubernetes cluster on Azure Local infrastructure        | `../../../src/000-cloud/053-azure-local-host/terraform`  |
| `edge_iot_ops`               | Deploys Azure IoT Operations instance and MQTT broker           | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_assets`                | (Optional) Creates asset endpoint profiles and assets           | `../../../src/100-edge/111-assets/terraform`             |
| `edge_observability`         | Connects cluster to Azure Monitor and Grafana                   | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`             | Configures dataflow endpoints for Event Grid and Event Hubs     | `../../../src/100-edge/130-messaging/terraform`          |

## Input Highlights

The blueprint exposes a focused set of inputs for Azure Local deployments:

| Variable                                        | Description                                                                                                       | Default           | Required |
|-------------------------------------------------|-------------------------------------------------------------------------------------------------------------------|-------------------|----------|
| `environment`                                   | Environment identifier (dev, test, prod)                                                                          | -                 | Yes      |
| `resource_prefix`                               | Prefix for resource names (must start with a letter; alphanum & dashes)                                           | -                 | Yes      |
| `location`                                      | Azure region for cloud resources                                                                                  | -                 | Yes      |
| `custom_location_id`                            | Resource ID of the custom location for Azure Local cluster                                                        | -                 | Yes      |
| `logical_network_id`                            | Resource ID of the logical network for the Kubernetes cluster                                                     | -                 | Yes      |
| `instance`                                      | Deployment instance suffix                                                                                        | `"001"`           | No       |
| `resource_group_name`                           | Name of resource group to create or use                                                                           | `null`            | No       |
| `use_existing_resource_group_for_cloud`         | Use an existing resource group for cloud resources with provided/computed name                                    | `false`           | No       |
| `arc_cluster_resource_group_name`               | Name of the resource group for Arc-connected cluster resources; if not provided, the cloud resource group is used | `null`            | No       |
| `use_existing_resource_group_for_arc_cluster`   | Use an existing resource group for Arc cluster with provided/computed name                                        | `true`            | No       |
| `azure_local_control_plane_count`               | Number of control plane nodes                                                                                     | `1`               | No       |
| `azure_local_node_pool_count`                   | Number of worker nodes                                                                                            | `1`               | No       |
| `azure_local_control_plane_vm_size`             | VM size for control plane nodes                                                                                   | `Standard_A4_v2`  | No       |
| `azure_local_node_pool_vm_size`                 | VM size for worker nodes                                                                                          | `Standard_D8s_v3` | No       |
| `azure_local_pod_cidr`                          | CIDR range for Kubernetes pods                                                                                    | `10.244.0.0/16`   | No       |
| `azure_local_aad_profile`                       | Azure AD profile (RBAC, admin groups, tenant)                                                                     | See vars (object) | No       |
| `should_enable_key_vault_public_network_access` | Enable public network access for Key Vault                                                                        | `true`            | No       |
| `should_enable_storage_public_network_access`   | Enable public network access for storage account                                                                  | `true`            | No       |
| `storage_account_is_hns_enabled`                | Enable hierarchical namespace (Data Lake Gen2)                                                                    | `true`            | No       |
| `should_create_data_lake`                       | Create a Data Lake Gen2 storage account                                                                           | `true`            | No       |
| `should_create_azure_functions`                 | Create Azure Functions resources for messaging                                                                    | `false`           | No       |
| `aio_features`                                  | Map of AIO feature flags (mode + settings)                                                                        | `null`            | No       |
| `should_create_anonymous_broker_listener`       | Enable insecure anonymous MQTT listener (dev/test only)                                                           | `false`           | No       |
| `should_deploy_resource_sync_rules`             | Deploy resource sync rules                                                                                        | `true`            | No       |
| `should_enable_opc_ua_simulator`                | Deploy OPC UA simulator                                                                                           | `false`           | No       |
| `asset_endpoint_profiles`                       | Asset endpoint profiles to create                                                                                 | `[]`              | No       |
| `assets`                                        | Assets to create                                                                                                  | `[]`              | No       |

For the full parameter list, review `terraform/variables.tf`.

## Prerequisites

Before deploying:

1. **Azure Local Setup**: Deploy and configure Azure Local (Azure Stack HCI) infrastructure with:
   * Azure Arc integration enabled
   * A custom location created for the Azure Local cluster
   * A logical network configured for Kubernetes cluster deployment
2. **Resource Providers**: Register required Azure resource providers by running `scripts/az-sub-init.sh` or following the [blueprints registration guidance](../README.md#register-resource-providers).
3. **Tooling**: Install Terraform 1.9.8 or later (but < 2.0) and Azure CLI.
4. **Authentication**: Authenticate with `az login` using an account with:
   * Permission to create resources in the target subscription
   * Permission to deploy Kubernetes clusters on Azure Local
   * Appropriate RBAC roles for IoT Operations deployment
5. **Azure Local IDs**: Gather the following resource IDs from your Azure Local deployment:
   * Custom location ID
   * Logical network ID
   * (Optional) Separate resource group name if Arc cluster resources should be isolated

## Deploy with Terraform

Run validation and plan from the repository root:

```bash
# Source Azure subscription initialization
source scripts/az-sub-init.sh

# Validate Terraform configuration
npm run tf-validate -- blueprints/azure-local/terraform

# Initialize Terraform
terraform -chdir=blueprints/azure-local/terraform init

# Plan deployment
terraform -chdir=blueprints/azure-local/terraform plan \
    -var "environment=dev" \
    -var "resource_prefix=contoso" \
    -var "location=eastus2" \
    -var "custom_location_id=/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.ExtendedLocation/customLocations/<name>" \
    -var "logical_network_id=/subscriptions/<sub-id>/resourceGroups/<rg>/providers/Microsoft.AzureStackHCI/logicalNetworks/<name>" \
    -out tfplan

terraform -chdir=blueprints/azure-local/terraform apply tfplan
```

> Replace the sample variable values with your environment-specific settings.

## Post-Deployment Tasks

* Use the `azure_iot_operations` output to discover the MQTT broker hostname and ports.
* Connect to the Arc-enabled cluster with the `cluster_connection.arc_proxy_command` output.
* Review Managed Grafana dashboards and Log Analytics to confirm telemetry ingestion.
* Configure additional asset profiles or dataflows via the IoT Operations portal as needed.

---

<!-- markdownlint-disable MD036 -->
*🤖 Authored with GitHub Copilot and validated by Terraform tooling.*
<!-- markdownlint-enable MD036 -->
