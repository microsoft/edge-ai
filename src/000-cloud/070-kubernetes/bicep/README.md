<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# AKS Resources

Deploys optionally Azure Kubernetes Service (AKS) resources.

## Parameters

| Name                     | Description                                                     | Type                                                | Default                                           | Required |
|:-------------------------|:----------------------------------------------------------------|:----------------------------------------------------|:--------------------------------------------------|:---------|
| common                   | The common component configuration.                             | `[_2.Common](#user-defined-types)`                  | n/a                                               | yes      |
| virtualNetworkName       | Virtual network name for subnet creation.                       | `string`                                            | n/a                                               | yes      |
| networkSecurityGroupName | Network security group name to apply to the subnets.            | `string`                                            | n/a                                               | yes      |
| aksNetworkConfig         | AKS network configuration for subnets and NAT gateway.          | `[_1.AksNetworkConfig](#user-defined-types)`        | [variables('_1.aksNetworkConfigDefaults')]        | no       |
| natGatewayId             | NAT gateway ID for associating AKS subnets.                     | `string`                                            | n/a                                               | no       |
| shouldCreateAks          | Whether to create an Azure Kubernetes Service cluster.          | `bool`                                              | `false`                                           | no       |
| kubernetesClusterConfig  | The settings for the Azure Kubernetes Service cluster.          | `[_1.KubernetesCluster](#user-defined-types)`       | [variables('_1.kubernetesClusterDefaults')]       | no       |
| containerRegistryName    | Name of the Azure Container Registry to create.                 | `string`                                            | n/a                                               | yes      |
| aksPrivateClusterConfig  | AKS private cluster configuration.                              | `[_1.AksPrivateClusterConfig](#user-defined-types)` | [variables('_1.aksPrivateClusterConfigDefaults')] | no       |
| privateEndpointSubnetId  | Subnet ID for the private endpoint (from networking component). | `string`                                            | n/a                                               | no       |
| virtualNetworkId         | Virtual network ID for private DNS zone linking.                | `string`                                            | n/a                                               | no       |
| telemetry_opt_out        | Whether to opt out of telemetry data collection.                | `bool`                                              | `false`                                           | no       |

## Resources

| Name       | Type                              | API Version |
|:-----------|:----------------------------------|:------------|
| network    | `Microsoft.Resources/deployments` | 2025-04-01  |
| aksCluster | `Microsoft.Resources/deployments` | 2025-04-01  |

## Modules

| Name       | Description                                                                                     |
|:-----------|:------------------------------------------------------------------------------------------------|
| network    | Creates subnets for AKS private endpoints in an existing Virtual Network.                       |
| aksCluster | Deploys an Azure Kubernetes Service (AKS) cluster with integration to Azure Container Registry. |

## Module Details

### network

Creates subnets for AKS private endpoints in an existing Virtual Network.

#### Parameters for network

| Name                         | Description                                                                      | Type                               | Default | Required |
|:-----------------------------|:---------------------------------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                       | The common component configuration.                                              | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| virtualNetworkName           | Virtual network name for subnet creation.                                        | `string`                           | n/a     | yes      |
| networkSecurityGroupName     | Network security group name to apply to the subnets.                             | `string`                           | n/a     | yes      |
| subnetAddressPrefixAks       | Address prefix for the AKS system node subnet.                                   | `string`                           | n/a     | yes      |
| subnetAddressPrefixAksPod    | Address prefix for the AKS pod subnet.                                           | `string`                           | n/a     | yes      |
| defaultOutboundAccessEnabled | Whether to enable default outbound internet access for AKS subnets.              | `bool`                             | n/a     | yes      |
| shouldEnableNatGateway       | Whether to associate AKS subnets with a NAT gateway for managed outbound egress. | `bool`                             | n/a     | yes      |
| natGatewayId                 | NAT gateway ID for associating AKS subnets.                                      | `string`                           | n/a     | no       |

#### Resources for network

| Name       | Type                                        | API Version |
|:-----------|:--------------------------------------------|:------------|
| snetAks    | `Microsoft.Network/virtualNetworks/subnets` | 2025-01-01  |
| snetAksPod | `Microsoft.Network/virtualNetworks/subnets` | 2025-01-01  |

#### Outputs for network

| Name                    | Type     | Description                                        |
|:------------------------|:---------|:---------------------------------------------------|
| snetAksId               | `string` | The subnet ID for the AKS cluster.                 |
| snetAksName             | `string` | The subnet name for the AKS cluster.               |
| snetAksPodId            | `string` | The subnet ID for the AKS pods.                    |
| snetAksPodName          | `string` | The subnet name for the AKS pods.                  |
| snetAksAddressPrefix    | `string` | The address prefix for the AKS system node subnet. |
| snetAksPodAddressPrefix | `string` | The address prefix for the AKS pod subnet.         |

### aksCluster

Deploys an Azure Kubernetes Service (AKS) cluster with integration to Azure Container Registry.

#### Parameters for aksCluster

