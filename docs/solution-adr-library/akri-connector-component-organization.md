---
title: 'Architecture Decision Record: Akri Connector Component Organization'
description: Architecture Decision Record addressing the organizational challenges of Akri connector components in the Edge AI Accelerator repository. Evaluates four architectural options for structuring connectors that use pre-built images versus custom buildable applications, comparing current application-based organization against dedicated blueprints, new component groupings, and specialized directories. Documents the recommended restructuring to blueprints/addons pattern for improved separation of concerns and developer experience.
author: Edge AI Team
ms.date: 2025-11-14
ms.topic: architecture-decision-record
estimated_reading_time: 12
keywords:
  - akri
  - akri-connector
  - component-organization
  - repository-structure
  - media-connector
  - onvif-connector
  - sse-connector
  - ros2-connector
  - rest-http-connector
  - blueprints
  - addons
  - development-environment
  - pre-built-images
  - buildable-applications
  - azure-iot-operations
  - architecture-decision-record
  - adr
---

## Status

Proposed

## Context

The Edge AI Accelerator project includes multiple Akri connector implementations for Azure IoT Operations (AIO), organized within the `src/500-application/` directory. During code review of the Media Connector integration, architectural questions arose regarding the appropriate organization of these components.

### Current State

Akri connectors are currently located in `src/500-application/` with the following structure:

* **505-akri-rest-http-connector**: REST HTTP connector with custom buildable applications (sensor simulators, weather stations, test clients)
* **506-ros2-connector**: ROS2 integration connector with custom buildable ROS2 bridge components
* **508-media-connector**: Media capture connector using pre-built MCR images, development environment only
* **509-sse-connector**: Server-Sent Events connector using pre-built MCR images, development environment only
* **510-onvif-connector**: ONVIF camera connector using pre-built MCR images, development environment only

### Problem Statement

The `src/500-application/` directory is intended for application workloads with buildable source code that can be containerized and deployed. However, three of the five Akri connectors (media, SSE, ONVIF) currently contain:

* Docker Compose files for local development
* References to pre-built container images from Microsoft Container Registry (MCR)
* Infrastructure-as-Code examples in README files
* No custom buildable application source code

This creates several issues:

1. **Semantic Inconsistency**: Components in `500-application/` are expected to have buildable artifacts, but media/SSE/ONVIF connectors do not
2. **Build Pipeline Confusion**: CI/CD pipelines expect to build container images from source, requiring special `.nobuild` marker files
3. **IaC Fragmentation**: Infrastructure deployment examples exist in component READMEs rather than centralized blueprint locations
4. **Developer Experience**: Unclear whether these are "applications to build" or "deployment patterns to reference"

### Architectural Principles

The repository follows these organizational principles:

1. **Component Isolation**: Each numbered component in `src/` is self-contained with clear deployment dependencies
2. **Blueprint Composition**: Blueprints orchestrate multiple components for end-to-end solutions
3. **Build System Semantics**: Components in `500-application/` should produce buildable container images
4. **IaC Centralization**: Infrastructure deployment patterns belong in `blueprints/` for discoverability

### Reference Architecture

The existing Fabric RTI blueprint (`blueprints/fabric-rti/`) demonstrates a successful pattern for addon/layered deployments:

* Provides complete Terraform implementation for deploying Fabric Real-Time Intelligence
* Can be applied on top of existing base blueprints (e.g., `full-single-node-cluster`)
* Contains no buildable application code
* Focuses on infrastructure orchestration and configuration

## Decision Drivers

1. **Semantic Clarity**: Repository organization should clearly communicate component purpose and usage patterns
2. **Build System Efficiency**: CI/CD pipelines should not require special-case handling for non-buildable components
3. **Developer Discoverability**: Infrastructure patterns should be easy to find in expected locations
4. **Extensibility**: Architecture should support future custom component development
5. **Backward Compatibility**: Existing deployments and documentation should remain functional
6. **Consistency**: Similar components should follow similar organizational patterns

## Options Considered

### Option 1: Status Quo with .nobuild Markers

**Description**: Maintain current organization in `src/500-application/` and use `.nobuild` marker files to skip build pipeline processing for non-buildable connectors.

**Structure**:

```plaintext
src/500-application/
  505-akri-rest-http-connector/     # HAS buildable apps
    services/
      sensor-simulator/
        Dockerfile
        app.py
  508-media-connector/              # NO buildable apps
    .nobuild
    docker-compose.yml
    README.md (contains IaC examples)
  509-sse-connector/
    .nobuild
    docker-compose.yml
    README.md (contains IaC examples)
  510-onvif-connector/
    .nobuild
    docker-compose.yml
    README.md (contains IaC examples)
```

