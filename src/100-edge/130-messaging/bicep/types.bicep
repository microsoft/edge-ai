metadata name = 'Component Types for Azure IoT Operations Messaging'
metadata description = 'Provides component-specific type definitions and defaults for messaging components.'

import * as core from './types.core.bicep'

/*
  Type Definitions
*/

@export()
@description('Event Hub configuration.')
type EventHub = {
  @description('The namespace name of the Event Hub.')
  namespaceName: string

  @description('The name of the Event Hub.')
  eventHubName: string
}

@export()
@description('Event Grid configuration.')
type EventGrid = {
  @description('The name of the Event Grid.')
  name: string

  @description('The topic name of the Event Grid.')
  topicName: string

  @description('The endpoint of the Event Grid.')
  endpoint: string
}
