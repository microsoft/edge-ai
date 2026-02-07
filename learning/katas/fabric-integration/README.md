---
title: Fabric Integration Katas
description: Learn Microsoft Fabric and Real-Time Intelligence integration with edge AI systems through hands-on practice with data pipelines, analytics, and end-to-end workflows
author: Edge AI Team
ms.date: 2025-10-20
ms.topic: kata-category
estimated_reading_time: 5 minutes
duration: 45-120 minutes
category: fabric-integration
difficulty: foundation to expert
---

## Fabric Integration Kata Series

This series provides a progressive, hands-on path to learning Microsoft Fabric and Real-Time Intelligence integration with edge AI systems. Each kata is mapped to a specific difficulty level and builds on the previous, culminating in expert and legendary challenges.

<!-- AUTO-GENERATED:START -->
<!-- This section is automatically generated. Manual edits will be overwritten. -->

## Difficulty Mapping & Progression

| #   | Kata Title                                                                        | Difficulty   | Duration | Prerequisites        | Technology Focus                                  | Scaffolding  |
|-----|-----------------------------------------------------------------------------------|--------------|----------|----------------------|---------------------------------------------------|--------------|
| 100 | [100 - Fabric RTI Blueprint Deployment](./100-fabric-rti-blueprint-deployment.md) | ⭐ Foundation | 90 min   | → 200, 200           | Terraform, Microsoft Fabric, Azure IoT Operations | Heavy        |
| 200 | [200 - Fabric Workspace Configuration](./200-fabric-workspace-configuration.md)   | ⭐⭐ Skill     | 90 min   | → 200                | Microsoft Fabric, Azure Portal, Azure CLI         | Medium-Heavy |
| 200 | [200 - Prerequisite Full Deployment](./200-prerequisite-full-deployment.md)       | ⭐⭐ Skill     | 60 min   | —                    | Terraform, Azure Arc, Azure IoT Operations        | Medium-Heavy |
| 300 | [300 - Edge to Cloud Data Pipeline](./300-edge-to-cloud-data-pipeline.md)         | ⭐⭐⭐ Advanced | 120 min  | → 200, 200, 100      | Azure IoT Operations, EventStream, Eventhouse     | Medium       |
| 400 | [400 - Fabric Analytics Dashboards](./400-fabric-analytics-dashboards.md)         | ⭐⭐⭐⭐ Expert  | 150 min  | → 200, 200, 100, 300 | Microsoft Fabric, KQL, DAX                        | Light        |

<!-- AUTO-GENERATED:END -->

## Getting Started

1. Complete [100-prerequisite-full-deployment.md](100-prerequisite-full-deployment.md) to set up your environment.
2. Progress through each kata in order, using the links above.
3. Use AI coaching prompts embedded in each kata for guidance.

## Repository Integration

- [Fabric Blueprint](/blueprints/fabric/)
- [Fabric RTI Blueprint](/blueprints/fabric-rti/)
- [Fabric Components](/src/000-cloud/031-fabric/)
- [RTI Components](/src/000-cloud/032-fabric-rti/)

📊 **[Track Your Progress](../../catalog.md)** - Monitor your progress on your learning journey

## Quick Start Success Criteria

- Deploy Fabric workspace and RTI components using repository blueprints
- Configure data pipelines for edge-to-cloud integration
- Build analytics dashboards with live edge AI insights
- Validate end-to-end data flow and troubleshoot integration issues

## Troubleshooting Guide

- **Access denied**: Check service principal permissions
- **Data ingestion failures**: Validate network/firewall rules
- **Pipeline errors**: Ensure schema compatibility
- **Performance issues**: Monitor ingestion rates and optimize

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
## Success Criteria

You have successfully completed this kata category when you can:

- [ ] Deploy complete Fabric workspace with RTI components using repository blueprints
- [ ] Configure working data pipelines that process edge sensor data in real-time
- [ ] Build analytics dashboards displaying live edge AI insights from Fabric
- [ ] Demonstrate end-to-end data flow from edge devices through Fabric to business intelligence
- [ ] Troubleshoot and optimize data integration performance for production workloads

Learn Microsoft Fabric and Real-Time Intelligence (RTI) integration with Edge AI systems through practical, hands-on katas focused on essential skills for data-driven Edge AI solutions.

## Category Overview

This category focuses on **emerging capabilities** in Microsoft Fabric and RTI integration that represent genuine skill gaps in Edge AI deployments. These katas provide hands-on experience with data pipelines, analytics workflows, and end-to-end integration patterns using actual repository blueprints.

### Learning Progression

<!-- AUTO-GENERATED: Learning Progression START -->

### 100 - Foundation Level

- **Focus**: Deploy fabric-rti Terraform blueprint to connect Edge AI infrastructure with Microsoft Fabric Real-Time Intelligence
- **Skills**: Terraform, Microsoft Fabric, Azure IoT Operations, EventStream, KQL (Kusto Query Language)
- **Time-to-Practice**: 1-2 hours

### 200 - Skill Level

- **Focus**: Configure Microsoft Fabric workspace and Real-Time Intelligence capabilities for edge data integration and Deploy complete Edge AI infrastructure stack as foundation for Microsoft Fabric RTI integration
- **Skills**: Microsoft Fabric, Azure Portal, Azure CLI, KQL (Kusto Query Language), Terraform
- **Time-to-Practice**: 3 hours

### 300 - Advanced Level

