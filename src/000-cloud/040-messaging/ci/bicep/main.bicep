metadata name = 'Cloud Messaging CI'
metadata description = 'CI deployment for Cloud Messaging resources including Event Hubs, Service Bus, and Event Grid.'

import * as core from '../../bicep/types.core.bicep'
import * as types from '../../bicep/types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Existing Resources
*/

resource existingAioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' existing = {
  name: 'id-${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
}

/*
  Modules
*/

module messagingModule '../../bicep/main.bicep' = {
  name: '${deployment().name}-ci'
  params: {
    common: common
    aioIdentityName: existingAioIdentity.name
  }
}

/*
  Outputs
*/

@description('The Event Hubs namespace name from the deployment.')
output eventHubNamespaceName string = messagingModule.outputs.eventHubNamespaceName

@description('The Event Hubs namespace ID from the deployment.')
output eventHubNamespaceId string = messagingModule.outputs.eventHubNamespaceId

@description('The Event Hubs names created in the namespace.')
output eventHubNames array = messagingModule.outputs.eventHubNames

@description('The MQTT endpoint for connecting to Event Grid.')
output eventGridMqttEndpoint string = messagingModule.outputs.eventGridMqttEndpoint
