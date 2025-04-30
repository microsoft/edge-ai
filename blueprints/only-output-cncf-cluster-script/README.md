# CNCF Cluster Script Output Blueprint

## Overview

This blueprint provides Infrastructure as Code (IaC) configurations for generating installation scripts that set up and configure K3s Kubernetes clusters with Azure Arc connectivity. Unlike the full deployment blueprints, this option focuses on script generation without actually deploying the cluster resources. The generated scripts can then be manually executed in your target environment.

There are two implementation options:

- **Terraform**: Generates scripts that can be output to a local directory
- **Bicep**: Generates scripts and stores them as secrets in an Azure Key Vault

Both implementations create two types of scripts:

1. **Server Script**: For setting up the primary K3s server node and Arc enablement
2. **Node Script**: For joining additional worker nodes to the cluster (for multi-node deployments)

## Terraform Structure

- Uses the reusable component from `/src/100-edge/100-cncf-cluster/terraform`
- Outputs the generated scripts to the specified output path
- Can optionally create an Azure managed identity for cluster Arc enablement

### Terraform Key Input Variables

| Variable                              | Description                                  | Default                           | Required |
|---------------------------------------|----------------------------------------------|-----------------------------------|:--------:|
| `resource_prefix`                     | Prefix for all resources                     | n/a                               |   yes    |
| `environment`                         | Environment (dev, test, prod)                | n/a                               |   yes    |
| `instance`                            | Instance identifier                          | `"001"`                           |    no    |
| `custom_locations_oid`                | Custom Locations Service Principal Object ID | `null` (will attempt to retrieve) |    no    |
| `arc_onboarding_sp`                   | Service Principal for Arc onboarding         | `null`                            |    no    |
| `cluster_admin_oid`                   | Object ID for cluster-admin permissions      | `null` (current user if enabled)  |    no    |
| `should_output_cluster_server_script` | Whether to output the server script          | `true`                            |    no    |
| `should_output_cluster_node_script`   | Whether to output the node script            | `false`                           |    no    |
| `script_output_filepath`              | Path to output script files                  | `"./out"`                         |    no    |

## Bicep Structure

- Deploys a user-assigned managed identity for Arc onboarding (if enabled)
- Creates role assignments (if enabled)
- Generates scripts and stores them as secrets in an Azure Key Vault
- Provides outputs for accessing the generated scripts

### Bicep Key Parameters

| Parameter                          | Description                                      | Default                        | Required |
|------------------------------------|--------------------------------------------------|--------------------------------|:--------:|
| `common`                           | Common settings (resourcePrefix, location, etc.) | n/a                            |   yes    |
| `customLocationsOid`               | Custom Locations Service Principal Object ID     | n/a                            |   yes    |
| `keyVaultName`                     | Name of the Key Vault for script storage         | Generated from resource prefix |    no    |
| `arcOnboardingSpClientId`          | Service Principal Client ID for Arc onboarding   | n/a                            |    no    |
| `shouldAddCurrentUserClusterAdmin` | Add current user as cluster admin                | `true`                         |    no    |
| `clusterServerVirtualMachineName`  | VM name for the server                           | n/a                            |    no    |
| `clusterNodeVirtualMachineNames`   | VM names for worker nodes                        | n/a                            |    no    |
| `shouldDeployScriptToVm`           | Deploy scripts directly to VMs                   | `false`                        |    no    |

## Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly with Windows-based systems and also works well with nix-compatible environments.

