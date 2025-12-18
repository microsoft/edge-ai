metadata name = 'AKS Resources'
metadata description = 'Deploys optionally Azure Kubernetes Service (AKS) resources.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Network Parameters
*/

@description('Virtual network name for subnet creation.')
param virtualNetworkName string

@description('Network security group name to apply to the subnets.')
param networkSecurityGroupName string

@description('AKS network configuration for subnets and NAT gateway.')
param aksNetworkConfig types.AksNetworkConfig = types.aksNetworkConfigDefaults

@description('NAT gateway ID for associating AKS subnets.')
param natGatewayId string?

/*
  Kubernetes Cluster Parameters
*/

@description('Whether to create an Azure Kubernetes Service cluster.')
param shouldCreateAks bool = false

@description('The settings for the Azure Kubernetes Service cluster.')
param kubernetesClusterConfig types.KubernetesCluster = types.kubernetesClusterDefaults

@description('Name of the Azure Container Registry to create.')
param containerRegistryName string

/*
  Private Cluster Parameters
*/

@description('AKS private cluster configuration.')
param aksPrivateClusterConfig types.AksPrivateClusterConfig = types.aksPrivateClusterConfigDefaults

@description('Subnet ID for the private endpoint (from networking component).')
param privateEndpointSubnetId string?

@description('Virtual network ID for private DNS zone linking.')
param virtualNetworkId string?

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Resources
*/

resource attribution 'Microsoft.Resources/deployments@2020-06-01' = if (!telemetry_opt_out) {
  name: 'pid-acce1e78-0375-4637-a593-86aa36dcfeac'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

/*
  Modules
*/

module network './modules/network.bicep' = {
  name: '${deployment().name}-network'
  params: {
    common: common
    virtualNetworkName: virtualNetworkName
    networkSecurityGroupName: networkSecurityGroupName
    subnetAddressPrefixAks: aksNetworkConfig.subnetAddressPrefixAks
    subnetAddressPrefixAksPod: aksNetworkConfig.subnetAddressPrefixAksPod
    defaultOutboundAccessEnabled: aksNetworkConfig.defaultOutboundAccessEnabled
    shouldEnableNatGateway: aksNetworkConfig.shouldEnableNatGateway
    natGatewayId: natGatewayId
    shouldEnablePrivateEndpoint: aksPrivateClusterConfig.shouldEnablePrivateEndpoint
  }
}

module aksCluster './modules/aks-cluster.bicep' = if (shouldCreateAks) {
  name: '${deployment().name}-aksCluster'
  params: {
    common: common
    nodeCount: kubernetesClusterConfig.nodeCount
    nodeVmSize: kubernetesClusterConfig.nodeVmSize
    dnsPrefix: kubernetesClusterConfig.?dnsPrefix ?? ''
    snetAksId: network.outputs.snetAksId
    snetAksPodId: network.outputs.snetAksPodId
    acrName: containerRegistryName
    shouldEnablePrivateCluster: aksPrivateClusterConfig.shouldEnablePrivateCluster
    shouldEnablePrivateClusterPublicFqdn: aksPrivateClusterConfig.shouldEnablePrivateClusterPublicFqdn
    shouldEnablePrivateEndpoint: aksPrivateClusterConfig.shouldEnablePrivateEndpoint
    privateEndpointSubnetId: privateEndpointSubnetId
    virtualNetworkId: virtualNetworkId
  }
}

/*
  Outputs
*/

@description('The AKS cluster name.')
output aksName string? = shouldCreateAks ? aksCluster!.outputs.aksName : null

@description('The AKS cluster ID.')
output aksId string? = shouldCreateAks ? aksCluster!.outputs.aksId : null

@description('The AKS cluster principal ID.')
output aksPrincipalId string? = shouldCreateAks ? aksCluster!.outputs.aksPrincipalId : null

@description('The AKS system node subnet ID.')
output snetAksId string = network.outputs.snetAksId

@description('The AKS system node subnet name.')
output snetAksName string = network.outputs.snetAksName

@description('The AKS pod subnet ID.')
output snetAksPodId string = network.outputs.snetAksPodId

@description('The AKS pod subnet name.')
output snetAksPodName string = network.outputs.snetAksPodName

@description('The address prefix for the AKS system node subnet.')
output snetAksAddressPrefix string = network.outputs.snetAksAddressPrefix

@description('The address prefix for the AKS pod subnet.')
output snetAksPodAddressPrefix string = network.outputs.snetAksPodAddressPrefix

@description('Whether default outbound access is enabled for AKS subnets.')
output defaultOutboundAccessEnabled bool = aksNetworkConfig.defaultOutboundAccessEnabled

@description('Whether NAT gateway is enabled for AKS subnets.')
output natGatewayEnabled bool = aksNetworkConfig.shouldEnableNatGateway

@description('The private endpoint ID (if enabled).')
output privateEndpointId string? = shouldCreateAks && aksPrivateClusterConfig.shouldEnablePrivateEndpoint
  ? aksCluster.?outputs.?privateEndpointId
  : null

@description('The private DNS zone ID (if enabled).')
output privateDnsZoneId string? = shouldCreateAks && aksPrivateClusterConfig.shouldEnablePrivateEndpoint
  ? aksCluster.?outputs.?privateDnsZoneId
  : null
