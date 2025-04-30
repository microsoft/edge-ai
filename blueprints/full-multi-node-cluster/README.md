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

| Variable                                  | Description                           | Default  | Notes                                    |
|-------------------------------------------|---------------------------------------|----------|------------------------------------------|
| `environment`                             | Environment type                      | Required | "dev", "test", "prod", etc.              |
| `resource_prefix`                         | Prefix for resource naming            | Required | Short unique alphanumeric string         |
| `location`                                | Azure region location                 | Required | "eastus2", "westus3", etc.               |
| `host_machine_count`                      | Number of VM hosts for the cluster    | `3`      | First host is server, others are workers |
| `custom_locations_oid`                    | Custom Locations object ID            | `null`   | Retrieved via Azure CLI if not provided  |
| `should_create_anonymous_broker_listener` | Enable anonymous MQTT broker listener | `false`  | For testing only - insecure              |
| `should_create_fabric`                    | Deploy Microsoft Fabric resources     | `false`  | Optional data analytics components       |
| `should_create_aks`                       | Deploy Azure Kubernetes Service       | `false`  | Optional alternative to K3s              |
| `should_create_private_endpoint`          | Use private endpoint for ACR          | `false`  | Enhanced security option                 |

For additional configuration options, review the variables in `variables.tf`.

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

| Variable                              | Description                           | Default  | Notes                                                                |
|---------------------------------------|---------------------------------------|----------|----------------------------------------------------------------------|
| `common.environment`                  | Environment type                      | Required | "dev", "test", "prod", etc.                                          |
| `common.resourcePrefix`               | Prefix for resource naming            | Required | Short unique alphanumeric string                                     |
| `common.location`                     | Azure region location                 | Required | "eastus2", "westus3", etc.                                           |
| `common.instance`                     | Deployment instance number            | `"001"`  | For multiple deployments                                             |
| `hostMachineCount`                    | Number of VM hosts for the cluster    | `3`      | Minimum 2 hosts required (`@minValue(2)`)                            |
| `adminPassword`                       | Password for SSH to the VMs           | Required | **Important**: always pass this inline, never store in `.bicepparam` |
| `customLocationsOid`                  | Custom Locations OID                  | Required | Retrieved from Azure CLI command `az ad sp show --id <ID>`           |
| `shouldCreateAnonymousBrokerListener` | Enable anonymous MQTT broker listener | `false`  | For testing only - insecure                                          |
| `shouldInitAio`                       | Deploy AIO initial resources          | `true`   | Platform components, Secret Sync, extensions                         |
| `shouldDeployAio`                     | Deploy AIO instance and components    | `true`   | MQ Broker, Data Flow, Assets, etc.                                   |

For additional configuration options, review the parameters in `main.bicep`.

## Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly with Windows-based systems and also works well with nix-compatible environments.

Refer to the Environment Setup section in the [Root README](../README.md#getting-started-and-prerequisites-setup) for detailed instructions on setting up your environment.

Additionally, ensure you have the following prerequisites:

- Sufficient quota for multiple VMs in your target region
- At least 8 GB of RAM per VM (32 GB+ recommended for all 3 nodes)
- Registered resource providers (see deployment instructions)
- Appropriate permissions to create resources

## Terraform Deployment Instructions

```sh
# Navigate to the terraform directory
cd ./terraform
```

### 1. Prepare Configuration

First, use `terraform-docs` to generate a `.tfvars` file with all available parameters:

```sh
# Generate the tfvars file template
terraform-docs tfvars hcl .
```

If terraform-docs is not installed, you'll need to install it:

```sh
# Install terraform-docs - macOS
brew install terraform-docs

# Install terraform-docs - Linux
../../scripts/install-terraform-docs.sh
```

Or visit the [terraform-docs installation page](https://terraform-docs.io/user-guide/installation/) for more options.

Copy the generated output to a file named `terraform.tfvars` and fill in at least these required values:

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

### 3. Deploy Terraform Resources

```bash
# Apply the Terraform configuration
terraform apply
```

## Bicep Deployment Instructions

```sh
# Navigate to the bicep directory
cd ./bicep
```

### 1. Get and Set Custom Locations OID

First, retrieve the Custom Locations OID and set it as an environment variable:

```sh
# Get the custom locations OID and export it as an environment variable
export CUSTOM_LOCATIONS_OID=$(az ad sp show --id bc313c14-388c-4e7d-a58e-70017303ee3b --query id -o tsv)

# Verify the environment variable is set correctly
echo $CUSTOM_LOCATIONS_OID
```

### 2. Create a Parameters File

Generate a parameters file using the Azure CLI's `bicep generate-params` command:

```sh
# Generate a parameters file template
az bicep generate-params --file main.bicep --output-format bicepparam --include-params all > main.bicepparam
```

Then edit the `main.bicepparam` file to set your deployment parameter values. At minimum, you must provide values for these required parameters:

```bicep
// Parameters for full-multi-node-cluster blueprint
using './main.bicep'

// Required parameters
param common = {
  resourcePrefix: 'myprefix'     // Replace with a unique prefix
  location: 'eastus2'            // Replace with your Azure region
  environment: 'dev'             // 'dev', 'test', or 'prod'
  instance: '001'                // Instance identifier
}

// Resource group name (defaults to rg-{resourcePrefix}-{environment}-{instance} if not specified)
param resourceGroupName = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'

// This is not optimal, to be replaced by KeyVault usage in future
@secure()
param adminPassword = 'YourSecurePassword123!' // Replace with a secure password

// The object id of the Custom Locations Entra ID application for your tenant
param customLocationsOid = readEnvironmentVariable('CUSTOM_LOCATIONS_OID') // Read from environment variable

// Optional parameters with defaults
param hostMachineCount = 3 // Minimum 2 nodes required, default 3
param shouldCreateAnonymousBrokerListener = false // For testing only - insecure
param shouldInitAio = true // Deploy AIO initial resources
param shouldDeployAio = true // Deploy AIO instance and components
```

### 3. Deploy Resources with Bicep

Deploy the resources using Azure CLI:

```bash
# Deploy using the Azure CLI
az deployment sub create --name <uniquename-prefix> --location <location> --parameters ./main.bicepparam
```

> **Note**: Ensure the CUSTOM_LOCATIONS_OID environment variable is set in your current shell session before running the deployment command.

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

You should see pods distributed across your worker nodes, with system pods on the control plane (server) node.

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
- **Custom Locations OID**: Verify correct OID for your tenant. This can vary between Azure AD instances
- **VM size availability**: Ensure the chosen VM size is available in your selected region

#### Terraform Deployments

The following messages are considered normal during deployment:

```txt
module.cloud_vm_host.azurerm_linux_virtual_machine.main[*]: Creating...
module.edge_cncf_cluster.null_resource.k3s_setup: Still creating... [7m6s elapsed]
module.edge_iot_ops.module.iot_ops_instance.azurerm_arc_kubernetes_cluster_extension.iot_operations: Still creating... [3m20s elapsed]
```

For recovery from failed deployments, you may:

- List terraform resources with the command `terraform state list` and remove specific resources using `terraform state rm <resource-id>`
- Manually remove the resource group with all its included resources

## Related Blueprints

- **[Full Single Cluster](../full-single-node-cluster/README.md)**: Complete deployment on a single-node cluster
- **[Only Cloud Single Node Cluster](../only-cloud-single-node-cluster/README.md)**: Deploy only the cloud resources
- **[Only Edge IoT Ops](../only-edge-iot-ops/README.md)**: Deploy only the edge components assuming cloud infrastructure exists
