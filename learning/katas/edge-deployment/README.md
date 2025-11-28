---
title: Edge Deployment Katas
description: Streamlined AI-assisted deployment workflows for edge computing platforms with infrastructure as code
author: Edge AI Team
ms.date: 2025-06-16
ms.topic: kata-category
estimated_reading_time: 5
difficulty: foundation to legendary
duration: 60-120 minutes
# Learning Platform Integration
category: edge-deployment
prerequisite_katas: []
role_relevance:
  - edge-engineer
  - devops-engineer
  - solution-architect
target_audience:
  - Edge Engineers
  - DevOps Engineers
  - Solution Architects
  - Infrastructure Engineers
learning_objectives:
  - Learn AI-assisted deployment workflows for edge computing platforms
  - Apply infrastructure as code patterns using Terraform and Bicep
  - Troubleshoot complex deployment issues effectively
  - Implement secure and scalable edge deployment strategies
# Content Classification
content_type: hands-on
real_world_application: Real-world edge computing deployment scenarios with infrastructure as code
complexity_factors:
  - Multi-component infrastructure deployment coordination
  - Edge-specific networking and security considerations
  - Cross-platform deployment automation and validation
# Repository Integration
uses_prompts: []
uses_instructions:
  - .github/instructions/terraform.instructions.md
  - .github/instructions/bicep.instructions.md
uses_chatmodes: []
repository_paths:
  - src/
  - blueprints/
  - scripts/
repository_integration:
  - "src/"
  - "blueprints/"
  - "scripts/"
# Success Criteria & Assessment
success_criteria:
  - Demonstrate successful edge infrastructure deployment workflows
  - Apply infrastructure as code best practices and patterns
  - Troubleshoot and resolve complex deployment issues
  - Implement secure and scalable deployment strategies
common_pitfalls:
  - "Incomplete dependency management": Ensure all component dependencies are properly configured
  - "Security configuration gaps": Apply proper security policies and access controls
  - "Poor error handling": Implement comprehensive error detection and recovery procedures
# SEO & Discoverability
keywords:
  - edge deployment
  - infrastructure as code
  - deployment workflows
  - azure edge
tags:
  - deployment
  - infrastructure
  - edge-computing
  - automation
# AI Coaching Integration
ai_coaching_enabled: true
validation_checkpoints:
  - "Deployment workflow execution: Verify successful deployment of edge infrastructure components"
  - "Infrastructure validation: Confirm all deployed resources are properly configured and operational"
  - "Security compliance: Ensure security policies and access controls are correctly implemented"
extension_challenges:
  - challenge_name: Multi-Site Edge Deployment
    description: Deploy coordinated edge infrastructure across multiple geographic locations
    difficulty: advanced
    estimated_time: 120 minutes
  - challenge_name: Zero-Downtime Edge Updates
    description: Implement rolling update strategies for edge infrastructure with zero downtime
    difficulty: expert
    estimated_time: 90 minutes
troubleshooting_guide: |
  **Common Issues:**
  - Deployment timeouts: Check network connectivity and resource availability
  - Authentication failures: Verify service principal permissions and credentials
  - Resource conflicts: Ensure unique naming and avoid resource group conflicts
---

## Quick Context

Edge Deployment katas provide hands-on practice with AI-assisted deployment workflows for edge computing platforms. These exercises focus on infrastructure as code patterns, deployment automation, and troubleshooting techniques for real-world edge scenarios.

📊 **[Track Your Progress](../../catalog.md)** - Monitor your progress on your learning journey

## 🤖 AI Coaching Available

This kata category includes AI coaching support to help guide you through:

- Edge-specific deployment patterns and workflows
- Infrastructure as code best practices and troubleshooting
- Security and networking configuration for edge environments
- Performance optimization and scalability techniques

## Learning Objectives

By completing these edge deployment katas, you will:

- **Learn Edge Deployment**: Develop expertise in edge-specific deployment workflows and patterns
- **Apply IaC Patterns**: Use Terraform and Bicep effectively for edge infrastructure deployment
- **Troubleshoot Effectively**: Diagnose and resolve complex deployment issues quickly
- **Implement Security**: Apply proper security policies and access controls for edge environments

