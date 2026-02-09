---
title: Full Multi-node Cluster Blueprint
description: Complete end-to-end deployment of Azure IoT Operations on a multi-node, Arc-enabled Kubernetes cluster providing production-grade high availability edge computing environment
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - azure iot operations
  - multi node cluster
  - high availability
  - kubernetes
  - arc-enabled
  - terraform
  - bicep
  - edge computing
  - production deployment
  - k3s cluster
estimated_reading_time: 3
---

## Full Multi-node Cluster Blueprint

This blueprint provides a complete end-to-end deployment of Azure IoT Operations (AIO) on a multi-node, Arc-enabled Kubernetes cluster. It deploys all necessary components from VM creation to AIO installation, resulting in a production-grade edge computing environment with high availability that integrates with Azure cloud services.
Please follow general blueprint deployment and recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. Multiple Linux VM hosts in Azure (default: 3 nodes) **or** uses existing Azure Arc-enabled servers
2. A K3s Kubernetes cluster with one server node and multiple worker nodes
3. Azure Arc connection for the cluster
4. Cloud resources required by AIO (Key Vault, Storage, etc.)
5. Azure IoT Operations components (MQTT Broker, Data Processor, etc.)
6. Optional messaging and observability components

The resulting architecture provides a resilient, high-availability edge-to-cloud solution with secure communication, data processing capabilities, and comprehensive monitoring suitable for production environments.

### Deployment Modes

| Mode                  | Description                       | Use Case                                                |
|-----------------------|-----------------------------------|---------------------------------------------------------|
| **Azure VMs**         | Creates new Linux VMs in Azure    | Development, testing, proof-of-concept                  |
| **Azure Arc Servers** | Uses existing Arc-enabled servers | Production edge deployments, on-premises infrastructure |

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
- **Locals** (`locals.tf`): Contains local variable calculations and transformations
- **Providers** (`providers.tf`): Configures the required Terraform providers

### Key Modules Used

