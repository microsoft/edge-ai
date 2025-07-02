<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# AKS Resources

Deploys optionally Azure Kubernetes Service (AKS) resources.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_2.Common](#user-defined-types)`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|networkSecurityGroupName|Network security group name to apply to the subnets.|`string`|n/a|yes|
|shouldCreateAks|Whether to create an Azure Kubernetes Service cluster.|`bool`|`false`|no|
|kubernetesClusterConfig|The settings for the Azure Kubernetes Service cluster.|`[_1.KubernetesCluster](#user-defined-types)`|[variables('_1.kubernetesClusterDefaults')]|no|
|containerRegistryName|Name of the Azure Container Registry to create.|`string`|n/a|yes|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|network|`Microsoft.Resources/deployments`|2022-09-01|
|aksCluster|`Microsoft.Resources/deployments`|2022-09-01|

## Modules

|Name|Description|
| :--- | :--- |
|attribution||
|network|Creates subnets for AKS private endpoints in an existing Virtual Network.|
|aksCluster|Deploys an Azure Kubernetes Service (AKS) cluster with integration to Azure Container Registry.|

## Module Details

### attribution

### network

Creates subnets for AKS private endpoints in an existing Virtual Network.

#### Parameters for network

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|virtualNetworkName|Virtual network name for subnet creation.|`string`|n/a|yes|
|networkSecurityGroupName|Network security group name to apply to the subnets.|`string`|n/a|yes|

#### Resources for network

|Name|Type|API Version|
| :--- | :--- | :--- |
|vnet|`Microsoft.Network/virtualNetworks`|2024-05-01|
|nsg|`Microsoft.Network/networkSecurityGroups`|2024-05-01|
|snetAks|`Microsoft.Network/virtualNetworks/subnets`|2024-05-01|
|snetAksPod|`Microsoft.Network/virtualNetworks/subnets`|2024-05-01|

#### Outputs for network

|Name|Type|Description|
| :--- | :--- | :--- |
|snetAksId|`string`|The subnet ID for the AKS cluster.|
|snetAksName|`string`|The subnet name for the AKS cluster.|
|snetAksPodId|`string`|The subnet ID for the AKS pods.|

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
|acrName|ACR name for pull role assignment.|`string`|n/a|yes|

#### Resources for aksCluster

|Name|Type|API Version|
| :--- | :--- | :--- |
|acr|`Microsoft.ContainerRegistry/registries`|2023-01-01-preview|
|aksCluster|`Microsoft.ContainerService/managedClusters`|2023-06-01|
|roleAssignment|`Microsoft.Authorization/roleAssignments`|2022-04-01|

#### Outputs for aksCluster

|Name|Type|Description|
| :--- | :--- | :--- |
|aksName|`string`|The AKS cluster name.|

## User Defined Types

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

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
