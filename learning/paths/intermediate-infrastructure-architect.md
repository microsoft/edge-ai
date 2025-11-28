---
title: "Intermediate: Infrastructure Architect"
description: "Design and deploy edge-to-cloud infrastructure with architectural rigor using ADRs and deployment automation"
author: Edge AI Team
ms.date: 10/24/2025
ms.topic: learning-path
estimated_reading_time: 10
difficulty: skill
keywords:
  - infrastructure-architecture
  - adr-creation
  - edge-deployment
  - azure-arc
  - azure-iot-operations
  - kubernetes
prerequisites:
  - foundation-ai-first-engineering
outcomes:
  - Build expertise with Architecture Decision Records for infrastructure design
  - Deploy single-node and multi-node edge clusters
  - Plan network topology and system architecture
  - Evaluate technologies for enterprise requirements
  - Design cross-site and enterprise-scale architectures
technologies:
  - Architecture Decision Records
  - Terraform
  - Azure Arc
  - Azure IoT Operations
  - Kubernetes
  - Azure
---

**Level**: Intermediate • **Duration**: 9.5 hours • **Topics**: Infrastructure Design, ADRs, Edge Deployment, System Architecture

Design and deploy edge-to-cloud infrastructure with architectural rigor using systematic evaluation and documentation.

**Perfect for**: Platform engineers and infrastructure architects building edge-to-cloud systems

**Recommended for**: Platform Engineers, Solution Architects, Infrastructure Engineers, Cloud Architects

---

## Learning Journey

### Prerequisites

- **Required**: [Foundation: AI-First Engineering](foundation-ai-first-engineering.md)
- Understanding of infrastructure concepts
- Basic familiarity with cloud platforms

### Core Learning Path

#### Foundation (100-level)

- [ ] [**Kata: 100 - Your First ADR with Research Agent**](../katas/adr-creation/100-basic-messaging-architecture.md)
  *Foundation | 40 min* • Learn foundational ADR creation through systematic evaluation and documentation of messaging technology decisions for distributed systems
  **Prerequisites:** None • **Technologies:** MQTT, Azure IoT Operations, Architecture Decision Records (ADR), GitHub Copilot

#### Advanced Architecture Decisions (200-level)

- [ ] [**Kata: 200 - Research-Driven ADR Creation**](../katas/adr-creation/200-advanced-observability-stack.md)
  *Intermediate | 50 min* • Learn complex ADR creation through multi-component evaluation, comparing TIG vs TICK stack for edge observability and monitoring
  **Prerequisites:** adr-creation-100-basic-messaging-architecture • **Technologies:** Prometheus, Grafana, OpenTelemetry, Kubernetes, Azure Monitor, GitHub Copilot

- [ ] [**Kata: 400 - Complex System Documentation**](../katas/adr-creation/400-service-mesh-selection.md)
  *Expert | 90 min* • Create an ADR for service mesh technology selection in edge computing environments with industrial automation requirements
  **Prerequisites:** adr-creation-100-basic-messaging-architecture, adr-creation-200-advanced-observability-stack • **Technologies:** Istio, Linkerd, Consul, Kubernetes, GitHub Copilot

#### Edge Deployment Proficiency (300-level)

- [ ] [**Kata: 300 - Single-Node Edge Deployment**](../katas/edge-deployment/100-deployment-basics.md)
  *Foundation | 75 min* • Develop AI-assisted deployment workflows using structured guidance to deploy edge infrastructure and handle deployment failures in production environments
  **Prerequisites:** None • **Technologies:** Terraform, Bicep, Azure, GitHub Copilot

- [ ] [**Kata: 100 - Multi-Node Cluster Setup**](../katas/edge-deployment/100-resource-management.md)
  *Foundation | 90 min* • Learn to deploy and optimize Azure IoT Operations blueprints in resource-constrained edge environments with effective monitoring and troubleshooting strategies
  **Prerequisites:** edge-deployment-100-deployment-basics • **Technologies:** Terraform, Bicep, Azure, GitHub Copilot