| Module                    | Purpose                                   | Source Location                                          |
|---------------------------|-------------------------------------------|----------------------------------------------------------|
| `cloud_resource_group`    | Creates resource groups                   | `../../../src/000-cloud/000-resource-group/terraform`    |
| `cloud_security_identity` | Manages identities and security resources | `../../../src/000-cloud/010-security-identity/terraform` |
| `cloud_observability`     | Sets up monitoring resources              | `../../../src/000-cloud/020-observability/terraform`     |
| `cloud_data`              | Creates data storage resources            | `../../../src/000-cloud/030-data/terraform`              |
| `cloud_messaging`         | Deploys messaging components              | `../../../src/000-cloud/040-messaging/terraform`         |
| `cloud_networking`        | Provisions virtual network resources      | `../../../src/000-cloud/050-networking/terraform`        |
| `cloud_vm_host`           | Creates multiple VM hosts for the cluster | `../../../src/000-cloud/051-vm-host/terraform`           |
| `cloud_acr`               | Azure Container Registry resources        | `../../../src/000-cloud/060-acr/terraform`               |
| `cloud_kubernetes`        | Optional AKS cluster resources            | `../../../src/000-cloud/070-kubernetes/terraform`        |
| `edge_cncf_cluster`       | Deploys multi-node K3s Kubernetes cluster | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_arc_extensions`     | Installs Arc cluster extensions           | `../../../src/100-edge/109-arc-extensions/terraform`     |
| `edge_iot_ops`            | Installs Azure IoT Operations             | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_assets`             | Manages IoT devices and assets            | `../../../src/100-edge/111-assets/terraform`             |
| `edge_observability`      | Sets up monitoring and observability      | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`          | Deploys edge messaging components         | `../../../src/100-edge/130-messaging/terraform`          |

### Variable Reference in Terraform

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable                                  | Description                           | Default  | Notes                                         |
|-------------------------------------------|---------------------------------------|----------|-----------------------------------------------|
| `environment`                             | Environment type                      | Required | "dev", "test", "prod", etc.                   |
| `resource_prefix`                         | Prefix for resource naming            | Required | Short unique alphanumeric string              |
| `location`                                | Azure region location                 | Required | "eastus2", "westus3", etc.                    |
| `resource_group_name`                     | Name of existing resource group       | `null`   | When null, name is generated                  |
| `host_machine_count`                      | Number of VM hosts for the cluster    | `3`      | First host is server, others are workers      |
| `should_use_arc_machines`                 | Use existing Arc servers              | `false`  | Set to true for Arc server deployments        |
| `arc_machine_count`                       | Number of Arc machines                | `1`      | Required when should_use_arc_machines is true |
| `arc_machine_name_prefix`                 | Prefix for Arc machine names          | `null`   | Defaults to resource_prefix                   |
| `cluster_server_ip`                       | Server node IP address                | `null`   | Required when should_use_arc_machines is true |
| `onboard_identity_type`                   | Identity for Arc onboarding           | `"id"`   | Use "skip" for Arc servers                    |
| `custom_locations_oid`                    | Custom Locations object ID            | `null`   | Retrieved via Azure CLI if not provided       |
| `should_create_anonymous_broker_listener` | Enable anonymous MQTT broker listener | `false`  | For testing only - insecure                   |
| `should_create_aks`                       | Deploy Azure Kubernetes Service       | `false`  | Optional alternative to K3s                   |
| `should_enable_private_endpoints`         | Use private endpoints for ACR         | `false`  | Enhanced security option                      |
| `aio_features`                            | AIO feature configurations            | `null`   | Configure Azure IoT Operations features       |

For additional configuration options, review the variables in `variables.tf`.

### Example Configurations

| Example File                                                     | Description                                           |
|------------------------------------------------------------------|-------------------------------------------------------|
| [simple.tfvars.example](terraform/simple.tfvars.example)         | Minimal configuration for Azure VM-based deployment   |
| [simple-arc.tfvars.example](terraform/simple-arc.tfvars.example) | Configuration for Azure Arc-enabled server deployment |

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

## Deploying to Azure Arc for Servers

This blueprint supports deploying to existing Azure Arc-enabled servers instead of creating new Azure VMs. This mode is ideal for production edge deployments where physical or on-premises servers are already registered with Azure Arc.

### Prerequisites for Arc Server Deployment

Before deploying to Arc-enabled servers, ensure:

1. **Arc-enabled servers are registered** in your Azure subscription
2. **System-assigned managed identity** is enabled on each Arc machine
3. **K3s prerequisites** are installed on each server:
   - Linux OS (Ubuntu 22.04 LTS recommended)
   - Minimum 8 GB RAM per node, 16 GB recommended
   - Network connectivity between all nodes
   - SSH access configured for cluster setup
4. **Naming convention** follows the pattern `{prefix}1`, `{prefix}2`, `{prefix}3`, etc.

### Arc Server Configuration

For a complete example of Arc server configuration, see [simple-arc.tfvars.example](terraform/simple-arc.tfvars.example).

Key variables for Arc server deployment:

| Variable                               | Description                                                                  |
|----------------------------------------|------------------------------------------------------------------------------|
| `should_use_arc_machines`              | Set to `true` to enable Arc server mode                                      |
| `arc_machine_count`                    | Number of Arc machines to use for the cluster                                |
| `arc_machine_name_prefix`              | Naming prefix for machines (e.g., `edgeserver` for edgeserver1, edgeserver2) |
| `cluster_server_ip`                    | IP address of the first machine (K3s server node)                            |
| `onboard_identity_type`                | Set to `"skip"` for Arc's system-assigned identity                           |
| `cluster_server_host_machine_username` | SSH username on the Arc machines                                             |

### Identity Configuration for Arc Servers

When deploying to Arc-enabled servers, the `onboard_identity_type` variable controls how cluster onboarding identities are managed:

| Value  | Description                           | Use Case                                  |
|--------|---------------------------------------|-------------------------------------------|
| `id`   | Create user-assigned managed identity | Azure VM deployments (default)            |
| `sp`   | Create service principal              | Custom authentication scenarios           |
| `skip` | Skip identity creation                | Arc servers with system-assigned identity |

For Arc server deployments, set `onboard_identity_type = "skip"` because the Arc onboarding process already establishes a system-assigned managed identity on each machine.

### Quick Start with Arc Servers

1. Copy the example configuration:

   ```bash
   cp simple-arc.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and update the values for your environment. See [simple-arc.tfvars.example](terraform/simple-arc.tfvars.example) for detailed documentation of each variable.

