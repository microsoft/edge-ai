metadata name = 'Registry Endpoints Module'
metadata description = 'Manages container registry endpoints for Azure IoT Operations, including the default MCR endpoint, custom registry endpoints, and ACR role assignments.'

import * as types from '../types.bicep'

/*
  Parameters
*/

@description('Azure IoT Operations instance ID (parent for registry endpoints).')
param aioInstanceId string

@description('Custom location ID for the Azure IoT Operations deployment.')
param customLocationId string

@description('Principal ID of the AIO Arc extension for ACR role assignments.')
param extensionPrincipalId string

@description('List of custom registry endpoints to configure.')
param registryEndpoints types.RegistryEndpointConfig[]

/*
  Variables
*/

var aioInstanceName = last(split(aioInstanceId, '/'))!

// Filter endpoints that have ACR resource ID and use SystemAssignedManagedIdentity
var endpointsWithAcr = filter(
  registryEndpoints,
  endpoint => endpoint.?acrResourceId != null && endpoint.authentication.method == 'SystemAssignedManagedIdentity'
)

// Default audience for system-assigned managed identity using environment function
var defaultSystemAssignedManagedIdentityAudience = environment().resourceManager

/*
  Resources
*/

// Default MCR endpoint (always created)
resource mcrEndpoint 'Microsoft.IoTOperations/instances/registryEndpoints@2025-10-01' = {
  name: '${aioInstanceName}/mcr'
  extendedLocation: {
    type: 'CustomLocation'
    name: customLocationId
  }
  properties: {
    host: 'mcr.microsoft.com'
    authentication: {
      method: 'Anonymous'
      anonymousSettings: {}
    }
  }
}

// Custom registry endpoints
resource customEndpoints 'Microsoft.IoTOperations/instances/registryEndpoints@2025-10-01' = [
  for endpoint in registryEndpoints: {
    name: '${aioInstanceName}/${endpoint.name}'
    extendedLocation: {
      type: 'CustomLocation'
      name: customLocationId
    }
    properties: {
      host: endpoint.host
      // Apply default audience for SystemAssignedManagedIdentity when not specified
      #disable-next-line BCP225
      authentication: endpoint.authentication.method == 'SystemAssignedManagedIdentity'
        ? {
            method: 'SystemAssignedManagedIdentity'
            systemAssignedManagedIdentitySettings: {
              audience: endpoint.authentication.systemAssignedManagedIdentitySettings.?audience ?? defaultSystemAssignedManagedIdentityAudience
            }
          }
        : endpoint.authentication
    }
  }
]

// Existing ACR references for role assignments
resource acrs 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' existing = [
  for endpoint in endpointsWithAcr: {
    name: last(split(endpoint.acrResourceId!, '/'))!
  }
]

// ACR role assignments for SystemAssignedManagedIdentity endpoints with acrResourceId
@batchSize(1)
resource acrPullRoleAssignments 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for (endpoint, i) in endpointsWithAcr: {
    name: guid(endpoint.acrResourceId!, extensionPrincipalId, 'AcrPull', endpoint.name)
    scope: acrs[i]
    properties: {
      // https://learn.microsoft.com/azure/role-based-access-control/built-in-roles/containers#acrpull
      roleDefinitionId: subscriptionResourceId(
        'Microsoft.Authorization/roleDefinitions',
        '7f951dda-4ed3-4680-a7ca-43fe172d538d'
      )
      principalId: extensionPrincipalId
      principalType: 'ServicePrincipal'
    }
  }
]

/*
  Outputs
*/

@description('Default MCR registry endpoint.')
output mcrEndpoint object = {
  id: mcrEndpoint.id
  name: mcrEndpoint.name
  host: 'mcr.microsoft.com'
}

@description('Array of custom registry endpoints.')
output customEndpointsOutput array = [
  for (endpoint, i) in registryEndpoints: {
    id: customEndpoints[i].id
    name: customEndpoints[i].name
    host: endpoint.host
  }
]

@description('Array of ACR role assignment IDs.')
output acrRoleAssignments array = [
  for (endpoint, i) in endpointsWithAcr: {
    name: endpoint.name
    id: acrPullRoleAssignments[i].id
  }
]