**Pros**:

* Zero migration effort - no file moves required
* All Akri connectors remain co-located in single directory
* `.nobuild` marker provides explicit signal for build system
* Docker Compose environments remain in same location as documentation

**Cons**:

* Semantic inconsistency - violates "500-application = buildable apps" principle
* Build pipeline requires special-case handling logic
* Infrastructure examples fragmented in component READMEs
* Difficult for users to discover deployment patterns
* Does not align with blueprint composition model
* Misleading for developers expecting buildable source code

**Implementation Effort**: Low (already implemented for media-connector)

### Option 2: Restructure to Blueprints with Development Environments

**Description**: Move Infrastructure-as-Code deployment patterns to `blueprints/addons/` while retaining Docker Compose development environments in `src/500-application/` with clear naming to indicate dev-only status.

**Structure**:

```plaintext
blueprints/addons/
  akri-media-connector/
    terraform/
      main.tf           # Deployment of Media Connector to AIO cluster
      variables.tf
      outputs.tf
    README.md           # Production deployment guide

  akri-sse-connector/
    terraform/
      main.tf
      variables.tf
      outputs.tf
    README.md

  akri-onvif-connector/
    terraform/
      main.tf
      variables.tf
      outputs.tf
    README.md

src/500-application/
  505-akri-rest-http-connector/     # REMAINS - has buildable apps
    services/
      sensor-simulator/

  508-media-connector-dev/          # RENAMED to indicate dev environment
    docker-compose.yml
    .env.example
    README.md                       # Local development guide only

  509-sse-connector-dev/
    docker-compose.yml
    .env.example
    README.md

  510-onvif-connector-dev/
    docker-compose.yml
    .env.example
    README.md
```

**Pros**:

* Clear semantic separation: blueprints for IaC, src/ for dev environments
* Aligns with existing blueprint composition model (follows fabric-rti pattern)
* Infrastructure patterns centralized and discoverable in `blueprints/addons/`
* No build pipeline special-casing required (dev environments not in build matrix)
* Enables layered deployment: base blueprint + connector addon(s)
* Clear naming convention communicates dev-only vs production deployment

**Cons**:

* Moderate migration effort - requires moving and restructuring files
* Splits Akri connectors across two directories (REST/ROS2 vs others)
* Requires documentation updates and path reference changes
* Need to update .gitignore and build system exclusion patterns
* Breaking change for existing deployment workflows

**Implementation Effort**: Medium (file moves, Terraform refactoring, documentation updates)

### Option 3: Add Custom Buildable Components

**Description**: Develop custom buildable applications for media, SSE, and ONVIF connectors to justify their placement in `src/500-application/` and provide value-added integration examples.

**Structure**:

```plaintext
src/500-application/
  505-akri-rest-http-connector/
    services/
      sensor-simulator/             # Existing custom app

  508-media-connector/
    services/
      alert-handler/                # NEW: Custom Python service
        Dockerfile
        app.py                      # Processes camera alerts, publishes to MQ
        requirements.txt
      ai-inference/                 # NEW: Custom ML inference
        Dockerfile
        inference.py                # YOLO/TensorFlow for object detection
        models/

  509-sse-connector/
    services/
      event-aggregator/             # NEW: Custom event processing
        Dockerfile
        aggregator.py               # Correlates events, generates insights

  510-onvif-connector/
    services/
      ptz-controller/               # NEW: Custom PTZ automation
        Dockerfile
        controller.py               # Automated pan-tilt-zoom control
```

**Example Custom Components**:

**Media Connector**:

* **Alert Handler Service**: Consumes camera motion/alert events, applies business logic, publishes filtered alerts to Azure Event Grid/Event Hub
* **AI Inference Pipeline**: Processes video frames with ML models (object detection, person counting, anomaly detection), publishes annotated results
* **Clip Archive Service**: Manages video clip lifecycle (compression, metadata tagging, Azure Blob upload)

**SSE Connector**:

* **Event Aggregator**: Correlates events from multiple SSE sources, detects patterns, generates composite alerts
* **Alert Correlation Engine**: Applies rules to event streams, triggers workflows based on event sequences
* **Dataflow Adapter**: Transforms SSE events to AIO Dataflow format for seamless integration

**ONVIF Connector**:

* **PTZ Controller**: Automated camera control based on event triggers (preset positions, tracking, patrol routes)
* **Camera Configuration Manager**: Bulk camera configuration deployment and validation
* **Motion Analytics**: Analyzes ONVIF motion detection events, calculates occupancy metrics

