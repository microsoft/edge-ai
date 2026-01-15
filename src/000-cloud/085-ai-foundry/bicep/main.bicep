metadata name = 'Microsoft Foundry'
metadata description = 'Deploys Microsoft Foundry account with optional projects, model deployments, RAI policies, and private endpoint support.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

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

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

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
  Private Endpoint Parameters
*/

@description('Whether to create a private endpoint for the Microsoft Foundry account.')
param shouldCreatePrivateEndpoint bool = false

@description('Subnet ID for the private endpoint.')
param privateEndpointSubnetId string = ''

@description('Virtual network ID for DNS zone links.')
param virtualNetworkId string = ''

/*
  Variables
*/

var accountName = aiFoundryName ?? 'aif-${common.resourcePrefix}-${common.environment}-${common.instance}'

/*
  Resources
*/

resource aiFoundryAccount 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: accountName
  location: common.location
  kind: 'AIServices'
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: aiFoundryConfig.sku
  }
  properties: {
    allowProjectManagement: true
    customSubDomainName: accountName
    publicNetworkAccess: aiFoundryConfig.shouldEnablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    disableLocalAuth: !aiFoundryConfig.shouldEnableLocalAuth
    networkAcls: {
      defaultAction: 'Allow'
    }
  }
  tags: union(tags, {
    environment: common.environment
    component: 'ai-foundry'
  })
}

resource projects 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = [
  for project in aiProjects: {
    parent: aiFoundryAccount
    name: project.name
    location: common.location
    identity: {
      type: 'SystemAssigned'
    }
    properties: {
      displayName: project.displayName
      description: project.description
    }
  }
]

resource raiPolicyResources 'Microsoft.CognitiveServices/accounts/raiPolicies@2024-10-01' = [
  for policy in raiPolicies: {
    parent: aiFoundryAccount
    name: policy.name
    properties: {
      basePolicyName: policy.basePolicyName
      mode: policy.mode
      contentFilters: policy.contentFilters
    }
  }
]

@batchSize(1)
resource deployments 'Microsoft.CognitiveServices/accounts/deployments@2025-06-01' = [
  for deployment in modelDeployments: {
    parent: aiFoundryAccount
    name: deployment.name
    sku: {
      name: deployment.scale.type
      capacity: deployment.scale.capacity
    }
    properties: {
      model: {
        format: deployment.model.format
        name: deployment.model.name
        version: deployment.model.version
      }
      raiPolicyName: deployment.?raiPolicyName ?? null
      versionUpgradeOption: deployment.?versionUpgradeOption ?? 'OnceNewDefaultVersionAvailable'
    }
    dependsOn: raiPolicyResources
  }
]

resource privateDnsZoneCognitiveServices 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldCreatePrivateEndpoint) {
  name: 'privatelink.cognitiveservices.azure.com'
  location: 'global'
  tags: tags
}

resource privateDnsZoneOpenAI 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldCreatePrivateEndpoint) {
  name: 'privatelink.openai.azure.com'
  location: 'global'
  tags: tags
}

resource privateDnsZoneAIServices 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldCreatePrivateEndpoint) {
  name: 'privatelink.services.ai.azure.com'
  location: 'global'
  tags: tags
}

resource dnsLinkCognitiveServices 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldCreatePrivateEndpoint) {
  parent: privateDnsZoneCognitiveServices
  name: 'link-${common.resourcePrefix}-cognitiveservices'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource dnsLinkOpenAI 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldCreatePrivateEndpoint) {
  parent: privateDnsZoneOpenAI
  name: 'link-${common.resourcePrefix}-openai'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource dnsLinkAIServices 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldCreatePrivateEndpoint) {
  parent: privateDnsZoneAIServices
  name: 'link-${common.resourcePrefix}-aiservices'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId
    }
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (shouldCreatePrivateEndpoint) {
  name: 'pe-${accountName}'
  location: common.location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: 'plsc-${accountName}'
        properties: {
          privateLinkServiceId: aiFoundryAccount.id
          groupIds: ['account']
        }
      }
    ]
  }
}

resource privateEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (shouldCreatePrivateEndpoint) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'cognitiveservices'
        properties: {
          privateDnsZoneId: privateDnsZoneCognitiveServices.id
        }
      }
      {
        name: 'openai'
        properties: {
          privateDnsZoneId: privateDnsZoneOpenAI.id
        }
      }
      {
        name: 'aiservices'
        properties: {
          privateDnsZoneId: privateDnsZoneAIServices.id
        }
      }
    ]
  }
}

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
  Outputs
*/

@description('Microsoft Foundry account object with id, name, endpoint, and principalId.')
output aiFoundry object = {
  id: aiFoundryAccount.id
  name: aiFoundryAccount.name
  endpoint: 'https://${accountName}.cognitiveservices.azure.com'
  principalId: aiFoundryAccount.identity.principalId
}

@description('Microsoft Foundry account resource ID.')
output aiFoundryId string = aiFoundryAccount.id

@description('Microsoft Foundry account name.')
output aiFoundryName string = aiFoundryAccount.name

@description('Microsoft Foundry account endpoint.')
output aiFoundryEndpoint string = aiFoundryAccount.properties.endpoint

@description('Microsoft Foundry account system-assigned managed identity principal ID.')
output aiFoundryPrincipalId string = aiFoundryAccount.identity.principalId

@description('Array of created Microsoft Foundry projects.')
output projectsArray array = [
  for (project, i) in aiProjects: {
    name: projects[i].name
    id: projects[i].id
    principalId: projects[i].identity.principalId
  }
]

@description('Array of created RAI policies.')
output raiPoliciesArray array = [
  for (policy, i) in raiPolicies: {
    name: raiPolicyResources[i].name
    id: raiPolicyResources[i].id
  }
]

@description('Array of created model deployments.')
output deploymentsArray array = [
  for (deployment, i) in modelDeployments: {
    name: deployments[i].name
    id: deployments[i].id
  }
]

@description('Private endpoint resource ID.')
output privateEndpointId string = shouldCreatePrivateEndpoint ? privateEndpoint.id : ''