- **Focus**: Design and implement a robust edge-to-cloud data pipeline architecture for real-time analytics
- **Skills**: Azure IoT Operations, EventStream, Eventhouse, KQL, MQTT
- **Time-to-Practice**: 2 hours

### 400 - Expert Level

- **Focus**: Build advanced analytics dashboards in Microsoft Fabric using real-time edge-to-cloud data
- **Skills**: Microsoft Fabric, KQL, DAX, Power BI, Azure IoT Operations
- **Time-to-Practice**: 3 hours

<!-- AUTO-GENERATED: Learning Progression END -->

### Target Skills

- **Microsoft Fabric RTI Deployment**: Using `blueprints/fabric-rti/` for Real-Time Intelligence infrastructure
- **Edge Data Pipeline Integration**: Connecting Edge AI telemetry to Fabric analytics workflows
- **Eventhouse and Analytics Configuration**: Practical experience with RTI components and KQL databases
- **End-to-End Data Workflows**: Complete integration from Edge collection to Fabric analytics

## Prerequisites

**Technical Foundation**:

- Understanding of Edge AI architecture and data collection patterns
- Basic knowledge of Azure infrastructure deployment
- Familiarity with data pipeline concepts

**Repository Knowledge**:

- Completion of Edge Deployment Basics kata or equivalent experience
- Understanding of blueprint deployment patterns from full-single-node-cluster

## Blueprint and Component Integration

### Blueprints Used

- **`blueprints/fabric-rti/`**: Real-Time Intelligence deployment for hands-on RTI configuration practice
- **`blueprints/fabric/`**: Core Fabric capabilities for data warehousing and analytics scenarios
- **Integration with Edge blueprints**: Connecting Edge deployments to Fabric analytics

### Components Referenced

- **`src/000-cloud/031-fabric/`**: Core Fabric infrastructure components and configuration patterns
- **`src/000-cloud/032-fabric-rti/`**: Real-Time Intelligence specific components and RTI workflows

## Kata Difficulty and Duration

| Kata                            | Difficulty   | Duration  | Focus Area                                              |
|---------------------------------|--------------|-----------|---------------------------------------------------------|
| 01 - Fabric RTI Basics          | Intermediate | 35-45 min | RTI deployment and configuration fundamentals           |
| 02 - Edge-to-Fabric Integration | Advanced     | 50-65 min | End-to-end integration and data workflow implementation |

## Success Outcomes

**Upon completion, you will**:

- Deploy and configure Microsoft Fabric RTI infrastructure using repository blueprints
- Implement end-to-end data integration from Edge AI systems to Fabric analytics
- Configure Eventhouse, EventStream, and KQL databases for real-time analytics
- Apply Fabric integration patterns to enterprise Edge AI scenarios

## Getting Started with Fabric Integration

1. **Choose your starting point** based on your Fabric experience:
   - **New to Fabric**: Start with 01 - Fabric RTI Basics
   - **Familiar with Fabric**: Jump to 02 - Edge-to-Fabric Integration

2. **Validate prerequisites**: Ensure you have access to Azure subscription and repository blueprints

3. **Enable AI coaching** (recommended): Use Learning Kata Coach agent for guided practice and progress tracking

## Resources

### Essential References

- [Fabric Blueprint](/blueprints/fabric/) - Core Microsoft Fabric infrastructure deployment patterns
- [Fabric RTI Blueprint](/blueprints/fabric-rti/) - Real-Time Intelligence specific deployment configuration
- [Fabric Components](/src/000-cloud/031-fabric/) - Infrastructure as code components for Fabric services
- [RTI Components](/src/000-cloud/032-fabric-rti/) - Real-Time Intelligence specific IaC components

### Microsoft Documentation

- [Microsoft Fabric documentation](https://learn.microsoft.com/fabric/) - Comprehensive Fabric service documentation
- [Real-Time Intelligence overview](https://learn.microsoft.com/fabric/real-time-intelligence/) - RTI concepts and capabilities
- [Eventhouse and KQL databases](https://learn.microsoft.com/fabric/real-time-intelligence/eventhouse) - Real-time analytics foundations

## Common Integration Issues

**Common Issues:**

- **Fabric workspace access denied**: Verify service principal permissions and authentication configuration for edge services
- **Data ingestion failures**: Check network connectivity and firewall rules between edge infrastructure and Azure Fabric services
- **Real-time pipeline errors**: Validate data schema compatibility and transformation logic between edge and Fabric formats
- **Performance issues**: Monitor ingestion rates and consider data partitioning strategies for high-volume edge deployments
- **Authentication timeouts**: Ensure proper token refresh mechanisms for long-running edge data streams

**Tips for Success:**

- Start with small data volumes to validate pipeline configuration before scaling
- Use Fabric monitoring tools to track data ingestion and processing performance
- Test authentication and connectivity separately before implementing full integration
- Review existing blueprints for proven configuration patterns and settings

## AI Coaching Information

**AI Coaching Support Available:**

- Fabric workspace deployment and configuration best practices guidance
- Real-Time Intelligence pipeline design and optimization assistance
- Edge-to-cloud data integration patterns and troubleshooting support
- Analytics workflow development and performance tuning coaching

**How to Access:**

- Use the 🤖 AI coaching prompts embedded within each kata
- Ask for guidance on specific Fabric service configuration or integration challenges
- Request assistance with data pipeline design and optimization strategies

---

**Ready to build Fabric integration expertise?** 🚀 **Start with [100 - Prerequisite Full Deployment](100-prerequisite-full-deployment.md)**

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
