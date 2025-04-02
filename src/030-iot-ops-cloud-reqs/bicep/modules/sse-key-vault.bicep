metadata name = 'Secret Store Extension Key Vault Module'
metadata description = 'Creates an Azure Key Vault for use with the Secret Sync Extension to securely store and synchronize secrets.'

import * as core from '../types.core.bicep'

@description('The common component configuration.')
param common core.Common

@description('The name of the Key Vault.')
param keyVaultName string

resource sseKeyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: common.location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      name: 'standard'
      family: 'A'
    }
    enableRbacAuthorization: true
  }
}

output sseKeyVaultName string = sseKeyVault.name
output sseKeyVaultId string = sseKeyVault.id
