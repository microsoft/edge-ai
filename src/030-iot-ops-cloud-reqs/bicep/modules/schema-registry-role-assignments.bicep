@description('The name for the Storage Account used by the Schema Registry.')
param storageAccountName string

@description('The name for the Blob Container for the schemas.')
param schemaBlobContainerName string

@description('The Principal ID for the Schema Registry.')
param schemaRegistryPrincipalId string

resource schemaRegistryStore 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccountName

  resource schemaBlobServices 'blobServices' existing = {
    name: 'default'

    resource schemaContainer 'containers' existing = {
      name: schemaBlobContainerName
    }
  }
}

@description('Assigns "Storage Blob Data Contributor" to the ADR Schema Registry.')
resource registryStorageContributor 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, schemaRegistryPrincipalId, 'ba92f5b4-2d11-453d-a403-e96b0029c9fe')
  scope: schemaRegistryStore::schemaBlobServices::schemaContainer
  properties: {
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
    )
    principalId: schemaRegistryPrincipalId
    principalType: 'ServicePrincipal'
  }
}
