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
  Networking Parameters
*/

@description('Whether to enable private endpoints for the storage account.')
param shouldEnablePrivateEndpoint bool = false

@description('Subnet resource ID used for storage private endpoints.')
param privateEndpointSubnetId string?

@description('Virtual network resource ID used for private DNS links.')
param virtualNetworkId string?

@description('Whether to enable public network access for the storage account.')
param shouldEnablePublicNetworkAccess bool = true

@description('Whether to create the blob Private DNS zone when a shared zone is not supplied.')
param shouldCreateBlobPrivateDnsZone bool = true

@description('Existing blob Private DNS zone ID to reuse for the storage private endpoint.')
param blobPrivateDnsZoneId string?

/*
  Local Variables
*/

var blobPrivateDnsZoneName = format('privatelink.blob.{0}', environment().suffixes.storage)
var filePrivateDnsZoneName = format('privatelink.file.{0}', environment().suffixes.storage)
var dfsPrivateDnsZoneName = format('privatelink.dfs.{0}', environment().suffixes.storage)

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
    publicNetworkAccess: shouldEnablePublicNetworkAccess ? 'Enabled' : 'Disabled'
    networkAcls: {
      bypass: 'AzureServices'
      defaultAction: shouldEnablePublicNetworkAccess ? 'Allow' : 'Deny'
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
  Private Networking Resources
*/

resource blobPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldEnablePrivateEndpoint && shouldCreateBlobPrivateDnsZone) {
  name: blobPrivateDnsZoneName
  location: 'global'
}

resource blobPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldEnablePrivateEndpoint && shouldCreateBlobPrivateDnsZone) {
  parent: blobPrivateDnsZone
  name: 'vnet-pzl-blob-${common.resourcePrefix}-${common.environment}-${common.instance}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId!
    }
    registrationEnabled: false
  }
}

resource filePrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldEnablePrivateEndpoint) {
  name: filePrivateDnsZoneName
  location: 'global'
}

resource filePrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldEnablePrivateEndpoint) {
  parent: filePrivateDnsZone
  name: 'vnet-pzl-file-${common.resourcePrefix}-${common.environment}-${common.instance}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId!
    }
    registrationEnabled: false
  }
}

resource dfsPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldEnablePrivateEndpoint) {
  name: dfsPrivateDnsZoneName
  location: 'global'
}

resource dfsPrivateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldEnablePrivateEndpoint) {
  parent: dfsPrivateDnsZone
  name: 'vnet-pzl-dfs-${common.resourcePrefix}-${common.environment}-${common.instance}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId!
    }
    registrationEnabled: false
  }
}

resource storageBlobPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (shouldEnablePrivateEndpoint) {
  name: 'pe-blob-${storageAccountName}'
  location: common.location
  properties: {
    subnet: {
      id: privateEndpointSubnetId!
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-blob-privatelink'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'blob'
          ]
        }
      }
    ]
  }
}

resource storageFilePrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (shouldEnablePrivateEndpoint) {
  name: 'pe-file-${storageAccountName}'
  location: common.location
  dependsOn: [storageBlobPrivateEndpoint]
  properties: {
    subnet: {
      id: privateEndpointSubnetId!
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-file-privatelink'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }
}

resource storageDfsPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-05-01' = if (shouldEnablePrivateEndpoint) {
  name: 'pe-dfs-${storageAccountName}'
  location: common.location
  dependsOn: [storageFilePrivateEndpoint]
  properties: {
    subnet: {
      id: privateEndpointSubnetId!
    }
    privateLinkServiceConnections: [
      {
        name: 'storage-dfs-privatelink'
        properties: {
          privateLinkServiceId: storageAccount.id
          groupIds: [
            'dfs'
          ]
        }
      }
    ]
  }
}

resource storageBlobPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (shouldEnablePrivateEndpoint && (shouldCreateBlobPrivateDnsZone || blobPrivateDnsZoneId != null)) {
  parent: storageBlobPrivateEndpoint
  name: 'blob-private-dns'
  dependsOn: [
    blobPrivateDnsZoneLink
  ]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'blob-zone'
        properties: {
          privateDnsZoneId: shouldCreateBlobPrivateDnsZone ? blobPrivateDnsZone.id : blobPrivateDnsZoneId!
        }
      }
    ]
  }
}

resource storageFilePrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (shouldEnablePrivateEndpoint) {
  parent: storageFilePrivateEndpoint
  name: 'file-private-dns'
  dependsOn: [
    filePrivateDnsZoneLink
  ]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'file-zone'
        properties: {
          privateDnsZoneId: filePrivateDnsZone.id
        }
      }
    ]
  }
}

resource storageDfsPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2023-05-01' = if (shouldEnablePrivateEndpoint) {
  parent: storageDfsPrivateEndpoint
  name: 'dfs-private-dns'
  dependsOn: [
    dfsPrivateDnsZoneLink
  ]
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'dfs-zone'
        properties: {
          privateDnsZoneId: dfsPrivateDnsZone.id
        }
      }
    ]
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

@description('The blob private endpoint ID when created.')
output storageBlobPrivateEndpointId string? = shouldEnablePrivateEndpoint ? storageBlobPrivateEndpoint.id : null

@description('The blob private endpoint IP address when created.')
output storageBlobPrivateEndpointIp string? = shouldEnablePrivateEndpoint
  ? storageBlobPrivateEndpoint!.properties.customDnsConfigs[0].ipAddresses[0]
  : null

@description('The blob private DNS zone ID when available.')
output blobPrivateDnsZoneId string? = shouldEnablePrivateEndpoint
  ? (shouldCreateBlobPrivateDnsZone ? blobPrivateDnsZone.id : blobPrivateDnsZoneId)
  : null

@description('The blob private DNS zone name when managed by this component.')
output blobPrivateDnsZoneName string? = shouldEnablePrivateEndpoint && shouldCreateBlobPrivateDnsZone
  ? blobPrivateDnsZone.name
  : null