3. Deploy:

   ```bash
   terraform init
   terraform apply
   ```

## Bicep Structure

This blueprint consists of the following key components:

- **Main Configuration** (`bicep/main.bicep`): Orchestrates the deployment workflow and module dependencies
- **Types** (`bicep/types.core.bicep`): Defines core type definitions used throughout the blueprint

### Key Modules Used in Bicep

| Module                  | Purpose                                   | Source Location                                      |
|-------------------------|-------------------------------------------|------------------------------------------------------|
| `cloudResourceGroup`    | Creates resource groups                   | `../../../src/000-cloud/000-resource-group/bicep`    |
| `cloudSecurityIdentity` | Manages identities and security resources | `../../../src/000-cloud/010-security-identity/bicep` |
| `cloudData`             | Creates data storage resources            | `../../../src/000-cloud/030-data/bicep`              |
| `cloudVmHost`           | Creates multiple VM hosts for the cluster | `../../../src/000-cloud/051-vm-host/bicep`           |
| `edgeCncfCluster`       | Deploys multi-node K3s Kubernetes cluster | `../../../src/100-edge/100-cncf-cluster/bicep`       |
| `edgeIotOps`            | Installs Azure IoT Operations             | `../../../src/100-edge/110-iot-ops/bicep`            |

## Variable Reference in Bicep

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable                              | Description                           | Default   | Notes                                                                |
|---------------------------------------|---------------------------------------|-----------|----------------------------------------------------------------------|
| `common.environment`                  | Environment type                      | Required  | "dev", "test", "prod", etc.                                          |
| `common.resourcePrefix`               | Prefix for resource naming            | Required  | Short unique alphanumeric string                                     |
| `common.location`                     | Azure region location                 | Required  | "eastus2", "westus3", etc.                                           |
| `useExistingResourceGroup`            | Use existing resource group           | `false`   | When true, looks up a resource group instead of creating it          |
| `resourceGroupName`                   | Name of existing resource group       | Generated | When empty, name is generated from common parameters                 |
| `common.instance`                     | Deployment instance number            | `"001"`   | For multiple deployments                                             |
| `hostMachineCount`                    | Number of VM hosts for the cluster    | `3`       | Minimum 2 hosts required (`@minValue(2)`)                            |
| `adminPassword`                       | Password for SSH to the VMs           | Required  | **Important**: always pass this inline, never store in `.bicepparam` |
| `customLocationsOid`                  | Custom Locations OID                  | Required  | Retrieved from Azure CLI command `az ad sp show --id <ID>`           |
| `shouldCreateAnonymousBrokerListener` | Enable anonymous MQTT broker listener | `false`   | For testing only - insecure                                          |
| `shouldInitAio`                       | Deploy AIO initial resources          | `true`    | Platform components, Secret Sync, extensions                         |
| `shouldDeployAio`                     | Deploy AIO instance and components    | `true`    | MQ Broker, Data Flow, Assets, etc.                                   |

For additional configuration options, review the parameters in `main.bicep`.

## Prerequisites

Ensure you have the following prerequisites:

- Sufficient quota for multiple VMs in your target region
- At least 8 GB of RAM per VM, recommended 16 GB of RAM per VM
- Registered resource providers (see deployment instructions)
- Appropriate permissions to create resources

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow)

## Related Blueprints

- **[Full Single Cluster](../full-single-node-cluster/README.md)**: Complete deployment on a single-node cluster
- **[Only Cloud Single Node Cluster](../only-cloud-single-node-cluster/README.md)**: Deploy only the cloud resources
- **[Only Edge IoT Ops](../only-edge-iot-ops/README.md)**: Deploy only the edge components assuming cloud infrastructure exists

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
