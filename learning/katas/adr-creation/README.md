---
title: ADR Creation Katas
description: Streamlined practice for OSS edge computing architecture decision records
author: Edge AI Team
ms.date: 2025-09-18
ms.topic: kata-category
estimated_reading_time: 5
difficulty: foundation to legendary
duration: 45-90 minutes
# Learning Platform Integration
category: adr-creation
prerequisite_katas: []
role_relevance:
  - solution-architect
  - edge-engineer
  - developer
target_audience:
  - Solution Architects
  - Edge Engineers
  - Software Developers
  - Project Managers
learning_objectives:
  - Create structured Architecture Decision Records (ADRs) for edge computing technologies
  - Apply decision criteria frameworks for technology selection
  - Document architectural decisions with clear rationale and trade-offs
  - Follow established ADR templates and formatting standards
# Content Classification
content_type: hands-on
real_world_application: Real-world technology decisions for edge computing projects using OSS technologies
complexity_factors:
  - Understanding multiple technology options and trade-offs
  - Balancing technical and business requirements
  - Documenting decisions clearly for future reference
# Repository Integration
uses_prompts: []
uses_instructions: []
uses_chatmodes: []
repository_paths:
  - project-adrs/
  - docs/solution-adr-library/
  - docs/solution-technology-paper-library/
repository_integration:
  - "project-adrs/"
  - ".github/copilot-instructions.md"
# Success Criteria & Assessment
success_criteria:
  - Complete ADR documents following established templates
  - Clear documentation of decision criteria and rationale
  - Proper use of ADR status and consequences sections
  - Integration with project ADR library
common_pitfalls:
  - "Insufficient decision criteria": Ensure all relevant factors are considered and documented
  - "Missing trade-off analysis": Document both pros and cons of each option
  - "Poor formatting": Follow established ADR templates and markdown formatting
# SEO & Discoverability
keywords:
  - adr creation
  - architectural decision records
  - edge computing
  - oss technologies
tags:
  - architecture
  - documentation
  - decision-making
# AI Coaching Integration
ai_coaching_enabled: true
validation_checkpoints:
  - "ADR structure completion: Verify all required ADR sections are present and properly formatted"
  - "Decision criteria validation: Confirm all relevant technical and business factors are documented"
  - "Trade-off analysis quality: Ensure comprehensive pros/cons analysis for each option"
extension_challenges:
  - challenge_name: Multi-Technology Stack ADR
    description: Create comprehensive ADR for full edge computing stack including messaging, observability, and service mesh
    difficulty: advanced
    estimated_time: 60 minutes
  - challenge_name: Cross-Team ADR Review
    description: Conduct peer review process for ADR validation and consensus building
    difficulty: intermediate
    estimated_time: 30 minutes
troubleshooting_guide: |
  **Common Issues:**
  - ADR format not recognized: Use the provided templates in project-adrs/adr-template.md
  - Missing decision context: Include problem statement and constraints in context section
  - Incomplete options analysis: Document at least 2-3 viable alternatives with clear trade-offs
---

## Quick Context

Architecture Decision Records (ADRs) are lightweight documents that capture important architectural decisions made during edge computing projects. These katas provide hands-on practice creating ADRs for real technology choices you'll encounter in edge AI implementations.

📊 **[Track Your Progress](../../catalog.md)** - Monitor your progress on your learning journey

## 🤖 AI Coaching Available

This kata category includes AI coaching support to help guide you through:

- ADR structure and formatting best practices
- Decision criteria framework application
- Technology trade-off analysis techniques
- Real-world decision scenario guidance

## Learning Objectives

By completing these ADR creation katas, you will:

- **Learn ADR Structure**: Create well-formatted Architecture Decision Records following industry standards
- **Apply Decision Frameworks**: Use systematic criteria to evaluate technology alternatives
- **Analyze Trade-offs**: Document technical, operational, and business implications of architectural choices
- **Communicate Decisions**: Write clear, concise ADRs that stakeholders can understand and act upon
- **Build Decision Skills**: Develop consistent approaches to architectural decision-making

## Real-World Application

These progressive katas prepare you for:

- **Technology Selection**: Systematic evaluation of edge computing technologies from messaging to AI platforms
- **Stakeholder Communication**: Clear documentation of architectural decisions with increasing sophistication
- **Decision Tracking**: Comprehensive ADR management in real projects across multiple domains
- **Architecture Governance**: Consistent decision-making processes for distributed systems
- **Edge AI Architecture**: Platform selection for computer vision, inference optimization, and MLOps at the edge
- **Network Architecture**: Site-to-site connectivity, VPN topology design, and industrial data flow patterns

## ADR Creation Katas

Streamlined practice creating Architecture Decision Records (ADRs) for open-source edge computing technologies following [Azure architecture decision guides][ms-azure-architecture-decisions]. These optimized katas focus on real technology decisions you'll encounter in edge computing projects with minimal reading overhead.

### What You'll Practice

- **ADR Structure**: Create well-formatted Architecture Decision Records following established templates
- **Decision Criteria**: Apply systematic frameworks to evaluate technology alternatives
- **Trade-off Analysis**: Document technical, operational, and business implications of architectural choices
- **Stakeholder Communication**: Write clear, concise ADRs that stakeholders can understand and act upon

### Project Integration Resources

Practice with real project ADR examples and templates:

- **ADR Templates**: Use [solution ADR templates][adr-templates] for structured decision documentation
- **Real Examples**: Study [solution ADR library][adr-library] for practical patterns from customer projects
- **Solution Libraries**: Reference [technology papers][technology-papers] for decision context

