metadata name = 'AKS and ACR Resources'
metadata description = 'Deploys Azure Container Registry (ACR) and optionally Azure Kubernetes Service (AKS) resources.'

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

@description('Network security group ID to apply to the subnets.')
param networkSecurityGroupId string

/*
  Container Registry Parameters
*/

@description('Whether to create a private endpoint for the Azure Container Registry.')
param shouldCreateAcrPrivateEndpoint bool = false

@description('The settings for the Azure Container Registry.')
param containerRegistryConfig types.ContainerRegistry = types.containerRegistryDefaults

/*
  Kubernetes Cluster Parameters
*/

@description('Whether to create an Azure Kubernetes Service cluster.')
param shouldCreateAks bool = false

@description('The settings for the Azure Kubernetes Service cluster.')
param kubernetesClusterConfig types.KubernetesCluster = types.kubernetesClusterDefaults

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
    networkSecurityGroupId: networkSecurityGroupId
    shouldCreateAcrPrivateEndpoint: shouldCreateAcrPrivateEndpoint
  }
}

module containerRegistry './modules/container-registry.bicep' = {
  name: '${deployment().name}-containerRegistry'
  params: {
    common: common
    sku: containerRegistryConfig.sku
    shouldCreateAcrPrivateEndpoint: shouldCreateAcrPrivateEndpoint
    snetAcrId: shouldCreateAcrPrivateEndpoint ? network.outputs.snetAcrId : ''
    virtualNetworkName: virtualNetworkName
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
    acrId: containerRegistry.outputs.acrId
  }
}

/*
  Outputs
*/

@description('The AKS cluster name.')
output aksName string = aksCluster.outputs.aksName

@description('The Azure Container Registry name.')
output acrName string = containerRegistry.outputs.acrName
