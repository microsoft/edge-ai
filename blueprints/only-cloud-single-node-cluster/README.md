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

| Variable                   | Description                     | Default   | Notes                                                                |
|----------------------------|---------------------------------|-----------|----------------------------------------------------------------------|
| `common.environment`       | Environment type                | Required  | "dev", "test", "prod", etc.                                          |
| `useExistingResourceGroup` | Use existing resource group     | `false`   | When true, looks up a resource group instead of creating it          |
| `resourceGroupName`        | Name of existing resource group | Generated | When empty, name is generated from common parameters                 |
| `common.resourcePrefix`    | Prefix for resource naming      | Required  | Short unique alphanumeric string                                     |
| `common.location`          | Azure region location           | Required  | "eastus2", "westus3", etc.                                           |
| `common.instance`          | Deployment instance number      | `"001"`   | For multiple deployments                                             |
| `adminPassword`            | A password for SSH to the VM    | Required  | **Important**: always pass this inline, never store in `.bicepparam` |

For additional configuration options, review the parameters in `main.bicep`.

## Prerequisites

Ensure you have the following prerequisites:

- Registered resource providers (see deployment instructions)
- Appropriate permissions to create resources

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow)

## Related Blueprints

- **[Full Single Cluster](../full-single-node-cluster/README.md)**: Complete deployment including edge components
- **[Full Multi-node Cluster](../full-multi-node-cluster/README.md)**: Multi-node high-availability deployment
- **[Only Edge IoT Ops](../only-edge-iot-ops/README.md)**: Deploy only the edge components assuming cloud infrastructure exists
