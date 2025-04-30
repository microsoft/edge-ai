# Only Cloud Single Node Cluster Blueprint

## Overview

This blueprint provides a deployment of the cloud components required for Azure IoT Operations (AIO) along with a single-node VM host. Unlike the full blueprint, this version **only** deploys the cloud resources and VM infrastructure, without installing the Kubernetes cluster or AIO components on the edge. This is ideal for scenarios where you want to prepare the cloud infrastructure first and handle the edge components separately or through a different process.

Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. A Linux VM host in Azure
2. Resource Group for all resources
3. Security and Identity resources (Key Vault, Managed Identities)
4. Data storage components
5. All cloud prerequisites for later AIO installation

The resulting architecture provides the cloud infrastructure needed for an Azure IoT Operations deployment, ready for subsequent edge component installation.

## Implementation Options

This blueprint is currently available in:

- **Bicep** - Infrastructure as Code using Azure Bicep

Future implementations may include Terraform support.

## Bicep Structure

This blueprint consists of the following key components:

- **Main Template** (`bicep/main.bicep`): The primary deployment template that orchestrates the overall solution
- **Types Definition** (`bicep/types.core.bicep`): Defines core parameter types and structures used throughout the deployment

### Key Modules Used in Bicep

| Module                  | Purpose                                 | Source Location                                      |
|-------------------------|-----------------------------------------|------------------------------------------------------|
| `cloudResourceGroup`    | Creates the resource group              | `../../../src/000-cloud/000-resource-group/bicep`    |
| `cloudSecurityIdentity` | Sets up security and identity resources | `../../../src/000-cloud/010-security-identity/bicep` |
| `cloudData`             | Creates data storage resources          | `../../../src/000-cloud/030-data/bicep`              |
| `cloudVmHost`           | Provisions the VM host                  | `../../../src/000-cloud/050-vm-host/bicep`           |

## Variable Reference in Bicep

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable                | Description                  | Default  | Notes                                                                |
|-------------------------|------------------------------|----------|----------------------------------------------------------------------|
| `common.environment`    | Environment type             | Required | "dev", "test", "prod", etc.                                          |
| `common.resourcePrefix` | Prefix for resource naming   | Required | Short unique alphanumeric string                                     |
| `common.location`       | Azure region location        | Required | "eastus2", "westus3", etc.                                           |
| `common.instance`       | Deployment instance number   | `"001"`  | For multiple deployments                                             |
| `adminPassword`         | A password for SSH to the VM | Required | **Important**: always pass this inline, never store in `.bicepparam` |

For additional configuration options, review the parameters in `main.bicep`.

## Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly with Windows-based systems and also works well with nix-compatible environments.

Refer to the Environment Setup section in the [Root README](../README.md#getting-started-and-prerequisites-setup) for detailed instructions on setting up your environment.

## Bicep Deployment Instructions

```sh
# Navigate to the bicep directory
cd ./bicep
```

### 1. Create a Parameters File

Generate a parameters file using the Azure CLI Bicep extension:

```sh
# Navigate to the bicep directory if not already there
cd ./bicep

# Generate a complete parameters file with all available parameters
az bicep generate-params --file main.bicep --output-format bicepparam --include-params all > main.bicepparam
```

Edit the generated `main.bicepparam` file to set your deployment values:

```bicep
// Parameters for only-cloud-single-node-cluster blueprint
using './main.bicep'

// Required common parameters
param common = {
  resourcePrefix: 'myprefix'     // Replace with a unique prefix
  location: 'eastus2'            // Replace with your Azure region
  environment: 'dev'             // 'dev', 'test', or 'prod'
  instance: '001'                // For multiple deployments
}

// Optional: Override the default resource group name
param resourceGroupName = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'

// Required: VM admin password (required for SSH access)
@secure()
param adminPassword = '' // Replace with a secure password - DO NOT STORE IN FILE
```

### 2. Deploy Resources with Bicep

```sh
# Deploy using the Azure CLI
az deployment sub create --name <uniquename-prefix> --location <location> --parameters ./main.bicepparam
```

## Access Deployed Resources

After successful deployment:

1. **Access the VM Host**:

   ```sh
   # Get the public IP of the VM
   RG_NAME="rg-<resource_prefix>-<environment>-<instance>"
   VM_NAME=$(az vm list -g $RG_NAME --query "[0].name" -o tsv)
   VM_IP=$(az vm show -d -g $RG_NAME -n $VM_NAME --query publicIps -o tsv)

   # SSH to the VM
   ssh <admin-username>@$VM_IP
   ```

## Post-Deployment Tasks

### Next Steps

After deploying the cloud infrastructure, you can:

1. **Install and configure a Kubernetes cluster** on the VM host
2. **Connect the cluster to Azure Arc**
3. **Deploy Azure IoT Operations** components
4. **Configure additional observability and messaging** components

### Monitoring the Deployment

View deployed resources and their status:

```bash
RG_NAME="rg-<resource_prefix>-<environment>-<instance>"
az resource list --resource-group $RG_NAME -o table
```

## Cleanup

When finished with your deployment:

```sh
RG_NAME="rg-<resource_prefix>-<environment>-<instance>"
# Delete the resource group and all its resources
az group delete --name "$RG_NAME"
```

## Deployment Troubleshooting

### Common Issues

- **Resource Deployment Failures**: Ensure you have registered all required resource providers in your subscription.
- **VM Creation Issues**: Check that your VM size is available in the selected region. Modify the parameters if needed.
- **Quota Limitations**: Some deployments may encounter quota limitations. Request quota increases if necessary.

## Related Blueprints

- **[Full Single Cluster](../full-single-node-cluster/README.md)**: Complete deployment including edge components
- **[Full Multi-node Cluster](../full-multi-node-cluster/README.md)**: Multi-node high-availability deployment
- **[Only Edge IoT Ops](../only-edge-iot-ops/README.md)**: Deploy only the edge components assuming cloud infrastructure exists
