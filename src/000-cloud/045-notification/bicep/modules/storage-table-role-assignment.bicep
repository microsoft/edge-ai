metadata name = 'Storage Table Data Contributor Role Assignment Module'
metadata description = 'Grants a Logic App identity the Storage Table Data Contributor role on the storage account.'

/*
  Parameters
*/

@description('The name of the storage account to scope the role assignment to.')
param storageAccountName string

@description('The principal ID granted the Storage Table Data Contributor role.')
param principalId string

/*
  Variables
*/

@description('Storage Table Data Contributor role definition ID.')
var storageTableDataContributorRoleId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'

/*
  Resources
*/

resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' existing = {
  name: storageAccountName
}

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storageAccount.id, principalId, storageTableDataContributorRoleId)
  scope: storageAccount
  properties: {
    principalId: principalId
    // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/storage#storage-table-data-contributor
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      storageTableDataContributorRoleId
    )
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The resource ID of the role assignment.')
output roleAssignmentId string = roleAssignment.id