| Name                                 | Description                                               | Type                               | Default | Required |
|:-------------------------------------|:----------------------------------------------------------|:-----------------------------------|:--------|:---------|
| common                               | The common component configuration.                       | `[_1.Common](#user-defined-types)` | n/a     | yes      |
| nodeCount                            | Number of nodes for the agent pool in the AKS cluster.    | `int`                              | n/a     | yes      |
| nodeVmSize                           | VM size for the agent pool in the AKS cluster.            | `string`                           | n/a     | yes      |
| dnsPrefix                            | DNS prefix for the AKS cluster.                           | `string`                           | n/a     | yes      |
| snetAksId                            | Subnet ID for AKS cluster.                                | `string`                           | n/a     | yes      |
| snetAksPodId                         | Subnet ID for AKS pods.                                   | `string`                           | n/a     | yes      |
| acrName                              | ACR name for pull role assignment.                        | `string`                           | n/a     | yes      |
| shouldEnablePrivateCluster           | Whether to enable private cluster mode for AKS.           | `bool`                             | n/a     | yes      |
| shouldEnablePrivateClusterPublicFqdn | Whether to enable public FQDN for private cluster.        | `bool`                             | n/a     | yes      |
| shouldEnablePrivateEndpoint          | Whether to create a private endpoint for the AKS cluster. | `bool`                             | n/a     | yes      |
| privateEndpointSubnetId              | Subnet ID where the private endpoint will be created.     | `string`                           | n/a     | no       |
| virtualNetworkId                     | Virtual network ID for linking the private DNS zone.      | `string`                           | n/a     | no       |

#### Resources for aksCluster

| Name                | Type                                                      | API Version |
|:--------------------|:----------------------------------------------------------|:------------|
| aksCluster          | `Microsoft.ContainerService/managedClusters`              | 2024-09-01  |
| roleAssignment      | `Microsoft.Authorization/roleAssignments`                 | 2022-04-01  |
| privateDnsZone      | `Microsoft.Network/privateDnsZones`                       | 2024-06-01  |
| privateDnsZoneLink  | `Microsoft.Network/privateDnsZones/virtualNetworkLinks`   | 2024-06-01  |
| privateEndpoint     | `Microsoft.Network/privateEndpoints`                      | 2024-05-01  |
| privateDnsZoneGroup | `Microsoft.Network/privateEndpoints/privateDnsZoneGroups` | 2024-05-01  |

#### Outputs for aksCluster

| Name              | Type     | Description                           |
|:------------------|:---------|:--------------------------------------|
| aksName           | `string` | The AKS cluster name.                 |
| aksId             | `string` | The AKS cluster ID.                   |
| aksPrincipalId    | `string` | The AKS cluster principal ID.         |
| privateEndpointId | `string` | The private endpoint ID (if enabled). |
| privateDnsZoneId  | `string` | The private DNS zone ID (if enabled). |

## User Defined Types

### `_1.AksNetworkConfig`

Network configuration for AKS subnets.

| Property                     | Type     | Description                                                                      |
|:-----------------------------|:---------|:---------------------------------------------------------------------------------|
| subnetAddressPrefixAks       | `string` | Address prefix for the AKS system node subnet.                                   |
| subnetAddressPrefixAksPod    | `string` | Address prefix for the AKS pod subnet.                                           |
| defaultOutboundAccessEnabled | `bool`   | Whether to enable default outbound internet access for AKS subnets.              |
| shouldEnableNatGateway       | `bool`   | Whether to associate AKS subnets with a NAT gateway for managed outbound egress. |

### `_1.AksPrivateClusterConfig`

Private cluster configuration for AKS.

| Property                             | Type   | Description                                               |
|:-------------------------------------|:-------|:----------------------------------------------------------|
| shouldEnablePrivateCluster           | `bool` | Whether to enable private cluster mode for AKS.           |
| shouldEnablePrivateClusterPublicFqdn | `bool` | Whether to enable public FQDN for private cluster.        |
| shouldEnablePrivateEndpoint          | `bool` | Whether to create a private endpoint for the AKS cluster. |

### `_1.KubernetesCluster`

The settings for the Azure Kubernetes Service cluster.

| Property   | Type     | Description                                                                         |
|:-----------|:---------|:------------------------------------------------------------------------------------|
| nodeCount  | `int`    | Number of nodes for the agent pool in the AKS cluster.                              |
| nodeVmSize | `string` | VM size for the agent pool in the AKS cluster.                                      |
| dnsPrefix  | `string` | DNS prefix for the AKS cluster. If not provided, a default value will be generated. |

### `_2.Common`

Common settings for the components.

| Property       | Type     | Description                                                       |
|:---------------|:---------|:------------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module.                          |
| location       | `string` | Location for all resources in this module.                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod. |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...        |

## Outputs

| Name                         | Type     | Description                                                 |
|:-----------------------------|:---------|:------------------------------------------------------------|
| aksName                      | `string` | The AKS cluster name.                                       |
| aksId                        | `string` | The AKS cluster ID.                                         |
| aksPrincipalId               | `string` | The AKS cluster principal ID.                               |
| snetAksId                    | `string` | The AKS system node subnet ID.                              |
| snetAksName                  | `string` | The AKS system node subnet name.                            |
| snetAksPodId                 | `string` | The AKS pod subnet ID.                                      |
| snetAksPodName               | `string` | The AKS pod subnet name.                                    |
| snetAksAddressPrefix         | `string` | The address prefix for the AKS system node subnet.          |
| snetAksPodAddressPrefix      | `string` | The address prefix for the AKS pod subnet.                  |
| defaultOutboundAccessEnabled | `bool`   | Whether default outbound access is enabled for AKS subnets. |
| natGatewayEnabled            | `bool`   | Whether NAT gateway is enabled for AKS subnets.             |
| privateEndpointId            | `string` | The private endpoint ID (if enabled).                       |
| privateDnsZoneId             | `string` | The private DNS zone ID (if enabled).                       |

<!-- END_BICEP_DOCS -->