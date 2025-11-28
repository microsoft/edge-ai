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
  ADR Namespace Parameters
*/

@description('Whether to create the ADR Namespace.')
param shouldCreateAdrNamespace bool = true

@description('The name for the ADR Namespace.')
param adrNamespaceName string = 'adrns-${common.resourcePrefix}-${common.environment}-${common.instance}'

@description('Dictionary of messaging endpoints for the ADR namespace.')
param adrNamespaceMessagingEndpoints types.AdrNamespaceMessagingEndpoints?

@description('Whether to enable system-assigned managed identity for the ADR namespace.')
param adrNamespaceEnableIdentity bool = true

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Resources
*/

resource attribution 'Microsoft.Resources/deployments@2020-06-01' = if (!telemetry_opt_out) {
  name: 'pid-acce1e78-0375-4637-a593-86aa36dcfeac'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

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
    schemaRegistryPrincipalId: schemaRegistry!.outputs.schemaRegistryPrincipalId
  }
}

module adrNamespace 'modules/adr-namespace.bicep' = if (shouldCreateAdrNamespace) {
  name: '${deployment().name}-adrNamespace'
  params: {
    common: common
    adrNamespaceName: adrNamespaceName
    messagingEndpoints: adrNamespaceMessagingEndpoints
    enableSystemAssignedIdentity: adrNamespaceEnableIdentity
  }
}

/*
  Outputs
*/

@description('The ADR Schema Registry Name.')
output schemaRegistryName string = shouldCreateSchemaRegistry ? schemaRegistry!.outputs.schemaRegistryName : ''

@description('The ADR Schema Registry ID.')
output schemaRegistryId string = shouldCreateSchemaRegistry ? schemaRegistry!.outputs.schemaRegistryId : ''

@description('The Storage Account Name.')
output storageAccountName string = shouldCreateSchemaRegistry
  ? storageAccount!.outputs.storageAccountName
  : storageAccountName

@description('The Storage Account ID.')
output storageAccountId string = shouldCreateStorageAccount ? storageAccount!.outputs.storageAccountId : ''

@description('The Schema Container Name.')
output schemaContainerName string = shouldCreateStorageAccount
  ? storageAccount!.outputs.schemaContainerName
  : schemaContainerName

/*
  ADR Namespace Outputs
*/

@description('The ADR Namespace Name.')
output adrNamespaceName string = shouldCreateAdrNamespace ? adrNamespace!.outputs.adrNamespaceName : ''

@description('The ADR Namespace ID.')
output adrNamespaceId string = shouldCreateAdrNamespace ? adrNamespace!.outputs.adrNamespaceId : ''

@description('The complete ADR namespace resource information.')
output adrNamespace object = shouldCreateAdrNamespace ? adrNamespace!.outputs.adrNamespace : {}
