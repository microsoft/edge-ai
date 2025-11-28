import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('Virtual network name for subnet creation.')
param virtualNetworkName string

@description('Network security group name to apply to the subnets.')
param networkSecurityGroupName string

@description('Name of the Azure Container Registry to create.')
param containerRegistryName string

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
    containerRegistryName: containerRegistryName
    networkSecurityGroupName: networkSecurityGroupName
    shouldCreateAks: shouldCreateAks
    kubernetesClusterConfig: kubernetesClusterConfig
  }
}
