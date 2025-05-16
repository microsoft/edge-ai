metadata name = 'AKS and ACR Component Types'
metadata description = 'Type definitions and defaults for the AKS and ACR component.'

import * as core from './types.core.bicep'

/*
  Container Registry Configuration
*/

@export()
@description('The settings for the Azure Container Registry.')
type ContainerRegistry = {
  @description('The SKU for the Azure Container Registry. Options are Basic, Standard, Premium.')
  sku: 'Basic' | 'Standard' | 'Premium'
}

@export()
var containerRegistryDefaults = {
  sku: 'Premium'
}

/*
  Kubernetes Cluster Configuration
*/

@export()
@description('The settings for the Azure Kubernetes Service cluster.')
type KubernetesCluster = {
  @description('Number of nodes for the agent pool in the AKS cluster.')
  nodeCount: int

  @description('VM size for the agent pool in the AKS cluster.')
  nodeVmSize: string

  @description('DNS prefix for the AKS cluster. If not provided, a default value will be generated.')
  dnsPrefix: string?
}

@export()
var kubernetesClusterDefaults = {
  nodeCount: 1
  nodeVmSize: 'Standard_D8ds_v5'
  dnsPrefix: ''
}
