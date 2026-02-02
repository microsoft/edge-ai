---
title: "Expert: Data & Analytics Integration"
description: "Build edge-to-cloud data pipelines with Microsoft Fabric Real-Time Intelligence for advanced analytics"
author: Edge AI Team
ms.date: 10/24/2025
ms.topic: learning-path
estimated_reading_time: 8
difficulty: expert
keywords:
  - microsoft-fabric
  - real-time-intelligence
  - data-pipelines
  - azure-iot-operations
  - kql
  - analytics
prerequisites:
  - foundation-ai-first-engineering
  - intermediate-infrastructure-architect
outcomes:
  - Configure Microsoft Fabric workspaces and Real-Time Intelligence
  - Build edge-to-cloud data pipelines with Azure IoT Operations
  - Implement multi-source data integration
  - Develop advanced analytics pipelines with KQL
  - Create real-time analytics dashboards
  - Design enterprise data lake architectures
  - Implement cross-region replication strategies
  - Establish compliance and governance frameworks
technologies:
  - Microsoft Fabric
  - Azure IoT Operations
  - EventStream
  - Eventhouse
  - KQL (Kusto Query Language)
  - Power BI
  - MQTT
  - Terraform
---

**Level**: Expert • **Duration**: 8 hours • **Topics**: Microsoft Fabric, Real-Time Intelligence, Data Pipelines, Analytics

Build sophisticated edge-to-cloud data pipelines with Microsoft Fabric for enterprise-scale analytics.

**Perfect for**: Data engineers and analytics specialists building real-time data platforms

**Recommended for**: Data Engineers, Analytics Engineers, Solution Architects, Data Scientists, Platform Engineers

---

## Learning Journey

### Prerequisites

- **Required**: [Foundation: AI-First Engineering](foundation-ai-first-engineering.md)
- **Required**: [Intermediate: Infrastructure Architect](intermediate-infrastructure-architect.md)
- Understanding of data pipeline concepts

### Core Learning Path

#### Foundation Setup (100-200 level)

- [ ] [**Kata: 200 - Fabric Workspace Setup**](../katas/fabric-integration/200-prerequisite-full-deployment.md)
  *Foundation | 90 min* • Deploy complete Edge AI infrastructure stack as foundation for Microsoft Fabric RTI integration
  **Prerequisites:** None • **Technologies:** Terraform, Azure, Azure IoT Operations, Kubernetes

- [ ] [**Kata: 200 - Real-Time Intelligence Configuration**](../katas/fabric-integration/200-fabric-workspace-configuration.md)
  *Foundation | 60 min* • Configure Microsoft Fabric workspace and Real-Time Intelligence capabilities for edge data integration
  **Prerequisites:** fabric-integration-200-prerequisite-full-deployment • **Technologies:** Microsoft Fabric, Azure, KQL (Kusto Query Language)

- [ ] [**Kata: 100 - Edge-to-Fabric Data Flow**](../katas/fabric-integration/100-fabric-rti-blueprint-deployment.md)
  *Foundation | 45 min* • Deploy fabric-rti Terraform blueprint to connect Edge AI infrastructure with Microsoft Fabric Real-Time Intelligence
  **Prerequisites:** fabric-integration-200-prerequisite-full-deployment, fabric-integration-200-fabric-workspace-configuration • **Technologies:** Terraform, Microsoft Fabric, Azure IoT Operations, EventStream, KQL (Kusto Query Language), MQTT

#### Advanced Integration (300-400 level)

- [ ] [**Kata: 300 - Edge-to-Cloud Data Pipeline**](../katas/fabric-integration/300-edge-to-cloud-data-pipeline.md)
  *Advanced | 90 min* • Design and implement a robust edge-to-cloud data pipeline architecture for real-time analytics
  **Prerequisites:** fabric-integration-100-prerequisite-full-deployment, fabric-integration-200-fabric-workspace-configuration, fabric-integration-105-fabric-rti-blueprint-deployment • **Technologies:** Azure IoT Operations, EventStream, Eventhouse, KQL, MQTT, Terraform

- [ ] [**Kata: 400 - Real-Time Analytics Dashboards**](../katas/fabric-integration/400-fabric-analytics-dashboards.md)
  *Expert | 120 min* • Build advanced analytics dashboards in Microsoft Fabric using real-time edge-to-cloud data
  **Prerequisites:** fabric-integration-100-prerequisite-full-deployment, fabric-integration-200-fabric-workspace-configuration, fabric-integration-105-fabric-rti-blueprint-deployment, fabric-integration-300-edge-to-cloud-data-pipeline • **Technologies:** Microsoft Fabric, KQL, DAX, Power BI, Azure IoT Operations

- [ ] [**Kata: 400 - Performance Diagnostics**](../katas/troubleshooting/400-multi-component-debugging.md)
  *Expert | 60 min* • Develop proficiency in debugging workflows for interconnected Edge AI systems with multiple dependencies, service interactions, and failures
  **Prerequisites:** troubleshooting-100-basic-edge-troubleshooting, troubleshooting-200-intermediate-debugging, troubleshooting-300-advanced-system-analysis • **Technologies:** Kubernetes, Azure IoT Operations, Azure Arc, Prometheus, Grafana, GitHub Copilot

- [ ] [**Kata: 400 - Data Quality Monitoring**](../katas/troubleshooting/400-performance-optimization.md)
  *Expert | 75 min* • Develop proficiency in performance tuning and capacity planning for Edge AI systems using data-driven optimization and intelligent resource allocation
  **Prerequisites:** troubleshooting-100-basic-edge-troubleshooting, troubleshooting-200-intermediate-debugging • **Technologies:** Kubernetes, Azure IoT Operations, Azure Arc, Prometheus, Grafana, GitHub Copilot

#### Enterprise Architecture (500+ level)

- [ ] [**Kata: 500 - Enterprise Data Lake Architecture**](../katas/task-planning/500-learning-platform-extraction.md)
  *Legendary | 80 min* • Learn comprehensive extraction and packaging of documentation frameworks and learning platform capabilities for client project delivery
  **Prerequisites:** task-planning-100-edge-documentation-planning, task-planning-200-repository-analysis-planning, task-planning-300-ai-asset-extraction • **Technologies:** GitHub Copilot, Docsify

- [ ] [**Kata: 400 - Cross-Region Replication**](../katas/task-planning/400-ai-asset-extraction.md)
  *Expert | 70 min* • Learn systematic extraction and packaging of AI prompts, instructions, and agents for client project delivery using comprehensive task planning
  **Prerequisites:** task-planning-100-edge-documentation-planning, task-planning-200-repository-analysis-planning • **Technologies:** GitHub Copilot

- [ ] [**Kata: 400 - Compliance & Governance**](../katas/task-planning/400-pr-generation.md)
  *Expert | 50 min* • Learn AI-assisted PR generation workflow through systematic analysis of git changes, creating accurate PR descriptions
  **Prerequisites:** task-planning-100-edge-documentation-planning • **Technologies:** GitHub Copilot, Git

---

## Next Steps

After completing this path, consider these follow-up options:

- **Expert Path**: [Enterprise Integration](expert-enterprise-integration.md) - Complex multi-system integration
- **Specialization**: Advanced analytics domains (ML pipelines, streaming analytics, data governance)
- **Innovation**: Real-time AI/ML integration with data platforms

---

## Progress Tracking

Your progress is automatically tracked as you complete each kata and lab. Use the 📚 checkbox to add items to your personalized learning path, and watch the ✅ indicator update as you complete activities.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
