---
title: Full Single Cluster Blueprint
description: Complete end-to-end deployment of Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster with all components from VM creation to AIO installation
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - azure iot operations
  - single node cluster
  - kubernetes
  - arc-enabled
  - terraform
  - bicep
  - edge computing
  - vm deployment
  - k3s cluster
estimated_reading_time: 3
---

## Full Single Cluster Blueprint

This blueprint provides a complete end-to-end deployment of Azure IoT Operations (AIO) on a single-node, Arc-enabled Kubernetes cluster. It deploys all necessary components from VM creation to AIO installation, resulting in a fully functional edge computing environment that integrates with Azure cloud services.
Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. A Linux VM host in Azure
2. A K3s Kubernetes cluster on the VM
3. Azure Arc connection for the cluster
4. Cloud resources required by AIO (Key Vault, Storage, etc.)
5. Azure IoT Operations components (MQTT Broker, Data Processor, etc.)
6. Optional messaging and observability components
7. Optional Preview Connectors for asset discovery (in Terraform only)

The resulting architecture provides a unified edge-to-cloud solution with secure communication, data processing capabilities, and comprehensive monitoring.

## Implementation Options

This blueprint is available in two implementation options:

- **Terraform** - Infrastructure as Code using HashiCorp Terraform
- **Bicep** - Infrastructure as Code using Azure Bicep

Choose the implementation that best fits your team's expertise and existing pipelines.

## Terraform Structure

This blueprint consists of the following key components:

- **Main Configuration** (`main.tf`): Orchestrates the deployment workflow and module dependencies
- **Variables** (`variables.tf`): Defines input parameters with descriptions and defaults
- **Outputs** (`outputs.tf`): Exposes important resource information for future reference
- **Versions** (`versions.tf`): Specifies provider versions and requirements

### Key Modules Used in Terraform

| Module                    | Purpose                                 | Source Location                                          |
|---------------------------|-----------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`    | Creates resource groups                 | `../../../src/000-cloud/000-resource-group/terraform`    |
| `cloud_security_identity` | Handles identity and security resources | `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_observability`     | Sets up monitoring infrastructure       | `../../../src/000-cloud/020-observability/terraform`     |
| `cloud_data`              | Creates data storage resources          | `../../../src/000-cloud/030-data/terraform`              |
| `cloud_messaging`         | Sets up messaging infrastructure        | `../../../src/000-cloud/040-messaging/terraform`         |
| `cloud_vm_host`           | Creates the VM host for the cluster     | `../../../src/000-cloud/051-vm-host/terraform`           |
| `cloud_aks_acr`           | Deploys AKS and/or ACR                  | `../../../src/000-cloud/060-aks-acr/terraform`           |
| `edge_cncf_cluster`       | Deploys K3s Kubernetes cluster          | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_iot_ops`            | Installs Azure IoT Operations           | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_observability`      | Sets up edge monitoring                 | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`          | Deploys edge messaging components       | `../../../src/100-edge/130-messaging/terraform`          |

### Variable Reference in Terraform

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable                                  | Description                        | Default  | Notes                                                       |
|-------------------------------------------|------------------------------------|----------|-------------------------------------------------------------|
| `environment`                             | Environment type                   | Required | "dev", "test", "prod", etc.                                 |
| `resource_prefix`                         | Prefix for resource naming         | Required | Short unique alphanumeric string (max 8 chars recommended)  |
| `resource_group_name`                     | Name of resource group             | `null`   | When null, name is generated from prefix, env, and instance |
| `location`                                | Azure region location              | Required | "eastus2", "westus3", etc.                                  |
| `instance`                                | Deployment instance number         | `"001"`  | For multiple deployments                                    |
| `should_get_custom_locations_oid`         | Auto-retrieve Custom Locations OID | `true`   | Set to false when providing custom_locations_oid            |
| `custom_locations_oid`                    | Custom Locations SP Object ID      | `null`   | Required for Arc custom locations                           |
| `should_create_anonymous_broker_listener` | Enable anonymous MQTT listener     | `false`  | For dev/test only, not secure for production                |
| `should_create_aks`                       | Create Azure Kubernetes Service    | `false`  | When true, deploys AKS in addition to the K3s cluster       |
| `should_create_acr_private_endpoint`      | Enable ACR private endpoint        | `false`  | Creates a private endpoint for the Azure Container Registry |
| `aio_features`                            | AIO feature configurations         | `null`   | Map of feature settings for Azure IoT Operations            |

For additional configuration options, review the variables in `variables.tf`.

> Note: The `aio_features` variable is a map that allows you to specify feature flags for Azure IoT Operations. This can be used to enable or disable specific features based on your deployment needs. For example, you can use the following format of variables to enable the preview feature [OPC UA asset discovery](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/howto-autodetect-opc-ua-assets-use-akri):

```hcl
should_deploy_resource_sync_rules     = true

aio_features = {
  connectors = {
    settings = {
      preview = "Enabled"
    }
  }
}

```

## Bicep Structure

This blueprint also provides a Bicep implementation with the following components:

- **Main Template** (`bicep/main.bicep`): The primary deployment template that orchestrates the overall solution
- **Types Definition** (`bicep/types.core.bicep`): Defines core parameter types and structures used throughout the deployment

The Bicep implementation follows the same architecture as the Terraform version, providing a native Azure Resource Manager (ARM) approach to deploying the same resources.

### Key Modules Used in Bicep

| Module                  | Purpose                             | Source Location                                      |
|-------------------------|-------------------------------------|------------------------------------------------------|
| `resourceGroup`         | Creates the resource group          | Inline resource in main.bicep                        |
| `cloudResourceGroup`    | Sets up cloud resources             | `../../../src/000-cloud/000-resource-group/bicep`    |
| `cloudSecurityIdentity` | Handles identity and security       | `../../../src/000-cloud/010-security-identity/bicep` |
| `edgeVmHost`            | Creates the VM host for the cluster | `../../../src/100-edge/051-vm-host/bicep`            |
| `edgeCncfCluster`       | Deploys K3s Kubernetes cluster      | `../../../src/100-edge/100-cncf-cluster/bicep`       |
| `edgeIotOps`            | Installs Azure IoT Operations       | `../../../src/100-edge/110-iot-ops/bicep`            |

## Parameter Reference in Bicep

The Bicep implementation uses a streamlined parameter approach with a `Common` object type and additional parameters:

| Parameter                             | Description                    | Default        | Notes                                                       |
|---------------------------------------|--------------------------------|----------------|-------------------------------------------------------------|
| `common.resourcePrefix`               | Prefix for resource naming     | Required       | Short unique alphanumeric string (max 8 chars recommended)  |
| `common.location`                     | Azure region location          | Required       | "eastus2", "westus3", etc.                                  |
| `common.environment`                  | Environment type               | Required       | "dev", "test", "prod", etc.                                 |
| `common.instance`                     | Deployment instance number     | Required       | For multiple deployments                                    |
| `useExistingResourceGroup`            | Use existing resource group    | `false`        | When true, looks up a resource group instead of creating it |
| `resourceGroupName`                   | Name of resource group         | Generated      | When empty, name is generated from common parameters        |
| `resourceGroupName`                   | Resource group name            | Auto-generated | Uses pattern: `rg-{prefix}-{environment}-{instance}`        |
| `adminPassword`                       | VM admin password              | Required       | **Important**: always pass this securely                    |
| `customLocationsOid`                  | Custom Locations SP Object ID  | Required       | Needed for Arc custom locations feature                     |
| `shouldCreateAnonymousBrokerListener` | Enable anonymous MQTT listener | `false`        | For dev/test only                                           |

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
