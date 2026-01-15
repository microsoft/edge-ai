metadata name = 'K8 Bridge Role Assignment'
metadata description = 'Assigns Azure Kubernetes Service Arc Contributor Role to K8 Bridge principal for OPC asset discovery.'

/*
  Parameters
*/

@description('The ID (resource ID) of the custom location.')
param customLocationId string

@description('The principal ID of the K8 Bridge for Azure IoT Operations. Required when this module is used.')
param k8sBridgePrincipalId string

/*
  Resources
*/

resource k8BridgeRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(customLocationId, 'Azure Kubernetes Service Arc Contributor Role', k8sBridgePrincipalId)
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '34e09817-6cbe-4d01-b1a2-e0eac5743d41'
    ) // Azure Kubernetes Service Arc Contributor Role
    principalId: k8sBridgePrincipalId
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The ID of the role assignment.')
output roleAssignmentId string = k8BridgeRoleAssignment.id

@description('The principal ID used for the role assignment.')
output principalId string = k8sBridgePrincipalId
