<!-- BEGIN_BICEP_DOCS -->
<!-- markdown-table-prettify-ignore-start -->
<!-- markdownlint-disable MD033 -->

# Observability

Deploys Azure observability resources including Azure Monitor Workspace, Log Analytics Workspace, Azure Managed Grafana, and Data Collection Rules for container monitoring and metrics collection.

## Parameters

|Name|Description|Type|Default|Required|
| :--- | :--- | :--- | :--- | :--- |
|common|The common component configuration.|`[_1.Common](#user-defined-types)`|n/a|yes|
|tags|Additional tags to add to the resources.|`object`|{}|no|
|logRetentionInDays|Log Analytics Workspace retention in days|`int`|30|no|
|dailyQuotaInGb|Log Analytics Workspace daily quota in GB|`int`|10|no|
|grafanaMajorVersion|Grafana major version|`string`|10|no|
|grafanaAdminPrincipalId|The principalId (objectId) of the user or service principal to assign the Grafana Admin role.|`string`|n/a|no|
|logsDataCollectionRuleNamespaces|List of cluster namespaces to be exposed in the log analytics workspace|`array`|['kube-system', 'gatekeeper-system', 'azure-arc', 'azure-iot-operations']|no|
|logsDataCollectionRuleStreams|List of streams to be enabled in the log analytics workspace|`array`|['Microsoft-ContainerLog', 'Microsoft-ContainerLogV2', 'Microsoft-KubeEvents', 'Microsoft-KubePodInventory', 'Microsoft-KubeNodeInventory', 'Microsoft-KubePVInventory', 'Microsoft-KubeServices', 'Microsoft-KubeMonAgentEvents', 'Microsoft-InsightsMetrics', 'Microsoft-ContainerInventory', 'Microsoft-ContainerNodeInventory', 'Microsoft-Perf']|no|
|telemetry_opt_out|Whether to opt out of telemetry data collection.|`bool`|`false`|no|

## Resources

|Name|Type|API Version|
| :--- | :--- | :--- |
|attribution|`Microsoft.Resources/deployments`|2020-06-01|
|monitorWorkspace|`Microsoft.Monitor/accounts`|2023-04-03|
|logAnalytics|`Microsoft.OperationalInsights/workspaces`|2025-02-01|
|grafana|`Microsoft.Dashboard/grafana`|2024-10-01|
|containerInsightsSolution|`Microsoft.OperationsManagement/solutions`|2015-11-01-preview|
|grafanaLogsReaderRole|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|grafanaMetricsReaderRole|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|grafanaAdminRole|`Microsoft.Authorization/roleAssignments`|2022-04-01|
|dataCollectionEndpoint|`Microsoft.Insights/dataCollectionEndpoints`|2023-03-11|
|logsDataCollectionRule|`Microsoft.Insights/dataCollectionRules`|2023-03-11|
|metricsDataCollectionRule|`Microsoft.Insights/dataCollectionRules`|2023-03-11|

## Modules

|Name|Description|
| :--- | :--- |
|attribution||

## Module Details

### attribution

## User Defined Types

### `_1.Common`

Common settings for the components.

|Property|Type|Description|
| :--- | :--- | :--- |
|resourcePrefix|`string`|Prefix for all resources in this module|
|location|`string`|Location for all resources in this module|
|environment|`string`|Environment for all resources in this module: dev, test, or prod|
|instance|`string`|Instance identifier for naming resources: 001, 002, etc...|

## Outputs

|Name|Type|Description|
| :--- | :--- | :--- |
|monitorWorkspaceName|`string`|The Azure Monitor Workspace name.|
|logAnalyticsName|`string`|The Log Analytics Workspace name.|
|logAnalyticsId|`string`|The Log Analytics Workspace ID.|
|grafanaName|`string`|The Azure Managed Grafana name.|
|metricsDataCollectionRuleName|`string`|The metrics data collection rule name.|
|logsDataCollectionRuleName|`string`|The logs data collection rule name.|

<!-- markdown-table-prettify-ignore-end -->
<!-- END_BICEP_DOCS -->
