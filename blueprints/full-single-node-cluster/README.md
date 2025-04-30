# Full Single Cluster Blueprint

## Overview

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
| `edge_vm_host`            | Creates the VM host for the cluster     | `../../../src/100-edge/050-vm-host/terraform`            |
| `edge_cncf_cluster`       | Deploys K3s Kubernetes cluster          | `../../../src/100-edge/100-cncf-cluster/terraform`       |
| `edge_iot_ops`            | Installs Azure IoT Operations           | `../../../src/100-edge/110-iot-ops/terraform`            |
| `edge_observability`      | Sets up edge monitoring                 | `../../../src/100-edge/120-observability/terraform`      |
| `edge_messaging`          | Deploys edge messaging components       | `../../../src/100-edge/130-messaging/terraform`          |

### Variable Reference in Terraform

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable                                  | Description                        | Default  | Notes                                            |
|-------------------------------------------|------------------------------------|----------|--------------------------------------------------|
| `environment`                             | Environment type                   | Required | "dev", "test", "prod", etc.                      |
| `resource_prefix`                         | Prefix for resource naming         | Required | Short unique alphanumeric string                 |
| `location`                                | Azure region location              | Required | "eastus2", "westus3", etc.                       |
| `instance`                                | Deployment instance number         | `"001"`  | For multiple deployments                         |
| `should_get_custom_locations_oid`         | Auto-retrieve Custom Locations OID | `true`   | Set to false when providing custom_locations_oid |
| `custom_locations_oid`                    | Custom Locations SP Object ID      | `null`   | Required for Arc custom locations                |
| `should_create_anonymous_broker_listener` | Enable anonymous MQTT listener     | `false`  | For dev/test only, not secure for production     |

For additional configuration options, review the variables in `variables.tf`.

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
| `edgeVmHost`            | Creates the VM host for the cluster | `../../../src/100-edge/050-vm-host/bicep`            |
| `edgeCncfCluster`       | Deploys K3s Kubernetes cluster      | `../../../src/100-edge/100-cncf-cluster/bicep`       |
| `edgeIotOps`            | Installs Azure IoT Operations       | `../../../src/100-edge/110-iot-ops/bicep`            |

## Parameter Reference in Bicep

The Bicep implementation uses a streamlined parameter approach with a `Common` object type:

| Parameter                             | Description                    | Default        | Notes                                                |
|---------------------------------------|--------------------------------|----------------|------------------------------------------------------|
| `common.resourcePrefix`               | Prefix for resource naming     | Required       | Short unique alphanumeric string                     |
| `common.location`                     | Azure region location          | Required       | "eastus2", "westus3", etc.                           |
| `common.environment`                  | Environment type               | Required       | "dev", "test", "prod", etc.                          |
| `common.instance`                     | Deployment instance number     | Required       | For multiple deployments                             |
| `resourceGroupName`                   | Resource group name            | Auto-generated | Uses pattern: `rg-{prefix}-{environment}-{instance}` |
| `adminPassword`                       | VM admin password              | Required       | **Important**: always pass this securely             |
| `customLocationsOid`                  | Custom Locations SP Object ID  | Required       | Needed for Arc custom locations feature              |
| `shouldCreateAnonymousBrokerListener` | Enable anonymous MQTT listener | `false`        | For dev/test only                                    |

## Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](../../.devcontainer/README.md) to get started quickly with all the necessary tools pre-installed.

