metadata name = 'Cloud Notification'
metadata description = 'Deploys Azure Logic Apps for leak detection notifications with state tracking. The primary workflow subscribes to Event Hub ALERT_DLQC events, deduplicates using Azure Table Storage, and posts new-leak alerts to Microsoft Teams. A secondary workflow provides an HTTP endpoint to close active leak sessions. The Teams connection requires user consent after deployment via the Azure Portal.'

import * as core from './types.core.bicep'
import * as types from './types.bicep'

/*
  Common Parameters
*/

@description('The common component configuration.')
param common core.Common

@description('Additional tags to add to the resources.')
param tags object = {}

/*
  Dependency Parameters
*/

@description('Resource group reference (name, id, location).')
param resourceGroup types.ResourceGroupRef

@description('Event Hub namespace reference (id, name) for Logic App trigger.')
param eventhubNamespace types.EventHubNamespaceRef

@description('Name of the Event Hub to subscribe to for leak events.')
param eventhubName string

@description('Storage account reference (id, name) for leak-session Table Storage.')
param storageAccount types.StorageAccountRef

/*
  Optional Parameters
*/

@description('Whether to create role assignments for the Logic App managed identities.')
param shouldAssignRoles bool = true

@description('Teams chat or channel thread ID for posting notifications.')
param teamsRecipientId string

@description('Teams posting location type.')
param teamsPostLocation string = 'Group chat'

@description('Whether to opt out of telemetry data collection.')
param telemetry_opt_out bool = false

/*
  Variables
*/

var defaultTags = {
  Environment: common.environment
  Instance: common.instance
}

var tableName = 'leaksessions'

var eventhubDataReceiverRoleId = 'a638d3c7-ab3a-418d-83e6-5f17a39d4fde'
var storageTableDataContributorRoleId = '0a9a7e1f-b9d0-4cc4-a60d-0319b160aaa3'

/*
  Resources
*/

// Fixed PID GUID so Partner Center can aggregate deployments of this module
// across subscriptions. Do not templatize — a stable string is the point.
// The 'no-deployments-resources' lint rule asks us to declare this as a module,
// but the PID attribution pattern requires it to be an inline empty deployment,
// not a module reference. Suppression is intentional and standard for this pattern.
#disable-next-line no-deployments-resources
resource attribution 'Microsoft.Resources/deployments@2020-06-01' = if (!telemetry_opt_out) {
  name: 'pid-2eb2bc30-7a1e-4710-93fa-168d388da93c'
  properties: {
    mode: 'Incremental'
    template: {
      '$schema': 'https://schema.management.azure.com/schemas/2015-01-01/deploymentTemplate.json#'
      contentVersion: '1.0.0.0'
      resources: []
    }
  }
}

resource leakSessionsTable 'Microsoft.Storage/storageAccounts/tableServices/tables@2023-05-01' = {
  name: '${storageAccount.name}/default/${tableName}'
}

module eventhubConnection 'modules/eventhub-connection.bicep' = {
  name: '${deployment().name}-evhub-conn'
  params: {
    common: common
    tags: union(defaultTags, tags)
    eventhubNamespaceName: eventhubNamespace.name
    location: resourceGroup.location
  }
}

module teamsConnection 'modules/teams-connection.bicep' = {
  name: '${deployment().name}-teams-conn'
  params: {
    common: common
    tags: union(defaultTags, tags)
    location: resourceGroup.location
  }
}

module leakCloseLogicApp 'modules/leak-close-logic-app.bicep' = {
  name: '${deployment().name}-close-app'
  params: {
    common: common
    tags: union(defaultTags, tags)
    location: resourceGroup.location
    teamsConnectionId: teamsConnection.outputs.connectionId
    teamsConnectionName: teamsConnection.outputs.connectionName
    teamsManagedApiId: teamsConnection.outputs.managedApiId
    storageAccountName: storageAccount.name
    tableName: tableName
    teamsRecipientId: teamsRecipientId
    teamsPostLocation: teamsPostLocation
  }
  dependsOn: [
    leakSessionsTable
  ]
}

module leakNotifyLogicApp 'modules/leak-notify-logic-app.bicep' = {
  name: '${deployment().name}-notify-app'
  params: {
    common: common
    tags: union(defaultTags, tags)
    location: resourceGroup.location
    eventhubName: eventhubName
    eventhubConnectionId: eventhubConnection.outputs.connectionId
    eventhubConnectionName: eventhubConnection.outputs.connectionName
    eventhubManagedApiId: eventhubConnection.outputs.managedApiId
    teamsConnectionId: teamsConnection.outputs.connectionId
    teamsConnectionName: teamsConnection.outputs.connectionName
    teamsManagedApiId: teamsConnection.outputs.managedApiId
    storageAccountName: storageAccount.name
    tableName: tableName
    teamsRecipientId: teamsRecipientId
    teamsPostLocation: teamsPostLocation
    closeLeakCallbackUrl: leakCloseLogicApp.outputs.callbackUrl
  }
  dependsOn: [
    leakSessionsTable
  ]
}

/*
  Role Assignments
*/

resource eventhubNamespaceRef 'Microsoft.EventHub/namespaces@2024-05-01-preview' existing = {
  name: eventhubNamespace.name
}

resource storageAccountRef 'Microsoft.Storage/storageAccounts@2023-05-01' existing = {
  name: storageAccount.name
}

resource notifyEventhubReceiverRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (shouldAssignRoles) {
  name: guid(eventhubNamespace.id, leakNotifyLogicApp.name, 'EventHubDataReceiver')
  scope: eventhubNamespaceRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', eventhubDataReceiverRoleId)
    principalId: leakNotifyLogicApp.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource notifyStorageTableRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (shouldAssignRoles) {
  name: guid(storageAccount.id, leakNotifyLogicApp.name, 'StorageTableDataContributor')
  scope: storageAccountRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageTableDataContributorRoleId)
    principalId: leakNotifyLogicApp.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

resource closeStorageTableRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = if (shouldAssignRoles) {
  name: guid(storageAccount.id, leakCloseLogicApp.name, 'StorageTableDataContributor')
  scope: storageAccountRef
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', storageTableDataContributorRoleId)
    principalId: leakCloseLogicApp.outputs.identityPrincipalId
    principalType: 'ServicePrincipal'
  }
}

/*
  Outputs
*/

@description('HTTP endpoint URL for closing active leak sessions.')
#disable-next-line outputs-should-not-contain-secrets
output closeLeakEndpoint string = leakCloseLogicApp.outputs.callbackUrl

@description('Logic App workflow resource details for the primary notification workflow.')
output logicApp types.LogicAppRef = {
  id: leakNotifyLogicApp.outputs.logicAppId
  name: leakNotifyLogicApp.outputs.logicAppName
  identityPrincipalId: leakNotifyLogicApp.outputs.identityPrincipalId
}
