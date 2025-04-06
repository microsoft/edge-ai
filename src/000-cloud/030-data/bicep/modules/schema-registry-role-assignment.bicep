metadata name = 'Schema Registry Role Assignments Module'
metadata description = 'Creates role assignments for the Schema Registry to access the storage account.'

/*
  Parameters
*/

@description('The name of the storage account.')
param storageAccountName string

@description('The name of the blob container for schemas.')
param schemaBlobContainerName string

@description('The principal ID of the schema registry.')
param schemaRegistryPrincipalId string

/*
  Variables
*/

@description('Storage Blob Data Contributor role definition ID')
var storageBlobDataContributorRoleId = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'

/*
  Resources
*/

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName

  resource blobService 'blobServices' existing = {
    name: 'default'

    resource container 'containers' existing = {
      name: schemaBlobContainerName
    }
  }
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(schemaBlobContainerName, schemaRegistryPrincipalId, storageBlobDataContributorRoleId)
  scope: storageAccount::blobService::container
  properties: {
    principalId: schemaRegistryPrincipalId
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-blob-data-contributor
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageBlobDataContributorRoleId
    ) // Storage Blob Data Contributor
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The resource ID of the role assignment.')
output roleAssignmentId string = roleAssignment.id
