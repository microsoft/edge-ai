import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('Virtual network name for subnet creation.')
param virtualNetworkName string

@description('Network security group ID to apply to the subnets.')
param networkSecurityGroupId string

@description('Whether to create a private endpoint for the Azure Container Registry.')
param shouldCreateAcrPrivateEndpoint bool = false

@description('The settings for the Azure Container Registry.')
param containerRegistryConfig types.ContainerRegistry = types.containerRegistryDefaults

@description('Whether to create an Azure Kubernetes Service cluster.')
param shouldCreateAks bool = false

@description('The settings for the Azure Kubernetes Service cluster.')
param kubernetesClusterConfig types.KubernetesCluster = types.kubernetesClusterDefaults

/*
  Modules
*/

module mainModule '../../bicep/main.bicep' = {
  name: '${deployment().name}-main'
  params: {
    common: common
    virtualNetworkName: virtualNetworkName
    networkSecurityGroupId: networkSecurityGroupId
    shouldCreateAcrPrivateEndpoint: shouldCreateAcrPrivateEndpoint
    containerRegistryConfig: containerRegistryConfig
    shouldCreateAks: shouldCreateAks
    kubernetesClusterConfig: kubernetesClusterConfig
  }
}