## Edge Deployment Katas

Streamlined practice for developing AI-assisted deployment workflows specifically for edge computing platforms. These optimized exercises build expertise in infrastructure as code deployment with minimal reading overhead.

### What You'll Practice

- **Deployment Workflows**: Systematic deployment planning and execution with embedded guidance
- **Infrastructure as Code**: Terraform and Bicep deployment patterns using action-oriented approach
- **Troubleshooting**: Advanced deployment issue resolution with streamlined structure

### Project Integration Resources

These katas integrate with real project components for practical experience:

- **Edge Blueprints**: Practice with [full-single-node-cluster][full-single-node-cluster] and [minimum-single-node-cluster][minimum-single-node-cluster]
- **Edge Components**: Explore [IoT Operations deployment][iot-ops-deployment] and [CNCF cluster setup][cncf-cluster-setup]
- **Cloud Integration**: Learn with [messaging components][messaging-components] and [observability setup][observability-setup]

<!-- AUTO-GENERATED:START -->
<!-- This section is automatically generated. Manual edits will be overwritten. -->

## Streamlined Kata Progression

| #   | Kata Title                                                                          | Difficulty      | Duration | Prerequisites   | Technology Focus                 | Scaffolding |
|-----|-------------------------------------------------------------------------------------|-----------------|----------|-----------------|----------------------------------|-------------|
| 100 | [100 - Deployment Basics](./100-deployment-basics.md)                               | ⭐ Foundation    | 30 min   | —               | Terraform, Azure, GitHub Copilot | Heavy       |
| 100 | [100 - Edge Resource Management and Optimization](./100-resource-management.md)     | ⭐ Foundation    | 45 min   | → 100           | Terraform, Azure, Kubernetes     | Heavy       |
| 300 | [300 - Multi-Blueprint Coordination](./300-multi-blueprint-coordination.md)         | ⭐⭐⭐ Advanced    | 90 min   | → 100, 100      | Terraform, Azure, GitHub Copilot | Medium      |
| 400 | [400 - Enterprise Compliance Validation](./400-enterprise-compliance-validation.md) | ⭐⭐⭐⭐ Expert     | 120 min  | → 100, 100, 300 | Terraform, Azure, GitHub Copilot | Light       |
| 500 | [500 - Deployment Expert](./500-deployment-expert.md)                               | ⭐⭐⭐⭐⭐ Legendary | 150 min  | → 400           | Terraform, Bicep, Azure          | Light       |

<!-- AUTO-GENERATED:END -->

## Learning Progression

<!-- AUTO-GENERATED: Learning Progression START -->

### 100 - Foundation Level

- **Focus**: Develop AI-assisted deployment workflows using structured guidance to deploy edge infrastructure and handle deployment failures in production environments and Learn to deploy and optimizing Azure IoT Operations blueprints in resource-constrained edge environments with effective monitoring and troubleshooting strategies
- **Skills**: Terraform, Azure, GitHub Copilot, Kubernetes
- **Time-to-Practice**: 1-2 hours

### 300 - Advanced Level

- **Focus**: Learn multi-blueprint coordination for complex edge deployment scenarios with dependency management and staged deployment strategies
- **Skills**: Terraform, Azure, GitHub Copilot
- **Time-to-Practice**: 1-2 hours

### 400 - Expert Level

- **Focus**: Learn AI-assisted compliance validation, security checking, and enterprise governance requirements for production-ready edge deployments
- **Skills**: Terraform, Azure, GitHub Copilot, PowerShell
- **Time-to-Practice**: 2 hours

### 500 - Legendary Level

- **Focus**: Learn advanced deployment patterns and architectures to design custom deployment solutions for complex edge computing environments
- **Skills**: Terraform, Bicep, Azure, Kubernetes, GitHub Copilot
- **Time-to-Practice**: 3 hours

<!-- AUTO-GENERATED: Learning Progression END -->

## Real-World Application

These streamlined katas prepare you for:

- **Edge Platform Deployment**: Systematic deployment of complex edge systems
- **Infrastructure Management**: AI-assisted infrastructure as code practices
- **Deployment Automation**: Streamlined deployment workflows and troubleshooting
- **Production Operations**: Real-world edge deployment and maintenance

