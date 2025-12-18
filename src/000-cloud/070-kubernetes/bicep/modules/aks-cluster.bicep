metadata name = 'Azure Kubernetes Service Cluster'
metadata description = 'Deploys an Azure Kubernetes Service (AKS) cluster with integration to Azure Container Registry.'

import * as core from '../types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  AKS Cluster Parameters
*/

@description('Number of nodes for the agent pool in the AKS cluster.')
param nodeCount int

@description('VM size for the agent pool in the AKS cluster.')
param nodeVmSize string

@description('DNS prefix for the AKS cluster.')
param dnsPrefix string

@description('Subnet ID for AKS cluster.')
param snetAksId string

@description('Subnet ID for AKS pods.')
param snetAksPodId string

@description('ACR name for pull role assignment.')
param acrName string

/*
  Private Cluster Parameters
*/

@description('Whether to enable private cluster mode for AKS.')
param shouldEnablePrivateCluster bool

@description('Whether to enable public FQDN for private cluster.')
param shouldEnablePrivateClusterPublicFqdn bool

@description('Whether to create a private endpoint for the AKS cluster.')
param shouldEnablePrivateEndpoint bool

@description('Subnet ID where the private endpoint will be created.')
param privateEndpointSubnetId string?

@description('Virtual network ID for linking the private DNS zone.')
param virtualNetworkId string?

/*
  Local Variables
*/

var clusterDnsPrefix = empty(dnsPrefix)
  ? 'dns-${common.resourcePrefix}-${common.environment}-${common.instance}'
  : dnsPrefix
var aksName = 'aks-${common.resourcePrefix}-${common.environment}-${common.instance}'

/*
  Resources
*/

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2024-09-01' = {
  name: aksName
  location: common.location
  tags: {
    environment: common.environment
    component: 'kubernetes-cluster'
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    dnsPrefix: clusterDnsPrefix
    networkProfile: {
      networkPlugin: 'azure'
      networkPolicy: 'azure'
      loadBalancerSku: 'standard'
      serviceCidr: '10.1.0.0/16'
      dnsServiceIP: '10.1.0.10'
    }
    agentPoolProfiles: [
      {
        name: 'default'
        count: nodeCount
        vmSize: nodeVmSize
        vnetSubnetID: snetAksId
        podSubnetID: snetAksPodId
        mode: 'System'
      }
    ]
    apiServerAccessProfile: shouldEnablePrivateCluster
      ? {
          enablePrivateCluster: true
          enablePrivateClusterPublicFQDN: shouldEnablePrivateClusterPublicFqdn
          privateDNSZone: 'system'
        }
      : null
  }
}

// Assign ACR Pull role to AKS
resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(aksCluster.id, acr.id, 'acrpull')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '7f951dda-4ed3-4680-a7ca-43fe172d538d'
    ) // AcrPull role
    principalId: aksCluster.properties.identityProfile.kubeletidentity.objectId
    principalType: 'ServicePrincipal'
  }
}

// Private DNS Zone for AKS private endpoint (only when private endpoint is enabled)
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = if (shouldEnablePrivateEndpoint && !empty(virtualNetworkId)) {
  name: 'privatelink.${common.location}.azmk8s.io'
  location: 'global'
  tags: {
    environment: common.environment
    component: 'kubernetes-cluster'
  }
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = if (shouldEnablePrivateEndpoint && !empty(virtualNetworkId)) {
  parent: privateDnsZone
  name: '${aksName}-dns-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: virtualNetworkId!
    }
  }
}

// Private endpoint for AKS API server
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = if (shouldEnablePrivateEndpoint && !empty(privateEndpointSubnetId)) {
  name: 'pe-${aksName}'
  location: common.location
  properties: {
    subnet: {
      id: privateEndpointSubnetId!
    }
    privateLinkServiceConnections: [
      {
        name: 'pe-${aksName}-connection'
        properties: {
          privateLinkServiceId: aksCluster.id
          groupIds: [
            'management'
          ]
        }
      }
    ]
  }
}

resource privateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = if (shouldEnablePrivateEndpoint && !empty(privateEndpointSubnetId) && !empty(virtualNetworkId)) {
  parent: privateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'privatelink-azmk8s-io'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
}

/*
  Outputs
*/

@description('The AKS cluster name.')
output aksName string = aksCluster.name

@description('The AKS cluster ID.')
output aksId string = aksCluster.id

@description('The AKS cluster principal ID.')
output aksPrincipalId string = aksCluster.identity.principalId

@description('The private endpoint ID (if enabled).')
output privateEndpointId string? = shouldEnablePrivateEndpoint ? privateEndpoint.id : null

@description('The private DNS zone ID (if enabled).')
output privateDnsZoneId string? = shouldEnablePrivateEndpoint && !empty(virtualNetworkId) ? privateDnsZone.id : null
