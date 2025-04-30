metadata name = 'Arc Role Assignment Module'
metadata description = 'Assigns required Azure Arc roles to the deployment identity for cluster access.'

/*
  Parameters
*/

@description('The principal ID of the deployment identity that will be assigned the role.')
param deployIdentityPrincipalId string

@description('The name of the Arc connected cluster.')
param arcConnectedClusterName string

/*
  Resources
*/

resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2021-03-01' existing = {
  name: arcConnectedClusterName
}

@description('Assigns "Azure Arc Kubernetes Viewer" role to the deployment identity.')
resource arcViewerRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, deployIdentityPrincipalId, '63f0a09d-1495-4db4-a681-037d84835eb4')
  scope: arcConnectedCluster
  properties: {
    // Azure Arc Kubernetes Viewer role
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '63f0a09d-1495-4db4-a681-037d84835eb4'
    )
    principalId: deployIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

@description('Assigns "Azure Arc Enabled Kubernetes Cluster User Role" to the deployment identity.')
resource arcClusterUserRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, deployIdentityPrincipalId, '00493d72-78f6-4148-b6c5-d3ce8e4799dd')
  scope: arcConnectedCluster
  properties: {
    // Azure Arc Enabled Kubernetes Cluster User Role
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '00493d72-78f6-4148-b6c5-d3ce8e4799dd'
    )
    principalId: deployIdentityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The ID of the Azure Arc Kubernetes Viewer role assignment.')
output arcViewerRoleId string = arcViewerRole.id

@description('The ID of the Azure Arc Enabled Kubernetes Cluster User role assignment.')
output arcClusterUserRoleId string = arcClusterUserRole.id
