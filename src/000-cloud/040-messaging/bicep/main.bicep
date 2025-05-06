metadata name = 'Cloud Messaging'
metadata description = 'Deploys Azure cloud messaging resources including Event Hubs, Service Bus, and Event Grid for IoT edge solution communication.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('Additional tags to add to the resources.')
param tags object = {}

@description('The User-Assigned Managed Identity for Azure IoT Operations.')
param aioIdentityName string

/*
Variables
*/

var defaultTags = {
  Environment: common.environment
  Instance: common.instance
}

/*
  Event Hubs Parameters
*/

@description('Whether to create Event Hubs resources.')
param shouldCreateEventHub bool = true

@description('The configuration for the Event Hubs Namespace.')
param eventHubConfig types.EventHubConfig?

/*
  Event Grid Parameters
*/

@description('Whether to create Event Grid resources.')
param shouldCreateEventGrid bool = true

@description('The configuration for the Event Grid Domain.')
param eventGridConfig types.EventGridConfig?

/*
  Modules
*/

module eventHub 'modules/event-hubs.bicep' = if (shouldCreateEventHub) {
  name: '${deployment().name}-eventHub'
  params: {
    common: common
    eventHubConfig: eventHubConfig
    aioIdentityName: aioIdentityName
    tags: union(defaultTags, tags)
  }
}

module eventGrid 'modules/event-grid.bicep' = if (shouldCreateEventGrid) {
  name: '${deployment().name}-eventGrid'
  params: {
    common: common
    eventGridConfig: eventGridConfig
    aioIdentityName: aioIdentityName
    tags: union(defaultTags, tags)
  }
}

/*
  Outputs
*/

@description('The Event Hubs Namespace name.')
output eventHubNamespaceName string = shouldCreateEventHub ? eventHub.outputs.namespaceName : ''

@description('The Event Hubs Namespace ID.')
output eventHubNamespaceId string = shouldCreateEventHub ? eventHub.outputs.namespaceId : ''

@description('The list of Event Hub names created in the namespace.')
output eventHubNames array = shouldCreateEventHub ? eventHub.outputs.eventHubNames : []

@description('The Event Grid topic name created.')
output eventGridTopicNames string = shouldCreateEventGrid ? eventGrid.outputs.topicSpaceName : ''

@description('The Event Grid endpoint URL for MQTT connections')
output eventGridMqttEndpoint string = shouldCreateEventGrid ? eventGrid.outputs.mqttEndpoint : ''
