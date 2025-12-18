metadata name = 'Secret Store Extension Key Vault Module'
metadata description = 'Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Key Vault Parameters
*/

@description('The name of the Key Vault.')
param keyVaultName string

/*
  Role Assignment Parameters
*/

@description('Whether or not to create a role assignment for an admin user.')
param shouldAssignAdminUserRole bool

@description('The Object ID for an admin user that will be granted the "Key Vault Secrets Officer" role.')
param adminUserObjectId string

/*
  Networking Parameters
*/

@description('Whether to create a private endpoint for the Key Vault.')
param shouldCreatePrivateEndpoint bool = false

@description('Subnet resource ID for the Key Vault private endpoint.')
param privateEndpointSubnetId string?

@description('Virtual network resource ID for the Key Vault private DNS link.')
param virtualNetworkId string?

@description('Whether public network access remains enabled on the Key Vault.')
param shouldEnablePublicNetworkAccess bool = true

/*
  Resources
*/

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: common.location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableRbacAuthorization: true
    publicNetworkAccess: shouldEnablePublicNetworkAccess ? 'Enabled' : 'Disabled'
  }
}

@description('Assigns "Key Vault Secrets Officer" to the admin user Object ID.')
resource keyVaultSecretsOfficerCurrentUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (shouldAssignAdminUserRole) {
  name: guid(resourceGroup().id, adminUserObjectId, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
  scope: keyVault
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-officer
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
    )
    principalId: adminUserObjectId
    principalType: 'User'
  }
}

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2023-09-01' = if (shouldCreatePrivateEndpoint) {
  name: 'pe-${keyVaultName}'
  location: common.location
  properties: {
    subnet: {
      id: privateEndpointSubnetId!
    }
    privateLinkServiceConnections: [
      {
        name: 'kv-privatelink'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = if (shouldCreatePrivateEndpoint) {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
}

resource keyVaultDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = if (shouldCreatePrivateEndpoint) {
  parent: keyVaultPrivateDnsZone
  name: 'vnet-link-${common.resourcePrefix}-${common.environment}-${common.instance}'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId!
    }
    registrationEnabled: false
  }
}

resource keyVaultPrivateDnsRecord 'Microsoft.Network/privateDnsZones/A@2020-06-01' = if (shouldCreatePrivateEndpoint) {
  parent: keyVaultPrivateDnsZone
  name: keyVaultName
  properties: {
    ttl: 300
    aRecords: [
      {
        ipv4Address: keyVaultPrivateEndpoint!.properties.customDnsConfigs[0].ipAddresses[0]
      }
    ]
  }
}

/*
  Outputs
*/

@description('The name of the Secret Store Extension Key Vault.')
output keyVaultName string = keyVault.name

@description('The resource ID of the Secret Store Extension Key Vault.')
output keyVaultId string = keyVault.id

@description('The Key Vault private endpoint ID when created.')
output keyVaultPrivateEndpointId string? = shouldCreatePrivateEndpoint ? keyVaultPrivateEndpoint.id : null

@description('The Key Vault private endpoint name when created.')
output keyVaultPrivateEndpointName string? = shouldCreatePrivateEndpoint ? keyVaultPrivateEndpoint.name : null

@description('The Key Vault private endpoint IP address when created.')
output keyVaultPrivateEndpointIp string? = shouldCreatePrivateEndpoint
  ? keyVaultPrivateEndpoint!.properties.customDnsConfigs[0].ipAddresses[0]
  : null

@description('The Key Vault private DNS zone ID when created.')
output keyVaultPrivateDnsZoneId string? = shouldCreatePrivateEndpoint ? keyVaultPrivateDnsZone.id : null

@description('The Key Vault private DNS zone name when created.')
output keyVaultPrivateDnsZoneName string? = shouldCreatePrivateEndpoint ? keyVaultPrivateDnsZone.name : null
