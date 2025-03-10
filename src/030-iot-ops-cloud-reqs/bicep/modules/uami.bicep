import * as core from '../types.core.bicep'

@description('The common component configuration.')
param common core.Common

resource sseUami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${common.resourcePrefix}-sse-uami'
  location: common.location
}

resource aioUami 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'id-${common.resourcePrefix}-${common.environment}-aio-${common.instance}'
  location: common.location
}

output sseUamiName string = sseUami.name
output sseUamiId string = sseUami.id
output sseUamiPrincipalId string = sseUami.properties.principalId

output aioUamiName string = aioUami.name
output aioUamiId string = aioUami.id
output aioUamiPrincipalId string = aioUami.properties.principalId
