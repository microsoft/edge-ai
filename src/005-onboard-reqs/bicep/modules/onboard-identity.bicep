import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

extension microsoftGraphV1

@description('The common component configuration.')
param common core.Common

@description('The identity type to use for onboarding the cluster to Azure Arc.')
param identityType types.OnboardIdentityType

/*
  Local Variables
*/

var enableUami = toLower(identityType) == 'id'
var enableSp = toLower(identityType) == 'sp'
var servicePrincipalAppName = 'sp-${common.resourcePrefix}-${common.?environment}-arc-aio-${common.?instance ?? '001'}'

/*
  Resources
*/

resource userAssignedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2024-11-30' = if (enableUami) {
  name: 'id-${common.resourcePrefix}-${common.?environment}-arc-aio-${common.?instance ?? '001'}'
  location: common.location
}

resource arcOnboardingRoleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('arc-onboarding', resourceGroup().id)
  properties: {
    principalId: enableUami ? userAssignedIdentity.properties.principalId : arcOnboardingClientSp.id
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', '34e09817-6cbe-4d01-b1a2-e0eac5743d41') // Kubernetes Cluster - Azure Arc Onboarding role
    principalType: 'ServicePrincipal'
  }
}

resource arcOnboardingApp 'Microsoft.Graph/applications@v1.0' = if (enableSp) {
  uniqueName: servicePrincipalAppName
  displayName: servicePrincipalAppName
}

// Note: generating SP client (addPassword) secret is not supported with Bicep MS Graph Types - and likely will never be.
// See [GH issue](https://github.com/microsoftgraph/msgraph-bicep-types/issues/38)
// In deployments, the secret will need to be generated with CLI or other means, and passed as a parameter to the next module, so we are not outputing it.
resource arcOnboardingClientSp 'Microsoft.Graph/servicePrincipals@v1.0' = if (enableSp)  {
  appId: arcOnboardingApp.appId
}

/*
  Outputs
*/

@description('The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output userManagedIdentityId string = enableUami ? userAssignedIdentity.id : ''

@description('The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output userManagedIdentityName string = enableUami ? userAssignedIdentity.name : ''

@description('The User Assigned Managed Identity with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output userAssignedIdentity object = enableUami ? userAssignedIdentity : {}

@description('The Service Principal App (Client) ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output servicePrincipalClientId string = enableSp ? arcOnboardingClientSp.appId : ''
