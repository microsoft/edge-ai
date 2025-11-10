---
title: Edge Observability Component
description: Edge-side observability infrastructure that connects Azure IoT Operations to cloud monitoring services through Arc Kubernetes extensions for comprehensive edge-to-cloud visibility
author: Edge AI Team
ms.date: 2025-06-07
ms.topic: reference
keywords:
  - edge observability
  - azure iot operations
  - arc kubernetes extensions
  - azure monitor
  - prometheus
  - grafana
  - edge monitoring
  - kubernetes monitoring
  - telemetry collection
  - distributed tracing
  - terraform
  - bicep
estimated_reading_time: 2
---

## Edge Observability Component

This component establishes edge-side observability infrastructure that connects Azure IoT Operations environments to cloud monitoring services, providing comprehensive visibility into edge operations and seamless integration with cloud-based monitoring dashboards.

## Purpose and Role

The Edge Observability component bridges edge and cloud monitoring by:

- **Edge-side Data Collection**: Deploys monitoring agents and collectors on edge Kubernetes clusters
- **Cloud Integration**: Connects edge telemetry to Azure Monitor and Log Analytics workspaces
- **Distributed Monitoring**: Enables end-to-end observability from edge devices to cloud services
- **Operational Insights**: Provides real-time visibility into Azure IoT Operations performance

## Component Resources

This component deploys the following edge monitoring infrastructure:

### Arc Kubernetes Extensions

- **Azure Monitor Container Insights**: Collects container and pod metrics from edge Kubernetes clusters
- **Azure Monitor Prometheus**: Gathers Prometheus metrics from AIO services and custom applications
- **Log Analytics Agent**: Forwards logs from edge services to cloud Log Analytics workspace
- **Grafana Integration**: Connects edge metrics to cloud-managed Grafana dashboards

### Monitoring Configuration

- **Metric Collection Rules**: Defines which metrics are collected and forwarded to cloud
- **Log Forwarding Rules**: Configures log aggregation and shipping to Azure Monitor
- **Alert Integration**: Enables cloud-based alerting on edge-generated metrics and logs
- **Dashboard Connectivity**: Links edge data to cloud monitoring dashboards

## Integration with Cloud Observability

This component works in conjunction with the Cloud Observability component (020-observability):

- **Metric Flow**: Edge-collected metrics appear in cloud Grafana dashboards
- **Log Aggregation**: Edge logs are centralized in cloud Log Analytics workspace
- **Unified Dashboards**: Single pane of glass for edge and cloud monitoring
- **Alert Correlation**: Cloud alerts can be triggered by edge conditions

## Monitoring Capabilities

### Azure IoT Operations Monitoring

- AIO service health and performance metrics
- MQTT broker throughput and connection status
- Device connectivity and message flow
- Resource utilization of AIO components

### Kubernetes Cluster Monitoring

- Node health and resource consumption
- Pod performance and restart patterns
- Network traffic and service mesh metrics
- Storage and persistent volume usage

### Application Monitoring

- Custom application metrics via Prometheus
- Application logs and error tracking
- Performance counters and business metrics
- AI model inference performance

## Prerequisites

This component requires:

- Azure Arc-enabled Kubernetes cluster with Azure IoT Operations deployed
- Cloud Observability component (020-observability) already deployed
- Appropriate permissions to install Arc extensions on the target cluster

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
