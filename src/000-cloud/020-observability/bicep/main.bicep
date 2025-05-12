metadata name = 'Observability'
metadata description = 'Deploys Azure observability resources including Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules for container monitoring and metrics collection.'

import * as core from './types.core.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('Additional tags to add to the resources.')
param tags object = {}

var defaultTags = {
  Environment: common.environment
  Instance: common.instance
}

/*
  Log Analytics Parameters
*/

@description('Log Analytics Workspace retention in days')
param logRetentionInDays int = 30

@description('Log Analytics Workspace daily quota in GB')
param dailyQuotaInGb int = 10

/*
  Grafana Parameters
*/

@description('Grafana major version')
param grafanaMajorVersion string = '10'

@description('The principalId (objectId) of the user or service principal to assign the Grafana Admin role.')
param grafanaAdminPrincipalId string?

/*
  Data Collection Parameters
*/

@description('List of cluster namespaces to be exposed in the log analytics workspace')
param logsDataCollectionRuleNamespaces array = [
  'kube-system'
  'gatekeeper-system'
  'azure-arc'
  'azure-iot-operations'
]

@description('List of streams to be enabled in the log analytics workspace')
param logsDataCollectionRuleStreams array = [
  'Microsoft-ContainerLog'
  'Microsoft-ContainerLogV2'
  'Microsoft-KubeEvents'
  'Microsoft-KubePodInventory'
  'Microsoft-KubeNodeInventory'
  'Microsoft-KubePVInventory'
  'Microsoft-KubeServices'
  'Microsoft-KubeMonAgentEvents'
  'Microsoft-InsightsMetrics'
  'Microsoft-ContainerInventory'
  'Microsoft-ContainerNodeInventory'
  'Microsoft-Perf'
]

/*
  Local Variables
*/

var grafanaAdminLocalPrincipalId = grafanaAdminPrincipalId ?? deployer().objectId

/*
  Monitoring Resources
*/

// Azure Monitor Workspace
resource monitorWorkspace 'Microsoft.Monitor/accounts@2023-04-03' = {
  name: 'azmon-${common.resourcePrefix}-${common.environment}-${common.instance}'
  location: common.location
}

// Log Analytics Workspace
resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: 'log-${common.resourcePrefix}-${common.environment}-${common.instance}'
  location: common.location
  properties: {
    sku: {
      name: 'PerGB2018'
    }
    retentionInDays: logRetentionInDays
    workspaceCapping: {
      dailyQuotaGb: dailyQuotaInGb
    }
    features: {
      disableLocalAuth: false
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
}

// Azure Managed Grafana
resource grafana 'Microsoft.Dashboard/grafana@2024-10-01' = {
  name: 'amg-${common.resourcePrefix}-${common.environment}-${common.instance}'
  location: common.location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicNetworkAccess: 'Enabled'
    grafanaMajorVersion: grafanaMajorVersion
    apiKey: 'Disabled'
    deterministicOutboundIP: 'Disabled'
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: [
        {
          azureMonitorWorkspaceResourceId: monitorWorkspace.id
        }
      ]
    }
  }
  identity: {
    type: 'SystemAssigned'
  }
  tags: union(defaultTags, tags)
}

/*
  Monitoring Solutions
*/

resource containerInsightsSolution 'Microsoft.OperationsManagement/solutions@2015-11-01-preview' = {
  name: 'ContainerInsights(${logAnalytics.name})'
  location: common.location
  properties: {
    workspaceResourceId: logAnalytics.id
  }
  plan: {
    name: 'ContainerInsights(${logAnalytics.name})'
    product: 'OMSGallery/ContainerInsights'
    publisher: 'Microsoft'
    promotionCode: ''
  }
  tags: union(defaultTags, tags)
}

/*
  Role Assignments
*/

// Use guid() instead of uniqueGuid() for deterministic role assignment names
resource grafanaLogsReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(logAnalytics.id, grafana.id, 'Reader')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      'acdd72a7-3385-48ef-bd42-f606fba81ae7'
    ) // Reader
    principalId: grafana.identity.principalId
    principalType: 'ServicePrincipal'
  }
  scope: logAnalytics
}