## Prerequisites

**For All Katas**:

- Visual Studio Code with GitHub Copilot extension installed and active
- Active GitHub Copilot subscription with chat functionality
- **Active Azure subscription** with Contributor or Owner role
- Azure CLI, Terraform, and Bicep installed and configured
- Basic understanding of cloud infrastructure concepts
- Familiarity with command-line tools and Git

**For Kata 300 and Beyond** (Multi-Blueprint and Expert):

- Strong understanding of Terraform module composition and state management
- Experience with Azure resource dependencies and integration patterns
- Understanding of Kubernetes and container orchestration (Kata 400-405)
- Sufficient time availability:
  - Kata 300: 120 minutes, cleanup within 3 hours
  - Kata 400: 150 minutes, cleanup within 4 hours
  - Kata 405: 240 minutes, cleanup within 6 hours

**For Kata 405** (Legendary - Production Deployment):

- Production operations experience with incident response and SLA management
- Understanding of disaster recovery concepts (RPO/RTO, failover procedures)
- Familiarity with enterprise monitoring and alerting systems
- Substantial Azure quota for multi-region deployment

## Cost Considerations

> **💰 Important**: All edge deployment katas deploy real Azure resources that incur costs.

**Estimated Costs by Kata**:

- **Kata 100** (Deployment Basics): $20-35 USD for single blueprint deployment
- **Kata 200** (Resource Management): $25-50 USD for IoT Operations and edge resources
- **Kata 300** (Multi-Blueprint Coordination): $40-60 USD for coordinated multi-blueprint deployment
- **Kata 400** (Enterprise Compliance): $30-50 USD for compliance validation resources
- **Kata 405** (Deployment Expert): $45-70 USD for multi-region DR infrastructure

**Cost Management Best Practices**:

- Set timers when deploying resources to track deployment duration
- Complete cleanup steps within recommended timeframes (see each kata for specific guidance)
- Verify all resources deleted using `az resource list --output table` after cleanup
- Set up Azure budget alerts to prevent unexpected costs
- Use [Azure Cost Management][azure-cost-management] to monitor spending in real-time
- Consider using smaller VM SKUs (Standard_D2s_v3 instead of D4s_v3) for cost-conscious learning

**Cleanup Priority by Kata**:

- **Kata 100-200**: Complete cleanup within 2-3 hours of deployment
- **Kata 300**: Complete cleanup within 3-4 hours of deployment
- **Kata 400-405**: Complete cleanup within 4-6 hours of deployment
- Always verify cleanup completion in Azure Portal - some resources (Arc, IoT Operations) may require manual deletion

## Difficulty-Based Numbering

Kata filenames use a difficulty-based numbering system:

- **100-200** prefix: Foundation (Difficulty 1-2) - Beginner-friendly with heavy scaffolding and explicit prompts
- **300** prefix: Intermediate (Difficulty 3) - Moderate scaffolding with decision frameworks and validation checkpoints
- **400** prefix: Expert (Difficulty 4) - Light scaffolding with evaluation matrices and compliance frameworks
- **405** prefix: Legendary (Difficulty 5) - Minimal scaffolding, outcome-focused for production expertise

This numbering helps you quickly identify kata complexity and select appropriate challenges for your skill level.

**Ready to start edge deployment practice?**

🚀 **[Begin with 100 - Deployment Basics][kata-100-basics]**

*Learn edge deployment through streamlined, hands-on practice.*

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->

<!-- Reference Links -->
<!-- Internal Project Links -->
[full-single-node-cluster]: /blueprints/full-single-node-cluster/
[minimum-single-node-cluster]: /blueprints/minimum-single-node-cluster/
[iot-ops-deployment]: /src/100-edge/110-iot-ops/
[cncf-cluster-setup]: /src/100-edge/120-cncf-cluster/
[messaging-components]: /src/000-cloud/020-messaging/
[observability-setup]: /src/000-cloud/030-observability/
[kata-100-basics]: /learning/katas/edge-deployment/100-deployment-basics
[azure-cost-management]: https://docs.microsoft.com/azure/cost-management-billing/
