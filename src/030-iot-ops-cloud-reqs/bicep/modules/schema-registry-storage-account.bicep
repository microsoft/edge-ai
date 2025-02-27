import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

@description('The common component configuration.')
param common core.Common

@description('The name for the new Storage Account.')
param storageAccountName string

@description('The settings for the new Storage Account.')
param storageAccountSettings types.StorageAccountSettings

@description('The name for the new Blob Container for schemas.')
param schemaContainerName string

resource schemaRegistryStore 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  kind: 'StorageV2'
  location: common.location
  sku: {
    name: '${storageAccountSettings.tier}_${storageAccountSettings.replicationType}'
  }
  properties: {
    allowBlobPublicAccess: false
    allowSharedKeyAccess: false
    isHnsEnabled: true
    isLocalUserEnabled: true
    publicNetworkAccess: 'Disabled'
    minimumTlsVersion: 'TLS1_2'
    supportsHttpsTrafficOnly: true
  }

  resource schemaBlobServices 'blobServices' = {
    name: 'default'

    resource schemaContainer 'containers' = {
      name: schemaContainerName
    }
  }
}

output storageAccountName string = schemaRegistryStore.name
output storageAccountId string = schemaRegistryStore.id
output schemaContainerName string = schemaRegistryStore::schemaBlobServices::schemaContainer.name
output schemaContainerUrl string = '${schemaRegistryStore.properties.primaryEndpoints.blob}/${schemaContainerName}'