resource grafanaMetricsReaderRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(monitorWorkspace.id, grafana.id, 'Monitoring Reader')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '43d0d8ad-25c7-4714-9337-8ba259a9fe05'
    ) // Monitoring Data Reader
    principalId: grafana.identity.principalId
    principalType: 'ServicePrincipal'
  }
  scope: monitorWorkspace
}

resource grafanaAdminRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(grafana.id, 'Admin')
  properties: {
    roleDefinitionId: subscriptionResourceId(
      'Microsoft.Authorization/roleDefinitions',
      '22926164-76b3-42b3-bc55-97df8dab3e41'
    ) // Grafana Admin
    principalId: grafanaAdminLocalPrincipalId
  }
  scope: grafana
}

/*
  Data Collection Resources
*/

// Data Collection Endpoint
resource dataCollectionEndpoint 'Microsoft.Insights/dataCollectionEndpoints@2023-03-11' = {
  name: 'dce-${common.resourcePrefix}-${common.environment}-${common.instance}'
  location: common.location
  properties: {
    description: 'Data Collection Endpoint for Azure Monitor'
    networkAcls: {
      publicNetworkAccess: 'Enabled'
    }
  }
  tags: union(defaultTags, tags)
}

// Logs Data Collection Rule
resource logsDataCollectionRule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'dcr-${common.resourcePrefix}-${common.environment}-logs-${common.instance}'
  location: common.location
  kind: 'Linux'
  properties: {
    description: 'DCR for Azure Monitor Container Insights'
    dataSources: {
      extensions: [
        {
          name: 'ContainerInsightsExtension'
          streams: logsDataCollectionRuleStreams
          extensionName: 'ContainerInsights'
          extensionSettings: {
            dataCollectionSettings: {
              interval: '1m'
              namespaceFilteringMode: 'Off'
              namespaces: logsDataCollectionRuleNamespaces
              enableContainerLogV2: true
            }
          }
        }
      ]
    }
    destinations: {
      logAnalytics: [
        {
          workspaceResourceId: logAnalytics.id
          name: 'logAnalytics'
        }
      ]
    }
    dataFlows: [
      {
        streams: logsDataCollectionRuleStreams
        destinations: ['logAnalytics']
      }
    ]
  }
}

// Metrics Data Collection Rule
resource metricsDataCollectionRule 'Microsoft.Insights/dataCollectionRules@2023-03-11' = {
  name: 'dcr-${common.resourcePrefix}-${common.environment}-metrics-${common.instance}'
  location: common.location
  kind: 'Linux'
  properties: {
    description: 'DCR for Azure Monitor Metrics Profile (Managed Prometheus)'
    dataCollectionEndpointId: dataCollectionEndpoint.id
    dataSources: {
      prometheusForwarder: [
        {
          name: 'PrometheusDataSource'
          streams: ['Microsoft-PrometheusMetrics']
        }
      ]
    }
    destinations: {
      monitoringAccounts: [
        {
          accountResourceId: monitorWorkspace.id
          name: 'MonitoringAccount'
        }
      ]
    }
    dataFlows: [
      {
        streams: ['Microsoft-PrometheusMetrics']
        destinations: ['MonitoringAccount']
      }
    ]
  }
}

/*
  Outputs
*/

@description('The Azure Monitor Workspace name.')
output monitorWorkspaceName string = monitorWorkspace.name

@description('The Log Analytics Workspace name.')
output logAnalyticsName string = logAnalytics.name

@description('The Log Analytics Workspace ID.')
output logAnalyticsId string = logAnalytics.id

@description('The Azure Managed Grafana name.')
output grafanaName string = grafana.name

@description('The metrics data collection rule name.')
output metricsDataCollectionRuleName string = metricsDataCollectionRule.name

@description('The logs data collection rule name.')
output logsDataCollectionRuleName string = logsDataCollectionRule.name
