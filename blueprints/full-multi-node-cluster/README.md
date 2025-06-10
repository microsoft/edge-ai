# Full Multi-node Cluster Blueprint

## Overview

This blueprint provides a complete end-to-end deployment of Azure IoT Operations (AIO) on a multi-node, Arc-enabled Kubernetes cluster. It deploys all necessary components from VM creation to AIO installation, resulting in a production-grade edge computing environment with high availability that integrates with Azure cloud services.
Please follow general blueprint deployment and recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. Multiple Linux VM hosts in Azure (default: 3 nodes)
2. A K3s Kubernetes cluster with one server node and multiple worker nodes
3. Azure Arc connection for the cluster
4. Cloud resources required by AIO (Key Vault, Storage, etc.)
5. Azure IoT Operations components (MQTT Broker, Data Processor, etc.)
6. Optional messaging and observability components

The resulting architecture provides a resilient, high-availability edge-to-cloud solution with secure communication, data processing capabilities, and comprehensive monitoring suitable for production environments.

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
| `cloud_fabric`            | Provisions Microsoft Fabric resources     | `../../../src/000-cloud/031-fabric/terraform`            |
| `cloud_messaging`         | Deploys messaging components              | `../../../src/000-cloud/040-messaging/terraform`         |
| `cloud_vm_host`           | Creates multiple VM hosts for the cluster | `../../../src/000-cloud/050-vm-host/terraform`           |
| `cloud_aks_acr`           | Optional AKS and ACR resources            | `../../../src/000-cloud/060-aks-acr/terraform`           |
| `edge_cncf_cluster`       | Deploys multi-node K3s Kubernetes cluster | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_iot_ops`            | Installs Azure IoT Operations             | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_observability`      | Sets up monitoring and observability      | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`          | Deploys edge messaging components         | `../../../src/100-edge/130-messaging/terraform`          |

### Variable Reference in Terraform

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable                                  | Description                           | Default  | Notes                                       |
|-------------------------------------------|---------------------------------------|----------|---------------------------------------------|
| `environment`                             | Environment type                      | Required | "dev", "test", "prod", etc.                 |
| `resource_prefix`                         | Prefix for resource naming            | Required | Short unique alphanumeric string            |
| `location`                                | Azure region location                 | Required | "eastus2", "westus3", etc.                  |
| `resource_group_name`                     | Name of existing resource group       | `null`   | When null, name is generated                |
| `host_machine_count`                      | Number of VM hosts for the cluster    | `3`      | First host is server, others are workers    |
| `custom_locations_oid`                    | Custom Locations object ID            | `null`   | Retrieved via Azure CLI if not provided     |
| `should_create_anonymous_broker_listener` | Enable anonymous MQTT broker listener | `false`  | For testing only - insecure                 |
| `should_create_fabric`                    | Deploy Microsoft Fabric resources     | `false`  | Optional data analytics components          |
| `should_create_aks`                       | Deploy Azure Kubernetes Service       | `false`  | Optional alternative to K3s                 |
| `should_create_acr_private_endpoint`      | Use private endpoint for ACR          | `false`  | Enhanced security option                    |
| `should_enable_opc_sim_asset_discovery`   | Enable Asset Discovery feature        | `false`  | Preview feature for OPC UA simulator assets |
| `aio_features`                            | AIO feature configurations            | `null`   | Configure Azure IoT Operations features     |

For additional configuration options, review the variables in `variables.tf`.

> Note: The `aio_features` variable is a map that allows you to specify feature flags for Azure IoT Operations. This can be used to enable or disable specific features based on your deployment needs. For example, you can use the following format of variables to enable the preview feature [OPC UA asset discovery](https://learn.microsoft.com/azure/iot-operations/discover-manage-assets/howto-autodetect-opc-ua-assets-use-akri):

```hcl
should_enable_opc_sim_asset_discovery = true
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

This blueprint consists of the following key components:

- **Main Configuration** (`bicep/main.bicep`): Orchestrates the deployment workflow and module dependencies
- **Types** (`bicep/types.core.bicep`): Defines core type definitions used throughout the blueprint

### Key Modules Used in Bicep

| Module                  | Purpose                                   | Source Location                                      |
|-------------------------|-------------------------------------------|------------------------------------------------------|
| `cloudResourceGroup`    | Creates resource groups                   | `../../../src/000-cloud/000-resource-group/bicep`    |
| `cloudSecurityIdentity` | Manages identities and security resources | `../../../src/000-cloud/010-security-identity/bicep` |
| `cloudData`             | Creates data storage resources            | `../../../src/000-cloud/030-data/bicep`              |
| `cloudVmHost`           | Creates multiple VM hosts for the cluster | `../../../src/000-cloud/050-vm-host/bicep`           |
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
