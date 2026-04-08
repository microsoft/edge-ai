<!-- BEGIN_TF_DOCS -->
# Notification

Deploys Azure Logic Apps for Event Hub event notifications with state deduplication.
The primary workflow subscribes to Event Hub events, deduplicates using Azure Table
Storage, and posts new-event alerts to Microsoft Teams.
A secondary workflow provides an HTTP endpoint to close active event sessions.
The Teams connection requires user consent after deployment via the Azure Portal.

## Requirements

| Name      | Version         |
|-----------|-----------------|
| terraform | >= 1.9.8, < 2.0 |
| azapi     | >= 2.3.0        |
| azurerm   | >= 4.51.0       |

## Providers

| Name    | Version   |
|---------|-----------|
| azapi   | >= 2.3.0  |
| azurerm | >= 4.51.0 |

## Resources

| Name                                                                                                                                                                    | Type        |
|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| [azapi_resource.event_sessions_table](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)                                               | resource    |
| [azapi_resource.eventhub_connection](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)                                                | resource    |
| [azapi_resource.teams_connection](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource)                                                   | resource    |
| [azapi_resource_action.close_session_callback_url](https://registry.terraform.io/providers/Azure/azapi/latest/docs/resources/resource_action)                           | resource    |
| [azurerm_logic_app_action_custom.close_response](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_action_custom)               | resource    |
| [azurerm_logic_app_action_custom.delete_entity](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_action_custom)                | resource    |
| [azurerm_logic_app_action_custom.for_each_event](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_action_custom)               | resource    |
| [azurerm_logic_app_action_custom.get_active_session](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_action_custom)           | resource    |
| [azurerm_logic_app_action_custom.post_closure_summary](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_action_custom)         | resource    |
| [azurerm_logic_app_trigger_custom.close_session_trigger](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_trigger_custom)      | resource    |
| [azurerm_logic_app_trigger_custom.eventhub_trigger](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_trigger_custom)           | resource    |
| [azurerm_logic_app_workflow.close_session](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_workflow)                          | resource    |
| [azurerm_logic_app_workflow.teams_notification](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/logic_app_workflow)                     | resource    |
| [azurerm_role_assignment.close_session_storage_table_data_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment) | resource    |
| [azurerm_role_assignment.eventhub_data_receiver](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)                       | resource    |
| [azurerm_role_assignment.storage_table_data_contributor](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/role_assignment)               | resource    |
| [azurerm_managed_api.eventhub](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/managed_api)                                          | data source |
| [azurerm_managed_api.teams](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/data-sources/managed_api)                                             | data source |

## Inputs

| Name                            | Description                                                                                                                                                               | Type                                                          | Default                     | Required |
|---------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------|-----------------------------|:--------:|
| closure\_message\_template      | HTML message body for session-closure Teams notifications. Supports Logic App expression syntax for dynamic fields                                                        | `string`                                                      | n/a                         |   yes    |
| environment                     | Environment for all resources in this module: dev, test, or prod                                                                                                          | `string`                                                      | n/a                         |   yes    |
| event\_schema                   | JSON schema object for parsing Event Hub events in the Logic App Parse\_Event action                                                                                      | `any`                                                         | n/a                         |   yes    |
| eventhub\_name                  | Name of the Event Hub to subscribe to for events                                                                                                                          | `string`                                                      | n/a                         |   yes    |
| eventhub\_namespace             | Event Hub namespace for Logic App trigger connectivity and role assignment                                                                                                | ```object({ id = string name = string })```                   | n/a                         |   yes    |
| location                        | Azure region where all resources will be deployed                                                                                                                         | `string`                                                      | n/a                         |   yes    |
| notification\_message\_template | HTML template for new-event Teams notifications. Supports Terraform template variable: close\_session\_url. Supports Logic App expression syntax for dynamic event fields | `string`                                                      | n/a                         |   yes    |
| partition\_key\_field           | Event schema field name used as the Table Storage partition key for session state deduplication lookups                                                                   | `string`                                                      | n/a                         |   yes    |
| resource\_group                 | Resource group object containing name and id where resources will be deployed                                                                                             | ```object({ name = string id = string location = string })``` | n/a                         |   yes    |
| resource\_prefix                | Prefix for all resources in this module                                                                                                                                   | `string`                                                      | n/a                         |   yes    |
| storage\_account                | Storage account for event session state tracking via Table Storage                                                                                                        | ```object({ id = string name = string })```                   | n/a                         |   yes    |
| teams\_recipient\_id            | Teams chat or channel thread ID for posting event notifications                                                                                                           | `string`                                                      | n/a                         |   yes    |
| close\_failure\_message         | HTTP response text when session close fails. Otherwise, 'Failed to close session'                                                                                         | `string`                                                      | `"Failed to close session"` |    no    |
| close\_not\_found\_message      | HTTP response text when no active session is found. Otherwise, 'No active session found'                                                                                  | `string`                                                      | `"No active session found"` |    no    |
| close\_purpose                  | Purpose label for the close Logic App name. Otherwise, 'close'                                                                                                            | `string`                                                      | `"close"`                   |    no    |
| close\_success\_message         | HTTP response text when session is closed. Otherwise, 'Session closed'                                                                                                    | `string`                                                      | `"Session closed"`          |    no    |
| eventhub\_consumer\_group       | Consumer group for Event Hub trigger. Otherwise, '$Default'                                                                                                               | `string`                                                      | `"$Default"`                |    no    |
| extra\_entity\_fields           | Additional fields merged into the default insert entity body. Ignored when insert\_entity\_body is provided. Otherwise, '{}'                                              | `map(any)`                                                    | `{}`                        |    no    |
| insert\_entity\_body            | Table Storage entity body for inserting a new session record. Otherwise, auto-generated from partition\_key\_field with session tracking fields                           | `any`                                                         | `null`                      |    no    |
| instance                        | Instance identifier for naming resources: 001, 002, etc                                                                                                                   | `string`                                                      | `"001"`                     |    no    |
| maximum\_events\_count          | Maximum number of events to retrieve per trigger execution. Otherwise, 50                                                                                                 | `number`                                                      | `50`                        |    no    |
| notification\_purpose           | Purpose label for the notification Logic App name. Otherwise, 'notify'                                                                                                    | `string`                                                      | `"notify"`                  |    no    |
| polling\_interval               | Polling interval in seconds for Event Hub trigger. Otherwise, 5                                                                                                           | `number`                                                      | `5`                         |    no    |
| should\_assign\_roles           | Whether to create role assignments for the Logic App managed identity                                                                                                     | `bool`                                                        | `true`                      |    no    |
| table\_name                     | Azure Table Storage table name for session state tracking. Otherwise, 'notifications'                                                                                     | `string`                                                      | `"notifications"`           |    no    |
| tags                            | Tags to apply to all resources in this module                                                                                                                             | `map(string)`                                                 | `{}`                        |    no    |
| teams\_post\_location           | Teams posting location type for the notification message. Otherwise, 'Group chat'                                                                                         | `string`                                                      | `"Group chat"`              |    no    |
| update\_entity\_body            | Table Storage entity body for updating an existing session record. Otherwise, auto-generated with LastEventAt timestamp and EventCount increment                          | `any`                                                         | `null`                      |    no    |

## Outputs

| Name                     | Description                                                              |
|--------------------------|--------------------------------------------------------------------------|
| close\_logic\_app        | Close session Logic App workflow resource details.                       |
| close\_session\_endpoint | HTTP endpoint URL for closing active event sessions.                     |
| logic\_app               | Notification Logic App workflow resource details.                        |
| storage\_account         | Storage account used for event session state tracking via Table Storage. |
<!-- END_TF_DOCS -->