Refer to the Environment Setup section in the [Root README](../README.md#getting-started-and-prerequisites-setup) for detailed instructions on setting up your environment.

## Specific Prerequisites for Only Output CNCF Cluster Script

Before deploying this blueprint, you must have:

1. **Azure Key Vault** (required for Bicep implementation only)

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
# terraform.tfvars
resource_prefix = "myproject"
environment = "dev"
instance = "001"
custom_locations_oid = "00000000-0000-0000-0000-000000000000"
should_output_cluster_node_script = true
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

Generate a parameters file with all available parameters using the Azure CLI:

```sh
# Generate a parameters file with all available parameters
az bicep generate-params --file main.bicep --output-format bicepparam --include-params all > main.bicepparam
```

Edit the generated `main.bicepparam` file to set required parameters and customize optional ones:

```bicep
// main.bicepparam
using 'main.bicep'

// Required common configuration parameters
param common = {
  resourcePrefix: 'myprefix'    // Prefix for all resources
  location: 'eastus2'           // Azure region for deployment
  environment: 'dev'            // Environment (dev, test, prod)
  instance: '001'               // Instance identifier for resource naming
}

// Required parameter for Custom Locations integration
// Uses the environment variable set in the previous step
param customLocationsOid = readEnvironmentVariable('CUSTOM_LOCATIONS_OID')

// Optional: Azure Arc Configuration Parameters
param arcConnectedClusterName = 'arck-${common.resourcePrefix}-${common.environment}-${common.instance}'
param arcOnboardingIdentityName = 'id-${common.resourcePrefix}-arc-${common.environment}-${common.instance}'
param shouldEnableArcAutoUpgrade = common.environment != 'prod' // Auto-upgrade is enabled by default for non-prod environments
param shouldAssignRoles = true                                  // Default: assign necessary roles for Arc onboarding

// Optional: K3s Cluster Configuration Parameters
param clusterServerHostMachineUsername = common.resourcePrefix // Default: uses resourcePrefix as username
param shouldAddCurrentUserClusterAdmin = true                  // Default: adds current user as cluster admin
param clusterServerVirtualMachineName = ''                     // If specified, scripts will be deployed to this VM
param clusterNodeVirtualMachineNames = []                      // Array of VM names for node machines in multi-node setup

// Optional: Key Vault Parameters for Script Storage
param keyVaultName = 'kv-${common.resourcePrefix}-${common.environment}-${common.instance}'
param keyVaultResourceGroupName = resourceGroup().name         // Default: current resource group
param deployUserTokenSecretName = 'deploy-user-token'          // Secret name for deploy user token
param k3sTokenSecretName = 'k3s-server-token'                  // Secret name for K3s token
param nodeScriptSecretName = 'cluster-node-ubuntu-k3s'         // Secret name for node script
param serverScriptSecretName = 'cluster-server-ubuntu-k3s'     // Secret name for server script

// Optional: Script Deployment Configuration
param shouldDeployScriptToVm = false  // Set to true to deploy scripts directly to VMs
param shouldSkipAzCliLogin = false    // Set to true to skip Azure CLI login in scripts
param shouldSkipInstallingAzCli = false  // Set to true to skip Azure CLI installation

// This is not optimal, to be replaced by KeyVault usage in future
@secure()
param arcOnboardingSpClientSecret = '' // Service Principal Client Secret for Arc onboarding

// Optional: K3s cluster token - will be auto-generated if not provided
@secure()
param serverToken = '' // K3s server token for securing node/server communication
```

### 3. Deploy Resources with Bicep

```sh
# Deploy using the Azure CLI at the subscription level
az deployment sub create --name <uniquename-prefix> --location <location> --parameters ./main.bicepparam
```

> **Note**: Ensure the CUSTOM_LOCATIONS_OID environment variable is set in your current shell session before running the deployment command.

## Access Deployed Resources

### Terraform Deployed Resources

After deployment, all scripts are output to a `./out/` directory.

```sh
# Output all script files
ls -al ./out/
```

### Bicep Deployed Resources

After deployment, the Azure CLI will show deployment outputs with commands to retrieve the scripts from Key Vault. You can also retrieve them using these commands:

```bash
# Get the Key Vault name (if using the default naming pattern)
KV_NAME="kv-<resourcePrefix>-<environment>-<instance>"

# Retrieve scripts from Key Vault and save to local files
az keyvault secret show --name cluster-server-ubuntu-k3s --vault-name $KV_NAME --query value -o tsv > server-script.sh
az keyvault secret show --name cluster-node-ubuntu-k3s --vault-name $KV_NAME --query value -o tsv > node-script.sh

# Make scripts executable
chmod +x server-script.sh node-script.sh
```

> **Note**: The deployment outputs from Bicep will provide the exact commands to use for retrieving scripts from Key Vault, which may be preferable to using the commands above.

## Generated Scripts

This blueprint produces two types of scripts:

1. **Server Script**: Sets up the Kubernetes cluster primary node with K3s, installs necessary components, and enables Azure Arc connectivity.

2. **Node Script**: Configures additional nodes to join an existing K3s cluster (for multi-node deployments).

The scripts handle:

- K3s installation and configuration
- Azure CLI installation (optional)
- Azure login and subscription setup
- Azure Arc enablement
- Custom locations registration
- Workload identity setup
- Cluster role assignments

## Related Resources

- See the [full-single-cluster](../full-single-cluster/README.md) blueprint for complete deployment including the cluster
- See the [full-multi-node-cluster](../full-multi-node-cluster/README.md) blueprint for multi-node deployments
