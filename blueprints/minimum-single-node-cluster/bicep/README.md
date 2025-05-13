<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Minimum Single Node Cluster Blueprint (Bicep)

This blueprint provides the minimal set of resources required to deploy Azure IoT Operations on a single-node, Arc-enabled Kubernetes cluster. It includes only the essential components and minimizes resource usage.

For a detailed overview and resource optimizations, please refer to the main README.md file in the minimum-single-node-cluster folder.

## Required Parameters

| Name | Type | Description |
|------|------|-------------|
| common | object | Common configuration for resource naming and location |
| adminPassword | securestring | Password for the VM administrator account |
| customLocationsOid | string | Object ID of the Custom Locations Entra ID application |

## Optional Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| resourceGroupName | string | auto-generated | Name of the resource group |
| shouldCreateAnonymousBrokerListener | bool | false | Whether to enable an insecure anonymous AIO MQ Broker Listener |
| shouldInitAio | bool | true | Whether to deploy initial AIO components |
| shouldDeployAio | bool | true | Whether to deploy AIO instance components |

### Common Object Properties

| Name | Type | Description |
|------|------|-------------|
| resourcePrefix | string | Prefix for all resources in this module |
| location | string | Azure region for deploying resources |
| environment | string | Environment name: dev, test, or prod |
| instance | string | Instance identifier for naming resources |

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|cloudResourceGroup|`Microsoft.Resources/deployments`|2022-09-01|
|cloudSecurityIdentity|`Microsoft.Resources/deployments`|2022-09-01|
|cloudData|`Microsoft.Resources/deployments`|2022-09-01|
|cloudVmHost|`Microsoft.Resources/deployments`|2022-09-01|
|edgeCncfCluster|`Microsoft.Resources/deployments`|2022-09-01|
|edgeIotOps|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|cloudResourceGroup|Creates the required resources needed for an edge IaC deployment.|
|cloudSecurityIdentity|Provisions cloud resources required for Azure IoT Operations including Schema Registry, Storage Account, Key Vault, and User Assigned Managed Identities.|
|cloudData|Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.|
|cloudVmHost|Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments.|
|edgeCncfCluster|This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity.|
|edgeIotOps|Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters.|

## Module Details

### cloudResourceGroup

Creates the required resources needed for an edge IaC deployment. This module creates the resource group with appropriate tags, including the 'TeamName' tag required by Azure policies.

### cloudSecurityIdentity

Provisions cloud resources required for Azure IoT Operations including Key Vault and User Assigned Managed Identities for various components (Secret Store Extension, Azure IoT Operations, Arc Onboarding, etc.).

### cloudData

Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution. The minimum single node cluster uses Standard tier storage with LRS (Locally Redundant Storage) replication to minimize costs.

### cloudVmHost

Provisions virtual machines and networking infrastructure for hosting Azure IoT Operations edge deployments. The minimum single node cluster uses a single Standard_D4s_v3 VM, which is the minimum recommended size for running Azure IoT Operations.

### edgeCncfCluster

This module provisions and deploys automation scripts to a VM host that create and configure a K3s Kubernetes cluster with Arc connectivity. The scripts handle cluster setup, workload identity enablement, and installation of required Azure Arc extensions.

### edgeIotOps

Deploys Azure IoT Operations extensions, instances, and configurations on Azure Arc-enabled Kubernetes clusters. The minimum single node cluster disables optional components like the OPC UA simulator and Open Telemetry Collector to reduce resource consumption.

## Outputs

| Name | Type | Description |
|------|------|-------------|
| arcConnectedClusterName | string | Name of the Arc-enabled Kubernetes cluster |
| vmUsername | string | Administrator username for the VM |
| vmNames | array | Names of all VMs deployed by the blueprint |
| aioPlatformExtensionId | string | ID of the Azure IoT Operations Platform Extension |

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
