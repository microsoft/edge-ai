---
title: Tiered Notification Service
description: Azure Function that processes events from Event Hub and dispatches tiered webhook notifications to Teams, Slack, or generic HTTP endpoints
author: Edge AI Team
ms.date: 2026-03-10
ms.topic: reference
keywords:
  - azure-functions
  - event-hub
  - alerts
  - notifications
  - webhook
  - teams
  - slack
  - inference
  - managed-identity
  - severity-routing
estimated_reading_time: 10
---

## Tiered Notification Service

Azure Function (Node.js v4 programming model) that consumes event messages from Event Hub and dispatches structured, severity-tiered webhook notifications to Microsoft Teams, Slack, or generic HTTP endpoints.

## Overview

This function completes the notification pipeline in the Edge AI alert architecture. The [507-ai-inference](../507-ai-inference/) service runs on-device inference using ONNX Runtime or Candle backends, publishing results to MQTT topics. Inference results flagged as high-priority are routed through AIO dataflows to a dedicated Event Hub. This function triggers on those messages, applies severity-tiered processing with deduplication, and sends formatted notifications to the configured webhook destination.

### Why Severity-Tiered Routing?

Edge AI inference pipelines generate a high volume of alerts across varying priority levels. Sending every alert as an immediate webhook notification creates noise that causes operators to ignore critical events. The tiered routing approach addresses this by separating alerts into dispatch categories based on severity:

1. **Critical and high** alerts trigger immediate webhook dispatch, ensuring operators receive time-sensitive notifications without delay.
2. **Medium** alerts accumulate in a digest buffer and flush periodically as a single summary notification, reducing interruptions while preserving visibility.
3. **Low** alerts are logged for dashboard consumption only, keeping operational dashboards complete without generating webhook traffic.

### Key Callouts

* The function uses in-memory deduplication with a configurable time window (`DEDUP_WINDOW_MS`) to suppress repeated alerts from the same source, label, and severity combination.
* Medium-severity digest batches flush at a configurable interval (`DIGEST_INTERVAL_MS`) or at the end of each Event Hub batch invocation.
* Webhook format detection is automatic: the function inspects the destination URL to determine whether to send a Teams Adaptive Card, Slack Block Kit message, or generic JSON payload.
* Failed webhook dispatches retry once on transient errors (HTTP 5xx or network failures) before logging the error.
* Infrastructure (Function App, App Service Plan, Storage Account, managed identity, RBAC) is provisioned entirely by the `040-messaging` Terraform component. This component contains only the application code.

### Processing Pipeline

| Severity | Dispatch Behavior                                  |
|----------|----------------------------------------------------|
| Critical | Immediate webhook dispatch                         |
| High     | Immediate webhook dispatch                         |
| Medium   | Buffered into periodic digest, flushed on interval |
| Low      | Logged only (dashboard consumption, no webhook)    |

## Architecture

```text
┌ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ┐
  Edge Environment
│                                                                                              │
  ┌─────────────────┐   MQTT    ┌──────────────────┐
│ │ 507-ai-         │─────────▶│  AIO Dataflow    │                                           │
  │ inference       │          │  (Filter/Route)  │
│ │ (ONNX / Candle) │          └────────┬─────────┘                                           │
  └─────────────────┘                   │
│                                        │ Kafka/AMQP                                          │
 ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─│─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─
                                         │
┌────────────────────────────────────────┼─────────────────────────────────────────────────────┐
│ Cloud Environment (Azure)              │                                                     │
│                                        ▼                                                     │
│  ┌──────────────────────────────────────────────────────────────┐                             │
│  │  Event Hub Namespace (040-messaging)                        │                             │
│  │  ┌────────────────────────┐  ┌───────────────────────────┐  │                             │
│  │  │  Alert Event Hub       │  │  Consumer Group:          │  │                             │
│  │  │  (evh-*-alerts-*)      │  │  fn-notifications         │  │                             │
│  │  └────────────────────────┘  └───────────────────────────┘  │                             │
│  └──────────────────────────────────┬───────────────────────────┘                             │
│                                     │  Managed Identity Auth                                 │
│                                     ▼                                                        │
│  ┌───────────────────────────────────────────────────────────────────────────────────────┐    │
│  │                        Azure Function App (this component)                           │    │
│  │  ┌───────────────────┐  ┌──────────────────┐  ┌─────────────────────────────────┐    │    │
│  │  │  Event Hub Trigger │  │ Severity Filter  │  │ Webhook Dispatch                │    │    │
│  │  │  (Batch, up to 64) │─▶│ + Deduplication  │─▶│ (Teams / Slack / Generic JSON)  │    │    │
│  │  └───────────────────┘  └──────────────────┘  └────────────────┬────────────────┘    │    │
│  └────────────────────────────────────────────────────────────────┼──────────────────────┘    │
│                                                                    │                          │
└────────────────────────────────────────────────────────────────────┼──────────────────────────┘
                                                                     │
                                                                     ▼
                                              ┌─────────────────────────────────────┐
                                              │        Webhook Destination          │
                                              │  (Teams / Slack / HTTP Endpoint)    │
                                              └─────────────────────────────────────┘
```