**Pros**:

* Validates placement in `src/500-application/` with legitimate buildable artifacts
* Provides production-ready integration examples and reference implementations
* Demonstrates end-to-end scenarios (camera → connector → custom app → cloud)
* Enables advanced use cases beyond basic connector functionality
* Maintains Akri connector co-location in single directory
* No breaking changes to existing structure

**Cons**:

* Significant development effort for custom components
* Increases maintenance burden (code, tests, documentation)
* May introduce complexity for users only needing basic connector functionality
* Custom components may duplicate functionality available in other services
* Requires ongoing updates as connector APIs evolve

**Implementation Effort**: High (new service development, testing, documentation)

### Option 4: Hybrid Approach - Split by Maturity

**Description**: Combine Option 2 and Option 3 - move current dev-only connectors to blueprints immediately, develop custom components over time to graduate them back to `src/500-application/`.

**Short-Term Structure**:

```plaintext
blueprints/addons/
  akri-media-connector/             # Immediate move
  akri-sse-connector/               # Immediate move
  akri-onvif-connector/             # Immediate move

src/500-application/
  505-akri-rest-http-connector/     # Stays (has buildable apps)
  506-ros2-connector/               # Stays (has buildable apps)
```

**Long-Term Structure** (after custom component development):

```plaintext
src/500-application/
  505-akri-rest-http-connector/
  506-ros2-connector/
  508-media-connector/              # Moved back after adding alert-handler service
    services/alert-handler/
  509-sse-connector/                # Moved back after adding event-aggregator
    services/event-aggregator/

blueprints/addons/
  akri-onvif-connector/             # Remains until custom component developed
```

**Pros**:

* Immediate semantic consistency - non-buildable components move to blueprints
* Provides clear graduation path for connector maturity
* Phased implementation reduces initial effort
* Enables prioritization of custom component development by business value
* Maintains flexibility to add components only where valuable

**Cons**:

* Complex migration path with multiple phases
* Components may move between directories over time (confusing for users)
* Difficult to predict timeline for "graduation" back to src/
* May create inconsistent patterns if some connectors never graduate
* Requires ongoing tracking of connector maturity status

**Implementation Effort**: Medium initial (restructure), High long-term (custom components)

## Decision

**[TO BE DETERMINED]**

This ADR presents four viable options for organizing Akri connector components. The decision requires input from:

* **Product Management**: Which custom components provide the most business value?
* **Engineering**: What is the acceptable maintenance burden for custom components?
* **Documentation**: How do we communicate the organizational model to users?
* **Operations**: What deployment patterns do field teams actually use?

### Recommendation

#### Recommended: Option 2 - Restructure to Blueprints with Development Environments

**Rationale**:

1. **Immediate Value**: Achieves semantic consistency without requiring new feature development
2. **Aligns with Existing Patterns**: Follows proven blueprint composition model (fabric-rti precedent)
3. **User Experience**: Centralizes infrastructure patterns in discoverable location
4. **Extensibility**: Does not preclude adding custom components in the future
5. **Clean Build Pipeline**: Eliminates special-case handling for non-buildable components

**Phased Implementation**:

**Phase 1** (Immediate - Sprint 1):

* Create `blueprints/addons/akri-media-connector/` with Terraform from current README examples
* Create `blueprints/addons/akri-sse-connector/` with Terraform deployment
* Create `blueprints/addons/akri-onvif-connector/` with Terraform deployment
* Rename `src/500-application/508-media-connector/` to `508-media-connector-dev/`
* Rename `src/500-application/509-sse-connector/` to `509-sse-connector-dev/`
* Rename `src/500-application/510-onvif-connector/` to `510-onvif-connector-dev/`
* Update documentation and deployment guides
* Update build system to exclude `-dev` pattern from build matrix

**Phase 2** (Optional - Future Sprints):

* Evaluate business need for custom components based on customer feedback
* Develop high-value custom components (e.g., alert-handler for media connector)
* Graduate connectors with custom components back to `src/500-application/` without `-dev` suffix
* Remove `-dev` suffix and `.nobuild` marker upon graduation

This approach provides immediate architectural consistency while maintaining flexibility for future enhancement.

## Consequences

### Positive Consequences

* **Semantic Clarity**: Repository organization clearly communicates component purpose
* **Blueprint Discoverability**: Users can easily find all addon blueprints in centralized location
* **Build System Simplification**: No special-case logic required for non-buildable components
* **Consistent Patterns**: All IaC follows blueprint composition model
* **Extensibility**: Architecture supports future custom component development without restructuring

