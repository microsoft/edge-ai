metadata name = 'Cluster Extensions for Observability'
metadata description = 'Creates the cluster extensions required to expose cluster and container metrics.'

/*
  Parameters
*/

@description('The name of the Arc connected cluster.')
param arcConnectedClusterName string

@description('The name of the Azure Monitor Workspace.')
param azureMonitorWorkspaceName string

@description('The name of the Log Analytics Workspace.')
param logAnalyticsWorkspaceName string

@description('The resource group name where the Log Analytics Workspace is located.')
param logAnalyticsWorkspaceResourceGroupName string = resourceGroup().name

@description('The name of the Azure Managed Grafana instance.')
param azureManagedGrafanaName string

/*
  Local Variables
*/

var amaLogsDomain = 'opinsights.azure.com'

/*
  Resources
*/

// Get existing resources by name
resource arcConnectedCluster 'Microsoft.Kubernetes/connectedClusters@2024-01-01' existing = {
  name: arcConnectedClusterName
}

resource azureMonitorWorkspace 'Microsoft.Monitor/accounts@2023-04-03' existing = {
  name: azureMonitorWorkspaceName
}

resource azureManagedGrafana 'Microsoft.Dashboard/grafana@2022-08-01' existing = {
  name: azureManagedGrafanaName
}

resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2023-09-01' existing = {
  name: logAnalyticsWorkspaceName
  scope: resourceGroup(logAnalyticsWorkspaceResourceGroupName)
}

resource containerMetricsExtension 'Microsoft.KubernetesConfiguration/extensions@2024-11-01' = {
  scope: arcConnectedCluster
  name: 'azuremonitor-metrics'
  properties: {
    extensionType: 'Microsoft.AzureMonitor.Containers.Metrics'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    configurationSettings: {
      'azure-monitor-workspace-resource-id': azureMonitorWorkspace.id
      'grafana-resource-id': azureManagedGrafana.id
    }
    configurationProtectedSettings: {}
  }
  identity: {
    type: 'SystemAssigned'
  }
}

resource containerLogsExtension 'Microsoft.KubernetesConfiguration/extensions@2024-11-01' = {
  scope: arcConnectedCluster
  name: 'azuremonitor-containers'
  properties: {
    extensionType: 'Microsoft.AzureMonitor.Containers'
    autoUpgradeMinorVersion: true
    releaseTrain: 'Stable'
    configurationSettings: {
      logAnalyticsWorkspaceResourceID: logAnalyticsWorkspace.id
      'omsagent.domain': amaLogsDomain
      'amalogs.domain': amaLogsDomain
      'omsagent.useAADAuth': 'true'
      'amalogs.useAADAuth': 'true'
    }
    configurationProtectedSettings: {
      'amalogs.secret.wsid': logAnalyticsWorkspace.properties.customerId
      'amalogs.secret.key': logAnalyticsWorkspace.listKeys().primarySharedKey
      'omsagent.secret.wsid': logAnalyticsWorkspace.properties.customerId
      'omsagent.secret.key': logAnalyticsWorkspace.listKeys().primarySharedKey
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

/*
  Outputs
*/

@description('The container metrics extension.')
output containerMetricsExtension object = containerMetricsExtension

@description('The container logs extension.')
output containerLogsExtension object = containerLogsExtension
