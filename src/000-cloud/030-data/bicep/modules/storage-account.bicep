metadata name = 'Storage Account Module'
metadata description = 'Creates an Azure Storage Account and blob container for storing schemas.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

/*
  Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The settings for the storage account.')
param storageAccountSettings types.StorageAccountSettings = types.storageAccountSettingsDefaults

@description('The name of the storage account.')
param storageAccountName string

@description('Whether to create the Blob Container for schemas.')
param shouldCreateSchemaContainer bool

@description('The name of the blob container for schemas.')
param schemaContainerName string

/*
  Resources
*/

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountName
  location: common.location
  sku: {
    name: '${storageAccountSettings.tier}_${storageAccountSettings.replicationType}'
  }
  kind: 'StorageV2'
  properties: {
    accessTier: 'Hot'
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: 'Allow'
    }
  }

  resource blobService 'blobServices' = {
    name: 'default'

    resource container 'containers' = if (shouldCreateSchemaContainer) {
      name: schemaContainerName
      properties: {
        publicAccess: 'None'
      }
    }
  }
}

/*
  Outputs
*/

@description('The name of the storage account.')
output storageAccountName string = storageAccount.name

@description('The resource ID of the storage account.')
output storageAccountId string = storageAccount.id

@description('The primary blob endpoint URL of the storage account.')
output primaryBlobEndpoint string = storageAccount.properties.primaryEndpoints.blob

@description('The name of the schema container.')
output schemaContainerName string = shouldCreateSchemaContainer
  ? storageAccount::blobService::container.name
  : schemaContainerName

@description('The resource ID of the schema container, or null if not created.')
output schemaContainerId string? = shouldCreateSchemaContainer ? storageAccount::blobService::container.id : null
