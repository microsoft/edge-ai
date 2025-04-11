metadata name = 'Arc Onboarding Role Assignment Module'
metadata description = 'Assigns the required Kubernetes Cluster - Azure Arc Onboarding role to a managed identity or service principal.'

import * as core from '../types.core.bicep'

@description('The Principal ID for the identity that will be assigned the Arc Onboarding role.')
param arcOnboardingPrincipalId string

/*
  Resources
*/

resource arcOnboardingRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, arcOnboardingPrincipalId, '34e09817-6cbe-4d01-b1a2-e0eac5743d41')
  properties: {
    principalId: arcOnboardingPrincipalId
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '34e09817-6cbe-4d01-b1a2-e0eac5743d41'
    ) // Kubernetes Cluster - Azure Arc Onboarding role
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('The ID of the role assignment for Kubernetes Cluster - Azure Arc Onboarding.')
output roleAssignmentId string = arcOnboardingRoleAssignment.id
