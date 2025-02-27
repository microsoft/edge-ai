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
