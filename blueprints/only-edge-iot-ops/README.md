---
title: Only Edge IoT Ops Blueprint
description: Deployment of Azure IoT Operations components on existing Arc-enabled Kubernetes cluster without cloud infrastructure setup, ideal for existing edge environments
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - azure iot operations
  - edge components
  - arc-enabled cluster
  - existing infrastructure
  - terraform
  - bicep
  - edge deployment
  - mqtt broker
  - data processor
estimated_reading_time: 2
---

## Only Edge IoT Ops Blueprint

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

Ensure you have the following prerequisites:

- An Arc-enabled Kubernetes cluster (via another blueprint or manually)
- A Key Vault to store secrets (via another blueprint or manually)
- User-assigned managed identities for AIO and Secret Store extensions (via another blueprint or manually)
- Registered resource providers (see deployment instructions)
- Appropriate permissions to create resources

## Deploy Blueprint

Follow detailed deployment instructions from the blueprints README.md, [Detailed Deployment Workflow](../README.md#detailed-deployment-workflow)

## Related Blueprints

- **[Full Single Cluster](../full-single-node-cluster/README.md)**: Complete deployment including cloud and edge components
- **[Only Cloud Single Node Cluster](../only-cloud-single-node-cluster/README.md)**: Deploy only the cloud resources
- **[Full Multi-node Cluster](../full-multi-node-cluster/README.md)**: Multi-node high-availability deployment

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
