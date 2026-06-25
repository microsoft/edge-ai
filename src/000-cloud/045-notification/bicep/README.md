<!-- BEGIN_BICEP_DOCS -->
<!-- markdownlint-disable MD033 -->

# Notification Component

Deploys Azure Logic Apps for Event Hub event notifications with Table Storage session deduplication. The primary workflow polls an Event Hub, deduplicates sessions in Azure Table Storage, and posts new-event alerts to Microsoft Teams. A secondary workflow exposes an HTTP endpoint to close active event sessions. The Teams connection requires user consent after deployment via the Azure Portal.

## Parameters

| Name                        | Description                                                                                                                                                | Type                               | Default       | Required |
|:----------------------------|:-----------------------------------------------------------------------------------------------------------------------------------------------------------|:-----------------------------------|:--------------|:---------|
| common                      | The common component configuration.                                                                                                                        | `[_2.Common](#user-defined-types)` | n/a           | yes      |
| eventhubNamespaceName       | The name of the Event Hub namespace for Logic App trigger connectivity and role assignment.                                                                | `string`                           | n/a           | yes      |
| eventhubName                | The name of the Event Hub to subscribe to for events.                                                                                                      | `string`                           | n/a           | yes      |
| storageAccountName          | The name of the storage account used for event session state tracking via Table Storage.                                                                   | `string`                           | n/a           | yes      |
| eventSchema                 | JSON schema object for parsing Event Hub events in the Logic App Parse_Event action.                                                                       | `object`                           | n/a           | yes      |
| notificationMessageTemplate | HTML template for new-event Teams notifications. Supports the `${close_session_url}` placeholder and Logic App expression syntax for dynamic event fields. | `string`                           | n/a           | yes      |
| closureMessageTemplate      | HTML message body for session-closure Teams notifications. Supports Logic App expression syntax for dynamic fields.                                        | `string`                           | n/a           | yes      |
| partitionKeyField           | Event schema field name used as the Table Storage partition key for session state deduplication lookups.                                                   | `string`                           | n/a           | yes      |
| teamsRecipientId            | Teams chat or channel thread ID for posting event notifications.                                                                                           | `securestring`                     | n/a           | yes      |
| teamsGroupId                | Microsoft 365 Group ID (Team ID) for posting to a Teams channel. Required when teamsPostLocation is 'Channel'.                                             | `string`                           | n/a           | no       |
| teamsPostLocation           | Teams posting location: 'Channel' or 'Group chat'.                                                                                                         | `string`                           | Channel       | no       |
| eventhubConsumerGroup       | Consumer group for the Event Hub trigger.                                                                                                                  | `string`                           | $Default      | no       |
| maximumEventsCount          | Maximum events retrieved per trigger execution.                                                                                                            | `int`                              | 50            | no       |
| pollingInterval             | Polling interval in seconds for the Event Hub trigger.                                                                                                     | `int`                              | 5             | no       |
| shouldAssignRoles           | Whether to create role assignments for the Logic App managed identities.                                                                                   | `bool`                             | `true`        | no       |
| tableName                   | Azure Table Storage table name for session state tracking.                                                                                                 | `string`                           | notifications | no       |

## Resources

| Name                                   | Type                                                     | API Version |
|:---------------------------------------|:---------------------------------------------------------|:------------|
| eventSessionsTable                     | `Microsoft.Storage/storageAccounts/tableServices/tables` | 2023-05-01  |
| eventhubConnection                     | `Microsoft.Web/connections`                              | 2016-06-01  |
| teamsConnection                        | `Microsoft.Web/connections`                              | 2016-06-01  |
| closeSession                           | `Microsoft.Logic/workflows`                              | 2019-05-01  |
| teamsNotification                      | `Microsoft.Logic/workflows`                              | 2019-05-01  |
| eventhubDataReceiverRoleAssignment     | `Microsoft.Resources/deployments`                        | 2025-04-01  |
| notificationStorageTableRoleAssignment | `Microsoft.Resources/deployments`                        | 2025-04-01  |
| closeSessionStorageTableRoleAssignment | `Microsoft.Resources/deployments`                        | 2025-04-01  |

## Modules

| Name                                   | Description                                                                                                    |
|:---------------------------------------|:---------------------------------------------------------------------------------------------------------------|
| eventhubDataReceiverRoleAssignment     | Grants the notification Logic App identity the Azure Event Hubs Data Receiver role on the Event Hub namespace. |
| notificationStorageTableRoleAssignment | Grants a Logic App identity the Storage Table Data Contributor role on the storage account.                    |
| closeSessionStorageTableRoleAssignment | Grants a Logic App identity the Storage Table Data Contributor role on the storage account.                    |

## Module Details

### eventhubDataReceiverRoleAssignment

Grants the notification Logic App identity the Azure Event Hubs Data Receiver role on the Event Hub namespace.

#### Parameters for eventhubDataReceiverRoleAssignment

