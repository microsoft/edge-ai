import * as core from '../types.core.bicep'

@description('The common component configuration.')
param common core.Common

@description('The URL for the Blob Container for the schemas.')
param storageAccountContainerUrl string

@description('The name for the ADR Schema Registry.')
param schemaRegistryName string

@description('The ADLS Gen2 namespace for the ADR Schema Registry.')
param schemaRegistryNamespace string

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

output schemaRegistryName string = schemaRegistry.name
output schemaRegistryId string = schemaRegistry.id
output schemaRegistryPrincipalId string = schemaRegistry.identity.principalId
