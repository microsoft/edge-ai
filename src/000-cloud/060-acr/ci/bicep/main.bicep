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

@description('Whether to create a private endpoint for the Azure Container Registry.')
param shouldCreateAcrPrivateEndpoint bool = false

@description('The settings for the Azure Container Registry.')
param containerRegistryConfig types.ContainerRegistry = types.containerRegistryDefaults

/*
  Modules
*/

module mainModule '../../bicep/main.bicep' = {
  name: '${deployment().name}-main'
  params: {
    common: common
    virtualNetworkName: virtualNetworkName
    networkSecurityGroupName: networkSecurityGroupName
    shouldCreateAcrPrivateEndpoint: shouldCreateAcrPrivateEndpoint
    containerRegistryConfig: containerRegistryConfig
  }
}

/*
  Outputs
*/

@description('The Azure Container Registry ID.')
output acrId string = mainModule.outputs.acrId

@description('The Azure Container Registry name.')
output acrName string = mainModule.outputs.acrName
