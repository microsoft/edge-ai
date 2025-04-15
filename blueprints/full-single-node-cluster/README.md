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
- **Locals** (`locals.tf`): Contains local variable calculations and transformations
- **Providers** (`providers.tf`): Configures the required Terraform providers

### Key Modules Used in Terraform

| Module                       | Purpose                              | Source Location                                 |
|------------------------------|--------------------------------------|-------------------------------------------------|
| `onboard_requirements`       | Handles onboarding prerequisites     | `../../../src/005-onboard-reqs/terraform`       |
| `vm_host`                    | Creates the VM host for the cluster  | `../../../src/010-vm-host/terraform`            |
| `cncf_cluster_install`       | Deploys K3s Kubernetes cluster       | `../../../src/020-cncf-cluster/terraform`       |
| `iot_ops_cloud_requirements` | Sets up cloud prerequisites for AIO  | `../../../src/030-iot-ops-cloud-reqs/terraform` |
| `iot_ops_install`            | Installs Azure IoT Operations        | `../../../src/040-iot-ops/terraform`            |
| `messaging`                  | Deploys messaging components         | `../../../src/050-messaging/terraform`          |
| `observability`              | Sets up monitoring and observability | `../../../src/070-observability/terraform`      |
| `iot_ops_utilities`          | Installs AIO utility components      | `../../../src/080-iot-ops-utility/terraform`    |

### Variable Reference in Terraform

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable          | Description                | Default  | Notes                            |
|-------------------|----------------------------|----------|----------------------------------|
| `environment`     | Environment type           | Required | "dev", "test", "prod", etc.      |
| `resource_prefix` | Prefix for resource naming | Required | Short unique alphanumeric string |
| `location`        | Azure region location      | Required | "eastus2", "westus3", etc.       |
| `instance`        | Deployment instance number | `"001"`  | For multiple deployments         |

For additional configuration options, review the variables in `variables.tf`.

## Bicep Structure

This blueprint also provides a Bicep implementation with the following components:

- **Main Template** (`bicep/main.bicep`): The primary deployment template that orchestrates the overall solution
- **Types Definition** (`bicep/types.core.bicep`): Defines core parameter types and structures used throughout the deployment

The Bicep implementation follows the same architecture as the Terraform version, providing a native Azure Resource Manager (ARM) approach to deploying the same resources.
Note currently not all modules are available in Bicep yet.

### Key Modules Used in Bicep

| Module            | Purpose                             | Source Location                             |
|-------------------|-------------------------------------|---------------------------------------------|
| `onboardReqs`     | Handles onboarding prerequisites    | `../../../src/005-onboard-reqs/bicep`       |
| `vmHost`          | Creates the VM host for the cluster | `../../../src/010-vm-host/bicep`            |
| `cncfCluster`     | Deploys K3s Kubernetes cluster      | `../../../src/020-cncf-cluster/bicep`       |
| `iotOpsCloudReqs` | Sets up cloud prerequisites for AIO | `../../../src/030-iot-ops-cloud-reqs/bicep` |
| `iotOps`          | Installs Azure IoT Operations       | `../../../src/040-iot-ops/bicep`            |

## Variable Reference in Bicep

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable                 | Description                  | Default  | Notes                                                                |
|--------------------------|------------------------------|----------|----------------------------------------------------------------------|
| `common.environment`     | Environment type             | Required | "dev", "test", "prod", etc.                                          |
| `common.resource_prefix` | Prefix for resource naming   | Required | Short unique alphanumeric string                                     |
| `common.location`        | Azure region location        | Required | "eastus2", "westus3", etc.                                           |
| `common.instance`        | Deployment instance number   | `"001"`  | For multiple deployments                                             |
| `adminPassword`          | A password for SSH to the VM | Required | **Important**: always pass this inline, never store in `.bicepparam` |

For additional configuration options, review the parameters in `main.bicep` (Bicep).

## Prerequisites

- Azure subscription with Owner or Contributor access
- Azure CLI installed (version 2.60.0 or later)
- For Terraform: Terraform installed (version 1.9.8 or later)
- For Bicep: Bicep CLI version 0.34.0 or later
- Git installed

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

Create a file named `main.bicepparam` in the root of the `full-single-node-cluster` directory with your deployment parameters:

```bicep
// Parameters for full-single-node-cluster blueprint
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

```sh
# Deploy using the Azure CLI
az deployment sub create --name <uniquename-prefix> --location northeurope --parameters ./main.bicepparam
```

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
az resource list --resource-group $RG_NAME -o table
```

## Cleanup

### Cleanup for Terraform Deployments

When finished with your deployment:

```sh
terraform destroy -var-file=terraform.tfvars
```

### Cleanup for Bicep Deployments

When finished with your deployment:

```sh
RG_NAME="rg-<common.resource_prefix>-<common.environment>-<common.instance>"
# Delete the resource group and all its resources
az group delete --name "$RG_NAME"
```

## Terraform Deployment Troubleshooting

Deployment duration is expected to be reasonable, although actual completion times may vary.
Make sure that you don't see the following message for more than ~10 minutes, messages that persist too long indicate a stuck deployment operation:

```text
module.iot_ops_install.module.apply_scripts_post_init[0].terraform_data.apply_scripts: Still creating... [2h17m9s elapsed]
```

After 1-2 hours, it may fail with an error message like this:

```text
│   24:   provisioner "local-exec" {
│
│ Error running command 'source ../../../src/040-iot-ops/terraform/modules/apply-scripts/../../../scripts/init-scripts.sh &&
│ ../../../src/040-iot-ops/terraform/modules/apply-scripts/../../../scripts/apply-otel-collector.sh': exit status 1. Output: Starting 'az
│ connectedk8s proxy'
│ Proxy PID: 79335, PGID: 79335
```

This particular error occurs because the Arc cluster is in an inappropriate state.
In this case, you can perform the following steps to recover and rerun `terraform apply` after that:

- List terraform resources with the command `terraform state list` and remove specific resources using `terraform state rm <resource-id>`
- Manually remove the resource group with all its included resources

The following messages are considered normal during deployment:

```text
module.cncf_cluster_install.azurerm_virtual_machine_extension.linux_setup[0]: Still creating... [7m6s elapsed]
module.iot_ops_install.module.iot_ops_instance.azurerm_arc_kubernetes_cluster_extension.iot_operations: Still creating... [3m20s elapsed]
module.iot_ops_install.module.iot_ops_instance.azapi_resource.instance: Still creating... [2m10s elapsed]
```
