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
  Local Variables
*/

var clusterDnsPrefix = empty(dnsPrefix)
  ? 'dns-${common.resourcePrefix}-${common.environment}-${common.instance}'
  : dnsPrefix

/*
  Resources
*/

resource acr 'Microsoft.ContainerRegistry/registries@2023-01-01-preview' existing = {
  name: acrName
}

resource aksCluster 'Microsoft.ContainerService/managedClusters@2023-06-01' = {
  name: 'aks-${common.resourcePrefix}-${common.environment}-${common.instance}'
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

/*
  Outputs
*/

@description('The AKS cluster name.')
output aksName string = aksCluster.name
