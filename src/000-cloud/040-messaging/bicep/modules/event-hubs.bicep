metadata name = 'Event Hubs'
metadata description = 'Deploys Azure Event Hubs Namespace with Event Hubs, partitions, and consumer groups.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

/*
  Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The Event Hubs configuration.')
param eventHubConfig types.EventHubConfig = {
  sku: 'Standard'
  capacity: 1
  eventHubs: [
    {
      name: 'evh-${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
      messageRetentionInDays: 1
      partitionCount: 1
    }
  ]
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

resource eventHubNamespace 'Microsoft.EventHub/namespaces@2024-05-01-preview' = {
  name: 'evhns-${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
  location: common.location
  sku: {
    name: eventHubConfig.sku
    tier: eventHubConfig.sku
    capacity: eventHubConfig.capacity
  }
  properties: {
    minimumTlsVersion: '1.2'
  }

  tags: union(defaultTags, tags)
}

resource eventHubs 'Microsoft.EventHub/namespaces/eventhubs@2024-05-01-preview' = [
  for hub in eventHubConfig.eventHubs: {
    name: hub.name
    parent: eventHubNamespace
    properties: {
      messageRetentionInDays: hub.messageRetentionInDays
      partitionCount: hub.partitionCount
    }
  }
]

resource dataSenderRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(eventHubNamespace.id, 'Azure Event Hubs Data Sender')
  scope: eventHubNamespace
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '2b629674-e913-4c01-ae53-ef4638d8f975'
    )
    principalId: aioIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The name of the Event Hubs Namespace.')
output namespaceName string = eventHubNamespace.name

@description('The ID of the Event Hubs Namespace.')
output namespaceId string = eventHubNamespace.id

@description('The list of Event Hub names created in the namespace.')
output eventHubNames array = [for hub in eventHubConfig.eventHubs: hub.name]
