metadata name = 'ADR Namespace Module'
metadata description = 'Creates an Azure Device Registry (ADR) Namespace for organizing assets and devices in Azure IoT Operations.'

import * as core from '../types.core.bicep'
import * as types from '../types.bicep'

/*
  Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('The name of the ADR namespace. Lowercase alphanumeric with optional internal hyphens, 3-64 characters.')
param adrNamespaceName string?

@description('Dictionary of messaging endpoints for the namespace.')
param messagingEndpoints types.AdrNamespaceMessagingEndpoints?

@description('Whether to enable system-assigned managed identity for the namespace.')
param enableSystemAssignedIdentity bool = true

/*
  Variables
*/

var namespaceName = adrNamespaceName ?? 'adrns-${common.resourcePrefix}-${common.environment}-${common.instance}'

/*
  Resources
*/

resource adrNamespace 'Microsoft.DeviceRegistry/namespaces@2025-10-01' = {
  name: namespaceName
  location: common.location
  identity: enableSystemAssignedIdentity
    ? {
        type: 'SystemAssigned'
      }
    : null
  properties: {
    messaging: messagingEndpoints != null
      ? {
          endpoints: messagingEndpoints
        }
      : null
  }
}

/*
  Outputs
*/

@description('The name of the ADR namespace.')
output adrNamespaceName string = adrNamespace.name

@description('The resource ID of the ADR namespace.')
output adrNamespaceId string = adrNamespace.id

@description('The principal ID of the ADR namespace managed identity.')
output adrNamespacePrincipalId string = enableSystemAssignedIdentity ? adrNamespace.identity.principalId : ''

@description('The tenant ID of the ADR namespace managed identity.')
output adrNamespaceTenantId string = enableSystemAssignedIdentity ? adrNamespace.identity.tenantId : ''

@description('The complete ADR namespace resource information.')
output adrNamespace object = {
  id: adrNamespace.id
  name: adrNamespace.name
  location: adrNamespace.location
  identity: enableSystemAssignedIdentity
    ? {
        principalId: adrNamespace.identity.principalId
        tenantId: adrNamespace.identity.tenantId
        type: adrNamespace.identity.type
      }
    : null
}
