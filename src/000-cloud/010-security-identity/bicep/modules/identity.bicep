metadata name = 'User Assigned Managed Identity Module'
metadata description = 'Creates user-assigned managed identities for Secret Store Extension and Azure IoT Operations components.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

extension microsoftGraphV1

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Identity Parameters
*/

@description('The identity type to use for onboarding the cluster to Azure Arc.')
param identityType types.OnboardIdentityType

/*
  Local Variables
*/

var enableUami = toLower(identityType) == 'id'
var enableSp = toLower(identityType) == 'sp'
var servicePrincipalAppName = 'sp-${common.resourcePrefix}-arc-${common.environment}-${common.instance}'

/*
  Resources
*/

resource arcOnboardingApp 'Microsoft.Graph/applications@v1.0' = if (enableSp) {
  uniqueName: servicePrincipalAppName
  displayName: servicePrincipalAppName
}

// Note: generating SP client (addPassword) secret is not supported with Bicep MS Graph Types - and likely will never be.
// See [GH issue](https://github.com/microsoftgraph/msgraph-bicep-types/issues/38)
// In deployments, the secret will need to be generated with CLI or other means, and passed as a parameter to the next module, so we are not outputing it.
resource arcOnboardingClientSp 'Microsoft.Graph/servicePrincipals@v1.0' = if (enableSp) {
  appId: arcOnboardingApp.appId
}

resource arcOnboardingIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = if (enableUami) {
  name: 'id-${common.resourcePrefix}-arc-${common.environment}-${common.instance}'
  location: common.location
}

resource sseIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${common.resourcePrefix}-sse-${common.environment}-${common.instance}'
  location: common.location
}

resource aioIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${common.resourcePrefix}-aio-${common.environment}-${common.instance}'
  location: common.location
}

/*
  Outputs
*/

@description('The Secret Store Extension User Assigned Managed Identity name.')
output sseIdentityName string = sseIdentity.name

@description('The Secret Store Extension User Assigned Managed Identity ID.')
output sseIdentityId string = sseIdentity.id

@description('The Secret Store Extension User Assigned Managed Identity Principal ID.')
output sseIdentityPrincipalId string = sseIdentity.properties.principalId

@description('The Azure IoT Operations User Assigned Managed Identity name.')
output aioIdentityName string = aioIdentity.name

@description('The Azure IoT Operations User Assigned Managed Identity ID.')
output aioIdentityId string = aioIdentity.id

@description('The Azure IoT Operations User Assigned Managed Identity Principal ID.')
output aioIdentityPrincipalId string = aioIdentity.properties.principalId

@description('The User Assigned Managed Identity ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingIdentityId string? = enableUami ? arcOnboardingIdentity.id : null

@description('The User Assigned Managed Identity name with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output arcOnboardingIdentityName string? = enableUami ? arcOnboardingIdentity.name : null

@description('The Service Principal App (Client) ID with "Kubernetes Cluster - Azure Arc Onboarding" permissions.')
output servicePrincipalClientId string? = enableSp ? arcOnboardingClientSp.appId : null
