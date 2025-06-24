---
title: 03 - Service Mesh Selection
description: Practice ADR creation for complex microservices infrastructure, evaluating Istio vs Linkerd for edge computing service mesh deployment in industrial automation scenarios
author: Edge AI Team
ms.date: 2025-06-17
ms.topic: kata
estimated_reading_time: 8
difficulty: advanced
duration: 45-50 minutes
keywords:
  - praxisworx
  - adr creation
  - architectural decision records
  - service mesh
  - istio
  - linkerd
  - open service mesh
  - osm
  - microservices
  - edge computing
  - industrial automation
  - azure integration
  - azure iot operations
  - smi compliance
  - numbered progression
---

## Quick Context

**You'll Learn**: Create sophisticated infrastructure-level ADRs for complex distributed systems decisions involving multiple technical and business factors.

**Real Challenge**: Your quality control system uses 25+ microservices across 200+ edge clusters with Azure IoT Operations managing industrial devices and data flows. You need secure, high-performance site-to-site and service-to-service communication with comprehensive traffic management that integrates seamlessly with Azure IoT Operations.
Choose between Istio, Linkerd, and Open Service Mesh (OSM) for service mesh deployment while balancing feature richness against operational complexity in resource-constrained edge environments.

**Your Task**: Create a strategic ADR that evaluates all three service mesh solutions against performance, security, operational, and Azure IoT Operations integration criteria, documenting a clear recommendation with implementation strategy.

### Essential Setup

**Required** (check these first):

- [ ] Completion of previous ADR katas (messaging architecture and observability)
- [ ] Understanding of microservices architecture and Kubernetes concepts
- [ ] Knowledge of service mesh concepts (traffic management, security, observability)
- [ ] Familiarity with Azure IoT Operations and industrial edge computing scenarios

**Quick Validation**: Can explain what a service mesh does and why it's needed for microservices communication, especially in industrial IoT scenarios.

## Practice Tasks

### Task 1: Service Mesh Architecture and Performance Research (20 minutes)

**What You'll Do**: Research all three service mesh architectures, performance characteristics, and edge deployment patterns.

**Steps**:

1. **Research** Istio architecture and capabilities
   - [ ] Use GitHub Copilot to understand control plane complexity and data plane performance
   - [ ] Focus on: feature richness, resource requirements, configuration complexity
   - **Expected result**: Clear understanding of Istio's comprehensive capabilities and operational overhead

2. **Research** Linkerd architecture and operational model
   - [ ] Use Copilot to understand simplified architecture and performance optimization
   - [ ] Focus on: operational simplicity, resource efficiency, core feature set
   - **Expected result**: Clear understanding of Linkerd's streamlined approach and limitations

3. **Research** Open Service Mesh (OSM) architecture and cloud-native approach
   - [ ] Use Copilot to understand SMI-compliant architecture and Azure integration
   - [ ] Focus on: SMI specification compliance, Azure ecosystem integration, enterprise features
   - **Expected result**: Clear understanding of OSM's standards-based approach and Azure-native capabilities

4. **Analyze** edge computing deployment implications
   - [ ] Consider resource constraints, network connectivity, distributed management across all three solutions
   - [ ] Evaluate performance impact on real-time microservices communication for each option   - [ ] Assess Azure IoT Operations integration capabilities and industrial protocol support
   - **Success check**: Can articulate key architectural trade-offs between feature richness, operational simplicity, cloud-native integration, and Azure IoT Operations compatibility

### Task 2: Security and Operational Requirements Analysis (15 minutes)

**What You'll Do**: Define evaluation criteria for security, compliance, and operational management requirements.

**Steps**:

1. **Assess** security and compliance requirements
   - [ ] Mutual TLS implementation, authorization policies, enterprise integration
   - [ ] Audit logging, compliance reporting, network segmentation capabilities
   - **Expected result**: Comprehensive security requirements matrix with compliance considerations

2. **Evaluate** operational complexity factors
   - [ ] Deployment across 200+ edge clusters, configuration management, troubleshooting
   - [ ] Upgrade management, resource overhead, training requirements
   - **Expected result**: Clear operational complexity assessment for distributed edge deployment

