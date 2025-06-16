<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# AKS and ACR Resources

Deploys Azure Container Registry (ACR) and optionally Azure Kubernetes Service (AKS) resources.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|networkSecurityGroupId|Network security group ID to apply to the subnets.|`string`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint for the Azure Container Registry.|`bool`|`false`|no|
|containerRegistryConfig|The settings for the Azure Container Registry.|`[_1.ContainerRegistry](#user-defined-types)`|[variables('_1.containerRegistryDefaults')]|no|
|shouldCreateAks|Whether to create an Azure Kubernetes Service cluster.|`bool`|`false`|no|
|kubernetesClusterConfig|The settings for the Azure Kubernetes Service cluster.|`[_1.KubernetesCluster](#user-defined-types)`|[variables('_1.kubernetesClusterDefaults')]|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|network|`Microsoft.Resources/deployments`|2022-09-01|
|containerRegistry|`Microsoft.Resources/deployments`|2022-09-01|
|aksCluster|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|attribution||
|network|Creates subnets for AKS and ACR private endpoints in an existing Virtual Network.|
|containerRegistry|Deploys an Azure Container Registry with optional private endpoint.|
|aksCluster|Deploys an Azure Kubernetes Service (AKS) cluster with integration to Azure Container Registry.|

## Module Details

### attribution

### network

Creates subnets for AKS and ACR private endpoints in an existing Virtual Network.

#### Parameters for network

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|networkSecurityGroupId|Network security group ID to apply to the subnets.|`string`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint subnet for the Azure Container Registry.|`bool`|n/a|yes|

#### Resources for network

|Name|Type|API Version|
| :--- | :--- | :--- |
|vnet|`Microsoft.Network/virtualNetworks`|2024-05-01|
|snetAks|`Microsoft.Network/virtualNetworks/subnets`|2024-05-01|
|snetAksPod|`Microsoft.Network/virtualNetworks/subnets`|2024-05-01|
|snetAcr|`Microsoft.Network/virtualNetworks/subnets`|2024-05-01|

#### Outputs for network

|Name|Type|Description|
| :--- | :--- | :--- |
|snetAksId|`string`|The subnet ID for the AKS cluster.|
|snetAksName|`string`|The subnet name for the AKS cluster.|
|snetAksPodId|`string`|The subnet ID for the AKS pods.|
|snetAcrId|`string`|The subnet ID for the ACR private endpoint, if created.|

### containerRegistry

Deploys an Azure Container Registry with optional private endpoint.

#### Parameters for containerRegistry

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|sku|The SKU for the Azure Container Registry.|`string`|n/a|yes|
|shouldCreateAcrPrivateEndpoint|Whether to create a private endpoint for the Azure Container Registry.|`bool`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|snetAcrId|Subnet ID for ACR private endpoint.|`string`|n/a|yes|

#### Resources for containerRegistry

|Name|Type|API Version|
| :--- | :--- | :--- |
|vnet|`Microsoft.Network/virtualNetworks`|2024-05-01|
|acr|`Microsoft.ContainerRegistry/registries`|2023-01-01-preview|
|privateEndpoint|`Microsoft.Network/privateEndpoints`|2022-07-01|
|privateDnsZone|`Microsoft.Network/privateDnsZones`|2020-06-01|
|vnetLink|`Microsoft.Network/privateDnsZones/virtualNetworkLinks`|2020-06-01|
|aRecord|`Microsoft.Network/privateDnsZones/A`|2020-06-01|

#### Outputs for containerRegistry

|Name|Type|Description|
| :--- | :--- | :--- |
|acrId|`string`|The Azure Container Registry ID.|
|acrName|`string`|The Azure Container Registry name.|

### aksCluster

Deploys an Azure Kubernetes Service (AKS) cluster with integration to Azure Container Registry.

#### Parameters for aksCluster

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|nodeCount|Number of nodes for the agent pool in the AKS cluster.|`int`|n/a|yes|
|nodeVmSize|VM size for the agent pool in the AKS cluster.|`string`|n/a|yes|
|dnsPrefix|DNS prefix for the AKS cluster.|`string`|n/a|yes|
|snetAksId|Subnet ID for AKS cluster.|`string`|n/a|yes|
|snetAksPodId|Subnet ID for AKS pods.|`string`|n/a|yes|
|acrId|ACR ID for pull role assignment.|`string`|n/a|yes|

#### Resources for aksCluster

|Name|Type|API Version|
| :--- | :--- | :--- |
|aksCluster|`Microsoft.ContainerService/managedClusters`|2023-06-01|
|roleAssignment|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for aksCluster

|Name|Type|Description|
| :--- | :--- | :--- |
|aksName|`string`|The AKS cluster name.|

## User Defined Types

### `_1.ContainerRegistry`

The settings for the Azure Container Registry.

|Property|Type|Description|
| :--- | :--- | :--- |
|sku|`string`|The SKU for the Azure Container Registry. Options are Basic, Standard, Premium.|

### `_1.KubernetesCluster`

The settings for the Azure Kubernetes Service cluster.

|Property|Type|Description|
| :--- | :--- | :--- |
|nodeCount|`int`|Number of nodes for the agent pool in the AKS cluster.|
|nodeVmSize|`string`|VM size for the agent pool in the AKS cluster.|
|dnsPrefix|`string`|DNS prefix for the AKS cluster. If not provided, a default value will be generated.|

### `_2.Common`

Common settings for the components.

|Property|Type|Description|
| :--- | :--- | :--- |
|resourcePrefix|`string`|Prefix for all resources in this module.|
|location|`string`|Location for all resources in this module.|
|environment|`string`|Environment for all resources in this module: dev, test, or prod.|
|instance|`string`|Instance identifier for naming resources: 001, 002, etc...|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|aksName|`string`|The AKS cluster name.|
|acrName|`string`|The Azure Container Registry name.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
