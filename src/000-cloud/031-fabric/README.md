---
title: Microsoft Fabric Component
description: Microsoft Fabric resources including capacity, workspace, eventhouse, and lakehouse for real-time analytics and data lake scenarios for Edge AI workloads
author: Edge AI Team
ms.date: 07/29/2025
ms.topic: reference
estimated_reading_time: 6
keywords:
  - microsoft fabric
  - capacity
  - workspace
  - eventhouse
  - lakehouse
  - real-time analytics
  - data lake
  - edge ai
  - terraform
---

This component deploys Microsoft Fabric resources including capacity, workspace, eventhouse, and lakehouse to support real-time analytics and data lake scenarios for Edge AI workloads.

## Overview

Microsoft Fabric provides a unified analytics platform that combines data movement, data lakes, data integration, data science, real-time analytics, and business intelligence. This component creates the foundational Fabric infrastructure for processing and analyzing data from Edge devices.

## Resources Created

- **Fabric Capacity** (optional): Dedicated compute resources for Fabric workloads
- **Fabric Workspace**: Container for all Fabric items and collaboration
- **Fabric Eventhouse** (optional): Real-time analytics engine for time-series data
- **Fabric Lakehouse** (optional): Data lake storage for structured and unstructured data
- **KQL Databases**: Analytics databases within the eventhouse for real-time querying

## Key Features

- **Real-time Analytics**: Process streaming data from Edge devices using KQL databases
- **Data Lake Storage**: Store and analyze large volumes of Edge data in Delta Lake format
- **Unified Platform**: Single platform for data engineering, data science, and business intelligence
- **Scalable Compute**: Auto-scaling capacity based on workload demands
- **Integrated Security**: Built-in security and governance features

## Usage

This component is typically used as a foundation for:

- Real-time monitoring and alerting on Edge device telemetry
- Historical analysis of Edge data patterns
- Machine learning model training on Edge datasets
- Business intelligence dashboards for Edge operations
- Data integration from multiple Edge locations

## Configuration

The component supports flexible configuration options:

- **Capacity Management**: Create new capacity or use existing capacity
- **Resource Selection**: Choose which Fabric resources to create (workspace, eventhouse, lakehouse)
- **Database Configuration**: Configure multiple KQL databases with custom retention policies
- **Access Control**: Set capacity administrators and workspace permissions

## Dependencies

- Azure Resource Group for resource deployment
- Azure Active Directory for identity and access management
- Sufficient Azure subscription quotas for Fabric capacity

## External References

### Microsoft Fabric Real-Time Intelligence Documentation

- [Microsoft Fabric Real-Time Intelligence Overview](https://learn.microsoft.com/fabric/real-time-intelligence/) - Complete platform overview and real-time analytics capabilities
- [Eventhouse Overview](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse) - Real-time analytics engine for time-series data and streaming workloads
- [Create a KQL Database](https://learn.microsoft.com/fabric/real-time-intelligence/create-database) - Database creation, management, and configuration for analytics
- [Deploy an Eventhouse using Fabric APIs](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse-deploy-with-fabric-api) - Programmatic deployment patterns and automation

### EventStream Configuration and Management

- [EventStream REST API](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/eventstream-rest-api) - Complete API specification for sources, destinations, operators, and streaming configuration
- [Add and Manage EventStream Sources](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-manage-eventstream-sources) - All supported data sources, CustomEndpoint configuration, and connectivity options
- [Add and Manage EventStream Destinations](https://learn.microsoft.com/fabric/real-time-intelligence/event-streams/add-manage-eventstream-destinations) - Eventhouse destination configuration and data routing options

### Capacity Planning and Performance Optimization

- [Microsoft Fabric Capacity SKUs](https://learn.microsoft.com/fabric/enterprise/licenses#capacity) - Complete F2-F2048 SKU specifications with capacity units and performance characteristics
- [Plan Your Capacity Size](https://learn.microsoft.com/fabric/enterprise/plan-capacity) - Capacity sizing guidelines, consumption calculations, and throughput planning
- [Scale Your Capacity](https://learn.microsoft.com/fabric/enterprise/scale-capacity) - Dynamic scaling operations, considerations, and best practices

### Terraform Provider and Infrastructure Automation

- [Terraform Provider for Microsoft Fabric](https://registry.terraform.io/providers/microsoft/fabric/latest/docs) - Microsoft Fabric Terraform Provider documentation and guides
