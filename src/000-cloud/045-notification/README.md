---
title: Cloud Notification Component
description: Azure Logic App workflow that sends Microsoft Teams notifications when leak detection events arrive in Event Hub, using managed identity authentication and OAuth-based Teams integration
author: Edge AI Team
ms.date: 2026-02-23
ms.topic: reference
keywords:
  - notification
  - logic app
  - microsoft teams
  - leak detection
  - event hub trigger
  - azure logic app
  - teams connector
  - oauth
  - managed identity
  - terraform
estimated_reading_time: 4
---

## Cloud Notification Component

This component deploys an Azure Logic App workflow that sends Microsoft Teams notifications when leak detection events arrive in Event Hub. The Logic App subscribes to ALERT_DLQC events, parses the leak detection payload, and posts formatted alert messages directly to a Teams chat or channel via the Teams API Connection (OAuth connector).

## Purpose and Role

The Cloud Notification component provides automated alerting for the leak detection pipeline:

* **Event-Driven Notifications**: Monitors Event Hub for incoming leak detection events and triggers Teams messages in near real-time (5-second polling interval)
* **Teams Integration**: Posts formatted leak alert details directly to a Microsoft Teams chat or channel using the Teams API connector with OAuth authentication
* **Managed Identity Authentication**: Uses SystemAssigned managed identity for secure access to Event Hub — no credentials to manage
* **Minimal Operational Overhead**: Consumption-tier Logic App with built-in retry, error handling, and Azure Monitor integration

## Component Resources

This component creates the following Azure resources:

### Logic App Workflow

* **Logic App** (`la-{prefix}-leak-notify-{env}-{instance}`): Consumption-tier workflow with SystemAssigned managed identity that orchestrates the event-to-notification pipeline

### API Connections

* **EventHub API Connection** (`apicon-evhub-{prefix}-{env}-{instance}`): Connects to the Event Hub namespace using Managed Identity authentication (`managedIdentityAuth` parameter value set)
* **Teams API Connection** (`apicon-teams-{prefix}-{env}-{instance}`): Connects to Microsoft Teams using OAuth user authentication — requires manual consent in Azure Portal after deployment

### Workflow Actions

* **EventHub Trigger**: Polls the specified Event Hub every 5 seconds for new events via the EventHub API Connection
* **Parse Leak Event**: Decodes base64 `ContentData` from Event Hub messages and parses the JSON payload (confidence level, timestamp, device ID, location, alert type, message)
* **Post Teams Message**: Posts formatted leak alert details to a Teams chat or channel via the Teams API Connection

### RBAC Role Assignment

* **Azure Event Hubs Data Receiver**: Grants the Logic App managed identity read access on the Event Hub namespace (gated by `should_assign_roles`)

## Notification Workflow

1. **Event Ingestion**: ALERT_DLQC events flow from the edge MQTT broker through the 130-messaging dataflow into Event Hub
2. **Event Hub Trigger**: The Logic App polls Event Hub every 5 seconds and triggers on new events
3. **Payload Parsing**: The `Parse_Leak_Event` action decodes the base64 content and extracts structured fields (confidence level, device ID, location, alert type)
4. **Teams Notification**: The `Post_message_in_a_chat_or_channel` action sends a formatted alert message to the configured Teams thread

## Post-Deployment Steps

Both API connections require manual authorization in the Azure Portal after Terraform deployment:

1. **Authorize the EventHub API Connection**: Navigate to `apicon-evhub-{prefix}-{env}-{instance}` in the Azure Portal → Edit API connection → Authorize → select **Logic Apps Managed Identity** → Save
2. **Authorize the Teams API Connection**: Navigate to `apicon-teams-{prefix}-{env}-{instance}` in the Azure Portal → Edit API connection → Authorize → complete the **OAuth user consent flow** → Save
3. The Logic App begins processing events once both connections are authorized

## Variables

### Core

| Variable          | Type     | Default | Description                                      |
|-------------------|----------|---------|--------------------------------------------------|
| `environment`     | `string` | —       | Environment type: dev, test, or prod             |
| `resource_prefix` | `string` | —       | Prefix for all resource names (regex validated)  |
| `instance`        | `string` | `"001"` | Instance identifier for naming                   |

### Dependencies

| Variable             | Type     | Description                                              |
|----------------------|----------|----------------------------------------------------------|
| `resource_group`     | `object` | Resource group (name, id, location)                      |
| `eventhub_namespace` | `object` | Event Hub namespace (id, name) for trigger and RBAC      |
| `eventhub_name`      | `string` | Name of the Event Hub to subscribe to                    |

### Configuration

| Variable              | Type     | Default          | Description                                         |
|-----------------------|----------|------------------|-----------------------------------------------------|
| `teams_recipient_id`  | `string` | —                | Teams thread ID (`19:xxx@thread.v2`)                |
| `teams_post_location` | `string` | `"Group chat"`   | Teams posting location type                         |
| `should_assign_roles` | `bool`   | `true`           | Whether to create RBAC role assignments             |
| `tags`                | `map`    | `{}`             | Tags to apply to all resources                      |

## Outputs

| Output      | Type     | Description                                                        |
|-------------|----------|--------------------------------------------------------------------|
| `logic_app` | `object` | Logic App details: `id`, `name`, `identity_principal_id`           |

## Provider Requirements

| Provider    | Version      |
|-------------|--------------|
| `azurerm`   | >= 4.51.0    |
| `azapi`     | >= 2.3.0     |
| `terraform` | >= 1.9.8     |

## Deployment Options

### Terraform

Refer to [Terraform Components - Getting Started](../../README.md#terraform-components---getting-started) for
deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

### Bicep

Refer to [Bicep Components - Getting Started](../README.md#bicep-components---getting-started) for deployment instructions.

Learn more about the required configuration by reading the [./bicep/README.md](./bicep/README.md)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