<!-- AUTO-GENERATED:START -->
<!-- This section is automatically generated. Manual edits will be overwritten. -->

## Streamlined Kata Progression

| #   | Kata Title                                                                                        | Difficulty      | Duration | Prerequisites   | Technology Focus                                                  | Scaffolding  |
|-----|---------------------------------------------------------------------------------------------------|-----------------|----------|-----------------|-------------------------------------------------------------------|--------------|
| 100 | [100 - Basic Messaging Architecture](./100-basic-messaging-architecture.md)                       | ⭐ Foundation    | 60 min   | —               | Architecture Decision Records, MQTT, Apache Kafka                 | Heavy        |
| 200 | [200 - Advanced Observability Stack](./200-advanced-observability-stack.md)                       | ⭐⭐ Skill        | 50 min   | → 100           | comparing TIG vs TICK stack for edge observability and monitoring | Medium-Heavy |
| 400 | [400 - Service Mesh Selection](./400-service-mesh-selection.md)                                   | ⭐⭐⭐⭐ Expert     | 90 min   | → 200           | Istio, Linkerd, Open Service Mesh                                 | Light        |
| 500 | [500 - Cross-Site Industrial Data Architecture](./500-cross-site-industrial-data-architecture.md) | ⭐⭐⭐⭐⭐ Legendary | 180 min  | → 100, 200, 400 | Azure VPN Gateway, Azure IoT Operations, MQTT Broker              | Light        |
| 500 | [500 - Edge AI Inference Platform Selection](./500-edge-ai-inference-platform-selection.md)       | ⭐⭐⭐⭐⭐ Legendary | 150 min  | → 100, 200, 400 | Azure IoT Edge, ONNX Runtime, NVIDIA Triton                       | Light        |

<!-- AUTO-GENERATED:END -->

### Learning Progression

<!-- AUTO-GENERATED: Learning Progression START -->

### 100 - Foundation Level

- **Focus**: Learn foundational ADR creation through systematic evaluation and documentation of messaging technology decisions for distributed systems
- **Skills**: Architecture Decision Records, MQTT, Apache Kafka, GitHub Copilot
- **Time-to-Practice**: 1-2 hours

### 200 - Skill Level

- **Focus**: Learn complex ADR creation through multi-component evaluation, comparing TIG vs TICK stack for edge observability and monitoring
- **Skills**: Telegraf, InfluxDB, Grafana, Chronograf, Kapacitor
- **Time-to-Practice**: Under 1 hour

### 400 - Expert Level

- **Focus**: Create an ADR for service mesh technology selection in edge computing environments with industrial automation requirements
- **Skills**: Istio, Linkerd, Open Service Mesh, Kubernetes, Azure IoT Operations
- **Time-to-Practice**: 1-2 hours

### 500 - Legendary Level

- **Focus**: Design site-to-site VPN architecture for manufacturing data flow with Azure IoT Operations, MQTT bridging, and real-time operational requirements and Compare edge AI inference platforms for real-time drone defect detection with performance, MLOps, and connectivity resilience requirements
- **Skills**: Azure VPN Gateway, Azure IoT Operations, MQTT Broker, Site-to-Site VPN, Azure Arc
- **Time-to-Practice**: 6 hours

<!-- AUTO-GENERATED: Learning Progression END -->

## Prerequisites

- Basic understanding of software architecture concepts
- Familiarity with edge computing scenarios (helpful but not required)
- Ready to engage with hands-on decision documentation practice

## Essential Setup

Before starting these ADR creation katas, ensure you have:

- Access to the [project ADR templates][adr-templates] and [solution ADR library][adr-library]
- A text editor or IDE with Markdown support
- Basic familiarity with [Architecture Decision Records format][ms-azure-architecture-decisions]
- Understanding of edge computing technology categories (messaging, observability, networking, AI/ML)

## Practice Tasks

These katas guide you through creating Architecture Decision Records for edge computing scenarios:

- **Foundational ADR Skills**: Learn core ADR structure using messaging technology selection scenarios
- **Multi-Component Decisions**: Practice evaluating complex observability stacks with multiple integrated components
- **Advanced Architecture**: Apply ADR methodology to service mesh selection and distributed system patterns
- **Expert Integration**: Develop expertise in cross-site networking and edge AI platform architecture decisions

Each kata provides progressive reduction in scaffolding, building your ability to independently create comprehensive ADRs.

## Validation

You'll know you've successfully completed this kata category when you can:

- Create well-structured ADRs following established templates without guidance
- Apply systematic decision frameworks to evaluate technology alternatives
- Document comprehensive trade-off analyses for architectural choices
- Write clear, stakeholder-ready ADRs that communicate decisions effectively
- Leverage AI tools (chatmodes, Ask mode) appropriately throughout the decision process

**Ready to start practicing ADR creation?**

📋 **[Begin with 01 - Basic Messaging Architecture][kata-01-messaging]**

*Learn architectural decision documentation through streamlined, focused practice.*

---

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
<!-- Internal Project Links -->
[adr-templates]: /project-adrs/
[adr-library]: /docs/solution-adr-library/
[technology-papers]: /docs/solution-technology-paper-library/
[kata-01-messaging]: /learning/katas/adr-creation/01-basic-messaging-architecture

<!-- Microsoft Documentation -->
[ms-azure-architecture-decisions]: https://learn.microsoft.com/azure/architecture/guide/design-principles/
