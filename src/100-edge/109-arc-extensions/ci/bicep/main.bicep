metadata name = 'Arc Extensions CI'
metadata description = 'CI deployment for Arc Extensions component.'

import * as core from '../../bicep/types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

/*
  Existing Resources
*/

var resourceGroupName = 'rg-${common.resourcePrefix}-${common.environment}-${common.instance}'
var arcConnectedClusterName = 'arck-${common.resourcePrefix}-${common.environment}-${common.instance}'

resource resourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' existing = {
  name: resourceGroupName
  scope: subscription()
}

resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2024-12-01-preview' existing = {
  name: arcConnectedClusterName
  scope: resourceGroup
}

/*
  Module Deployment
*/

module ci '../../bicep/main.bicep' = {
  name: 'arc-extensions-ci-deployment'
  scope: resourceGroup
  params: {
    arcConnectedClusterName: arcConnectedCluster.name
  }
}
