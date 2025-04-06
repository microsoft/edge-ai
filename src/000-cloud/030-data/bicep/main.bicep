metadata name = 'Data Component'
metadata description = 'Creates storage resources including Azure Storage Account and Schema Registry for data in the Edge AI solution.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Storage Account Parameters
*/

@description('Whether to create the Storage Account.')
param shouldCreateStorageAccount bool = true

@description('The name for the Resource Group for the Storage Account.')
param storageAccountResourceGroupName string = shouldCreateStorageAccount
  ? resourceGroup().name
  : fail('storageAccountResourceGroupName required when shouldCreateStorageAccount is false')

@description('The name for the Storage Account used by the Schema Registry.')
param storageAccountName string = shouldCreateStorageAccount
  ? 'st${uniqueString(resourceGroup().id)}'
  : fail('storageAccountName required when shouldCreateStorageAccount is false')

@description('The settings for the new Storage Account.')
param storageAccountSettings types.StorageAccountSettings = types.storageAccountSettingsDefaults

/*
  Schema Registry Parameters
*/

@description('Whether to create the ADR Schema Registry.')
param shouldCreateSchemaRegistry bool = true

@description('Whether to create the Blob Container for schemas.')
param shouldCreateSchemaContainer bool = true

@description('The name for the Blob Container for schemas.')
param schemaContainerName string = 'schemas'

@description('The name for the ADR Schema Registry.')
param schemaRegistryName string = 'sr-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('The ADLS Gen2 namespace for the ADR Schema Registry.')
param schemaRegistryNamespace string = 'srns-${common.resourcePrefix}-${common.environment}-${common.instance}'

/*
  Modules
*/

module storageAccount 'modules/storage-account.bicep' = if (shouldCreateStorageAccount) {
  name: '${deployment().name}-storageAccount'
  scope: resourceGroup(storageAccountResourceGroupName)
  params: {
    common: common
    shouldCreateSchemaContainer: shouldCreateSchemaContainer
    schemaContainerName: schemaContainerName
    storageAccountSettings: storageAccountSettings
    storageAccountName: storageAccountName
  }
}

module schemaRegistry 'modules/schema-registry.bicep' = if (shouldCreateSchemaRegistry) {
  name: '${deployment().name}-schemaRegistry'
  dependsOn: [storageAccount]
  params: {
    common: common
    schemaRegistryName: schemaRegistryName
    schemaRegistryNamespace: schemaRegistryNamespace
    storageAccountContainerUrl: 'https://${storageAccountName}.blob.${environment().suffixes.storage}/${schemaContainerName}'
  }
}

module schemaRegistryRoleAssignment 'modules/schema-registry-role-assignment.bicep' = if (shouldCreateSchemaRegistry) {
  name: '${deployment().name}-schemaRegistryRoleAssignment'
  scope: resourceGroup(storageAccountResourceGroupName)
  dependsOn: [storageAccount]
  params: {
    storageAccountName: storageAccountName
    schemaBlobContainerName: schemaContainerName
    schemaRegistryPrincipalId: schemaRegistry.outputs.schemaRegistryPrincipalId
  }
}

/*
  Outputs
*/

@description('The ADR Schema Registry Name.')
output schemaRegistryName string = schemaRegistry.?outputs.schemaRegistryName ?? ''

@description('The ADR Schema Registry ID.')
output schemaRegistryId string = schemaRegistry.?outputs.schemaRegistryId ?? ''

@description('The Storage Account Name.')
output storageAccountName string = storageAccount.?outputs.storageAccountName ?? storageAccountName

@description('The Storage Account ID.')
output storageAccountId string = storageAccount.?outputs.storageAccountId ?? ''

@description('The Schema Container Name.')
output schemaContainerName string = storageAccount.?outputs.schemaContainerName ?? schemaContainerName