| Name                  | Description                                                          | Type     | Default | Required |
|:----------------------|:---------------------------------------------------------------------|:---------|:--------|:---------|
| eventhubNamespaceName | The name of the Event Hub namespace to scope the role assignment to. | `string` | n/a     | yes      |
| principalId           | The principal ID granted the Azure Event Hubs Data Receiver role.    | `string` | n/a     | yes      |

#### Resources for eventhubDataReceiverRoleAssignment

| Name                                                                                                                                                          | Type                                      | API Version |
|:--------------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------|:------------|
| [guid(resourceId('Microsoft.EventHub/namespaces', parameters('eventhubNamespaceName')), parameters('principalId'), variables('eventHubsDataReceiverRoleId'))] | `Microsoft.Authorization/roleAssignments` | 2022-04-01  |

#### Outputs for eventhubDataReceiverRoleAssignment

| Name             | Type     | Description                             |
|:-----------------|:---------|:----------------------------------------|
| roleAssignmentId | `string` | The resource ID of the role assignment. |

### notificationStorageTableRoleAssignment

Grants a Logic App identity the Storage Table Data Contributor role on the storage account.

#### Parameters for notificationStorageTableRoleAssignment

| Name               | Description                                                       | Type     | Default | Required |
|:-------------------|:------------------------------------------------------------------|:---------|:--------|:---------|
| storageAccountName | The name of the storage account to scope the role assignment to.  | `string` | n/a     | yes      |
| principalId        | The principal ID granted the Storage Table Data Contributor role. | `string` | n/a     | yes      |

#### Resources for notificationStorageTableRoleAssignment

| Name                                                                                                                                                                 | Type                                      | API Version |
|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------|:------------|
| [guid(resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName')), parameters('principalId'), variables('storageTableDataContributorRoleId'))] | `Microsoft.Authorization/roleAssignments` | 2022-04-01  |

#### Outputs for notificationStorageTableRoleAssignment

| Name             | Type     | Description                             |
|:-----------------|:---------|:----------------------------------------|
| roleAssignmentId | `string` | The resource ID of the role assignment. |

### closeSessionStorageTableRoleAssignment

Grants a Logic App identity the Storage Table Data Contributor role on the storage account.

#### Parameters for closeSessionStorageTableRoleAssignment

| Name               | Description                                                       | Type     | Default | Required |
|:-------------------|:------------------------------------------------------------------|:---------|:--------|:---------|
| storageAccountName | The name of the storage account to scope the role assignment to.  | `string` | n/a     | yes      |
| principalId        | The principal ID granted the Storage Table Data Contributor role. | `string` | n/a     | yes      |

#### Resources for closeSessionStorageTableRoleAssignment

| Name                                                                                                                                                                 | Type                                      | API Version |
|:---------------------------------------------------------------------------------------------------------------------------------------------------------------------|:------------------------------------------|:------------|
| [guid(resourceId('Microsoft.Storage/storageAccounts', parameters('storageAccountName')), parameters('principalId'), variables('storageTableDataContributorRoleId'))] | `Microsoft.Authorization/roleAssignments` | 2022-04-01  |

#### Outputs for closeSessionStorageTableRoleAssignment

| Name             | Type     | Description                             |
|:-----------------|:---------|:----------------------------------------|
| roleAssignmentId | `string` | The resource ID of the role assignment. |

## User Defined Types

### `_1.LogicAppReference`

Reference details for a Logic App workflow with a system-assigned identity.

| Property            | Type     | Description                                                          |
|:--------------------|:---------|:---------------------------------------------------------------------|
| id                  | `string` | The resource ID of the Logic App workflow.                           |
| name                | `string` | The name of the Logic App workflow.                                  |
| identityPrincipalId | `string` | The principal ID of the Logic App workflow system-assigned identity. |

### `_1.StorageAccountReference`

Reference details for the storage account used for session state tracking.

| Property | Type     | Description                             |
|:---------|:---------|:----------------------------------------|
| id       | `string` | The resource ID of the storage account. |
| name     | `string` | The name of the storage account.        |

### `_2.Common`

Common settings for the components.

| Property       | Type     | Description                                                      |
|:---------------|:---------|:-----------------------------------------------------------------|
| resourcePrefix | `string` | Prefix for all resources in this module                          |
| location       | `string` | Location for all resources in this module                        |
| environment    | `string` | Environment for all resources in this module: dev, test, or prod |
| instance       | `string` | Instance identifier for naming resources: 001, 002, etc...       |

## Outputs

| Name                 | Type     | Description                                                              |
|:---------------------|:---------|:-------------------------------------------------------------------------|
| logicApp             | ``       | Notification Logic App workflow resource details.                        |
| closeLogicApp        | ``       | Close session Logic App workflow resource details.                       |
| closeSessionEndpoint | `string` | HTTP endpoint URL for closing active event sessions.                     |
| storageAccount       | ``       | Storage account used for event session state tracking via Table Storage. |

<!-- END_BICEP_DOCS -->