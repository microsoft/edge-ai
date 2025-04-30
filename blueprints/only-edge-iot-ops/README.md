# Only Edge IoT Ops Blueprint

## Overview

This blueprint deploys Azure IoT Operations (AIO) components on an existing Arc-enabled Kubernetes cluster without setting up cloud infrastructure. It's designed for scenarios where you already have infrastructure in place and only need to deploy the AIO edge components. This is particularly useful for adding AIO capabilities to existing edge environments or for testing AIO components on pre-existing clusters.

Please follow general blueprint recommendations from blueprints [README.md](../README.md).

## Architecture

This blueprint deploys:

1. Azure IoT Operations extensions on an existing Arc-enabled Kubernetes cluster
2. AIO components including MQTT Broker, Data Processor, and other edge modules
3. Optional OPC UA simulator and OpenTelemetry collector
4. Custom Locations and resource sync rules
5. Secret Store integration with an existing Key Vault

This blueprint assumes you already have:

- An Arc-enabled Kubernetes cluster
- Required cloud resources like Key Vault and identities

## Implementation Options

This blueprint is available in:

- **Bicep** - Infrastructure as Code using Azure Bicep

## Bicep Structure

This blueprint consists of the following key components:

- **Main Template** (`bicep/main.bicep`): The primary deployment template that orchestrates the edge component deployment
- **Types Definition** (`bicep/types.core.bicep`): Defines core parameter types and structures used throughout the deployment

### Key Modules Used in Bicep

| Module       | Purpose                                  | Source Location                           |
|--------------|------------------------------------------|-------------------------------------------|
| `edgeIotOps` | Deploys Azure IoT Operations on the edge | `../../../src/100-edge/110-iot-ops/bicep` |

## Variable Reference in Bicep

Beyond the basic required variables, this blueprint supports advanced customization:

| Variable                              | Description                                     | Default                                                                    | Notes                             |
|---------------------------------------|-------------------------------------------------|----------------------------------------------------------------------------|-----------------------------------|
| `common.environment`                  | Environment type                                | Required                                                                   | "dev", "test", "prod", etc.       |
| `common.resourcePrefix`               | Prefix for resource naming                      | Required                                                                   | Short unique alphanumeric string  |
| `common.location`                     | Azure region location                           | Required                                                                   | "eastus2", "westus3", etc.        |
| `common.instance`                     | Deployment instance number                      | `"001"`                                                                    | For multiple deployments          |
| `arcConnectedClusterName`             | Name of existing Arc-enabled Kubernetes cluster | `"arck-${common.resourcePrefix}-${common.environment}-${common.instance}"` | Must already exist                |
| `sseKeyVaultName`                     | Name of Key Vault for Secret Sync               | `"kv-${common.resourcePrefix}-${common.environment}-${common.instance}"`   | Must already exist                |
| `shouldCreateAnonymousBrokerListener` | Creates an insecure anonymous MQTT listener     | `false`                                                                    | Only use in dev/test environments |
| `shouldDeployResourceSyncRules`       | Deploy Custom Locations Resource Sync Rules     | `true`                                                                     |                                   |

For additional configuration options, review the parameters in `main.bicep`.

## Prerequisites

