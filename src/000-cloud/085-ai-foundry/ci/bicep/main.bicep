import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('Name for the AI Foundry account. If not provided, defaults to aif-{resourcePrefix}-{environment}-{instance}.')
param aiFoundryName string?

/*
  Microsoft Foundry Configuration Parameters
*/

@description('Configuration settings for the Microsoft Foundry account.')
param aiFoundryConfig types.AiFoundryConfig = types.aiFoundryConfigDefaults

@description('Tags to apply to all resources.')
param tags object = {}

/*
  AI Projects Parameters
*/

@description('Array of AI Foundry projects to create.')
param aiProjects types.AiProject[] = []

/*
  RAI Policies Parameters
*/

@description('Array of RAI policies to create.')
param raiPolicies types.RaiPolicy[] = []

/*
  Model Deployments Parameters
*/

@description('Array of model deployments to create.')
param modelDeployments types.ModelDeployment[] = []

/*
  Modules
*/

module aiFoundry '../../bicep/main.bicep' = {
  name: '${deployment().name}-main'
  params: {
    common: common
    aiFoundryName: aiFoundryName
    aiFoundryConfig: aiFoundryConfig
    tags: tags
    aiProjects: aiProjects
    raiPolicies: raiPolicies
    modelDeployments: modelDeployments
    shouldCreatePrivateEndpoint: false
    privateEndpointSubnetId: ''
    virtualNetworkId: ''
  }
}
