metadata name = 'Data Component Types'
metadata description = 'Type definitions for the Data Component, including Storage Account and Schema Registry settings.'

import * as core from './types.core.bicep'

/*
  Type Definitions
*/

@export()
@description('Settings for the storage account.')
type StorageAccountSettings = {
  @description('The tier of the storage account: Standard or Premium.')
  tier: 'Standard' | 'Premium'

  @description('The replication type of the storage account: LRS, GRS, RAGRS, ZRS, GZRS or RAGZRS.')
  replicationType: 'LRS' | 'GRS' | 'RAGRS' | 'ZRS' | 'GZRS' | 'RAGZRS'
}

/*
  Default Values
*/

@export()
@description('Default settings for the storage account.')
var storageAccountSettingsDefaults = {
  tier: 'Standard'
  replicationType: 'LRS'
}

/*
  Schema Registry Types
*/

@export()
@description('Schema Registry settings.')
type SchemaRegistrySettings = {
  @description('The name of the schema registry.')
  name: string?

  @description('The namespace for the schema registry.')
  namespace: string?

  @description('The name of the container for schemas.')
  containerName: string
}

@export()
var schemaRegistrySettingsDefaults = {
  containerName: 'schemas'
}

/*
  ADR Namespace Types
*/

@export()
@description('ADR Namespace messaging endpoint configuration.')
type AdrNamespaceMessagingEndpoint = {
  @description('The type of the messaging endpoint.')
  endpointType: string

  @description('The address of the messaging endpoint.')
  address: string

  @description('The resource ID of the messaging endpoint (optional).')
  resourceId: string?
}

@export()
@description('Dictionary of messaging endpoints for the ADR namespace.')
type AdrNamespaceMessagingEndpoints = {
  @description('Messaging endpoints mapped by name.')
  *: AdrNamespaceMessagingEndpoint
}

@export()
@description('ADR Namespace settings.')
type AdrNamespaceSettings = {
  @description('The name of the ADR namespace.')
  name: string?

  @description('Dictionary of messaging endpoints for the namespace.')
  messagingEndpoints: AdrNamespaceMessagingEndpoints?

  @description('Whether to enable system-assigned managed identity for the namespace.')
  enableSystemAssignedIdentity: bool?
}

@export()
var adrNamespaceSettingsDefaults = {
  enableSystemAssignedIdentity: true
}
