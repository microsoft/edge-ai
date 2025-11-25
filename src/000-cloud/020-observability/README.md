---
title: Cloud Observability Component
description: Centralized monitoring and observability infrastructure for the Edge AI Accelerator using Azure Managed Grafana, Azure Monitor, and Log Analytics for comprehensive edge-to-cloud visibility
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - observability
  - monitoring
  - azure managed grafana
  - azure monitor workspace
  - log analytics workspace
  - grafana dashboard
  - azure iot operations
  - edge monitoring
  - telemetry
  - metrics
  - logs
  - terraform
  - bicep
estimated_reading_time: 3
---

## Cloud Observability Component

This component establishes centralized monitoring and observability infrastructure for the Edge AI Accelerator, providing comprehensive visibility into edge devices, Azure IoT Operations, and cloud services through integrated Azure monitoring services.

## Purpose and Role

The Cloud Observability component serves as the monitoring backbone for the entire Edge AI Accelerator solution:

- **Centralized Monitoring**: Aggregates metrics, logs, and traces from edge and cloud components
- **Real-time Visibility**: Provides real-time dashboards and alerting for operational insights
- **Performance Tracking**: Monitors AI model performance, device health, and system metrics
- **Troubleshooting**: Enables rapid identification and resolution of issues across the distributed system

## Component Resources

This component creates the following Azure monitoring resources:

### Core Monitoring Infrastructure

- **Azure Log Analytics Workspace**: Central repository for log data from edge and cloud
- **Azure Monitor Workspace**: Managed service for collecting and storing Prometheus metrics
- **Azure Managed Grafana**: Fully managed Grafana service for visualization and dashboards

### Dashboards and Visualization

- **Pre-configured AIO Dashboard**: Ready-to-use Grafana dashboard for Azure IoT Operations monitoring
- **Custom Dashboards**: Additional dashboards for edge device and application monitoring
- **Alert Rules**: Proactive monitoring with configurable alert thresholds

### Access and Security

- **Role-based Access Control**: Secure access to monitoring dashboards and data
- **Managed Identity Integration**: Seamless authentication with other Azure services

## Integration with Edge AI Accelerator

This observability infrastructure integrates with all components of the solution:

- **Edge Devices**: Collect metrics, logs, and telemetry from edge infrastructure and applications
- **Azure IoT Operations**: Monitor AIO services, message flows, and device connectivity
- **Data Pipeline**: Track data ingestion, processing, and storage performance
- **AI Workloads**: Monitor AI model inference performance and accuracy metrics

## Monitoring Capabilities

### Edge Device Monitoring

- System metrics (CPU, memory, disk, network)
- Application health and performance
- IoT Operations service status
- AI model inference metrics

### Cloud Service Monitoring

- Azure service health and performance
- Message throughput and latency
- Data processing pipeline status
- Resource utilization and costs

### End-to-End Observability

- Distributed tracing across edge and cloud
- Correlation of events across the entire solution
- Performance baselines and trend analysis

## Deployment Options

### Terraform

Refer to [Terraform Components - Getting Started](../README.md#terraform-components---getting-started) for deployment instructions.

Learn more about the required configuration by reading the [./terraform/README.md](./terraform/README.md)

### Bicep

Refer to [Bicep Components - Getting Started](../README.md#bicep-components---getting-started) for deployment instructions.

Learn more about the required configuration by reading the [./bicep/README.md](./bicep/README.md)

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