- [ ] [**Kata: 300 - Network Topology Planning**](../katas/edge-deployment/300-multi-blueprint-coordination.md)
  *Advanced | 120 min* • Learn multi-blueprint coordination for complex edge deployment scenarios with dependency management and staged deployment strategies
  **Prerequisites:** edge-deployment-100-deployment-basics, edge-deployment-200-resource-management • **Technologies:** GitOps, Flux, Kubernetes, GitHub Actions, Azure Arc

#### Expert Architecture & Planning (400-level)

- [ ] [**Kata: 400 - Multi-Component ADR Planning**](../katas/project-planning/400-enterprise-architecture-planning.md)
  *Expert | 50 min* • Develop enterprise architecture planning expertise and comprehensive system design with AI assistance for complex Edge AI transformations with multi-facility deployments
  **Prerequisites:** project-planning-100-basic-prompt-usage, project-planning-200-comprehensive-two-scenario • **Technologies:** GitHub Copilot, Azure

- [ ] [**Kata: 500 - Technology Evaluation Framework**](../katas/adr-creation/500-edge-ai-inference-platform-selection.md)
  *Legendary | 80 min* • Compare edge AI inference platforms for real-time drone defect detection with performance, MLOps, and connectivity resilience requirements
  **Prerequisites:** adr-creation-100-basic-messaging-architecture, adr-creation-200-advanced-observability-stack, adr-creation-300-service-mesh-selection • **Technologies:** Azure IoT Edge, NVIDIA Jetson, Azure Machine Learning, TensorFlow Lite, ONNX Runtime, GitHub Copilot

#### Legendary Enterprise Solutions (500-level)

- [ ] [**Kata: 500 - Cross-Site Architecture ADR**](../katas/adr-creation/500-cross-site-industrial-data-architecture.md)
  *Legendary | 100 min* • Design site-to-site VPN architecture for manufacturing data flow with Azure IoT Operations, MQTT bridging, and real-time operational requirements
  **Prerequisites:** adr-creation-100-basic-messaging-architecture, adr-creation-200-advanced-observability-stack, adr-creation-300-service-mesh-selection • **Technologies:** Azure VPN Gateway, Azure IoT Operations, MQTT Broker, Site-to-Site VPN, Azure Arc, Network Architecture, Industrial IoT, JIT Manufacturing

- [ ] [**Kata: 400 - Legacy System Integration**](../katas/edge-deployment/400-enterprise-compliance-validation.md)
  *Expert | 100 min* • Learn AI-assisted compliance validation, security checking, and enterprise governance requirements for production-ready edge deployments
  **Prerequisites:** edge-deployment-100-deployment-basics, edge-deployment-200-resource-management, edge-deployment-300-gitops-advanced • **Technologies:** Terraform, Bicep, Azure Policy, GitHub Copilot, Azure Arc

- [ ] [**Kata: 500 - Enterprise-Scale Deployment**](../katas/edge-deployment/500-deployment-expert.md)
  *Legendary | 120 min* • Learn advanced deployment patterns and architectures to design custom deployment solutions for complex edge computing environments
  **Prerequisites:** edge-deployment-400-enterprise-compliance-validation • **Technologies:** Terraform, Bicep, Azure, Kubernetes, GitHub Copilot

---

## Next Steps

After completing this path, consider these follow-up options:

- **Intermediate Path**: [DevOps Excellence](intermediate-devops-excellence.md) - Operations and troubleshooting
- **Expert Path**: [Data & Analytics Integration](expert-data-analytics-integration.md) - Build data pipelines
- **Expert Path**: [Enterprise Integration](expert-enterprise-integration.md) - Complex system integration

---

## Progress Tracking

Your progress is automatically tracked as you complete each kata and lab. Use the 📚 checkbox to add items to your personalized learning path, and watch the ✅ indicator update as you complete activities.

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