### Negative Consequences

* **Migration Effort**: Requires file moves, path updates, and documentation changes
* **Split Organization**: Akri connectors distributed across `blueprints/addons/` and `src/500-application/`
* **Learning Curve**: Users must understand distinction between dev environments and production blueprints
* **Temporary Disruption**: Existing deployment workflows require path updates

### Mitigation Strategies

1. **Documentation**: Create clear migration guide and update all references in getting-started guides
2. **Automation**: Provide script to automatically update user Terraform paths from old to new structure
3. **Deprecation Period**: Maintain symbolic links from old to new locations for one release cycle
4. **Communication**: Announce changes in release notes with clear migration instructions

## References

* [Application Instructions](../../.github/instructions/application.instructions.md) - Component organization standards
* [Blueprint README](../../blueprints/README.md) - Blueprint composition patterns
* [Fabric RTI Blueprint](../../blueprints/fabric-rti/) - Addon blueprint reference implementation
* [REST HTTP Connector](../../src/500-application/505-akri-rest-http-connector/) - Connector with buildable apps
* [Media Connector PR Discussion](https://dev.azure.com/ai-at-the-edge-flagship-accelerator/edge-ai/_git/edge-ai/pullrequest/530) - Original architectural review

## Notes

### Alternative Considerations Not Pursued

**Component-Level Blueprints**: Initially considered creating component-level blueprints (e.g., `blueprints/components/akri-media/`) but rejected because:

* Components in `src/` already provide component-level IaC in `ci/terraform/` directories
* Would create confusion about difference between component IaC and blueprint IaC
* Addon pattern more clearly communicates "applies on top of existing deployment"

**Separate Akri Repository**: Considered extracting all Akri connectors to separate repository but rejected because:

* Connectors are tightly coupled to AIO deployment patterns in this repository
* Would fragment documentation and example deployments
* Loss of blueprint composition benefits

### Related ADRs

* **[ADR-003: Language Selection](../../project-adrs/Accepted/003-adr-language-selection.md)**: Python selected for custom component development
* **[ADR-005: Cluster Support](../../project-adrs/Accepted/005-adr-cluster-support.md)**: K3s cluster support impacts connector deployment patterns

### Implementation Checklist

If Option 2 is selected, the following tasks must be completed:

**Infrastructure**:

* [ ] Create `blueprints/addons/akri-media-connector/terraform/` with main.tf, variables.tf, outputs.tf, versions.tf
* [ ] Create `blueprints/addons/akri-sse-connector/terraform/` with main.tf, variables.tf, outputs.tf, versions.tf
* [ ] Create `blueprints/addons/akri-onvif-connector/terraform/` with main.tf, variables.tf, outputs.tf, versions.tf
* [ ] Extract Terraform examples from component READMEs to blueprint main.tf files
* [ ] Create blueprint README.md files with deployment instructions and prerequisites

**Source Reorganization**:

* [ ] Rename `src/500-application/508-media-connector/` to `508-media-connector-dev/`
* [ ] Rename `src/500-application/509-sse-connector/` to `509-sse-connector-dev/`
* [ ] Rename `src/500-application/510-onvif-connector/` to `510-onvif-connector-dev/`
* [ ] Update component READMEs to focus on local development, link to blueprints for production
* [ ] Remove `.nobuild` markers (no longer needed for `-dev` directories)

**Build System**:

* [ ] Update build system to exclude `-dev` pattern from application build matrix
* [ ] Remove `.nobuild` marker detection logic from ApplicationBuilder.Helpers.psm1
* [ ] Update CI/CD pipeline documentation

**Documentation**:

* [ ] Update `blueprints/README.md` to document addon blueprint pattern
* [ ] Create migration guide for users with existing deployments
* [ ] Update getting-started guides to reference new blueprint locations
* [ ] Update `src/500-application/README.md` to explain `-dev` naming convention
* [ ] Update all cross-references in documentation

**Testing**:

* [ ] Validate blueprint deployments in test environment
* [ ] Verify docker-compose dev environments still function
* [ ] Test blueprint layering on top of full-single-node-cluster
* [ ] Validate CI/CD pipeline with new structure

**Communication**:

* [ ] Draft release notes announcing restructure
* [ ] Create announcement for team communication channels
* [ ] Update training materials and workshop guides

---

*AI and automation capabilities described in this architecture decision should be implemented following responsible AI principles, including fairness, reliability, safety, privacy, inclusiveness, transparency, and accountability. Organizations should ensure appropriate governance, monitoring, and human oversight are in place for all AI-powered solutions.*
