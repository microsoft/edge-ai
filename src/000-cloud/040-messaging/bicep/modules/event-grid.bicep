metadata name = 'Event Grid'
metadata description = 'Deploys Azure Event Grid Domain with topics and event subscriptions.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

/*
  Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The Event Grid configuration.')
param eventGridConfig types.EventGridConfig = {
  capacity: 1
  eventGridMaxClientSessionsPerAuthName: 8
  topicTemplates: ['default']
}

@description('Additional tags to add to the resources.')
param tags object = {}

@description('The Azure IoT Operations User Assigned Managed Identity name.')
param aioIdentityName string

/*
  Variables
*/

var defaultTags = {
  Environment: common.environment
  Instance: common.instance
}

var aioIdentityPrincipalId = aioIdentity.properties.principalId

/*
  Resources
*/

resource aioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = {
  name: aioIdentityName
}

resource eventGridNamespace 'Microsoft.EventGrid/namespaces@2025-02-15' = {
  name: 'evgns-${common.resourcePrefix}-${common.environment}-aio-${common.instance}'
  location: common.location
  sku: {
    name: 'Standard'
    capacity: eventGridConfig.capacity
  }
  properties: {
    topicSpacesConfiguration: {
      state: 'Enabled'
      maximumClientSessionsPerAuthenticationName: eventGridConfig.eventGridMaxClientSessionsPerAuthName
    }
  }

  tags: union(defaultTags, tags)
}

resource topicSpace 'Microsoft.EventGrid/namespaces/topicSpaces@2025-02-15' = {
  parent: eventGridNamespace
  name: 'evgts-${common.resourcePrefix}-${common.environment}-aio-${common.instance}'
  properties: {
    description: 'Default topic space for ${common.resourcePrefix} ${common.environment} environment'
    topicTemplates: eventGridConfig.topicTemplates
  }
}

resource dataSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(topicSpace.id, 'EventGrid TopicSpaces Publisher')
  scope: topicSpace
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'a12b0b94-b317-4dcd-84a8-502ce99884c6'
    )
    principalId: aioIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The name of the Event Grid Namespace.')
output namespaceName string = eventGridNamespace.name

@description('The ID of the Event Grid Namespace.')
output namespaceId string = eventGridNamespace.id

@description('The ID of the Event Grid Topic Space.')
output topicSpaceId string = topicSpace.id

@description('The name of the Event Grid Topic Space.')
output topicSpaceName string = topicSpace.name

@description('The MQTT endpoint for connecting to Event Grid.')
output mqttEndpoint string = '${eventGridNamespace.name}.${common.location}-1.ts.eventgrid.azure.net:8883'
