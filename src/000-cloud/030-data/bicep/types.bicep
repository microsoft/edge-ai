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
