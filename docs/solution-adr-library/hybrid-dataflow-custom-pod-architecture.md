---
title: Integrating Azure IoT Operations Dataflows and Custom Pods for Transformation Workloads
description: 'Adopting a hybrid approach for transformation and logic workloads at the edge using Azure IoT Operations Dataflows and custom Rust pods.'
author: mapach
ms.date: 2025-09-23
ms.topic: architecture
estimated_reading_time: 4
keywords:
  - architecture
  - edge
  - dataflow
  - transformation
  - mqtt
  - hybrid
  - rust
  - azure-iot-operations
  - solution
  - adr
  - library
---

## Status

- [x] Draft
- [ ] Proposed
- [ ] Accepted
- [ ] Deprecated

## Context

**Scenario Context**: Edge event detection and data processing for industrial IoT, requiring fusion of vision, sensor, and external data sources, with evolving Azure IoT Operations platform capabilities.

**Problem Statement**: How to architect transformation and logic workloads at the edge to balance performance, maintainability, and flexibility as Azure IoT Operations evolves from Data Processor Pipelines to Dataflows, while supporting complex event detection and integration needs.

**Constraints and Requirements**:

- Must support both lightweight and heavy transformation logic
- Need for modular, composable, and scalable components
- Integration with MQTT as the system backbone
- Support for rapid prototyping and production hardening
- Platform evolution (Pipelines → Dataflows, expression/WASM)
- Kubernetes deployment, node affinity, and scaling

**Success Criteria**:

- Reliable event detection with multi-source correlation
- Easy migration/adaptation as platform evolves
- High performance for heavy logic, low latency for routing/filtering
- Traceability and decoupling via MQTT
- Maintainable, testable, and debuggable transformation logic

## Decision

**Decision Statement**: Adopt a hybrid architecture for edge transformation/logic workloads, using Azure IoT Operations Dataflows for routing, filtering, and simple enrichment, and custom Rust pods for heavy transformation, enrichment, and heuristic logic, with MQTT as the integration backbone.

**Decision Rationale**: This approach provides the flexibility to leverage Dataflows' simplicity for integration and routing, while retaining the performance and control of custom code for complex logic. It enables modularity, scalability, and easier adaptation to platform changes.

**Implementation Approach**:

- Use Dataflows (expression/WASM) for lightweight, declarative tasks and integration with Azure services
- Implement custom Rust pods for heavy transformation, enrichment, Last-Known Values (LKVs) mapping, and heuristic logic
- Connect all components via MQTT topics for decoupling, traceability, and scalability
- Group transformations into pods/threads for fine-grained scaling and failure isolation
- Prototype with simple backends (in-memory), then harden for production (e.g., MQTT-backed state)

## Decision Drivers

- Modularity and maintainability
- Performance and scalability
- Flexibility to adapt to platform evolution
- Ease of debugging and tracing
- Integration with MQTT and Azure IoT Operations

## Considered Options

### Option 1: All-in Dataflows (Expression/WASM)

- **Description**: Use only Dataflows for all transformation and logic workloads
- **Technical Details**: Expression-based for simple logic, WASM for custom code
- **Pros**: Simpler integration, single framework, less custom code
- **Cons**: Limited performance/flexibility for heavy logic, evolving WASM support
- **Risks**: Platform maturity, debugging complexity
- **Dependencies**: Dataflow feature set, WASM runtime
- **Cost Analysis**: Lower initial dev, higher risk for complex needs

### Option 2: Hybrid Dataflows + Custom Pods (**Chosen**)

- **Description**: Dataflows for routing/simple logic, custom Rust pods for heavy/complex logic
- **Technical Details**: Dataflows for integration, Rust pods for transformation, all via MQTT
- **Pros**: Best of both worlds, modular, scalable, flexible, easier migration
- **Cons**: More moving parts, requires pod management
- **Risks**: Integration complexity, operational overhead
- **Dependencies**: MQTT, Kubernetes, Rust runtime
- **Cost Analysis**: Moderate dev/ops, lower risk for complex needs

### Option 3: All-in Custom Pods

- **Description**: Use only custom Rust pods for all logic
- **Technical Details**: All transformation, routing, and integration in Rust
- **Pros**: Maximum control/performance
- **Cons**: Higher dev/maintenance cost, less leverage of platform features
- **Risks**: Harder migration, more custom code
- **Dependencies**: Rust, MQTT, Kubernetes
- **Cost Analysis**: Higher dev/ops, less future-proof

## Comparison Matrix

| Criteria        | Dataflows Only | Hybrid (Chosen) | Custom Pods | Weight |
|-----------------|----------------|-----------------|-------------|--------|
| Modularity      | Medium         | High            | Medium      | High   |
| Performance     | Medium         | High            | High        | High   |
| Flexibility     | Medium         | High            | Medium      | High   |
| Maintainability | Medium         | High            | Medium      | High   |
| Migration Ease  | Low            | High            | Low         | Medium |
| Dev Effort      | Low            | Medium          | High        | Medium |

## Consequences

**Positive Consequences**:

- Modular, composable, and scalable architecture
- Easier adaptation to platform changes
- High performance for heavy logic
- Traceability and decoupling via MQTT

**Negative Consequences**:

- Increased operational complexity (pods + Dataflows)
- Requires careful topic/partition management in MQTT

**Neutral Consequences**:

- Some duplication of logic between Dataflows and pods
- Need for clear documentation and monitoring

## Future Considerations

**Monitoring and Evolution**:

- Monitor Dataflow/WASM feature evolution
- Watch for MQTT broker scaling/partitioning needs
- Re-evaluate as Azure IoT Operations matures

**Review Triggers**:

- Major platform changes (Dataflows, MQTT, Kubernetes)
- New requirements for transformation/logic workloads

*AI and automation capabilities described in this scenario should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*

*🤖 Crafted with precision by ✨Copilot following brilliant human instruction, then carefully refined by our team of discerning human reviewers.*