Refer to the Environment Setup section in the [Repository README](../../README.md#getting-started-and-prerequisites-setup) for detailed instructions on setting up your environment.

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
```

### 2. Initialize Terraform

```sh
# Set Azure subscription context
export ARM_SUBSCRIPTION_ID=$(az account show --query id -o tsv)

# Initialize Terraform
terraform init
```

### 3. Deploy Resources

```sh
# Preview the deployment plan
terraform plan -var-file=terraform.tfvars

# Apply the Terraform configuration
terraform apply -var-file=terraform.tfvars
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

Generate a parameters file using the Azure CLI's Bicep parameter generation feature:

```sh
# Generate the parameters file template
az bicep generate-params --file main.bicep --output-format bicepparam --include-params all > main.bicepparam
```

Edit the generated `main.bicepparam` file to customize your deployment parameters:

```bicep
// Parameters for full-single-node-cluster blueprint
using './main.bicep'

// Required parameters for the common object
param common = {
  resourcePrefix: 'myprefix'     // Replace with a unique prefix
  location: 'eastus2'            // Replace with your Azure region
  environment: 'dev'             // 'dev', 'test', or 'prod'
  instance: '001'                // For multiple deployments
}

// This is not optimal, to be replaced by KeyVault usage in future
@secure()
param adminPassword = 'YourSecurePassword123!' // Replace with a secure password

// Required for Arc custom locations
param customLocationsOid = readEnvironmentVariable('CUSTOM_LOCATIONS_OID') // Read from environment variable

// Optional parameters with defaults
param resourceGroupName = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'
param shouldCreateAnonymousBrokerListener = false // Set to true only for dev/test environments
param shouldInitAio = true // Deploy the Azure IoT Operations initial connected cluster resources
param shouldDeployAio = true // Deploy an Azure IoT Operations Instance
```

### 3. Deploy Resources with Bicep

```sh
# Deploy using the Azure CLI at the subscription level
az deployment sub create --name <uniquename-prefix> --location <location> --parameters ./main.bicepparam
```

> **Note**: Ensure the CUSTOM_LOCATIONS_OID environment variable is set in your current shell session before running the deployment command.

## Access Deployed Resources

After successful deployment:

1. **Access the Kubernetes cluster** (in one prompt):

   ```sh
   az connectedk8s proxy -n <cluster-name> -g <resource-group>
   ```

2. **View AIO resources** (in a separate prompt):

   ```sh
   kubectl get pods -n azure-iot-operations
   ```

3. **Check cluster node status**:

   ```sh
   kubectl get nodes -o wide
   ```

## Post-Deployment Tasks

### Monitoring the Deployment

#### For Terraform Deployments

View deployed resources and their status:

```bash
terraform output -json | jq
```

#### For Bicep Deployments

View deployed resources and their status:

```bash
# Get the resource group name
RG_NAME="rg-<resource_prefix>-<environment>-<instance>"

# List resources in the resource group
az resource list --resource-group $RG_NAME -o table
```

### Common Deployment Issues

- **Deployment times**: Full deployment can take 15-45 minutes depending on Azure region and resource availability
- **Resource group naming**: Ensure resource prefix follows validation rules (alphanumeric with dashes, starting with a letter)
- **Arc connection**: If Arc connection fails, check network connectivity from the VM to Azure
- **AIO extension timeouts**: Extensions may occasionally time out during first deployment - retry after VM optimization

## Cleanup

### Cleanup for Terraform Deployments

When finished with your deployment:

```sh
terraform destroy -var-file=terraform.tfvars
```

### Cleanup for Bicep Deployments

When finished with your deployment:

```sh
# Get the resource group name
RG_NAME="rg-<resource_prefix>-<environment>-<instance>"

# Delete the resource group and all its resources
az group delete --name "$RG_NAME" --yes
```

## Terraform Deployment Troubleshooting

Deployment duration is expected to be 15-45 minutes, although actual completion times may vary.
Make sure that you don't see the following message for more than ~10 minutes, messages that persist too long indicate a stuck deployment operation:

```text
module.edge_iot_ops.module.apply_scripts_post_init[0].terraform_data.apply_scripts: Still creating... [30m9s elapsed]
```

After 1-2 hours, it may fail with an error message like this:

```text
│   24:   provisioner "local-exec" {
│
│ Error running command 'source ../../../src/100-edge/110-iot-ops/terraform/modules/apply-scripts/../../../scripts/init-scripts.sh &&
│ ../../../src/100-edge/110-iot-ops/terraform/modules/apply-scripts/../../../scripts/apply-otel-collector.sh': exit status 1. Output: Starting 'az
│ connectedk8s proxy'
│ Proxy PID: 79335, PGID: 79335
```

This particular error occurs because the Arc cluster is in an inappropriate state.
In this case, you can perform the following steps to recover and rerun `terraform apply` after that:

- List terraform resources with the command `terraform state list` and remove specific resources using `terraform state rm <resource-id>`
- Manually remove the resource group with all its included resources

The following messages are considered normal during deployment:

```text
module.edge_cncf_cluster.azurerm_virtual_machine_extension.linux_setup[0]: Still creating... [7m6s elapsed]
module.edge_iot_ops.module.iot_ops_instance.azurerm_arc_kubernetes_cluster_extension.iot_operations: Still creating... [3m20s elapsed]
module.edge_iot_ops.module.iot_ops_instance.azapi_resource.instance: Still creating... [2m10s elapsed]
```
