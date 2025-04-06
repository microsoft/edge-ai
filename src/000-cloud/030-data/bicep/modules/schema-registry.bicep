metadata name = 'Schema Registry Module'
metadata description = 'Creates an Azure Device Registry (ADR) Schema Registry for storing and managing device schemas.'

import * as core from '../types.core.bicep'

/*
  Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The URL for the Blob Container for the schemas.')
param storageAccountContainerUrl string

@description('The name for the ADR Schema Registry.')
param schemaRegistryName string

@description('The ADLS Gen2 namespace for the ADR Schema Registry.')
param schemaRegistryNamespace string

/*
  Resources
*/

resource schemaRegistry 'Microsoft.DeviceRegistry/schemaRegistries@2024-09-01-preview' = {
  name: schemaRegistryName
  location: common.location
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    namespace: schemaRegistryNamespace
    storageAccountContainerUrl: storageAccountContainerUrl
  }
}

/*
  Outputs
*/

@description('The name of the schema registry.')
output schemaRegistryName string = schemaRegistry.name

@description('The resource ID of the schema registry.')
output schemaRegistryId string = schemaRegistry.id

@description('The principal ID of the schema registry managed identity.')
output schemaRegistryPrincipalId string = schemaRegistry.identity.principalId