**IMPORTANT:** We highly suggest using [this project's integrated dev container](./.devcontainer/README.md) to get started quickly with Windows-based systems and also works well with nix-compatible environments.

Refer to the Environment Setup section in the [Root README](../README.md#getting-started-and-prerequisites-setup) for detailed instructions on setting up your environment.

## Specific Prerequisites for Only Edge IoT Ops

Before deploying this blueprint, you must have:

1. An Arc-enabled Kubernetes cluster (created via another blueprint or manually)
2. A Key Vault to store secrets
3. User-assigned managed identities for AIO and Secret Store extensions
4. Required roles and permissions assigned to the identities

## Bicep Deployment Instructions

```sh
# Navigate to the bicep directory
cd ./bicep
```

### 1. Create a Parameters File

Use the Azure CLI to automatically generate a parameters file with all available parameters. This approach ensures you have a complete template with all possible configuration options:

```sh
# Generate the parameter file with all parameters
az bicep generate-params --file main.bicep --output-format bicepparam --include-params all > main.bicepparam
```

Open the `main.bicepparam` file in your editor and update the values as needed. Here's a sample of what the file will look like and the key parameters you should modify:

```bicep
using './main.bicep'

// Common configuration (Required)
param common = {
  resourcePrefix: 'myprefix'     // Replace with your unique prefix
  location: 'eastus2'            // Replace with your Azure region
  environment: 'dev'             // 'dev', 'test', or 'prod'
  instance: '001'                // Instance number
}

// Custom Location settings
param customLocationName = '${arcConnectedClusterName}-cl'

// Secret Store Extension settings
param sseIdentityName = 'id-${common.resourcePrefix}-sse-${common.environment}-${common.instance}'
param sseKeyVaultName = 'kv-${common.resourcePrefix}-${common.environment}-${common.instance}'
param sseKeyVaultResourceGroupName = resourceGroup().name  // Or specify your Key Vault resource group
param shouldAssignSseKeyVaultRoles = true

// Deployment identity and Key Vault settings
param deployKeyVaultName = sseKeyVaultName
param deployIdentityName = 'id-${common.resourcePrefix}-deploy-${common.environment}-${common.instance}'
param deployKeyVaultResourceGroupName = sseKeyVaultResourceGroupName
param deployUserTokenSecretName =  // Optional: Leave empty if not needed

// Deployment script settings
param deploymentScriptsSecretNamePrefix = '${common.resourcePrefix}-${common.environment}-${common.instance}'
param shouldAssignDeployIdentityRoles = true

// Azure IoT Operations settings
param shouldInitAio = true
param aioIdentityName = 'id-${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
param aioInstanceName = '${arcConnectedClusterName}-ops-instance'
param arcConnectedClusterName = 'arck-${common.resourcePrefix}-${common.environment}-${common.instance}'
param schemaRegistryName = 'sr-${common.resourcePrefix}-${common.environment}-${common.instance}'
param shouldDeployAio = true
param shouldCreateAnonymousBrokerListener = false  // Set to true only for development/testing
param shouldDeployResourceSyncRules = true
```

> **Important**: Review all parameters carefully. At minimum, you must update the `common` object properties, `arcConnectedClusterName`, `sseKeyVaultName`, and `sseKeyVaultResourceGroupName` to match your environment.

### 2. Deploy Resources with Bicep

```sh
# Get the resource group name where the Arc cluster exists
RG_NAME="rg-myprefix-dev-001"  # Replace with your actual resource group name

# Deploy using the Azure CLI
az deployment group create --name <uniquename-prefix> --resource-group $RG_NAME --parameters ./main.bicepparam
```

### 3. Monitor Deployment Progress

You can monitor the deployment progress in the Azure Portal or with the following command:

```sh
# Check deployment status
az deployment group show --name <uniquename-prefix> --resource-group $RG_NAME --query properties.provisioningState -o tsv
```

## Access Deployed Resources

After successful deployment:

1. **Access the Kubernetes cluster**:

   ```sh
   # Set variables
   RG_NAME="rg-myprefix-dev-001"  # Replace with your actual resource group name
   CLUSTER_NAME="arck-myprefix-dev-001"  # Replace with your actual cluster name

   # Connect to the Arc-enabled Kubernetes cluster
   az connectedk8s proxy -n $CLUSTER_NAME -g $RG_NAME
   ```

2. **View AIO resources** (in a separate terminal):

   ```sh
   # View AIO pods
   kubectl get pods -n azure-iot-operations

   # View AIO services
   kubectl get services -n azure-iot-operations

   # View AIO MQTT broker status
   kubectl get mqttbroker -n azure-iot-operations

   # View AIO data processor status
   kubectl get dataprocessor -n azure-iot-operations
   ```

## Post-Deployment Tasks

### Verifying the Deployment

Verify that all AIO components are deployed and running correctly:

```sh
# Check AIO extension status
az k8s-extension show --name azure-iot-operations --cluster-type connectedClusters --cluster-name $CLUSTER_NAME --resource-group $RG_NAME

# Check all AIO resources
az iot ops resource list --cluster-name $CLUSTER_NAME --resource-group $RG_NAME
```

### Connecting Devices

To connect devices to your MQTT broker:

1. Get the MQTT broker endpoint:

   ```sh
   # Get the LoadBalancer IP for the MQTT broker
   kubectl get service aio-mq-dmqtt-frontend -n azure-iot-operations -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
   ```

2. Use standard MQTT clients to connect to the broker using the IP address and port 8883 (or 1883 if anonymous listener is enabled).

## Cleanup

When you're done with the deployment:

```sh
# Remove AIO instance
az iot ops instance delete --name <aio-instance-name> --resource-group $RG_NAME --yes

# Remove AIO extension
az k8s-extension delete --name azure-iot-operations --cluster-type connectedClusters --cluster-name $CLUSTER_NAME --resource-group $RG_NAME --yes

# Remove secret store extension
az k8s-extension delete --name akvsecretsprovider --cluster-type connectedClusters --cluster-name $CLUSTER_NAME --resource-group $RG_NAME --yes
```

## Deployment Troubleshooting

### Common Issues

- **Extension Installation Failures**:
  - Verify that your Arc-enabled cluster is correctly configured and online
  - Check that the cluster has the required compute resources
  - Ensure all prerequisites are properly set up
- **Secret Store Issues**:
  - Verify that the managed identity has proper access to the Key Vault
  - Check that the Key Vault exists and is accessible from the cluster
- **MQTT Broker Connectivity**:
  - Ensure network connectivity between your clients and the cluster
  - Check that any required ports are open in firewalls
  - Verify SSL/TLS certificates if using secure connections

## Related Blueprints

- **[Full Single Cluster](../full-single-node-cluster/README.md)**: Complete deployment including cloud and edge components
- **[Only Cloud Single Node Cluster](../only-cloud-single-node-cluster/README.md)**: Deploy only the cloud resources
- **[Full Multi-node Cluster](../full-multi-node-cluster/README.md)**: Multi-node high-availability deployment
