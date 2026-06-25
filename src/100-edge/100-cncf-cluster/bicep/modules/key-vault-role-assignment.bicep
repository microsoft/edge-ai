metadata name = 'Key Vault Role Assignment Module'
metadata description = 'Assigns appropriate roles to access Key Vault secrets.'

/*
  Identity Parameters
*/

@description('The principal IDs of the Arc identities that need access to the secrets.')
param arcOnboardingPrincipalIds string[]

/*
  Key Vault Parameters
*/

@description('The name of the Key Vault containing the scripts.')
param keyVaultName string

@description('The name for the node script secret in Key Vault.')
param nodeScriptSecretName string

@description('The name for the server script secret in Key Vault.')
param serverScriptSecretName string

/*
  Resources
*/

resource keyVault 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVaultName

  resource serverScriptSecret 'secrets' existing = {
    name: serverScriptSecretName
  }

  resource nodeScriptSecret 'secrets' existing = {
    name: nodeScriptSecretName
  }
}

// Key Vault Secrets Officer role at the vault level
resource keyVaultSecretsOfficerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in arcOnboardingPrincipalIds: {
    name: guid(resourceGroup().id, principalId, 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7')
    scope: keyVault
    properties: {
      // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-officer
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
      )
      principalId: principalId
      principalType: 'ServicePrincipal'
    }
  }
]

// Role assignments for server script secret
resource keyVaultReaderServerSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in arcOnboardingPrincipalIds: {
    name: guid(resourceGroup().id, principalId, serverScriptSecretName, '21090545-7ca7-4776-b22c-e363652d74d2')
    scope: keyVault::serverScriptSecret
    properties: {
      // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-reader
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        '21090545-7ca7-4776-b22c-e363652d74d2'
      )
      principalId: principalId
      principalType: 'ServicePrincipal'
    }
  }
]

resource keyVaultSecretsUserServerSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in arcOnboardingPrincipalIds: {
    name: guid(resourceGroup().id, principalId, serverScriptSecretName, '4633458b-17de-408a-b874-0445c86b69e6')
    scope: keyVault::serverScriptSecret
    properties: {
      // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-user
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        '4633458b-17de-408a-b874-0445c86b69e6'
      )
      principalId: principalId
      principalType: 'ServicePrincipal'
    }
  }
]

// Role assignments for node script secret
resource keyVaultReaderNodeSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in arcOnboardingPrincipalIds: {
    name: guid(resourceGroup().id, principalId, nodeScriptSecretName, '21090545-7ca7-4776-b22c-e363652d74d2')
    scope: keyVault::nodeScriptSecret
    properties: {
      // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-reader
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        '21090545-7ca7-4776-b22c-e363652d74d2'
      )
      principalId: principalId
      principalType: 'ServicePrincipal'
    }
  }
]

resource keyVaultSecretsUserNodeSecret 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in arcOnboardingPrincipalIds: {
    name: guid(resourceGroup().id, principalId, nodeScriptSecretName, '4633458b-17de-408a-b874-0445c86b69e6')
    scope: keyVault::nodeScriptSecret
    properties: {
      // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/security#key-vault-secrets-user
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        '4633458b-17de-408a-b874-0445c86b69e6'
      )
      principalId: principalId
      principalType: 'ServicePrincipal'
    }
  }
]
