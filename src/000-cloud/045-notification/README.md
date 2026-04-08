---
title: Cloud Notification Component
description: Generic Event Hub to Microsoft Teams notification with Table Storage session deduplication, deployed as consumption-tier Azure Logic Apps with managed identity authentication
author: Edge AI Team
ms.date: 2026-02-27
ms.topic: reference
keywords:
  - notification
  - logic app
  - microsoft teams
  - event hub
  - session deduplication
  - table storage
  - azure logic app
  - teams connector
  - managed identity
  - terraform
estimated_reading_time: 5
---

## Cloud Notification Component

This component deploys Azure Logic Apps for Event Hub event notifications with state deduplication. The primary workflow subscribes to Event Hub events, deduplicates using Azure Table Storage, and posts new-event alerts to Microsoft Teams. A secondary workflow provides an HTTP endpoint to close active event sessions. All event schemas, notification templates, and entity bodies are caller-defined, making the component reusable across any event notification scenario.

## Purpose and Role

The Cloud Notification component provides a generic event-to-Teams notification pipeline with session tracking:

* **Event-Driven Notifications**: Monitors an Event Hub for incoming events and triggers Teams messages in near real-time with configurable polling interval
* **Session Deduplication**: Uses Azure Table Storage to track active event sessions, posting Teams alerts only for new sessions while silently updating existing ones
* **Close Session Endpoint**: Exposes an HTTP callback URL to close active sessions, delete the tracking record, and post a closure summary to Teams
* **Caller-Defined Templates**: Event schema, notification message, closure summary, insert/update entity bodies, and response messages are all provided by the caller
* **Managed Identity Authentication**: Uses SystemAssigned managed identity for secure access to Event Hub and Table Storage

## Architecture

The component creates two Logic App workflows that operate together:

### Primary Workflow (Notification)

