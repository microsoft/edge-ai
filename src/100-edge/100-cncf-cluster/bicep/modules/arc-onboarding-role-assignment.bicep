metadata name = 'Arc Onboarding Role Assignment Module'
metadata description = 'Assigns the required Kubernetes Cluster - Azure Arc Onboarding role to a managed identity or service principal.'

/*
  Identity Parameters
*/

@description('The Principal IDs for the identities that will be assigned the Arc Onboarding role.')
param arcOnboardingPrincipalIds string[]

/*
  Resources
*/

resource arcOnboardingRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for principalId in arcOnboardingPrincipalIds: {
    name: guid(resourceGroup().id, principalId, '34e09817-6cbe-4d01-b1a2-e0eac5743d41')
    properties: {
      principalId: principalId
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        '34e09817-6cbe-4d01-b1a2-e0eac5743d41'
      ) // Kubernetes Cluster - Azure Arc Onboarding role
      principalType: 'ServicePrincipal'
    }
  }
]

/*
  Outputs
*/

@description('The IDs of the role assignments for Kubernetes Cluster - Azure Arc Onboarding.')
output roleAssignmentIds string[] = [for (principalId, index) in arcOnboardingPrincipalIds: arcOnboardingRoleAssignment[index].id]
