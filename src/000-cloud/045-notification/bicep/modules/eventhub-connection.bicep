metadata name = 'Event Hub API Connection'
metadata description = 'API connection used by Logic Apps to subscribe to Event Hub via managed identity auth.'

import * as core from '../types.core.bicep'

@description('Common settings.')
param common core.Common

@description('Additional tags applied to the connection.')
param tags object = {}

@description('Event Hub namespace name (used to derive the sb:// endpoint).')
param eventhubNamespaceName string

@description('Resource group location where the connection is deployed.')
param location string

var connectionName = 'apicon-evhub-${common.resourcePrefix}-${common.environment}-${common.instance}'

// Actual managed API reference — Bicep pattern: fetch via subscriptionResourceId
// because managedApis live under Microsoft.Web/locations/{location}/managedApis
var eventhubManagedApiId = subscriptionResourceId(
  'Microsoft.Web/locations/managedApis',
  location,
  'eventhubs'
)

resource eventhubConnection 'Microsoft.Web/connections@2016-06-01' = {
  name: connectionName
  location: location
  tags: tags
  properties: {
    api: {
      id: eventhubManagedApiId
    }
    displayName: 'Event Hub (Managed Identity)'
    // BCP089 false positive: ApiConnectionDefinitionProperties type cache omits
    // parameterValueSet, but the ARM API accepts it and it is required to select
    // the managedIdentityAuth parameter set instead of the default shared-access-key set.
    #disable-next-line BCP089
    parameterValueSet: {
      name: 'managedIdentityAuth'
      values: {
        namespaceEndpoint: {
          value: 'sb://${eventhubNamespaceName}.servicebus.windows.net/'
        }
      }
    }
  }
}

@description('Connection resource ID, passed into Logic App parameters.')
output connectionId string = eventhubConnection.id

@description('Connection resource name.')
output connectionName string = eventhubConnection.name

@description('Managed API ID for the eventhubs connector, passed into Logic App parameters.')
output managedApiId string = eventhubManagedApiId
