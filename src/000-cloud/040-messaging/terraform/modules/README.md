---
title: Messaging Terraform Modules
description: Reusable Terraform modules for creating Azure messaging infrastructure including Event Grid and Event Hubs for real-time data processing and communication
author: Edge AI Team
ms.date: 06/07/2025
ms.topic: reference
keywords:
  - terraform modules
  - messaging
  - event grid
  - event hubs
  - real-time messaging
  - azure messaging
  - event-driven architecture
  - data streaming
  - infrastructure as code
estimated_reading_time: 2
---

## Messaging Terraform Modules

This directory contains reusable Terraform modules for creating Azure messaging infrastructure that enables real-time data processing and event-driven communication in the Edge AI Accelerator.

## Available Modules

### Event Grid Module (`./event-grid`)

Creates Azure Event Grid resources for event routing and distribution:

- **Event Grid Namespace**: Modern Event Grid namespace with MQTT broker capabilities
- **Topics**: Event topics for organizing different types of events
- **Subscriptions**: Event subscriptions for routing events to downstream consumers
- **Access Control**: Managed identity access for publishing and consuming events

### Event Hubs Module (`./event-hubs`)

Creates Azure Event Hubs resources for high-throughput data streaming:

- **Event Hubs Namespace**: Container for Event Hub instances
- **Event Hubs**: Individual event hubs for different data streams
- **Consumer Groups**: Logical groups for independent event processing
- **Authorization Rules**: Access policies for secure data streaming

## Architecture Integration

These messaging modules form the communication backbone of the Edge AI Accelerator:

- **Edge to Cloud**: Edge devices publish telemetry and AI inference results to Event Grid topics
- **Real-time Processing**: Event streams are consumed by downstream services for immediate processing
- **Data Pipeline**: Events flow from Event Grid to data persistence systems via Event Hubs
- **Scalable Design**: Both Event Grid and Event Hubs provide auto-scaling for varying workloads

## Module Usage

The modules are designed to work together to provide comprehensive messaging capabilities:

- **Event Grid** handles event routing and pub/sub messaging patterns
- **Event Hubs** manages high-volume data streaming and buffering
- Both modules support managed identity authentication for secure access

## Dependencies

These modules integrate with other components in the solution:

- **Security and Identity**: Uses managed identities created by the identity component
- **Data Persistence**: Events are consumed by the data component for storage and analytics
- **Edge Components**: Receive events published from edge devices and IoT Operations

For detailed information about each module's configuration and usage, refer to the individual module README files.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
