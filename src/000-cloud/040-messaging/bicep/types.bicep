/*
  Event Hub Types
*/

@export()
@description('The configuration for Event Hubs Namespace.')
type EventHubConfig = {
  @description('The SKU of the Event Hubs Namespace.')
  sku: 'Basic' | 'Standard' | 'Premium'

  @description('The capacity of the Event Hubs Namespace.')
  capacity: int

  @description('The list of Event Hubs to create in the namespace.')
  eventHubs: {
    @description('The name of the Event Hub.')
    name: string

    @description('The message retention period in days.')
    messageRetentionInDays: int

    @description('The number of partitions for the Event Hub.')
    partitionCount: int
  }[]
}

/*
  Event Grid Types
*/

@export()
@description('The configuration for Event Grid Domain.')
type EventGridConfig = {
  @description('Event Grid Namespace SKU capacity. Values between 1 and 40 are supported.')
  @minValue(1)
  @maxValue(40)
  capacity: int

  @description('Specifies the maximum number of client sessions per authentication name. Valid values are from 3 to 100. This parameter should be greater than the number of dataflows')
  @minValue(3)
  @maxValue(100)
  eventGridMaxClientSessionsPerAuthName: int

  @description('The topic templates for Event Grid namespace topic spaces.')
  topicTemplates: string[]
}