1. **Event Hub Trigger**: Polls the configured Event Hub at a configurable interval for new events
2. **Parse Event**: Decodes base64 `ContentData` from Event Hub messages and parses JSON using the caller-provided `event_schema`
3. **Session Lookup**: Queries Table Storage for an active session matching the event's partition key field
4. **New Session**: If no active session exists, inserts a new entity (auto-generated or caller-provided `insert_entity_body`) and posts a Teams notification using `notification_message_template` (with `close_session_url` interpolated via Terraform's `templatestring` built-in, referenced as `$${close_session_url}` in the template string)
5. **Existing Session**: If an active session exists, updates the entity (auto-generated or caller-provided `update_entity_body`) without sending a duplicate notification

### Close Session Workflow

1. **HTTP Trigger**: Accepts close-session requests at the callback URL
2. **Session Lookup**: Retrieves the active session from Table Storage
3. **Delete Entity**: Removes the session tracking record
4. **Closure Summary**: Posts a formatted summary to Teams using `closure_message_template`
5. **Response**: Returns a parameterized status message (`close_success_message`, `close_not_found_message`, or `close_failure_message`)

## Component Resources

### Logic App Workflows

* **Notification Logic App** (`la-{prefix}-{notification_purpose}-{env}-{instance}`): Consumption-tier workflow with SystemAssigned managed identity for the event notification pipeline
* **Close Session Logic App** (`la-{prefix}-{close_purpose}-{env}-{instance}`): Consumption-tier workflow with SystemAssigned managed identity for the session close endpoint

### API Connections

* **EventHub API Connection** (`conn-evh-{prefix}-{env}-{instance}`): Connects to the Event Hub namespace using Managed Identity authentication
* **Teams API Connection** (`conn-teams-{prefix}-{env}-{instance}`): Connects to Microsoft Teams using OAuth user authentication (requires post-deployment consent)

### Table Storage

* **Event Sessions Table**: Azure Table Storage table for tracking active event sessions, named via `table_name` variable

### RBAC Role Assignments

When `should_assign_roles = true` (default):

* **Azure Event Hubs Data Receiver**: Grants the notification Logic App read access on the Event Hub namespace
* **Storage Table Data Contributor**: Grants both Logic Apps read/write access to the Table Storage account

## Post-Deployment Steps

Both API connections require manual authorization in the Azure Portal after Terraform deployment:

1. Navigate to `conn-evh-{prefix}-{env}-{instance}` in the Azure Portal, select Edit API connection, authorize with **Logic Apps Managed Identity**, and save
2. Navigate to `conn-teams-{prefix}-{env}-{instance}` in the Azure Portal, select Edit API connection, authorize by completing the **OAuth user consent flow**, and save
3. The Logic Apps begin processing events once both connections are authorized

## Variables

### Required Dependencies

| Variable                        | Type     | Description                                                                        |
|---------------------------------|----------|------------------------------------------------------------------------------------|
| `closure_message_template`      | `string` | HTML template for the Teams closure summary message                                |
| `event_schema`                  | `any`    | JSON schema object for parsing Event Hub event payloads                            |
| `eventhub_name`                 | `string` | Name of the Event Hub to subscribe to for events                                   |
| `eventhub_namespace`            | `object` | Event Hub namespace with `id` and `name` attributes                                |
| `notification_message_template` | `string` | HTML template for Teams notification (supports `${close_session_url}` placeholder) |
| `partition_key_field`           | `string` | JSON field name from parsed event used as the Table Storage PartitionKey           |
| `resource_group`                | `object` | Resource group with `name`, `id`, and `location` attributes                        |
| `teams_recipient_id`            | `string` | Teams chat or channel thread ID for posting notifications                          |

### Optional Configuration

| Variable                  | Type     | Default           | Description                                                                              |
|---------------------------|----------|-------------------|------------------------------------------------------------------------------------------|
| `close_failure_message`   | `string` | `"Failed to ..."` | Response body when session close fails unexpectedly                                      |
| `close_not_found_message` | `string` | `"No active ..."` | Response body when no active session is found                                            |
| `close_purpose`           | `string` | `"close"`         | Purpose label used in close Logic App naming                                             |
| `close_success_message`   | `string` | `"Session ..."`   | Response body when session is closed successfully                                        |
| `eventhub_consumer_group` | `string` | `"$Default"`      | Event Hub consumer group for the trigger                                                 |
| `extra_entity_fields`     | `map`    | `{}`              | Additional fields merged into the default insert entity body. Otherwise, `{}`            |
| `insert_entity_body`      | `any`    | `null`            | Full override for insert entity body. Otherwise, auto-generated from partition_key_field |
| `maximum_events_count`    | `number` | `50`              | Maximum events per trigger poll                                                          |
| `notification_purpose`    | `string` | `"notify"`        | Purpose label used in notification Logic App naming                                      |
| `polling_interval`        | `number` | `5`               | Trigger polling interval in seconds                                                      |
| `should_assign_roles`     | `bool`   | `true`            | Whether to create RBAC role assignments                                                  |
| `storage_account`         | `object` | `null`            | Storage account for session state. Otherwise, auto-created                               |
| `table_name`              | `string` | `"notifications"` | Azure Table Storage table name for session tracking                                      |
| `tags`                    | `map`    | `{}`              | Tags applied to all resources                                                            |
| `teams_post_location`     | `string` | `"Group chat"`    | Teams posting location type. Otherwise, 'Group chat'                                     |
| `update_entity_body`      | `any`    | `null`            | Full override for update entity body. Otherwise, auto-generated                          |

## Outputs

| Output                   | Sensitive | Description                                                              |
|--------------------------|-----------|--------------------------------------------------------------------------|
| `close_logic_app`        | no        | Close session Logic App details: `id`, `name`, `identity_principal_id`.  |
| `close_session_endpoint` | yes       | HTTP endpoint URL for closing active event sessions.                     |
| `logic_app`              | no        | Notification Logic App details: `id`, `name`, `identity_principal_id`.   |
| `storage_account`        | no        | Storage account used for event session state tracking via Table Storage. |

## Usage Example

```terraform
module "notification" {
  source = "../../src/000-cloud/045-notification/terraform"

  environment     = "dev"
  resource_prefix = "myapp"
  instance        = "001"

  resource_group     = data.azurerm_resource_group.main
  eventhub_namespace = module.messaging.eventhub_namespace
  eventhub_name      = "evh-device-alerts"
  storage_account    = module.data.storage_account
  teams_recipient_id = "19:your-thread-id@thread.v2"

  event_schema = {
    type = "object"
    properties = {
      device_id  = { type = "string" }
      event_type = { type = "string" }
      severity   = { type = "string" }
      timestamp  = { type = "number" }
    }
  }

  partition_key_field = "device_id"

  notification_message_template = join("", [
    "<p><strong>Device Alert</strong></p>",
    "<p>Device: @{body('Parse_Event')?['device_id']}</p>",
    "<p>Type: @{body('Parse_Event')?['event_type']}</p>",
    "<p><a href=\"$${close_session_url}&device=@{encodeUriComponent(body('Parse_Event')?['device_id'])}\">Close Session</a></p>",
  ])

  closure_message_template = join("", [
    "<p><strong>Session Closed</strong></p>",
    "<p>Device: @{triggerOutputs()['queries']['device']}</p>",
  ])

  // Optional: add extra fields to the auto-generated insert entity body
  extra_entity_fields = {
    EventType = "@{body('Parse_Event')?['event_type']}"
    Severity  = "@{body('Parse_Event')?['severity']}"
  }
}
```

## Provider Requirements

| Provider    | Version   |
|-------------|-----------|
| `azurerm`   | >= 4.51.0 |
| `azapi`     | >= 2.3.0  |
| `terraform` | >= 1.9.8  |

## Deployment Options

### Terraform

Refer to [Terraform Components - Getting Started](../../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

---

<!-- markdownlint-disable MD036 -->
*Crafted with precision by Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