3. **Define** integration and strategic requirements
   - [ ] Kubernetes ecosystem integration, enterprise system connectivity, Azure cloud integration   - [ ] Azure IoT Operations compatibility, industrial protocol support, device management integration
   - [ ] Long-term viability, community support, SMI compliance, migration considerations
   - **Success check**: Multi-dimensional evaluation framework ready for three-way technology comparison including Azure IoT Operations requirements

### Task 3: Strategic ADR Creation with Implementation Plan (20 minutes)

**What You'll Do**: Create executive-level ADR with comprehensive analysis, strategic recommendation, and actionable implementation roadmap.

**Steps**:

1. **Perform** detailed three-way technology comparison
   - [ ] Apply evaluation criteria to all service mesh solutions (Istio, Linkerd, OSM) with specific evidence
   - [ ] Include performance analysis, security assessment, operational complexity comparison   - [ ] Document integration complexity, Azure ecosystem alignment, and Azure IoT Operations compatibility
   - [ ] Evaluate industrial protocol support, device connectivity patterns, and real-time communication requirements
   - **Expected result**: Comprehensive comparative analysis supporting strategic decision-making across all options with Azure IoT Operations considerations

2. **Document** strategic recommendation with multi-stakeholder justification
   - [ ] Present selected service mesh with rationale addressing technical, operational, and business concerns
   - [ ] Include risk assessment, mitigation strategies, and long-term implications
   - [ ] Address implementation complexity, timeline, resource requirements, and cloud integration benefits
   - **Expected result**: Executive-level recommendation with comprehensive strategic justification

3. **Include** detailed implementation strategy and success metrics
   - [ ] Phased deployment approach minimizing operational risk across edge infrastructure   - [ ] Integration methodology with existing systems, enterprise requirements, Azure services, and Azure IoT Operations
   - [ ] Performance validation framework and operational readiness criteria for industrial scenarios
   - [ ] Device connectivity validation and industrial protocol compatibility testing
   - **Success criteria**: Complete strategic ADR ready for infrastructure investment decisions with full Azure IoT Operations integration

## Completion Check

**You've Succeeded When**:

- [ ] Created comprehensive ADR comparing Istio, Linkerd, and Open Service Mesh with sophisticated analysis
- [ ] Addressed performance, security, operational, and Azure IoT Operations integration requirements across all three options
- [ ] Documented strategic recommendation with implementation roadmap and risk mitigation
- [ ] ADR meets executive-level quality standards for infrastructure technology decisions
- [ ] Included specific considerations for industrial IoT scenarios and device connectivity patterns

## Next Steps

**Apply Skills**: Use this advanced methodology for real-world infrastructure architecture decisions in enterprise organizations

## Resources

- [Azure Kubernetes Service][ms-azure-kubernetes] - Container orchestration and service mesh integration
- [Azure IoT Operations][ms-azure-iot-operations] - Unified data plane for industrial IoT scenarios
- [Service Mesh Interface (SMI)][smi-spec] - Kubernetes service mesh specification and standards
- [Microservices Architecture][ms-microservices-architecture] - Enterprise microservices patterns and best practices
- [Azure Arc-enabled Kubernetes][ms-azure-arc-kubernetes] - Hybrid and multi-cloud Kubernetes management
- [Previous ADRs](01-basic-messaging-architecture.md) - Reference methodology consistency across related decisions

---

<!-- Reference Links -->
[ms-azure-kubernetes]: https://docs.microsoft.com/azure/aks/
[ms-azure-iot-operations]: https://docs.microsoft.com/azure/iot-operations/
[smi-spec]: https://smi-spec.io/
[ms-microservices-architecture]: https://docs.microsoft.com/azure/architecture/microservices/
[ms-azure-arc-kubernetes]: https://docs.microsoft.com/azure/azure-arc/kubernetes/

<!-- markdownlint-disable MD036 -->
*🤖 Crafted with precision by ✨Copilot following brilliant human instruction,
then carefully refined by our team of discerning human reviewers.*
<!-- markdownlint-enable MD036 -->
