# Full Multi-node Cluster Blueprint

## Overview

This blueprint provides a complete end-to-end deployment of Azure IoT Operations (AIO) on a multi-node, Arc-enabled Kubernetes cluster. It deploys all necessary components from VM creation to AIO installation, resulting in a production-grade edge computing environment with high availability that integrates with Azure cloud services.
Please follow general blueprint recommendations from blueprints [README.md](../README.md).

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

| Module                       | Purpose                                   | Source Location                                 |
|------------------------------|-------------------------------------------|-------------------------------------------------|
| `onboard_requirements`       | Handles onboarding prerequisites          | `../../../src/005-onboard-reqs/terraform`       |
| `vm_host`                    | Creates multiple VM hosts for the cluster | `../../../src/010-vm-host/terraform`            |
| `cncf_cluster_install`       | Deploys multi-node K3s Kubernetes cluster | `../../../src/020-cncf-cluster/terraform`       |
| `iot_ops_cloud_requirements` | Sets up cloud prerequisites for AIO       | `../../../src/030-iot-ops-cloud-reqs/terraform` |
| `iot_ops_install`            | Installs Azure IoT Operations             | `../../../src/040-iot-ops/terraform`            |
| `messaging`                  | Deploys messaging components              | `../../../src/050-messaging/terraform`          |
| `observability`              | Sets up monitoring and observability      | `../../../src/070-observability/terraform`      |
| `iot_ops_utilities`          | Installs AIO utility components           | `../../../src/080-iot-ops-utility/terraform`    |

### Variable Reference in Terraform

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable             | Description                        | Default  | Notes                                    |
|----------------------|------------------------------------|----------|------------------------------------------|
| `host_machine_count` | Number of VM hosts for the cluster | `3`      | First host is server, others are workers |
| `environment`        | Environment type                   | Required | "dev", "test", "prod", etc.              |
| `resource_prefix`    | Prefix for resource naming         | Required | Short unique alphanumeric string         |
| `location`           | Azure region location              | Required | "eastus2", "westus3", etc.               |
| `instance`           | Deployment instance number         | `"001"`  | For multiple deployments                 |

For additional configuration options, review the variables in `variables.tf`.

## Bicep Structure

This blueprint consists of the following key components:

- **Main Configuration** (`bicep/main.bicep`): Orchestrates the deployment workflow and module dependencies
- **Types** (`bicep/types.core.bicep`): Defines core type definitions used throughout the blueprint

### Key Modules Used in Bicep

| Module            | Purpose                                   | Source Location                             |
|-------------------|-------------------------------------------|---------------------------------------------|
| `onboardReqs`     | Handles onboarding prerequisites          | `../../../src/005-onboard-reqs/bicep`       |
| `vmHost`          | Creates multiple VM hosts for the cluster | `../../../src/010-vm-host/bicep`            |
| `cncfCluster`     | Deploys multi-node K3s Kubernetes cluster | `../../../src/020-cncf-cluster/bicep`       |
| `iotOpsCloudReqs` | Sets up cloud prerequisites for AIO       | `../../../src/030-iot-ops-cloud-reqs/bicep` |
| `iotOps`          | Installs Azure IoT Operations             | `../../../src/040-iot-ops/bicep`            |

## Variable Reference in Bicep

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable                 | Description                  | Default  | Notes                                                                |
|--------------------------|------------------------------|----------|----------------------------------------------------------------------|
| `common.environment`     | Environment type             | Required | "dev", "test", "prod", etc.                                          |
| `common.resource_prefix` | Prefix for resource naming   | Required | Short unique alphanumeric string                                     |
| `common.location`        | Azure region location        | Required | "eastus2", "westus3", etc.                                           |
| `common.instance`        | Deployment instance number   | `"001"`  | For multiple deployments                                             |
| `hostMachineCount`       | Deployment instance number   | `3`      | First host is server, others are workers                             |
| `adminPassword`          | A password for SSH to the VM | Required | **Important**: always pass this inline, never store in `.bicepparam` |
| `customLocationsOid`     | Custom Locations OID         | Required | Retrieved from Azure CLI command `az ad sp show --id <OID>`          |

For additional configuration options, review the parameters in `main.bicep`.

## Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly with Windows-based systems and also works well with nix-compatible environments.

