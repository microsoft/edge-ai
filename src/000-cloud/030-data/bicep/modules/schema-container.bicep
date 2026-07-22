metadata name = 'Schema Container Module'
metadata description = 'Creates the blob container used by Azure Device Registry schemas.'

@description('The name of the Storage Account.')
param storageAccountName string

@description('The name of the schema blob container.')
param schemaContainerName string

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2024-01-01' existing = {
  parent: storageAccount
  name: 'default'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2024-01-01' = {
  parent: blobService
  name: schemaContainerName
  properties: {
    publicAccess: 'None'
  }
}

@description('The resource ID of the schema blob container.')
output schemaContainerId string = container.id
