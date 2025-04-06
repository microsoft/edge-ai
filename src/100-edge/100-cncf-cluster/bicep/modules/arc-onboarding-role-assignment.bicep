metadata name = 'Arc Onboarding Role Assignment Module'
metadata description = 'Assigns the required Kubernetes Cluster - Azure Arc Onboarding role to a managed identity or service principal.'

import * as core from '../types.core.bicep'

@description('The resource name for the identity used for Arc onboarding.')
param arcOnboardingIdentityName string?

@description('Service Principal Object Id used when assigning roles for Arc onboarding.')
param arcOnboardingSpPrincipalId string?

/*
  Resources
*/

resource arcOnboardingIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' existing = if (!empty(arcOnboardingIdentityName)) {
  name: arcOnboardingIdentityName!
}

var arcOnboardingPrincipalName = arcOnboardingIdentityName ?? arcOnboardingSpPrincipalId ?? fail('Either arcOnboardingIdentityName or arcOnboardingSpPrincipalId is required')
var arcOnboardingPrincipalId = arcOnboardingIdentity.?properties.principalId ?? arcOnboardingSpPrincipalId

resource arcOnboardingRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, arcOnboardingPrincipalName, '34e09817-6cbe-4d01-b1a2-e0eac5743d41')
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