Refer to the Environment Setup section in the [Root README](../README.md#getting-started-and-prerequisites-setup) for detailed instructions on setting up your environment.

Additionally, ensure you have the following prerequisites:

- Sufficient quota for multiple VMs in your target region

## Terraform Deployment Instructions

### 1. Prepare Configuration

Create a `terraform.tfvars` file with the following required variables:

```hcl
# Required variables
environment     = "dev"                 # Environment type (dev, test, prod)
resource_prefix = "myprefix"            # Short unique prefix for resource naming
location        = "eastus2"             # Azure region location

# Optional (recommended) variables
instance        = "001"                 # Deployment instance number
host_machine_count = 3                  # Number of VMs for the cluster (minimum 3 recommended for HA)
```

### 2. Initialize Terraform

```bash
# Set Azure subscription context
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Initialize Terraform
terraform init
```

### 3. Deploy Resources

```bash
# Apply the Terraform configuration
terraform apply
```

## Bicep Deployment Instructions

### 1. Login into Azure and get Custom Locations OID

First, ensure you are logged into your subscription and retrieve the Custom Locations OID:

```sh
# Set your Azure subscription
az account set --subscription <subscription-id>

# Get the custom locations OID
az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv
```

### 2. Create a Parameters File

Create a file named `main.bicepparam` in the root of the `full-multi-node-cluster` directory with your deployment parameters:

```bicep
// Parameters for full-multi-node-cluster blueprint
using './bicep/main.bicep'

// Required parameters
param common = {
  resourcePrefix: 'myprefix'     // Replace with a unique prefix
  location: 'eastus2'            // Replace with your Azure region
  environment: 'dev'             // 'dev', 'test', or 'prod'
  instance: '001'
}

// This is not optimal, to be replaced by KeyVault usage in future
@secure()
param adminPassword = 'YourSecurePassword123!' // Replace with a secure password

param customLocationsOid = 'YourRetrievedOID' // Replace with the OID retrieved from the previous step

```

### 3. Deploy Resources with Bicep

```bash
# Deploy using the Azure CLI
az deployment sub create --name <uniquename-prefix> --location northeurope --parameters ./main.bicepparam
```

## Access Deployed Resources

After successful deployment:

1. **Access the Kubernetes cluster** (in one prompt):

   ```bash
   az connectedk8s proxy -n <cluster-name> -g <resource-group>
   ```

2. **View AIO resources** (in a separate prompt):

   ```bash
   kubectl get pods -n azure-iot-operations
   ```

3. **Check cluster nodes status**:

   ```bash
   kubectl get nodes -o wide
   ```

## Post-Deployment Tasks

### Verifying High Availability Setup

Check that your workloads are properly distributed across nodes:

```bash
kubectl get pods -A -o wide
```

### Monitoring the Deployment

#### For Terraform Deployments

View deployed resources and their status:

```bash
terraform output -json | jq
```

#### For Bicep Deployments

View deployed resources and their status:

```bash
az resource list --resource-group $RG_NAME -o table
```

## Cleanup

When finished with your deployment and you want to remove all deployed resources.

### Terraform Cleanup

```bash
terraform destroy -var-file=terraform.tfvars
```

### Bicep Cleanup

```bash
RG_NAME="rg-<common.resource_prefix>-<common.environment>-<common.instance>"
# Delete the resource group and all its resources
az group delete --name "$RG_NAME"
```

## Deployment Troubleshooting

Deployment duration for multi-node clusters will be longer than single-node deployments. Be patient during the provisioning process.

### Common Issues

- **Node joining failures**: If worker nodes fail to join the cluster, verify networking connectivity between VMs
- **Terraform timeouts**: Multi-node deployments may require increased timeouts for resource creation
- **Arc-enabled Kubernetes issues**: Similar to single-node deployments, Arc connection issues may occur

#### Terraform Deployments

The following messages are considered normal during deployment:

```txt
module.vm_host.azurerm_linux_virtual_machine.main[*]: Creating...
module.cncf_cluster_install.null_resource.k3s_setup: Still creating... [7m6s elapsed]
module.iot_ops_install.module.iot_ops_instance.azurerm_arc_kubernetes_cluster_extension.iot_operations: Still creating... [3m20s elapsed]
```

For recovery from failed deployments, you may:

- List terraform resources with the command `terraform state list` and remove specific resources using `terraform state rm <resource-id>`
- Manually remove the resource group with all its included resources