### Infrastructure Boundary

The `040-messaging` Terraform component provisions all cloud infrastructure for this function:

| Resource                 | Purpose                                          |
|--------------------------|--------------------------------------------------|
| App Service Plan         | Consumption-tier hosting for the Function App    |
| Azure Function App       | Runtime environment for this application code    |
| Storage Account          | Function App internal state and trigger tracking |
| User-Assigned MI         | `notification_identity` for Event Hub auth       |
| RBAC Role Assignment     | `Azure Event Hubs Data Receiver` on namespace    |
| Event Hub Consumer Group | `fn-notifications` on the alert Event Hub        |

This component contains only the application code deployed to the Terraform-provisioned Function App.

## Prerequisites

* [Full Single Node Cluster](../../../blueprints/full-single-node-cluster/) blueprint deployed with alert dataflow configuration (see [alert-dataflow.tfvars.example](../../../blueprints/full-single-node-cluster/terraform/alert-dataflow.tfvars.example))
* [507-ai-inference](../507-ai-inference/) service deployed to the edge cluster, publishing inference results to MQTT topics
* [Azure Functions Core Tools v4](https://learn.microsoft.com/azure/azure-functions/functions-run-local) for local development and deployment
* [Node.js >= 20](https://nodejs.org/) runtime
* [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) with subscription access
* A webhook URL: [Teams Incoming Webhook](https://learn.microsoft.com/microsoftteams/platform/webhooks-and-connectors/how-to/add-incoming-webhook), [Slack Webhook](https://api.slack.com/messaging/webhooks), or any HTTP endpoint accepting JSON POST requests

## Deployment

### Step 1: Deploy Infrastructure

Deploy the `full-single-node-cluster` blueprint with alert dataflow support enabled. The `alert-dataflow.tfvars.example` provides a reference configuration:

```hcl
should_create_azure_functions = true
alert_eventhub_name           = "evh-aio-alerts-dev-001"
notification_webhook_url      = "https://your-teams-or-slack-webhook-url"
alert_severity_threshold      = "high"

eventhubs = {
  "evh-aio-sample" = {}
  "evh-aio-alerts-dev-001" = {
    message_retention = 1
    partition_count   = 2
    consumer_groups = {
      "fn-notifications" = {
        user_metadata = "Alert notification function consumer group"
      }
    }
  }
}
```

This provisions the Event Hub namespace, alert Event Hub with consumer group, Function App with managed identity, and wires the app settings automatically.

### Step 2: Install Dependencies

```bash
cd src/500-application/513-tiered-notification-service
npm install
```

### Step 3: Deploy Function Code

Deploy the application code to the Terraform-provisioned Function App using the Azure Functions Core Tools:

```bash
func azure functionapp publish <FUNCTION_APP_NAME>
```

The Function App name is available from the blueprint output `function_app`.

### Deployment Outcomes

After completing the deployment:

* The Function App authenticates to Event Hub using managed identity (no connection strings in production)
* Event Hub trigger app settings (`EventHubConnection__fullyQualifiedNamespace`, `EventHubConnection__credential`, `EventHubConnection__clientId`) are configured by Terraform
* The function processes messages from the `fn-notifications` consumer group on the alert Event Hub
* Webhook notifications dispatch to the configured URL with automatic format detection

### Verification

1. Check Function App logs in the Azure Portal under the Function App > Functions > processAlerts > Monitor
2. Publish a test MQTT message to the inference alert topic (e.g., `edge-ai/+/+/+/inference/+/+/high`)
3. Confirm webhook delivery at the configured Teams channel, Slack channel, or HTTP endpoint

## Integration with Azure IoT Operations

The alert notification pipeline relies on the [507-ai-inference](../507-ai-inference/) service and AIO dataflows to route inference results from MQTT topics to the dedicated Event Hub. The `alert-dataflow.tfvars.example` in the `full-single-node-cluster` blueprint configures:

* A Kafka-type dataflow endpoint targeting the Event Hub namespace
* A dataflow subscribing to inference alert topics (`edge-ai/+/+/+/inference/+/+/high`, `edge-ai/+/+/+/alerts/triggers`)
* A passthrough transformation that forwards the full JSON payload

The edge messaging component (`130-messaging`) provisions these dataflow resources when `should_create_alert_eventhub_dataflows = true`.

## Configuration

### Environment Variables (Deployed)

When deployed to the Function App provisioned by `040-messaging`, managed identity authentication is configured automatically via Terraform:

| Variable                                      | Description                                               | Default            |
|-----------------------------------------------|-----------------------------------------------------------|--------------------|
| `EventHubConnection__fullyQualifiedNamespace` | Event Hub namespace FQDN                                  | Set by Terraform   |
| `EventHubConnection__credential`              | Authentication method                                     | `managedidentity`  |
| `EventHubConnection__clientId`                | Client ID of the notification managed identity            | Set by Terraform   |
| `ALERT_EVENTHUB_NAME`                         | Name of the alert Event Hub                               | Set by Terraform   |
| `ALERT_EVENTHUB_CONSUMER_GROUP`               | Consumer group for this function                          | `fn-notifications` |
| `NOTIFICATION_WEBHOOK_URL`                    | Destination webhook URL                                   | Required           |
| `ALERT_SEVERITY_THRESHOLD`                    | Minimum severity to dispatch: low, medium, high, critical | `high`             |
| `DEDUP_WINDOW_MS`                             | Deduplication window in milliseconds                      | `30000`            |
| `DIGEST_INTERVAL_MS`                          | Medium-severity digest interval in milliseconds           | `300000`           |

### Environment Variables (Local Development)

For local development, use a connection string in `local.settings.json`:

| Variable                        | Description                                               | Default            |
|---------------------------------|-----------------------------------------------------------|--------------------|
| `EventHubConnection`            | Event Hub namespace connection string (Listen)            | Required           |
| `ALERT_EVENTHUB_NAME`           | Name of the alert Event Hub                               | Required           |
| `ALERT_EVENTHUB_CONSUMER_GROUP` | Consumer group for this function                          | `fn-notifications` |
| `NOTIFICATION_WEBHOOK_URL`      | Destination webhook URL                                   | Required           |
| `ALERT_SEVERITY_THRESHOLD`      | Minimum severity to dispatch: low, medium, high, critical | `high`             |

### Severity Mapping

Alerts with an explicit `severity` field use that value directly. Otherwise, severity is derived from the `confidence` or `score` field:

| Confidence Range | Severity |
|------------------|----------|
| >= 0.95          | critical |
| >= 0.80          | high     |
| >= 0.50          | medium   |
| < 0.50           | low      |

## Webhook Payload Formats

The function auto-detects the webhook platform from the destination URL and formats the payload accordingly.

### Teams (Adaptive Card)

Detected when the webhook URL contains `webhook.office.com` or `.logic.azure.com`. Sends an Adaptive Card with severity-colored header and a FactSet containing severity, source, model, timestamp, confidence, and label fields.

### Slack (Block Kit)

Detected when the webhook URL contains `hooks.slack.com`. Sends a Block Kit message with a header block and a section containing markdown-formatted field pairs.

### Generic JSON

Used for all other webhook URLs. Sends a flat JSON object with `event`, `severity`, `timestamp`, `source`, `model`, `label`, `confidence`, and the full alert `details`.

### Digest Payloads

Medium-severity alerts are batched into a single digest notification containing a summary count and a list of source/label pairs. The digest format adapts to the detected webhook platform using the same URL inspection logic.

## Project Structure

```text
513-tiered-notification-service/
├── README.md                        # This documentation
├── host.json                        # Function host configuration (batch size, logging)
├── package.json                     # Node.js dependencies and scripts
├── local.settings.json.template     # Environment variable template for local development
└── src/
    └── functions/
        └── processAlerts.js         # Event Hub trigger with severity routing and webhook dispatch
```

## Development

### Local Build

```bash
cd src/500-application/513-tiered-notification-service

cp local.settings.json.template local.settings.json

# Edit with your Event Hub connection string and webhook URL
nano local.settings.json

npm install
npm start
```

> [!IMPORTANT]
> Local development uses a connection string for Event Hub authentication. The deployed Function App uses managed identity, which cannot be used locally without additional configuration.

### Testing

Run the test suite with vitest:

```bash
npm test
```

Run tests in watch mode during development:

```bash
npm run test:watch
```

Generate a coverage report:

```bash
npm run test:coverage
```

### Host Configuration

The `host.json` configures the Event Hub trigger for batch processing:

| Setting                              | Value   | Purpose                            |
|--------------------------------------|---------|------------------------------------|
| `eventHubs.maxEventBatchSize`        | 64      | Maximum messages per invocation    |
| `eventHubs.prefetchCount`            | 128     | Messages prefetched from Event Hub |
| `eventHubs.batchCheckpointFrequency` | 1       | Checkpoint after every batch       |
| `logging.logLevel.Host.Triggers`     | Warning | Reduce trigger-level log noise     |

### Updating the Webhook URL

To change the webhook destination after deployment:

1. Update the `notification_webhook_url` variable in your blueprint tfvars
2. Re-apply the Terraform blueprint to update the Function App settings
3. The function automatically detects the new webhook platform on the next invocation
